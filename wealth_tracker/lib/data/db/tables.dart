import 'package:drift/drift.dart';

/// A single thing the user owns: crypto, metals, cash, vehicles, property...
class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get valuationMode => text()();

  /// Units held: coins for crypto, grams for metals, currency units for
  /// fiat, or `1` for manually-valued assets.
  RealColumn get quantity => real()();

  /// Crypto symbol (BTC), metal symbol (XAU/XAG) or currency code
  /// (USD/EGP). Null for manually-valued assets.
  TextColumn get symbolOrCurrency => text().nullable()();

  /// Current value in USD, only used when [valuationMode] is manual.
  RealColumn get manualValueUsd => real().nullable()();

  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached last-known USD price for a priceable symbol (crypto ticker,
/// `XAU_GRAM` / `XAG_GRAM`, or a currency code for FX).
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
