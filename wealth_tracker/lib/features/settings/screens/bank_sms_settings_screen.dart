import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../ledger/providers/ledger_providers.dart';
import '../providers/settings_providers.dart';
import 'sms_rules_settings_screen.dart';

/// Enable/disable bank SMS detection and manage the vendor rules that
/// auto-fill a detected charge's ledger and category. See SmsReceiver.kt
/// for why this doesn't depend on a third-party SMS-reading plugin.
class BankSmsSettingsScreen extends ConsumerStatefulWidget {
  const BankSmsSettingsScreen({super.key});

  @override
  ConsumerState<BankSmsSettingsScreen> createState() =>
      _BankSmsSettingsScreenState();
}

class _BankSmsSettingsScreenState extends ConsumerState<BankSmsSettingsScreen>
    with WidgetsBindingObserver {
  bool _enabled = false;
  bool _requesting = false;
  bool _silent = false;

  /// Null while still checking. Only meaningful when [_enabled] is true --
  /// covers anyone who turned this on before POST_NOTIFICATIONS was
  /// requested at all (see [_toggle]'s doc comment): their SMS capture
  /// looks "on" but detected charges were silently never surfacing.
  bool? _notificationsGranted;

  /// Null while still checking. Whether Android is letting this app run
  /// unrestricted in the background -- when it isn't, the OS can (and does)
  /// silently delay or drop the WorkManager task that carries a detected
  /// charge/payment SMS to the card-balance update and (for a Quick Add
  /// match) the ledger entry itself, especially once the app hasn't been
  /// opened in a while: reported as "the SMS balance update doesn't work
  /// sometimes, especially when the app is closed." Checked at open and
  /// re-checked on every app resume (see [didChangeAppLifecycleState])
  /// rather than only once, since the user can flip this from outside the
  /// app (a phone-wide battery saver mode, a manufacturer's own "manage
  /// apps" screen, or the system settings screen
  /// [_fixBackgroundRestriction] itself opens) at any time.
  bool? _unrestrictedBackground;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enabled = ref.read(settingsRepositoryProvider).smsCaptureEnabled;
    _silent = ref.read(settingsRepositoryProvider).smsNotificationsSilent;
    if (_enabled) _checkNotificationPermission();
    _checkBackgroundRestriction();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-checked every time the app resumes -- [_fixBackgroundRestriction]
    // opens Android's own system settings screen for this, which has no
    // result Flutter can await directly; picking it back up on resume is
    // what actually reflects a choice made there once the user returns.
    // Also covers the setting changing from outside the app entirely (a
    // phone-wide battery saver mode, a manufacturer's own "manage apps"
    // screen) rather than only the one path this screen's own button offers.
    if (state == AppLifecycleState.resumed) _checkBackgroundRestriction();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (mounted) setState(() => _notificationsGranted = status.isGranted);
  }

  Future<void> _checkBackgroundRestriction() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (mounted) setState(() => _unrestrictedBackground = status.isGranted);
  }

  Future<void> _fixBackgroundRestriction() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    if (mounted) setState(() => _unrestrictedBackground = status.isGranted);
  }

  Future<void> _fixNotificationPermission() async {
    final status = await Permission.notification.request();
    if (!mounted) return;
    setState(() => _notificationsGranted = status.isGranted);
    if (!status.isGranted && status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications were denied. Enable them for Money Hub in your phone\'s app settings.',
          ),
        ),
      );
    }
  }

  Future<void> _toggle(bool wantEnabled) async {
    final settings = ref.read(settingsRepositoryProvider);
    if (!wantEnabled) {
      await settings.setSmsCaptureEnabled(false);
      setState(() => _enabled = false);
      return;
    }

    setState(() => _requesting = true);
    final status = await Permission.sms.request();
    // Detecting the SMS itself only needs Permission.sms -- but the whole
    // point of this feature is the notification it posts (see SmsReceiver.kt),
    // and Android 13+ silently drops any NotificationManager.notify() call
    // until POST_NOTIFICATIONS is separately granted. Not requesting this
    // too was the "SMS detection is on but nothing ever happens" bug: SMS
    // detection genuinely worked, the notification just never appeared.
    final notificationStatus = await Permission.notification.request();
    final granted = status.isGranted;
    await settings.setSmsCaptureEnabled(granted);
    if (!mounted) return;
    setState(() {
      _enabled = granted;
      _notificationsGranted = notificationStatus.isGranted;
      _requesting = false;
    });

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.isPermanentlyDenied
                ? 'SMS permission was denied. Enable it for Money Hub in your phone\'s app settings to turn this on.'
                : 'SMS permission is needed for this to work.',
          ),
        ),
      );
    } else if (!notificationStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notificationStatus.isPermanentlyDenied
                ? 'Notifications were denied. Enable them for Money Hub in your phone\'s app '
                      'settings, or detected charges will never show up.'
                : 'Notification permission is needed too, or detected charges never show up.',
          ),
        ),
      );
    }
  }

  Future<void> _toggleSilent(bool silent) async {
    await ref.read(settingsRepositoryProvider).setSmsNotificationsSilent(silent);
    if (mounted) setState(() => _silent = silent);
  }

  @override
  Widget build(BuildContext context) {
    final counterparties =
        ref.watch(counterpartiesStreamProvider).valueOrNull ?? const [];

    final colors = context.appColors;
    final rowDecoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: colors.border),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Bank SMS detection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: rowDecoration,
            child: SwitchListTile(
              secondary: _IconChip(Icons.sms_outlined),
              title: const Text('Read bank SMS'),
              subtitle: const Text(
                'Auto-adds when an SMS Rule matches; otherwise notifies you to confirm',
              ),
              value: _enabled,
              onChanged: _requesting ? null : _toggle,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: rowDecoration,
            child: SwitchListTile(
              secondary: _IconChip(Icons.notifications_off_outlined),
              title: const Text('Silent notifications'),
              subtitle: const Text(
                'No sound or vibration for a detected charge/payment; off matches your phone\'s normal ringer',
              ),
              value: _silent,
              onChanged: _toggleSilent,
            ),
          ),
          if (_enabled && _notificationsGranted == false) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bad.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.bad.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    color: colors.bad,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Notifications aren\'t granted, so detected charges never show up even '
                      'though SMS reading is on.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.bad),
                    ),
                  ),
                  TextButton(
                    onPressed: _fixNotificationPermission,
                    child: const Text('Fix'),
                  ),
                ],
              ),
            ),
          ],
          if (_enabled && _unrestrictedBackground == false) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bad.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.bad.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.battery_alert_outlined,
                    color: colors.bad,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your phone is restricting this app\'s background activity, so a bank '
                      'text can arrive and never get processed -- especially once the app '
                      'hasn\'t been opened in a while.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.bad),
                    ),
                  ),
                  TextButton(
                    onPressed: _fixBackgroundRestriction,
                    child: const Text('Fix'),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Text(
              'When your bank texts you, this checks it against your SMS Rules -- a '
              'ledger-payment rule adds it straight to that ledger with nothing to confirm '
              'when it\'s a repayment, or opens a quick review screen to confirm a charge. '
              'A credit-card/bank-account rule keeps that balance current automatically '
              'either way. Needs the sensitive "read SMS" permission to work.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textDim),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: rowDecoration,
            child: ListTile(
              leading: _IconChip(Icons.account_balance_wallet_outlined),
              title: const Text('Default ledger'),
              subtitle: const Text(
                'Pre-selected on Confirm payment when no vendor rule matches',
              ),
              trailing: DropdownButton<String>(
                value:
                    counterparties.any(
                      (c) =>
                          c.id ==
                          ref.watch(defaultLedgerCounterpartyIdProvider),
                    )
                    ? ref.watch(defaultLedgerCounterpartyIdProvider)
                    : null,
                hint: const Text('None'),
                underline: const SizedBox.shrink(),
                items: counterparties
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (id) async {
                  await ref
                      .read(settingsRepositoryProvider)
                      .setDefaultLedgerCounterpartyId(id);
                  ref.read(defaultLedgerCounterpartyIdProvider.notifier).state =
                      id;
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: rowDecoration,
            child: ListTile(
              leading: _IconChip(Icons.rule_outlined),
              title: const Text('SMS Rules'),
              subtitle: const Text(
                'Build a rule from a real bank text -- updates a card/account balance, or adds a ledger payment',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SmsRulesSettingsScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: context.appColors.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
    );
  }
}
