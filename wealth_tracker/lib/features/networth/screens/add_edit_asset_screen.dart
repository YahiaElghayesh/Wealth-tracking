import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/asset_category.dart';
import '../../../data/db/database.dart';
import '../providers/asset_providers.dart';

class AddEditAssetScreen extends ConsumerStatefulWidget {
  const AddEditAssetScreen({super.key, this.existing});

  final Asset? existing;

  @override
  ConsumerState<AddEditAssetScreen> createState() => _AddEditAssetScreenState();
}

class _AddEditAssetScreenState extends ConsumerState<AddEditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  late AssetCategory _category;
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _symbolController;
  late final TextEditingController _manualValueController;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _category = existing == null
        ? AssetCategory.cash
        : AssetCategory.values.byName(existing.category);
    _nameController = TextEditingController(text: existing?.name ?? '');
    _quantityController =
        TextEditingController(text: existing == null ? '' : existing.quantity.toString());
    _symbolController = TextEditingController(text: existing?.symbolOrCurrency ?? '');
    _manualValueController = TextEditingController(
      text: existing?.manualValueUsd == null ? '' : existing!.manualValueUsd.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _symbolController.dispose();
    _manualValueController.dispose();
    super.dispose();
  }

  ValuationMode get _valuationMode => _category.defaultValuationMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit asset' : 'Add asset')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AssetCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: AssetCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (c) => setState(() => _category = c!),
            ),
            const SizedBox(height: 16),
            ..._buildValuationFields(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: const Text('Save'),
      ),
    );
  }

  List<Widget> _buildValuationFields() {
    switch (_valuationMode) {
      case ValuationMode.manual:
        return [
          TextFormField(
            controller: _manualValueController,
            decoration: const InputDecoration(labelText: 'Current value (USD)', prefixText: r'$ '),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _requiredNumber,
          ),
        ];
      case ValuationMode.crypto:
        return [
          TextFormField(
            controller: _symbolController,
            decoration: const InputDecoration(
              labelText: 'CoinGecko ID',
              hintText: 'e.g. bitcoin, ethereum, solana',
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Quantity held'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _requiredNumber,
          ),
        ];
      case ValuationMode.metal:
        return [
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Quantity (grams)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _requiredNumber,
          ),
        ];
      case ValuationMode.fiatCurrency:
        return [
          TextFormField(
            controller: _symbolController,
            decoration: const InputDecoration(
              labelText: 'Currency code',
              hintText: 'e.g. USD, EGP',
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Amount held'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _requiredNumber,
          ),
        ];
    }
  }

  String? _requiredNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (double.tryParse(v.trim()) == null) return 'Enter a number';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(assetRepositoryProvider);
    final symbol = switch (_valuationMode) {
      ValuationMode.metal => _category == AssetCategory.gold ? 'XAU_GRAM' : 'XAG_GRAM',
      ValuationMode.crypto => _symbolController.text.trim(),
      ValuationMode.fiatCurrency => _symbolController.text.trim().toUpperCase(),
      ValuationMode.manual => null,
    };
    final quantity = _valuationMode == ValuationMode.manual
        ? 1.0
        : double.parse(_quantityController.text.trim());
    final manualValue = _valuationMode == ValuationMode.manual
        ? double.parse(_manualValueController.text.trim())
        : null;

    final companion = AssetsCompanion(
      name: Value(_nameController.text.trim()),
      category: Value(_category.name),
      valuationMode: Value(_valuationMode.name),
      quantity: Value(quantity),
      symbolOrCurrency: Value(symbol),
      manualValueUsd: Value(manualValue),
    );

    if (_isEditing) {
      await repo.update(widget.existing!.id, companion);
    } else {
      await repo.add(companion);
    }

    if (mounted) Navigator.of(context).pop();
  }
}
