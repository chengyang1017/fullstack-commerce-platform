import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'providers/customer_auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
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

  const stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  if (stripePublishableKey.isEmpty) {
    throw StateError('缺少 STRIPE_PUBLISHABLE_KEY');
  }

  Stripe.publishableKey = stripePublishableKey;
  Stripe.urlScheme = 'flutterstripe';

  await Stripe.instance.applySettings();

  final customerAuthService = CustomerAuthService();

  final cartRepository = CartRepository(service: LocalCartService());

  final addressRepository = AddressRepository(service: LocalAddressService());

  final paymentRepository = PaymentRepository(
    StripePaymentService(authService: customerAuthService),
  );

  runApp(
    MyApp(
      customerAuthService: customerAuthService,
      cartRepository: cartRepository,
      addressRepository: addressRepository,
      paymentRepository: paymentRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final CustomerAuthService customerAuthService;
  final CartRepository cartRepository;
  final AddressRepository addressRepository;
  final PaymentRepository paymentRepository;

  const MyApp({
    super.key,
    required this.customerAuthService,
    required this.cartRepository,
    required this.addressRepository,
    required this.paymentRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CustomerAuthService>(
          create: (_) => customerAuthService,
          dispose: (_, service) => service.dispose(),
        ),

        ChangeNotifierProvider<CustomerAuthProvider>(
          create: (context) {
            return CustomerAuthProvider(context.read<CustomerAuthService>())
              ..restoreSession();
          },
        ),

        Provider<AddressRepository>.value(value: addressRepository),

        Provider<OrderRepository>(
          create: (context) {
            return OrderRepository(
              ApiOrderService(authService: context.read<CustomerAuthService>()),
            );
          },
          dispose: (_, repository) => repository.dispose(),
        ),

        Provider<PaymentRepository>.value(value: paymentRepository),

        Provider<ProductRepository>(
          create: (_) {
            return ApiProductRepository();
          },
          dispose: (_, repository) {
            if (repository is ApiProductRepository) {
              repository.dispose();
            }
          },
        ),

        ChangeNotifierProvider<CartProvider>(
          create: (_) {
            return CartProvider(repository: cartRepository)..loadCart();
          },
        ),

        ChangeNotifierProvider<OrderProvider>(
          create: (context) {
            return OrderProvider(
              context.read<OrderRepository>(),
              context.read<CustomerAuthProvider>(),
            )..start();
          },
        ),

        ChangeNotifierProvider<ProductProvider>(
          create: (context) {
            return ProductProvider(
              productRepository: context.read<ProductRepository>(),
            )..loadProducts();
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Shopping App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const CustomerAuthGate(),
      ),
    );
  }
}
