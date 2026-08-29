import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/ledger_category_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/db/database.dart';
import '../../ledger/providers/ledger_providers.dart';

/// User-managed ledger expense categories — the quick-pick chips on the
/// add-transaction screen, each with an emoji icon. "Other" is always
/// available there too, as a built-in free-text fallback, so it isn't
/// listed (or manageable) here.
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

  Future<void> _pickIcon(BuildContext context, WidgetRef ref, LedgerCategory category) async {
    final colors = context.appColors;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Text('Choose an icon', style: Theme.of(context).textTheme.titleMedium),
              Text(category.name, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textDim)),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final option in categoryIconOptions)
                    _IconOption(
                      emoji: option,
                      selected: option == category.icon,
                      onTap: () => Navigator.pop(context, option),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      await ref.read(ledgerCategoryRepositoryProvider).updateIcon(category.id, picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(ledgerCategoriesStreamProvider);
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories & icons')),
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
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete),
                ),
                onDismissed: (_) => ref.read(ledgerCategoryRepositoryProvider).delete(category.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: ListTile(
                    leading: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _pickIcon(context, ref, category),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: Text(category.icon ?? fallbackCategoryEmoji, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
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

class _IconOption extends StatelessWidget {
  const _IconOption({required this.emoji, required this.selected, required this.onTap});

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : colors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
