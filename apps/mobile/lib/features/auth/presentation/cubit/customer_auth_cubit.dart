import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/customer_auth_service.dart';
import 'customer_auth_state.dart';

class CustomerAuthCubit
    extends Cubit<CustomerAuthState> {
  CustomerAuthCubit({
    required CustomerAuthService authService,
  })  : _authService = authService,
        super(const CustomerAuthState());

  final CustomerAuthService _authService;

  Future<void> restoreSession() async {
    emit(
      CustomerAuthState(
        status: CustomerAuthStatus.checking,
        user: state.user,
      ),
    );

    final user = await _authService.restoreSession();

    emit(
      CustomerAuthState(
        status: user == null
            ? CustomerAuthStatus.unauthenticated
            : CustomerAuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final user = await _authService.login(
      email: email,
      password: password,
    );

    emit(
      CustomerAuthState(
        status: CustomerAuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = await _authService.register(
      name: name,
      email: email,
      password: password,
    );

    emit(
      CustomerAuthState(
        status: CustomerAuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = await _authService.uploadAvatar(
      bytes: bytes,
      fileName: fileName,
    );

    emit(
      CustomerAuthState(
        status: CustomerAuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> removeAvatar() async {
    final user = await _authService.removeAvatar();

    emit(
      CustomerAuthState(
        status: CustomerAuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> logout() async {
    emit(
      CustomerAuthState(
        status: CustomerAuthStatus.checking,
        user: state.user,
      ),
    );

    await _authService.logout();

    emit(
      const CustomerAuthState(
        status: CustomerAuthStatus.unauthenticated,
      ),
    );
  }
}
