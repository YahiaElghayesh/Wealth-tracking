import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/update/app_update_controller.dart';
import '../../../core/update/app_update_service.dart';

class AppUpdatesSettingsScreen extends ConsumerStatefulWidget {
  const AppUpdatesSettingsScreen({super.key});

  @override
  ConsumerState<AppUpdatesSettingsScreen> createState() => _AppUpdatesSettingsScreenState();
}

class _AppUpdatesSettingsScreenState extends ConsumerState<AppUpdatesSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Checking is cheap (one API call) and this is the one screen the user
    // only ever visits to find out whether there's something new -- may as
    // well save them the extra tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUpdateControllerProvider.notifier).check();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appUpdateControllerProvider);
    final controller = ref.read(appUpdateControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('App updates')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isUpdateCheckConfigured)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "This build wasn't produced with update checking configured "
                  '(no APP_UPDATE_TOKEN secret set in CI), so this screen can\'t '
                  'reach GitHub. See the README for how to set that up.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.currentBuildNumber > 0)
                      Text('Installed build: ${state.currentBuildNumber}'),
                    const SizedBox(height: 12),
                    _StatusView(state: state),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ActionButton(state: state, controller: controller),
          ],
        ],
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case AppUpdateStatus.idle:
      case AppUpdateStatus.checking:
        return const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Checking for updates…'),
          ],
        );
      case AppUpdateStatus.upToDate:
        return const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 18),
            SizedBox(width: 8),
            Text("You're on the latest build"),
          ],
        );
      case AppUpdateStatus.updateAvailable:
        return Text('Update available: build ${state.available!.buildNumber}');
      case AppUpdateStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Downloading update… ${(state.downloadProgress * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: state.downloadProgress),
          ],
        );
      case AppUpdateStatus.downloaded:
        return const Text('Downloaded — tap Install below to continue.');
      case AppUpdateStatus.error:
        return Text(
          state.errorMessage ?? 'Something went wrong.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        );
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.state, required this.controller});

  final AppUpdateState state;
  final AppUpdateController controller;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case AppUpdateStatus.updateAvailable:
        return FilledButton.icon(
          onPressed: controller.downloadAndInstall,
          icon: const Icon(Icons.download),
          label: const Text('Download & install'),
        );
      case AppUpdateStatus.downloaded:
        return FilledButton.icon(
          onPressed: controller.retryInstall,
          icon: const Icon(Icons.install_mobile),
          label: const Text('Install'),
        );
      case AppUpdateStatus.error:
      case AppUpdateStatus.upToDate:
        return OutlinedButton.icon(
          onPressed: controller.check,
          icon: const Icon(Icons.refresh),
          label: const Text('Check again'),
        );
      case AppUpdateStatus.idle:
      case AppUpdateStatus.checking:
      case AppUpdateStatus.downloading:
        return const SizedBox.shrink();
    }
  }
}
