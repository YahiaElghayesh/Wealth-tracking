package com.yahiaelghayesh.wealth_tracker

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.net.Uri
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

/**
 * Backs the "Pin to home screen" action on each ledger row -- a dynamic,
 * per-ledger *pinned* shortcut (`ShortcutManagerCompat.requestPinShortcut`),
 * genuinely distinct from the static `<shortcuts.xml>` entry this replaces:
 * a static shortcut is fixed at build time and can't carry a specific
 * ledger's id, which is exactly why it always fell back to the ledger-
 * picker screen instead of opening a specific ledger's add-payment form.
 * This one is created on demand, once per ledger the user chooses to pin,
 * each with its own generated avatar (initial + a color derived from the
 * ledger's name, so several pinned ledgers stay visually distinguishable
 * on the home screen) and its own counterpartyId baked into the launch
 * Intent.
 *
 * The launch Intent reuses the exact same path the "Add Payment" widget's
 * own tap already goes through: `home_widget`'s plugin only recognizes a
 * launch as "one of ours" by checking the Intent's action string for its
 * own `es.antonborri.home_widget.action.LAUNCH` constant and then reading
 * the data URI -- it isn't specific to widgets at all, just to that action
 * string. Reusing it here means `handleQuickAddLaunch`
 * (quick_add_launch.dart) handles a pinned-shortcut tap identically to a
 * widget tap, with zero new Dart-side handling.
 */
object LedgerShortcuts {
    private const val ID_PREFIX = "ledger_"

    // Same palette as the Statistics category pie chart
    // (_CategoryPieChartState._palette in statistics_screen.dart) -- reused
    // here purely for visual consistency, not because the two have to stay
    // in sync.
    private val palette = listOf(
        Color.parseColor("#2E7D6B"),
        Color.parseColor("#1565C0"),
        Color.parseColor("#6A1B9A"),
        Color.parseColor("#FF8F00"),
        Color.parseColor("#C62828"),
        Color.parseColor("#00838F"),
        Color.parseColor("#9E9D24"),
        Color.parseColor("#4527A0"),
        Color.parseColor("#AD1457"),
        Color.parseColor("#37474F"),
    )

    fun isSupported(context: Context): Boolean = ShortcutManagerCompat.isRequestPinShortcutSupported(context)

    /**
     * Submits a pin request to the launcher for [counterpartyId]/[name].
     * Returns false when pinned shortcuts aren't supported at all on this
     * device/launcher; true means the request was submitted -- the actual
     * placement still depends on the launcher's own (usually async)
     * confirmation UI, which this has no way to observe the outcome of.
     */
    fun pin(context: Context, counterpartyId: String, name: String): Boolean {
        if (!isSupported(context)) return false

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = "es.antonborri.home_widget.action.LAUNCH"
            data = Uri.parse("wealthtracker://add_ledger_entry?counterpartyId=$counterpartyId")
        }

        val label = name.ifBlank { "Ledger" }
        val shortcut = ShortcutInfoCompat.Builder(context, "$ID_PREFIX$counterpartyId")
            .setShortLabel(label.take(10))
            .setLongLabel("Add payment · $label")
            .setIcon(IconCompat.createWithBitmap(avatarBitmap(label)))
            .setIntent(launchIntent)
            .build()

        return ShortcutManagerCompat.requestPinShortcut(context, shortcut, null)
    }

    /** A circular avatar with [name]'s first letter, colored deterministically
     * from the name so the same ledger always gets the same color. */
    private fun avatarBitmap(name: String): Bitmap {
        val size = 192
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val color = palette[(name.hashCode() and 0x7FFFFFFF) % palette.size]

        val circlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }
        canvas.drawCircle(size / 2f, size / 2f, size / 2f, circlePaint)

        val initial = name.trim().firstOrNull()?.uppercaseChar()?.toString() ?: "?"
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = Color.WHITE
            textSize = size * 0.46f
            typeface = Typeface.DEFAULT_BOLD
            textAlign = Paint.Align.CENTER
        }
        val textY = size / 2f - (textPaint.descent() + textPaint.ascent()) / 2f
        canvas.drawText(initial, size / 2f, textY, textPaint)

        return bitmap
    }
}
