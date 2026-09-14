package com.dexterous.flutterlocalnotifications;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.Keep;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import androidx.core.app.NotificationManagerCompat;

import com.dexterous.flutterlocalnotifications.isolate.IsolatePreferences;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterCallbackInformation;

public class ActionBroadcastReceiver extends BroadcastReceiver {
  public static final String ACTION_TAPPED =
      "com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver.ACTION_TAPPED";
  public static final String ACTION_DISMISSED =
      "com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver.ACTION_DISMISSED";
  public static final String DISMISS_ISOLATE = "dismissIsolate";
  private static final int DISMISS_ISOLATE_MAIN = 0;
  private static final int DISMISS_ISOLATE_BACKGROUND = 1;
  private static final String TAG = "ActionBroadcastReceiver";
  @Nullable private static ActionEventSink actionEventSink;
  @Nullable private static FlutterEngine engine;
  IsolatePreferences preferences;

  @VisibleForTesting
  ActionBroadcastReceiver(IsolatePreferences preferences) {
    this.preferences = preferences;
  }

  @Keep
  public ActionBroadcastReceiver() {}

  @Override
  public void onReceive(Context context, Intent intent) {
    if (!ACTION_TAPPED.equalsIgnoreCase(intent.getAction())
        && !ACTION_DISMISSED.equalsIgnoreCase(intent.getAction())) {
      return;
    }

    final Map<String, Object> action =
        FlutterLocalNotificationsPlugin.extractNotificationResponseMap(intent);

    // A main-isolate dismissal is only delivered while the app is running.
    if (ACTION_DISMISSED.equalsIgnoreCase(intent.getAction())
        && intent.getIntExtra(DISMISS_ISOLATE, DISMISS_ISOLATE_BACKGROUND)
            == DISMISS_ISOLATE_MAIN) {
      MethodChannel liveChannel = FlutterLocalNotificationsPlugin.liveChannel;
      if (liveChannel != null) {
        liveChannel.invokeMethod("didReceiveNotificationResponse", action);
      }
      return;
    }

    preferences = preferences == null ? new IsolatePreferences(context) : preferences;

    if (intent.getBooleanExtra(FlutterLocalNotificationsPlugin.CANCEL_NOTIFICATION, false)) {
      int notificationId = (int) action.get(FlutterLocalNotificationsPlugin.NOTIFICATION_ID);
      Object tag = action.get(FlutterLocalNotificationsPlugin.NOTIFICATION_TAG);

      if (tag instanceof String) {
        NotificationManagerCompat.from(context).cancel((String) tag, notificationId);
      } else {
        NotificationManagerCompat.from(context).cancel(notificationId);
      }
    }

    // Money Hub patch, part 2: destroy any leftover engine from a
    // previous tap *before* queuing this tap's item into actionEventSink,
    // not after. actionEventSink.eventSink is a raw platform-channel
    // EventSink bound to whichever engine last called back's
    // EventChannel#receiveBroadcastStream -- destroying an engine never
    // invokes that stream's onCancel (destroy() tears the whole engine
    // down at once, it doesn't gracefully notify each channel), so that
    // field is left pointing at a dead, disconnected sink. If item#2 is
    // added while it's still set, addItem() below takes the "sink != null"
    // branch and fires straight into that dead sink -- never into `cache`
    // -- so when the *new* engine's callbackDispatcher() finishes its own
    // getCallbackHandle round-trip and calls .listen() a moment later,
    // there's nothing left in `cache` to replay. The new engine ends up
    // fully alive, with a real, correctly-attached stream listener, that
    // never receives the very item this tap was for: no crash, no
    // timeout, just a second engine sitting there forever waiting on data
    // that already went into the void. Resetting eventSink to null here,
    // before addItem() runs, routes this tap's item into `cache` instead,
    // where the new engine's own onListen() picks it up once it attaches.
    if (engine != null) {
      engine.destroy();
      engine = null;
      if (actionEventSink != null) {
        actionEventSink.eventSink = null;
      }
    }

    if (actionEventSink == null) {
      actionEventSink = new ActionEventSink();
    }
    actionEventSink.addItem(action);

    startEngine(context);
  }

  private void startEngine(Context context) {
    FlutterInjector injector = FlutterInjector.instance();
    FlutterLoader loader = injector.flutterLoader();

    loader.startInitialization(context);
    loader.ensureInitializationComplete(context, null);

    engine = new FlutterEngine(context);

    /// This lookup needs to be done after creating an instance of `FlutterEngine` or lookup may
    // fail
    FlutterCallbackInformation dispatcherHandle = preferences.lookupDispatcherHandle();
    if (dispatcherHandle == null) {
      Log.w(TAG, "Callback information could not be retrieved");
      return;
    }

    DartExecutor dartExecutor = engine.getDartExecutor();

    initializeEventChannel(dartExecutor);

    String dartBundlePath = loader.findAppBundlePath();
    dartExecutor.executeDartCallback(
        new DartExecutor.DartCallback(context.getAssets(), dartBundlePath, dispatcherHandle));
  }

  private void initializeEventChannel(DartExecutor dartExecutor) {
    EventChannel channel =
        new EventChannel(
            dartExecutor.getBinaryMessenger(), "dexterous.com/flutter/local_notifications/actions");
    channel.setStreamHandler(actionEventSink);
  }

  private static class ActionEventSink implements StreamHandler {

    final List<Map<String, Object>> cache = new ArrayList<>();

    @Nullable private EventSink eventSink;

    public void addItem(Map<String, Object> item) {
      if (eventSink != null) {
        eventSink.success(item);
      } else {
        cache.add(item);
      }
    }

    @Override
    public void onListen(Object arguments, EventSink events) {
      for (Map<String, Object> item : cache) {
        events.success(item);
      }

      cache.clear();
      eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
      eventSink = null;
    }
  }
}
