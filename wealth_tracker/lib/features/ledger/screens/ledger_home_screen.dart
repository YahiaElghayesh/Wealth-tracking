import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/settings_action.dart';
import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../networth/providers/asset_providers.dart'
    show pricesUsdPerUnitProvider;
import '../../returns/screens/returns_history_screen.dart';
import '../../returns/screens/returns_tab_view.dart';
import '../providers/ledger_providers.dart';
import '../providers/ledger_shortcut_channel.dart';
import 'counterparty_detail_screen.dart';

/// Ledgers, Tabs and Returns as three tabs of one screen -- a ledger and a
/// tab used to sit intermixed in a single list (distinguished only by the
/// [Counterparty.isTab] flag), which is what the add/edit dialogs' own
/// Ledger/Tab toggle further down still reflects; splitting them into their
/// own [TabBarView] pages here is purely a display change; a Return is a
/// third, unrelated kind of thing entirely (see returns_tab_view.dart) that
/// simply shares this screen's tab strip rather than adding a whole new
/// bottom-nav icon.
class LedgerHomeScreen extends ConsumerStatefulWidget {
  const LedgerHomeScreen({super.key});

  @override
  ConsumerState<LedgerHomeScreen> createState() => _LedgerHomeScreenState();
}

class _LedgerHomeScreenState extends ConsumerState<LedgerHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        // Only the settled index matters here (which FAB/AppBar action to
        // show) -- listening unconditionally would also fire mid-swipe,
        // rebuilding this Scaffold on every frame of the transition.
        if (!_tabController.indexIsChanging) setState(() {});
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addCounterparty(
    BuildContext context,
    WidgetRef ref, {
    required bool initialIsTab,
  }) async {
    final controller = TextEditingController();
    var includeInStatistics = true;
    var includeInCalculator = true;
    var visible = true;
    var isTab = initialIsTab;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isTab ? 'Add tab' : 'Add ledger'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Ledger')),
                    ButtonSegment(value: true, label: Text('Tab')),
                  ],
                  selected: {isTab},
                  onSelectionChanged: (s) =>
                      setDialogState(() => isTab = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Dad',
                  ),
                ),
                if (!isTab) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include in Statistics'),
                    value: includeInStatistics,
                    onChanged: (v) =>
                        setDialogState(() => includeInStatistics = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include in Calculator'),
                    value: includeInCalculator,
                    onChanged: (v) =>
                        setDialogState(() => includeInCalculator = v),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "A tab is just a running record of payments back and "
                      "forth -- it never counts toward Statistics or the "
                      "Calculator, since it doesn't mean anyone owes anyone "
                      "anything.",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show in list'),
                  subtitle: const Text(
                    'Turn off to hide it without deleting anything',
                  ),
                  value: visible,
                  onChanged: (v) => setDialogState(() => visible = v),
                ),
              ],
            ),
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
            isTab: isTab,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onReturnsTab = _tabController.index == 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledgers'),
        actions: [
          if (onReturnsTab)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Returns history',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReturnsHistoryScreen()),
              ),
            )
          else
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ledgers'),
            Tab(text: 'Tabs'),
            Tab(text: 'Returns'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CounterpartyListView(isTab: false),
          _CounterpartyListView(isTab: true),
          ReturnsTabView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onReturnsTab
            ? showAddReturnDialog(context, ref)
            : _addCounterparty(
                context,
                ref,
                initialIsTab: _tabController.index == 1,
              ),
        child: Icon(onReturnsTab ? Icons.add : Icons.person_add),
      ),
    );
  }
}

/// One of the two counterparty tabs -- [isTab] picks which; everything
/// else (empty state aside) is identical, since [Counterparty] itself
/// already carries all the ledger-vs-tab-specific behavior (balance
/// wording, Statistics/Calculator opt-outs, ...) that [_CounterpartyTile]
/// renders.
class _CounterpartyListView extends ConsumerWidget {
  const _CounterpartyListView({required this.isTab});

  final bool isTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterpartiesAsync = ref.watch(counterpartiesStreamProvider);

    return counterpartiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (all) {
        final counterparties = all.where((c) => c.isTab == isTab).toList();
        if (counterparties.isEmpty) {
          return Center(
            child: Text(
              isTab
                  ? 'Add a tab to start tracking payments.'
                  : 'Add a ledger to start tracking payments.',
            ),
          );
        }
        final visibleCounterparties = counterparties
            .where((c) => c.visible)
            .toList();
        final hiddenCounterparties = counterparties
            .where((c) => !c.visible)
            .toList();
        return ListView(
          // Extra bottom clearance so the last row -- including the
          // "Hidden" section once expanded -- never ends up sitting under
          // the shared add FAB.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            ...visibleCounterparties.map(
              (c) => _CounterpartyTile(counterparty: c),
            ),
            if (hiddenCounterparties.isNotEmpty)
              _HiddenLedgersSection(counterparties: hiddenCounterparties),
          ],
        );
      },
    );
  }
}

/// The explicit "which ledger is this icon for?" prompt, opened from this
/// screen's own AppBar action. Stays open after each pin (showing a brief
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
            : SingleChildScrollView(
                child: Column(
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
/// switching "Show in list" back on is the same flow either way.
Future<void> _editCounterparty(
  BuildContext context,
  WidgetRef ref,
  Counterparty counterparty,
) async {
  final controller = TextEditingController(text: counterparty.name);
  var includeInStatistics = counterparty.includeInStatistics;
  var includeInCalculator = counterparty.includeInCalculator;
  var visible = counterparty.visible;
  var isTab = counterparty.isTab;
  final save = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(isTab ? 'Edit tab' : 'Edit ledger'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Ledger')),
                  ButtonSegment(value: true, label: Text('Tab')),
                ],
                selected: {isTab},
                onSelectionChanged: (s) =>
                    setDialogState(() => isTab = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              if (!isTab) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include in Statistics'),
                  value: includeInStatistics,
                  onChanged: (v) =>
                      setDialogState(() => includeInStatistics = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include in Calculator'),
                  value: includeInCalculator,
                  onChanged: (v) =>
                      setDialogState(() => includeInCalculator = v),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "A tab is just a running record of payments back and "
                    "forth -- it never counts toward Statistics or the "
                    "Calculator, since it doesn't mean anyone owes anyone "
                    "anything.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show in list'),
                subtitle: const Text(
                  'Turn off to hide it without deleting anything',
                ),
                value: visible,
                onChanged: (v) => setDialogState(() => visible = v),
              ),
            ],
          ),
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
            isTab: isTab,
          ),
        );
  }
}

class _CounterpartyTile extends ConsumerWidget {
  const _CounterpartyTile({required this.counterparty});

  final Counterparty counterparty;

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(counterparty.isTab ? 'Delete tab?' : 'Delete ledger?'),
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
                    CircleAvatar(
                      child: Icon(
                        counterparty.isTab
                            ? Icons.swap_horiz
                            : Icons.account_balance_wallet_outlined,
                      ),
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
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit',
                      onPressed: () =>
                          _editCounterparty(context, ref, counterparty),
                    ),
                    IconButton(
                      icon: Icon(
                        counterparty.visible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      tooltip: counterparty.visible
                          ? 'Hide from list'
                          : 'Show in list',
                      onPressed: () => ref
                          .read(ledgerRepositoryProvider)
                          .updateCounterparty(
                            counterparty.copyWith(
                              visible: !counterparty.visible,
                            ),
                          ),
                    ),
                  ],
                ),
                // The balance gets its own full-width row below the name
                // instead of squeezing into a ListTile subtitle next to
                // trailing icons -- that left barely any room for the
                // amount, ellipsis-truncating a real balance like
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
                              Text(
                                counterparty.isTab
                                    ? (balance > 0
                                          ? "You've paid more, by "
                                          : "They've paid more, by ")
                                    : (balance > 0 ? 'Owes you ' : 'You owe '),
                              ),
                              Flexible(
                                child: MoneyText(
                                  formatMoney(balance.abs(), defaultCurrency),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: counterparty.isTab
                                      ? TextStyle(
                                          color: context.appColors.textBody,
                                        )
                                      : null,
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

/// A collapsed-by-default "Hidden (N)" row at the end of the list -- the
/// only way to find a ledger or tab whose "Show in list" switch (see
/// `_editCounterparty`/`_addCounterparty`) is off, since a hidden one is
/// otherwise nowhere in the main list at all. Once expanded, each hidden
/// counterparty renders as the exact same full `_CounterpartyTile` as the
/// main list -- balance, tapping in to open it, Edit, all of it -- so
/// "hidden" only ever means "not shown in the main list," never a
/// degraded view of the ledger or tab itself.
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
            title: Text('Hidden (${widget.counterparties.length})'),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              // No horizontal inset -- the ListView this section itself
              // sits in already provides that, and adding more here just
              // narrows these tiles below their normal width, truncating
              // a currency code that fits everywhere else.
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                children: [
                  for (final counterparty in widget.counterparties)
                    _CounterpartyTile(counterparty: counterparty),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
