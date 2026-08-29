package com.yahiaelghayesh.wealth_tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Small home-screen widget with a single purpose: tapping it opens the app
 * straight into adding a ledger entry, skipping the dashboard/ledger
 * navigation. Each placed instance can be configured (see
 * [QuickAddLedgerWidgetConfigureActivity]) to target a specific
 * counterparty, so multiple widgets can each point at a different person's
 * ledger; the target is baked into the launch URI's `counterpartyId` query
 * parameter, which the Flutter side reads (see
 * lib/features/ledger/providers/quick_add_launch.dart).
 */
class QuickAddLedgerWidgetProvider : AppWidgetProvider() {
    companion object {
        // Below this granted width there isn't room for "Add Payment" plus
        // a ledger name to stay legible side by side -- switch to the
        // compact square layout (matching the mockup's true 1x1 widget)
        // instead of letting the wide one clip.
        private const val COMPACT_MAX_WIDTH_DP = 110

        private fun renderOne(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetData: android.content.SharedPreferences,
            widgetId: Int,
        ) {
            val configured = QuickAddLedgerWidgetConfigureActivity.loadCounterparty(context, widgetId)

            val uriBuilder = Uri.parse("wealthtracker://add_ledger_entry").buildUpon()
            if (configured != null) {
                uriBuilder.appendQueryParameter("counterpartyId", configured.first)
            }
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                uriBuilder.build(),
            )

            // The avatar shows the bound ledger's initial (matching the
            // mockup's w1x1 pattern); an unconfigured widget just keeps
            // the "+" it's inflated with, since there's no name yet to
            // take an initial from.
            val initial = configured?.second?.trim()?.firstOrNull()?.uppercaseChar()?.toString()
            val name = configured?.second

            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, Int.MAX_VALUE)
            val compact = widthDp < COMPACT_MAX_WIDTH_DP

            val views = RemoteViews(context.packageName, R.layout.quick_add_ledger_widget).apply {
                setOnClickPendingIntent(R.id.quick_add_root, pendingIntent)
                setViewVisibility(R.id.quick_add_compact, if (compact) android.view.View.VISIBLE else android.view.View.GONE)
                setViewVisibility(R.id.quick_add_wide, if (compact) android.view.View.GONE else android.view.View.VISIBLE)
                setTextViewText(R.id.quick_add_subtitle, name ?: "")
                setTextViewText(R.id.quick_add_name_compact, name ?: "Add Payment")
                if (initial != null) {
                    setTextViewText(R.id.quick_add_avatar, initial)
                    setTextViewText(R.id.quick_add_avatar_compact, initial)
                }
            }
            WidgetBackground.applyTo(views, R.id.quick_add_root, widgetData)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        appWidgetIds.forEach { widgetId -> renderOne(context, appWidgetManager, widgetData, widgetId) }
    }

    // Fired whenever the user resizes the widget — re-render so it switches
    // between the compact and wide layouts immediately instead of waiting
    // for the next periodic update.
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        renderOne(context, appWidgetManager, HomeWidgetPlugin.getData(context), appWidgetId)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        appWidgetIds.forEach { widgetId ->
            QuickAddLedgerWidgetConfigureActivity.clearCounterparty(context, widgetId)
        }
    }
}
