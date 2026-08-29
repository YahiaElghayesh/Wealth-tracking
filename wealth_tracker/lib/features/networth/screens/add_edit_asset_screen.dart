import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/asset_category.dart';
import '../../../core/models/currency.dart';
import '../../../core/models/gold_karat.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../data/db/database.dart';
import '../../../data/pricing/coingecko_price_provider.dart';
import '../providers/asset_providers.dart';
import '../providers/pricing_providers.dart';

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
  late GoldKarat _goldKarat;
  late String _vehicleType;
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _symbolController;

  /// The CoinGecko ID actually saved — set when the user picks a search
  /// result, or falls back to whatever raw text they typed (so pasting a
  /// known ID directly, e.g. "bitcoin", still works without picking a
  /// suggestion). Starts at the existing asset's stored ID when editing.
  String _selectedCoinId = '';

  bool get _isEditing => widget.existing != null;

  Timer? _coinSearchDebounce;
  List<CoinSearchResult> _coinResults = [];
  String _lastCoinQuery = '';
  bool _coinFieldListenerAttached = false;

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
    _goldKarat = (existing != null && _category == AssetCategory.gold)
        ? GoldKarat.fromPriceSymbol(existing.symbolOrCurrency) ?? defaultGoldKarat
        : defaultGoldKarat;
    _vehicleType = existing?.vehicleType ?? 'car';
    _nameController = TextEditingController(text: existing?.name ?? '');
    _quantityController =
        TextEditingController(text: existing == null ? '' : existing.quantity.toString());
    _symbolController = TextEditingController(
      text: (existing != null && _category.defaultValuationMode == ValuationMode.crypto)
          ? existing.symbolOrCurrency
          : '',
    );
    _selectedCoinId = _symbolController.text;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _symbolController.dispose();
    _coinSearchDebounce?.cancel();
    super.dispose();
  }

  /// Called synchronously from `Autocomplete`'s `optionsBuilder`, which
  /// can't itself be async — kicks off a debounced network search and
  /// caches the results so the *next* build (triggered by the `setState`
  /// once results land) picks them up.
  void _scheduleCoinSearch(String query) {
    if (query == _lastCoinQuery) return;
    _lastCoinQuery = query;
    _coinSearchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _coinResults = []);
      return;
    }
    _coinSearchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await ref.read(cryptoPriceProviderProvider).searchCoins(query);
      if (mounted && query == _lastCoinQuery) {
        setState(() => _coinResults = results);
      }
    });
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
              isExpanded: true,
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
          if (_category == AssetCategory.vehicle) ...[
            Text('Vehicle type', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.appColors.textDim, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final option in const [('car', 'Car'), ('motorcycle', 'Motorcycle'), ('scooter', 'Scooter')])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: option.$1 == 'scooter' ? 0 : 8),
                      child: _VehicleTypeOption(
                        type: option.$1,
                        label: option.$2,
                        selected: _vehicleType == option.$1,
                        onTap: () => setState(() => _vehicleType = option.$1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
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
                  isExpanded: true,
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
          Autocomplete<CoinSearchResult>(
            initialValue: TextEditingValue(text: _symbolController.text),
            displayStringForOption: (option) => option.toString(),
            optionsBuilder: (value) {
              _scheduleCoinSearch(value.text);
              return _coinResults;
            },
            onSelected: (option) {
              setState(() {
                _symbolController.text = option.toString();
                _selectedCoinId = option.id;
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              // Typing a raw ID directly (without picking a suggestion)
              // must still work, e.g. pasting a known id like "bitcoin".
              // fieldViewBuilder reruns on every rebuild but Autocomplete
              // keeps the same controller instance alive throughout, so
              // guard against attaching the listener more than once.
              if (!_coinFieldListenerAttached) {
                _coinFieldListenerAttached = true;
                controller.addListener(() => _selectedCoinId = controller.text.trim());
              }
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Cryptocurrency',
                  hintText: 'Start typing a name, e.g. Bitcoin',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              );
            },
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
          if (_category == AssetCategory.gold) ...[
            DropdownButtonFormField<GoldKarat>(
              isExpanded: true,
              initialValue: _goldKarat,
              decoration: const InputDecoration(labelText: 'Karat'),
              items: GoldKarat.values
                  .map((k) => DropdownMenuItem(value: k, child: Text(k.label)))
                  .toList(),
              onChanged: (k) => setState(() => _goldKarat = k!),
            ),
            const SizedBox(height: 16),
          ],
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
      ValuationMode.metal => _category == AssetCategory.gold ? _goldKarat.priceSymbol : 'XAG_GRAM',
      ValuationMode.crypto => _selectedCoinId.trim().isEmpty ? _symbolController.text.trim() : _selectedCoinId.trim(),
      ValuationMode.currency => _currency,
    };
    final quantity = double.parse(_quantityController.text.trim());

    final companion = AssetsCompanion(
      name: Value(_nameController.text.trim()),
      category: Value(_category.name),
      valuationMode: Value(_valuationMode.name),
      quantity: Value(quantity),
      symbolOrCurrency: Value(symbol),
      vehicleType: Value(_category == AssetCategory.vehicle ? _vehicleType : null),
    );

    if (_isEditing) {
      await repo.update(widget.existing!.id, companion);
    } else {
      await repo.add(companion);
    }

    if (mounted) Navigator.of(context).pop();
  }
}

/// One choice in the vehicle-type picker: car / motorcycle / scooter, each
/// with its own icon -- used everywhere the asset displays afterward, not
/// just here.
class _VehicleTypeOption extends StatelessWidget {
  const _VehicleTypeOption({
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String type;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  Widget _icon(Color color) {
    switch (type) {
      case 'motorcycle':
        return AppIcon.motorcycle(size: 22, color: color);
      case 'scooter':
        return AppIcon.scooter(size: 22, color: color);
      default:
        return AppIcon.car(size: 22, color: color, holeColor: Colors.transparent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final color = selected ? theme.colorScheme.primary : colors.textDim;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? theme.colorScheme.primary : colors.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            _icon(color),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
