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
    this.overflow,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maskLength;

  /// Passed straight through to the underlying [Text] — set these at a call
  /// site that can't guarantee enough width (e.g. sitting next to a
  /// variable-length name in a Row) instead of letting it overflow.
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideValuesProvider);
    final effectiveStyle = moneyTextStyle(context).merge(_withoutFontFamily(style));
    return Text(
      hidden ? '•' * maskLength : text,
      style: effectiveStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  /// A TextTheme slot (e.g. `theme.textTheme.headlineSmall`) carries its own
  /// `fontFamily` — Fraunces, for the slots this app's theme repoints to a
  /// serif headline font. [TextStyle.merge] lets a non-null field on the
  /// argument win, so merging that style on top of [moneyTextStyle] would
  /// let its `fontFamily` silently override the mono font this widget
  /// exists to guarantee. Stripping just the family-related fields (every
  /// other property — size, weight, color, ...) still applies normally.
  static TextStyle? _withoutFontFamily(TextStyle? style) {
    if (style == null) return null;
    return TextStyle(
      color: style.color,
      backgroundColor: style.backgroundColor,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      fontStyle: style.fontStyle,
      letterSpacing: style.letterSpacing,
      wordSpacing: style.wordSpacing,
      textBaseline: style.textBaseline,
      height: style.height,
      leadingDistribution: style.leadingDistribution,
      locale: style.locale,
      foreground: style.foreground,
      background: style.background,
      shadows: style.shadows,
      decoration: style.decoration,
      decorationColor: style.decorationColor,
      decorationStyle: style.decorationStyle,
      decorationThickness: style.decorationThickness,
      debugLabel: style.debugLabel,
    );
  }
}
