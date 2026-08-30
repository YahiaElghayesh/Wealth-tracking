import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../features/settings/providers/settings_providers.dart';
import '../providers/core_providers.dart';
import '../theme/app_colors.dart';

/// Covers [child] with a fingerprint/Face ID (or device PIN/pattern,
/// local_auth's own fallback) prompt whenever [biometricLockEnabledProvider]
/// is on -- re-armed every time the app is backgrounded and resumed.
///
/// Deliberately overlays [child] in a [Stack] rather than swapping it out:
/// [child] is `_RootShell`, whose `initState` registers the
/// `home_widget`-tap listener that the "Add Payment" pinned shortcuts and
/// widget quick-add rely on (see `quick_add_launch.dart`). That listener has
/// to stay alive even while locked, and it responds by pushing
/// `AddTransactionScreen` straight onto the app's root [Navigator] -- a
/// route that lands on top of this entire gate, lock screen included, with
/// no biometric check in between. That's not a bypass being tolerated, it's
/// the explicit design: quick-adding a payment must never require
/// fingerprint/Face ID, only opening the full app does.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  final _localAuth = LocalAuthentication();
  bool _unlocked = false;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unlocked = !ref.read(settingsRepositoryProvider).biometricLockEnabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock on backgrounding, not just at cold start -- otherwise
    // switching away and back would leave the app permanently unlocked for
    // the rest of the process's life after the very first check.
    if (state != AppLifecycleState.paused) return;
    if (ref.read(biometricLockEnabledProvider) && _unlocked) {
      setState(() => _unlocked = false);
    }
  }

  Future<void> _authenticate() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) {
        // No fingerprint/face/PIN lock available on this device at all --
        // don't trap the user behind a gate that could never open.
        setState(() {
          _unlocked = true;
          _checking = false;
        });
        return;
      }
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock Money Hub',
        persistAcrossBackgrounding: true,
      );
      setState(() {
        _unlocked = ok;
        _checking = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _error = e.message ?? 'Authentication failed';
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(biometricLockEnabledProvider);
    final locked = enabled && !_unlocked;

    return Stack(
      children: [
        widget.child,
        if (locked) Positioned.fill(child: _LockScreen(checking: _checking, error: _error, onUnlock: _authenticate)),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.checking, required this.error, required this.onUnlock});

  final bool checking;
  final String? error;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // An opaque Container (not just a Material) is the outer layer on
    // purpose -- Container's render object reports itself hit-testable
    // ("opaque" HitTestBehavior), which is what actually stops a tap on the
    // dead background area from falling through to `_RootShell` underneath
    // in the Stack. A bare Material with no GestureDetector of its own
    // wouldn't block anything. The FilledButton below still gets its own
    // taps first, same as any other button on an opaque background.
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: context.appColors.accentSoft, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(Icons.fingerprint, size: 36, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text('Money Hub is locked', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock with your fingerprint or face to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appColors.textDim),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, textAlign: TextAlign.center, style: TextStyle(color: context.appColors.bad)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: checking ? null : onUnlock,
                    icon: checking
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.lock_open),
                    label: const Text('Unlock'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
