package com.yahiaelghayesh.wealth_tracker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import androidx.core.app.NotificationCompat
import androidx.work.OneTimeWorkRequestBuilder
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
 * The notification's tap target carries the raw SMS text as extras on
 * MainActivity's launch Intent; MainActivity hands those to Dart once the
 * app is actually open (see its `money_hub/sms` MethodChannel), where all
 * the parsing/matching/DB-writing logic already lives and is tested. It
 * also carries a second, genuinely headless path: a "Quick add" action
 * button that hands the same raw text to [SmsQuickAddActionReceiver]
 * instead, which commits it in the background with no app UI involved at
 * all when a Vendor Rule already resolves the sender to a specific ledger.
 *
 * Before either of those, [looksLikeBankCardSms] gates whether this is
 * even worth treating as a bank alert at all -- every SMS reaching this
 * receiver used to post a notification unconditionally, including a
 * promotional text that happened to mention a cash amount or a percentage.
 * A real card alert always states three things together: how much, in
 * what currency, and which card (its last four digits) -- a promo rarely
 * states all three, so requiring every one of them before doing anything
 * further meaningfully cuts false positives without needing a full parse.
 *
 * A card *payment/settlement or refund* alert (paying down the card,
 * opposite of a purchase) never reaches either of those -- the user only
 * wants to be interrupted for purchases. [isCardPaymentOrRefundAlert]
 * recognizes that case natively (a deliberately narrow trigger-phrase
 * check, not a full parse) and routes it straight to a silent background
 * task instead of posting anything.
 */
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) return

        // A single logical SMS can arrive as multiple concatenated parts;
        // Android delivers them together in one broadcast.
        val body = messages.joinToString(separator = "") { it.messageBody ?: "" }
        val timestampMillis = messages.first().timestampMillis
        if (body.isBlank()) return

        // Every SMS used to trigger a notification, bank or not -- a
        // promotional text mentioning a percentage-off or a cash amount
        // ("Save up to 500 EGP!") looked identical to a real bank alert to
        // this receiver, since the actual bank-format check only ran once
        // the user tapped in. looksLikeBankCardSms requires all three of a
        // money-shaped amount, a currency, and a card reference with its
        // last four digits before anything below even runs.
        if (!looksLikeBankCardSms(body)) return

        if (isCardPaymentOrRefundAlert(body)) {
            enqueueAutoUpdate(context, body, timestampMillis)
            return
        }

        postNotification(context, body, timestampMillis)
    }

    /**
     * Enqueues the same kind of headless WorkManager task
     * [SmsQuickAddActionReceiver] does for its "Quick add" action, just
     * triggered automatically here instead of by a button tap -- runs
     * `commitSmsAutoUpdate` (lib/data/sms/sms_ledger_processor.dart) in a
     * background Flutter engine, which applies the payment to the tracked
     * card balance with no notification and no ledger entry.
     */
    private fun enqueueAutoUpdate(context: Context, body: String, timestampMillis: Long) {
        val inputData = buildTaskInputData(
            dartTask = SMS_AUTO_UPDATE_TASK_NAME,
            payload = mapOf(
                "body" to body,
                "timestampMillis" to timestampMillis,
            ),
        )
        val request = OneTimeWorkRequestBuilder<BackgroundWorker>()
            .setInputData(inputData)
            .build()
        WorkManager.getInstance(context).enqueue(request)
    }

    private fun postNotification(context: Context, body: String, timestampMillis: Long) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Bank SMS detected",
                NotificationManager.IMPORTANCE_HIGH,
            )
            channel.description = "A bank text that looks like a card charge or payment"
            manager.createNotificationChannel(channel)
        }

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
            putExtra(MainActivity.EXTRA_SMS_BODY, body)
            putExtra(MainActivity.EXTRA_SMS_TIMESTAMP, timestampMillis)
        }
        // Request code varies per SMS (truncated timestamp) so back-to-back
        // messages each get their own notification instead of one
        // overwriting the pending intent of another.
        val pendingIntent = PendingIntent.getActivity(
            context,
            timestampMillis.toInt(),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val quickAddIntent = Intent(context, SmsQuickAddActionReceiver::class.java).apply {
            putExtra(SmsQuickAddActionReceiver.EXTRA_SMS_BODY, body)
            putExtra(SmsQuickAddActionReceiver.EXTRA_SMS_TIMESTAMP, timestampMillis)
        }
        val quickAddPendingIntent = PendingIntent.getBroadcast(
            context,
            timestampMillis.toInt(),
            quickAddIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_notify_chat)
            .setContentTitle("Bank text detected")
            .setContentText("Tap to check if it's a payment or a card update.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(0, "Quick add", quickAddPendingIntent)
            .build()

        manager.notify(timestampMillis.toInt(), notification)
    }

    companion object {
        private const val CHANNEL_ID = "bank_sms_detected"

        // Must match smsAutoUpdateTaskName in
        // lib/data/sms/sms_ledger_processor.dart, which
        // priceRefreshCallbackDispatcher switches on.
        private const val SMS_AUTO_UPDATE_TASK_NAME = "smsAutoUpdate"

        /**
         * The three criteria a real bank card alert states together --
         * see the class doc comment. Each is checked independently so a
         * promo text would need to accidentally satisfy all three at once
         * to slip through, which the kind of wording promos actually use
         * essentially never does:
         *
         * 1. [amountPattern] -- a money-*shaped* number: has a decimal
         *    point or thousands-comma-grouping, e.g. "958.54" or
         *    "85,891.16". Deliberately narrower than "any number", since a
         *    bare 4-digit card number would otherwise also satisfy this on
         *    its own and collapse the three criteria into two.
         * 2. [currencyPattern] -- EGP/USD (this app's supported
         *    currencies) or "جم", the Arabic abbreviation CIB/NBE alerts
         *    actually use for Egyptian pounds.
         * 3. [cardKeywordPattern] together with [fourDigitPattern] -- the
         *    word "card" (or its Arabic root "بطاق", which every inflected
         *    form -- بطاقة، بطاقتكم، لبطاقة -- shares) *and* a standalone
         *    4-digit number, standing in for "the last four digits of a
         *    card number" without needing to locate the two adjacent to
         *    each other in the text.
         */
        private val amountPattern = Regex("""\d[\d,]*\.\d+|\d{1,3}(,\d{3})+""")
        private val currencyPattern = Regex("EGP|USD|جم", RegexOption.IGNORE_CASE)
        private val cardKeywordPattern = Regex("card|بطاق", RegexOption.IGNORE_CASE)
        private val fourDigitPattern = Regex("""\b\d{4}\b""")

        private fun looksLikeBankCardSms(body: String): Boolean {
            return amountPattern.containsMatchIn(body) &&
                currencyPattern.containsMatchIn(body) &&
                cardKeywordPattern.containsMatchIn(body) &&
                fourDigitPattern.containsMatchIn(body)
        }

        /**
         * Mirrors just the *trigger phrase* of `_cibPaymentPattern` and
         * `_nbePaymentPattern` in lib/data/sms/bank_sms_parser.dart --
         * deliberately much looser than either full Dart regex (no capture
         * groups, no date/amount validation), since this only decides
         * whether to skip the notification and run the silent background
         * task instead. It never decides what gets written to the database;
         * that's still entirely the tested Dart parser's call, run
         * separately once the background task starts. Neither of CIB's or
         * NBE's *charge* alerts (the ones that should still notify) contain
         * either phrase, so a false match here would need genuinely new
         * bank wording -- if a new payment-alert format is ever added to
         * the Dart parser, add its trigger phrase here too.
         */
        private val cibPaymentAlertPattern = Regex("نشكركم\\s*على\\s*سداد\\s*مبلغ")
        private val nbePaymentAlertPattern = Regex("تم\\s*سداد\\s*مبلغ.*?بطاقتكم\\s*الائتمانية")

        private fun isCardPaymentOrRefundAlert(body: String): Boolean {
            return cibPaymentAlertPattern.containsMatchIn(body) ||
                nbePaymentAlertPattern.containsMatchIn(body)
        }
    }
}
