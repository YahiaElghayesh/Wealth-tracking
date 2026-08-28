import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'ledger_providers.dart';

/// Mirrors the counterparty list (id + name only) into home_widget's
/// shared storage, so the quick-add widget's native configuration screen
/// can show "which person" options without touching the drift database
/// directly. Watched once at the app root, same pattern as
/// `homeWidgetSyncProvider`.
final widgetCounterpartiesSyncProvider = Provider<void>((ref) {
  final counterparties = ref.watch(counterpartiesStreamProvider).valueOrNull;
  if (counterparties == null) return;

  final json = jsonEncode([
    for (final c in counterparties) {'id': c.id, 'name': c.name},
  ]);
  unawaited(HomeWidget.saveWidgetData<String>('counterparties_json', json));
});
