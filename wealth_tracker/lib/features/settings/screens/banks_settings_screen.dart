import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../providers/sms_rule_providers.dart';

/// The shared list of bank names Credit Cards, Bank Accounts, and SMS
/// Rules all pick from -- add/rename/remove any number of them.
class BanksSettingsScreen extends ConsumerWidget {
  const BanksSettingsScreen({super.key});

  Future<void> _addBank(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add bank'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. CIB',
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
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(bankRepositoryProvider).add(name);
    }
  }

  Future<void> _renameBank(
    BuildContext context,
    WidgetRef ref,
    Bank bank,
  ) async {
    final controller = TextEditingController(text: bank.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename bank'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && name != bank.name) {
      await ref.read(bankRepositoryProvider).rename(bank.id, name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banksAsync = ref.watch(banksStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Banks')),
      body: banksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (banks) {
          if (banks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No banks yet. Tap + to add one -- used by Credit cards, Bank accounts, and SMS Rules.',
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: banks.length,
            itemBuilder: (context, i) {
              final bank = banks[i];
              return Dismissible(
                key: ValueKey(bank.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete),
                ),
                onDismissed: (_) =>
                    ref.read(bankRepositoryProvider).delete(bank.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_outlined),
                    title: Text(bank.name),
                    trailing: const Icon(Icons.edit, size: 18),
                    onTap: () => _renameBank(context, ref, bank),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addBank(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
