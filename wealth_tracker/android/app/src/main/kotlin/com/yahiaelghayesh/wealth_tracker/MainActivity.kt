package com.yahiaelghayesh.wealth_tracker

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth's Android implementation shows a BiometricPrompt, which needs
// a FragmentActivity host -- plain FlutterActivity doesn't extend one, so
// this had to switch from FlutterActivity or the fingerprint/Face ID lock
// would crash (or just never show) as soon as it tried to authenticate.
class MainActivity : FlutterFragmentActivity() {
    private var smsChannel: MethodChannel? = null
    private var shortcutsChannel: MethodChannel? = null

    // home_widget's click detection reads the launch Intent both from the
    // "was I cold-started by a widget tap" check (activity.intent, i.e.
    // getIntent()) and from onNewIntent for a warm tap while the app is
    // already running. Activity.onNewIntent does NOT update getIntent() on
    // its own — without this override, a warm tap on the "Add Payment"
    // widget just brings the app to the foreground on whatever screen was
    // already showing instead of opening the add-payment form. SmsReceiver's
    // notification tap relies on the same override — see extractPendingSms.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractPendingSms(intent)?.let { smsChannel?.invokeMethod("onNewSms", it) }
    }

    // Dart's counterpart lives in lib/data/sms/native_sms_channel.dart —
    // see SmsReceiver.kt for why this exists instead of a Flutter SMS
    // plugin. `takePendingSms` covers a cold start (Dart asks once, after
    // its first frame); `onNewSms` (above) covers the warm-app case.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        smsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "money_hub/sms")
        smsChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "takePendingSms" -> result.success(extractPendingSms(intent))
                else -> result.notImplemented()
            }
        }

        // Dart's counterpart lives in lib/features/ledger/providers/ledger_shortcut_channel.dart --
        // see LedgerShortcuts.kt for why this exists instead of the old
        // static <shortcuts.xml> entry.
        shortcutsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "money_hub/shortcuts")
        shortcutsChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "pinLedgerShortcut" -> {
                    val counterpartyId = call.argument<String>("counterpartyId")
                    val name = call.argument<String>("name")
                    if (counterpartyId == null || name == null) {
                        result.error("invalid_args", "counterpartyId and name are required", null)
                    } else {
                        result.success(LedgerShortcuts.pin(this, counterpartyId, name))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Reads the SMS extras off [intent] and clears them so re-reading the
     * same Intent later (e.g. a second `takePendingSms` call) doesn't
     * reprocess the same message. */
    private fun extractPendingSms(intent: Intent): Map<String, Any>? {
        val body = intent.getStringExtra(EXTRA_SMS_BODY) ?: return null
        val timestampMillis = intent.getLongExtra(EXTRA_SMS_TIMESTAMP, 0L)
        intent.removeExtra(EXTRA_SMS_BODY)
        intent.removeExtra(EXTRA_SMS_TIMESTAMP)
        return mapOf("body" to body, "timestampMillis" to timestampMillis)
    }

    companion object {
        const val EXTRA_SMS_BODY = "money_hub_sms_body"
        const val EXTRA_SMS_TIMESTAMP = "money_hub_sms_timestamp"
    }
}
