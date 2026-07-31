import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'repositories/address_repository.dart';
import 'repositories/cart_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/payment_repository.dart';
import 'screens/main_page.dart';
import 'services/address_service.dart';
import 'services/cart_service.dart';
import 'services/order_service.dart';
import 'services/payment_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final auth = FirebaseAuth.instance;

  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }

  debugPrint(
    '目前 Firebase UID：${auth.currentUser?.uid}',
  );

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

  final cartRepository = CartRepository(
    service: LocalCartService(),
  );

  final addressRepository =
      AddressRepository(
    service: LocalAddressService(),
  );

  final orderRepository = OrderRepository(
    FirestoreOrderService(),
  );

  final paymentRepository =
      PaymentRepository(
    StripePaymentService(),
  );

  runApp(
    MyApp(
      cartRepository: cartRepository,
      addressRepository:
          addressRepository,
      orderRepository: orderRepository,
      paymentRepository:
          paymentRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final CartRepository cartRepository;
  final AddressRepository
      addressRepository;
  final OrderRepository orderRepository;
  final PaymentRepository
      paymentRepository;

  const MyApp({
    super.key,
    required this.cartRepository,
    required this.addressRepository,
    required this.orderRepository,
    required this.paymentRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AddressRepository>.value(
          value: addressRepository,
        ),
        Provider<OrderRepository>.value(
          value: orderRepository,
        ),
        Provider<PaymentRepository>.value(
          value: paymentRepository,
        ),
        ChangeNotifierProvider(
          create: (context) {
            return CartProvider(
              repository: cartRepository,
            )..loadCart();
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            return OrderProvider(
              orderRepository,
            )..start();
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Shopping App',
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(
            seedColor: Colors.blue,
          ),
          useMaterial3: true,
        ),
        home: const MainPage(),
      ),
    );
  }
}