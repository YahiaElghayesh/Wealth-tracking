import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Fraunces -- serif, used only for app-bar/dialog titles ("headline"-ish
/// slots). Inter -- the workhorse UI font for everything else. IBM Plex
/// Mono -- every numeric/money value, via [moneyTextStyle] rather than a
/// TextTheme slot, since Flutter has no "monospace numerals" slot and money
/// text always needs an explicit style anyway (see MoneyText).
///
/// These three fonts, and every color below, are not a fresh design --
/// they're the exact tokens from the mockup artifact the user approved
/// (https://claude.ai/code/artifact/725578b0-a702-47e1-a987-8cea9466bd0a),
/// extracted from its committed CSS rather than re-guessed.
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final appColors = isDark ? AppColors.dark : AppColors.light;

  const lightBg = Color(0xFFF4F6FB);
  const lightSurface = Color(0xFFFFFFFF);
  const lightAccent = Color(0xFF2F5FE0);
  const lightText = Color(0xFF0F192A);

  const darkBg = Color(0xFF0D1117);
  const darkSurface = Color(0xFF161B22);
  const darkAccent = Color(0xFF5B82FF);
  const darkText = Color(0xFFECF0F7);

  final bg = isDark ? darkBg : lightBg;
  final surface = isDark ? darkSurface : lightSurface;
  final accent = isDark ? darkAccent : lightAccent;
  final text = isDark ? darkText : lightText;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: Colors.white,
    secondary: appColors.gold,
    onSecondary: Colors.white,
    tertiary: appColors.good,
    onTertiary: Colors.white,
    error: appColors.bad,
    onError: Colors.white,
    surface: surface,
    onSurface: text,
    surfaceContainerHighest: appColors.surface2,
    onSurfaceVariant: appColors.textDim,
    outline: appColors.border,
    outlineVariant: appColors.border,
    inverseSurface: text,
    onInverseSurface: surface,
    shadow: Colors.black,
    scrim: Colors.black,
    primaryContainer: appColors.accentSoft,
    onPrimaryContainer: accent,
  );

  final baseTextTheme = GoogleFonts.interTextTheme(ThemeData(brightness: brightness).textTheme);
  final fraunces = GoogleFonts.frauncesTextTheme(ThemeData(brightness: brightness).textTheme);
  final textTheme = baseTextTheme.copyWith(
    titleLarge: fraunces.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: text),
    headlineSmall: fraunces.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: text),
    headlineMedium: fraunces.headlineMedium?.copyWith(fontWeight: FontWeight.w600, color: text),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: bg,
    textTheme: textTheme,
    extensions: [appColors],
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: text,
      titleTextStyle: GoogleFonts.fraunces(fontSize: 21, fontWeight: FontWeight.w600, color: text),
      iconTheme: IconThemeData(color: appColors.textDim),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: appColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(iconColor: accent, textColor: text),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: appColors.textDim),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: appColors.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      labelStyle: GoogleFonts.inter(color: appColors.textDim, fontSize: 12, fontWeight: FontWeight.w700),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? accent : appColors.border,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: appColors.accentSoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: states.contains(WidgetState.selected) ? accent : appColors.textDim,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? accent : appColors.textDim,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: appColors.border, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: accent,
      side: BorderSide(color: appColors.border),
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11.5, color: text),
      shape: const StadiumBorder(),
    ),
  );
}

/// The one text style every money/numeric value in the app should use --
/// IBM Plex Mono with tabular figures, matching the mockup's `.num` class.
/// [MoneyText] applies this by default; pass a different [color]/[fontSize]
/// to fit the surrounding context (a hero total vs. a small trailing amount).
TextStyle moneyTextStyle(
  BuildContext context, {
  Color? color,
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w600,
}) {
  return GoogleFonts.ibmPlexMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? Theme.of(context).colorScheme.onSurface,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
