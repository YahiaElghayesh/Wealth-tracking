import 'package:drift/drift.dart';

/// A separate, fully isolated data space -- its own assets, ledgers,
/// statistics and calculator, switched from the profile picker beside
/// Settings. Every other user-data table below carries a [profileId]
/// stamped at insert time and filtered on every query, so nothing bleeds
/// between profiles.
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Manual ordering for display — set to insertion order by default.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A single thing the user owns: crypto, metals, cash, vehicles, property...
class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get valuationMode => text()();

  /// Units held: coins for crypto, grams for metals, shares for stocks, or
  /// an amount denominated in [symbolOrCurrency] for the `currency`
  /// valuation mode (covers both literal cash holdings and a typed-in value
  /// like a car's or a certificate's).
  RealColumn get quantity => real()();

  /// Crypto symbol (e.g. `bitcoin`), metal symbol (`XAU_GRAM_<karat>K`/`XAG_GRAM`),
  /// stock ticker (`SYMBOL:EXCHANGE`, e.g. `AAPL:NASDAQ`/`COMI:EGX`), or a
  /// currency code (EGP/USD/EUR/SAR/AED/TRY).
  TextColumn get symbolOrCurrency => text()();

  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// 'car' / 'motorcycle' / 'scooter' -- only meaningful when [category] is
  /// AssetCategory.vehicle, picks which icon shows everywhere this asset
  /// displays. Null (including for every non-vehicle asset) falls back to
  /// the generic car icon.
  TextColumn get vehicleType => text().nullable()();

  /// What was originally paid for this asset, in [purchaseCurrency] --
  /// optional (null means "not tracked"). Only surfaced in the UI for
  /// gold/silver/real estate/stock/crypto; the column itself is generic so
  /// nothing stops another category from using it later.
  RealColumn get purchasePrice => real().nullable()();
  TextColumn get purchaseCurrency => text().nullable()();

  /// When this asset was bought -- optional, and (unlike [purchasePrice])
  /// asked for on every category, since "when did I get this" doesn't
  /// depend on whether a gain/loss can be computed for it.
  DateTimeColumn get purchaseDate => dateTime().nullable()();

  /// Which [Profiles] row this asset belongs to. Nullable only because
  /// SQLite can't add a NOT NULL column with a dynamic default -- every
  /// insert going forward always stamps a real profile id; the migration
  /// backfills every pre-existing row to the seeded default profile.
  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached last-known USD price for a priceable symbol (crypto ticker,
/// `XAU_GRAM_<karat>K` / `XAG_GRAM`, or a currency code for FX).
class PriceCache extends Table {
  TextColumn get symbol => text()();
  RealColumn get priceUsd => real()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {symbol};
}

/// A person money is tracked against (e.g. "Dad").
class Counterparties extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Whether this ledger's data appears in the Statistics tab. Defaults to
  /// true so existing ledgers keep behaving exactly as before until the
  /// user explicitly opts one out.
  BoolColumn get includeInStatistics =>
      boolean().withDefault(const Constant(true))();

  /// Whether this ledger's balance is summed into the Calculator tab's
  /// "current liquid cash" total. Defaults to true for the same reason.
  BoolColumn get includeInCalculator =>
      boolean().withDefault(const Constant(true))();

  /// Whether this ledger shows up in the main Ledger list at all. Defaults
  /// to true so every existing ledger keeps showing exactly as before;
  /// setting this to false doesn't archive or delete anything -- the
  /// ledger, its transactions, and its Statistics/Calculator inclusion all
  /// keep working exactly as they do today, it's purely hidden from the
  /// main list until switched back (see the Ledger tab's own "Hidden
  /// ledgers" section for how to find one again).
  BoolColumn get visible => boolean().withDefault(const Constant(true))();

  /// A Tab is the same row-per-payment recording as a Ledger, but never
  /// represents anyone owing anyone anything -- it's just a running log of
  /// money going back and forth (e.g. a shared trip or a running tab with
  /// a friend). Defaults to false so every existing counterparty stays a
  /// normal Ledger. A Tab is always kept out of Statistics and the
  /// Calculator's liquid-cash total regardless of the two flags above --
  /// see `LedgerRepository.addCounterparty`/`updateCounterparty`, which
  /// enforce that even if a caller tries to pass true for either.
  BoolColumn get isTab => boolean().withDefault(const Constant(false))();

  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A single ledger entry. Positive [amount] means the user paid on the
/// counterparty's behalf (counterparty's debt to the user grows);
/// negative means the counterparty paid the user back.
class LedgerTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get counterpartyId => text().references(Counterparties, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get amount => real()();

  /// Currency [amount] was entered in (EGP/USD/EUR/SAR/AED/TRY). Balances
  /// and monthly totals convert everything to EGP via live FX for a single
  /// aggregate figure; the original currency is kept for display.
  TextColumn get currency => text().withDefault(const Constant('EGP'))();

  TextColumn get category => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  /// Denormalized from the owning counterparty's own profile, so "every
  /// transaction across every counterparty" queries (the calculator's
  /// combined total) can filter to the active profile without a join.
  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  /// 'manual' (typed in on this screen) or 'sms' (a vendor-rule auto-match
  /// via `commitSmsQuickAdd`, or a charge confirmed on `SmsReviewScreen`
  /// after tapping its notification) -- shown on the ledger row so a
  /// vendor-rule-matched entry doesn't look indistinguishable from one
  /// typed in by hand. Defaults to 'manual' so every pre-existing row
  /// (all of which really were typed in, since this column didn't exist
  /// before) backfills correctly with no migration logic beyond the
  /// column default.
  TextColumn get source => text().withDefault(const Constant('manual'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Small key/value store for app-level metadata (e.g. last Drive sync time).
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Manually-entered inputs for the "current liquid cash" calculator: the
/// ledger totals auto-derive from existing data, but these values (apartment
/// savings set aside monthly, the CIB account balance, and each credit
/// card's current owed balance) only the user knows and re-enters when they
/// check. One row per [key]; see `calculator_inputs.dart` for the fixed set
/// of keys in use.
class CalculatorInputs extends Table {
  TextColumn get key => text()();
  RealColumn get value => real()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// One saved "current liquid cash" calculation — an immutable historical
/// record, not a live-editing state. Each row is what the calculator's
/// inputs and result were at the moment the user tapped Save; card owed
/// amounts are stored directly (not just the available-balance the user
/// typed in) so a later change to a card's limit in Settings doesn't
/// retroactively change past history.
///
/// The three fixed nbe/cibExplorerWallet/cibPlatinum columns are the
/// original, pre-user-managed-cards format — kept as-is (never dropped) so
/// history saved before credit cards became user-editable still displays.
/// Every snapshot saved since then instead uses [cardEntriesJson], a
/// JSON-encoded list of `{name, bank, currency, limit, availableBalance,
/// owed}` — one per card that existed at save time, how ever many there are.
class CalculatorSnapshots extends Table {
  TextColumn get id => text()();
  DateTimeColumn get computedAt => dateTime()();
  RealColumn get resultAmount => real()();
  RealColumn get ledgersTotal => real()();
  RealColumn get apartmentSavings => real()();
  RealColumn get cibAccountBalance => real()();
  RealColumn get nbeAvailable => real().withDefault(const Constant(0))();
  RealColumn get nbeOwed => real().withDefault(const Constant(0))();
  RealColumn get cibExplorerWalletAvailable =>
      real().withDefault(const Constant(0))();
  RealColumn get cibExplorerWalletOwed =>
      real().withDefault(const Constant(0))();
  RealColumn get cibPlatinumAvailable =>
      real().withDefault(const Constant(0))();
  RealColumn get cibPlatinumOwed => real().withDefault(const Constant(0))();

  /// JSON-encoded list of `{label, amount, isAddition}` custom line items.
  TextColumn get customItemsJson => text().withDefault(const Constant('[]'))();

  /// JSON-encoded list of per-card entries — see class doc. Empty list
  /// (`'[]'`, the default) on every snapshot saved before user-managed
  /// cards existed; the fixed nbe/cib* columns above carry those instead.
  TextColumn get cardEntriesJson => text().withDefault(const Constant('[]'))();

  /// JSON-encoded list of per-manual-input entries — one per ManualInput
  /// row that existed at save time (see ManualInputSnapshotEntry). Empty
  /// list (`'[]'`, the default) on every snapshot saved before manual
  /// inputs became user-managed; the fixed apartmentSavings/
  /// cibAccountBalance columns above carry those instead, and are never
  /// written to again by any snapshot saved after this point.
  TextColumn get manualInputEntriesJson =>
      text().withDefault(const Constant('[]'))();

  /// True once [cardEntriesJson] is the authoritative source for this
  /// snapshot's card breakdown -- distinct from [cardEntriesJson] simply
  /// being `'[]'`, which is genuinely ambiguous on its own: a profile with
  /// zero cards configured at save time produces the exact same empty
  /// list a snapshot saved before user-managed cards existed does. Every
  /// snapshot saved going forward sets this to `true` unconditionally
  /// (the default), so an empty-but-current list still renders correctly
  /// as "no cards" instead of silently falling back to the fixed legacy
  /// nbe/cib* columns, which are the same three hardcoded card names
  /// regardless of profile. Existing rows are backfilled by the migration
  /// that added this column, from whether their own [cardEntriesJson] was
  /// already non-empty at that point -- the best available signal for
  /// data written before this flag existed.
  BoolColumn get cardsRecorded => boolean().withDefault(const Constant(true))();

  /// Same idea as [cardsRecorded], for [manualInputEntriesJson].
  BoolColumn get manualInputsRecorded =>
      boolean().withDefault(const Constant(true))();

  /// JSON-encoded list of per-bank-account entries (see
  /// BankAccountSnapshotEntry) -- one per BankAccount row that existed at
  /// save time. Unlike [cardEntriesJson]/[manualInputEntriesJson], bank
  /// accounts have no fixed legacy predecessor to distinguish an empty
  /// list from, so no matching "*Recorded" flag is needed: an empty list
  /// unambiguously means "no bank accounts configured" on every snapshot,
  /// old or new.
  TextColumn get bankAccountEntriesJson =>
      text().withDefault(const Constant('[]'))();

  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A credit card the user tracks in the Calculator tab — fully user-managed
/// (added/edited/removed from Settings) rather than a fixed hardcoded set.
class CreditCards extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get bank => text()();
  RealColumn get limitAmount => real()();
  TextColumn get currency => text().withDefault(const Constant('EGP'))();

  /// Manual ordering for display — set to insertion order by default, but
  /// not tied to it, so a future "reorder" gesture has somewhere to write.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// The last 4 digits printed on the card, as they appear in bank SMS
  /// alerts (e.g. "...ending in 4912") — lets SMS-based balance tracking
  /// know which card a given message is about.
  TextColumn get lastFourDigits => text().nullable()();

  /// A supplementary card's own last-4 digits -- a supplementary card
  /// shares its primary card's limit and balance outright (a real bank
  /// doesn't track them separately), so it's never a second [CreditCards]
  /// row of its own; it's just a second number an SMS about *this* card
  /// might carry instead of [lastFourDigits]. See
  /// `sms_rule_engine.dart`'s card-matching loop, which checks both.
  TextColumn get supplementaryLastFourDigits => text().nullable()();

  /// Available-to-spend balance, kept current by SMS capture (or left null
  /// until the user first types one into the Calculator). Separate from any
  /// particular Calculator session's typed value — this is the card's own
  /// remembered state, in [currency].
  RealColumn get currentAvailableBalance => real().nullable()();

  /// When [currentAvailableBalance] was last set -- by a parsed SMS, or by
  /// the user editing the Calculator tab's balance field directly (see
  /// CalculatorScreen's debounced save-back) -- whichever happened most
  /// recently. Null if it's never been touched by either.
  DateTimeColumn get balanceUpdatedAt => dateTime().nullable()();

  /// 'sms' or 'manual', matching whichever of the two actually last set
  /// [currentAvailableBalance]/[balanceUpdatedAt] -- shown alongside that
  /// timestamp so "Updated 2h ago" doesn't leave the user guessing whether
  /// that was a real bank alert or their own typed correction. Null exactly
  /// when [balanceUpdatedAt] is (never touched by either yet).
  TextColumn get balanceUpdatedSource => text().nullable()();

  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A bank account the user tracks in the Calculator tab -- unlike
/// [CreditCards], there's no limit/owed math: the account's available
/// balance is simply added straight into the Calculator's total, the same
/// way a [ManualInputs] addition is.
class BankAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get bank => text()();
  TextColumn get currency => text().withDefault(const Constant('EGP'))();

  /// Manual ordering for display — set to insertion order by default, but
  /// not tied to it, so a future "reorder" gesture has somewhere to write.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  TextColumn get accountNumber => text().nullable()();

  /// Available balance, kept current by a debounced save-back the moment
  /// the user edits it in the Calculator tab -- mirroring
  /// [CreditCards.currentAvailableBalance]'s own doc comment (and the
  /// "reset itself" bug it fixes) exactly, since this is the same kind of
  /// field. Null until the user first types a value in.
  RealColumn get currentAvailableBalance => real().nullable()();

  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A user-managed signed line item for the Calculator tab (e.g. "Apartment
/// savings", "CIB Accounts Balance") — fully user-managed (added/edited/
/// removed from Settings), replacing the old fixed two-field setup the same
/// way CreditCards replaced the old fixed three-card setup.
class ManualInputs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isAddition => boolean()();
  TextColumn get currency => text().withDefault(const Constant('EGP'))();

  /// Manual ordering for display — set to insertion order by default, but
  /// not tied to it, so a future "reorder" gesture has somewhere to write.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  /// The last value actually typed into this input's Calculator field, in
  /// [currency] -- kept current by a debounced save-back the moment the
  /// user edits it (see CalculatorScreen's `_scheduleManualInputSave`,
  /// mirroring `_scheduleCardBalanceSave`'s own doc comment for
  /// [CreditCards.currentAvailableBalance]). Before this column existed, a
  /// typed value only ever persisted at all once the user tapped the whole
  /// Calculator screen's Save button (which bakes it into a
  /// CalculatorSnapshot) -- any edit made after the last Save, or before
  /// the very first one, lived only in this screen's in-memory
  /// TextEditingController and vanished the moment the app process was
  /// killed (an app update, or simply closing the app for a while), which
  /// looked exactly like "my manual input got reset". Null means never
  /// typed into on this device yet -- the seeding logic falls back to the
  /// last saved snapshot's matching-by-name entry in that case, same as it
  /// always has.
  RealColumn get currentValue => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A user-managed ledger expense category — quick-pick chips on the
/// add-transaction screen. Editable from Settings instead of a fixed,
/// hardcoded list; "Other" is not a row here — it's always appended as a
/// synthetic last choice by the UI, since picking it switches to a free-text
/// field rather than assigning a category on its own.
class LedgerCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// A single emoji representing this category, picked from a fixed set in
  /// Settings -> Categories & icons. Null falls back to a generic receipt
  /// glyph wherever it's displayed.
  TextColumn get icon => text().nullable()();

  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A monthly bill/subscription the user wants tracked and totaled (e.g.
/// Netflix, YouTube Premium, Amazon Prime) -- fully user-managed, added
/// either directly from the Recurring Payments tab or from a matched bank
/// SMS charge (see SmsReviewScreen).
class RecurringPayments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('EGP'))();

  /// True when [amount] is the exact charge every month; false when it's
  /// only a floor -- a usage-based bill that's never less than this but can
  /// run higher (e.g. a metered utility). Surfaced as a small "min." badge
  /// wherever this shows; still summed at face value into the tab's
  /// monthly total either way, since that's the best available estimate
  /// without knowing the real bill in advance.
  BoolColumn get isExactAmount => boolean().withDefault(const Constant(true))();

  /// Day of the month (1-31) this bills on -- not a full date, since the
  /// whole point is "every month on this day," not one specific
  /// occurrence. A day past a shorter month's own last day (e.g. 31 in
  /// February) is left for display logic to clamp, not stored specially.
  /// Only meaningful when [frequency] is 'monthly'; for any other
  /// frequency this still holds a value (never null -- see the column's
  /// own NOT NULL constraint, kept rather than loosened to avoid an
  /// ALTER-driven migration) but it's a meaningless placeholder the app
  /// never reads.
  IntColumn get dayOfMonth => integer()();

  /// Manual ordering for display — set to insertion order by default, but
  /// not tied to it, so a future "reorder" gesture has somewhere to write.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  /// 'monthly' | 'interval' | 'yearly' -- see
  /// core/models/recurring_payment_frequency.dart. Defaults to 'monthly'
  /// so every row created before this column existed (the only kind that
  /// existed then) keeps reading correctly with no backfill needed.
  TextColumn get frequency => text().withDefault(const Constant('monthly'))();

  /// Only meaningful when [frequency] is 'interval': how many days between
  /// occurrences (e.g. 10 for "every 10 days").
  IntColumn get intervalDays => integer().nullable()();

  /// Only meaningful when [frequency] is 'interval': the date the interval
  /// counts from. The due date is always computed fresh as the next
  /// multiple of [intervalDays] on/after this anchor (see
  /// recurring_payment_due.dart) rather than stored and advanced, so it
  /// can never drift out of sync with a missed "mark as paid" tap.
  DateTimeColumn get intervalAnchorDate => dateTime().nullable()();

  /// Only meaningful when [frequency] is 'yearly': the month (1-12) this
  /// bills on every year.
  IntColumn get yearlyMonth => integer().nullable()();

  /// Only meaningful when [frequency] is 'yearly': the day of that month
  /// (1-31), clamped the same way [dayOfMonth] is for a shorter month.
  IntColumn get yearlyDay => integer().nullable()();

  /// When the user last tapped "mark as paid" -- drives the green
  /// paid/pending state and the total card's paid/pending split. Compared
  /// against the *current* billing cycle (recurring_payment_due.dart), not
  /// just "is this non-null", so a paid-mark from a previous cycle
  /// automatically reads as pending again once a new one comes due.
  DateTimeColumn get lastPaidAt => dateTime().nullable()();

  /// Free-text notes -- e.g. account numbers, a reason the amount varies,
  /// anything the fixed fields above don't capture. Optional, shown under
  /// the name wherever this payment displays.
  TextColumn get notes => text().nullable()();

  /// 'auto' (charged/paid automatically -- the original, only behavior
  /// before this column existed, so it's the default every pre-existing
  /// row backfills to) or 'manual' (the user has to actually pay this one
  /// themselves). 'auto' keeps today's behavior: once the due date arrives
  /// with no explicit "mark as paid" tap, it's simply assumed paid (see
  /// recurringPaymentIsPaidForCurrentCycle). 'manual' turns that assumption
  /// off and instead schedules a repeating reminder notification (see
  /// RecurringPaymentReminderChannel) starting at midnight on the due date,
  /// re-shown every 4 hours until the notification's own "Done" action (or
  /// the in-app paid toggle) is actually pressed.
  TextColumn get paymentMode => text().withDefault(const Constant('auto'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One permanent, auto-recorded snapshot of a single past calendar month's
/// recurring-payments totals -- written automatically (see
/// RecurringPaymentHistoryRepository.ensureRecorded) the first time the app
/// notices the calendar has moved past that month, since nothing else
/// remembers what a month's total/paid/pending were once the current
/// month's numbers take their place. [pendingAmount] isn't stored
/// separately -- always `totalAmount - paidAmount`.
class RecurringPaymentHistory extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  /// The recorded month, as a plain calendar year/month pair rather than a
  /// full date -- this row represents an entire month, not one instant in
  /// it, and (unlike a single int count of months) stays unambiguous
  /// across year boundaries.
  IntColumn get year => integer()();

  /// 1-12.
  IntColumn get month => integer()();

  TextColumn get currency => text().withDefault(const Constant('EGP'))();
  RealColumn get totalAmount => real()();
  RealColumn get paidAmount => real()();
  DateTimeColumn get recordedAt => dateTime()();

  /// JSON-encoded list of `{name, amount, paid}` -- one per payment that
  /// was due this month, each `amount` already converted to the
  /// settlement currency at record time (see
  /// RecurringPaymentHistoryItem). Empty list (`'[]'`, the default) on
  /// every row recorded before this per-item breakdown existed --
  /// distinguishable from a genuinely-empty month by `totalAmount > 0`,
  /// since ensureRecorded never inserts a row at all when nothing was due
  /// (see that method's own doc comment), so a real recorded total always
  /// implies at least one contributing item.
  TextColumn get itemsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A rule matching a bank SMS merchant name to where it should be recorded:
/// "any charge at a merchant whose name contains [vendorPattern] (case
/// insensitive) is a payment made on [counterpartyId]'s behalf, categorized
/// as [category]". Drives the SMS auto-capture feature.
class VendorRules extends Table {
  TextColumn get id => text()();
  TextColumn get vendorPattern => text()();
  TextColumn get counterpartyId => text().references(Counterparties, #id)();
  TextColumn get category => text()();

  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A user-managed bank name -- the single shared list Credit Cards, Bank
/// Accounts, and SMS Rules all pick from, so a card/account and a rule can
/// be reliably tied to the same bank instead of matching on free-typed
/// text that could differ by a character.
class Banks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A user-built SMS rule replacing the app's old hardwired per-bank
/// parsing -- see `lib/data/sms/sms_rule_engine.dart` for how [segmentsJson]
/// (a marked-up real sample SMS, split into fixed literal text and
/// variable placeholders) becomes a matcher, and how a match is applied.
class SmsRules extends Table {
  TextColumn get id => text()();
  TextColumn get bankId => text().references(Banks, #id)();

  /// User-given label (e.g. "Amazon refund") shown instead of the generic
  /// operation name in the rules list -- optional, since [operation] alone
  /// is still a perfectly fine label for a rule with only one obvious
  /// purpose.
  TextColumn get name => text().nullable()();

  /// 'creditCardBalance' | 'bankAccountBalance' | 'ledgerPayment'.
  TextColumn get operation => text()();

  /// The real SMS this rule was built from -- concatenating every segment
  /// in [segmentsJson] reconstructs this exactly, but this column is kept
  /// too since it's what the edit screen actually displays and re-marks.
  TextColumn get sampleText => text()();

  /// JSON-encoded list of `{type, text, tag, role}` segments -- see
  /// `SmsRuleSegment` -- in order, alternating literal text this rule
  /// requires to appear with the variable portions (card/account number,
  /// value, vendor, sender) it extracts.
  TextColumn get segmentsJson => text()();

  /// Only meaningful for a 'ledgerPayment' rule -- which ledger a match
  /// adds its entry to. An SMS never names one of the user's own ledgers,
  /// so this is picked once, at rule-creation time, the same way a Vendor
  /// Rule already worked.
  TextColumn get targetCounterpartyId =>
      text().nullable().references(Counterparties, #id)();

  /// For a 'ledgerPayment' rule, the currency its ledger entries default to
  /// when the message itself doesn't carry a recognized `currency` tag
  /// match. For a balance rule, unused directly -- a matched `currency` is
  /// only ever compared against the card's/account's own currency to
  /// decide whether a conversion is needed, never stored.
  TextColumn get currency => text().nullable()();

  /// Whether a local notification is shown when this rule successfully
  /// applies to a real incoming SMS.
  BoolColumn get notifyOnMatch =>
      boolean().withDefault(const Constant(false))();

  /// 'strict' (default) requires every un-tagged part of the sample to
  /// appear in a real SMS essentially verbatim (whitespace aside) --
  /// 'flexible' keeps only a couple of words immediately next to each tag
  /// as an anchor and treats longer untagged stretches as "anything goes
  /// here", tolerating a date, an extra sentence, or other wording a
  /// single sample can't predict. See `compileSmsRulePattern`.
  TextColumn get matchMode => text().withDefault(const Constant('strict'))();

  /// Whether this rule is actually applied to incoming SMS -- a disabled
  /// rule is skipped by matching entirely (see `_matchAllRules`), without
  /// deleting it, so a rule that's temporarily wrong or noisy can be
  /// switched off and back on instead of being rebuilt from scratch.
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();
  TextColumn get profileId => text().nullable().references(Profiles, #id)();

  @override
  Set<Column> get primaryKey => {id};
}
