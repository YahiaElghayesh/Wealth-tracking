import 'package:intl/intl.dart';

final _usdFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _egpFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);

String formatUsd(double value) => _usdFormat.format(value);

String formatEgp(double value) => _egpFormat.format(value);
