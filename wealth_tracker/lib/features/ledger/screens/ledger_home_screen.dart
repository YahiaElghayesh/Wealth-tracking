import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/settings_action.dart';
import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../networth/providers/asset_providers.dart'
    show pricesUsdPerUnitProvider;
import '../providers/ledger_providers.dart';
import '../providers/ledger_shortcut_channel.dart';
import 'counterparty_detail_screen.dart';

class LedgerHomeScreen extends ConsumerWidget {
  const LedgerHomeScreen({super.key});

  Future<void> _addCounterparty(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    var includeInStatistics = true;
    var includeInCalculator = true;
    var visible = true;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add ledger'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Dad',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include in Statistics'),
                value: includeInStatistics,
                onChanged: (v) => setDialogState(() => includeInStatistics = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include in Calculator'),
                value: includeInCalculator,
                onChanged: (v) => setDialogState(() => includeInCalculator = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show in ledger list'),
                subtitle: const Text(
                  'Turn off to hide it without deleting anything',
                ),
                value: visible,
                onChanged: (v) => setDialogState(() => visible = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref
          .read(ledgerRepositoryProvider)
          .addCounterparty(
            name,
            includeInStatistics: includeInStatistics,
            includeInCalculator: includeInCalculator,
            visible: visible,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterpartiesAsync = ref.watch(counterpartiesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_home_screen_outlined),
            tooltip: 'Add home screen icon',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _LedgerShortcutPickerDialog(),
            ),
          ),
          const HideValuesAction(),
          const SettingsAction(),
        ],
      ),
      body: counterpartiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (counterparties) {
          if (counterparties.isEmpty) {
            return const Center(
              child: Text('Add a ledger to start tracking payments.'),
            );
          }
          final visibleCounterparties = counterparties
              .where((c) => c.visible)
              .toList();
          final hiddenCounterparties = counterparties
              .where((c) => !c.visible)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...visibleCounterparties.map(
                (c) => _CounterpartyTile(counterparty: c),
              ),
              if (hiddenCounterparties.isNotEmpty)
                _HiddenLedgersSection(counterparties: hiddenCounterparties),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCounterparty(context, ref),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

/// The explicit "which ledger is this icon for?" prompt -- a per-row pin
/// button (see `_CounterpartyTile`) already implies its own ledger by
/// which row it's on, but this is the dedicated flow for someone who just
/// wants to build up several pinned icons in one sitting without hunting
/// through the list row by row. Stays open after each pin (showing a brief
/// "pinned" state on that row) so tapping several ledgers in a row creates
/// several icons without reopening the dialog each time.
class _LedgerShortcutPickerDialog extends ConsumerStatefulWidget {
  const _LedgerShortcutPickerDialog();

  @override
  ConsumerState<_LedgerShortcutPickerDialog> createState() =>
      _LedgerShortcutPickerDialogState();
}

class _LedgerShortcutPickerDialogState
    extends ConsumerState<_LedgerShortcutPickerDialog> {
  final _pinning = <String>{};
  final _pinned = <String>{};

  Future<void> _pin(Counterparty counterparty) async {
    setState(() => _pinning.add(counterparty.id));
    final requested = await pinLedgerShortcut(
      counterpartyId: counterparty.id,
      name: counterparty.name,
    );
    if (!mounted) return;
    setState(() {
      _pinning.remove(counterparty.id);
      if (requested) _pinned.add(counterparty.id);
    });
    if (!requested) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't request a home-screen icon on this device."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final counterparties =
        ref.watch(counterpartiesStreamProvider).valueOrNull ?? const [];

    return AlertDialog(
      title: const Text('Add home screen icon'),
      content: SizedBox(
        width: double.maxFinite,
        child: counterparties.isEmpty
            ? const Text('Add a ledger first.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Which ledger should this icon open straight to?',
                      ),
                    ),
                  ),
                  for (final counterparty in counterparties)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(
                          counterparty.name.isEmpty
                              ? '?'
                              : counterparty.name[0].toUpperCase(),
                        ),
                      ),
                      title: Text(counterparty.name),
                      trailing: _pinning.contains(counterparty.id)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _pinned.contains(counterparty.id)
                          ? const Icon(Icons.check_circle)
                          : const Icon(Icons.add_to_home_screen_outlined),
                      onTap: _pinning.contains(counterparty.id)
                          ? null
                          : () => _pin(counterparty),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Shared by [_CounterpartyTile] and [_HiddenLedgersSection] -- a hidden
/// ledger's row reopens this exact dialog rather than a separate one, so
/// switching "Show in ledger list" back on is the same flow either way.
Future<void> _editCounterparty(
  BuildContext context,
  WidgetRef ref,
  Counterparty counterparty,
) async {
  final controller = TextEditingController(text: counterparty.name);
  var includeInStatistics = counterparty.includeInStatistics;
  var includeInCalculator = counterparty.includeInCalculator;
  var visible = counterparty.visible;
  final save = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Edit ledger'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include in Statistics'),
              value: includeInStatistics,
              onChanged: (v) => setDialogState(() => includeInStatistics = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include in Calculator'),
              value: includeInCalculator,
              onChanged: (v) => setDialogState(() => includeInCalculator = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show in ledger list'),
              subtitle: const Text(
                'Turn off to hide it without deleting anything',
              ),
              value: visible,
              onChanged: (v) => setDialogState(() => visible = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  final name = controller.text.trim();
  if (save == true && name.isNotEmpty) {
    await ref
        .read(ledgerRepositoryProvider)
        .updateCounterparty(
          counterparty.copyWith(
            name: name,
            includeInStatistics: includeInStatistics,
            includeInCalculator: includeInCalculator,
            visible: visible,
          ),
        );
  }
}

class _CounterpartyTile extends ConsumerWidget {
  const _CounterpartyTile({required this.counterparty});

  final Counterparty counterparty;

  /// Requests a pinned home-screen shortcut for this specific ledger --
  /// see ledger_shortcut_channel.dart / LedgerShortcuts.kt. A user can tap
  /// this on as many ledger rows as they want, building up one icon per
  /// ledger, each opening straight to that ledger's add-payment form
  /// instead of the "which ledger?" picker a single generic shortcut can't
  /// avoid.
  Future<void> _pinShortcut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final requested = await pinLedgerShortcut(
      counterpartyId: counterparty.id,
      name: counterparty.name,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          requested
              ? 'Check your home screen to confirm adding "${counterparty.name}".'
              : "Couldn't request a home-screen icon on this device.",
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete ledger?'),
            content: Text(
              'This removes "${counterparty.name}" and every payment recorded against it. This can\'t be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      await ref
          .read(ledgerRepositoryProvider)
          .deleteCounterparty(counterparty.id);
    }
    return confirmed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(
      transactionsStreamProvider(counterparty.id),
    );
    final prices = ref.watch(pricesUsdPerUnitProvider);
    final hideValues = ref.watch(hideValuesProvider);
    final transactions = transactionsAsync.valueOrNull;
    final balance = transactions == null
        ? null
        : runningBalance(transactions, prices).amount;

    return Dismissible(
      key: ValueKey(counterparty.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, ref),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CounterpartyDetailScreen(counterparty: counterparty),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      child: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hideValues ? '••••••' : counterparty.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_to_home_screen_outlined,
                        size: 20,
                      ),
                      tooltip: 'Pin to home screen',
                      onPressed: () => _pinShortcut(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit',
                      onPressed: () =>
                          _editCounterparty(context, ref, counterparty),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                // The balance gets its own full-width row below the name
                // instead of squeezing into a ListTile subtitle next to
                // three trailing icons -- that left barely any room for
                // the amount, ellipsis-truncating a real balance like
                // "13,976.00" down to "13,9…" and making it unreadable.
                if (!hideValues) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: balance == null
                        ? const Text('Loading…')
                        : balance == 0
                        ? const Text('Settled up')
                        : Row(
                            children: [
                              Text(balance > 0 ? 'Owes you ' : 'You owe '),
                              Flexible(
                                child: MoneyText(
                                  formatMoney(balance.abs(), defaultCurrency),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A collapsed-by-default "Hidden ledgers (N)" row at the end of the list --
/// the only way to find and re-show a ledger whose "Show in ledger list"
/// switch (see `_edit`/`_addCounterparty`) is off, since a hidden ledger is
/// otherwise nowhere in the main list at all. Tapping a hidden ledger here
/// still opens the normal Edit dialog, so switching it back on is a single
/// flip away, same as turning it off in the first place.
class _HiddenLedgersSection extends ConsumerStatefulWidget {
  const _HiddenLedgersSection({required this.counterparties});

  final List<Counterparty> counterparties;

  @override
  ConsumerState<_HiddenLedgersSection> createState() =>
      _HiddenLedgersSectionState();
}

class _HiddenLedgersSectionState extends ConsumerState<_HiddenLedgersSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: Text('Hidden ledgers (${widget.counterparties.length})'),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            for (final counterparty in widget.counterparties)
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.account_balance_wallet_outlined),
                ),
                title: Text(counterparty.name),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: 'Show in ledger list',
                  onPressed: () => ref
                      .read(ledgerRepositoryProvider)
                      .updateCounterparty(counterparty.copyWith(visible: true)),
                ),
                onTap: () => _editCounterparty(context, ref, counterparty),
              ),
        ],
      ),
    );
  }
}
