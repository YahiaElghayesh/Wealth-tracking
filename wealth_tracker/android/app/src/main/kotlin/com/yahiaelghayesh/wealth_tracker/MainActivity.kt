package com.yahiaelghayesh.wealth_tracker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // home_widget's click detection reads the launch Intent both from the
    // "was I cold-started by a widget tap" check (activity.intent, i.e.
    // getIntent()) and from onNewIntent for a warm tap while the app is
    // already running. Activity.onNewIntent does NOT update getIntent() on
    // its own — without this override, a warm tap on the "Add Payment"
    // widget just brings the app to the foreground on whatever screen was
    // already showing instead of opening the add-payment form.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
