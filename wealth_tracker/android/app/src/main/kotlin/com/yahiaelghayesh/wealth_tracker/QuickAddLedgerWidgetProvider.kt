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
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        appWidgetIds.forEach { widgetId ->
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

            val views = RemoteViews(context.packageName, R.layout.quick_add_ledger_widget).apply {
                setOnClickPendingIntent(R.id.quick_add_root, pendingIntent)
                setTextViewText(R.id.quick_add_subtitle, configured?.second ?: "")
            }
            WidgetBackground.applyTo(views, R.id.quick_add_root, widgetData)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        appWidgetIds.forEach { widgetId ->
            QuickAddLedgerWidgetConfigureActivity.clearCounterparty(context, widgetId)
        }
    }
}
