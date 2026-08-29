package com.yahiaelghayesh.wealth_tracker

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock
import android.util.TypedValue
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

        // Classic RemoteViews text doesn't reflow or auto-shrink to fit the
        // space a launcher actually grants a resized widget — fixed sp
        // sizes at a 1-cell height just overlap/clip instead. Rather than
        // let that happen, hide progressively more of the secondary rows
        // as the granted height shrinks, so what *is* shown always fits.
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

            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, Int.MAX_VALUE)
            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, Int.MAX_VALUE)
            val showBreakdown = heightDp >= 90
            val showUpdatedAt = heightDp >= 130
            // Classic RemoteViews text is a fixed sp size that doesn't
            // reflow to fit a resized widget -- a compact-width widget
            // showing a large EGP total (e.g. "EGP 1,842,300") would
            // otherwise clip with an ellipsis instead of just rendering
            // smaller. Step the size down as the granted width shrinks.
            val totalTextSizeSp = when {
                widthDp < 110 -> 15f
                widthDp < 150 -> 18f
                else -> 22f
            }

            val views = RemoteViews(context.packageName, R.layout.net_worth_widget).apply {
                setOnClickPendingIntent(R.id.widget_root, revealPendingIntent)
                setTextViewTextSize(R.id.widget_total_egp, TypedValue.COMPLEX_UNIT_SP, totalTextSizeSp)
                // Primary figure is EGP (bigger, first) with USD secondary —
                // matches how the rest of the app now orders the two.
                setTextViewText(
                    R.id.widget_total_egp,
                    if (revealed) widgetData.getString("net_worth_total_egp", "—")?.ifBlank { "—" } ?: "—" else MASK,
                )
                setTextViewText(
                    R.id.widget_total_usd,
                    if (revealed) widgetData.getString("net_worth_total_usd", "") ?: "" else MASK,
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
                setViewVisibility(R.id.widget_breakdown_row, if (showBreakdown) android.view.View.VISIBLE else android.view.View.GONE)
                setViewVisibility(R.id.widget_updated_at, if (showUpdatedAt) android.view.View.VISIBLE else android.view.View.GONE)
            }
            WidgetBackground.applyTo(views, R.id.widget_root, widgetData)
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

    // Fired whenever the user resizes the widget — re-render so the
    // breakdown/updated-at rows show or hide to match the new size
    // immediately, instead of waiting for the next periodic update.
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        renderOne(context, appWidgetManager, HomeWidgetPlugin.getData(context), appWidgetId, revealed = false)
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
