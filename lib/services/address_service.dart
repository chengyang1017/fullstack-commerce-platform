import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/address.dart';

abstract class AddressService {
  Future<List<Address>> loadAddresses();

  Future<void> saveAddresses(List<Address> addresses);
}

class LocalAddressService implements AddressService {
  static const String _key = 'customer_addresses_v1';

  final SharedPreferencesAsync _preferences;

  LocalAddressService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<List<Address>> loadAddresses() async {
    final raw = await _preferences.getString(_key);

    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return const [];
      }

      return decoded
          .map(
            (item) => Address.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      await _preferences.remove(_key);
      return const [];
    }
  }

  @override
  Future<void> saveAddresses(List<Address> addresses) async {
    final encoded = jsonEncode(
      addresses.map((address) => address.toJson()).toList(),
    );

    await _preferences.setString(_key, encoded);
  }
}
