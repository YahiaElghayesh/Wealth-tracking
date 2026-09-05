package com.yahiaelghayesh.wealth_tracker

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker
import dev.fluttercommunity.workmanager.buildTaskInputData

/**
 * Schedules and cancels the repeating reminder notification for a 'manual'
 * RecurringPayment (see RecurringPayments.paymentMode's doc comment in
 * lib/data/db/tables.dart) -- Dart's `recurringPaymentReminderSyncProvider`
 * calls [schedule]/[cancel] whenever a payment's paid/pending state or
 * payment mode changes, computing *when* the first reminder is due (midnight
 * on the current cycle's due date); everything after that first firing --
 * the whole repeat-every-4-hours-until-done chain -- runs entirely natively,
 * with no need for the app (or even a Flutter engine) to be running.
 * [RecurringPaymentReminderReceiver] re-arms the next firing every time it
 * shows the notification; [RecurringPaymentReminderBootReceiver] restores
 * every still-pending reminder after a device restart, since AlarmManager
 * itself forgets every alarm across one.
 *
 * Deliberately uses `setAndAllowWhileIdle` rather than the exact-alarm
 * variant, mirroring NetWorthWidgetProvider's own reasoning: a reminder
 * landing within a few minutes of the requested time is entirely fine for
 * this, and it avoids sending the user to Android 12+'s "Alarms & reminders"
 * special-access settings page just to turn this feature on.
 */
object RecurringPaymentReminderScheduler {
    private const val PREFS_NAME = "recurring_payment_reminders"
    private const val CHANNEL_ID = "recurring_payment_reminder"
    private const val REPEAT_INTERVAL_MS = 4 * 60 * 60 * 1000L

    const val ACTION_SHOW = "com.yahiaelghayesh.wealth_tracker.action.SHOW_RECURRING_REMINDER"
    const val EXTRA_PAYMENT_ID = "payment_id"
    const val EXTRA_NAME = "name"
    const val EXTRA_AMOUNT = "amount"

    fun schedule(context: Context, paymentId: String, name: String, amount: String, dueAtMillis: Long) {
        persist(context, paymentId, name, amount, dueAtMillis)
        armAlarm(context, paymentId, name, amount, dueAtMillis)
    }

    fun cancel(context: Context, paymentId: String) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            .remove(nameKey(paymentId))
            .remove(amountKey(paymentId))
            .remove(fireAtKey(paymentId))
            .apply()
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntentFor(context, paymentId, "", ""))
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(notificationIdFor(paymentId))
    }

    /**
     * Re-arms every reminder still recorded in SharedPreferences -- called
     * once on device boot ([RecurringPaymentReminderBootReceiver]), since
     * AlarmManager forgets every alarm across a restart. A reminder whose
     * stored fire time already passed during the downtime fires again
     * almost immediately rather than being silently lost until the app is
     * next opened.
     */
    fun rescheduleAllAfterBoot(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val ids = prefs.all.keys
            .filter { it.endsWith(":fireAt") }
            .map { it.removeSuffix(":fireAt") }
        val now = System.currentTimeMillis()
        for (id in ids) {
            val name = prefs.getString(nameKey(id), null) ?: continue
            val amount = prefs.getString(amountKey(id), "") ?: ""
            val fireAt = prefs.getLong(fireAtKey(id), -1L)
            if (fireAt < 0) continue
            armAlarm(context, id, name, amount, maxOf(fireAt, now + 5_000L))
        }
    }

    /**
     * Called by [RecurringPaymentReminderReceiver] right after showing a
     * reminder, to chain the next one 4 hours later -- this is the entire
     * "keep repeating until Done" mechanism, with no need for anything
     * outside this file to drive it.
     */
    fun rearmForRepeat(context: Context, paymentId: String, name: String, amount: String) {
        val nextFireAt = System.currentTimeMillis() + REPEAT_INTERVAL_MS
        persist(context, paymentId, name, amount, nextFireAt)
        armAlarm(context, paymentId, name, amount, nextFireAt)
    }

    fun notificationIdFor(paymentId: String): Int = paymentId.hashCode()

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Recurring payment reminders",
                // High importance is what makes this pop in from the top of
                // the screen (a "heads-up" notification) instead of just
                // sitting silently in the shade -- sound/vibration are
                // turned off explicitly below, since a channel's
                // sound/vibration settings (unlike its importance) can't be
                // changed later once first created on a real device.
                NotificationManager.IMPORTANCE_HIGH,
            )
            channel.description = "Reminds you about a manual recurring payment until you mark it paid"
            channel.setSound(null, null)
            channel.enableVibration(false)
            manager.createNotificationChannel(channel)
        }
    }

    fun channelId(): String = CHANNEL_ID

    private fun persist(context: Context, paymentId: String, name: String, amount: String, fireAtMillis: Long) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            .putString(nameKey(paymentId), name)
            .putString(amountKey(paymentId), amount)
            .putLong(fireAtKey(paymentId), fireAtMillis)
            .apply()
    }

    private fun armAlarm(context: Context, paymentId: String, name: String, amount: String, fireAtMillis: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = pendingIntentFor(context, paymentId, name, amount)
        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAtMillis, pendingIntent)
    }

    private fun pendingIntentFor(context: Context, paymentId: String, name: String, amount: String): PendingIntent {
        val intent = Intent(context, RecurringPaymentReminderReceiver::class.java).apply {
            action = ACTION_SHOW
            putExtra(EXTRA_PAYMENT_ID, paymentId)
            putExtra(EXTRA_NAME, name)
            putExtra(EXTRA_AMOUNT, amount)
        }
        return PendingIntent.getBroadcast(
            context,
            paymentId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun nameKey(paymentId: String) = "$paymentId:name"
    private fun amountKey(paymentId: String) = "$paymentId:amount"
    private fun fireAtKey(paymentId: String) = "$paymentId:fireAt"
}

/**
 * Fires when a manual recurring payment's reminder is due -- shows (or
 * updates, via a notification id stable per payment) the reminder
 * notification with a "Done" action, then immediately re-arms the next
 * firing 4 hours out via [RecurringPaymentReminderScheduler.rearmForRepeat].
 * This chain is the entire "keep pushing it every 4 hours until paid"
 * behavior -- it only ever stops because [RecurringPaymentReminderScheduler.cancel]
 * cancelled the underlying alarm first (from the "Done" action, or from the
 * in-app paid toggle via the Dart-side sync provider), so simply having
 * fired at all here means it's still genuinely pending.
 */
class RecurringPaymentReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != RecurringPaymentReminderScheduler.ACTION_SHOW) return
        val paymentId = intent.getStringExtra(RecurringPaymentReminderScheduler.EXTRA_PAYMENT_ID) ?: return
        val name = intent.getStringExtra(RecurringPaymentReminderScheduler.EXTRA_NAME) ?: return
        val amount = intent.getStringExtra(RecurringPaymentReminderScheduler.EXTRA_AMOUNT) ?: ""

        RecurringPaymentReminderScheduler.ensureChannel(context)

        val doneIntent = Intent(context, RecurringPaymentReminderDoneActionReceiver::class.java).apply {
            putExtra(RecurringPaymentReminderScheduler.EXTRA_PAYMENT_ID, paymentId)
        }
        val donePendingIntent = PendingIntent.getBroadcast(
            context,
            paymentId.hashCode(),
            doneIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context,
            paymentId.hashCode(),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val contentText = if (amount.isNotEmpty()) "$amount due -- tap Done once you've paid it." else "Tap Done once you've paid it."
        val notification = NotificationCompat.Builder(context, RecurringPaymentReminderScheduler.channelId())
            .setSmallIcon(android.R.drawable.stat_notify_chat)
            .setContentTitle("$name is due")
            .setContentText(contentText)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOnlyAlertOnce(true)
            .setAutoCancel(false)
            .setContentIntent(contentPendingIntent)
            .addAction(0, "Done", donePendingIntent)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(RecurringPaymentReminderScheduler.notificationIdFor(paymentId), notification)

        RecurringPaymentReminderScheduler.rearmForRepeat(context, paymentId, name, amount)
    }
}

/**
 * Fired by the reminder notification's "Done" action -- stops the repeating
 * chain immediately (cancels the pending alarm and dismisses the
 * notification) and enqueues a headless WorkManager task that marks the
 * payment paid in the real database, mirroring exactly how
 * SmsQuickAddActionReceiver hands its own button tap off to Dart rather
 * than duplicating database logic natively. The notification is stopped
 * eagerly here rather than waiting on that background task to report
 * success, since there's no cheap way to get a result back from a headless
 * isolate to this receiver -- if the task somehow fails, the payment simply
 * stays pending and the very next sync from the app (or the next due cycle)
 * will schedule a fresh reminder for it, same as any other missed write.
 */
class RecurringPaymentReminderDoneActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val paymentId = intent.getStringExtra(RecurringPaymentReminderScheduler.EXTRA_PAYMENT_ID) ?: return
        RecurringPaymentReminderScheduler.cancel(context, paymentId)

        val inputData = buildTaskInputData(
            dartTask = RECURRING_PAYMENT_MARK_PAID_TASK_NAME,
            payload = mapOf("paymentId" to paymentId),
        )
        val request = OneTimeWorkRequestBuilder<BackgroundWorker>()
            .setInputData(inputData)
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .build()
        WorkManager.getInstance(context).enqueue(request)
    }

    companion object {
        // Must match recurringPaymentMarkPaidTaskName in
        // lib/data/pricing/background_refresh.dart, which
        // priceRefreshCallbackDispatcher switches on.
        private const val RECURRING_PAYMENT_MARK_PAID_TASK_NAME = "recurringPaymentMarkPaid"
    }
}

/**
 * Restores every still-pending manual-payment reminder after a device
 * restart -- AlarmManager forgets every alarm it was holding across a
 * reboot, so without this, a reminder that was mid-chain when the phone
 * restarted would simply never fire again until the app happened to be
 * reopened (which re-syncs from Dart, but only for payments still due at
 * that later point -- one already due before the reboot would otherwise go
 * silent for however long that gap is).
 */
class RecurringPaymentReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        RecurringPaymentReminderScheduler.rescheduleAllAfterBoot(context)
    }
}
