import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_auth_provider.dart';
import '../main_page.dart';
import 'customer_login_page.dart';

class CustomerAuthGate extends StatelessWidget {
  const CustomerAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select(
      (CustomerAuthProvider provider) => provider.status,
    );

    switch (status) {
      case CustomerAuthStatus.checking:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case CustomerAuthStatus.authenticated:
        return const MainPage();

      case CustomerAuthStatus.unauthenticated:
        return const CustomerLoginPage();
    }
  }
}
