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

/// Reads (and clears) the SMS carried by the Intent that launched or last
/// re-launched this Activity, if any — covers a cold start from tapping the
/// native "bank text detected" notification. See MainActivity.kt: the
/// notification's PendingIntent stashes the raw SMS as launch-Intent
/// extras rather than going through a Flutter plugin, since a previous SMS
/// plugin's own Android build config broke `flutter build apk` outright;
/// nothing SMS-related in this app depends on a third-party plugin anymore.
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
void listenForNewSms(void Function(PendingSms sms) onSms) {
  _channel.setMethodCallHandler((call) async {
    if (call.method != 'onNewSms') return;
    final args = (call.arguments as Map).cast<String, dynamic>();
    onSms(
      PendingSms(
        body: args['body'] as String,
        timestampMillis: (args['timestampMillis'] as num).toInt(),
      ),
    );
  });
}
