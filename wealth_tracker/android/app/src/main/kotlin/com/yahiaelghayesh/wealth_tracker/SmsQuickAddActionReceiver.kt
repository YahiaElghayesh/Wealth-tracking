package com.yahiaelghayesh.wealth_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker
import dev.fluttercommunity.workmanager.buildTaskInputData

/**
 * Fired by the "Quick add" action button on a bank-SMS notification --
 * lets the user commit the charge to whichever ledger a Vendor Rule
 * already maps its sender to, straight from the notification panel, with
 * no need to open the app first. Enqueues a WorkManager one-off task that
 * runs the existing, tested Dart commit logic (`commitSmsQuickAdd`) in a
 * headless Flutter engine -- the exact same mechanism the periodic
 * background price refresh already uses (see `priceRefreshCallbackDispatcher`
 * in background_refresh.dart) -- rather than re-implementing SMS parsing or
 * ledger writes natively, which would mean keeping two copies of that
 * logic in sync forever. [buildTaskInputData]/[BackgroundWorker] come
 * straight from the `workmanager` plugin's own Android module; this is the
 * same request shape `Workmanager().registerOneOffTask()` builds on the
 * Dart side, just assembled natively since there's no running Dart engine
 * to call that from here.
 *
 * If nothing actually matches (no Vendor Rule for this sender), the Dart
 * side just does nothing; the notification itself is deliberately left in
 * place either way so the user still has the normal tap-to-review fallback
 * -- there's no cheap way to report the outcome back from a background
 * isolate to this receiver to decide whether it's now safe to dismiss it.
 */
class SmsQuickAddActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val body = intent.getStringExtra(EXTRA_SMS_BODY) ?: return
        val timestampMillis = intent.getLongExtra(EXTRA_SMS_TIMESTAMP, -1L)
        if (timestampMillis < 0) return

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

    companion object {
        const val EXTRA_SMS_BODY = "com.yahiaelghayesh.wealth_tracker.extra.SMS_BODY"
        const val EXTRA_SMS_TIMESTAMP = "com.yahiaelghayesh.wealth_tracker.extra.SMS_TIMESTAMP"

        // Must match smsQuickAddTaskName in
        // lib/data/sms/sms_ledger_processor.dart, which
        // priceRefreshCallbackDispatcher switches on.
        const val SMS_QUICK_ADD_TASK_NAME = "smsQuickAdd"
    }
}
