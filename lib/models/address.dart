class Address {
  final String id;
  final String receiverName;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final bool isDefault;

  const Address({
    required this.id,
    required this.receiverName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    this.isDefault = false,
  });

  String get fullAddress {
    return '$addressLine, $postcode $city, '
        '$state, $country';
  }

  Address copyWith({
    String? id,
    String? receiverName,
    String? phone,
    String? addressLine,
    String? city,
    String? state,
    String? postcode,
    String? country,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      receiverName: receiverName ?? this.receiverName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiverName': receiverName,
      'phone': phone,
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'isDefault': isDefault,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      receiverName: json['receiverName'] as String,
      phone: json['phone'] as String,
      addressLine: json['addressLine'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      postcode: json['postcode'] as String,
      country: json['country'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
