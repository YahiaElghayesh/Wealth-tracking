import 'package:flutter/material.dart';

import '../models/currency.dart';

const _more = '__more__';

/// A currency-picking form field used everywhere the app lets someone
/// choose a currency -- shows only [commonCurrencies] inline (the
/// household's actual day-to-day currencies) plus a trailing "More
/// currencies" row, rather than opening every dropdown onto a wall of
/// 150+ ISO-4217 codes. Tapping "More currencies" opens a searchable list
/// of the full [supportedCurrencies] set via [showCurrencySearch]. The
/// current [value] always stays selectable even when it isn't one of
/// [commonCurrencies] (picked earlier via search, or set on an existing
/// record) -- it's inserted into the visible list instead of being left
/// orphaned/invisible.
class CurrencyPickerField extends StatelessWidget {
  const CurrencyPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.helperText,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? labelText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final items = [
      ...commonCurrencies,
      if (!commonCurrencies.contains(value)) value,
    ];

    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(labelText: labelText, helperText: helperText),
      items: [
        for (final code in items)
          DropdownMenuItem(value: code, child: Text(code)),
        const DropdownMenuItem(
          value: _more,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 18),
              SizedBox(width: 8),
              Text('More currencies'),
            ],
          ),
        ),
      ],
      onChanged: (picked) async {
        if (picked == null) return;
        if (picked != _more) {
          onChanged(picked);
          return;
        }
        final searched = await showCurrencySearch(context, current: value);
        if (searched != null) onChanged(searched);
      },
    );
  }
}

/// Full-list searchable picker behind [CurrencyPickerField]'s "More
/// currencies" row -- a plain dialog with a search field is enough for a
/// list this size (150-ish entries), no need for a dedicated screen/route.
Future<String?> showCurrencySearch(
  BuildContext context, {
  required String current,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _CurrencySearchDialog(current: current),
  );
}

class _CurrencySearchDialog extends StatefulWidget {
  const _CurrencySearchDialog({required this.current});

  final String current;

  @override
  State<_CurrencySearchDialog> createState() => _CurrencySearchDialogState();
}

class _CurrencySearchDialogState extends State<_CurrencySearchDialog> {
  final _searchController = TextEditingController();
  List<String> _filtered = supportedCurrencies;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    final q = query.trim().toUpperCase();
    setState(() {
      _filtered = q.isEmpty
          ? supportedCurrencies
          : supportedCurrencies.where((c) => c.contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose a currency',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by code, e.g. GBP',
                  border: OutlineInputBorder(),
                ),
                onChanged: _onQueryChanged,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: _filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No matching currency',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final code = _filtered[i];
                          return ListTile(
                            title: Text(code),
                            trailing: code == widget.current
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () => Navigator.of(context).pop(code),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
