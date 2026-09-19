#!/usr/bin/env bash
# Run inside the verify-quick-add CI job, against a real (emulated) Android
# device with the actual debug APK installed.
#
# Every earlier version of this script proved the Dart code behind the
# notification tap is correct by hand-constructing the underlying Android
# Intent/broadcast a real tap is *supposed* to send, then firing it directly
# via `adb shell am broadcast`/`am start`. That reliably caught every bug in
# the code that runs *after* such an Intent arrives -- but it never once
# verified that a real incoming SMS actually produces a real, on-screen
# notification, or that tapping that actual rendered UI (with a real finger,
# or a real screen tap here) is what sends that Intent in the first place.
#
# This version instead: injects a real SMS into the emulator (`adb emu sms
# send`, which triggers the exact same Telephony.Sms.Intents.SMS_RECEIVED_
# ACTION broadcast a real bank text does), waits for the real notification
# it produces, dumps the real on-screen UI via uiautomator, locates it by
# its exact visible text, and taps those exact screen coordinates with
# `adb shell input tap` -- the same primitive a real finger tap resolves
# to. Two scenarios:
#   Part 1: a charge that RESOLVES to a known ledger, tapped twice in a row
#     (two separate real SMS, the second one after a genuine cold start) --
#     checks the on-device database actually gets both ledger entries. A
#     plain tap on the notification's body is the whole interaction now --
#     see showSmsChargeReviewNotification's own doc comment for why the
#     separate "Quick add" action button this used to test was removed
#     entirely (a real device reported it silently swallowing a tap during
#     the notification's heads-up pop-up).
#   Part 2: a charge that CANNOT resolve a ledger -- resolveLedgerTarget's
#     own "ask which ledger" case, and the original, real-world request
#     this notification exists for. Taps it once, confirms it correctly
#     reports nothing added and reposts a notification instead, then taps
#     *that* notification and confirms the real "which ledger?" picker is
#     on screen.
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

# SmsReceiver's own manifest entry only ever receives anything once the
# user has actually granted RECEIVE_SMS (a dangerous/runtime permission,
# normally granted by walking through Settings > Bank SMS detection in the
# app itself) -- Android silently never delivers the protected
# SMS_RECEIVED broadcast to an app that hasn't been granted it, receiver
# registration notwithstanding. A fresh install has neither this nor
# POST_NOTIFICATIONS granted, and no test UI here walks the real
# permission-request flow -- `pm grant` is the standard way to pre-grant a
# runtime permission from adb without needing to drive that UI.
echo "--- Granting RECEIVE_SMS and POST_NOTIFICATIONS (dangerous/runtime permissions no test UI flow grants here) ---"
adb shell pm grant "$PKG" android.permission.RECEIVE_SMS
adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS

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
# matches. Exact match, not substring.
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

# Expands the notification shade, then polls (re-dumping the UI every 5s,
# up to $2 seconds total -- default 90) for a node whose exact visible text
# is $1, tapping it the moment it appears. A charge notification only
# exists once SmsReceiver's WorkManager task has actually run
# commitSmsAutoDetect end to end (a real, if expedited, background engine
# spin-up plus WorkManager's own scheduling latency) -- a single fixed
# sleep before one dump attempt was proven too short on a loaded CI
# runner. Polling for the actual condition rather than guessing a delay
# removes that whole class of flake. Fails loudly with the full last-seen
# dump if $2 elapses with no match, so a genuine absence is still
# immediately diagnosable.
tap_notification_text() {
  local needle="$1" timeout="${2:-90}" waited=0 dump
  while [ "$waited" -lt "$timeout" ]; do
    adb shell cmd statusbar expand-notifications
    sleep 2
    dump="dump_$(date +%s%N).xml"
    dump_ui "$dump"
    local coords
    if coords=$(find_tap_coords "$dump" "$needle"); then
      echo "Found '$needle' after ${waited}s -- tapping at coordinates: $coords"
      adb shell input tap $coords
      return 0
    fi
    sleep 5
    waited=$((waited + 7))
  done
  echo "FAIL: could not find on-screen node with exact text '$needle' within ${timeout}s."
  echo "--- last UI dump ---"
  cat "$dump"
  echo "--- full logcat up to this point ---"
  adb logcat -d
  exit 1
}

# Injects a real SMS into the emulator -- the exact same
# Telephony.Sms.Intents.SMS_RECEIVED_ACTION broadcast a real bank text
# produces, triggering the app's real SmsReceiver -> WorkManager ->
# commitSmsAutoDetect -> showSmsChargeReviewNotification chain end to end,
# not a hand-constructed shortcut into the middle of it. Doesn't itself
# wait for the resulting notification -- tap_notification_text's own poll
# is what actually waits for that.
send_real_sms() {
  local body="$1"
  adb emu sms send TestBank "$body"
}

# --- Part 1: a real tap, twice in a row, on a charge that resolves ------

echo "=== Part 1: a real notification tap on a resolvable charge, twice in a row (second one after a genuine cold start) ==="

echo "--- Sending real SMS #1 (app left warm/running from the launch above) ---"
send_real_sms "$CHARGE_SMS"
tap_notification_text "Charge detected: Breadfast"
sleep 15

echo "--- Force-stopping for a genuine cold start before the second tap ---"
adb shell am force-stop "$PKG"
adb logcat -c

echo "--- Sending real SMS #2 (same text -- a real device timestamp still makes each dedupeId distinct) ---"
send_real_sms "$CHARGE_SMS"
tap_notification_text "Charge detected: Breadfast"
sleep 20

adb logcat -d > part1_logcat.txt
echo "--- entire logcat for Part 1 ---"
cat part1_logcat.txt

TAP_COUNT=$(grep -c "_onNotificationResponse: actionId=null" part1_logcat.txt || true)
echo "_onNotificationResponse invocation count: $TAP_COUNT (expected 2)"
if [ "$TAP_COUNT" -lt 2 ]; then
  echo "FAIL: a real tap on the notification never reached _onNotificationResponse both times -- the tap does not work."
  exit 1
fi
if grep -q "commitSmsQuickAdd: could not resolve a ledger" part1_logcat.txt; then
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
print(f"--- ledger_transactions rows for the seeded counterparty: {len(rows)} (expected 2) ---")
for row in rows:
    print("  ", row)
if len(rows) < 2:
    print("FAIL: both taps reached _onNotificationResponse, but the on-device "
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

echo "PASS: two real taps on the real notification each actually committed a ledger entry."

# --- Part 2: a real tap on a charge that CANNOT resolve a ledger --------

echo "=== Part 2: a real tap on a charge with no resolvable ledger -- the original 'ask which ledger' request ==="

echo "--- Relaunching the app (Part 1 left it force-stopped) ---"
adb shell am start -n "$PKG/$PKG.MainActivity"
sleep 15
adb logcat -c

echo "--- Sending the real, unresolvable-charge SMS ---"
send_real_sms "$UNRESOLVABLE_SMS"
tap_notification_text "Charge detected: Uber"
sleep 15

adb logcat -d > part2_logcat.txt
echo "--- entire logcat for tapping the unresolvable charge's notification ---"
cat part2_logcat.txt

grep -q "_onNotificationResponse: actionId=null" part2_logcat.txt || {
  echo "FAIL: the real tap on the unresolvable charge's notification never reached _onNotificationResponse."
  exit 1
}
grep -q "commitSmsQuickAdd: could not resolve a ledger, reposting review notification" part2_logcat.txt || {
  echo "FAIL: commitSmsQuickAdd never even recognized this as an unresolvable charge."
  exit 1
}
grep -q "commitSmsQuickAdd: review notification reposted" part2_logcat.txt || {
  echo "FAIL: commitSmsQuickAdd recognized the charge as unresolvable but never actually reposted a review notification -- this is the real 'tapping it does nothing' report."
  exit 1
}

echo "--- Tapping the reposted notification, warm (app never force-stopped since the tap above) ---"
# Deliberately no force-stop/kill here -- both were tried in earlier
# versions of this script and were self-inflicted test artifacts, not app
# bugs (force-stop cancels an app's own posted notifications as a
# documented side effect; `am kill` doesn't reliably kill this app's
# process shortly after an expedited WorkManager task ran). A warm tap is
# also the more relevant case now: a real, on-device report showed exactly
# this scenario (app already open, tapping a notification) failing until a
# native fallback was added -- this is what actually proves that fix.
tap_notification_text "Charge detected: Uber"
sleep 20

adb logcat -d > part2_body_tap_logcat.txt
echo "--- entire logcat for tapping the unresolvable charge's reposted notification ---"
cat part2_body_tap_logcat.txt

grep -q "_onNotificationResponse: actionId=null" part2_body_tap_logcat.txt || {
  echo "FAIL: tapping the reposted notification never reached _onNotificationResponse."
  exit 1
}
grep -q "processIncomingSms: reviewable match found, awaiting navigator" part2_body_tap_logcat.txt || {
  echo "FAIL: processIncomingSms didn't find the unresolvable charge reviewable a second time."
  exit 1
}
if grep -q "processIncomingSms: navigator never became available" part2_body_tap_logcat.txt; then
  echo "FAIL: lost the Navigator race for the unresolvable charge's own review screen."
  exit 1
fi
grep -q "processIncomingSms: navigator ready, pushing SmsReviewScreen" part2_body_tap_logcat.txt || {
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

echo "PASS: a real tap on an unresolvable charge's notification correctly reposted a notification, and a real tap on that repost opened a real, on-screen 'which ledger?' picker."
