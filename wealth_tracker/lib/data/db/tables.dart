import 'package:drift/drift.dart';

/// A single thing the user owns: crypto, metals, cash, vehicles, property...
class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get valuationMode => text()();

  /// Units held: coins for crypto, grams for metals, or an amount
  /// denominated in [symbolOrCurrency] for the `currency` valuation mode
  /// (covers both literal cash holdings and a typed-in value like a car's).
  RealColumn get quantity => real()();

  /// Crypto symbol (e.g. `bitcoin`), metal symbol (`XAU_GRAM_<karat>K`/`XAG_GRAM`),
  /// or a currency code (EGP/USD/EUR/SAR/AED/TRY).
  TextColumn get symbolOrCurrency => text()();

  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

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
  BoolColumn get includeInStatistics => boolean().withDefault(const Constant(true))();

  /// Whether this ledger's balance is summed into the Calculator tab's
  /// "current liquid cash" total. Defaults to true for the same reason.
  BoolColumn get includeInCalculator => boolean().withDefault(const Constant(true))();

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
  RealColumn get cibExplorerWalletAvailable => real().withDefault(const Constant(0))();
  RealColumn get cibExplorerWalletOwed => real().withDefault(const Constant(0))();
  RealColumn get cibPlatinumAvailable => real().withDefault(const Constant(0))();
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
  TextColumn get manualInputEntriesJson => text().withDefault(const Constant('[]'))();

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

  /// When [currentAvailableBalance] was last set by a parsed SMS — null if
  /// it's never been touched by SMS capture (e.g. only ever typed by hand).
  DateTimeColumn get balanceUpdatedAt => dateTime().nullable()();

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

  @override
  Set<Column> get primaryKey => {id};
}
