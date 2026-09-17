#!/usr/bin/env bash
# Run inside the verify-quick-add CI job, against a real (emulated) Android
# device with the actual debug APK installed. Three scenarios, all against
# the SMS charge-review notification real code paths can only be proven
# against a real device:
#   Part 1: the "Quick add" action, twice in a row, against a charge that
#     *resolves* to a known ledger -- checks the on-device database
#     actually gets the ledger entries it's supposed to, not just a debug
#     log line.
#   Part 2: a plain tap on the notification's body after a genuinely cold
#     start, for that same resolvable charge -- checks that SmsReviewScreen
#     actually opens on-screen, not just that a log line claims it was
#     pushed.
#   Part 3: Quick Add against a charge that CANNOT resolve a ledger --
#     resolveLedgerTarget's own "ask which ledger" case, and the actual
#     real-world scenario this whole notification exists for. Parts 1/2
#     only ever exercise a resolvable charge, which is a materially
#     different code path (commitSmsQuickAdd applies it directly and never
#     touches its own `needsLedgerSelection` fallback at all) -- passing
#     there proves nothing about whether Quick Add correctly reposts a
#     review notification for an unresolvable one, or whether tapping that
#     repost actually opens a working "which ledger?" picker. This checks
#     both, end to end, on-screen.
# See build-apk.yml's own comment on this job for the bugs each part
# exists to catch, including the one an earlier version of Part 1 missed:
# a fake, non-JSON payload proved the broadcast reaches Dart but never
# exercised _commitQuickAddFromBackground's own database/prefs/secure-
# storage setup at all, so it passed while Quick Add still didn't work.
#
# A dedicated script file, not an inline `script:` block in the workflow --
# reactivecircus/android-emulator-runner runs each line of an inline script
# as its own independent shell invocation, so a variable assigned on one
# line (or a multi-line `if`) doesn't survive to the next one. A real
# script file, with `bash` doing the parsing exactly once, has none of that.
set -euo pipefail

PKG=com.yahiaelghayesh.wealth_tracker
RECEIVER=com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver
# Both relative to the repo root -- this script is invoked from there (the
# emulator-runner action's `script:` doesn't inherit the workflow job's
# own `defaults.run.working-directory: wealth_tracker`), not from inside
# wealth_tracker/ itself.
APK=wealth_tracker/build/app/outputs/flutter-apk/app-debug.apk
SEED_DB=wealth_tracker/build/seed.sqlite

# Must match ci/build_seed_db_test.dart's own chargeSms constant exactly --
# a shell script can't import a Dart one, so keep the two in sync by hand.
CHARGE_SMS='Card #4912 charged EGP 958.54 at Breadfast. Available limit EGP 85891.16.'
PAYLOAD_1="{\"body\":\"$CHARGE_SMS\",\"timestampMillis\":1000000}"
# A *different* timestamp, not just a different notification id -- reusing
# the same body+timestamp for both taps would hit commitSmsQuickAdd's own
# dedupe check (dedupeId = timestamp:body.hashCode) and the second tap
# would correctly report added=false despite everything working, which
# would look identical to the real bug this test exists to catch.
PAYLOAD_2="{\"body\":\"$CHARGE_SMS\",\"timestampMillis\":2000000}"

# A real notification action's PendingIntent is fired by a system-
# privileged process (NotificationManagerService/SystemUI), not by an
# arbitrary shell process -- and this receiver is exported="false"
# (correctly; it's only ever meant to be reached that way). Sending the
# same broadcast from plain `adb shell` (UID shell, not system) may be
# getting silently blocked by that same exported check in a way the real
# tap never would be. `adb root` (available on this userdebug emulator
# image) bypasses the check entirely, same as system would -- also what
# lets this script push/pull files under the app's own data directory
# below without needing `run-as`.
adb root
adb wait-for-device

adb install -r "$APK"

echo "--- Launching the app once, so it registers the background notification-response callback handle, and so path_provider/drift create the app's real sqlite file ---"
adb shell am start -n "$PKG/$PKG.MainActivity"
sleep 15

echo "--- Locating the app's real sqlite file on-device (its exact directory is a path_provider implementation detail, not something to hard-code) ---"
DB_PATH=$(adb shell "find /data/data/$PKG -name 'wealth_tracker.sqlite' 2>/dev/null" | tr -d '\r')
if [ -z "$DB_PATH" ]; then
  echo "FAIL: wealth_tracker.sqlite not found anywhere under /data/data/$PKG after the app's first launch."
  exit 1
fi
echo "Found: $DB_PATH"

echo "--- Recording the app's own uid:gid on that file, before touching anything -- pushed as root, the replacement would otherwise land owned by root:root, which the app's own (unprivileged) process can't open ---"
OWNER=$(adb shell "stat -c '%u:%g' '$DB_PATH'" | tr -d '\r')
echo "App owns its database as: $OWNER"

echo "--- Stopping the app so its own database connection is fully closed before this test overwrites the file under it ---"
adb shell am force-stop "$PKG"
# Also remove any WAL/shm sidecars from that first launch -- overwriting
# just the main file while a stale -wal exists from the *old* (empty)
# database would let sqlite replay old-file WAL frames on top of the
# newly-pushed one.
adb shell "rm -f '$DB_PATH-wal' '$DB_PATH-shm'"

echo "--- Pushing a database seeded with one real SmsRule that matches CHARGE_SMS, so a real Quick Add tap has something to actually commit ---"
adb push "$SEED_DB" "$DB_PATH"
adb shell "chown $OWNER '$DB_PATH'"

# force-stop puts an app into Android's own stricter "stopped" state,
# which suppresses *all* broadcast delivery to it (even an explicit,
# manifest-registered, non-exported one) until it's launched again --
# exactly like the user opening it. Without this, every broadcast below
# would silently go nowhere for a reason that has nothing to do with
# Quick Add itself.
adb shell am start -n "$PKG/$PKG.MainActivity"
sleep 15

adb logcat -c

# A pushed script file, not `adb shell am broadcast ... --es payload
# "$PAYLOAD"` directly -- the payload is real JSON containing spaces, '#',
# and embedded double quotes, and passing that through two layers of
# shell re-parsing (this script's own bash, then whatever adb shell does
# to marshal multiple arguments to the device's sh) is exactly the kind
# of thing that can silently truncate or mangle a value at a space or
# quote boundary, with no error anywhere -- the app would just see
# whatever fragment survived, fail to decode it as JSON, and (by design,
# see app.dart's own now-instrumented jsonDecode catch block) return
# having printed nothing at all, indistinguishable from every earlier
# engine-plumbing bug this test also had to rule out. A script file
# pushed to the device and run with `sh` there is parsed exactly once,
# by exactly one shell, with the payload single-quoted (safe: the JSON
# itself never contains a single quote) -- same reasoning as this whole
# script being a real file instead of an inline `script:` block.
tap() {
  local id="$1" payload="$2" script="$3"
  cat > "$script" <<EOF
am broadcast -a "$RECEIVER.ACTION_TAPPED" -n "$PKG/$RECEIVER" --ei notificationId $id --es actionId quick_add --ez cancelNotification true --es payload '$payload'
EOF
  adb push "$script" "/data/local/tmp/$script"
  adb shell sh "/data/local/tmp/$script"
}

echo "--- First tap (real JSON payload, real charge SMS text, timestamp 1000000) ---"
tap 555 "$PAYLOAD_1" tap1.sh
# A previous run's own timestamps showed real, if slow, engine startup
# (this CI emulator is software-rendered and visibly sluggish -- "bad
# color buffer handle" GPU warnings throughout), and this tap now does
# real work (AppDatabase, SharedPreferences, SecureSettingsStore, a real
# ledger insert) beyond just reaching the callback -- 20s to give all of
# that room to finish, not just the callback dispatch itself.
sleep 20

echo "--- Second tap (same body, different timestamp -- second engine + dedupe both have to behave correctly) ---"
tap 556 "$PAYLOAD_2" tap2.sh
sleep 20

echo "--- process status for $PKG right after the second tap (is it even still alive?) ---"
adb shell "ps -A | grep wealth_tracker" || echo "(no matching process -- it's not running at all)"

adb logcat -d > logcat.txt
echo "--- entire logcat, unconditionally (not just a filtered grep) ---"
cat logcat.txt

echo "--- matching logcat lines (for quick scanning above the full dump) ---"
grep -i "notificationTapBackground\|Engine is already initialised\|Callback information could not be retrieved\|ActionBroadcastReceiver\|AndroidRuntime\|FATAL EXCEPTION\|Unhandled exception\|threw:\|Killed\|lowmemorykiller\|ANR in" logcat.txt || true

TAP_COUNT=$(grep -c "notificationTapBackground: actionId=quick_add" logcat.txt || true)
echo "notificationTapBackground invocation count: $TAP_COUNT (expected 2)"
if [ "$TAP_COUNT" -lt 2 ]; then
  echo "FAIL: Quick Add's native broadcast never reached the Dart callback both times -- the button does not work."
  exit 1
fi
if grep -q "Engine is already initialised" logcat.txt; then
  echo "FAIL: the engine-caching bug is back -- a tap after the first one is being silently dropped."
  exit 1
fi

ADDED_COUNT=$(grep -c "notificationTapBackground: commitSmsQuickAdd added=true" logcat.txt || true)
echo "commitSmsQuickAdd added=true count: $ADDED_COUNT (expected 2)"
if [ "$ADDED_COUNT" -lt 2 ]; then
  echo "FAIL: the broadcast reached Dart, but commitSmsQuickAdd never reported success both times -- Quick Add's own effect (a ledger entry) isn't happening, even though the plumbing that delivers the tap works. This is exactly the gap a fake non-JSON payload used to hide."
  exit 1
fi

echo "--- Pulling the on-device database (plus any WAL sidecar) to check the *actual* effect, not just a log line ---"
adb pull "$DB_PATH" pulled.sqlite
adb pull "$DB_PATH-wal" pulled.sqlite-wal 2>/dev/null || true
adb pull "$DB_PATH-shm" pulled.sqlite-shm 2>/dev/null || true

python3 - <<'PYEOF'
import sqlite3, sys
conn = sqlite3.connect("pulled.sqlite")
cur = conn.cursor()
cur.execute(
    "SELECT counterparty_id, amount, currency, category, source "
    "FROM ledger_transactions WHERE counterparty_id = 'ci-seed-counterparty' "
    "ORDER BY date"
)
rows = cur.fetchall()
print(f"--- ledger_transactions rows for the seeded counterparty: {len(rows)} (expected 2) ---")
for row in rows:
    print("  ", row)
if len(rows) < 2:
    print("FAIL: Quick Add reported success in its own log line, but the on-device "
          "database doesn't actually contain both ledger entries.")
    sys.exit(1)
for row in rows:
    counterparty_id, amount, currency, category, source = row
    if counterparty_id != "ci-seed-counterparty" or currency != "EGP" or category != "Breadfast" or source != "sms":
        print(f"FAIL: a ledger row exists but doesn't match what commitSmsQuickAdd should have written: {row}")
        sys.exit(1)
    if abs(amount - 85891.16) > 0.001:
        print(f"FAIL: ledger row amount {amount} doesn't match the seeded rule's expected 85891.16")
        sys.exit(1)
print("PASS: both ledger entries exist on-device with the expected data.")
PYEOF

echo "PASS: both Quick Add taps reached notificationTapBackground and each actually committed a ledger entry."

# --- Part 2: a plain tap on the notification's BODY (not the Quick Add
# action), after a genuinely cold start -- the separate bug reported as
# "it opens, sometimes to the last page, but never shows a picker".
# flutter_local_notifications launches this exact Intent
# (FlutterLocalNotificationsPlugin.java's own createNotification) when a
# notification body is tapped: the app's own launch Intent, action
# SELECT_NOTIFICATION, with `notificationId`/`payload` extras -- simulated
# directly here rather than via ActionBroadcastReceiver (that receiver is
# only ever used for an AndroidNotificationAction, never a plain body tap).
echo "--- Force-stopping the app again for a genuinely cold start (the real scenario processIncomingSms's Navigator race was lost in) ---"
adb shell am force-stop "$PKG"
adb logcat -c

BODY_TAP_PAYLOAD="{\"body\":\"$CHARGE_SMS\",\"timestampMillis\":3000000}"
cat > body_tap.sh <<EOF
am start -n "$PKG/$PKG.MainActivity" -a "SELECT_NOTIFICATION" --ei notificationId 999 --es payload '$BODY_TAP_PAYLOAD'
EOF
adb push body_tap.sh /data/local/tmp/body_tap.sh
echo "--- Tapping the notification body on a cold (just force-stopped) app ---"
adb shell sh /data/local/tmp/body_tap.sh
# Generous: a genuinely cold Flutter engine start on this emulator (already
# observed to be slow/software-rendered) plus up to 5s of processIncomingSms's
# own _awaitNavigator wait plus the screen's own build.
sleep 25

adb logcat -d > body_tap_logcat.txt
echo "--- entire logcat for the body-tap scenario ---"
cat body_tap_logcat.txt

grep -q "_onNotificationResponse: actionId=null id=999" body_tap_logcat.txt || {
  echo "FAIL: the cold-start SELECT_NOTIFICATION intent never reached _onNotificationResponse at all."
  exit 1
}
grep -q "processIncomingSms: reviewable match found, awaiting navigator" body_tap_logcat.txt || {
  echo "FAIL: processIncomingSms didn't even find a reviewable match for the tapped charge."
  exit 1
}
if grep -q "processIncomingSms: navigator never became available" body_tap_logcat.txt; then
  echo "FAIL: processIncomingSms lost the cold-start Navigator race even with the widened wait -- the exact bug this is supposed to catch."
  exit 1
fi
grep -q "processIncomingSms: navigator ready, pushing SmsReviewScreen" body_tap_logcat.txt || {
  echo "FAIL: processIncomingSms never reached the point of actually pushing SmsReviewScreen."
  exit 1
}

echo "--- Confirming the actual on-screen UI, not just the log line that claims to have pushed it ---"
adb shell uiautomator dump /sdcard/window_dump.xml
adb pull /sdcard/window_dump.xml window_dump.xml
if ! grep -q "Confirm payment" window_dump.xml; then
  echo "FAIL: SmsReviewScreen's own log line printed, but its AppBar title 'Confirm payment' never actually appeared on screen."
  cat window_dump.xml
  exit 1
fi

echo "PASS: a cold-started tap on the notification body opened SmsReviewScreen for real, on-screen."

# --- Part 3: Quick Add against a charge resolveLedgerTarget can't resolve
# -- must match ci/build_seed_db_test.dart's own unresolvableChargeSms
# constant exactly.
UNRESOLVABLE_SMS='Card #7777 charged EGP 120.00 at Uber. Available limit EGP 40000.00.'
UNRESOLVABLE_TIMESTAMP=4000000
UNRESOLVABLE_PAYLOAD="{\"body\":\"$UNRESOLVABLE_SMS\",\"timestampMillis\":$UNRESOLVABLE_TIMESTAMP}"

echo "--- Relaunching the app (Part 2 left it force-stopped) before firing Quick Add again ---"
adb shell am start -n "$PKG/$PKG.MainActivity"
sleep 15
adb logcat -c

echo "--- Quick Add on a charge with no resolvable ledger (no target, no vendor mapping) ---"
tap 777 "$UNRESOLVABLE_PAYLOAD" tap3.sh
sleep 20

adb logcat -d > unresolvable_logcat.txt
echo "--- entire logcat for the unresolvable-charge Quick Add tap ---"
cat unresolvable_logcat.txt

grep -q "notificationTapBackground: actionId=quick_add id=777" unresolvable_logcat.txt || {
  echo "FAIL: the Quick Add broadcast for the unresolvable charge never reached notificationTapBackground."
  exit 1
}
grep -q "commitSmsQuickAdd: could not resolve a ledger, reposting review notification" unresolvable_logcat.txt || {
  echo "FAIL: commitSmsQuickAdd never even recognized this as an unresolvable charge -- it should have hit its needsLedgerSelection fallback."
  exit 1
}
grep -q "commitSmsQuickAdd: review notification reposted" unresolvable_logcat.txt || {
  echo "FAIL: commitSmsQuickAdd recognized the charge as unresolvable but never actually reposted a review notification -- this is the real Quick Add 'does nothing' report."
  exit 1
}
grep -q "notificationTapBackground: commitSmsQuickAdd added=false" unresolvable_logcat.txt || {
  echo "FAIL: expected commitSmsQuickAdd to report added=false for an unresolvable charge (it should never silently add one)."
  exit 1
}

echo "--- Force-stopping again for a cold start before tapping the reposted notification's body ---"
adb shell am force-stop "$PKG"
adb logcat -c

# showSmsChargeReviewNotification's own id is `timestampMillis & 0x7fffffff`
# -- 4000000 is already well under 2^31, so it's unchanged here. Same
# body+timestampMillis payload commitSmsQuickAdd's fallback reposted with.
cat > body_tap_unresolvable.sh <<EOF
am start -n "$PKG/$PKG.MainActivity" -a "SELECT_NOTIFICATION" --ei notificationId $UNRESOLVABLE_TIMESTAMP --es payload '$UNRESOLVABLE_PAYLOAD'
EOF
adb push body_tap_unresolvable.sh /data/local/tmp/body_tap_unresolvable.sh
echo "--- Tapping the reposted (no Quick Add button) notification's body on a cold app ---"
adb shell sh /data/local/tmp/body_tap_unresolvable.sh
sleep 25

adb logcat -d > unresolvable_body_tap_logcat.txt
echo "--- entire logcat for tapping the unresolvable charge's reposted notification ---"
cat unresolvable_body_tap_logcat.txt

grep -q "_onNotificationResponse: actionId=null id=$UNRESOLVABLE_TIMESTAMP" unresolvable_body_tap_logcat.txt || {
  echo "FAIL: tapping the reposted notification's body never reached _onNotificationResponse."
  exit 1
}
grep -q "processIncomingSms: reviewable match found, awaiting navigator" unresolvable_body_tap_logcat.txt || {
  echo "FAIL: processIncomingSms didn't find the unresolvable charge reviewable a second time."
  exit 1
}
if grep -q "processIncomingSms: navigator never became available" unresolvable_body_tap_logcat.txt; then
  echo "FAIL: lost the cold-start Navigator race for the unresolvable charge's own review screen."
  exit 1
fi
grep -q "processIncomingSms: navigator ready, pushing SmsReviewScreen" unresolvable_body_tap_logcat.txt || {
  echo "FAIL: never reached the point of pushing SmsReviewScreen for the unresolvable charge."
  exit 1
}

echo "--- Confirming the actual 'which ledger?' picker is on screen, not just a log line ---"
adb shell uiautomator dump /sdcard/window_dump_unresolvable.xml
adb pull /sdcard/window_dump_unresolvable.xml window_dump_unresolvable.xml
if ! grep -q "Confirm payment" window_dump_unresolvable.xml; then
  echo "FAIL: SmsReviewScreen never actually opened for the unresolvable charge."
  cat window_dump_unresolvable.xml
  exit 1
fi
if ! grep -q "Add to which ledger?" window_dump_unresolvable.xml; then
  echo "FAIL: SmsReviewScreen opened, but its ledger-picker prompt ('Add to which ledger?') isn't on screen -- exactly what was reported as missing."
  cat window_dump_unresolvable.xml
  exit 1
fi

echo "PASS: Quick Add on an unresolvable charge reposted a notification, and tapping it opened a real, on-screen 'which ledger?' picker."
