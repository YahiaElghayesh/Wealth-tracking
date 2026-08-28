package com.yahiaelghayesh.wealth_tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Small home-screen widget with a single purpose: tapping it opens the app
 * straight into "Add ledger entry", skipping the dashboard/ledger
 * navigation. The Flutter side reads the launch URI (see
 * lib/features/ledger/providers/quick_add_launch.dart) and pushes the add
 * screen once the app is up.
 */
class QuickAddLedgerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("wealthtracker://add_ledger_entry"),
        )

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.quick_add_ledger_widget).apply {
                setOnClickPendingIntent(R.id.quick_add_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
