import 'package:flutter/foundation.dart';

import '../models/customer_user.dart';
import '../services/customer_auth_service.dart';

enum CustomerAuthStatus { checking, authenticated, unauthenticated }

class CustomerAuthProvider extends ChangeNotifier {
  final CustomerAuthService _authService;

  CustomerAuthStatus _status = CustomerAuthStatus.checking;

  CustomerUser? _user;

  CustomerAuthProvider(this._authService);

  CustomerAuthStatus get status => _status;

  CustomerUser? get user => _user;

  bool get isLoggedIn => _status == CustomerAuthStatus.authenticated;

  Future<void> restoreSession() async {
    _status = CustomerAuthStatus.checking;

    notifyListeners();

    final user = await _authService.restoreSession();

    _user = user;

    _status = user == null
        ? CustomerAuthStatus.unauthenticated
        : CustomerAuthStatus.authenticated;

    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final user = await _authService.login(email: email, password: password);

    _user = user;

    _status = CustomerAuthStatus.authenticated;

    notifyListeners();
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

    _user = user;

    _status = CustomerAuthStatus.authenticated;

    notifyListeners();
  }

  Future<void> logout() async {
    _status = CustomerAuthStatus.checking;

    notifyListeners();

    await _authService.logout();

    _user = null;

    _status = CustomerAuthStatus.unauthenticated;

    notifyListeners();
  }
}
