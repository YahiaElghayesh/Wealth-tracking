import 'package:flutter/foundation.dart';

/// True while the "Add Payment" quick-add screen (opened via a pinned
/// per-ledger shortcut or the home-screen widget -- see
/// `quick_add_launch.dart` and `AddTransactionScreen`'s `closeAppOnSave`
/// flag) is on screen. [AppLockGate] watches this to suppress the
/// biometric lock overlay for exactly that screen and nothing else --
/// regular in-app navigation to Add Payment (e.g. from a ledger row's own
/// "+" button) never sets this, so it stays behind the lock like
/// everything else.
///
/// Tied to the screen's actual widget lifecycle rather than to the launch
/// Intent/URI that triggered it: the Intent can go stale (Android doesn't
/// clear it after use, only replaces it on the *next* new Intent), so
/// checking "was this launched via quick-add" at lock-time instead of "is
/// that screen on screen right now" would keep exempting the lock long
/// after the one quick-add visit that earned it ended.
final quickAddScreenActive = ValueNotifier<bool>(false);
