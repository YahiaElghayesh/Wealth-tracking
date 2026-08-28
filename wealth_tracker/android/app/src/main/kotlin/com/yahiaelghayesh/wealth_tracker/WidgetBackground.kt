package com.yahiaelghayesh.wealth_tracker

import android.content.SharedPreferences

/**
 * Resolves the user's chosen widget background preset + opacity (both set
 * from the app's Settings screen, mirrored into home_widget's shared prefs)
 * to a single ARGB color — shared by both widget providers so they always
 * agree on the available presets and the fallback.
 *
 * This is applied via `RemoteViews.setInt(id, "setBackgroundColor", ...)`
 * rather than a preset drawable, so opacity is a plain alpha channel on a
 * flat fill rather than a fixed value baked into an XML shape. Modern
 * Android (12+) launchers already round every widget's outer corners
 * themselves, so losing the drawable's own corner radius isn't a visible
 * regression there.
 */
object WidgetBackground {
    private const val PRESET_KEY = "widget_background_preset"
    private const val OPACITY_KEY = "widget_background_opacity"

    // Fully opaque base colors — opacity is applied on top of these.
    private const val COLOR_DEFAULT = 0xFF2E7D6B.toInt()
    private const val COLOR_BLUE = 0xFF1565C0.toInt()
    private const val COLOR_PURPLE = 0xFF6A1B9A.toInt()
    private const val COLOR_AMBER = 0xFFFF8F00.toInt()
    private const val COLOR_CHARCOAL = 0xFF263238.toInt()

    /** Matches the pre-opacity-control default look (~12% alpha). */
    private const val DEFAULT_OPACITY_PERCENT = 12

    fun resolveColor(widgetData: SharedPreferences): Int {
        val base = when (widgetData.getString(PRESET_KEY, "default")) {
            "blue" -> COLOR_BLUE
            "purple" -> COLOR_PURPLE
            "amber" -> COLOR_AMBER
            "charcoal" -> COLOR_CHARCOAL
            else -> COLOR_DEFAULT
        }
        val percent = widgetData.getInt(OPACITY_KEY, DEFAULT_OPACITY_PERCENT).coerceIn(0, 100)
        val alpha = percent * 255 / 100
        return (alpha shl 24) or (base and 0x00FFFFFF)
    }
}
