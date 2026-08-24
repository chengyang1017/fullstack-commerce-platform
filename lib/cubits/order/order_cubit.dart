import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/customer_auth_cubit.dart';
import '../../cubits/auth/customer_auth_state.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  OrderCubit({
    required OrderRepository repository,
    required CustomerAuthCubit authCubit,
  })  : _repository = repository,
        _authCubit = authCubit,
        super(const OrderState());

  final OrderRepository _repository;
  final CustomerAuthCubit _authCubit;

  StreamSubscription<CustomerAuthState>?
      _authSubscription;

  bool _started = false;

  int _loadVersion = 0;

  String? _boundAccountEmail;

  void start() {
    if (_started) {
      return;
    }

    _started = true;

    _authSubscription =
        _authCubit.stream.listen(
      (_) {
        unawaited(
          _syncAuthentication(),
        );
      },
    );

    unawaited(
      _syncAuthentication(),
    );
  }

  Future<void> _syncAuthentication() async {
    if (isClosed) {
      return;
    }

    final authState = _authCubit.state;

    if (authState.status ==
        CustomerAuthStatus.checking) {
      if (state.status ==
          OrderLoadStatus.initial) {
        emit(
          state.copyWith(
            status:
                OrderLoadStatus.loading,
            clearError: true,
          ),
        );
      }

      return;
    }

    final user = authState.user;

    if (!authState.isLoggedIn ||
        user == null) {
      _loadVersion++;

      _boundAccountEmail = null;

      emit(
        const OrderState(
          status:
              OrderLoadStatus.ready,
        ),
      );

      return;
    }

    if (_boundAccountEmail ==
            user.email &&
        (state.status ==
                OrderLoadStatus.loading ||
            state.status ==
                OrderLoadStatus.ready)) {
      return;
    }

    _boundAccountEmail = user.email;

    await _loadOrders();
  }

  Future<void> _loadOrders() async {
    final currentVersion =
        ++_loadVersion;

    emit(
      state.copyWith(
        status:
            OrderLoadStatus.loading,
        clearError: true,
      ),
    );

    try {
      final orders =
          await _repository.loadOrders();

      if (isClosed ||
          currentVersion !=
              _loadVersion) {
        return;
      }

      emit(
        state.copyWith(
          status:
              OrderLoadStatus.ready,
          orders:
              List.unmodifiable(
            orders,
          ),
          clearError: true,
        ),
      );
    } catch (error) {
      if (isClosed ||
          currentVersion !=
              _loadVersion) {
        return;
      }

      emit(
        state.copyWith(
          status:
              OrderLoadStatus.error,
          errorMessage:
              '訂單載入失敗：$error',
        ),
      );
    }
  }

  Future<void> refresh() async {
    final authState =
        _authCubit.state;

    if (!authState.isLoggedIn ||
        authState.user == null) {
      emit(
        const OrderState(
          status:
              OrderLoadStatus.ready,
        ),
      );

      return;
    }

    await _loadOrders();
  }

  void addCreatedOrder(
    Order order,
  ) {
    _replaceOrder(order);
  }

  Future<bool> cancelOrder(
    String orderId,
  ) async {
    if (isClosed ||
        state.isCancellingOrder(
          orderId,
        )) {
      return false;
    }

    final order =
        state.findById(orderId);

    if (order == null) {
      emit(
        state.copyWith(
          errorMessage:
              '找不到這筆訂單',
        ),
      );

      return false;
    }

    if (order.status !=
        OrderStatus.pendingPayment) {
      emit(
        state.copyWith(
          errorMessage:
              '只有待付款訂單可以取消',
        ),
      );

      return false;
    }

    final cancellingIds =
        Set<String>.from(
      state.cancellingOrderIds,
    )..add(orderId);

    emit(
      state.copyWith(
        cancellingOrderIds:
            Set.unmodifiable(
          cancellingIds,
        ),
        clearError: true,
      ),
    );

    try {
      final cancelledOrder =
          await _repository
              .cancelOrder(
        orderId,
      );

      if (isClosed) {
        return false;
      }

      _replaceOrder(
        cancelledOrder,
      );

      return true;
    } catch (error) {
      if (isClosed) {
        return false;
      }

      emit(
        state.copyWith(
          errorMessage:
              '取消訂單失敗：$error',
        ),
      );

      return false;
    } finally {
      if (!isClosed) {
        final nextCancellingIds =
            Set<String>.from(
          state.cancellingOrderIds,
        )..remove(orderId);

        emit(
          state.copyWith(
            cancellingOrderIds:
                Set.unmodifiable(
              nextCancellingIds,
            ),
          ),
        );
      }
    }
  }

  void _replaceOrder(
    Order order,
  ) {
    final nextOrders = <Order>[
      order,
      ...state.orders.where(
        (existingOrder) =>
            existingOrder.id !=
            order.id,
      ),
    ];

    nextOrders.sort(
      (left, right) =>
          right.createdAt.compareTo(
        left.createdAt,
      ),
    );

    emit(
      state.copyWith(
        orders:
            List.unmodifiable(
          nextOrders,
        ),
        status:
            OrderLoadStatus.ready,
        clearError: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    _loadVersion++;

    await _authSubscription?.cancel();

    await super.close();
  }
}