import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../../core/format/money_formatter.dart';

Future<Uint8List> buildMonthlySummaryPdf({
  required String counterpartyName,
  required DateTime month,
  required Map<String, double> categoryTotals,
  required double total,
  required double repayments,
}) async {
  final doc = pw.Document();
  final monthLabel = '${month.year}-${month.month.toString().padLeft(2, '0')}';

  doc.addPage(
    pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Monthly Summary — $counterpartyName',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(monthLabel),
          pw.SizedBox(height: 20),
          for (final entry in categoryTotals.entries)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text(entry.key), pw.Text(formatUsd(entry.value))],
              ),
            ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(formatUsd(total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          if (repayments > 0) ...[
            pw.SizedBox(height: 12),
            pw.Text('Repayments received this month: ${formatUsd(repayments)}'),
          ],
        ],
      ),
    ),
  );

  return doc.save();
}

String buildMonthlySummaryText({
  required String counterpartyName,
  required DateTime month,
  required Map<String, double> categoryTotals,
  required double total,
  required double repayments,
}) {
  final monthLabel = '${month.year}-${month.month.toString().padLeft(2, '0')}';
  final buffer = StringBuffer('Monthly Summary — $counterpartyName ($monthLabel)\n\n');
  for (final entry in categoryTotals.entries) {
    buffer.writeln('${entry.key}: ${formatUsd(entry.value)}');
  }
  buffer.writeln('\nTotal: ${formatUsd(total)}');
  if (repayments > 0) {
    buffer.writeln('Repayments received this month: ${formatUsd(repayments)}');
  }
  return buffer.toString();
}
