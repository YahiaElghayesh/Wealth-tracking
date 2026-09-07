package com.yahiaelghayesh.wealth_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
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
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) return

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
        WorkManager.getInstance(context).enqueue(request)
    }

    companion object {
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
