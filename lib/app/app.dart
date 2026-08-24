import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/cubit/customer_auth_cubit.dart';
import '../features/cart/presentation/cubit/cart_cubit.dart';
import '../core/settings/locale/locale_cubit.dart';
import '../features/order/presentation/cubit/order_cubit.dart';
import '../features/product/presentation/cubit/product_cubit.dart';
import '../core/settings/theme/theme_mode_cubit.dart';
import '../features/address/data/repositories/address_repository.dart';
import '../features/cart/data/repositories/cart_repository.dart';
import '../core/settings/locale/locale_preferences_repository.dart';
import '../features/order/data/repositories/order_repository.dart';
import '../features/payment/data/repositories/payment_repository.dart';
import '../features/product/data/repositories/product_repository.dart';
import '../core/settings/theme/theme_preferences_repository.dart';
import '../features/address/data/services/address_service.dart';
import '../features/cart/data/services/cart_service.dart';
import '../features/auth/data/services/customer_auth_service.dart';
import '../features/order/data/services/order_service.dart';
import '../features/payment/data/services/payment_service.dart';
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