import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../networth/providers/asset_providers.dart' show databaseProvider;

/// Mirrors every registered credit card's last-four-digits -- across every
/// profile, not just the active one -- into home_widget's shared storage,
/// so SmsReceiver.kt can use it as a native, synchronous 4th criterion for
/// recognizing a bank card SMS ("does this SMS's 4-digit number match a
/// card I've actually registered") without needing database access itself.
/// Deliberately unscoped by profile: the user's ask was "even if I'm not
/// selecting the profile [that card belongs to]" -- a card on a different
/// profile than whichever one happens to be active should still count.
/// Watched once at the app root, same pattern as
/// `widgetCounterpartiesSyncProvider`.
final knownCardsSyncProvider = Provider<void>((ref) {
  final db = ref.watch(databaseProvider);
  final subscription = db.select(db.creditCards).watch().listen((cards) {
    final lastFourDigits = {
      for (final c in cards)
        if (c.lastFourDigits != null && c.lastFourDigits!.isNotEmpty) c.lastFourDigits!,
    }.toList();
    unawaited(HomeWidget.saveWidgetData<String>('known_card_last_four_digits', jsonEncode(lastFourDigits)));
  });
  ref.onDispose(subscription.cancel);
});
