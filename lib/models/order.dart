import 'address.dart';
import 'cart_item.dart';

enum OrderStatus {
  pendingPayment,
  paid,
  processing,
  shipped,
  delivered,
  completed,
  cancelled,
}

enum ShippingMethod { standard, express }

enum PaymentMethod { onlineBanking, card, cashOnDelivery }

extension ShippingMethodDetails on ShippingMethod {
  String get title {
    switch (this) {
      case ShippingMethod.standard:
        return '標準配送';
      case ShippingMethod.express:
        return '快速配送';
    }
  }

  String get description {
    switch (this) {
      case ShippingMethod.standard:
        return '預計 3 至 5 天送達';
      case ShippingMethod.express:
        return '預計 1 至 2 天送達';
    }
  }

  double get fee {
    switch (this) {
      case ShippingMethod.standard:
        return 5;
      case ShippingMethod.express:
        return 15;
    }
  }
}

extension PaymentMethodDetails on PaymentMethod {
  String get title {
    switch (this) {
      case PaymentMethod.onlineBanking:
        return '網上銀行';
      case PaymentMethod.card:
        return '信用卡／簽帳卡';
      case PaymentMethod.cashOnDelivery:
        return '貨到付款';
    }
  }
}

class OrderItem {
  final String productId;
  final String productTitle;
  final String productImage;
  final double unitPrice;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.unitPrice,
    required this.quantity,
  });

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

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      productTitle: json['productTitle'] as String,
      productImage: json['productImage'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
    );
  }
}

class Order {
  final String id;
  final String? userId;
  final Address address;
  final List<OrderItem> items;
  final ShippingMethod shippingMethod;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final DateTime createdAt;

  const Order({
    required this.id,
    this.userId,
    required this.address,
    required this.items,
    required this.shippingMethod,
    required this.paymentMethod,
    required this.status,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'address': address.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'shippingMethod': shippingMethod.name,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      address: Address.fromJson(
        Map<String, dynamic>.from(json['address'] as Map),
      ),
      items: (json['items'] as List)
          .map(
            (item) =>
                OrderItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      shippingMethod: ShippingMethod.values.byName(
        json['shippingMethod'] as String,
      ),
      paymentMethod: PaymentMethod.values.byName(
        json['paymentMethod'] as String,
      ),
      status: OrderStatus.values.byName(json['status'] as String),
      subtotal: (json['subtotal'] as num).toDouble(),
      shippingFee: (json['shippingFee'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Order copyWith({
    String? id,
    String? userId,
    Address? address,
    List<OrderItem>? items,
    ShippingMethod? shippingMethod,
    PaymentMethod? paymentMethod,
    OrderStatus? status,
    double? subtotal,
    double? shippingFee,
    double? discount,
    double? total,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      address: address ?? this.address,
      items: items ?? this.items,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension OrderStatusDetails on OrderStatus {
  String get title {
    switch (this) {
      case OrderStatus.pendingPayment:
        return '待付款';
      case OrderStatus.paid:
        return '已付款';
      case OrderStatus.processing:
        return '處理中';
      case OrderStatus.shipped:
        return '已出貨';
      case OrderStatus.delivered:
        return '已送達';
      case OrderStatus.completed:
        return '已完成';
      case OrderStatus.cancelled:
        return '已取消';
    }
  }
}
