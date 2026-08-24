import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import '../../../auth/data/services/customer_auth_service.dart';

class PaymentCancelledException implements Exception {
  const PaymentCancelledException();
}

enum PaymentFailureType {
  missingCredential,
  paymentFailed,
  connectionFailed,
  authenticationExpired,
  invalidResponse,
  createPaymentFailed,
  confirmationFailed,
}

class PaymentFailedException implements Exception {
  const PaymentFailedException({
    required this.type,
    this.cause,
    this.statusCode,
    this.serverMessage,
  });

  final PaymentFailureType type;

  final Object? cause;

  final int? statusCode;

  final String? serverMessage;

  @override
  String toString() {
    return 'PaymentFailedException('
        'type: $type, '
        'statusCode: $statusCode, '
        'serverMessage: $serverMessage, '
        'cause: $cause'
        ')';
  }
}

abstract class PaymentService {
  Future<void> pay({required String orderId});
}

class StripePaymentService implements PaymentService {
  StripePaymentService({
    required CustomerAuthService authService,
    http.Client? client,
  }) : _authService = authService,
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final CustomerAuthService _authService;

  final http.Client _client;

  final bool _ownsClient;

  @override
  Future<void> pay({required String orderId}) async {
    try {
      final data = await _createPaymentIntent(orderId);

      if (data['alreadyPaid'] == true) {
        return;
      }

      final clientSecret = data['clientSecret'];

      if (clientSecret is! String || clientSecret.isEmpty) {
        throw const PaymentFailedException(
          type: PaymentFailureType.missingCredential,
        );
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Flutter Shopping',
          returnURL: 'flutterstripe://redirect',

          // 不在 Service 寫死中文 UI。
          // Stripe PaymentSheet 使用其原生 UI。
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
       * PaymentSheet 成功關閉後，
       * 客戶端主動要求 Node 向 Stripe
       * 查詢 PaymentIntent，
       * 並同步 PostgreSQL。
       *
       * 最終付款狀態仍然由後端決定。
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
        type: PaymentFailureType.paymentFailed,
        cause: error,
        serverMessage: error.error.localizedMessage,
      );
    } catch (error) {
      throw PaymentFailedException(
        type: PaymentFailureType.createPaymentFailed,
        cause: error,
      );
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
      fallbackType: PaymentFailureType.createPaymentFailed,
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
        throw const PaymentCancelledException();
      }

      if (paymentIntentStatus == 'requires_payment_method') {
        throw const PaymentFailedException(
          type: PaymentFailureType.paymentFailed,
        );
      }

      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 750));
      }
    }

    /*
     * 部分付款方式可能需要較長處理時間。
     * 此時不把已提交的付款當成失敗，
     * 後續仍由 webhook 完成更新。
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
      fallbackType: PaymentFailureType.confirmationFailed,
    );
  }

  Future<Map<String, dynamic>> _postOrderPaymentEndpoint({
    required String orderId,
    required String endpoint,
    required bool allowRefresh,
    required PaymentFailureType fallbackType,
  }) async {
    late final String accessToken;

    try {
      accessToken = await _authService.requireAccessToken();
    } catch (error) {
      throw PaymentFailedException(
        type: PaymentFailureType.authenticationExpired,
        cause: error,
      );
    }

    late final http.Response response;

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
    } catch (error) {
      throw PaymentFailedException(
        type: PaymentFailureType.connectionFailed,
        cause: error,
      );
    }

    if (response.statusCode == 401) {
      if (!allowRefresh) {
        throw PaymentFailedException(
          type: PaymentFailureType.authenticationExpired,
          statusCode: response.statusCode,
        );
      }

      String? refreshedToken;

      try {
        refreshedToken = await _authService.refreshAccessToken();
      } catch (error) {
        throw PaymentFailedException(
          type: PaymentFailureType.authenticationExpired,
          cause: error,
          statusCode: response.statusCode,
        );
      }

      if (refreshedToken == null || refreshedToken.isEmpty) {
        throw PaymentFailedException(
          type: PaymentFailureType.authenticationExpired,
          statusCode: response.statusCode,
        );
      }

      return _postOrderPaymentEndpoint(
        orderId: orderId,
        endpoint: endpoint,
        allowRefresh: false,
        fallbackType: fallbackType,
      );
    }

    final decoded = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final rawMessage = decoded['message'];

      throw PaymentFailedException(
        type: fallbackType,
        statusCode: response.statusCode,
        serverMessage: rawMessage is String && rawMessage.isNotEmpty
            ? rawMessage
            : null,
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
    } catch (error) {
      throw PaymentFailedException(
        type: PaymentFailureType.invalidResponse,
        cause: error,
      );
    }

    throw const PaymentFailedException(
      type: PaymentFailureType.invalidResponse,
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
