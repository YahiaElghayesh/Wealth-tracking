import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Real icons ported from the approved redesign mockup's inline SVG
/// `<symbol>` defs (not re-drawn from scratch) -- the exact Bitcoin mark,
/// the gold/silver bullion-bar shape traced from the user's own product
/// photo, and the motorcycle/scooter shapes built specifically to avoid
/// reading as a bicycle/stroller (both were explicit, repeated complaints
/// during the mockup phase). Multi-color icons (btc, the bars) have their
/// fills baked in and ignore [color]; single-color icons substitute
/// [color] for the mockup's `currentColor`.
class AppIcon {
  const AppIcon._();

  static Widget btc({double size = 24}) {
    return SvgPicture.string(_btcSvg, width: size, height: size);
  }

  static Widget goldBar({double size = 24}) {
    return SvgPicture.string(_barSvg(bar: '#d9a94e', dot: '#b3862f'), width: size, height: size);
  }

  static Widget silverBar({double size = 24}) {
    return SvgPicture.string(_barSvg(bar: '#cfd3d9', dot: '#9aa0a8'), width: size, height: size);
  }

  static Widget car({double size = 24, required Color color, Color? holeColor}) {
    return SvgPicture.string(
      _carSvg(_hex(color), _hex(holeColor ?? Colors.transparent)),
      width: size,
      height: size,
    );
  }

  static Widget motorcycle({double size = 24, required Color color}) {
    return SvgPicture.string(_motoSvg(_hex(color)), width: size, height: size);
  }

  static Widget scooter({double size = 24, required Color color}) {
    return SvgPicture.string(_scooterSvg(_hex(color)), width: size, height: size);
  }

  static Widget cash({double size = 24, required Color color}) {
    return SvgPicture.string(_cashSvg(_hex(color)), width: size, height: size);
  }

  static String _hex(Color c) {
    if (c.a == 0) return '#00000000';
    final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }
}

const _btcSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fill="#F7931A" d="M23.638 14.904c-1.602 6.43-8.113 10.34-14.542 8.736C2.67 22.05-1.244 15.525.362 9.105 1.962 2.67 8.475-1.243 14.9.358c6.43 1.605 10.342 8.115 8.738 14.548v-.002zm-6.35-4.613c.24-1.59-.974-2.45-2.64-3.03l.54-2.153-1.315-.328-.525 2.107c-.345-.087-.705-.167-1.064-.25l.526-2.127-1.32-.33-.54 2.165c-.285-.067-.565-.132-.84-.2l-1.815-.45-.35 1.407s.975.225.955.238c.535.136.63.486.615.766l-1.477 5.92c-.075.18-.24.45-.614.35.015.02-.96-.24-.96-.24l-.66 1.51 1.71.426.93.242-.54 2.19 1.32.327.54-2.17c.36.1.705.19 1.05.273l-.51 2.154 1.32.33.545-2.19c2.24.427 3.93.257 4.64-1.774.57-1.637-.03-2.58-1.217-3.196.854-.193 1.5-.76 1.68-1.93h.02zm-3.01 4.22c-.404 1.64-3.157.75-4.05.53l.72-2.9c.896.23 3.757.67 3.33 2.37zm.41-4.24c-.37 1.49-2.662.735-3.405.55l.654-2.64c.744.18 3.137.53 2.75 2.084v.006z"/></svg>
''';

/// Sealed assay-card shape, traced from the actual BTC (Bullion Trading
/// Center) card the user photographed: dark card, ring logo top-left, a
/// framed bar centered with a stamped-medallion dot texture. [bar]/[dot]
/// are the only things that change between the gold and silver variants.
String _barSvg({required String bar, required String dot}) => '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <rect x="2" y="1.5" width="20" height="21" rx="3.5" fill="#1d1e21"/>
  <circle cx="6.3" cy="6" r="2.1" fill="none" stroke="#f2f2f2" stroke-width=".8"/>
  <circle cx="6.3" cy="6" r="1.3" fill="none" stroke="#f2f2f2" stroke-width=".45"/>
  <rect x="8.3" y="9.3" width="7.4" height="11.4" rx="2.2" fill="#f2f2f2"/>
  <rect x="9.1" y="10.1" width="5.8" height="9.8" rx="1.7" fill="$bar"/>
  <circle cx="10.8" cy="11.7" r=".42" fill="none" stroke="$dot" stroke-width=".35"/>
  <circle cx="13.2" cy="11.7" r=".42" fill="none" stroke="$dot" stroke-width=".35"/>
  <circle cx="10.8" cy="13.9" r=".42" fill="none" stroke="$dot" stroke-width=".35"/>
  <circle cx="13.2" cy="13.9" r=".42" fill="none" stroke="$dot" stroke-width=".35"/>
  <circle cx="10.8" cy="16.1" r=".42" fill="none" stroke="$dot" stroke-width=".35"/>
  <circle cx="13.2" cy="16.1" r=".42" fill="none" stroke="$dot" stroke-width=".35"/>
  <circle cx="10.8" cy="18.3" r=".42" fill="none" stroke="$dot" stroke-width=".35"/>
  <circle cx="13.2" cy="18.3" r=".42" fill="none" stroke="$dot" stroke-width=".35"/>
</svg>
''';

String _carSvg(String color, String hole) => '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="$color">
  <path d="M5 16.5V13l1.6-4.3A2 2 0 018.5 7.5h7a2 2 0 011.9 1.2L19 13v3.5"/>
  <rect x="3.2" y="12.6" width="17.6" height="4.4" rx="1.6"/>
  <circle cx="7.5" cy="17.6" r="1.8" fill="$hole"/>
  <circle cx="16.5" cy="17.6" r="1.8" fill="$hole"/>
</svg>
''';

/// Deliberately bold/geometric (thick wheel rings + solid body mass) so
/// this doesn't read as a bicycle at small sizes -- the exact complaint
/// raised repeatedly during the mockup phase.
String _motoSvg(String color) => '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="5.5" cy="18.3" r="3" fill="none" stroke="$color" stroke-width="2.4"/>
  <circle cx="18.5" cy="18.3" r="3" fill="none" stroke="$color" stroke-width="2.4"/>
  <rect x="5" y="13.5" width="14" height="3.6" rx="1.8" fill="$color"/>
  <rect x="6.5" y="10.5" width="4.5" height="3.5" rx="1.6" fill="$color"/>
  <circle cx="18" cy="12" r="2.1" fill="$color"/>
  <path d="M18 10L16.2 6.8L13.5 6.8" fill="none" stroke="$color" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

/// Same bold-geometric approach as the motorcycle, so this doesn't read
/// as a stroller -- the other repeated complaint from the mockup phase.
String _scooterSvg(String color) => '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="6" cy="18.7" r="2.4" fill="none" stroke="$color" stroke-width="2.2"/>
  <circle cx="17.5" cy="18.7" r="2.4" fill="none" stroke="$color" stroke-width="2.2"/>
  <rect x="8" y="16.3" width="8" height="2" rx="1" fill="$color"/>
  <rect x="4.3" y="12.5" width="5.5" height="4.2" rx="2" fill="$color"/>
  <rect x="14.5" y="6" width="4.8" height="10.5" rx="2.4" fill="$color"/>
  <path d="M15.3 6L14.3 3.2M18.5 6L19.4 3.4" fill="none" stroke="$color" stroke-width="1.5" stroke-linecap="round"/>
</svg>
''';

String _cashSvg(String color) => '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="$color" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
  <rect x="2.5" y="6.5" width="19" height="11" rx="2"/>
  <circle cx="12" cy="12" r="2.6"/>
  <path d="M5.5 9v0M18.5 15v0"/>
</svg>
''';
