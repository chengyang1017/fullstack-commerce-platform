import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app/app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  const stripePublishableKey =
      String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  if (stripePublishableKey.isNotEmpty) {
    try {
      Stripe.publishableKey = stripePublishableKey;
      Stripe.urlScheme = 'flutterstripe';
      await Stripe.instance.applySettings();
    } catch (error, stackTrace) {
      developer.log(
        'Stripe initialization failed. The app will continue without payments.',
        name: 'bootstrap',
        error: error,
        stackTrace: stackTrace,
      );
    }
  } else {
    developer.log(
      'STRIPE_PUBLISHABLE_KEY is missing. The app will continue without payments.',
      name: 'bootstrap',
    );
  }

  runApp(const ShoppingApp());
}
