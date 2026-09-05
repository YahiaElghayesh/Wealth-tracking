import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../data/db/database.dart';

String _dateLabel(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

Future<Uint8List> buildMonthlySummaryPdf({
  required String counterpartyName,
  required DateTime month,
  required List<LedgerTransaction> transactions,
  required double total,
  required double repayments,
}) async {
  final doc = pw.Document();
  final monthLabel = '${month.year}-${month.month.toString().padLeft(2, '0')}';

  doc.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text(
          'Monthly Summary - $counterpartyName',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(monthLabel),
        pw.SizedBox(height: 20),
        for (final t in transactions)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(t.category),
                      pw.Text(
                        '${_dateLabel(t.date)}'
                        '${t.description == null ? '' : ' · ${t.description}'}'
                        '${t.source == 'sms' ? ' · SMS' : ''}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
                pw.Text(
                  '${t.amount >= 0 ? '+' : '-'}${formatMoney(t.amount.abs(), t.currency)}',
                ),
              ],
            ),
          ),
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Total',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              formatMoney(total, defaultCurrency),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        if (repayments > 0) ...[
          pw.SizedBox(height: 12),
          pw.Text(
            'Repayments received this month: ${formatMoney(repayments, defaultCurrency)}',
          ),
        ],
      ],
    ),
  );

  return doc.save();
}

String buildMonthlySummaryText({
  required String counterpartyName,
  required DateTime month,
  required List<LedgerTransaction> transactions,
  required double total,
  required double repayments,
}) {
  final monthLabel = '${month.year}-${month.month.toString().padLeft(2, '0')}';
  final buffer = StringBuffer(
    'Monthly Summary — $counterpartyName ($monthLabel)\n\n',
  );
  for (final t in transactions) {
    final sign = t.amount >= 0 ? '+' : '-';
    buffer.write('${_dateLabel(t.date)}  ${t.category}');
    if (t.description != null) buffer.write(' · ${t.description}');
    if (t.source == 'sms') buffer.write(' · SMS');
    buffer.writeln('  $sign${formatMoney(t.amount.abs(), t.currency)}');
  }
  buffer.writeln('\nTotal: ${formatMoney(total, defaultCurrency)}');
  if (repayments > 0) {
    buffer.writeln(
      'Repayments received this month: ${formatMoney(repayments, defaultCurrency)}',
    );
  }
  return buffer.toString();
}
