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
  IntColumn get dayOfMonth => integer()();

  /// Manual ordering for display — set to insertion order by default, but
  /// not tied to it, so a future "reorder" gesture has somewhere to write.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  TextColumn get profileId => text().nullable().references(Profiles, #id)();

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
