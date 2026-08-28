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
