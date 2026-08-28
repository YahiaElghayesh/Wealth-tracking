import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../ledger/providers/ledger_providers.dart';

/// User-managed ledger expense categories — the quick-pick chips on the
/// add-transaction screen. "Other" is always available there too, as a
/// built-in free-text fallback, so it isn't listed (or manageable) here.
class LedgerCategoriesSettingsScreen extends ConsumerWidget {
  const LedgerCategoriesSettingsScreen({super.key});

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Subscriptions'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(ledgerCategoryRepositoryProvider).add(name);
    }
  }

  Future<void> _renameCategory(BuildContext context, WidgetRef ref, LedgerCategory category) async {
    final controller = TextEditingController(text: category.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename category'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && name != category.name) {
      await ref.read(ledgerCategoryRepositoryProvider).rename(category.id, name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(ledgerCategoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ledger categories')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No categories yet. Tap + to add one.'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final category = categories[i];
              return Dismissible(
                key: ValueKey(category.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete),
                ),
                onDismissed: (_) => ref.read(ledgerCategoryRepositoryProvider).delete(category.id),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(category.name),
                    trailing: const Icon(Icons.edit, size: 18),
                    onTap: () => _renameCategory(context, ref, category),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCategory(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
