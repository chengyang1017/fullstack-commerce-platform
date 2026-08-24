import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app/app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  const stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  if (stripePublishableKey.isEmpty) {
    throw StateError('Missing STRIPE_PUBLISHABLE_KEY');
  }

  Stripe.publishableKey = stripePublishableKey;

  Stripe.urlScheme = 'flutterstripe';

  await Stripe.instance.applySettings();

  runApp(const ShoppingApp());
}
