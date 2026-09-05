import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../networth/providers/asset_providers.dart'
    show pricesUsdPerUnitProvider;
import '../pdf/monthly_summary_pdf.dart';
import '../providers/ledger_providers.dart';

class MonthlySummaryScreen extends ConsumerStatefulWidget {
  const MonthlySummaryScreen({super.key, required this.counterparty});

  final Counterparty counterparty;

  @override
  ConsumerState<MonthlySummaryScreen> createState() =>
      _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends ConsumerState<MonthlySummaryScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(
      transactionsStreamProvider(widget.counterparty.id),
    );
    final prices = ref.watch(pricesUsdPerUnitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly summary')),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          // The actual itemized entries for this month, oldest first --
          // matching the ledger's own row-per-payment view, rather than
          // collapsing everything into one number per category, which
          // threw away exactly the dates/notes/individual amounts a
          // shared or printed summary needs to actually mean something to
          // whoever receives it.
          final monthTransactions =
              transactions
                  .where(
                    (t) =>
                        t.date.year == _month.year &&
                        t.date.month == _month.month,
                  )
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date));
          final total = monthlyExpenseTotal(transactions, _month, prices);
          final repayments = monthlyRepaymentTotal(
            transactions,
            _month,
            prices,
          );

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _shiftMonth(-1),
                  ),
                  Text(
                    '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _shiftMonth(1),
                  ),
                ],
              ),
              Expanded(
                child: monthTransactions.isEmpty
                    ? const Center(child: Text('No entries this month.'))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final t in monthTransactions)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(t.category),
                              subtitle: Text(
                                '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}'
                                '${t.description == null ? '' : ' · ${t.description}'}'
                                '${t.source == 'sms' ? ' · SMS' : ''}',
                              ),
                              trailing: Text(
                                '${t.amount >= 0 ? '+' : '−'}${formatMoney(t.amount.abs(), t.currency)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  // Same convention as the ledger's own
                                  // detail screen: a charge grows what's
                                  // owed (bad/red), a repayment shrinks it
                                  // (good/green).
                                  color: t.amount >= 0
                                      ? context.appColors.bad
                                      : context.appColors.good,
                                ),
                              ),
                            ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Text(
                              formatMoney(total, defaultCurrency),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (repayments > 0)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Repayments received'),
                              trailing: Text(
                                formatMoney(repayments, defaultCurrency),
                              ),
                            ),
                        ],
                      ),
              ),
              if (monthTransactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('Share text'),
                          onPressed: () => SharePlus.instance.share(
                            ShareParams(
                              text: buildMonthlySummaryText(
                                counterpartyName: widget.counterparty.name,
                                month: _month,
                                transactions: monthTransactions,
                                total: total,
                                repayments: repayments,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export PDF'),
                          onPressed: () => Printing.layoutPdf(
                            onLayout: (_) => buildMonthlySummaryPdf(
                              counterpartyName: widget.counterparty.name,
                              month: _month,
                              transactions: monthTransactions,
                              total: total,
                              repayments: repayments,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
