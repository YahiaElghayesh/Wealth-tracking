import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/db/database.dart';
import '../providers/settings_providers.dart';

/// Manage the fully-isolated profiles a user can switch between (see
/// `AppBottomNav`'s sibling picker on the Net Worth app bar for the actual
/// switcher) — add, rename, delete. Every other screen's data (Net Worth,
/// Ledger, Statistics, Calculator, even Settings items like categories and
/// cards) is scoped to whichever profile is active.
class ProfilesSettingsScreen extends ConsumerWidget {
  const ProfilesSettingsScreen({super.key});

  Future<void> _addProfile(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, title: 'Add profile');
    if (name == null || name.isEmpty) return;
    await ref.read(profileRepositoryProvider).addProfile(name);
  }

  Future<void> _renameProfile(BuildContext context, WidgetRef ref, Profile profile) async {
    final name = await _promptName(context, title: 'Rename profile', initial: profile.name);
    if (name == null || name.isEmpty || name == profile.name) return;
    await ref.read(profileRepositoryProvider).renameProfile(profile.id, name);
  }

  Future<String?> _promptName(BuildContext context, {required String title, String? initial}) {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Family, Business'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProfile(BuildContext context, WidgetRef ref, Profile profile, List<Profile> all) async {
    if (all.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Can't delete the only profile.")),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete profile?'),
            content: Text(
              'This permanently deletes "${profile.name}" and everything in it — every asset, ledger, '
              "statistic and calculator entry. This can't be undone.",
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final wasActive = ref.read(activeProfileIdProvider) == profile.id;
    await ref.read(profileRepositoryProvider).deleteProfile(profile.id);
    if (wasActive) {
      final fallback = all.firstWhere((p) => p.id != profile.id).id;
      await ref.read(settingsRepositoryProvider).setActiveProfileId(fallback);
      ref.read(activeProfileIdProvider.notifier).state = fallback;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesStreamProvider);
    final activeId = ref.watch(activeProfileIdProvider);
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Profiles')),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (profiles) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            itemBuilder: (context, i) {
              final profile = profiles[i];
              final active = profile.id == activeId;
              return Dismissible(
                key: ValueKey(profile.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  await _deleteProfile(context, ref, profile, profiles);
                  return false;
                },
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: active ? Theme.of(context).colorScheme.primary : colors.border),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: active ? Theme.of(context).colorScheme.primary : colors.surface2,
                      foregroundColor: active ? Colors.white : colors.textDim,
                      child: Text(profile.name.isEmpty ? '?' : profile.name[0].toUpperCase()),
                    ),
                    title: Text(profile.name),
                    subtitle: active ? const Text('Active') : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Rename',
                      onPressed: () => _renameProfile(context, ref, profile),
                    ),
                    onTap: () async {
                      if (active) return;
                      await ref.read(settingsRepositoryProvider).setActiveProfileId(profile.id);
                      ref.read(activeProfileIdProvider.notifier).state = profile.id;
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addProfile(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
