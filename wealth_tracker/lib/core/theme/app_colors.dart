import 'package:flutter/material.dart';

/// Semantic colors from the approved redesign mockup that don't map onto
/// Flutter's [ColorScheme] slots — a second surface tone, dim/body text
/// tiers, a soft accent tint for chips/badges, and the fixed metal/crypto
/// colors used for gold, silver, and Bitcoin regardless of theme.
///
/// Values are the exact tokens from the mockup's `--app-*` CSS custom
/// properties (light) and its `body.app-dark` override block (dark) --
/// not re-derived, so the app actually matches what was approved.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surface2,
    required this.border,
    required this.textBody,
    required this.textDim,
    required this.accentSoft,
    required this.good,
    required this.bad,
    required this.gold,
    required this.silver,
    required this.btc,
  });

  final Color surface2;
  final Color border;
  final Color textBody;
  final Color textDim;
  final Color accentSoft;
  final Color good;
  final Color bad;
  final Color gold;
  final Color silver;
  final Color btc;

  static const light = AppColors(
    surface2: Color(0xFFEEF1F9),
    border: Color(0xFFE2E6F2),
    textBody: Color(0xCC0F192A), // rgba(15,25,42,.8)
    textDim: Color(0x8C0F192A), // rgba(15,25,42,.55)
    accentSoft: Color(0x142F5FE0), // rgba(47,95,224,.08)
    good: Color(0xFF17A673),
    bad: Color(0xFFD6483A),
    gold: Color(0xFFB8862C),
    silver: Color(0xFF8B95A3),
    btc: Color(0xFFF7931A),
  );

  static const dark = AppColors(
    surface2: Color(0xFF1F242C),
    border: Color(0xFF2B323C),
    textBody: Color(0xD1ECF0F7), // rgba(236,240,247,.82)
    textDim: Color(0x94ECF0F7), // rgba(236,240,247,.58)
    accentSoft: Color(0x2E5B82FF), // rgba(91,130,255,.18)
    good: Color(0xFF34C98F),
    bad: Color(0xFFF0806A),
    gold: Color(0xFFD9A94E),
    silver: Color(0xFFA7ADB6),
    btc: Color(0xFFF7931A),
  );

  @override
  AppColors copyWith({
    Color? surface2,
    Color? border,
    Color? textBody,
    Color? textDim,
    Color? accentSoft,
    Color? good,
    Color? bad,
    Color? gold,
    Color? silver,
    Color? btc,
  }) {
    return AppColors(
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      textBody: textBody ?? this.textBody,
      textDim: textDim ?? this.textDim,
      accentSoft: accentSoft ?? this.accentSoft,
      good: good ?? this.good,
      bad: bad ?? this.bad,
      gold: gold ?? this.gold,
      silver: silver ?? this.silver,
      btc: btc ?? this.btc,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      good: Color.lerp(good, other.good, t)!,
      bad: Color.lerp(bad, other.bad, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      silver: Color.lerp(silver, other.silver, t)!,
      btc: Color.lerp(btc, other.btc, t)!,
    );
  }
}

/// Shorthand for `Theme.of(context).extension<AppColors>()!`.
extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
