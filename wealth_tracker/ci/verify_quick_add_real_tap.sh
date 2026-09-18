#!/usr/bin/env bash
# Run inside the verify-quick-add CI job, against a real (emulated) Android
# device with the actual debug APK installed.
#
# Every earlier version of this script proved the Dart code behind Quick Add
# and the notification tap is correct by hand-constructing the underlying
# Android Intent/broadcast a real tap is *supposed* to send, then firing it
# directly via `adb shell am broadcast`/`am start`. That reliably caught
# every bug in the code that runs *after* such an Intent arrives -- but it
# never once verified that a real incoming SMS actually produces a real,
# on-screen notification with a real, tappable "Quick add" button, or that
# tapping that actual rendered UI (with a real finger, or a real screen tap
# here) is what sends that Intent in the first place. A bug in how the
# notification/action itself gets constructed -- a wrong PendingIntent flag,
# a channel importance too low for the action to render, anything in that
# construction path -- would pass every previous version of this test and
# still fail for a real user, which is exactly what kept happening after
# three separate rounds of that style of test all reporting success.
#
# This version instead: injects a real SMS into the emulator (`adb emu sms
# send`, which triggers the exact same Telephony.Sms.Intents.SMS_RECEIVED_
# ACTION broadcast a real bank text does), waits for the real notification
# it produces, dumps the real on-screen UI via uiautomator, locates the
# real "Quick add" button (or the notification body) by its exact visible
# text, and taps those exact screen coordinates with `adb shell input tap`
# -- the same primitive a real finger tap resolves to. Three scenarios:
#   Part 1: a charge that RESOLVES to a known ledger, tapped twice in a row
#     (two separate real SMS) -- checks the on-device database actually
#     gets both ledger entries.
#   Part 2: a plain tap on that same kind of notification's body, after a
#     genuinely cold start -- checks SmsReviewScreen actually opens
#     on-screen.
#   Part 3: a charge that CANNOT resolve a ledger -- resolveLedgerTarget's
#     own "ask which ledger" case, and the original, real-world request
#     this notification exists for. Taps its real "Quick add" button,
#     confirms it correctly reports nothing added and reposts a
#     notification instead, then taps *that* notification's body (cold
#     start again) and confirms the real "which ledger?" picker is on
#     screen.
# See build-apk.yml's own comment on this job for the native-layer bugs an
# earlier, non-UI-driven version of Part 1 alone already caught.
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
# below -- every tap in this script goes through the same `adb shell input
# tap`/`uiautomator` primitives a real finger uses, no special privilege
# involved.
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

# --- Helpers -----------------------------------------------------------

# Dumps the real on-screen UI hierarchy (including the notification shade,
# once expanded) to a local file, so a tap's exact target coordinates can
# be found the same way a human would find them: by what's actually
# visible.
dump_ui() {
  local out="$1"
  adb shell uiautomator dump /sdcard/dump.xml > /dev/null
  adb pull /sdcard/dump.xml "$out" > /dev/null
}

# Prints "$x $y" for the first node whose exact visible text or
# content-desc equals $2 in the dump at $1, or fails loudly with the full
# dump printed (so a mismatch is immediately diagnosable) if nothing
# matches. Exact match, not substring -- the notification body text here
# literally contains the phrase "Quick add" inside a sentence, so a naive
# substring search finds the wrong node entirely.
find_tap_coords() {
  local dump="$1" needle="$2"
  python3 - "$dump" "$needle" <<'PYEOF'
import re, sys
dump_path, needle = sys.argv[1], sys.argv[2]
with open(dump_path, encoding="utf-8", errors="replace") as f:
    content = f.read()
for m in re.finditer(r"<node[^>]*/?>", content):
    node = m.group(0)
    text_m = re.search(r'text="([^"]*)"', node)
    desc_m = re.search(r'content-desc="([^"]*)"', node)
    text = (text_m.group(1) if text_m else "").strip()
    desc = (desc_m.group(1) if desc_m else "").strip()
    if text == needle or desc == needle:
        b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', node)
        if b:
            x1, y1, x2, y2 = map(int, b.groups())
            print(f"{(x1 + x2) // 2} {(y1 + y2) // 2}")
            sys.exit(0)
sys.exit(1)
PYEOF
}

# Expands the notification shade, dumps the UI, and taps the exact screen
# coordinates of the node whose visible text is $1 -- failing loudly (full
# dump printed) if it isn't found, rather than tapping the wrong thing.
tap_notification_text() {
  local needle="$1" dump="dump_$(date +%s%N).xml"
  adb shell cmd statusbar expand-notifications
  sleep 2
  dump_ui "$dump"
  local coords
  if ! coords=$(find_tap_coords "$dump" "$needle"); then
    echo "FAIL: could not find on-screen node with exact text '$needle' to tap."
    echo "--- full UI dump ---"
    cat "$dump"
    exit 1
  fi
  echo "Tapping '$needle' at coordinates: $coords"
  adb shell input tap $coords
}

# Injects a real SMS into the emulator -- the exact same
# Telephony.Sms.Intents.SMS_RECEIVED_ACTION broadcast a real bank text
# produces, triggering the app's real SmsReceiver -> WorkManager ->
# commitSmsAutoDetect -> showSmsChargeReviewNotification chain end to end,
# not a hand-constructed shortcut into the middle of it.
send_real_sms() {
  local body="$1"
  adb emu sms send TestBank "$body"
  # Generous: WorkManager scheduling + a real (if expedited) background
  # engine spin-up, on an emulator already observed to be slow/
  # software-rendered, before the notification actually posts.
  sleep 20
}

# --- Part 1: Quick Add, twice in a row, on a charge that resolves -------

echo "=== Part 1: Quick Add on a real, resolvable charge notification, twice in a row ==="

echo "--- Sending real SMS #1 ---"
send_real_sms "$CHARGE_SMS"
tap_notification_text "Quick add"
sleep 15

echo "--- Sending real SMS #2 (same text -- a real device timestamp still makes each dedupeId distinct) ---"
send_real_sms "$CHARGE_SMS"
tap_notification_text "Quick add"
sleep 15

adb logcat -d > part1_logcat.txt
echo "--- entire logcat for Part 1 ---"
cat part1_logcat.txt

TAP_COUNT=$(grep -c "notificationTapBackground: actionId=quick_add" part1_logcat.txt || true)
echo "notificationTapBackground invocation count: $TAP_COUNT (expected 2)"
if [ "$TAP_COUNT" -lt 2 ]; then
  echo "FAIL: a real tap on the real 'Quick add' button never reached notificationTapBackground both times -- the button does not work."
  exit 1
fi
if grep -q "Engine is already initialised" part1_logcat.txt; then
  echo "FAIL: the engine-caching bug is back -- a tap after the first one is being silently dropped."
  exit 1
fi

ADDED_COUNT=$(grep -c "notificationTapBackground: commitSmsQuickAdd added=true" part1_logcat.txt || true)
echo "commitSmsQuickAdd added=true count: $ADDED_COUNT (expected 2)"
if [ "$ADDED_COUNT" -lt 2 ]; then
  echo "FAIL: the tap reached Dart, but commitSmsQuickAdd never reported success both times."
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

echo "PASS: two real taps on the real Quick Add button each actually committed a ledger entry."

# --- Part 2: a real tap on the notification BODY, after a cold start ----

echo "=== Part 2: a real tap on the notification body, after a genuinely cold start ==="

echo "--- Force-stopping the app for a genuinely cold start ---"
adb shell am force-stop "$PKG"
adb logcat -c

echo "--- Sending a fresh real SMS while the app is stopped (mirrors a bank text arriving while the app isn't running) ---"
send_real_sms "$CHARGE_SMS"

tap_notification_text "Charge detected: Breadfast"
# Generous: a genuinely cold Flutter engine start on this emulator plus up
# to 5s of processIncomingSms's own _awaitNavigator wait plus the screen's
# own build.
sleep 20

adb logcat -d > part2_logcat.txt
echo "--- entire logcat for Part 2 ---"
cat part2_logcat.txt

grep -q "_onNotificationResponse: actionId=null" part2_logcat.txt || {
  echo "FAIL: the real tap on the notification body never reached _onNotificationResponse at all."
  exit 1
}
grep -q "processIncomingSms: reviewable match found, awaiting navigator" part2_logcat.txt || {
  echo "FAIL: processIncomingSms didn't even find a reviewable match for the tapped charge."
  exit 1
}
if grep -q "processIncomingSms: navigator never became available" part2_logcat.txt; then
  echo "FAIL: processIncomingSms lost the cold-start Navigator race."
  exit 1
fi
grep -q "processIncomingSms: navigator ready, pushing SmsReviewScreen" part2_logcat.txt || {
  echo "FAIL: processIncomingSms never reached the point of actually pushing SmsReviewScreen."
  exit 1
}

echo "--- Confirming the actual on-screen UI, not just the log line that claims to have pushed it ---"
dump_ui window_dump.xml
if ! grep -q "Confirm payment" window_dump.xml; then
  echo "FAIL: SmsReviewScreen's own log line printed, but its AppBar title 'Confirm payment' never actually appeared on screen."
  cat window_dump.xml
  exit 1
fi

echo "PASS: a real tap on the notification body, after a cold start, opened SmsReviewScreen for real, on-screen."

# --- Part 3: Quick Add on a charge that CANNOT resolve a ledger ---------

echo "=== Part 3: Quick Add on a real charge with no resolvable ledger -- the original 'ask which ledger' request ==="

echo "--- Relaunching the app (Part 2 left it force-stopped) ---"
adb shell am start -n "$PKG/$PKG.MainActivity"
sleep 15
adb logcat -c

echo "--- Sending the real, unresolvable-charge SMS ---"
send_real_sms "$UNRESOLVABLE_SMS"
tap_notification_text "Quick add"
sleep 15

adb logcat -d > part3_logcat.txt
echo "--- entire logcat for tapping Quick Add on the unresolvable charge ---"
cat part3_logcat.txt

grep -q "notificationTapBackground: actionId=quick_add" part3_logcat.txt || {
  echo "FAIL: the real tap on the unresolvable charge's Quick Add button never reached notificationTapBackground."
  exit 1
}
grep -q "commitSmsQuickAdd: could not resolve a ledger, reposting review notification" part3_logcat.txt || {
  echo "FAIL: commitSmsQuickAdd never even recognized this as an unresolvable charge."
  exit 1
}
grep -q "commitSmsQuickAdd: review notification reposted" part3_logcat.txt || {
  echo "FAIL: commitSmsQuickAdd recognized the charge as unresolvable but never actually reposted a review notification -- this is the real Quick Add 'does nothing' report."
  exit 1
}
grep -q "notificationTapBackground: commitSmsQuickAdd added=false" part3_logcat.txt || {
  echo "FAIL: expected commitSmsQuickAdd to report added=false for an unresolvable charge."
  exit 1
}

echo "--- Force-stopping again for a cold start before tapping the reposted notification's body ---"
adb shell am force-stop "$PKG"
adb logcat -c
sleep 3

tap_notification_text "Charge detected: Uber"
sleep 25

adb logcat -d > part3_body_tap_logcat.txt
echo "--- entire logcat for tapping the unresolvable charge's reposted notification ---"
cat part3_body_tap_logcat.txt

grep -q "_onNotificationResponse: actionId=null" part3_body_tap_logcat.txt || {
  echo "FAIL: tapping the reposted notification's body never reached _onNotificationResponse."
  exit 1
}
grep -q "processIncomingSms: reviewable match found, awaiting navigator" part3_body_tap_logcat.txt || {
  echo "FAIL: processIncomingSms didn't find the unresolvable charge reviewable a second time."
  exit 1
}
if grep -q "processIncomingSms: navigator never became available" part3_body_tap_logcat.txt; then
  echo "FAIL: lost the cold-start Navigator race for the unresolvable charge's own review screen."
  exit 1
fi
grep -q "processIncomingSms: navigator ready, pushing SmsReviewScreen" part3_body_tap_logcat.txt || {
  echo "FAIL: never reached the point of pushing SmsReviewScreen for the unresolvable charge."
  exit 1
}

echo "--- Confirming the actual 'which ledger?' picker is on screen ---"
dump_ui window_dump_unresolvable.xml
if ! grep -q "Confirm payment" window_dump_unresolvable.xml; then
  echo "FAIL: SmsReviewScreen never actually opened for the unresolvable charge."
  cat window_dump_unresolvable.xml
  exit 1
fi
if ! grep -q "Add to which ledger?" window_dump_unresolvable.xml; then
  echo "FAIL: SmsReviewScreen opened, but its ledger-picker prompt ('Add to which ledger?') isn't on screen."
  cat window_dump_unresolvable.xml
  exit 1
fi

echo "PASS: a real tap on the real Quick Add button for an unresolvable charge correctly reposted a notification, and a real tap on that notification opened a real, on-screen 'which ledger?' picker."
