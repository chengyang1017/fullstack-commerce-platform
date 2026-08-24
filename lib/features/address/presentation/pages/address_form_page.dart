import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/address.dart';

class AddressFormPage
    extends StatefulWidget {
  const AddressFormPage({
    super.key,
  });

  @override
  State<AddressFormPage> createState() {
    return _AddressFormPageState();
  }
}

class _AddressFormPageState
    extends State<AddressFormPage> {
  final _formKey =
      GlobalKey<FormState>();

  final _receiverController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  final _addressController =
      TextEditingController();

  final _cityController =
      TextEditingController();

  final _stateController =
      TextEditingController();

  final _postcodeController =
      TextEditingController();

  final _countryController =
      TextEditingController(
    text: 'Malaysia',
  );

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
    final l10n =
        AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.addShippingAddress,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              const EdgeInsets.all(
            16,
          ),
          children: [
            _buildField(
              controller:
                  _receiverController,
              label:
                  l10n.recipientName,
            ),

            _buildField(
              controller:
                  _phoneController,
              label:
                  l10n.phoneNumber,
              keyboardType:
                  TextInputType.phone,
            ),

            _buildField(
              controller:
                  _addressController,
              label:
                  l10n.detailedAddress,
              maxLines: 2,
            ),

            _buildField(
              controller:
                  _cityController,
              label: l10n.city,
            ),

            _buildField(
              controller:
                  _stateController,
              label:
                  l10n.stateRegion,
            ),

            _buildField(
              controller:
                  _postcodeController,
              label:
                  l10n.postcode,
              keyboardType:
                  TextInputType.number,
            ),

            _buildField(
              controller:
                  _countryController,
              label:
                  l10n.country,
            ),

            SwitchListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: Text(
                l10n
                    .setAsDefaultAddress,
              ),
              value: _isDefault,
              onChanged: (
                value,
              ) {
                setState(() {
                  _isDefault =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 20,
            ),

            FilledButton(
              onPressed: _submit,
              child: Text(
                l10n.saveAddress,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController
        controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final l10n =
        AppLocalizations.of(context);

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType:
            keyboardType,
        maxLines: maxLines,
        decoration:
            InputDecoration(
          labelText: label,
        ),
        validator: (
          value,
        ) {
          if (value == null ||
              value.trim().isEmpty) {
            return l10n
                .requiredField(
              label,
            );
          }

          return null;
        },
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final now =
        DateTime.now();

    final address = Address(
      id:
          'address_${now.microsecondsSinceEpoch}',
      receiverName:
          _receiverController.text
              .trim(),
      phone:
          _phoneController.text
              .trim(),
      addressLine:
          _addressController.text
              .trim(),
      city:
          _cityController.text
              .trim(),
      state:
          _stateController.text
              .trim(),
      postcode:
          _postcodeController.text
              .trim(),
      country:
          _countryController.text
              .trim(),
      isDefault:
          _isDefault,
    );

    Navigator.pop(
      context,
      address,
    );
  }
}