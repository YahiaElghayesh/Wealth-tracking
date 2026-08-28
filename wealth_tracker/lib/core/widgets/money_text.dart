import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/privacy_providers.dart';

/// Drop-in replacement for `Text(formatMoney(...))` (or `formatUsd`/
/// `formatEgp`) that renders masked dots instead of [text] whenever
/// [hideValuesProvider] is on — a single switch-flip away from every other
/// money display in the app, rather than a hidden/shown state each screen
/// has to track for itself.
class MoneyText extends ConsumerWidget {
  const MoneyText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maskLength = 7,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maskLength;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideValuesProvider);
    return Text(hidden ? '•' * maskLength : text, style: style, textAlign: textAlign);
  }
}
