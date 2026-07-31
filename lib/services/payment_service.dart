import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart'
    show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentCancelledException implements Exception {
  const PaymentCancelledException();
}

class PaymentFailedException implements Exception {
  final String message;

  const PaymentFailedException(this.message);

  @override
  String toString() => message;
}

abstract class PaymentService {
  Future<void> pay({required String orderId});
}

class StripePaymentService implements PaymentService {
  final FirebaseFunctions _functions;

  StripePaymentService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  @override
  Future<void> pay({required String orderId}) async {
    try {
      final callable = _functions.httpsCallable('createStripePayment');

      final result = await callable.call<Map<String, dynamic>>({
        'orderId': orderId,
      });

      final data = Map<String, dynamic>.from(result.data);

      if (data['alreadyPaid'] == true) {
        return;
      }

      final clientSecret = data['clientSecret'] as String?;

      if (clientSecret == null || clientSecret.isEmpty) {
        throw const PaymentFailedException('後端沒有返回付款憑證');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Flutter Shopping',
          returnURL: 'flutterstripe://redirect',
          primaryButtonLabel: '確認付款',
          style: ThemeMode.system,

          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'MY',
            currencyCode: 'MYR',

            /*
             * 測試模式為 true。
             * Stripe 切換 live key 後改為 false。
             */
            testEnv: true,
          ),

          billingDetailsCollectionConfiguration:
              const BillingDetailsCollectionConfiguration(
                name: CollectionMode.always,
                email: CollectionMode.always,
                phone: CollectionMode.automatic,
                address: AddressCollectionMode.automatic,
              ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      /*
       * 注意：
       * 這裡只能表示 PaymentSheet 流程完成。
       * 不可以在這裡把 Order 改成 paid。
       * 真正狀態由 webhook 更新。
       */
    } on StripeException catch (error) {
      if (error.error.code == FailureCode.Canceled) {
        throw const PaymentCancelledException();
      }

      throw PaymentFailedException(
        error.error.localizedMessage ?? 'Stripe 付款失敗',
      );
    } on FirebaseFunctionsException catch (error) {
      throw PaymentFailedException(error.message ?? '無法建立付款');
    }
  }
}
