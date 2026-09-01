import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../networth/providers/asset_providers.dart' show databaseProvider;
import '../../settings/providers/settings_providers.dart';

/// Mirrors the *active* profile's Vendor Rule patterns into home_widget's
/// shared storage, so SmsReceiver.kt can use them as a native, synchronous
/// check for "does this charge SMS's vendor look like one a Vendor Rule
/// already resolves" -- without needing database access itself. A match
/// there means the charge is committed straight to the ledger in the
/// background with no notification and no confirmation needed, the same
/// zero-tap outcome the notification's own "Quick add" button already
/// gave -- just triggered automatically instead of requiring that tap.
///
/// Scoped to the active profile specifically -- unlike
/// `knownCardsSyncProvider`, which is deliberately unscoped -- because
/// `commitSmsQuickAdd` (sms_ledger_processor.dart), the Dart logic this
/// native check hands off to, only ever looks up rules for whichever
/// profile is active *at the moment the background task actually runs*.
/// Syncing patterns from every profile here would let the native side
/// route a charge to that silent auto-commit path only for it to find no
/// matching rule there and drop the charge entirely, with no notification
/// ever shown as a fallback. Re-synced whenever the active profile
/// changes, not just when a rule is added/edited/removed.
final knownVendorPatternsSyncProvider = Provider<void>((ref) {
  final db = ref.watch(databaseProvider);
  final profileId = ref.watch(activeProfileIdProvider);
  final subscription =
      (db.select(
        db.vendorRules,
      )..where((r) => r.profileId.equals(profileId))).watch().listen((rules) {
        final patterns = [for (final r in rules) r.vendorPattern.toLowerCase()];
        unawaited(
          HomeWidget.saveWidgetData<String>(
            'known_vendor_patterns',
            jsonEncode(patterns),
          ),
        );
      });
  ref.onDispose(subscription.cancel);
});
