package com.yahiaelghayesh.wealth_tracker

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget showing the last-computed net worth summary. Data is
 * written by the Flutter side (see lib/data/widget/home_widget_service.dart)
 * via HomeWidget.saveWidgetData whenever assets or prices change; this
 * provider just renders whatever was last saved; it does no calculation or
 * network access of its own.
 *
 * Values are masked by default (someone flipping through the phone
 * shouldn't see net worth at a glance) — tapping the widget reveals the
 * real numbers briefly, then it re-masks itself automatically. A true
 * "shown only while physically held down" gesture isn't something the
 * classic AppWidget/RemoteViews framework can express — a widget click is
 * a single tap event, not a press/release pair — so a timed reveal is the
 * closest available equivalent.
 */
class NetWorthWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val ACTION_REVEAL = "com.yahiaelghayesh.wealth_tracker.action.REVEAL_NET_WORTH"
        private const val ACTION_REHIDE = "com.yahiaelghayesh.wealth_tracker.action.REHIDE_NET_WORTH"
        private const val REVEAL_DURATION_MS = 5000L
        private const val MASK = "••••••"

        private fun renderOne(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetData: SharedPreferences,
            widgetId: Int,
            revealed: Boolean,
        ) {
            val revealIntent = Intent(context, NetWorthWidgetProvider::class.java).apply {
                action = ACTION_REVEAL
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            val revealPendingIntent = PendingIntent.getBroadcast(
                context,
                widgetId,
                revealIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val views = RemoteViews(context.packageName, R.layout.net_worth_widget).apply {
                setInt(R.id.widget_root, "setBackgroundColor", WidgetBackground.resolveColor(widgetData))
                setOnClickPendingIntent(R.id.widget_root, revealPendingIntent)
                setTextViewText(
                    R.id.widget_total_usd,
                    if (revealed) widgetData.getString("net_worth_total_usd", "—") ?: "—" else MASK,
                )
                setTextViewText(
                    R.id.widget_total_egp,
                    if (revealed) widgetData.getString("net_worth_total_egp", "") ?: "" else MASK,
                )
                setTextViewText(
                    R.id.widget_liquid,
                    if (revealed) widgetData.getString("net_worth_liquid_usd", "—") ?: "—" else MASK,
                )
                setTextViewText(
                    R.id.widget_nonliquid,
                    if (revealed) widgetData.getString("net_worth_nonliquid_usd", "—") ?: "—" else MASK,
                )
                setTextViewText(
                    R.id.widget_updated_at,
                    if (revealed) widgetData.getString("net_worth_updated_at", "") ?: "" else "Tap to reveal",
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    // Any *normal* update (widget placed, periodic refresh, Flutter pushing
    // new data) always renders masked — reveal only ever comes from a tap.
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            renderOne(context, appWidgetManager, widgetData, widgetId, revealed = false)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        when (intent.action) {
            ACTION_REVEAL -> {
                if (widgetId == -1) return
                val appWidgetManager = AppWidgetManager.getInstance(context)
                renderOne(context, appWidgetManager, HomeWidgetPlugin.getData(context), widgetId, revealed = true)

                val rehideIntent = Intent(context, NetWorthWidgetProvider::class.java).apply {
                    action = ACTION_REHIDE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                }
                val rehidePendingIntent = PendingIntent.getBroadcast(
                    context,
                    widgetId,
                    rehideIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                // Inexact on purpose — this is a cosmetic auto-hide, not
                // something that needs SCHEDULE_EXACT_ALARM permission
                // friction for a few seconds of possible slack.
                alarmManager.set(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    SystemClock.elapsedRealtime() + REVEAL_DURATION_MS,
                    rehidePendingIntent,
                )
            }
            ACTION_REHIDE -> {
                if (widgetId == -1) return
                val appWidgetManager = AppWidgetManager.getInstance(context)
                renderOne(context, appWidgetManager, HomeWidgetPlugin.getData(context), widgetId, revealed = false)
            }
            else -> super.onReceive(context, intent)
        }
    }
}
