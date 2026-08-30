package com.yahiaelghayesh.wealth_tracker

/**
 * The mockup's "Net Worth · compact" size, as a distinct pickable entry in
 * the launcher's widget picker rather than something the user finds by
 * resizing the standard one -- a resizable widget's picker preview only
 * ever shows one size, so anyone who didn't already know it could shrink
 * would never see the compact layout as an option. Genuinely identical
 * behavior to [NetWorthWidgetProvider] (same render logic, same reveal/
 * re-hide handling — plain inheritance, nothing overridden here); only the
 * default/allowed size range differs, via net_worth_compact_widget_info.xml
 * and its own manifest `<receiver>` entry.
 */
class NetWorthCompactWidgetProvider : NetWorthWidgetProvider()
