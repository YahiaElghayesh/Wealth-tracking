import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

/// Overwrites home_widget's shared `known_vendor_patterns` storage with an
/// empty list -- neutralizing SmsReceiver.kt's native `matchesKnownVendorPattern`
/// pre-filter, which used to fast-path a charge straight to
/// `commitSmsQuickAdd` (skipping the usual notification) whenever the
/// sender matched an old Vendor Rule pattern synced here. Vendor Rules
/// were replaced by SMS Rules' 'ledgerPayment' operation, which
/// `commitSmsQuickAdd` (sms_ledger_processor.dart) now matches against
/// instead -- but that native pre-filter is a separate, hardwired keyword
/// check that has no idea SMS Rules exist. Left un-neutralized, a device
/// upgrading from before this change would keep fast-pathing on its old,
/// no-longer-read Vendor Rule patterns: native skips the notification,
/// `commitSmsQuickAdd` finds no matching SMS Rule (since none has been
/// recreated yet), and the charge is silently dropped with nothing shown
/// at all -- worse than not recognizing it. Pushing `[]` here instead
/// means that pre-filter never matches, so every charge always falls
/// through to the safe "post a notification, let it get handled normally"
/// path, where the real, tested SMS Rules engine gets a fair chance to
/// run either way.
final knownVendorPatternsSyncProvider = Provider<void>((ref) {
  unawaited(
    HomeWidget.saveWidgetData<String>(
      'known_vendor_patterns',
      jsonEncode(const <String>[]),
    ),
  );
});
