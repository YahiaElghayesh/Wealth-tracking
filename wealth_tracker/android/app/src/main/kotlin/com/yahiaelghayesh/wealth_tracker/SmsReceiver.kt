package com.yahiaelghayesh.wealth_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.provider.Telephony
import android.util.Log
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker
import dev.fluttercommunity.workmanager.buildTaskInputData

/**
 * Native, plugin-free SMS capture. A Flutter SMS-reading plugin
 * (another_telephony) previously broke `flutter build apk` outright — its
 * own Android module declared a Java/Kotlin bytecode target that
 * conflicted with this app's, five build failures in a row before it was
 * ripped out. Rather than retry a different SMS plugin and risk the same
 * class of failure, this app now captures SMS itself with a plain
 * manifest-registered BroadcastReceiver: zero third-party Android build
 * config involved.
 *
 * Deliberately does *no* filtering of its own -- every incoming SMS is
 * handed unconditionally to [commitSmsAutoDetect] (lib/data/sms
 * /sms_ledger_processor.dart) in a headless Flutter engine, which decides
 * everything from there using the user's own SMS Rules. This receiver
 * used to run a keyword pre-filter here (`looksLikeBankCardSms`, an OTP
 * check, a couple of banks' payment/refund trigger phrases, a "known
 * vendor pattern" shortcut) before deciding whether to post a
 * notification -- removed entirely, per the explicit choice to depend
 * solely on SMS Rules rather than a native heuristic guessing what
 * "looks like" a bank text. The real, visible consequence: an SMS from a
 * bank you haven't built a Rule for yet (or an OTP) is now silently
 * ignored instead of prompting a notification -- there's no more
 * generic fallback prompt for "something we don't recognize".
 */
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "onReceive: action=${intent.action}")
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        // A plain enqueue() only writes the work request to WorkManager's own
        // database -- it does not itself keep the CPU awake, and this method
        // returns almost immediately afterward. Between that return and
        // WorkManager actually dispatching the job, there's a window where a
        // sufficiently aggressive power manager (this exists in degrees on
        // several OEM builds, on top of stock Android's own Doze) can let the
        // device fall back asleep before the job gets real CPU time --
        // "expedited" only raises how the job is scheduled once it runs, it
        // doesn't force the device to stay awake long enough to *reach* that
        // point. A short, self-expiring wake lock closes exactly that gap:
        // held across the whole handoff, not released early, since there's no
        // callback back from the headless Dart isolate to say when the real
        // work (commitSmsAutoDetect) actually finished. The timeout is the
        // only release mechanism by design -- bounded, so a crash or an
        // unexpectedly slow run can't hold it forever.
        val wakeLock = (context.getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "$TAG:smsProcessing")
        wakeLock.acquire(WAKE_LOCK_TIMEOUT_MILLIS)
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) {
            Log.d(TAG, "onReceive: getMessagesFromIntent returned null/empty")
            return
        }

        // A single logical SMS can arrive as multiple concatenated parts;
        // Android delivers them together in one broadcast.
        val rawBody = messages.joinToString(separator = "") { it.messageBody ?: "" }
        val timestampMillis = messages.first().timestampMillis
        if (rawBody.isBlank()) return
        // See normalizeSmsBody's own doc comment -- strips invisible bidi
        // marks banks embed around numbers in Arabic text before the Dart
        // rule matcher ever sees this text (its own normalizeSmsBody in
        // sms_rule_engine.dart does the same, so this is only a courtesy
        // for whatever might read the raw WorkManager input data directly).
        val body = normalizeSmsBody(rawBody)

        val inputData = buildTaskInputData(
            dartTask = SMS_AUTO_DETECT_TASK_NAME,
            payload = mapOf(
                "body" to body,
                "timestampMillis" to timestampMillis,
            ),
        )
        // Expedited (with a graceful non-expedited fallback once the app's
        // daily expedited-job quota is used up) rather than a plain one-off
        // request -- Doze/App-Standby can otherwise defer an unconstrained
        // WorkManager task substantially on a device that's been idle a
        // while (the reported "SMS silently doesn't do anything if the app
        // hasn't been opened in a long time" bug: the receiver ran and this
        // was enqueued fine, but the actual balance/ledger write it carries
        // could sit deferred for a long time before Android ever ran it).
        // Expedited work gets a much stronger execution guarantee from the
        // OS specifically to avoid that.
        val request = OneTimeWorkRequestBuilder<BackgroundWorker>()
            .setInputData(inputData)
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .build()
        Log.d(TAG, "onReceive: enqueuing WorkManager task, id=${request.id}")
        WorkManager.getInstance(context).enqueue(request)
    }

    companion object {
        private const val TAG = "SmsReceiver"

        // Long enough for WorkManager to actually dispatch and run the
        // enqueued task under normal Doze/App-Standby conditions, even on a
        // device that's been idle a while; short enough that holding it
        // every single incoming SMS is not a meaningful battery cost.
        private const val WAKE_LOCK_TIMEOUT_MILLIS = 60_000L

        // Must match smsAutoDetectTaskName in
        // lib/data/sms/sms_ledger_processor.dart, which
        // priceRefreshCallbackDispatcher switches on.
        private const val SMS_AUTO_DETECT_TASK_NAME = "smsAutoDetect"

        /**
         * Strips invisible Unicode bidi/formatting characters banks commonly
         * embed in Arabic SMS text to control how a Western-digit number (an
         * amount, a card's last-4-digits) displays inside right-to-left prose
         * -- RLM/LRM marks, explicit embedding/override/isolate direction
         * controls, and zero-width joiners. Mirrors normalizeSmsBody in
         * lib/data/sms/sms_rule_engine.dart.
         */
        private val bidiMarkPattern = Regex("[\u200B-\u200F\u202A-\u202E\u2066-\u2069\u061C]")

        fun normalizeSmsBody(body: String): String {
            return bidiMarkPattern.replace(body, "").replace('\u00A0', ' ')
        }
    }
}
