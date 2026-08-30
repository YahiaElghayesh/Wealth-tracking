# Wealth Tracker

A personal net worth and family debt tracker, built with Flutter for Android and Windows.

## What it does

**Net worth** — log assets (crypto, gold, silver, cash in any currency, vehicles, real
estate, other) and see your total net worth in USD and EGP, split into liquid
(crypto/metals/cash) vs. non-liquid (vehicles/property/other). Crypto and FX prices are
pulled live for free with no signup; gold/silver need a free goldapi.io key. An Android
home-screen widget shows the same summary without opening the app.

**Debt ledger** — log payments made on someone else's behalf (e.g. household expenses you
front for a parent), categorized (groceries, food delivery, fuel, etc.), with a running
balance and a month-end summary you can share as text or export as a PDF.

**Sync** — your phone and Windows machine stay in sync via a single hidden file in your own
Google Drive (`appDataFolder` — never your visible Drive). No server to host.

## Project status

This was built end-to-end in a Linux sandbox with no Android SDK, no Windows machine, and
no device to run it on. Everything here compiles (`flutter analyze` is clean) and the
pure logic is unit tested (`flutter test`), but **none of it has been run as a real app
yet** — that's the next step, on your own machine/phone, following the setup below.
Expect some first-run friction, especially around the Drive OAuth setup.

## Setup

### 1. Install Flutter

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
and run `flutter doctor` to confirm your Android and/or Windows toolchains are ready.

```
cd wealth_tracker
flutter pub get
```

The database layer uses code generation (`drift`). If you change anything in
`lib/data/db/tables.dart`, regenerate with:

```
dart run build_runner build --delete-conflicting-outputs
```

### 2. Run it

```
flutter run -d windows    # Windows desktop
flutter run -d <deviceid> # Android device/emulator, see `flutter devices`
```

The app works fully offline with manually-entered values from the first launch — live
pricing and Drive sync are both optional, additive setup steps below.

### 3. Live prices (optional but recommended)

- **Crypto and FX** work immediately, no setup — CoinGecko and open.er-api.com are both
  free, keyless APIs.
- **Gold/silver** need a free API key from [goldapi.io](https://www.goldapi.io/). Sign up,
  copy your access token, and paste it into the app's Settings screen. The free tier is
  low-volume, so the app caches prices locally and only refetches on a manual "Refresh"
  or a background schedule — don't expect tick-by-tick updates.

### 4. Google Drive sync (optional)

Both platforms need an OAuth client from **your own** Google Cloud project — this can't be
set up on your behalf, since it's tied to your Google account.

1. Go to [Google Cloud Console](https://console.cloud.google.com/) → create a new project
   (or reuse one) → **APIs & Services → Library** → enable the **Google Drive API**.
2. **APIs & Services → OAuth consent screen** → configure it (External is fine for
   personal use; you'll be the only test user).
3. **APIs & Services → Credentials → Create Credentials → OAuth client ID**:
   - **For Android**: choose "Android", set the package name to
     `com.yahiaelghayesh.wealth_tracker`, and provide your app's SHA-1 signing
     certificate fingerprint (get it with
     `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
     for a debug build, or your release keystore's fingerprint for a release build). No
     further configuration needed in the app itself — the native SDK finds this client
     automatically once it's registered. **Also create a second client of type "Web
     application"** in the same project (no redirect URIs needed) — copy its Client ID
     and paste it into the app's Settings → Google Drive sync → "Google Web Client ID".
     google_sign_in requires this even on Android; without it, sign-in fails with
     "server client ID must be provided on Android".
   - **For Windows**: choose "Desktop app". Google will give you a Client ID and Client
     Secret — paste both into the app's Settings screen under "Google Drive sync". (This
     secret isn't meaningfully confidential for installed/desktop apps per Google's own
     guidance, but keep it out of any public repo regardless.)
4. In the app, go to Settings → Google Drive sync → **Sign in to Google**, then **Sync
   now**. The first sync on any device just uploads; after that, sync compares
   modification times and applies whichever side changed (see
   `lib/data/sync/sync_decision.dart` for the exact rule), or asks you to pick a side if
   both changed since the last sync.

To revoke access later, use your [Google Account permissions page](https://myaccount.google.com/permissions)
— signing out in the app only clears the locally-stored token, it doesn't revoke the grant
server-side.

### 5. Android home-screen widget

Build and install the app on an Android device, then long-press the home screen →
Widgets → **Wealth Tracker** → drag the "Net Worth" widget onto the screen. It shows
whatever was last computed in the app and refreshes automatically every few hours, or
immediately after you open the app and its data changes.

### 6. In-app update checking (optional)

Settings → App updates lets the app check GitHub for a newer CI build and install it
directly, without going back to GitHub Actions to download an APK by hand. Since this
repo is private, that requires a token baked into the app at build time:

1. Create a **fine-grained personal access token**: GitHub → Settings → Developer
   settings → Personal access tokens → Fine-grained tokens → Generate new token.
2. Repository access → Only select repositories → this repo.
3. Permissions → Repository permissions → **Contents: Read-only** (Metadata: Read-only
   comes along automatically).
4. Set an expiration long enough that you won't need to regenerate it often — the app
   can't reach GitHub at all with an expired token, and there's no in-app way to update
   just the token once it's baked into an already-installed build.
5. Add the generated token as a repository secret named `APP_UPDATE_TOKEN`
   (Settings → Secrets and variables → Actions → New repository secret).

CI passes it to `flutter build apk` via `--dart-define` on every build; builds made
without that secret configured leave the update-checking screen showing a plain
"not configured" message instead of failing confusingly.

Because that token only grants read access to this one repository's contents, it's a
low-risk thing to embed in a distributed APK — but it's still a real credential, and
anyone with a copy of the installed APK file could extract it. Revoke and rotate it
(same GitHub settings page) if that's ever a concern.

## Architecture

- **State management**: Riverpod
- **Local database**: `drift` (SQLite), synced tables are `assets`, `counterparties`,
  `ledger_transactions`; `price_cache` and `sync_meta` are local-only
- **Pricing**: `lib/data/pricing/` — a `PriceProvider` interface with CoinGecko (crypto),
  open.er-api.com (FX), and goldapi.io (metals) implementations, fanned out and merged by
  `PriceRefreshService`
- **Ledger**: `lib/data/ledger/` — pure calculator functions (`runningBalance`,
  `monthlyCategoryTotals`, etc.) kept separate from the drift repository for testability
- **Sync**: `lib/data/sync/` — `DriveSyncService` orchestrates auth (platform-specific) +
  snapshot upload/download; `decideSyncAction` is the pure last-writer-wins decision logic
- **Android widget**: `android/app/.../NetWorthWidgetProvider.kt` + `home_widget` bridge

## Tests

```
flutter analyze
flutter test
```

Tests cover the net worth calculator, ledger balance/monthly-grouping logic, price refresh
merging/error-handling, and the sync conflict decision matrix — all pure functions with no
device, network, or database dependency, so they run anywhere.
