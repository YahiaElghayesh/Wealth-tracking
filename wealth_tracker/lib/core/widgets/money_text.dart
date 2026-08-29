import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/privacy_providers.dart';
import '../theme/app_theme.dart';

/// Drop-in replacement for `Text(formatMoney(...))` (or `formatUsd`/
/// `formatEgp`) that renders masked dots instead of [text] whenever
/// [hideValuesProvider] is on — a single switch-flip away from every other
/// money display in the app, rather than a hidden/shown state each screen
/// has to track for itself.
///
/// Also the single point where every money value in the app picks up the
/// approved redesign's IBM Plex Mono numeral style: [style] merges onto
/// [moneyTextStyle]'s default (mono + tabular figures) rather than
/// replacing it, so passing just a `fontSize`/`color` override -- which is
/// how every existing call site already uses this widget -- keeps the mono
/// font automatically instead of silently falling back to the body font.
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
    final effectiveStyle = moneyTextStyle(context).merge(style);
    return Text(hidden ? '•' * maskLength : text, style: effectiveStyle, textAlign: textAlign);
  }
}
