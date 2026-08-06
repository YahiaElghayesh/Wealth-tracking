import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/format/money_formatter.dart';
import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../pdf/monthly_summary_pdf.dart';
import '../providers/ledger_providers.dart';

class MonthlySummaryScreen extends ConsumerStatefulWidget {
  const MonthlySummaryScreen({super.key, required this.counterparty});

  final Counterparty counterparty;

  @override
  ConsumerState<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends ConsumerState<MonthlySummaryScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider(widget.counterparty.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly summary')),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          final categoryTotals = monthlyCategoryTotals(transactions, _month);
          final total = monthlyExpenseTotal(transactions, _month);
          final repayments = monthlyRepaymentTotal(transactions, _month);

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shiftMonth(-1)),
                  Text(
                    '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shiftMonth(1)),
                ],
              ),
              Expanded(
                child: categoryTotals.isEmpty
                    ? const Center(child: Text('No entries this month.'))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final entry in categoryTotals.entries)
                            ListTile(
                              title: Text(entry.key),
                              trailing: Text(formatUsd(entry.value)),
                            ),
                          const Divider(),
                          ListTile(
                            title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Text(
                              formatUsd(total),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (repayments > 0)
                            ListTile(
                              title: const Text('Repayments received'),
                              trailing: Text(formatUsd(repayments)),
                            ),
                        ],
                      ),
              ),
              if (categoryTotals.isNotEmpty)
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
                                categoryTotals: categoryTotals,
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
                              categoryTotals: categoryTotals,
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
