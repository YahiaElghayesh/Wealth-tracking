package com.yahiaelghayesh.wealth_tracker

import android.content.SharedPreferences

/**
 * Resolves the user's chosen widget background preset (set from the app's
 * Settings screen, mirrored into home_widget's shared prefs) to a drawable
 * resource — shared by both widget providers so they always agree on the
 * available presets and the fallback.
 */
object WidgetBackground {
    private const val PREF_KEY = "widget_background_preset"

    fun resolve(widgetData: SharedPreferences): Int {
        return when (widgetData.getString(PREF_KEY, "default")) {
            "blue" -> R.drawable.widget_background_blue
            "purple" -> R.drawable.widget_background_purple
            "amber" -> R.drawable.widget_background_amber
            "charcoal" -> R.drawable.widget_background_charcoal
            else -> R.drawable.widget_background
        }
    }
}
