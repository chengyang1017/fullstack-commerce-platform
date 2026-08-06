import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import 'customer_auth_service.dart';

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
  final CustomerAuthService _authService;
  final http.Client _client;
  final bool _ownsClient;

  StripePaymentService({
    required CustomerAuthService authService,
    http.Client? client,
  }) : _authService = authService,
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  @override
  Future<void> pay({required String orderId}) async {
    try {
      final data = await _createPaymentIntent(orderId);

      if (data['alreadyPaid'] == true) {
        return;
      }

      final clientSecret = data['clientSecret'];

      if (clientSecret is! String || clientSecret.isEmpty) {
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
       * PaymentSheet 成功關閉後，客戶端主動要求 Node
       * 向 Stripe 查詢 PaymentIntent，並同步 PostgreSQL。
       * 即使本地 webhook 沒有及時轉發，使用者也不用再點一次付款。
       */
      await _waitForPaymentConfirmation(orderId);
    } on PaymentCancelledException {
      rethrow;
    } on PaymentFailedException {
      rethrow;
    } on StripeException catch (error) {
      if (error.error.code == FailureCode.Canceled) {
        throw const PaymentCancelledException();
      }

      throw PaymentFailedException(
        error.error.localizedMessage ?? 'Stripe 付款失敗',
      );
    } catch (error) {
      throw PaymentFailedException('無法建立付款：$error');
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(
    String orderId, {
    bool allowRefresh = true,
  }) {
    return _postOrderPaymentEndpoint(
      orderId: orderId,
      endpoint: 'payment-intent',
      allowRefresh: allowRefresh,
      fallbackMessage: '無法建立付款',
    );
  }

  Future<void> _waitForPaymentConfirmation(String orderId) async {
    const maxAttempts = 12;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final data = await _syncPaymentStatus(orderId);

      if (data['paid'] == true) {
        return;
      }

      final paymentIntentStatus = data['paymentIntentStatus'];

      if (paymentIntentStatus == 'canceled') {
        throw const PaymentFailedException('付款已取消');
      }

      if (paymentIntentStatus == 'requires_payment_method') {
        throw const PaymentFailedException('付款失敗，請更換付款方式');
      }

      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(
          const Duration(milliseconds: 750),
        );
      }
    }

    /*
     * 部分付款方式可能需要較長處理時間。
     * 此時不把已提交的付款當成失敗，後續仍由 webhook 完成更新。
     */
  }

  Future<Map<String, dynamic>> _syncPaymentStatus(
    String orderId, {
    bool allowRefresh = true,
  }) {
    return _postOrderPaymentEndpoint(
      orderId: orderId,
      endpoint: 'payment-sync',
      allowRefresh: allowRefresh,
      fallbackMessage: '無法確認付款結果',
    );
  }

  Future<Map<String, dynamic>> _postOrderPaymentEndpoint({
    required String orderId,
    required String endpoint,
    required bool allowRefresh,
    required String fallbackMessage,
  }) async {
    final accessToken = await _authService.requireAccessToken();

    http.Response response;

    try {
      response = await _client.post(
        Uri.parse(
          '${_authService.baseUrl}'
          '/api/customer/orders/'
          '$orderId/$endpoint',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(const <String, dynamic>{}),
      );
    } catch (_) {
      throw const PaymentFailedException(
        '無法連接服務器，請檢查網絡和後端服務',
      );
    }

    if (response.statusCode == 401 && allowRefresh) {
      final refreshedToken = await _authService.refreshAccessToken();

      if (refreshedToken == null || refreshedToken.isEmpty) {
        throw const PaymentFailedException('登入已失效，請重新登入');
      }

      return _postOrderPaymentEndpoint(
        orderId: orderId,
        endpoint: endpoint,
        allowRefresh: false,
        fallbackMessage: fallbackMessage,
      );
    }

    final decoded = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['message'];

      throw PaymentFailedException(
        message is String && message.isNotEmpty
            ? message
            : fallbackMessage,
      );
    }

    return decoded;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      throw const PaymentFailedException('服務器返回格式無效');
    }

    throw const PaymentFailedException('服務器返回格式無效');
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
