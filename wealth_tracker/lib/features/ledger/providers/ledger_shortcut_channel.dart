import 'package:flutter/services.dart';

const _channel = MethodChannel('money_hub/shortcuts');

/// Requests a pinned home-screen shortcut for [counterpartyId]/[name] --
/// launches straight to that ledger's add-payment form (see
/// `LedgerShortcuts.kt`), distinct from the "Add Payment" widget and
/// carrying its own generated avatar so several pinned ledgers stay
/// visually distinguishable on the home screen. A user can call this once
/// per ledger to build up as many of these as they want.
///
/// Returns false (rather than throwing) when the platform doesn't support
/// pinned shortcuts at all, or the request otherwise couldn't be
/// submitted -- true only confirms the *request* reached the launcher, not
/// that the user went on to accept its own placement confirmation, which
/// this has no way to observe.
Future<bool> pinLedgerShortcut({required String counterpartyId, required String name}) async {
  final result = await _channel.invokeMethod<bool>(
    'pinLedgerShortcut',
    {'counterpartyId': counterpartyId, 'name': name},
  );
  return result ?? false;
}
