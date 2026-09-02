import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/security/app_lock_exemption.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/ledger_home_screen.dart';
import 'ledger_providers.dart';

const quickAddLedgerHost = 'add_ledger_entry';

/// Handles a launch (cold-start or already-running) coming from the
/// "Add Payment" home-screen widget or a pinned per-ledger shortcut --
/// both fire the identical `home_widget` launch Intent/URI (see
/// LedgerShortcuts.kt's own doc comment), so this one function covers
/// both. If that widget instance was configured for a specific person
/// (see the widget's configure screen, native-side), the URI carries
/// `counterpartyId` and we jump straight to their add-entry form.
/// Otherwise: exactly one counterparty is an unambiguous default; more
/// than one sends the user to pick.
Future<void> handleQuickAddLaunch(Uri? uri, WidgetRef ref) async {
  if (uri?.host != quickAddLedgerHost) return;

  // Claimed immediately -- before the slower work below (awaiting the
  // Navigator, a database round-trip for the counterparty list) -- for the
  // same reason `processIncomingSms` claims its own exemption upfront: on
  // a slow or cold-starting device that chain can outlast [AppLockGate]'s
  // bounded wait for an exemption to appear, and without an early claim
  // here the OS biometric prompt could fire mid-launch (the reported "the
  // add payment icon asks me for biometrics" bug -- this function
  // previously never claimed anything at all). Released synchronously on
  // every path that doesn't end up pushing [AddTransactionScreen]; the
  // paths that do release a frame later instead (see the comment at each
  // of those `push` calls).
  QuickActionExemption.claim();

  final navigator = await _awaitNavigator();
  if (navigator == null) {
    QuickActionExemption.release();
    return;
  }

  final configuredId = uri!.queryParameters['counterpartyId'];
  final counterparties = await ref
      .read(ledgerRepositoryProvider)
      .watchCounterparties()
      .first;

  final matches = counterparties.where((c) => c.id == configuredId);
  final configuredMatch = matches.isEmpty ? null : matches.first;

  if (configuredMatch != null) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          counterpartyId: configuredMatch.id,
          closeAppOnSave: true,
        ),
      ),
    );
    _releaseAfterThisFrame();
  } else if (counterparties.length == 1) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          counterpartyId: counterparties.first.id,
          closeAppOnSave: true,
        ),
      ),
    );
    _releaseAfterThisFrame();
  } else {
    // Ambiguous -- sent to pick a ledger instead, and that screen claims
    // no exemption of its own, so nothing further will ever release this
    // claim if it's left outstanding.
    navigator.push(MaterialPageRoute(builder: (_) => const LedgerHomeScreen()));
    QuickActionExemption.release();
  }
}

/// [AddTransactionScreen]'s own initState claims its lifecycle-tied
/// exemption synchronously during this same frame's build phase, strictly
/// before any postFrameCallback fires -- so releasing the upfront claim
/// here, once the frame is done, can never let the exemption count touch
/// zero while the app is still locked and that screen is on screen.
void _releaseAfterThisFrame() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    QuickActionExemption.release();
  });
}

/// [navigatorKey]'s Navigator is usually already mounted by the time this
/// runs (callers wait for the first frame), but polls briefly rather than
/// giving up immediately, as a safety net against rarer timing races.
Future<NavigatorState?> _awaitNavigator() async {
  for (var attempt = 0; attempt < 10; attempt++) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) return navigator;
    await Future.delayed(const Duration(milliseconds: 100));
  }
  return null;
}

Future<Uri?>? _initialWidgetLaunchUriFuture;

/// Memoized wrapper around `HomeWidget.initiallyLaunchedFromHomeWidget()` --
/// that native call consumes/clears the launch Intent it reads on first
/// use, so calling the plugin directly from two independent call sites
/// (`main.dart`'s upfront cold-start check and `app.dart`'s own
/// post-first-frame check) would let only whichever ran first ever see a
/// real value. Every caller across the app should go through this
/// function instead of the plugin method directly.
Future<Uri?> takeInitialWidgetLaunchUri() {
  return _initialWidgetLaunchUriFuture ??=
      HomeWidget.initiallyLaunchedFromHomeWidget();
}
