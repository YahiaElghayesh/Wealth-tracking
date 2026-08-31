import 'package:flutter/foundation.dart';

/// True while a screen exempt from the biometric lock -- the "Add Payment"
/// quick-add form (opened via a pinned per-ledger shortcut or the
/// home-screen widget; see `quick_add_launch.dart` and
/// `AddTransactionScreen`'s `closeAppOnSave` flag) or the SMS-triggered
/// "Confirm payment" review screen (`SmsReviewScreen`) -- is on screen.
/// [AppLockGate] watches this to suppress the biometric lock overlay for
/// exactly that screen and nothing else -- regular in-app navigation (e.g.
/// Add Payment from a ledger row's own "+" button, or opening the SMS
/// review screen while already using the app) never sets this, so it stays
/// behind the lock like everything else.
///
/// Tied to the screen's actual widget lifecycle rather than to the launch
/// Intent/URI that triggered it: the Intent can go stale (Android doesn't
/// clear it after use, only replaces it on the *next* new Intent), so
/// checking "was this launched via quick-add" at lock-time instead of "is
/// that screen on screen right now" would keep exempting the lock long
/// after the one quick-add visit that earned it ended.
final quickAddScreenActive = ValueNotifier<bool>(false);

/// Mirrors [AppLockGate]'s own unlocked state -- written there, read by
/// screens that need to tell a genuinely cold/locked launch apart from
/// being opened while the app is already unlocked and in normal use (see
/// `SmsReviewScreen`, which needs that distinction: exempt-and-force-close
/// is right when it's the very reason a locked app just opened, but wrong
/// when an SMS notification is tapped while the user is mid-task elsewhere
/// in an already-unlocked app -- there, a plain pop back to whatever they
/// were doing is correct, and forcing the whole app shut would be a jarring
/// surprise). Starts `false` (the same conservative default [AppLockGate]
/// itself starts from) so a screen that reads this before [AppLockGate] has
/// even mounted still gets the "treat as locked" answer, never the reverse.
final appUnlocked = ValueNotifier<bool>(false);
