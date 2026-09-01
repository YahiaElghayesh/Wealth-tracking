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
        val rawBody = messages.joinToString(separator = "") { it.messageBody ?: "" }
        val timestampMillis = messages.first().timestampMillis
        if (rawBody.isBlank()) return
        // See normalizeSmsBody's own doc comment -- strips invisible bidi
        // marks banks embed around numbers in Arabic text before any of the
        // checks below (or the Dart parser downstream) ever see this text.
        val body = normalizeSmsBody(rawBody)

        // Every SMS used to trigger a notification, bank or not -- a
        // promotional text mentioning a percentage-off or a cash amount
        // ("Save up to 500 EGP!") looked identical to a real bank alert to
        // this receiver, since the actual bank-format check only ran once
        // the user tapped in. looksLikeBankCardSms requires a money-shaped
        // amount, a currency, a card reference with its last four digits,
        // and (when at least one card is actually registered) that those
        // four digits match a real card, before anything below even runs.
        if (!looksLikeBankCardSms(context, body)) return

        // An OTP/verification-code SMS restates the amount, currency, and
        // card it's for (to identify which purchase the code belongs to),
        // so it can satisfy every criterion above despite not being a
        // transaction of any kind -- see isOtpMessage's own doc comment.
        if (isOtpMessage(body)) return

        if (isCardPaymentOrRefundAlert(body)) {
            enqueueAutoUpdate(context, body, timestampMillis)
            return
        }

        // A charge whose vendor already matches a Vendor Rule (see
        // matchesKnownVendorPattern) skips the notification entirely and
        // commits straight to that rule's ledger, per the user's explicit
        // ask to not have to confirm ones that are already resolved -- the
        // same zero-tap outcome the notification's own "Quick add" button
        // already gave, just triggered automatically instead of requiring
        // that tap.
        if (matchesKnownVendorPattern(context, body)) {
            enqueueQuickAdd(context, body, timestampMillis)
            return
        }

        postNotification(context, body, timestampMillis)
    }

    /**
     * Enqueues the same headless WorkManager task the notification's own
     * "Quick add" action button does ([SmsQuickAddActionReceiver]), just
     * triggered automatically here instead of by a tap -- runs
     * `commitSmsQuickAdd` (lib/data/sms/sms_ledger_processor.dart) in a
     * background Flutter engine, which re-verifies the vendor-rule match
     * with the real, tested Dart logic (this native check is a fast,
     * approximate pre-filter, not the actual decision) and, if it still
     * matches, both updates the tracked card balance and adds the ledger
     * entry -- with no notification and no confirmation needed.
     */
    private fun enqueueQuickAdd(context: Context, body: String, timestampMillis: Long) {
        val inputData = buildTaskInputData(
            dartTask = SMS_QUICK_ADD_TASK_NAME,
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

        // Must match smsQuickAddTaskName in
        // lib/data/sms/sms_ledger_processor.dart -- the same task name
        // SmsQuickAddActionReceiver's own button-triggered path uses.
        private const val SMS_QUICK_ADD_TASK_NAME = "smsQuickAdd"

        /**
         * Strips invisible Unicode bidi/formatting characters banks commonly
         * embed in Arabic SMS text to control how a Western-digit number (an
         * amount, a card's last-4-digits) displays inside right-to-left prose
         * -- RLM/LRM marks, explicit embedding/override/isolate direction
         * controls, and zero-width joiners -- none of which \s matches in
         * Kotlin's regex engine, so one sitting between two pieces a pattern
         * below expects adjacent (e.g. a currency code and its amount) would
         * silently defeat the match with no visible sign why, since these
         * characters render as nothing at all. Mirrors _normalizeSmsBody in
         * lib/data/sms/bank_sms_parser.dart -- kept in sync so this receiver's
         * own gate and the Dart parser downstream never disagree about
         * whether a given SMS looks like a bank alert.
         */
        private val bidiMarkPattern = Regex("[\u200B-\u200F\u202A-\u202E\u2066-\u2069\u061C]")

        fun normalizeSmsBody(body: String): String {
            return bidiMarkPattern.replace(body, "").replace('\u00A0', ' ')
        }

        /**
         * The criteria a real bank card alert states together -- see the
         * class doc comment. Each is checked independently so a promo text
         * would need to accidentally satisfy all of them at once to slip
         * through, which the kind of wording promos actually use
         * essentially never does:
         *
         * 1. [amountPattern] -- a money-*shaped* number: has a decimal
         *    point or thousands-comma-grouping, e.g. "958.54" or
         *    "85,891.16". Deliberately narrower than "any number", since a
         *    bare 4-digit card number would otherwise also satisfy this on
         *    its own and collapse this criterion into the next.
         * 2. [currencyPattern] -- EGP/USD (this app's supported
         *    currencies) or "جم", the Arabic abbreviation CIB/NBE alerts
         *    actually use for Egyptian pounds.
         * 3. [cardKeywordPattern] together with [fourDigitPattern] -- the
         *    word "card" (or its Arabic root "بطاق", which every inflected
         *    form -- بطاقة، بطاقتكم، لبطاقة -- shares) *and* a standalone
         *    4-digit number, standing in for "the last four digits of a
         *    card number" without needing to locate the two adjacent to
         *    each other in the text.
         * 4. [matchesKnownCardIfAnyRegistered] -- that 4-digit number
         *    actually belongs to a card the user has registered (in any
         *    profile, not just whichever is active), read from
         *    home_widget's shared storage (see
         *    lib/features/calculator/providers/known_cards_sync.dart --
         *    the only Dart->native bridge already used for exactly this
         *    "native code needs something Dart's database owns" need).
         *    Skipped (never blocks) when nothing is registered yet, so a
         *    fresh install or a user who hasn't added any cards doesn't
         *    lose SMS detection entirely over an empty list.
         */
        private val amountPattern = Regex("""\d[\d,]*\.\d+|\d{1,3}(,\d{3})+""")
        private val currencyPattern = Regex("EGP|USD|جم", RegexOption.IGNORE_CASE)
        private val cardKeywordPattern = Regex("card|بطاق", RegexOption.IGNORE_CASE)
        private val fourDigitPattern = Regex("""\b\d{4}\b""")

        // Must match the file/key HomeWidget.saveWidgetData writes to from
        // known_cards_sync.dart -- see home_widget's own Android plugin
        // (HomeWidgetPlugin.PREFERENCES) for why this exact plain
        // SharedPreferences file, rather than the Flutter shared_preferences
        // plugin's own storage (which as of its current version is backed
        // by AndroidX DataStore, not a plain SharedPreferences file this
        // receiver could read directly).
        private const val HOME_WIDGET_PREFERENCES = "HomeWidgetPreferences"
        private const val KNOWN_CARDS_KEY = "known_card_last_four_digits"

        // Must match the key HomeWidget.saveWidgetData writes to from
        // known_vendor_patterns_sync.dart.
        private const val KNOWN_VENDOR_PATTERNS_KEY = "known_vendor_patterns"

        private fun looksLikeBankCardSms(context: Context, body: String): Boolean {
            return amountPattern.containsMatchIn(body) &&
                currencyPattern.containsMatchIn(body) &&
                cardKeywordPattern.containsMatchIn(body) &&
                fourDigitPattern.containsMatchIn(body) &&
                matchesKnownCardIfAnyRegistered(context, body)
        }

        private fun matchesKnownCardIfAnyRegistered(context: Context, body: String): Boolean {
            val knownLastFourDigits = readKnownCardLastFourDigits(context)
            if (knownLastFourDigits.isEmpty()) return true
            return fourDigitPattern.findAll(body).any { it.value in knownLastFourDigits }
        }

        private fun readKnownCardLastFourDigits(context: Context): Set<String> {
            val json = context
                .getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
                .getString(KNOWN_CARDS_KEY, null) ?: return emptySet()
            return try {
                val array = org.json.JSONArray(json)
                (0 until array.length()).map { array.getString(it) }.toSet()
            } catch (e: org.json.JSONException) {
                emptySet()
            }
        }

        /**
         * Whether [body] looks like it's for a vendor a Vendor Rule already
         * resolves -- a plain case-insensitive substring check against
         * [readKnownVendorPatterns], deliberately approximate (no attempt at
         * locating exactly where a "vendor" segment starts/ends the way each
         * bank-specific Dart pattern does) since this only decides whether to
         * skip the notification and hand off to the background auto-commit
         * task instead; the real match (and the actual ledger write) is
         * still entirely `commitSmsQuickAdd`'s call, re-run separately with
         * the tested Dart logic once that task starts. Unlike
         * [matchesKnownCardIfAnyRegistered], an empty list answers false, not
         * true -- no Vendor Rules configured yet means nothing here should
         * ever silently skip the notification.
         */
        private fun matchesKnownVendorPattern(context: Context, body: String): Boolean {
            val patterns = readKnownVendorPatterns(context)
            if (patterns.isEmpty()) return false
            val lowerBody = body.lowercase()
            return patterns.any { lowerBody.contains(it) }
        }

        private fun readKnownVendorPatterns(context: Context): Set<String> {
            val json = context
                .getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
                .getString(KNOWN_VENDOR_PATTERNS_KEY, null) ?: return emptySet()
            return try {
                val array = org.json.JSONArray(json)
                (0 until array.length()).map { array.getString(it) }.toSet()
            } catch (e: org.json.JSONException) {
                emptySet()
            }
        }

        /**
         * Mirrors just the *trigger phrase* of `_cibPaymentPattern`,
         * `_nbePaymentPattern`, and `_nbeRefundPattern` in
         * lib/data/sms/bank_sms_parser.dart -- deliberately much looser
         * than any of the full Dart regexes (no capture groups, no date/
         * amount validation), since this only decides whether to skip the
         * notification and run the silent background task instead. It
         * never decides what gets written to the database; that's still
         * entirely the tested Dart parser's call, run separately once the
         * background task starts. Neither of CIB's or NBE's *charge*
         * alerts (the ones that should still notify) contain any of these
         * phrases, so a false match here would need genuinely new bank
         * wording -- if a new payment/refund-alert format is ever added to
         * the Dart parser, add its trigger phrase here too.
         */
        private val cibPaymentAlertPattern = Regex("نشكركم\\s*على\\s*سداد\\s*مبلغ")
        private val nbePaymentAlertPattern = Regex("تم\\s*سداد\\s*مبلغ.*?بطاقتكم\\s*الائتمانية")
        private val nbeRefundAlertPattern = Regex("تم\\s*رد.*?بطاقتكم\\s*الائتمانية")

        /**
         * A one-time-passcode SMS states a secret code for the user to type
         * elsewhere -- never a completed charge, payment, or refund -- even
         * though it commonly restates the purchase amount, currency, and
         * card it's for (to tell the user which purchase the code is
         * authorizing), which is exactly what lets it slip past
         * [looksLikeBankCardSms]'s four criteria above despite not being a
         * transaction at all (confirmed from a real message: "...لبطاقة رقم
         * 4912 بمبلغ EGP 2844.90... OTP: 624303"). Checked on wording alone,
         * not which bank sent it, same as every other pattern in this file
         * -- "OTP" appears verbatim regardless of the surrounding language,
         * and Arabic banks separately phrase this as "الرقم السري المتغير"
         * (variable/dynamic secret number) or "رمز التحقق" (verification
         * code).
         */
        private val otpPattern = Regex(
            """\botp\b|الرقم\s*السري\s*المتغير|رمز\s*التحقق""",
            RegexOption.IGNORE_CASE,
        )

        private fun isOtpMessage(body: String): Boolean = otpPattern.containsMatchIn(body)

        private fun isCardPaymentOrRefundAlert(body: String): Boolean {
            return cibPaymentAlertPattern.containsMatchIn(body) ||
                nbePaymentAlertPattern.containsMatchIn(body) ||
                nbeRefundAlertPattern.containsMatchIn(body)
        }
    }
}
