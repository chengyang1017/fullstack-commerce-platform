import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/address.dart';
import '../models/order.dart';

abstract class OrderService {
  Stream<List<Order>> watchOrders(String userId);

  Future<void> createOrder(Order order);
}

class FirestoreOrderService implements OrderService {
  final FirebaseFirestore _firestore;

  FirestoreOrderService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders {
    return _firestore.collection('orders');
  }

  @override
  Stream<List<Order>> watchOrders(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(_fromDocument).toList(growable: false);
        });
  }

  

  @override
  Future<void> createOrder(Order order) async {
    final userId = order.userId;

    if (userId == null || userId.isEmpty) {
      throw StateError('建立訂單時缺少 userId');
    }

    await _orders.doc(order.id).set({
      'userId': userId,

      'status': order.status.name,
      'paymentStatus': order.status == OrderStatus.pendingPayment
          ? 'unpaid'
          : 'cashOnDelivery',

      'currency': 'myr',

      // Flutter 頁面顯示使用。
      'subtotal': order.subtotal,
      'shippingFee': order.shippingFee,
      'discount': order.discount,
      'total': order.total,

      // Stripe 後端使用，單位是 sen。
      'subtotalMinor': _toMinor(order.subtotal),
      'shippingFeeMinor': _toMinor(order.shippingFee),
      'discountMinor': _toMinor(order.discount),
      'totalMinor': _toMinor(order.total),

      'shippingMethod': order.shippingMethod.name,

      'paymentMethod': order.paymentMethod.name,

      'address': order.address.toJson(),

      'items': order.items.map((item) => item.toJson()).toList(growable: false),

      'paymentIntentId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Order _fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();

    final rawItems = data['items'] as List<dynamic>? ?? const [];

    final rawAddress = data['address'] as Map<dynamic, dynamic>? ?? const {};

    return Order(
      id: document.id,
      userId: data['userId'] as String?,
      address: Address.fromJson(Map<String, dynamic>.from(rawAddress)),
      items: rawItems
          .map((rawItem) {
            return OrderItem.fromJson(
              Map<String, dynamic>.from(rawItem as Map),
            );
          })
          .toList(growable: false),
      shippingMethod: _parseShippingMethod(data['shippingMethod']),
      paymentMethod: _parsePaymentMethod(data['paymentMethod']),
      status: data['paymentStatus'] == 'paid'
    ? OrderStatus.processing
    : _parseOrderStatus(
        data['status'],
      ),
      subtotal: _readMoney(
        data,
        valueKey: 'subtotal',
        minorKey: 'subtotalMinor',
      ),
      shippingFee: _readMoney(
        data,
        valueKey: 'shippingFee',
        minorKey: 'shippingFeeMinor',
      ),
      discount: _readMoney(
        data,
        valueKey: 'discount',
        minorKey: 'discountMinor',
      ),
      total: _readMoney(data, valueKey: 'total', minorKey: 'totalMinor'),
      createdAt: _readDateTime(data['createdAt']),
    );
  }

  int _toMinor(double value) {
    return (value * 100).round();
  }

  double _readMoney(
    Map<String, dynamic> data, {
    required String valueKey,
    required String minorKey,
  }) {
    final value = data[valueKey];

    if (value is num) {
      return value.toDouble();
    }

    final minor = data[minorKey];

    if (minor is num) {
      return minor.toDouble() / 100;
    }

    return 0;
  }

  DateTime _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }

  OrderStatus _parseOrderStatus(Object? value) {
    if (value == 'paid') {
      return OrderStatus.processing;
    }

    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.pendingPayment,
    );
  }

  ShippingMethod _parseShippingMethod(Object? value) {
    return ShippingMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => ShippingMethod.standard,
    );
  }

  PaymentMethod _parsePaymentMethod(Object? value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => PaymentMethod.onlineBanking,
    );
  }
}
