import 'package:flutter/services.dart';

/// One SMS handed over from the native side, still unparsed.
class PendingSms {
  const PendingSms({required this.body, required this.timestampMillis});

  final String body;
  final int timestampMillis;
}

const _channel = MethodChannel('money_hub/sms');

/// Memoizes [takePendingSms]'s single underlying platform-channel call --
/// see that function's own doc comment for why this needs to be callable
/// more than once (`main()`, before `runApp`, and then again from
/// `app.dart`'s cold-start check) without actually re-invoking the native
/// side, which really does clear its stashed Intent extra on the *first*
/// call and would silently return null to whichever caller runs second.
Future<PendingSms?>? _pendingSmsFuture;

/// Legacy: covered a cold start from tapping the *native* "bank text
/// detected" notification MainActivity.kt used to build, which stashed the
/// raw SMS as launch-Intent extras. SmsReceiver.kt no longer posts any
/// notification itself (see its own doc comment -- the whole native
/// keyword pre-filter that decided whether to is gone, replaced by
/// `commitSmsAutoDetect` actually running the user's SMS Rules in a
/// background isolate); the one notification this app now shows for a
/// charge that needs review (`showSmsChargeReviewNotification`) is posted
/// from Dart via flutter_local_notifications, and its tap is handled
/// through that plugin's own payload/response mechanism (see app.dart's
/// `_onNotificationResponse`, plus [listenForNewSms]'s own
/// `onNotificationBodyTapped`/`onNativeNewIntent` params below for the
/// independent native fallback that same tap also goes through), not this
/// legacy path. Left in place, rather than removed, since nothing calling
/// this now-always-null path causes any harm -- `main()` still calls it
/// as part of [coldStartLaunchPending]'s computation, for one.
///
/// Reads (and clears) the SMS carried by the Intent that launched or last
/// re-launched this Activity, if any.
///
/// Safe to call more than once -- every call after the first returns the
/// same already-resolved result instead of re-invoking the native side
/// (see [_pendingSmsFuture]).
Future<PendingSms?> takePendingSms() {
  return _pendingSmsFuture ??= _channel
      .invokeMapMethod<String, dynamic>('takePendingSms')
      .then((result) {
        if (result == null) return null;
        return PendingSms(
          body: result['body'] as String,
          timestampMillis: (result['timestampMillis'] as num).toInt(),
        );
      });
}

/// Registers [onSms] for the warm-app case — the notification tapped while
/// this Activity is already running arrives via `onNewIntent` instead of a
/// fresh launch, so MainActivity pushes it straight to Dart rather than
/// waiting for another `takePendingSms` call that would never happen.
///
/// [onNotificationBodyTapped] and [onNativeNewIntent] are a second,
/// independent purpose this same channel now also serves -- see
/// MainActivity.kt's own `onNewIntent` override for why. Only one handler
/// can ever be registered on a [MethodChannel] at a time, which is why
/// these live in the same function rather than each getting their own
/// `listenFor...` -- a second call here would silently replace, not add
/// to, whatever the first one registered.
void listenForNewSms(
  void Function(PendingSms sms) onSms, {
  void Function(String payload)? onNotificationBodyTapped,
  void Function(String? action)? onNativeNewIntent,
}) {
  _channel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'onNewSms':
        final args = (call.arguments as Map).cast<String, dynamic>();
        onSms(
          PendingSms(
            body: args['body'] as String,
            timestampMillis: (args['timestampMillis'] as num).toInt(),
          ),
        );
      case 'onNotificationBodyTapped':
        onNotificationBodyTapped?.call(call.arguments as String);
      case 'nativeOnNewIntent':
        onNativeNewIntent?.call(call.arguments as String?);
    }
  });
}
