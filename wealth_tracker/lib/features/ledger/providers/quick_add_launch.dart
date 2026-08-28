import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/ledger_home_screen.dart';
import 'ledger_providers.dart';

const quickAddLedgerHost = 'add_ledger_entry';

/// Handles a launch (cold-start or already-running) coming from the
/// "Add Payment" home-screen widget. Jumps straight into the add-entry
/// form when there's exactly one counterparty (the common case — logging
/// payments for one parent); otherwise sends the user to pick one.
Future<void> handleQuickAddLaunch(Uri? uri, WidgetRef ref) async {
  if (uri?.host != quickAddLedgerHost) return;

  final navigator = navigatorKey.currentState;
  if (navigator == null) return;

  final counterparties = await ref.read(ledgerRepositoryProvider).watchCounterparties().first;

  if (counterparties.length == 1) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(counterpartyId: counterparties.first.id),
      ),
    );
  } else {
    navigator.push(MaterialPageRoute(builder: (_) => const LedgerHomeScreen()));
  }
}
