import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/ledger_home_screen.dart';
import 'ledger_providers.dart';

const quickAddLedgerHost = 'add_ledger_entry';

/// Handles a launch (cold-start or already-running) coming from the
/// "Add Payment" home-screen widget. If that widget instance was
/// configured for a specific person (see the widget's configure screen,
/// native-side), the URI carries `counterpartyId` and we jump straight to
/// their add-entry form. Otherwise: exactly one counterparty is an
/// unambiguous default; more than one sends the user to pick.
Future<void> handleQuickAddLaunch(Uri? uri, WidgetRef ref) async {
  if (uri?.host != quickAddLedgerHost) return;

  final navigator = await _awaitNavigator();
  if (navigator == null) return;

  final configuredId = uri!.queryParameters['counterpartyId'];
  final counterparties = await ref.read(ledgerRepositoryProvider).watchCounterparties().first;

  final matches = counterparties.where((c) => c.id == configuredId);
  final configuredMatch = matches.isEmpty ? null : matches.first;

  if (configuredMatch != null) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(counterpartyId: configuredMatch.id, closeAppOnSave: true),
      ),
    );
  } else if (counterparties.length == 1) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(counterpartyId: counterparties.first.id, closeAppOnSave: true),
      ),
    );
  } else {
    navigator.push(MaterialPageRoute(builder: (_) => const LedgerHomeScreen()));
  }
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
