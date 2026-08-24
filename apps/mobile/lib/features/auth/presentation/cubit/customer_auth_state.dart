import '../../domain/models/customer_user.dart';

enum CustomerAuthStatus {
  checking,
  authenticated,
  unauthenticated,
}

class CustomerAuthState {
  const CustomerAuthState({
    this.status = CustomerAuthStatus.checking,
    this.user,
  });

  final CustomerAuthStatus status;
  final CustomerUser? user;

  bool get isLoggedIn {
    return status ==
        CustomerAuthStatus.authenticated;
  }
}