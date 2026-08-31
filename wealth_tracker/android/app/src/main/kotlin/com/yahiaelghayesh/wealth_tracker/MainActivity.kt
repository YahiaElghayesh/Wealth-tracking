package com.yahiaelghayesh.wealth_tracker

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
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
    private var updaterChannel: MethodChannel? = null
    private var securityChannel: MethodChannel? = null

    // FLAG_SECURE blocks three things Android otherwise does with this
    // window's actual rendered pixels, none of which the Dart-level
    // biometric lock overlay (AppLockGate) can reach since they all happen
    // outside Flutter's own paint pipeline: screenshots, the recent-apps
    // task switcher's thumbnail (real balances were showing there
    // uncovered -- confirmed from a live screenshot), and screen
    // recording. It also removes the specific bug those two things share a
    // root cause with: Android's app-switch resume animation is built from
    // a cached snapshot of the window's last real frame, so without this
    // flag that stale, unlocked frame could still flash on screen for a
    // moment before Flutter's own re-lock repaint catches up -- with it,
    // Android can't cache that frame at all and substitutes a blank one
    // instead. On by default (not tied to whether the biometric lock
    // setting is on) -- this is a financial app; screenshot/recording
    // exposure of real balances is a risk regardless of whether app-open
    // authentication happens to be enabled right now. The user can opt out
    // from Settings -- see [screenshotsAllowed] for how that choice is read
    // this early, and the `money_hub/security` channel below for how it's
    // applied live if flipped while the app is already running.
    override fun onCreate(savedInstanceState: Bundle?) {
        applySecureFlag(!screenshotsAllowed())
        super.onCreate(savedInstanceState)
    }

    private fun applySecureFlag(secure: Boolean) {
        if (secure) {
            window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    /** Reads the same key `SettingsRepository.allowScreenshots` (Dart side)
     * writes to. `shared_preferences`' Android implementation always
     * prefixes stored keys with `flutter.` and stores them in a
     * `FlutterSharedPreferences` file, both fixed implementation details of
     * that plugin, not anything configured here -- read directly, rather
     * than over a MethodChannel, because this runs before the Flutter
     * engine (and thus any channel) exists yet. Defaults to false (screenshots
     * blocked) to match `SettingsRepository.allowScreenshots`'s own default. */
    private fun screenshotsAllowed(): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        return prefs.getBoolean("flutter.allow_screenshots", false)
    }

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

        // Dart's counterpart lives in lib/core/update/app_update_service.dart
        // and lib/core/update/app_update_screen.dart -- see AppUpdater.kt for
        // why this needs native code instead of a Flutter plugin (the
        // FileProvider content:// URI dance a downloaded APK needs before
        // the system installer will touch it).
        updaterChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "money_hub/updater")
        updaterChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "canInstallPackages" -> result.success(AppUpdater.canInstall(this))
                "requestInstallPermission" -> {
                    AppUpdater.requestInstallPermission(this)
                    result.success(null)
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("invalid_args", "path is required", null)
                    } else {
                        AppUpdater.install(this, path)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Dart's counterpart lives in lib/core/security/screenshot_channel.dart
        // -- covers only the *live* toggle case; the persisted default is
        // already applied in onCreate, above, before this channel exists.
        securityChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "money_hub/security")
        securityChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setScreenshotsAllowed" -> {
                    val allowed = call.argument<Boolean>("allowed") ?: false
                    applySecureFlag(!allowed)
                    result.success(null)
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
