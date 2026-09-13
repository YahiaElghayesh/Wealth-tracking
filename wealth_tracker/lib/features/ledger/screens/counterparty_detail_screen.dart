import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/models/ledger_category_icons.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../networth/providers/asset_providers.dart'
    show pricesUsdPerUnitProvider;
import '../providers/ledger_providers.dart';
import 'add_transaction_screen.dart';
import 'monthly_summary_screen.dart';

/// A repayment always shows the same "money came back" glyph; a charge
/// shows its category's real user-managed icon (Settings -> Categories &
/// icons), falling back to a generic receipt glyph for a category that was
/// deleted or free-typed without ever getting an icon.
String _emojiFor(
  String category,
  bool isAddition,
  Map<String, String> categoryIcons,
) {
  if (!isAddition) return '↩︎';
  return categoryIcons[category] ?? fallbackCategoryEmoji;
}

/// A month/year divider interspersed between [LedgerTransaction] rows in
/// the flat list [_groupedRows] builds -- [transactions] arrives already
/// sorted newest-first (`LedgerRepository.watchTransactions`'s own query),
/// so a header only ever needs inserting the moment the running month
/// changes, never a separate sort/group pass of its own.
class _MonthHeader {
  const _MonthHeader(this.label);
  final String label;
}

final _monthYearFormat = DateFormat.yMMMM();

List<Object> _groupedRows(List<LedgerTransaction> transactions) {
  final rows = <Object>[];
  String? lastLabel;
  for (final t in transactions) {
    final label = _monthYearFormat.format(t.date);
    if (label != lastLabel) {
      rows.add(_MonthHeader(label));
      lastLabel = label;
    }
    rows.add(t);
  }
  return rows;
}

Future<bool> _confirmDeleteTransaction(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete entry?'),
          content: const Text("This can't be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

class CounterpartyDetailScreen extends ConsumerWidget {
  const CounterpartyDetailScreen({super.key, required this.counterparty});

  final Counterparty counterparty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(
      transactionsStreamProvider(counterparty.id),
    );
    final prices = ref.watch(pricesUsdPerUnitProvider);
    final hideValues = ref.watch(hideValuesProvider);
    final categories =
        ref.watch(ledgerCategoriesStreamProvider).valueOrNull ?? const [];
    final categoryIcons = {
      for (final c in categories)
        if (c.icon != null) c.name: c.icon!,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(hideValues ? '••••••' : counterparty.name),
        actions: [
          const HideValuesAction(),
          IconButton(
            icon: const Icon(Icons.summarize),
            tooltip: 'Monthly summary',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    MonthlySummaryScreen(counterparty: counterparty),
              ),
            ),
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          final theme = Theme.of(context);
          final colors = context.appColors;
          final balance = runningBalance(transactions, prices).amount;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hideValues
                            ? '••••••'
                            : isEffectivelySettled(balance)
                            ? (counterparty.isTab ? 'All even' : 'Nothing owed')
                            : counterparty.isTab
                            ? (balance >= 0
                                  ? "You've paid more"
                                  : '${counterparty.name} has paid more')
                            : (balance >= 0
                                  ? '${counterparty.name} owes you'
                                  : 'You owe ${counterparty.name}'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textDim,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      isEffectivelySettled(balance)
                          ? Text(
                              'Settled up',
                              style: theme.textTheme.headlineSmall,
                            )
                          : MoneyText(
                              formatMoney(balance.abs(), defaultCurrency),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: counterparty.isTab
                                    ? colors.textBody
                                    : (balance > 0 ? colors.bad : colors.good),
                              ),
                              maskLength: 7,
                            ),
                      const SizedBox(height: 6),
                      Text(
                        '${transactions.length} entries',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(
                        child: Text('No entries yet. Tap + to add one.'),
                      )
                    : Builder(
                        builder: (context) {
                          final rows = _groupedRows(transactions);
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: rows.length,
                            itemBuilder: (context, i) {
                              final row = rows[i];
                              if (row is _MonthHeader) {
                                return Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    4,
                                    i == 0 ? 0 : 20,
                                    4,
                                    8,
                                  ),
                                  child: Text(
                                    row.label,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: colors.textDim,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                );
                              }
                              final t = row as LedgerTransaction;
                          // A charge (you paid on their behalf) grows what
                          // they owe you -- shown "+" and in the bad/red
                          // tone, same convention as a bill growing; a
                          // repayment shrinks it -- shown "−" and good/green.
                          final isAddition = t.amount >= 0;
                          final signColor = isAddition
                              ? colors.bad
                              : colors.good;
                          return Dismissible(
                            key: ValueKey(t.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) =>
                                _confirmDeleteTransaction(context),
                            background: Container(
                              margin: const EdgeInsets.only(top: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: const Icon(Icons.delete),
                            ),
                            onDismissed: (_) => ref
                                .read(ledgerRepositoryProvider)
                                .deleteTransaction(t.id),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddTransactionScreen(
                                    counterpartyId: counterparty.id,
                                    existing: t,
                                  ),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: signColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: hideValues
                                          ? Icon(
                                              Icons.lock_outline,
                                              size: 15,
                                              color: colors.textDim,
                                            )
                                          : Text(
                                              _emojiFor(
                                                t.category,
                                                isAddition,
                                                categoryIcons,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hideValues ? '••••••' : t.category,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            hideValues
                                                ? '••••••'
                                                : '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}'
                                                      '${t.description == null ? '' : ' · ${t.description}'}'
                                                      '${t.source == 'sms' ? ' · SMS' : ''}',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: colors.textDim,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    MoneyText(
                                      '${isAddition ? '+' : '−'}${formatMoney(t.amount.abs(), t.currency)}',
                                      style: TextStyle(
                                        color: signColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AddTransactionScreen(counterpartyId: counterparty.id),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
