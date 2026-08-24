import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'cubits/auth/customer_auth_cubit.dart';
import 'cubits/cart/cart_cubit.dart';
import 'cubits/order/order_cubit.dart';
import 'cubits/product/product_cubit.dart';
import 'repositories/address_repository.dart';
import 'repositories/cart_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/payment_repository.dart';
import 'repositories/product_repository.dart';
import 'screens/auth/customer_auth_gate.dart';
import 'services/address_service.dart';
import 'services/cart_service.dart';
import 'services/customer_auth_service.dart';
import 'services/order_service.dart';
import 'services/payment_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const stripePublishableKey =
      String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );

  if (stripePublishableKey.isEmpty) {
    throw StateError(
      '缺少 STRIPE_PUBLISHABLE_KEY',
    );
  }

  Stripe.publishableKey =
      stripePublishableKey;

  Stripe.urlScheme = 'flutterstripe';

  await Stripe.instance.applySettings();

  final customerAuthService =
      CustomerAuthService();

  final cartRepository =
      CartRepository(
    service: LocalCartService(),
  );

  final addressRepository =
      AddressRepository(
    service: LocalAddressService(),
  );

  final paymentRepository =
      PaymentRepository(
    StripePaymentService(
      authService: customerAuthService,
    ),
  );

  runApp(
    MyApp(
      customerAuthService:
          customerAuthService,
      cartRepository:
          cartRepository,
      addressRepository:
          addressRepository,
      paymentRepository:
          paymentRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final CustomerAuthService
      customerAuthService;

  final CartRepository
      cartRepository;

  final AddressRepository
      addressRepository;

  final PaymentRepository
      paymentRepository;

  const MyApp({
    super.key,
    required this.customerAuthService,
    required this.cartRepository,
    required this.addressRepository,
    required this.paymentRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<
            CustomerAuthService>(
          create: (_) {
            return customerAuthService;
          },
          dispose: (service) {
            service.dispose();
          },
        ),

        RepositoryProvider<
            AddressRepository>.value(
          value: addressRepository,
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
            PaymentRepository>.value(
          value: paymentRepository,
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
      ],
      child: MultiBlocProvider(
        providers: [
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
            create: (_) {
              return CartCubit(
                repository:
                    cartRepository,
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
        child: MaterialApp(
          debugShowCheckedModeBanner:
              false,
          title: 'Shopping App',
          theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(
              seedColor: Colors.blue,
            ),
            useMaterial3: true,
          ),
          home:
              const CustomerAuthGate(),
        ),
      ),
    );
  }
}