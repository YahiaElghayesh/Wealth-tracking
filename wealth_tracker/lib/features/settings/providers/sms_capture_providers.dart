import 'package:another_telephony/telephony.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/sms/sms_ledger_processor.dart';
import '../../networth/providers/asset_providers.dart' show databaseProvider;

final _telephony = Telephony.instance;

/// Whether the SMS permission is currently granted, as far as this session
/// knows — set after a successful [requestSmsPermission] call. There's no
/// permission-status check in `another_telephony` that doesn't also
/// (harmlessly, if already granted) request it, so this starts `false` and
/// is only trusted once actually checked.
final smsPermissionGrantedProvider = StateProvider<bool>((ref) => false);

/// Requests the SMS permission (Android's runtime dialog only appears if
/// it isn't already granted — calling this when already granted resolves
/// immediately with no dialog). Returns whether it ended up granted.
Future<bool> requestSmsPermission() async {
  final granted = await _telephony.requestSmsPermissions;
  return granted ?? false;
}

bool _listening = false;

/// Starts listening for incoming SMS, foreground and background alike.
/// Call only once permission is confirmed granted, and only on Android.
/// Safe to call more than once per app run — only registers the listener
/// the first time.
void startSmsListener(WidgetRef ref) {
  if (_listening) return;
  _listening = true;

  _telephony.listenIncomingSms(
    onNewMessage: (message) async {
      final db = ref.read(databaseProvider);
      await processIncomingSms(db, body: message.body, timestampMillis: message.date);
    },
    onBackgroundMessage: smsBackgroundMessageHandler,
    listenInBackground: true,
  );
}

/// Headless entry point Android invokes for a message that arrives while
/// the app isn't running — there's no ProviderScope here, same as
/// `background_refresh.dart`'s callback dispatcher, so it opens its own DB
/// connection instead of reading one from Riverpod.
@pragma('vm:entry-point')
void smsBackgroundMessageHandler(SmsMessage message) async {
  final db = AppDatabase();
  try {
    await processIncomingSms(db, body: message.body, timestampMillis: message.date);
  } finally {
    await db.close();
  }
}
