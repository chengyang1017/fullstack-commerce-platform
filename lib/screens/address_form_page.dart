import 'package:flutter/material.dart';

import '../models/address.dart';

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({super.key});

  @override
  State<AddressFormPage> createState() {
    return _AddressFormPageState();
  }
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _receiverController = TextEditingController();

  final _phoneController = TextEditingController();

  final _addressController = TextEditingController();

  final _cityController = TextEditingController();

  final _stateController = TextEditingController();

  final _postcodeController = TextEditingController();

  final _countryController = TextEditingController(text: 'Malaysia');

  bool _isDefault = false;

  @override
  void dispose() {
    _receiverController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _countryController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增收貨地址')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField(controller: _receiverController, label: '收件人姓名'),
            _buildField(
              controller: _phoneController,
              label: '電話號碼',
              keyboardType: TextInputType.phone,
            ),
            _buildField(
              controller: _addressController,
              label: '詳細地址',
              maxLines: 2,
            ),
            _buildField(controller: _cityController, label: '城市'),
            _buildField(controller: _stateController, label: '州屬'),
            _buildField(
              controller: _postcodeController,
              label: '郵遞區號',
              keyboardType: TextInputType.number,
            ),
            _buildField(controller: _countryController, label: '國家'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('設為預設地址'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _submit, child: const Text('保存地址')),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '請輸入$label';
          }

          return null;
        },
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();

    final address = Address(
      id:
          'address_'
          '${now.microsecondsSinceEpoch}',
      receiverName: _receiverController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postcode: _postcodeController.text.trim(),
      country: _countryController.text.trim(),
      isDefault: _isDefault,
    );

    Navigator.pop(context, address);
  }
}
