import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/customer_auth_cubit.dart';
import '../../cubits/auth/customer_auth_state.dart';
import '../main_page.dart';
import 'customer_login_page.dart';

class CustomerAuthGate extends StatelessWidget {
  const CustomerAuthGate({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      CustomerAuthCubit,
      CustomerAuthState
    >(
      buildWhen: (
        previous,
        current,
      ) {
        return previous.status !=
            current.status;
      },
      builder: (
        context,
        state,
      ) {
        switch (state.status) {
          case CustomerAuthStatus.checking:
            return const Scaffold(
              body: Center(
                child:
                    CircularProgressIndicator(),
              ),
            );

          case CustomerAuthStatus
                .authenticated:
            return const MainPage();

          case CustomerAuthStatus
                .unauthenticated:
            return const CustomerLoginPage();
        }
      },
    );
  }
}