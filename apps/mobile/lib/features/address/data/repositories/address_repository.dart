import '../../domain/models/address.dart';
import '../services/address_service.dart';

class AddressRepository {
  final AddressService _service;

  const AddressRepository({required AddressService service})
    : _service = service;

  Future<List<Address>> loadAddresses() {
    return _service.loadAddresses();
  }

  Future<void> saveAddresses(List<Address> addresses) {
    return _service.saveAddresses(addresses);
  }
}
