#!/usr/bin/env bash
# Run inside the verify-quick-add CI job, against a real (emulated) Android
# device with the actual debug APK installed -- proves the SMS charge-review
# notification's "Quick add" action still reaches Dart, twice in a row,
# instead of inferring it from a source read. See build-apk.yml's own
# comment on this job for the two real bugs this exists to catch.
#
# A dedicated script file, not an inline `script:` block in the workflow --
# reactivecircus/android-emulator-runner runs each line of an inline script
# as its own independent shell invocation, so a variable assigned on one
# line (or a multi-line `if`) doesn't survive to the next one. A real
# script file, with `bash` doing the parsing exactly once, has none of that.
set -euo pipefail

PKG=com.yahiaelghayesh.wealth_tracker
RECEIVER=com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver
# Relative to the repo root -- this script is invoked from there (the
# emulator-runner action's `script:` doesn't inherit the workflow job's
# own `defaults.run.working-directory: wealth_tracker`), not from inside
# wealth_tracker/ itself.
APK=wealth_tracker/build/app/outputs/flutter-apk/app-debug.apk

# A real notification action's PendingIntent is fired by a system-
# privileged process (NotificationManagerService/SystemUI), not by an
# arbitrary shell process -- and this receiver is exported="false"
# (correctly; it's only ever meant to be reached that way). Sending the
# same broadcast from plain `adb shell` (UID shell, not system) may be
# getting silently blocked by that same exported check in a way the real
# tap never would be, which a previous run's total silence (not even the
# plugin's own "Callback information could not be retrieved" warning,
# which would appear if onReceive ran at all) is consistent with. `adb
# root` is available on this userdebug emulator image specifically to
# rule that out -- root bypasses the check entirely, same as system would.
adb root
adb wait-for-device

adb install -r "$APK"

echo "--- Launching the app once, so it registers the background notification-response callback handle ---"
adb shell am start -n "$PKG/$PKG.MainActivity"
sleep 15

echo "--- For reference, whatever dumpsys package shows about $RECEIVER (informational only -- the real pass/fail check is the broadcast below, since dumpsys' own output format for a receiver with no intent-filter has proven unreliable to grep) ---"
adb shell dumpsys package "$PKG" > package_dump.txt || true
grep -i "ActionBroadcastReceiver" package_dump.txt || echo "(not found in dumpsys output -- not necessarily conclusive, see above)"

# Deliberately NOT `am force-stop` here, even though the whole point of
# this action is to work while the app "isn't running" -- force-stop
# puts an app into Android's own stricter "stopped" state, which
# suppresses *all* broadcast delivery to it (even an explicit,
# manifest-registered, non-exported one) until it's launched again by
# the user. That's a much harsher state than the OS ever puts a
# backgrounded/LRU-killed app into on its own, and a previous run of
# this exact script proved it: zero evidence the broadcast was ever
# delivered at all after force-stopping, with the compiled manifest's
# <receiver> entry independently confirmed present via aapt2 in the
# same run. ActionBroadcastReceiver's own logic doesn't care whether
# the main app is alive anyway -- it always spins up its own separate
# headless engine -- so there's nothing this test actually needs
# force-stop for.
adb logcat -c

echo "--- First tap ---"
adb shell am broadcast -a "$RECEIVER.ACTION_TAPPED" -n "$PKG/$RECEIVER" \
  --ei notificationId 555 --es actionId quick_add --ez cancelNotification true --es payload test
# A previous run's own timestamps showed real, if slow, engine startup
# (this CI emulator is software-rendered and visibly sluggish -- "bad
# color buffer handle" GPU warnings throughout) -- 20s rather than 10 to
# rule out the second engine simply not having finished starting yet by
# the time logcat is read, rather than the actual caching bug being back.
sleep 20

echo "--- Second tap -- this is exactly what the engine-caching bug broke: the first tap worked, every one after silently did nothing ---"
adb shell am broadcast -a "$RECEIVER.ACTION_TAPPED" -n "$PKG/$RECEIVER" \
  --ei notificationId 556 --es actionId quick_add --ez cancelNotification true --es payload test
sleep 20

adb logcat -d > logcat.txt
echo "--- full logcat around ActionBroadcastReceiver/Flutter/crashes, unconditionally (not just on failure) ---"
grep -i "ActionBroadcastReceiver\|flutter\|AndroidRuntime\|FATAL EXCEPTION" logcat.txt || echo "(nothing matched at all)"

echo "--- matching logcat lines ---"
grep -i "notificationTapBackground\|Engine is already initialised\|Callback information could not be retrieved" logcat.txt || true

COUNT=$(grep -c "notificationTapBackground: actionId=quick_add" logcat.txt || true)
echo "notificationTapBackground invocation count: $COUNT (expected 2)"
if [ "$COUNT" -lt 2 ]; then
  echo "FAIL: Quick Add's native broadcast never reached the Dart callback both times -- the button does not work."
  exit 1
fi
if grep -q "Engine is already initialised" logcat.txt; then
  echo "FAIL: the engine-caching bug is back -- a tap after the first one is being silently dropped."
  exit 1
fi
echo "PASS: both Quick Add taps reached notificationTapBackground."
