package com.yahiaelghayesh.wealth_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget showing the last-computed net worth summary. Data is
 * written by the Flutter side (see lib/data/widget/home_widget_service.dart)
 * via HomeWidget.saveWidgetData whenever assets or prices change; this
 * provider just renders whatever was last saved; it does no calculation or
 * network access of its own.
 */
class NetWorthWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.net_worth_widget).apply {
                setInt(R.id.widget_root, "setBackgroundResource", WidgetBackground.resolve(widgetData))
                setTextViewText(
                    R.id.widget_total_usd,
                    widgetData.getString("net_worth_total_usd", "—") ?: "—",
                )
                setTextViewText(
                    R.id.widget_total_egp,
                    widgetData.getString("net_worth_total_egp", "") ?: "",
                )
                setTextViewText(
                    R.id.widget_liquid,
                    widgetData.getString("net_worth_liquid_usd", "—") ?: "—",
                )
                setTextViewText(
                    R.id.widget_nonliquid,
                    widgetData.getString("net_worth_nonliquid_usd", "—") ?: "—",
                )
                setTextViewText(
                    R.id.widget_updated_at,
                    widgetData.getString("net_worth_updated_at", "") ?: "",
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
