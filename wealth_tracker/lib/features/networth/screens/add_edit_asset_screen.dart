import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/asset_category.dart';
import '../../../core/models/currency.dart';
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
  late String _currency;
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _symbolController;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _category = existing == null
        ? AssetCategory.cash
        : AssetCategory.values.byName(existing.category);
    _currency = (existing != null && _category.defaultValuationMode == ValuationMode.currency)
        ? existing.symbolOrCurrency
        : defaultCurrency;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _quantityController =
        TextEditingController(text: existing == null ? '' : existing.quantity.toString());
    _symbolController = TextEditingController(
      text: (existing != null && _category.defaultValuationMode == ValuationMode.crypto)
          ? existing.symbolOrCurrency
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  ValuationMode get _valuationMode => _category.defaultValuationMode;

  String get _amountLabel => _category == AssetCategory.cash ? 'Amount held' : 'Current value';

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
      case ValuationMode.currency:
        return [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(labelText: _amountLabel),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _requiredNumber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: supportedCurrencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (c) => setState(() => _currency = c!),
                ),
              ),
            ],
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
      ValuationMode.currency => _currency,
    };
    final quantity = double.parse(_quantityController.text.trim());

    final companion = AssetsCompanion(
      name: Value(_nameController.text.trim()),
      category: Value(_category.name),
      valuationMode: Value(_valuationMode.name),
      quantity: Value(quantity),
      symbolOrCurrency: Value(symbol),
    );

    if (_isEditing) {
      await repo.update(widget.existing!.id, companion);
    } else {
      await repo.add(companion);
    }

    if (mounted) Navigator.of(context).pop();
  }
}
