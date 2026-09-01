import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../data/repositories/settings_repository.dart';
import '../../features/settings/providers/settings_providers.dart';
import '../providers/core_providers.dart';
import '../theme/app_colors.dart';
import 'quick_add_exemption.dart';

/// Waited before every auto-triggered biometric prompt (cold start, and
/// every resume from the background) -- not for pacing, but to give a
/// concurrently-arriving "Add Payment" quick-add push (see
/// `quick_add_launch.dart`) time to mount `AddTransactionScreen` and flip
/// [quickAddScreenActive] first. That push is asynchronous (it polls for
/// the root [Navigator] to be mounted, normally resolving well inside one
/// frame), so evaluating the exemption flag immediately would sometimes
/// race it and fire the OS biometric sheet over what's supposed to be a
/// zero-auth shortcut. 200ms is well past the push's typical completion
/// time but short enough that a normal app open still reads as instant.
///
/// The SMS-triggered `SmsReviewScreen` push used to share this same 200ms
/// window despite needing much longer -- unlike the quick-add push, it
/// first runs a chain of real drift/SQLite round-trips (dedupe check,
/// parse, the card-balance update, a vendor-rule lookup) before ever
/// reaching the point of pushing a screen, which on a real device
/// (especially at cold start, while other providers are also hitting the
/// database) could easily outlast this delay -- the biometric prompt would
/// then fire before the exemption was ever set (the reported "asked for
/// biometrics when adding a payment from an SMS notification" bug). Fixed
/// at the source instead of by lengthening this delay for everyone:
/// `processIncomingSms` (sms_ledger_processor.dart) now claims
/// [quickAddScreenActive] itself immediately, before any of that I/O runs,
/// rather than waiting for `SmsReviewScreen` to mount and claim it late.
const _autoPromptDelay = Duration(milliseconds: 200);

/// Wraps the app's current screen (via [MaterialApp.builder], so this sees
/// *every* route, not just the first one) with a fingerprint/Face ID (or
/// device PIN/pattern, local_auth's own fallback) lock whenever
/// [biometricLockEnabledProvider] is on. The prompt fires automatically --
/// on first showing the lock screen and every time the app returns from the
/// background (subject to [biometricGraceMinutesProvider], see below) --
/// with no "Unlock" tap needed first; a manual retry button only appears if
/// that automatic attempt fails or is cancelled.
///
/// A successful check stays valid for [biometricGraceMinutesProvider]
/// minutes (0, the default, means "every time") -- resuming (or cold
/// -starting) within that window skips the prompt entirely rather than
/// re-asking. Checked against the persisted [SettingsRepository
/// .lastBiometricUnlockAt], not just in-memory state, since Android can
/// (and does) kill a backgrounded app well within a window someone might
/// reasonably set here.
///
/// The "Add Payment" pinned shortcuts and the home-screen widget's
/// quick-add are exempt: while [quickAddScreenActive] is true (set by
/// `AddTransactionScreen` itself, only for the quick-add-invoked instance),
/// this neither shows the lock overlay nor fires the biometric prompt, so
/// quick-adding a payment never requires fingerprint/Face ID. Everything
/// else -- including screens reached by regular in-app navigation while
/// backgrounded and resumed -- stays behind the lock.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  final _localAuth = LocalAuthentication();
  bool _unlocked = false;
  bool _checking = false;
  String? _error;

  /// When a check last actually succeeded, in this same widget instance --
  /// distinct from the persisted [SettingsRepository.lastBiometricUnlockAt]
  /// (which exists to survive a process death) and used for a completely
  /// different purpose: some devices fire a spurious pause-then-resume (or
  /// resume-only) app-lifecycle transition on *this app's own Activity*
  /// while the OS biometric sheet itself is showing or being dismissed --
  /// an OEM quirk in how that sheet is hosted, nothing this app controls.
  /// Without this guard, that spurious resume immediately re-evaluates the
  /// grace period; at the default of 0 minutes that always reads as
  /// "expired", so it re-locks and re-prompts on the spot -- which
  /// succeeds, fires the same spurious resume again, and loops forever
  /// (confirmed: a real "stuck scanning my face over and over" report).
  /// [_resumeDebounce] is checked before any relock decision so a resume
  /// landing implausibly soon after a real success is treated as an
  /// artifact of that same success, not a new app-open event.
  ///
  /// Deliberately short -- long enough to cover the OEM artifact (which is
  /// part of the same UI transaction as the sheet's own dismissal, so
  /// effectively instant) but short enough that a genuinely fast deliberate
  /// app-switch-and-return doesn't get mistaken for it. An earlier, much
  /// longer window here (2 seconds) fixed the original lockout loop but
  /// overcorrected: any real resume landing inside that whole 2-second span
  /// -- not just the sheet's own immediate aftermath -- silently skipped
  /// the relock check entirely, regardless of the user's chosen grace
  /// period (the reported "app sometimes opens without biometrics" bug,
  /// since a quick glance at another app and back easily lands inside 2
  /// seconds but essentially never inside this shorter one).
  DateTime? _lastLocalUnlockAt;
  static const _resumeDebounce = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    quickAddScreenActive.addListener(_onQuickAddExemptionChanged);
    final settings = ref.read(settingsRepositoryProvider);
    // A cold start counts as "resuming" for grace-period purposes too --
    // Android killing the process while backgrounded is common well within
    // a window someone might reasonably set, and there'd be no way to tell
    // that apart from a deliberate relaunch otherwise.
    _setUnlocked(
      !settings.biometricLockEnabled || _withinGracePeriod(settings),
    );
    if (_unlocked) _lastLocalUnlockAt = DateTime.now();
    if (!_unlocked) _scheduleAutoPrompt();
  }

  /// Updates [_unlocked] and mirrors it into [appUnlocked] together, so the
  /// two can never drift -- every place this state changes goes through
  /// here instead of assigning [_unlocked] directly.
  void _setUnlocked(bool value) {
    _unlocked = value;
    appUnlocked.value = value;
  }

  /// Whether the last successful check is still within
  /// [SettingsRepository.biometricGraceMinutes] of right now. 0 minutes
  /// (the default) always answers false, matching this app's "every time"
  /// behavior before the grace period existed -- a >=0 comparison against
  /// zero elapsed time would otherwise flip that default's meaning.
  bool _withinGracePeriod(SettingsRepository settings) {
    final graceMinutes = settings.biometricGraceMinutes;
    if (graceMinutes <= 0) return false;
    final lastUnlock = settings.lastBiometricUnlockAt;
    if (lastUnlock == null) return false;
    return DateTime.now().difference(lastUnlock) <
        Duration(minutes: graceMinutes);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    quickAddScreenActive.removeListener(_onQuickAddExemptionChanged);
    super.dispose();
  }

  /// The lock overlay's own visibility already reacts to this (see [build]),
  /// but a rebuild alone doesn't affect a biometric prompt that's already
  /// showing -- there's nothing more to do here beyond that rebuild; this
  /// listener exists so the overlay's disappearance the moment quick-add
  /// takes over is immediate rather than waiting on some other rebuild.
  void _onQuickAddExemptionChanged() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The re-lock decision now happens here, on resume, not at pause time --
    // it has to: whether a grace period is still valid can only be known
    // once we know *when* the app is coming back, not when it left. (With
    // the grace period at its default of 0 minutes, this still re-locks on
    // every single resume, exactly as pausing used to do unconditionally --
    // zero elapsed time never satisfies "still within a positive window".)
    if (state != AppLifecycleState.resumed || !_unlocked) return;
    final lastLocalUnlock = _lastLocalUnlockAt;
    if (lastLocalUnlock != null &&
        DateTime.now().difference(lastLocalUnlock) < _resumeDebounce) {
      return;
    }
    final settings = ref.read(settingsRepositoryProvider);
    if (!settings.biometricLockEnabled || _withinGracePeriod(settings)) return;
    // Locks immediately, synchronously with the resume event -- not left
    // for whenever _authenticate's own state update happens to land --
    // so the opaque lock overlay is what's on screen the instant this
    // frame renders, with no gap a stale unlocked frame could show through.
    setState(() => _setUnlocked(false));
    _scheduleAutoPrompt();
  }

  void _scheduleAutoPrompt() {
    Future.delayed(_autoPromptDelay, () {
      if (!mounted || _unlocked || quickAddScreenActive.value) return;
      _authenticate();
    });
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
        _lastLocalUnlockAt = DateTime.now();
        setState(() {
          _setUnlocked(true);
          _checking = false;
        });
        return;
      }
      // Re-checked right before actually surfacing the OS prompt -- the
      // scheduling delay in [_scheduleAutoPrompt] covers the common case,
      // this covers the rest.
      if (quickAddScreenActive.value) {
        setState(() => _checking = false);
        return;
      }
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock Money Hub',
        persistAcrossBackgrounding: true,
      );
      if (ok) {
        _lastLocalUnlockAt = DateTime.now();
        // Persisted, not just kept in [_unlocked] -- see
        // [SettingsRepository.lastBiometricUnlockAt]'s own doc comment for
        // why a grace period needs this to survive a process death.
        await ref
            .read(settingsRepositoryProvider)
            .setLastBiometricUnlockAt(DateTime.now());
      }
      if (!mounted) return;
      setState(() {
        _setUnlocked(ok);
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
    final locked = enabled && !_unlocked && !quickAddScreenActive.value;

    return Stack(
      children: [
        widget.child,
        if (locked)
          Positioned.fill(
            child: _LockScreen(
              checking: _checking,
              error: _error,
              onUnlock: _authenticate,
            ),
          ),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({
    required this.checking,
    required this.error,
    required this.onUnlock,
  });

  final bool checking;
  final String? error;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // An opaque Container (not just a Material) is the outer layer on
    // purpose -- Container's render object reports itself hit-testable
    // ("opaque" HitTestBehavior), which is what actually stops a tap on the
    // dead background area from falling through to whatever's underneath in
    // the Stack. A bare Material with no GestureDetector of its own
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
                    decoration: BoxDecoration(
                      color: context.appColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.fingerprint,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Money Hub is locked',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    checking
                        ? 'Checking your fingerprint or face…'
                        : 'Waiting for fingerprint or Face ID…',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appColors.textDim),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.appColors.bad),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Only ever needed as a fallback -- the prompt above fires
                  // on its own; this is for when that attempt failed, was
                  // dismissed, or the user wants to retry without waiting
                  // for another background/resume cycle.
                  FilledButton.icon(
                    onPressed: checking ? null : onUnlock,
                    icon: checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open),
                    label: const Text('Try again'),
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
