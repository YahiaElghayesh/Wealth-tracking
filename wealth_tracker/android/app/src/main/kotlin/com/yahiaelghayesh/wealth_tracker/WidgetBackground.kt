package com.yahiaelghayesh.wealth_tracker

import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.os.Build
import android.widget.RemoteViews

/**
 * Resolves the user's chosen widget background preset + opacity (both set
 * from the app's Settings screen, mirrored into home_widget's shared prefs)
 * and applies it to a widget's root view — shared by both widget providers
 * so they always agree on the available presets, the fallback, and how the
 * color actually gets painted.
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

    private fun resolveColor(widgetData: SharedPreferences): Int {
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

    /**
     * Paints [rootId] with the user's chosen color + opacity, rounded where
     * the platform allows it. RemoteViews has no direct "rounded rect with
     * an arbitrary runtime color" primitive: `setBackgroundColor` always
     * paints a flat, square-cornered fill, and tinting a shape drawable's
     * color at runtime (`setColorStateList` -> `setBackgroundTintList`)
     * only exists from Android 12 onward. So: 12+ gets the real rounded
     * shape, tinted; everything older falls back to the previous flat,
     * square-cornered fill so color/opacity still work everywhere.
     */
    fun applyTo(views: RemoteViews, rootId: Int, widgetData: SharedPreferences) {
        val argb = resolveColor(widgetData)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setInt(rootId, "setBackgroundResource", R.drawable.widget_rounded_shape)
            views.setColorStateList(rootId, "setBackgroundTintList", ColorStateList.valueOf(argb))
        } else {
            views.setInt(rootId, "setBackgroundColor", argb)
        }
    }
}
