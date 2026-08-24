import '../../../address/domain/models/address.dart';
import '../../../cart/domain/models/cart_item.dart';

enum OrderStatus {
  pendingPayment,
  paid,
  processing,
  shipped,
  delivered,
  completed,
  cancelled,
  refunded,
}

enum OrderPaymentStatus {
  unpaid,
  processing,
  paid,
  failed,
  refunded,
  partiallyRefunded,
}

enum ShippingMethod { standard, express }

enum PaymentMethod { onlineBanking, card, cashOnDelivery }

extension ShippingMethodDetails on ShippingMethod {
  double get fee {
    switch (this) {
      case ShippingMethod.standard:
        return 5;

      case ShippingMethod.express:
        return 15;
    }
  }

  String get apiValue {
    switch (this) {
      case ShippingMethod.standard:
        return 'STANDARD';

      case ShippingMethod.express:
        return 'EXPRESS';
    }
  }
}

extension PaymentMethodDetails on PaymentMethod {
  String get apiValue {
    switch (this) {
      case PaymentMethod.onlineBanking:
        return 'ONLINE_BANKING';

      case PaymentMethod.card:
        return 'CARD';

      case PaymentMethod.cashOnDelivery:
        return 'CASH_ON_DELIVERY';
    }
  }
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.unitPrice,
    required this.quantity,
  });

  final String productId;
  final String productTitle;
  final String productImage;
  final double unitPrice;
  final int quantity;

  double get subtotal {
    return unitPrice * quantity;
  }

  factory OrderItem.fromCartItem(CartItem item) {
    return OrderItem(
      productId: item.product.id,
      productTitle: item.product.title,
      productImage: item.product.image,
      unitPrice: item.product.price,
      quantity: item.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'unitPrice': unitPrice,
      'quantity': quantity,
    };
  }

  Map<String, dynamic> toCreateOrderJson() {
    return {'productId': productId, 'quantity': quantity};
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: _readRequiredString(json, 'productId'),
      productTitle: _readRequiredString(json, 'productTitle'),
      productImage:
          _readOptionalString(json, 'productImage') ??
          _readOptionalString(json, 'productImageUrl') ??
          '',
      unitPrice: _readMoney(
        json,
        valueKey: 'unitPrice',
        minorKey: 'unitPriceMinor',
      ),
      quantity: _readRequiredInt(json, 'quantity'),
    );
  }
}

class Order {
  const Order({
    required this.id,
    this.orderNumber = '',
    this.userId,
    required this.address,
    required this.items,
    required this.shippingMethod,
    required this.paymentMethod,
    required this.status,
    this.paymentStatus = OrderPaymentStatus.unpaid,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final String? userId;
  final Address address;
  final List<OrderItem> items;
  final ShippingMethod shippingMethod;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final OrderPaymentStatus paymentStatus;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final DateTime createdAt;

  String get displayNumber {
    return orderNumber.isEmpty ? id : orderNumber;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'userId': userId,
      'address': address.toJson(),
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'shippingMethod': shippingMethod.name,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateOrderJson() {
    return {
      'items': items
          .map((item) => item.toCreateOrderJson())
          .toList(growable: false),
      'shippingMethod': shippingMethod.apiValue,
      'paymentMethod': paymentMethod.apiValue,
      'recipientName': address.receiverName,
      'recipientPhone': address.phone,
      'addressLine1': address.addressLine,
      'city': address.city,
      'state': address.state,
      'postalCode': address.postcode,
      'countryCode': _toCountryCode(address.country),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final id = _readRequiredString(json, 'id');

    final rawItems = json['items'];

    if (rawItems is! List) {
      throw const FormatException('Invalid order item data');
    }

    final address = json['address'] is Map
        ? Address.fromJson(Map<String, dynamic>.from(json['address'] as Map))
        : Address(
            id: 'order_address_$id',
            receiverName: _readRequiredString(json, 'recipientName'),
            phone: _readRequiredString(json, 'recipientPhone'),
            addressLine: _joinAddressLines(
              _readRequiredString(json, 'addressLine1'),
              _readOptionalString(json, 'addressLine2'),
            ),
            city: _readRequiredString(json, 'city'),
            state: _readRequiredString(json, 'state'),
            postcode: _readRequiredString(json, 'postalCode'),
            country: _readOptionalString(json, 'countryCode') ?? 'MY',
          );

    return Order(
      id: id,
      orderNumber: _readOptionalString(json, 'orderNumber') ?? id,
      userId: _readOptionalString(json, 'userId'),
      address: address,
      items: rawItems
          .map(
            (item) =>
                OrderItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      shippingMethod: _parseShippingMethod(json['shippingMethod']),
      paymentMethod: _parsePaymentMethod(json['paymentMethod']),
      status: _parseOrderStatus(json['status']),
      paymentStatus: _parsePaymentStatus(json['paymentStatus']),
      subtotal: _readMoney(
        json,
        valueKey: 'subtotal',
        minorKey: 'subtotalMinor',
      ),
      shippingFee: _readMoney(
        json,
        valueKey: 'shippingFee',
        minorKey: 'shippingMinor',
      ),
      discount: _readMoney(
        json,
        valueKey: 'discount',
        minorKey: 'discountMinor',
      ),
      total: _readMoney(json, valueKey: 'total', minorKey: 'totalMinor'),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    String? userId,
    Address? address,
    List<OrderItem>? items,
    ShippingMethod? shippingMethod,
    PaymentMethod? paymentMethod,
    OrderStatus? status,
    OrderPaymentStatus? paymentStatus,
    double? subtotal,
    double? shippingFee,
    double? discount,
    double? total,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      address: address ?? this.address,
      items: items ?? this.items,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is String && value.isNotEmpty) {
    return value;
  }

  throw FormatException('Missing order field: $key');
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is String && value.isNotEmpty) {
    return value;
  }

  return null;
}

int _readRequiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is num) {
    return value.toInt();
  }

  throw FormatException('Missing numeric order field: $key');
}

double _readMoney(
  Map<String, dynamic> json, {
  required String valueKey,
  required String minorKey,
}) {
  final value = json[valueKey];

  if (value is num) {
    return value.toDouble();
  }

  final minorValue = json[minorKey];

  if (minorValue is num) {
    return minorValue.toDouble() / 100;
  }

  return 0;
}

DateTime _readDateTime(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
  }

  return DateTime.now();
}

ShippingMethod _parseShippingMethod(Object? value) {
  switch (value) {
    case 'EXPRESS':
    case 'express':
      return ShippingMethod.express;

    case 'STANDARD':
    case 'standard':
    default:
      return ShippingMethod.standard;
  }
}

PaymentMethod _parsePaymentMethod(Object? value) {
  switch (value) {
    case 'CARD':
    case 'card':
      return PaymentMethod.card;

    case 'CASH_ON_DELIVERY':
    case 'cashOnDelivery':
      return PaymentMethod.cashOnDelivery;

    case 'ONLINE_BANKING':
    case 'onlineBanking':
    default:
      return PaymentMethod.onlineBanking;
  }
}

OrderStatus _parseOrderStatus(Object? value) {
  switch (value) {
    case 'PAID':
    case 'paid':
      return OrderStatus.paid;

    case 'PROCESSING':
    case 'processing':
      return OrderStatus.processing;

    case 'SHIPPED':
    case 'shipped':
      return OrderStatus.shipped;

    case 'DELIVERED':
    case 'delivered':
      return OrderStatus.delivered;

    case 'COMPLETED':
    case 'completed':
      return OrderStatus.completed;

    case 'CANCELLED':
    case 'cancelled':
      return OrderStatus.cancelled;

    case 'REFUNDED':
    case 'refunded':
      return OrderStatus.refunded;

    case 'PENDING_PAYMENT':
    case 'pendingPayment':
    default:
      return OrderStatus.pendingPayment;
  }
}

OrderPaymentStatus _parsePaymentStatus(Object? value) {
  switch (value) {
    case 'PROCESSING':
    case 'processing':
      return OrderPaymentStatus.processing;

    case 'PAID':
    case 'paid':
      return OrderPaymentStatus.paid;

    case 'FAILED':
    case 'failed':
      return OrderPaymentStatus.failed;

    case 'REFUNDED':
    case 'refunded':
      return OrderPaymentStatus.refunded;

    case 'PARTIALLY_REFUNDED':
    case 'partiallyRefunded':
      return OrderPaymentStatus.partiallyRefunded;

    case 'UNPAID':
    case 'unpaid':
    default:
      return OrderPaymentStatus.unpaid;
  }
}

String _joinAddressLines(String addressLine1, String? addressLine2) {
  final secondLine = addressLine2?.trim();

  if (secondLine == null || secondLine.isEmpty) {
    return addressLine1;
  }

  return '$addressLine1, $secondLine';
}

String _toCountryCode(String country) {
  final normalized = country.trim().toUpperCase();

  if (RegExp(r'^[A-Z]{2}$').hasMatch(normalized)) {
    return normalized;
  }

  if (normalized == 'MALAYSIA' ||
      country.trim() == '馬來西亞' ||
      country.trim() == '马来西亚') {
    return 'MY';
  }

  return 'MY';
}
