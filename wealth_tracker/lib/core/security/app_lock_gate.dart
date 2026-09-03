import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../data/repositories/settings_repository.dart';
import '../../features/settings/providers/settings_providers.dart';
import '../providers/core_providers.dart';
import '../theme/app_colors.dart';
import 'app_lock_exemption.dart';

/// Longest [AppLockGate] will hold off its automatic biometric prompt
/// waiting for a concurrently-arriving quick-add/SMS launch to claim
/// [QuickActionExemption] -- a safety net, not the primary mechanism:
/// [_waitForExemptionOrTimeout] returns the instant that claim actually
/// happens (see that method), so this only matters in the rare case
/// nothing ever claims it, where it bounds how long a genuinely locked
/// open stays on the "waiting" state before the prompt fires.
const _maxExemptionWait = Duration(milliseconds: 900);

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
/// The "Add Payment" pinned shortcuts, the home-screen widget's quick-add,
/// and a tapped bank-SMS notification are all exempt: while
/// [QuickActionExemption.isActive] is true, this neither shows the lock
/// overlay nor fires the biometric prompt, so none of those three ever
/// require fingerprint/Face ID. Everything else -- including screens
/// reached by regular in-app navigation while backgrounded and resumed --
/// stays behind the lock. See app_lock_exemption.dart for exactly how (and
/// how early) that gets claimed for each of the three.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  final _localAuth = LocalAuthentication();

  /// The lock overlay's own on/off state -- the *only* flag that decides
  /// whether it's painted (see [build]); [QuickActionExemption.isActive]
  /// is folded into that same [build] check rather than kept in sync with
  /// this field, so there's exactly one place either can go stale instead
  /// of two.
  bool _locked = false;
  bool _checking = false;
  String? _error;

  /// When a check last actually succeeded, in this same widget instance --
  /// distinct from the persisted [SettingsRepository.lastBiometricUnlockAt]
  /// (which exists to survive a process death) and used for a completely
  /// different purpose: some devices fire a spurious pause-then-resume (or
  /// resume-only) app-lifecycle transition on *this app's own Activity*
  /// while the OS biometric sheet itself is showing or being dismissed --
  /// an OEM quirk in how that sheet is hosted, nothing this app controls.
  /// Without this guard, that spurious resume would immediately re-run the
  /// relock check; at the default grace period of 0 minutes that always
  /// reads as "expired", so it would re-lock and re-prompt on the spot --
  /// which succeeds, fires the same spurious resume again, and loops
  /// forever (confirmed: a real "stuck scanning my face over and over"
  /// report). [_resumeDebounce] is checked before any relock decision so a
  /// resume landing implausibly soon after a real success is treated as an
  /// artifact of that same success, not a new app-open event.
  DateTime? _lastSuccessAt;
  static const _resumeDebounce = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    QuickActionExemption.listenable.addListener(_onExemptionChanged);
    // Waits only when main() flagged a quick-add/SMS launch as pending --
    // see coldStartLaunchPending's own doc comment and _evaluateLock's
    // `wait` parameter for why an ordinary cold start (the common case)
    // still skips the wait entirely.
    _evaluateLock(wait: coldStartLaunchPending);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    QuickActionExemption.listenable.removeListener(_onExemptionChanged);
    super.dispose();
  }

  /// While a claim is active, the lock overlay's own visibility already
  /// reacts to [QuickActionExemption.isActive] (see [build]) -- a plain
  /// rebuild is all that's needed there, so the overlay's disappearance
  /// the moment a quick action takes over is immediate rather than waiting
  /// on some other rebuild.
  ///
  /// Once the claim ends, a plain rebuild isn't always enough: [_locked]
  /// may have been set `true` by an [_evaluateLock] that ran *before* (or
  /// concurrently with) this exemption existed -- a lifecycle resume
  /// racing a quick-add/SMS launch on cold start, most commonly -- and
  /// nothing since then has corrected it, even if the grace period would
  /// actually have said "don't lock" had [_evaluateLock] been given the
  /// chance to run without an exemption in the way. Re-running it here
  /// instead of just repainting is what stopped a stray lock screen (with
  /// its fingerprint prompt) from appearing the instant someone backed out
  /// of or saved a quick-add screen, even within an otherwise-satisfied
  /// grace period.
  ///
  /// Only when [_locked] is actually `true`, though: a quick-add tap or an
  /// SMS arriving while the app is genuinely already open and unlocked
  /// (there was no resume, nothing raced) claims and releases this same
  /// exemption too -- claiming unconditionally is what makes those two
  /// call sites race-free in the first place, see
  /// [QuickActionExemption]'s own doc comment -- and re-running
  /// [_evaluateLock] on every one of *those* releases would re-derive
  /// "should be locked" from scratch and could re-lock an app the user is
  /// actively, unremarkably still using, just because an unrelated SMS
  /// happened to arrive in the background. [_locked] being `true` here
  /// means there's an actual stray lock to correct; `false` means there
  /// never was one, so there's nothing to do.
  void _onExemptionChanged() {
    if (QuickActionExemption.isActive) {
      setState(() {});
    } else if (_locked) {
      _evaluateLock();
    }
  }

  /// Single entry point for "decide whether the app should be locked right
  /// now" -- called from [initState] (cold start counts as a resume for
  /// grace-period purposes too, since Android killing the process while
  /// backgrounded is common well within a window someone might reasonably
  /// set), from every genuine resume in [didChangeAppLifecycleState], and
  /// from [_onExemptionChanged] once a claim ends. Replaces what used to
  /// be two separately-maintained code paths (one in each caller) that
  /// could -- and did -- drift out of sync with each other.
  ///
  /// [wait] controls whether [_promptWhenReady] waits out
  /// [_waitForExemptionOrTimeout] before prompting. True everywhere except
  /// an ordinary cold start's call from [initState] (see
  /// [coldStartLaunchPending]). That wait exists for exactly one race: a
  /// resume's lifecycle callback -- or, on cold start, this very first
  /// evaluation -- firing *before* a concurrently-arriving quick-add/SMS
  /// launch (delivered over its own, independent stream/channel) has
  /// claimed its exemption yet. Skipping the wait on an ordinary cold
  /// start (the overwhelming majority of opens, which never claim
  /// anything) avoids a flat, pointless delay before the fingerprint
  /// prompt could even appear -- the reported "app takes longer to open"
  /// regression -- while still waiting whenever [coldStartLaunchPending]
  /// says a real claim is actually on its way.
  void _evaluateLock({bool wait = true}) {
    final settings = ref.read(settingsRepositoryProvider);
    if (!settings.biometricLockEnabled || _withinGracePeriod(settings)) {
      setState(() => _locked = false);
      return;
    }
    setState(() => _locked = true);
    _promptWhenReady(wait: wait);
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final lastSuccess = _lastSuccessAt;
    if (lastSuccess != null &&
        DateTime.now().difference(lastSuccess) < _resumeDebounce) {
      return;
    }
    _evaluateLock();
  }

  /// Waits, event-driven rather than on a blind timer, for
  /// [QuickActionExemption] to become active before firing the automatic
  /// biometric prompt -- resolves the *instant* a claim lands (a
  /// concurrently-arriving quick-add/SMS launch, see
  /// app_lock_exemption.dart), rather than always waiting the same fixed
  /// delay regardless of how quickly that claim actually shows up.
  /// [_maxExemptionWait] only bounds the case nothing ever claims it.
  Future<void> _waitForExemptionOrTimeout() async {
    if (QuickActionExemption.isActive) return;
    final completer = Completer<void>();
    void onChanged() {
      if (QuickActionExemption.isActive && !completer.isCompleted) {
        completer.complete();
      }
    }

    QuickActionExemption.listenable.addListener(onChanged);
    try {
      await completer.future.timeout(_maxExemptionWait, onTimeout: () {});
    } finally {
      QuickActionExemption.listenable.removeListener(onChanged);
    }
  }

  Future<void> _promptWhenReady({bool wait = true}) async {
    if (wait) await _waitForExemptionOrTimeout();
    if (!mounted || !_locked || QuickActionExemption.isActive) return;
    _authenticate();
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
        _lastSuccessAt = DateTime.now();
        setState(() {
          _locked = false;
          _checking = false;
        });
        return;
      }
      // Re-checked right before actually surfacing the OS prompt -- covers
      // a claim that lands in the narrow window after
      // [_waitForExemptionOrTimeout] already gave up.
      if (QuickActionExemption.isActive) {
        setState(() => _checking = false);
        return;
      }
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock Money Hub',
        persistAcrossBackgrounding: true,
      );
      if (ok) {
        _lastSuccessAt = DateTime.now();
        // Persisted, not just kept in [_locked] -- see
        // [SettingsRepository.lastBiometricUnlockAt]'s own doc comment for
        // why a grace period needs this to survive a process death.
        await ref
            .read(settingsRepositoryProvider)
            .setLastBiometricUnlockAt(DateTime.now());
      }
      if (!mounted) return;
      setState(() {
        _locked = !ok;
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
    final locked = enabled && _locked && !QuickActionExemption.isActive;
    // Kept in lockstep with what's actually painted below, every build --
    // see app_lock_exemption.dart's own doc comment for why screens need
    // this distinct from [QuickActionExemption.isActive] itself.
    appUnlocked.value = !locked;

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
