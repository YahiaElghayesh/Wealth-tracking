#!/usr/bin/env bash
# Run inside the verify-quick-add CI job, against a real (emulated) Android
# device with the actual debug APK installed. Two scenarios, against the SMS
# charge-review notification real code paths can only be proven against a
# real device:
#   Part 1: a plain tap on the notification body ("Quick add" is no longer a
#     separate action button -- see showSmsChargeReviewNotification's own
#     doc comment for why: a real device reported the button silently
#     swallowing a tap during the notification's heads-up pop-up, working
#     only once it had settled into the shade a moment later; a body tap
#     doesn't have that failure mode), twice in a row, against a charge that
#     *resolves* to a known ledger -- checks the on-device database actually
#     gets the ledger entries it's supposed to, not just a debug log line.
#   Part 2: the same tap against a charge that CANNOT resolve a ledger --
#     resolveLedgerTarget's own "ask which ledger" case, and the actual
#     real-world scenario this whole notification exists for. Checks that
#     the first tap correctly reports nothing added and reposts a
#     notification (carrying `quickAddFailed: true` in its payload) rather
#     than silently doing nothing, and that tapping *that* repost opens a
#     real, on-screen "which ledger?" picker.
# See build-apk.yml's own comment on this job for the bugs each part exists
# to catch.
#
# A dedicated script file, not an inline `script:` block in the workflow --
# reactivecircus/android-emulator-runner runs each line of an inline script
# as its own independent shell invocation, so a variable assigned on one
# line (or a multi-line `if`) doesn't survive to the next one. A real
# script file, with `bash` doing the parsing exactly once, has none of that.
set -euo pipefail

PKG=com.yahiaelghayesh.wealth_tracker
# Both relative to the repo root -- this script is invoked from there (the
# emulator-runner action's `script:` doesn't inherit the workflow job's
# own `defaults.run.working-directory: wealth_tracker`), not from inside
# wealth_tracker/ itself.
APK=wealth_tracker/build/app/outputs/flutter-apk/app-debug.apk
SEED_DB=wealth_tracker/build/seed.sqlite

# Must match ci/build_seed_db_test.dart's own chargeSms/unresolvableChargeSms
# constants exactly -- a shell script can't import a Dart one, so keep
# these in sync by hand if either ever changes.
CHARGE_SMS='Card #4912 charged EGP 958.54 at Breadfast. Available limit EGP 85891.16.'
UNRESOLVABLE_SMS='Card #7777 charged EGP 120.00 at Uber. Available limit EGP 40000.00.'

# `adb root` (available on this userdebug emulator image) is needed only
# for pushing/pulling/chown-ing files under the app's own data directory
# below -- every tap in this script goes through the exact Intent
# flutter_local_notifications' own createNotification builds for a body
# tap (action SELECT_NOTIFICATION, `notificationId`/`payload` extras),
# fired via `am start` the same way SystemUI fires it for a real tap, no
# special privilege involved.
adb root
adb wait-for-device

adb install -r "$APK"

echo "--- Launching the app once, so it registers the notification-response callback, and so path_provider/drift create the app's real sqlite file ---"
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

echo "--- Pushing a database seeded with a resolvable and an unresolvable SmsRule ---"
adb push "$SEED_DB" "$DB_PATH"
adb shell "chown $OWNER '$DB_PATH'"

# force-stop puts an app into Android's own stricter "stopped" state, which
# suppresses broadcast/notification-action delivery to it until it's
# launched again -- exactly like the user opening it.
adb shell am start -n "$PKG/$PKG.MainActivity"
sleep 15

adb logcat -c

# A pushed script file, not `adb shell am start ... --es payload "$PAYLOAD"`
# directly -- the payload is real JSON containing spaces, '#', and embedded
# double quotes, and passing that through two layers of shell re-parsing
# (this script's own bash, then whatever adb shell does to marshal multiple
# arguments to the device's sh) is exactly the kind of thing that can
# silently truncate or mangle a value at a space or quote boundary, with no
# error anywhere. A script file pushed to the device and run with `sh`
# there is parsed exactly once, by exactly one shell, with the payload
# single-quoted (safe: the JSON itself never contains a single quote).
tap_body() {
  local id="$1" payload="$2" script="$3"
  cat > "$script" <<EOF
am start -n "$PKG/$PKG.MainActivity" -a "SELECT_NOTIFICATION" --ei notificationId $id --es payload '$payload'
EOF
  adb push "$script" "/data/local/tmp/$script"
  adb shell sh "/data/local/tmp/$script"
}

# --- Part 1: a plain body tap ("Quick add"), twice, on a resolvable charge

echo "=== Part 1: a plain notification-body tap, twice in a row, on a charge that resolves to a known ledger ==="

PAYLOAD_1="{\"body\":\"$CHARGE_SMS\",\"timestampMillis\":1000000}"
# A *different* timestamp, not just a different notification id -- reusing
# the same body+timestamp for both taps would hit commitSmsQuickAdd's own
# dedupe check (dedupeId = timestamp:body.hashCode) and the second tap
# would correctly report added=false despite everything working, which
# would look identical to the real bug this test exists to catch.
PAYLOAD_2="{\"body\":\"$CHARGE_SMS\",\"timestampMillis\":2000000}"

echo "--- First tap (real JSON payload, real charge SMS text, timestamp 1000000) ---"
tap_body 555 "$PAYLOAD_1" tap1.sh
# A previous run's own timestamps showed real, if slow, engine startup
# (this CI emulator is software-rendered and visibly sluggish -- "bad
# color buffer handle" GPU warnings throughout), and this tap now does
# real work (a real ledger insert) beyond just reaching the callback -- 20s
# to give all of that room to finish, not just the callback dispatch itself.
sleep 20

echo "--- Force-stopping for a cold start before the second tap ---"
adb shell am force-stop "$PKG"
adb shell am start -n "$PKG/$PKG.MainActivity"
sleep 15

echo "--- Second tap (same body, different timestamp -- second engine + dedupe both have to behave correctly) ---"
tap_body 556 "$PAYLOAD_2" tap2.sh
sleep 20

adb logcat -d > part1_logcat.txt
echo "--- entire logcat for Part 1 ---"
cat part1_logcat.txt

TAP_COUNT=$(grep -c "_onNotificationResponse: actionId=null" part1_logcat.txt || true)
echo "_onNotificationResponse invocation count: $TAP_COUNT (expected 2)"
if [ "$TAP_COUNT" -lt 2 ]; then
  echo "FAIL: a tap on the notification body never reached _onNotificationResponse both times -- the tap does not work."
  exit 1
fi

ADDED_COUNT=$(grep -c "commitSmsQuickAdd: could not resolve a ledger" part1_logcat.txt || true)
if [ "$ADDED_COUNT" -gt 0 ]; then
  echo "FAIL: commitSmsQuickAdd treated a resolvable charge as unresolvable -- seeded rule/vendor mapping regressed."
  exit 1
fi

echo "--- Pulling the on-device database to check the actual effect ---"
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
print(f"--- ledger_transactions rows for the seeded counterparty: {len(rows)} (expected exactly 2) ---")
for row in rows:
    print("  ", row)
if len(rows) < 2:
    print("FAIL: both taps reached _onNotificationResponse, but the on-device "
          "database doesn't actually contain both ledger entries.")
    sys.exit(1)
if len(rows) > 2:
    print("FAIL: more than 2 rows -- a tap is being double-committed (a real "
          "bug this exact check once let through with a '< 2' comparison: "
          "flutter_local_notifications' own delivery and MainActivity.kt's "
          "independent native fallback both firing for the same real tap, "
          "each calling commitSmsQuickAdd, produced 4 rows for 2 taps).")
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

echo "PASS: two taps on the notification body each actually committed a ledger entry."

# --- Part 2: the same tap against a charge that CANNOT resolve a ledger -

echo "=== Part 2: a notification-body tap on a charge with no resolvable ledger -- the original 'ask which ledger' request ==="

UNRESOLVABLE_TIMESTAMP=4000000
UNRESOLVABLE_PAYLOAD="{\"body\":\"$UNRESOLVABLE_SMS\",\"timestampMillis\":$UNRESOLVABLE_TIMESTAMP}"

echo "--- Force-stopping for a cold start before this scenario ---"
adb shell am force-stop "$PKG"
adb shell am start -n "$PKG/$PKG.MainActivity"
sleep 15
adb logcat -c

echo "--- Tapping the notification body for a charge with no resolvable ledger (no target, no vendor mapping) ---"
# Notification id matches what showSmsChargeReviewNotification actually
# uses (timestampMillis & 0x7fffffff) -- a mismatched id here previously
# let this test silently check the wrong log line for a nonexistent id
# while the real one used $UNRESOLVABLE_TIMESTAMP, without ever failing.
tap_body "$UNRESOLVABLE_TIMESTAMP" "$UNRESOLVABLE_PAYLOAD" tap3.sh
sleep 20

adb logcat -d > unresolvable_logcat.txt
echo "--- entire logcat for the unresolvable-charge tap ---"
cat unresolvable_logcat.txt

grep -q "_onNotificationResponse: actionId=null id=$UNRESOLVABLE_TIMESTAMP" unresolvable_logcat.txt || {
  echo "FAIL: the tap for the unresolvable charge never reached _onNotificationResponse."
  exit 1
}
grep -q "commitSmsQuickAdd: could not resolve a ledger, reposting review notification" unresolvable_logcat.txt || {
  echo "FAIL: commitSmsQuickAdd never even recognized this as an unresolvable charge -- it should have hit its needsLedgerSelection fallback."
  exit 1
}
grep -q "commitSmsQuickAdd: review notification reposted" unresolvable_logcat.txt || {
  echo "FAIL: commitSmsQuickAdd recognized the charge as unresolvable but never actually reposted a review notification -- this is the real 'tapping it does nothing' report."
  exit 1
}

echo "--- Force-stopping again for a cold start before tapping the reposted notification's body ---"
adb shell am force-stop "$PKG"
adb shell am start -n "$PKG/$PKG.MainActivity"
sleep 15
adb logcat -c

# showSmsChargeReviewNotification's own id is `timestampMillis & 0x7fffffff`
# -- 4000000 is already well under 2^31, so it's unchanged here. The
# repost carries the same body+timestampMillis, plus `quickAddFailed: true`
# -- what tells _onNotificationResponse to go to processIncomingSms this
# time instead of trying (and re-failing) commitSmsQuickAdd again.
UNRESOLVABLE_REPOST_PAYLOAD="{\"body\":\"$UNRESOLVABLE_SMS\",\"timestampMillis\":$UNRESOLVABLE_TIMESTAMP,\"quickAddFailed\":true}"
echo "--- Tapping the reposted notification's body on a cold app ---"
tap_body "$UNRESOLVABLE_TIMESTAMP" "$UNRESOLVABLE_REPOST_PAYLOAD" body_tap_unresolvable.sh
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

echo "PASS: a tap on an unresolvable charge's notification reposted a notification, and tapping that repost opened a real, on-screen 'which ledger?' picker."
