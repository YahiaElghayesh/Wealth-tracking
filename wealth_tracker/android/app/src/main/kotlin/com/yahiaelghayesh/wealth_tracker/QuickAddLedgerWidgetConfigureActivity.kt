package com.yahiaelghayesh.wealth_tracker

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

/**
 * Lets the user pick which counterparty (person) a placed "Add Payment"
 * widget instance targets, so multiple widgets can each point at a
 * different ledger. Selection is stored per appWidgetId in
 * [PREFS_NAME], read back by [QuickAddLedgerWidgetProvider].
 */
class QuickAddLedgerWidgetConfigureActivity : Activity() {

    companion object {
        const val PREFS_NAME = "quick_add_widget_config"

        fun counterpartyIdKey(appWidgetId: Int) = "id_$appWidgetId"
        fun counterpartyNameKey(appWidgetId: Int) = "name_$appWidgetId"

        fun loadCounterparty(context: Context, appWidgetId: Int): Pair<String, String>? {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val id = prefs.getString(counterpartyIdKey(appWidgetId), null)
            val name = prefs.getString(counterpartyNameKey(appWidgetId), null)
            return if (id != null && name != null) Pair(id, name) else null
        }

        fun clearCounterparty(context: Context, appWidgetId: Int) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
                .remove(counterpartyIdKey(appWidgetId))
                .remove(counterpartyNameKey(appWidgetId))
                .apply()
        }
    }

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        setContentView(R.layout.quick_add_widget_configure)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val counterparties = readCounterparties()
        val listView = findViewById<ListView>(R.id.configure_list)
        val emptyMessage = findViewById<TextView>(R.id.configure_empty_message)

        if (counterparties.isEmpty()) {
            listView.visibility = View.GONE
            emptyMessage.visibility = View.VISIBLE
            return
        }

        listView.adapter = ArrayAdapter(
            this,
            android.R.layout.simple_list_item_1,
            counterparties.map { it.second },
        )
        listView.setOnItemClickListener { _, _, position, _ ->
            val (id, name) = counterparties[position]
            saveSelection(id, name)
            requestWidgetRefresh()
            finishWithResult()
        }
    }

    private fun readCounterparties(): List<Pair<String, String>> {
        val json = HomeWidgetPlugin.getData(this).getString("counterparties_json", null) ?: return emptyList()
        return try {
            val array = JSONArray(json)
            (0 until array.length()).map { i ->
                val entry = array.getJSONObject(i)
                Pair(entry.getString("id"), entry.getString("name"))
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun saveSelection(counterpartyId: String, counterpartyName: String) {
        val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(counterpartyIdKey(appWidgetId), counterpartyId)
            .putString(counterpartyNameKey(appWidgetId), counterpartyName)
            .apply()
    }

    private fun requestWidgetRefresh() {
        val appWidgetManager = AppWidgetManager.getInstance(this)
        QuickAddLedgerWidgetProvider().onUpdate(this, appWidgetManager, intArrayOf(appWidgetId))
    }

    private fun finishWithResult() {
        val resultValue = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, resultValue)
        finish()
    }
}
