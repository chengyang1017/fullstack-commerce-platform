import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/auth/customer_auth_cubit.dart';
import '../cubits/cart/cart_cubit.dart';
import '../cubits/locale/locale_cubit.dart';
import '../cubits/order/order_cubit.dart';
import '../cubits/product/product_cubit.dart';
import '../cubits/theme/theme_mode_cubit.dart';
import '../repositories/address_repository.dart';
import '../repositories/cart_repository.dart';
import '../repositories/locale_preferences_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/theme_preferences_repository.dart';
import '../services/address_service.dart';
import '../services/cart_service.dart';
import '../services/customer_auth_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import 'app_view.dart';

class ShoppingApp extends StatelessWidget {
  const ShoppingApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<
            CustomerAuthService>(
          create: (_) {
            return CustomerAuthService();
          },
          dispose: (service) {
            service.dispose();
          },
        ),

        RepositoryProvider<
            CartRepository>(
          create: (_) {
            return CartRepository(
              service:
                  LocalCartService(),
            );
          },
        ),

        RepositoryProvider<
            AddressRepository>(
          create: (_) {
            return AddressRepository(
              service:
                  LocalAddressService(),
            );
          },
        ),

        RepositoryProvider<
            OrderRepository>(
          create: (context) {
            return OrderRepository(
              ApiOrderService(
                authService:
                    context.read<
                        CustomerAuthService>(),
              ),
            );
          },
          dispose: (repository) {
            repository.dispose();
          },
        ),

        RepositoryProvider<
            PaymentRepository>(
          create: (context) {
            return PaymentRepository(
              StripePaymentService(
                authService:
                    context.read<
                        CustomerAuthService>(),
              ),
            );
          },
        ),

        RepositoryProvider<
            ProductRepository>(
          create: (_) {
            return ApiProductRepository();
          },
          dispose: (repository) {
            if (repository
                is ApiProductRepository) {
              repository.dispose();
            }
          },
        ),

        RepositoryProvider<
            ThemePreferencesRepository>(
          create: (_) {
            return ThemePreferencesRepository();
          },
        ),

        RepositoryProvider<
            LocalePreferencesRepository>(
          create: (_) {
            return LocalePreferencesRepository();
          },
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeModeCubit>(
            create: (context) {
              return ThemeModeCubit(
                repository:
                    context.read<
                        ThemePreferencesRepository>(),
              )..loadThemeMode();
            },
          ),

          BlocProvider<LocaleCubit>(
            create: (context) {
              return LocaleCubit(
                repository:
                    context.read<
                        LocalePreferencesRepository>(),
              )..loadLocale();
            },
          ),

          BlocProvider<
              CustomerAuthCubit>(
            create: (context) {
              return CustomerAuthCubit(
                authService:
                    context.read<
                        CustomerAuthService>(),
              )..restoreSession();
            },
          ),

          BlocProvider<OrderCubit>(
            create: (context) {
              return OrderCubit(
                repository:
                    context.read<
                        OrderRepository>(),
                authCubit:
                    context.read<
                        CustomerAuthCubit>(),
              )..start();
            },
          ),

          BlocProvider<CartCubit>(
            create: (context) {
              return CartCubit(
                repository:
                    context.read<
                        CartRepository>(),
              )..loadCart();
            },
          ),

          BlocProvider<ProductCubit>(
            create: (context) {
              return ProductCubit(
                productRepository:
                    context.read<
                        ProductRepository>(),
              )..loadProducts();
            },
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}