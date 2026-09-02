import 'package:flutter/foundation.dart';

/// How many independent things currently want the biometric lock
/// (`AppLockGate`) suppressed -- a *count*, not a bare flag, specifically
/// so two overlapping claims can never step on each other: the launch
/// -time claim taken in `main()`/`app.dart` the instant a quick-add or
/// SMS-triggered launch is detected, and the destination screen's own
/// claim once it actually mounts, legitimately overlap for a moment during
/// every such launch (see [QuickActionExemption]'s own doc comment) -- with
/// a plain bool, whichever of the two released first would incorrectly
/// clear the other's still-active claim.
///
/// [AppLockGate] treats the lock as suppressed exactly while this is above
/// zero. Nothing outside this file should touch [_count] directly --
/// always go through [QuickActionExemption.claim]/[release].
final _count = ValueNotifier<int>(0);

/// A screen exempt from the biometric lock -- the "Add Payment" quick-add
/// form (opened via a pinned per-ledger shortcut or the home-screen
/// widget; see `quick_add_launch.dart` and `AddTransactionScreen`'s
/// `closeAppOnSave` flag) or the SMS-triggered "Confirm payment" review
/// screen (`SmsReviewScreen`) -- claims this for as long as it's on
/// screen, tied to its own widget lifecycle (`initState`/`dispose`) rather
/// than to the launch Intent/URI that triggered it: the Intent can go
/// stale (Android doesn't clear it after use, only replaces it on the
/// *next* new Intent), so checking "was this launched via quick-add" at
/// lock-time instead of "is that screen on screen right now" would keep
/// exempting the lock long after the one quick-add visit that earned it
/// ended.
///
/// That screen-lifetime claim alone still leaves a gap: the async chain
/// between "the launch/SMS was detected" and "the destination screen has
/// actually mounted and claimed its own exemption" (awaiting the
/// Navigator, a database round-trip for the ledger/vendor-rule lookup, ...)
/// can, on a slow or cold-starting device, take longer than
/// [AppLockGate] would otherwise wait before firing the OS biometric
/// prompt. Every launch path (`main.dart`'s upfront checks for a cold
/// start, `handleQuickAddLaunch`/`processIncomingSms` for a warm one)
/// closes that gap by claiming *immediately*, as the very first thing it
/// does once it knows this launch is one of these two kinds -- before any
/// of that slower work runs -- and releasing again once the destination
/// screen has had a real chance to claim its own (see each call site's
/// own comment for exactly when). The two claims overlapping for a moment
/// is exactly what [_count] being a counter (not a bool) is for.
class QuickActionExemption {
  QuickActionExemption._();

  /// True while at least one claim is active -- [AppLockGate] suppresses
  /// both the lock overlay and any pending auto-prompt while this is true.
  static bool get isActive => _count.value > 0;

  /// Fires whenever [isActive] might have changed -- add a listener to
  /// react immediately (e.g. to bail out of a wait the moment an
  /// exemption appears) rather than polling.
  static Listenable get listenable => _count;

  static void claim() => _count.value++;

  /// A no-op if nothing is currently claimed -- every release call site
  /// pairs with a specific claim, but guards defensively anyway so a
  /// logic error elsewhere degrades to "the lock fires when it shouldn't
  /// have" rather than an underflow into a negative, permanently-broken
  /// count.
  static void release() {
    if (_count.value > 0) _count.value--;
  }
}

/// Mirrors [AppLockGate]'s own "is the lock overlay currently showing"
/// state -- written there, read by screens that need to tell a genuinely
/// cold/locked launch apart from being opened while the app is already
/// unlocked and in normal use (see `SmsReviewScreen`, which needs that
/// distinction: exempt-and-force-close is right when it's the very reason
/// a locked app just opened, but wrong when an SMS notification is tapped
/// while the user is mid-task elsewhere in an already-unlocked app --
/// there, a plain pop back to whatever they were doing is correct, and
/// forcing the whole app shut would be a jarring surprise). Starts `false`
/// (the same conservative default `AppLockGate` itself starts from) so a
/// screen that reads this before `AppLockGate` has even mounted still gets
/// the "treat as locked" answer, never the reverse.
final appUnlocked = ValueNotifier<bool>(false);
