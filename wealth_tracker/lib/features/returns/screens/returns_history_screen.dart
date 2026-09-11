import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/money_text.dart';
import '../../../data/db/database.dart';
import '../providers/returns_providers.dart';

/// Every return already marked "Received" -- the Returns tab's own
/// equivalent of a ledger's past transactions, reachable from its AppBar
/// rather than mixed into the pending list.
class ReturnsHistoryScreen extends ConsumerWidget {
  const ReturnsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(returnsHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Returns history')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (history) {
          if (history.isEmpty) {
            return const Center(child: Text('Nothing received yet.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final item in history) _HistoryCard(item: item)],
          );
        },
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.item});

  final Return item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
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
      onDismissed: (_) =>
          ref.read(returnsRepositoryProvider).deleteReturn(item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.vendor,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  MoneyText(formatMoney(item.amount, item.currency)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Received ${_formatDate(item.receivedAt!)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.textDim),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(returnsRepositoryProvider)
                        .markPending(item.id),
                    child: const Text('Undo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
