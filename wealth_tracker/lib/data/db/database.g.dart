// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AssetsTable extends Assets with TableInfo<$AssetsTable, Asset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valuationModeMeta = const VerificationMeta(
    'valuationMode',
  );
  @override
  late final GeneratedColumn<String> valuationMode = GeneratedColumn<String>(
    'valuation_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolOrCurrencyMeta = const VerificationMeta(
    'symbolOrCurrency',
  );
  @override
  late final GeneratedColumn<String> symbolOrCurrency = GeneratedColumn<String>(
    'symbol_or_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    valuationMode,
    quantity,
    symbolOrCurrency,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Asset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('valuation_mode')) {
      context.handle(
        _valuationModeMeta,
        valuationMode.isAcceptableOrUnknown(
          data['valuation_mode']!,
          _valuationModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_valuationModeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('symbol_or_currency')) {
      context.handle(
        _symbolOrCurrencyMeta,
        symbolOrCurrency.isAcceptableOrUnknown(
          data['symbol_or_currency']!,
          _symbolOrCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_symbolOrCurrencyMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Asset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Asset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      valuationMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valuation_mode'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      symbolOrCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol_or_currency'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }
}

class Asset extends DataClass implements Insertable<Asset> {
  final String id;
  final String name;
  final String category;
  final String valuationMode;

  /// Units held: coins for crypto, grams for metals, or an amount
  /// denominated in [symbolOrCurrency] for the `currency` valuation mode
  /// (covers both literal cash holdings and a typed-in value like a car's).
  final double quantity;

  /// Crypto symbol (e.g. `bitcoin`), metal symbol (`XAU_GRAM_<karat>K`/`XAG_GRAM`),
  /// or a currency code (EGP/USD/EUR/SAR/AED/TRY).
  final String symbolOrCurrency;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Asset({
    required this.id,
    required this.name,
    required this.category,
    required this.valuationMode,
    required this.quantity,
    required this.symbolOrCurrency,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['valuation_mode'] = Variable<String>(valuationMode);
    map['quantity'] = Variable<double>(quantity);
    map['symbol_or_currency'] = Variable<String>(symbolOrCurrency);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      valuationMode: Value(valuationMode),
      quantity: Value(quantity),
      symbolOrCurrency: Value(symbolOrCurrency),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Asset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Asset(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      valuationMode: serializer.fromJson<String>(json['valuationMode']),
      quantity: serializer.fromJson<double>(json['quantity']),
      symbolOrCurrency: serializer.fromJson<String>(json['symbolOrCurrency']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'valuationMode': serializer.toJson<String>(valuationMode),
      'quantity': serializer.toJson<double>(quantity),
      'symbolOrCurrency': serializer.toJson<String>(symbolOrCurrency),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Asset copyWith({
    String? id,
    String? name,
    String? category,
    String? valuationMode,
    double? quantity,
    String? symbolOrCurrency,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Asset(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    valuationMode: valuationMode ?? this.valuationMode,
    quantity: quantity ?? this.quantity,
    symbolOrCurrency: symbolOrCurrency ?? this.symbolOrCurrency,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Asset copyWithCompanion(AssetsCompanion data) {
    return Asset(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      valuationMode: data.valuationMode.present
          ? data.valuationMode.value
          : this.valuationMode,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      symbolOrCurrency: data.symbolOrCurrency.present
          ? data.symbolOrCurrency.value
          : this.symbolOrCurrency,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Asset(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('valuationMode: $valuationMode, ')
          ..write('quantity: $quantity, ')
          ..write('symbolOrCurrency: $symbolOrCurrency, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    valuationMode,
    quantity,
    symbolOrCurrency,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Asset &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.valuationMode == this.valuationMode &&
          other.quantity == this.quantity &&
          other.symbolOrCurrency == this.symbolOrCurrency &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AssetsCompanion extends UpdateCompanion<Asset> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<String> valuationMode;
  final Value<double> quantity;
  final Value<String> symbolOrCurrency;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.valuationMode = const Value.absent(),
    this.quantity = const Value.absent(),
    this.symbolOrCurrency = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String id,
    required String name,
    required String category,
    required String valuationMode,
    required double quantity,
    required String symbolOrCurrency,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       valuationMode = Value(valuationMode),
       quantity = Value(quantity),
       symbolOrCurrency = Value(symbolOrCurrency),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Asset> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? valuationMode,
    Expression<double>? quantity,
    Expression<String>? symbolOrCurrency,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (valuationMode != null) 'valuation_mode': valuationMode,
      if (quantity != null) 'quantity': quantity,
      if (symbolOrCurrency != null) 'symbol_or_currency': symbolOrCurrency,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<String>? valuationMode,
    Value<double>? quantity,
    Value<String>? symbolOrCurrency,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AssetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      valuationMode: valuationMode ?? this.valuationMode,
      quantity: quantity ?? this.quantity,
      symbolOrCurrency: symbolOrCurrency ?? this.symbolOrCurrency,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (valuationMode.present) {
      map['valuation_mode'] = Variable<String>(valuationMode.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (symbolOrCurrency.present) {
      map['symbol_or_currency'] = Variable<String>(symbolOrCurrency.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('valuationMode: $valuationMode, ')
          ..write('quantity: $quantity, ')
          ..write('symbolOrCurrency: $symbolOrCurrency, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PriceCacheTable extends PriceCache
    with TableInfo<$PriceCacheTable, PriceCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceUsdMeta = const VerificationMeta(
    'priceUsd',
  );
  @override
  late final GeneratedColumn<double> priceUsd = GeneratedColumn<double>(
    'price_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [symbol, priceUsd, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('price_usd')) {
      context.handle(
        _priceUsdMeta,
        priceUsd.isAcceptableOrUnknown(data['price_usd']!, _priceUsdMeta),
      );
    } else if (isInserting) {
      context.missing(_priceUsdMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol};
  @override
  PriceCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceCacheData(
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      priceUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_usd'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $PriceCacheTable createAlias(String alias) {
    return $PriceCacheTable(attachedDatabase, alias);
  }
}

class PriceCacheData extends DataClass implements Insertable<PriceCacheData> {
  final String symbol;
  final double priceUsd;
  final DateTime fetchedAt;
  const PriceCacheData({
    required this.symbol,
    required this.priceUsd,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    map['price_usd'] = Variable<double>(priceUsd);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  PriceCacheCompanion toCompanion(bool nullToAbsent) {
    return PriceCacheCompanion(
      symbol: Value(symbol),
      priceUsd: Value(priceUsd),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory PriceCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceCacheData(
      symbol: serializer.fromJson<String>(json['symbol']),
      priceUsd: serializer.fromJson<double>(json['priceUsd']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'priceUsd': serializer.toJson<double>(priceUsd),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  PriceCacheData copyWith({
    String? symbol,
    double? priceUsd,
    DateTime? fetchedAt,
  }) => PriceCacheData(
    symbol: symbol ?? this.symbol,
    priceUsd: priceUsd ?? this.priceUsd,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  PriceCacheData copyWithCompanion(PriceCacheCompanion data) {
    return PriceCacheData(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      priceUsd: data.priceUsd.present ? data.priceUsd.value : this.priceUsd,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceCacheData(')
          ..write('symbol: $symbol, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symbol, priceUsd, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceCacheData &&
          other.symbol == this.symbol &&
          other.priceUsd == this.priceUsd &&
          other.fetchedAt == this.fetchedAt);
}

class PriceCacheCompanion extends UpdateCompanion<PriceCacheData> {
  final Value<String> symbol;
  final Value<double> priceUsd;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const PriceCacheCompanion({
    this.symbol = const Value.absent(),
    this.priceUsd = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceCacheCompanion.insert({
    required String symbol,
    required double priceUsd,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : symbol = Value(symbol),
       priceUsd = Value(priceUsd),
       fetchedAt = Value(fetchedAt);
  static Insertable<PriceCacheData> custom({
    Expression<String>? symbol,
    Expression<double>? priceUsd,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (priceUsd != null) 'price_usd': priceUsd,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriceCacheCompanion copyWith({
    Value<String>? symbol,
    Value<double>? priceUsd,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return PriceCacheCompanion(
      symbol: symbol ?? this.symbol,
      priceUsd: priceUsd ?? this.priceUsd,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (priceUsd.present) {
      map['price_usd'] = Variable<double>(priceUsd.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceCacheCompanion(')
          ..write('symbol: $symbol, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CounterpartiesTable extends Counterparties
    with TableInfo<$CounterpartiesTable, Counterparty> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CounterpartiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'counterparties';
  @override
  VerificationContext validateIntegrity(
    Insertable<Counterparty> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Counterparty map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Counterparty(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $CounterpartiesTable createAlias(String alias) {
    return $CounterpartiesTable(attachedDatabase, alias);
  }
}

class Counterparty extends DataClass implements Insertable<Counterparty> {
  final String id;
  final String name;
  const Counterparty({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  CounterpartiesCompanion toCompanion(bool nullToAbsent) {
    return CounterpartiesCompanion(id: Value(id), name: Value(name));
  }

  factory Counterparty.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Counterparty(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Counterparty copyWith({String? id, String? name}) =>
      Counterparty(id: id ?? this.id, name: name ?? this.name);
  Counterparty copyWithCompanion(CounterpartiesCompanion data) {
    return Counterparty(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Counterparty(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Counterparty && other.id == this.id && other.name == this.name);
}

class CounterpartiesCompanion extends UpdateCompanion<Counterparty> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rowid;
  const CounterpartiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CounterpartiesCompanion.insert({
    required String id,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Counterparty> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CounterpartiesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return CounterpartiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CounterpartiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerTransactionsTable extends LedgerTransactions
    with TableInfo<$LedgerTransactionsTable, LedgerTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterpartyIdMeta = const VerificationMeta(
    'counterpartyId',
  );
  @override
  late final GeneratedColumn<String> counterpartyId = GeneratedColumn<String>(
    'counterparty_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES counterparties (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    counterpartyId,
    date,
    amount,
    currency,
    category,
    description,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('counterparty_id')) {
      context.handle(
        _counterpartyIdMeta,
        counterpartyId.isAcceptableOrUnknown(
          data['counterparty_id']!,
          _counterpartyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_counterpartyIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      counterpartyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LedgerTransactionsTable createAlias(String alias) {
    return $LedgerTransactionsTable(attachedDatabase, alias);
  }
}

class LedgerTransaction extends DataClass
    implements Insertable<LedgerTransaction> {
  final String id;
  final String counterpartyId;
  final DateTime date;
  final double amount;

  /// Currency [amount] was entered in (EGP/USD/EUR/SAR/AED/TRY). Balances
  /// and monthly totals convert everything to EGP via live FX for a single
  /// aggregate figure; the original currency is kept for display.
  final String currency;
  final String category;
  final String? description;
  final DateTime createdAt;
  const LedgerTransaction({
    required this.id,
    required this.counterpartyId,
    required this.date,
    required this.amount,
    required this.currency,
    required this.category,
    this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['counterparty_id'] = Variable<String>(counterpartyId);
    map['date'] = Variable<DateTime>(date);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LedgerTransactionsCompanion toCompanion(bool nullToAbsent) {
    return LedgerTransactionsCompanion(
      id: Value(id),
      counterpartyId: Value(counterpartyId),
      date: Value(date),
      amount: Value(amount),
      currency: Value(currency),
      category: Value(category),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory LedgerTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerTransaction(
      id: serializer.fromJson<String>(json['id']),
      counterpartyId: serializer.fromJson<String>(json['counterpartyId']),
      date: serializer.fromJson<DateTime>(json['date']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'counterpartyId': serializer.toJson<String>(counterpartyId),
      'date': serializer.toJson<DateTime>(date),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LedgerTransaction copyWith({
    String? id,
    String? counterpartyId,
    DateTime? date,
    double? amount,
    String? currency,
    String? category,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
  }) => LedgerTransaction(
    id: id ?? this.id,
    counterpartyId: counterpartyId ?? this.counterpartyId,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    category: category ?? this.category,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  LedgerTransaction copyWithCompanion(LedgerTransactionsCompanion data) {
    return LedgerTransaction(
      id: data.id.present ? data.id.value : this.id,
      counterpartyId: data.counterpartyId.present
          ? data.counterpartyId.value
          : this.counterpartyId,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerTransaction(')
          ..write('id: $id, ')
          ..write('counterpartyId: $counterpartyId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    counterpartyId,
    date,
    amount,
    currency,
    category,
    description,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerTransaction &&
          other.id == this.id &&
          other.counterpartyId == this.counterpartyId &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.category == this.category &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class LedgerTransactionsCompanion extends UpdateCompanion<LedgerTransaction> {
  final Value<String> id;
  final Value<String> counterpartyId;
  final Value<DateTime> date;
  final Value<double> amount;
  final Value<String> currency;
  final Value<String> category;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LedgerTransactionsCompanion({
    this.id = const Value.absent(),
    this.counterpartyId = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerTransactionsCompanion.insert({
    required String id,
    required String counterpartyId,
    required DateTime date,
    required double amount,
    this.currency = const Value.absent(),
    required String category,
    this.description = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       counterpartyId = Value(counterpartyId),
       date = Value(date),
       amount = Value(amount),
       category = Value(category),
       createdAt = Value(createdAt);
  static Insertable<LedgerTransaction> custom({
    Expression<String>? id,
    Expression<String>? counterpartyId,
    Expression<DateTime>? date,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<String>? category,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (counterpartyId != null) 'counterparty_id': counterpartyId,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? counterpartyId,
    Value<DateTime>? date,
    Value<double>? amount,
    Value<String>? currency,
    Value<String>? category,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LedgerTransactionsCompanion(
      id: id ?? this.id,
      counterpartyId: counterpartyId ?? this.counterpartyId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (counterpartyId.present) {
      map['counterparty_id'] = Variable<String>(counterpartyId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('counterpartyId: $counterpartyId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final String key;
  final String value;
  const SyncMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(key: Value(key), value: Value(value));
  }

  factory SyncMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncMetaData copyWith({String? key, String? value}) =>
      SyncMetaData(key: key ?? this.key, value: value ?? this.value);
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalculatorInputsTable extends CalculatorInputs
    with TableInfo<$CalculatorInputsTable, CalculatorInput> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalculatorInputsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calculator_inputs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalculatorInput> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CalculatorInput map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalculatorInput(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CalculatorInputsTable createAlias(String alias) {
    return $CalculatorInputsTable(attachedDatabase, alias);
  }
}

class CalculatorInput extends DataClass implements Insertable<CalculatorInput> {
  final String key;
  final double value;
  final DateTime updatedAt;
  const CalculatorInput({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<double>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CalculatorInputsCompanion toCompanion(bool nullToAbsent) {
    return CalculatorInputsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalculatorInput.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalculatorInput(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<double>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<double>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CalculatorInput copyWith({String? key, double? value, DateTime? updatedAt}) =>
      CalculatorInput(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CalculatorInput copyWithCompanion(CalculatorInputsCompanion data) {
    return CalculatorInput(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalculatorInput(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalculatorInput &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class CalculatorInputsCompanion extends UpdateCompanion<CalculatorInput> {
  final Value<String> key;
  final Value<double> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CalculatorInputsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalculatorInputsCompanion.insert({
    required String key,
    required double value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<CalculatorInput> custom({
    Expression<String>? key,
    Expression<double>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalculatorInputsCompanion copyWith({
    Value<String>? key,
    Value<double>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CalculatorInputsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalculatorInputsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VendorRulesTable extends VendorRules
    with TableInfo<$VendorRulesTable, VendorRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VendorRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vendorPatternMeta = const VerificationMeta(
    'vendorPattern',
  );
  @override
  late final GeneratedColumn<String> vendorPattern = GeneratedColumn<String>(
    'vendor_pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterpartyIdMeta = const VerificationMeta(
    'counterpartyId',
  );
  @override
  late final GeneratedColumn<String> counterpartyId = GeneratedColumn<String>(
    'counterparty_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES counterparties (id)',
    ),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vendorPattern,
    counterpartyId,
    category,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vendor_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<VendorRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vendor_pattern')) {
      context.handle(
        _vendorPatternMeta,
        vendorPattern.isAcceptableOrUnknown(
          data['vendor_pattern']!,
          _vendorPatternMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vendorPatternMeta);
    }
    if (data.containsKey('counterparty_id')) {
      context.handle(
        _counterpartyIdMeta,
        counterpartyId.isAcceptableOrUnknown(
          data['counterparty_id']!,
          _counterpartyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_counterpartyIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VendorRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VendorRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vendorPattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_pattern'],
      )!,
      counterpartyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
    );
  }

  @override
  $VendorRulesTable createAlias(String alias) {
    return $VendorRulesTable(attachedDatabase, alias);
  }
}

class VendorRule extends DataClass implements Insertable<VendorRule> {
  final String id;
  final String vendorPattern;
  final String counterpartyId;
  final String category;
  const VendorRule({
    required this.id,
    required this.vendorPattern,
    required this.counterpartyId,
    required this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vendor_pattern'] = Variable<String>(vendorPattern);
    map['counterparty_id'] = Variable<String>(counterpartyId);
    map['category'] = Variable<String>(category);
    return map;
  }

  VendorRulesCompanion toCompanion(bool nullToAbsent) {
    return VendorRulesCompanion(
      id: Value(id),
      vendorPattern: Value(vendorPattern),
      counterpartyId: Value(counterpartyId),
      category: Value(category),
    );
  }

  factory VendorRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VendorRule(
      id: serializer.fromJson<String>(json['id']),
      vendorPattern: serializer.fromJson<String>(json['vendorPattern']),
      counterpartyId: serializer.fromJson<String>(json['counterpartyId']),
      category: serializer.fromJson<String>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vendorPattern': serializer.toJson<String>(vendorPattern),
      'counterpartyId': serializer.toJson<String>(counterpartyId),
      'category': serializer.toJson<String>(category),
    };
  }

  VendorRule copyWith({
    String? id,
    String? vendorPattern,
    String? counterpartyId,
    String? category,
  }) => VendorRule(
    id: id ?? this.id,
    vendorPattern: vendorPattern ?? this.vendorPattern,
    counterpartyId: counterpartyId ?? this.counterpartyId,
    category: category ?? this.category,
  );
  VendorRule copyWithCompanion(VendorRulesCompanion data) {
    return VendorRule(
      id: data.id.present ? data.id.value : this.id,
      vendorPattern: data.vendorPattern.present
          ? data.vendorPattern.value
          : this.vendorPattern,
      counterpartyId: data.counterpartyId.present
          ? data.counterpartyId.value
          : this.counterpartyId,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VendorRule(')
          ..write('id: $id, ')
          ..write('vendorPattern: $vendorPattern, ')
          ..write('counterpartyId: $counterpartyId, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, vendorPattern, counterpartyId, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VendorRule &&
          other.id == this.id &&
          other.vendorPattern == this.vendorPattern &&
          other.counterpartyId == this.counterpartyId &&
          other.category == this.category);
}

class VendorRulesCompanion extends UpdateCompanion<VendorRule> {
  final Value<String> id;
  final Value<String> vendorPattern;
  final Value<String> counterpartyId;
  final Value<String> category;
  final Value<int> rowid;
  const VendorRulesCompanion({
    this.id = const Value.absent(),
    this.vendorPattern = const Value.absent(),
    this.counterpartyId = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VendorRulesCompanion.insert({
    required String id,
    required String vendorPattern,
    required String counterpartyId,
    required String category,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vendorPattern = Value(vendorPattern),
       counterpartyId = Value(counterpartyId),
       category = Value(category);
  static Insertable<VendorRule> custom({
    Expression<String>? id,
    Expression<String>? vendorPattern,
    Expression<String>? counterpartyId,
    Expression<String>? category,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vendorPattern != null) 'vendor_pattern': vendorPattern,
      if (counterpartyId != null) 'counterparty_id': counterpartyId,
      if (category != null) 'category': category,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VendorRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? vendorPattern,
    Value<String>? counterpartyId,
    Value<String>? category,
    Value<int>? rowid,
  }) {
    return VendorRulesCompanion(
      id: id ?? this.id,
      vendorPattern: vendorPattern ?? this.vendorPattern,
      counterpartyId: counterpartyId ?? this.counterpartyId,
      category: category ?? this.category,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vendorPattern.present) {
      map['vendor_pattern'] = Variable<String>(vendorPattern.value);
    }
    if (counterpartyId.present) {
      map['counterparty_id'] = Variable<String>(counterpartyId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VendorRulesCompanion(')
          ..write('id: $id, ')
          ..write('vendorPattern: $vendorPattern, ')
          ..write('counterpartyId: $counterpartyId, ')
          ..write('category: $category, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalculatorSnapshotsTable extends CalculatorSnapshots
    with TableInfo<$CalculatorSnapshotsTable, CalculatorSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalculatorSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
    'computed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultAmountMeta = const VerificationMeta(
    'resultAmount',
  );
  @override
  late final GeneratedColumn<double> resultAmount = GeneratedColumn<double>(
    'result_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ledgersTotalMeta = const VerificationMeta(
    'ledgersTotal',
  );
  @override
  late final GeneratedColumn<double> ledgersTotal = GeneratedColumn<double>(
    'ledgers_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apartmentSavingsMeta = const VerificationMeta(
    'apartmentSavings',
  );
  @override
  late final GeneratedColumn<double> apartmentSavings = GeneratedColumn<double>(
    'apartment_savings',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cibAccountBalanceMeta = const VerificationMeta(
    'cibAccountBalance',
  );
  @override
  late final GeneratedColumn<double> cibAccountBalance =
      GeneratedColumn<double>(
        'cib_account_balance',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _nbeAvailableMeta = const VerificationMeta(
    'nbeAvailable',
  );
  @override
  late final GeneratedColumn<double> nbeAvailable = GeneratedColumn<double>(
    'nbe_available',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nbeOwedMeta = const VerificationMeta(
    'nbeOwed',
  );
  @override
  late final GeneratedColumn<double> nbeOwed = GeneratedColumn<double>(
    'nbe_owed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cibExplorerWalletAvailableMeta =
      const VerificationMeta('cibExplorerWalletAvailable');
  @override
  late final GeneratedColumn<double> cibExplorerWalletAvailable =
      GeneratedColumn<double>(
        'cib_explorer_wallet_available',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _cibExplorerWalletOwedMeta =
      const VerificationMeta('cibExplorerWalletOwed');
  @override
  late final GeneratedColumn<double> cibExplorerWalletOwed =
      GeneratedColumn<double>(
        'cib_explorer_wallet_owed',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _cibPlatinumAvailableMeta =
      const VerificationMeta('cibPlatinumAvailable');
  @override
  late final GeneratedColumn<double> cibPlatinumAvailable =
      GeneratedColumn<double>(
        'cib_platinum_available',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _cibPlatinumOwedMeta = const VerificationMeta(
    'cibPlatinumOwed',
  );
  @override
  late final GeneratedColumn<double> cibPlatinumOwed = GeneratedColumn<double>(
    'cib_platinum_owed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customItemsJsonMeta = const VerificationMeta(
    'customItemsJson',
  );
  @override
  late final GeneratedColumn<String> customItemsJson = GeneratedColumn<String>(
    'custom_items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _cardEntriesJsonMeta = const VerificationMeta(
    'cardEntriesJson',
  );
  @override
  late final GeneratedColumn<String> cardEntriesJson = GeneratedColumn<String>(
    'card_entries_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    computedAt,
    resultAmount,
    ledgersTotal,
    apartmentSavings,
    cibAccountBalance,
    nbeAvailable,
    nbeOwed,
    cibExplorerWalletAvailable,
    cibExplorerWalletOwed,
    cibPlatinumAvailable,
    cibPlatinumOwed,
    customItemsJson,
    cardEntriesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calculator_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalculatorSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    if (data.containsKey('result_amount')) {
      context.handle(
        _resultAmountMeta,
        resultAmount.isAcceptableOrUnknown(
          data['result_amount']!,
          _resultAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resultAmountMeta);
    }
    if (data.containsKey('ledgers_total')) {
      context.handle(
        _ledgersTotalMeta,
        ledgersTotal.isAcceptableOrUnknown(
          data['ledgers_total']!,
          _ledgersTotalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ledgersTotalMeta);
    }
    if (data.containsKey('apartment_savings')) {
      context.handle(
        _apartmentSavingsMeta,
        apartmentSavings.isAcceptableOrUnknown(
          data['apartment_savings']!,
          _apartmentSavingsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_apartmentSavingsMeta);
    }
    if (data.containsKey('cib_account_balance')) {
      context.handle(
        _cibAccountBalanceMeta,
        cibAccountBalance.isAcceptableOrUnknown(
          data['cib_account_balance']!,
          _cibAccountBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cibAccountBalanceMeta);
    }
    if (data.containsKey('nbe_available')) {
      context.handle(
        _nbeAvailableMeta,
        nbeAvailable.isAcceptableOrUnknown(
          data['nbe_available']!,
          _nbeAvailableMeta,
        ),
      );
    }
    if (data.containsKey('nbe_owed')) {
      context.handle(
        _nbeOwedMeta,
        nbeOwed.isAcceptableOrUnknown(data['nbe_owed']!, _nbeOwedMeta),
      );
    }
    if (data.containsKey('cib_explorer_wallet_available')) {
      context.handle(
        _cibExplorerWalletAvailableMeta,
        cibExplorerWalletAvailable.isAcceptableOrUnknown(
          data['cib_explorer_wallet_available']!,
          _cibExplorerWalletAvailableMeta,
        ),
      );
    }
    if (data.containsKey('cib_explorer_wallet_owed')) {
      context.handle(
        _cibExplorerWalletOwedMeta,
        cibExplorerWalletOwed.isAcceptableOrUnknown(
          data['cib_explorer_wallet_owed']!,
          _cibExplorerWalletOwedMeta,
        ),
      );
    }
    if (data.containsKey('cib_platinum_available')) {
      context.handle(
        _cibPlatinumAvailableMeta,
        cibPlatinumAvailable.isAcceptableOrUnknown(
          data['cib_platinum_available']!,
          _cibPlatinumAvailableMeta,
        ),
      );
    }
    if (data.containsKey('cib_platinum_owed')) {
      context.handle(
        _cibPlatinumOwedMeta,
        cibPlatinumOwed.isAcceptableOrUnknown(
          data['cib_platinum_owed']!,
          _cibPlatinumOwedMeta,
        ),
      );
    }
    if (data.containsKey('custom_items_json')) {
      context.handle(
        _customItemsJsonMeta,
        customItemsJson.isAcceptableOrUnknown(
          data['custom_items_json']!,
          _customItemsJsonMeta,
        ),
      );
    }
    if (data.containsKey('card_entries_json')) {
      context.handle(
        _cardEntriesJsonMeta,
        cardEntriesJson.isAcceptableOrUnknown(
          data['card_entries_json']!,
          _cardEntriesJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalculatorSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalculatorSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}computed_at'],
      )!,
      resultAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}result_amount'],
      )!,
      ledgersTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ledgers_total'],
      )!,
      apartmentSavings: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}apartment_savings'],
      )!,
      cibAccountBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cib_account_balance'],
      )!,
      nbeAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}nbe_available'],
      )!,
      nbeOwed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}nbe_owed'],
      )!,
      cibExplorerWalletAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cib_explorer_wallet_available'],
      )!,
      cibExplorerWalletOwed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cib_explorer_wallet_owed'],
      )!,
      cibPlatinumAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cib_platinum_available'],
      )!,
      cibPlatinumOwed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cib_platinum_owed'],
      )!,
      customItemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_items_json'],
      )!,
      cardEntriesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_entries_json'],
      )!,
    );
  }

  @override
  $CalculatorSnapshotsTable createAlias(String alias) {
    return $CalculatorSnapshotsTable(attachedDatabase, alias);
  }
}

class CalculatorSnapshot extends DataClass
    implements Insertable<CalculatorSnapshot> {
  final String id;
  final DateTime computedAt;
  final double resultAmount;
  final double ledgersTotal;
  final double apartmentSavings;
  final double cibAccountBalance;
  final double nbeAvailable;
  final double nbeOwed;
  final double cibExplorerWalletAvailable;
  final double cibExplorerWalletOwed;
  final double cibPlatinumAvailable;
  final double cibPlatinumOwed;

  /// JSON-encoded list of `{label, amount, isAddition}` custom line items.
  final String customItemsJson;

  /// JSON-encoded list of per-card entries — see class doc. Empty list
  /// (`'[]'`, the default) on every snapshot saved before user-managed
  /// cards existed; the fixed nbe/cib* columns above carry those instead.
  final String cardEntriesJson;
  const CalculatorSnapshot({
    required this.id,
    required this.computedAt,
    required this.resultAmount,
    required this.ledgersTotal,
    required this.apartmentSavings,
    required this.cibAccountBalance,
    required this.nbeAvailable,
    required this.nbeOwed,
    required this.cibExplorerWalletAvailable,
    required this.cibExplorerWalletOwed,
    required this.cibPlatinumAvailable,
    required this.cibPlatinumOwed,
    required this.customItemsJson,
    required this.cardEntriesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['computed_at'] = Variable<DateTime>(computedAt);
    map['result_amount'] = Variable<double>(resultAmount);
    map['ledgers_total'] = Variable<double>(ledgersTotal);
    map['apartment_savings'] = Variable<double>(apartmentSavings);
    map['cib_account_balance'] = Variable<double>(cibAccountBalance);
    map['nbe_available'] = Variable<double>(nbeAvailable);
    map['nbe_owed'] = Variable<double>(nbeOwed);
    map['cib_explorer_wallet_available'] = Variable<double>(
      cibExplorerWalletAvailable,
    );
    map['cib_explorer_wallet_owed'] = Variable<double>(cibExplorerWalletOwed);
    map['cib_platinum_available'] = Variable<double>(cibPlatinumAvailable);
    map['cib_platinum_owed'] = Variable<double>(cibPlatinumOwed);
    map['custom_items_json'] = Variable<String>(customItemsJson);
    map['card_entries_json'] = Variable<String>(cardEntriesJson);
    return map;
  }

  CalculatorSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return CalculatorSnapshotsCompanion(
      id: Value(id),
      computedAt: Value(computedAt),
      resultAmount: Value(resultAmount),
      ledgersTotal: Value(ledgersTotal),
      apartmentSavings: Value(apartmentSavings),
      cibAccountBalance: Value(cibAccountBalance),
      nbeAvailable: Value(nbeAvailable),
      nbeOwed: Value(nbeOwed),
      cibExplorerWalletAvailable: Value(cibExplorerWalletAvailable),
      cibExplorerWalletOwed: Value(cibExplorerWalletOwed),
      cibPlatinumAvailable: Value(cibPlatinumAvailable),
      cibPlatinumOwed: Value(cibPlatinumOwed),
      customItemsJson: Value(customItemsJson),
      cardEntriesJson: Value(cardEntriesJson),
    );
  }

  factory CalculatorSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalculatorSnapshot(
      id: serializer.fromJson<String>(json['id']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
      resultAmount: serializer.fromJson<double>(json['resultAmount']),
      ledgersTotal: serializer.fromJson<double>(json['ledgersTotal']),
      apartmentSavings: serializer.fromJson<double>(json['apartmentSavings']),
      cibAccountBalance: serializer.fromJson<double>(json['cibAccountBalance']),
      nbeAvailable: serializer.fromJson<double>(json['nbeAvailable']),
      nbeOwed: serializer.fromJson<double>(json['nbeOwed']),
      cibExplorerWalletAvailable: serializer.fromJson<double>(
        json['cibExplorerWalletAvailable'],
      ),
      cibExplorerWalletOwed: serializer.fromJson<double>(
        json['cibExplorerWalletOwed'],
      ),
      cibPlatinumAvailable: serializer.fromJson<double>(
        json['cibPlatinumAvailable'],
      ),
      cibPlatinumOwed: serializer.fromJson<double>(json['cibPlatinumOwed']),
      customItemsJson: serializer.fromJson<String>(json['customItemsJson']),
      cardEntriesJson: serializer.fromJson<String>(json['cardEntriesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'computedAt': serializer.toJson<DateTime>(computedAt),
      'resultAmount': serializer.toJson<double>(resultAmount),
      'ledgersTotal': serializer.toJson<double>(ledgersTotal),
      'apartmentSavings': serializer.toJson<double>(apartmentSavings),
      'cibAccountBalance': serializer.toJson<double>(cibAccountBalance),
      'nbeAvailable': serializer.toJson<double>(nbeAvailable),
      'nbeOwed': serializer.toJson<double>(nbeOwed),
      'cibExplorerWalletAvailable': serializer.toJson<double>(
        cibExplorerWalletAvailable,
      ),
      'cibExplorerWalletOwed': serializer.toJson<double>(cibExplorerWalletOwed),
      'cibPlatinumAvailable': serializer.toJson<double>(cibPlatinumAvailable),
      'cibPlatinumOwed': serializer.toJson<double>(cibPlatinumOwed),
      'customItemsJson': serializer.toJson<String>(customItemsJson),
      'cardEntriesJson': serializer.toJson<String>(cardEntriesJson),
    };
  }

  CalculatorSnapshot copyWith({
    String? id,
    DateTime? computedAt,
    double? resultAmount,
    double? ledgersTotal,
    double? apartmentSavings,
    double? cibAccountBalance,
    double? nbeAvailable,
    double? nbeOwed,
    double? cibExplorerWalletAvailable,
    double? cibExplorerWalletOwed,
    double? cibPlatinumAvailable,
    double? cibPlatinumOwed,
    String? customItemsJson,
    String? cardEntriesJson,
  }) => CalculatorSnapshot(
    id: id ?? this.id,
    computedAt: computedAt ?? this.computedAt,
    resultAmount: resultAmount ?? this.resultAmount,
    ledgersTotal: ledgersTotal ?? this.ledgersTotal,
    apartmentSavings: apartmentSavings ?? this.apartmentSavings,
    cibAccountBalance: cibAccountBalance ?? this.cibAccountBalance,
    nbeAvailable: nbeAvailable ?? this.nbeAvailable,
    nbeOwed: nbeOwed ?? this.nbeOwed,
    cibExplorerWalletAvailable:
        cibExplorerWalletAvailable ?? this.cibExplorerWalletAvailable,
    cibExplorerWalletOwed: cibExplorerWalletOwed ?? this.cibExplorerWalletOwed,
    cibPlatinumAvailable: cibPlatinumAvailable ?? this.cibPlatinumAvailable,
    cibPlatinumOwed: cibPlatinumOwed ?? this.cibPlatinumOwed,
    customItemsJson: customItemsJson ?? this.customItemsJson,
    cardEntriesJson: cardEntriesJson ?? this.cardEntriesJson,
  );
  CalculatorSnapshot copyWithCompanion(CalculatorSnapshotsCompanion data) {
    return CalculatorSnapshot(
      id: data.id.present ? data.id.value : this.id,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
      resultAmount: data.resultAmount.present
          ? data.resultAmount.value
          : this.resultAmount,
      ledgersTotal: data.ledgersTotal.present
          ? data.ledgersTotal.value
          : this.ledgersTotal,
      apartmentSavings: data.apartmentSavings.present
          ? data.apartmentSavings.value
          : this.apartmentSavings,
      cibAccountBalance: data.cibAccountBalance.present
          ? data.cibAccountBalance.value
          : this.cibAccountBalance,
      nbeAvailable: data.nbeAvailable.present
          ? data.nbeAvailable.value
          : this.nbeAvailable,
      nbeOwed: data.nbeOwed.present ? data.nbeOwed.value : this.nbeOwed,
      cibExplorerWalletAvailable: data.cibExplorerWalletAvailable.present
          ? data.cibExplorerWalletAvailable.value
          : this.cibExplorerWalletAvailable,
      cibExplorerWalletOwed: data.cibExplorerWalletOwed.present
          ? data.cibExplorerWalletOwed.value
          : this.cibExplorerWalletOwed,
      cibPlatinumAvailable: data.cibPlatinumAvailable.present
          ? data.cibPlatinumAvailable.value
          : this.cibPlatinumAvailable,
      cibPlatinumOwed: data.cibPlatinumOwed.present
          ? data.cibPlatinumOwed.value
          : this.cibPlatinumOwed,
      customItemsJson: data.customItemsJson.present
          ? data.customItemsJson.value
          : this.customItemsJson,
      cardEntriesJson: data.cardEntriesJson.present
          ? data.cardEntriesJson.value
          : this.cardEntriesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalculatorSnapshot(')
          ..write('id: $id, ')
          ..write('computedAt: $computedAt, ')
          ..write('resultAmount: $resultAmount, ')
          ..write('ledgersTotal: $ledgersTotal, ')
          ..write('apartmentSavings: $apartmentSavings, ')
          ..write('cibAccountBalance: $cibAccountBalance, ')
          ..write('nbeAvailable: $nbeAvailable, ')
          ..write('nbeOwed: $nbeOwed, ')
          ..write('cibExplorerWalletAvailable: $cibExplorerWalletAvailable, ')
          ..write('cibExplorerWalletOwed: $cibExplorerWalletOwed, ')
          ..write('cibPlatinumAvailable: $cibPlatinumAvailable, ')
          ..write('cibPlatinumOwed: $cibPlatinumOwed, ')
          ..write('customItemsJson: $customItemsJson, ')
          ..write('cardEntriesJson: $cardEntriesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    computedAt,
    resultAmount,
    ledgersTotal,
    apartmentSavings,
    cibAccountBalance,
    nbeAvailable,
    nbeOwed,
    cibExplorerWalletAvailable,
    cibExplorerWalletOwed,
    cibPlatinumAvailable,
    cibPlatinumOwed,
    customItemsJson,
    cardEntriesJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalculatorSnapshot &&
          other.id == this.id &&
          other.computedAt == this.computedAt &&
          other.resultAmount == this.resultAmount &&
          other.ledgersTotal == this.ledgersTotal &&
          other.apartmentSavings == this.apartmentSavings &&
          other.cibAccountBalance == this.cibAccountBalance &&
          other.nbeAvailable == this.nbeAvailable &&
          other.nbeOwed == this.nbeOwed &&
          other.cibExplorerWalletAvailable == this.cibExplorerWalletAvailable &&
          other.cibExplorerWalletOwed == this.cibExplorerWalletOwed &&
          other.cibPlatinumAvailable == this.cibPlatinumAvailable &&
          other.cibPlatinumOwed == this.cibPlatinumOwed &&
          other.customItemsJson == this.customItemsJson &&
          other.cardEntriesJson == this.cardEntriesJson);
}

class CalculatorSnapshotsCompanion extends UpdateCompanion<CalculatorSnapshot> {
  final Value<String> id;
  final Value<DateTime> computedAt;
  final Value<double> resultAmount;
  final Value<double> ledgersTotal;
  final Value<double> apartmentSavings;
  final Value<double> cibAccountBalance;
  final Value<double> nbeAvailable;
  final Value<double> nbeOwed;
  final Value<double> cibExplorerWalletAvailable;
  final Value<double> cibExplorerWalletOwed;
  final Value<double> cibPlatinumAvailable;
  final Value<double> cibPlatinumOwed;
  final Value<String> customItemsJson;
  final Value<String> cardEntriesJson;
  final Value<int> rowid;
  const CalculatorSnapshotsCompanion({
    this.id = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.resultAmount = const Value.absent(),
    this.ledgersTotal = const Value.absent(),
    this.apartmentSavings = const Value.absent(),
    this.cibAccountBalance = const Value.absent(),
    this.nbeAvailable = const Value.absent(),
    this.nbeOwed = const Value.absent(),
    this.cibExplorerWalletAvailable = const Value.absent(),
    this.cibExplorerWalletOwed = const Value.absent(),
    this.cibPlatinumAvailable = const Value.absent(),
    this.cibPlatinumOwed = const Value.absent(),
    this.customItemsJson = const Value.absent(),
    this.cardEntriesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalculatorSnapshotsCompanion.insert({
    required String id,
    required DateTime computedAt,
    required double resultAmount,
    required double ledgersTotal,
    required double apartmentSavings,
    required double cibAccountBalance,
    this.nbeAvailable = const Value.absent(),
    this.nbeOwed = const Value.absent(),
    this.cibExplorerWalletAvailable = const Value.absent(),
    this.cibExplorerWalletOwed = const Value.absent(),
    this.cibPlatinumAvailable = const Value.absent(),
    this.cibPlatinumOwed = const Value.absent(),
    this.customItemsJson = const Value.absent(),
    this.cardEntriesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       computedAt = Value(computedAt),
       resultAmount = Value(resultAmount),
       ledgersTotal = Value(ledgersTotal),
       apartmentSavings = Value(apartmentSavings),
       cibAccountBalance = Value(cibAccountBalance);
  static Insertable<CalculatorSnapshot> custom({
    Expression<String>? id,
    Expression<DateTime>? computedAt,
    Expression<double>? resultAmount,
    Expression<double>? ledgersTotal,
    Expression<double>? apartmentSavings,
    Expression<double>? cibAccountBalance,
    Expression<double>? nbeAvailable,
    Expression<double>? nbeOwed,
    Expression<double>? cibExplorerWalletAvailable,
    Expression<double>? cibExplorerWalletOwed,
    Expression<double>? cibPlatinumAvailable,
    Expression<double>? cibPlatinumOwed,
    Expression<String>? customItemsJson,
    Expression<String>? cardEntriesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (computedAt != null) 'computed_at': computedAt,
      if (resultAmount != null) 'result_amount': resultAmount,
      if (ledgersTotal != null) 'ledgers_total': ledgersTotal,
      if (apartmentSavings != null) 'apartment_savings': apartmentSavings,
      if (cibAccountBalance != null) 'cib_account_balance': cibAccountBalance,
      if (nbeAvailable != null) 'nbe_available': nbeAvailable,
      if (nbeOwed != null) 'nbe_owed': nbeOwed,
      if (cibExplorerWalletAvailable != null)
        'cib_explorer_wallet_available': cibExplorerWalletAvailable,
      if (cibExplorerWalletOwed != null)
        'cib_explorer_wallet_owed': cibExplorerWalletOwed,
      if (cibPlatinumAvailable != null)
        'cib_platinum_available': cibPlatinumAvailable,
      if (cibPlatinumOwed != null) 'cib_platinum_owed': cibPlatinumOwed,
      if (customItemsJson != null) 'custom_items_json': customItemsJson,
      if (cardEntriesJson != null) 'card_entries_json': cardEntriesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalculatorSnapshotsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? computedAt,
    Value<double>? resultAmount,
    Value<double>? ledgersTotal,
    Value<double>? apartmentSavings,
    Value<double>? cibAccountBalance,
    Value<double>? nbeAvailable,
    Value<double>? nbeOwed,
    Value<double>? cibExplorerWalletAvailable,
    Value<double>? cibExplorerWalletOwed,
    Value<double>? cibPlatinumAvailable,
    Value<double>? cibPlatinumOwed,
    Value<String>? customItemsJson,
    Value<String>? cardEntriesJson,
    Value<int>? rowid,
  }) {
    return CalculatorSnapshotsCompanion(
      id: id ?? this.id,
      computedAt: computedAt ?? this.computedAt,
      resultAmount: resultAmount ?? this.resultAmount,
      ledgersTotal: ledgersTotal ?? this.ledgersTotal,
      apartmentSavings: apartmentSavings ?? this.apartmentSavings,
      cibAccountBalance: cibAccountBalance ?? this.cibAccountBalance,
      nbeAvailable: nbeAvailable ?? this.nbeAvailable,
      nbeOwed: nbeOwed ?? this.nbeOwed,
      cibExplorerWalletAvailable:
          cibExplorerWalletAvailable ?? this.cibExplorerWalletAvailable,
      cibExplorerWalletOwed:
          cibExplorerWalletOwed ?? this.cibExplorerWalletOwed,
      cibPlatinumAvailable: cibPlatinumAvailable ?? this.cibPlatinumAvailable,
      cibPlatinumOwed: cibPlatinumOwed ?? this.cibPlatinumOwed,
      customItemsJson: customItemsJson ?? this.customItemsJson,
      cardEntriesJson: cardEntriesJson ?? this.cardEntriesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    if (resultAmount.present) {
      map['result_amount'] = Variable<double>(resultAmount.value);
    }
    if (ledgersTotal.present) {
      map['ledgers_total'] = Variable<double>(ledgersTotal.value);
    }
    if (apartmentSavings.present) {
      map['apartment_savings'] = Variable<double>(apartmentSavings.value);
    }
    if (cibAccountBalance.present) {
      map['cib_account_balance'] = Variable<double>(cibAccountBalance.value);
    }
    if (nbeAvailable.present) {
      map['nbe_available'] = Variable<double>(nbeAvailable.value);
    }
    if (nbeOwed.present) {
      map['nbe_owed'] = Variable<double>(nbeOwed.value);
    }
    if (cibExplorerWalletAvailable.present) {
      map['cib_explorer_wallet_available'] = Variable<double>(
        cibExplorerWalletAvailable.value,
      );
    }
    if (cibExplorerWalletOwed.present) {
      map['cib_explorer_wallet_owed'] = Variable<double>(
        cibExplorerWalletOwed.value,
      );
    }
    if (cibPlatinumAvailable.present) {
      map['cib_platinum_available'] = Variable<double>(
        cibPlatinumAvailable.value,
      );
    }
    if (cibPlatinumOwed.present) {
      map['cib_platinum_owed'] = Variable<double>(cibPlatinumOwed.value);
    }
    if (customItemsJson.present) {
      map['custom_items_json'] = Variable<String>(customItemsJson.value);
    }
    if (cardEntriesJson.present) {
      map['card_entries_json'] = Variable<String>(cardEntriesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalculatorSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('computedAt: $computedAt, ')
          ..write('resultAmount: $resultAmount, ')
          ..write('ledgersTotal: $ledgersTotal, ')
          ..write('apartmentSavings: $apartmentSavings, ')
          ..write('cibAccountBalance: $cibAccountBalance, ')
          ..write('nbeAvailable: $nbeAvailable, ')
          ..write('nbeOwed: $nbeOwed, ')
          ..write('cibExplorerWalletAvailable: $cibExplorerWalletAvailable, ')
          ..write('cibExplorerWalletOwed: $cibExplorerWalletOwed, ')
          ..write('cibPlatinumAvailable: $cibPlatinumAvailable, ')
          ..write('cibPlatinumOwed: $cibPlatinumOwed, ')
          ..write('customItemsJson: $customItemsJson, ')
          ..write('cardEntriesJson: $cardEntriesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CreditCardsTable extends CreditCards
    with TableInfo<$CreditCardsTable, CreditCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankMeta = const VerificationMeta('bank');
  @override
  late final GeneratedColumn<String> bank = GeneratedColumn<String>(
    'bank',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitAmountMeta = const VerificationMeta(
    'limitAmount',
  );
  @override
  late final GeneratedColumn<double> limitAmount = GeneratedColumn<double>(
    'limit_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastFourDigitsMeta = const VerificationMeta(
    'lastFourDigits',
  );
  @override
  late final GeneratedColumn<String> lastFourDigits = GeneratedColumn<String>(
    'last_four_digits',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    bank,
    limitAmount,
    currency,
    sortOrder,
    lastFourDigits,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credit_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('bank')) {
      context.handle(
        _bankMeta,
        bank.isAcceptableOrUnknown(data['bank']!, _bankMeta),
      );
    } else if (isInserting) {
      context.missing(_bankMeta);
    }
    if (data.containsKey('limit_amount')) {
      context.handle(
        _limitAmountMeta,
        limitAmount.isAcceptableOrUnknown(
          data['limit_amount']!,
          _limitAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limitAmountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('last_four_digits')) {
      context.handle(
        _lastFourDigitsMeta,
        lastFourDigits.isAcceptableOrUnknown(
          data['last_four_digits']!,
          _lastFourDigitsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreditCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      bank: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank'],
      )!,
      limitAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}limit_amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      lastFourDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_four_digits'],
      ),
    );
  }

  @override
  $CreditCardsTable createAlias(String alias) {
    return $CreditCardsTable(attachedDatabase, alias);
  }
}

class CreditCard extends DataClass implements Insertable<CreditCard> {
  final String id;
  final String name;
  final String bank;
  final double limitAmount;
  final String currency;

  /// Manual ordering for display — set to insertion order by default, but
  /// not tied to it, so a future "reorder" gesture has somewhere to write.
  final int sortOrder;

  /// The last 4 digits printed on the card, as they appear in bank SMS
  /// alerts (e.g. "...ending in 4912") — lets a future SMS-based balance
  /// update know which card a given message is about. Optional; nothing
  /// reads this yet.
  final String? lastFourDigits;
  const CreditCard({
    required this.id,
    required this.name,
    required this.bank,
    required this.limitAmount,
    required this.currency,
    required this.sortOrder,
    this.lastFourDigits,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['bank'] = Variable<String>(bank);
    map['limit_amount'] = Variable<double>(limitAmount);
    map['currency'] = Variable<String>(currency);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || lastFourDigits != null) {
      map['last_four_digits'] = Variable<String>(lastFourDigits);
    }
    return map;
  }

  CreditCardsCompanion toCompanion(bool nullToAbsent) {
    return CreditCardsCompanion(
      id: Value(id),
      name: Value(name),
      bank: Value(bank),
      limitAmount: Value(limitAmount),
      currency: Value(currency),
      sortOrder: Value(sortOrder),
      lastFourDigits: lastFourDigits == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFourDigits),
    );
  }

  factory CreditCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditCard(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      bank: serializer.fromJson<String>(json['bank']),
      limitAmount: serializer.fromJson<double>(json['limitAmount']),
      currency: serializer.fromJson<String>(json['currency']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      lastFourDigits: serializer.fromJson<String?>(json['lastFourDigits']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'bank': serializer.toJson<String>(bank),
      'limitAmount': serializer.toJson<double>(limitAmount),
      'currency': serializer.toJson<String>(currency),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'lastFourDigits': serializer.toJson<String?>(lastFourDigits),
    };
  }

  CreditCard copyWith({
    String? id,
    String? name,
    String? bank,
    double? limitAmount,
    String? currency,
    int? sortOrder,
    Value<String?> lastFourDigits = const Value.absent(),
  }) => CreditCard(
    id: id ?? this.id,
    name: name ?? this.name,
    bank: bank ?? this.bank,
    limitAmount: limitAmount ?? this.limitAmount,
    currency: currency ?? this.currency,
    sortOrder: sortOrder ?? this.sortOrder,
    lastFourDigits: lastFourDigits.present
        ? lastFourDigits.value
        : this.lastFourDigits,
  );
  CreditCard copyWithCompanion(CreditCardsCompanion data) {
    return CreditCard(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      bank: data.bank.present ? data.bank.value : this.bank,
      limitAmount: data.limitAmount.present
          ? data.limitAmount.value
          : this.limitAmount,
      currency: data.currency.present ? data.currency.value : this.currency,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      lastFourDigits: data.lastFourDigits.present
          ? data.lastFourDigits.value
          : this.lastFourDigits,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditCard(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bank: $bank, ')
          ..write('limitAmount: $limitAmount, ')
          ..write('currency: $currency, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastFourDigits: $lastFourDigits')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    bank,
    limitAmount,
    currency,
    sortOrder,
    lastFourDigits,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditCard &&
          other.id == this.id &&
          other.name == this.name &&
          other.bank == this.bank &&
          other.limitAmount == this.limitAmount &&
          other.currency == this.currency &&
          other.sortOrder == this.sortOrder &&
          other.lastFourDigits == this.lastFourDigits);
}

class CreditCardsCompanion extends UpdateCompanion<CreditCard> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> bank;
  final Value<double> limitAmount;
  final Value<String> currency;
  final Value<int> sortOrder;
  final Value<String?> lastFourDigits;
  final Value<int> rowid;
  const CreditCardsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.bank = const Value.absent(),
    this.limitAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastFourDigits = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CreditCardsCompanion.insert({
    required String id,
    required String name,
    required String bank,
    required double limitAmount,
    this.currency = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastFourDigits = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       bank = Value(bank),
       limitAmount = Value(limitAmount);
  static Insertable<CreditCard> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? bank,
    Expression<double>? limitAmount,
    Expression<String>? currency,
    Expression<int>? sortOrder,
    Expression<String>? lastFourDigits,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (bank != null) 'bank': bank,
      if (limitAmount != null) 'limit_amount': limitAmount,
      if (currency != null) 'currency': currency,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (lastFourDigits != null) 'last_four_digits': lastFourDigits,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CreditCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? bank,
    Value<double>? limitAmount,
    Value<String>? currency,
    Value<int>? sortOrder,
    Value<String?>? lastFourDigits,
    Value<int>? rowid,
  }) {
    return CreditCardsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      bank: bank ?? this.bank,
      limitAmount: limitAmount ?? this.limitAmount,
      currency: currency ?? this.currency,
      sortOrder: sortOrder ?? this.sortOrder,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (bank.present) {
      map['bank'] = Variable<String>(bank.value);
    }
    if (limitAmount.present) {
      map['limit_amount'] = Variable<double>(limitAmount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (lastFourDigits.present) {
      map['last_four_digits'] = Variable<String>(lastFourDigits.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditCardsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bank: $bank, ')
          ..write('limitAmount: $limitAmount, ')
          ..write('currency: $currency, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastFourDigits: $lastFourDigits, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerCategoriesTable extends LedgerCategories
    with TableInfo<$LedgerCategoriesTable, LedgerCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $LedgerCategoriesTable createAlias(String alias) {
    return $LedgerCategoriesTable(attachedDatabase, alias);
  }
}

class LedgerCategory extends DataClass implements Insertable<LedgerCategory> {
  final String id;
  final String name;
  final int sortOrder;
  const LedgerCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  LedgerCategoriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory LedgerCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  LedgerCategory copyWith({String? id, String? name, int? sortOrder}) =>
      LedgerCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  LedgerCategory copyWithCompanion(LedgerCategoriesCompanion data) {
    return LedgerCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class LedgerCategoriesCompanion extends UpdateCompanion<LedgerCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const LedgerCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerCategoriesCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<LedgerCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return LedgerCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AssetsTable assets = $AssetsTable(this);
  late final $PriceCacheTable priceCache = $PriceCacheTable(this);
  late final $CounterpartiesTable counterparties = $CounterpartiesTable(this);
  late final $LedgerTransactionsTable ledgerTransactions =
      $LedgerTransactionsTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final $CalculatorInputsTable calculatorInputs = $CalculatorInputsTable(
    this,
  );
  late final $VendorRulesTable vendorRules = $VendorRulesTable(this);
  late final $CalculatorSnapshotsTable calculatorSnapshots =
      $CalculatorSnapshotsTable(this);
  late final $CreditCardsTable creditCards = $CreditCardsTable(this);
  late final $LedgerCategoriesTable ledgerCategories = $LedgerCategoriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    assets,
    priceCache,
    counterparties,
    ledgerTransactions,
    syncMeta,
    calculatorInputs,
    vendorRules,
    calculatorSnapshots,
    creditCards,
    ledgerCategories,
  ];
}

typedef $$AssetsTableCreateCompanionBuilder =
    AssetsCompanion Function({
      required String id,
      required String name,
      required String category,
      required String valuationMode,
      required double quantity,
      required String symbolOrCurrency,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AssetsTableUpdateCompanionBuilder =
    AssetsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
      Value<String> valuationMode,
      Value<double> quantity,
      Value<String> symbolOrCurrency,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AssetsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valuationMode => $composableBuilder(
    column: $table.valuationMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symbolOrCurrency => $composableBuilder(
    column: $table.symbolOrCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valuationMode => $composableBuilder(
    column: $table.valuationMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symbolOrCurrency => $composableBuilder(
    column: $table.symbolOrCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get valuationMode => $composableBuilder(
    column: $table.valuationMode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get symbolOrCurrency => $composableBuilder(
    column: $table.symbolOrCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetsTable,
          Asset,
          $$AssetsTableFilterComposer,
          $$AssetsTableOrderingComposer,
          $$AssetsTableAnnotationComposer,
          $$AssetsTableCreateCompanionBuilder,
          $$AssetsTableUpdateCompanionBuilder,
          (Asset, BaseReferences<_$AppDatabase, $AssetsTable, Asset>),
          Asset,
          PrefetchHooks Function()
        > {
  $$AssetsTableTableManager(_$AppDatabase db, $AssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> valuationMode = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> symbolOrCurrency = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion(
                id: id,
                name: name,
                category: category,
                valuationMode: valuationMode,
                quantity: quantity,
                symbolOrCurrency: symbolOrCurrency,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                required String valuationMode,
                required double quantity,
                required String symbolOrCurrency,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion.insert(
                id: id,
                name: name,
                category: category,
                valuationMode: valuationMode,
                quantity: quantity,
                symbolOrCurrency: symbolOrCurrency,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetsTable,
      Asset,
      $$AssetsTableFilterComposer,
      $$AssetsTableOrderingComposer,
      $$AssetsTableAnnotationComposer,
      $$AssetsTableCreateCompanionBuilder,
      $$AssetsTableUpdateCompanionBuilder,
      (Asset, BaseReferences<_$AppDatabase, $AssetsTable, Asset>),
      Asset,
      PrefetchHooks Function()
    >;
typedef $$PriceCacheTableCreateCompanionBuilder =
    PriceCacheCompanion Function({
      required String symbol,
      required double priceUsd,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$PriceCacheTableUpdateCompanionBuilder =
    PriceCacheCompanion Function({
      Value<String> symbol,
      Value<double> priceUsd,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$PriceCacheTableFilterComposer
    extends Composer<_$AppDatabase, $PriceCacheTable> {
  $$PriceCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceUsd => $composableBuilder(
    column: $table.priceUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PriceCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceCacheTable> {
  $$PriceCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceUsd => $composableBuilder(
    column: $table.priceUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PriceCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceCacheTable> {
  $$PriceCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<double> get priceUsd =>
      $composableBuilder(column: $table.priceUsd, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$PriceCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceCacheTable,
          PriceCacheData,
          $$PriceCacheTableFilterComposer,
          $$PriceCacheTableOrderingComposer,
          $$PriceCacheTableAnnotationComposer,
          $$PriceCacheTableCreateCompanionBuilder,
          $$PriceCacheTableUpdateCompanionBuilder,
          (
            PriceCacheData,
            BaseReferences<_$AppDatabase, $PriceCacheTable, PriceCacheData>,
          ),
          PriceCacheData,
          PrefetchHooks Function()
        > {
  $$PriceCacheTableTableManager(_$AppDatabase db, $PriceCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriceCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriceCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PriceCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> symbol = const Value.absent(),
                Value<double> priceUsd = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceCacheCompanion(
                symbol: symbol,
                priceUsd: priceUsd,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String symbol,
                required double priceUsd,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => PriceCacheCompanion.insert(
                symbol: symbol,
                priceUsd: priceUsd,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PriceCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceCacheTable,
      PriceCacheData,
      $$PriceCacheTableFilterComposer,
      $$PriceCacheTableOrderingComposer,
      $$PriceCacheTableAnnotationComposer,
      $$PriceCacheTableCreateCompanionBuilder,
      $$PriceCacheTableUpdateCompanionBuilder,
      (
        PriceCacheData,
        BaseReferences<_$AppDatabase, $PriceCacheTable, PriceCacheData>,
      ),
      PriceCacheData,
      PrefetchHooks Function()
    >;
typedef $$CounterpartiesTableCreateCompanionBuilder =
    CounterpartiesCompanion Function({
      required String id,
      required String name,
      Value<int> rowid,
    });
typedef $$CounterpartiesTableUpdateCompanionBuilder =
    CounterpartiesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> rowid,
    });

final class $$CounterpartiesTableReferences
    extends BaseReferences<_$AppDatabase, $CounterpartiesTable, Counterparty> {
  $$CounterpartiesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LedgerTransactionsTable, List<LedgerTransaction>>
  _ledgerTransactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ledgerTransactions,
        aliasName: 'counterparties__id__ledger_transactions__counterparty_id',
      );

  $$LedgerTransactionsTableProcessedTableManager get ledgerTransactionsRefs {
    final manager = $$LedgerTransactionsTableTableManager(
      $_db,
      $_db.ledgerTransactions,
    ).filter((f) => f.counterpartyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ledgerTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VendorRulesTable, List<VendorRule>>
  _vendorRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.vendorRules,
    aliasName: 'counterparties__id__vendor_rules__counterparty_id',
  );

  $$VendorRulesTableProcessedTableManager get vendorRulesRefs {
    final manager = $$VendorRulesTableTableManager(
      $_db,
      $_db.vendorRules,
    ).filter((f) => f.counterpartyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_vendorRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CounterpartiesTableFilterComposer
    extends Composer<_$AppDatabase, $CounterpartiesTable> {
  $$CounterpartiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ledgerTransactionsRefs(
    Expression<bool> Function($$LedgerTransactionsTableFilterComposer f) f,
  ) {
    final $$LedgerTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.counterpartyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> vendorRulesRefs(
    Expression<bool> Function($$VendorRulesTableFilterComposer f) f,
  ) {
    final $$VendorRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vendorRules,
      getReferencedColumn: (t) => t.counterpartyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VendorRulesTableFilterComposer(
            $db: $db,
            $table: $db.vendorRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CounterpartiesTableOrderingComposer
    extends Composer<_$AppDatabase, $CounterpartiesTable> {
  $$CounterpartiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CounterpartiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CounterpartiesTable> {
  $$CounterpartiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> ledgerTransactionsRefs<T extends Object>(
    Expression<T> Function($$LedgerTransactionsTableAnnotationComposer a) f,
  ) {
    final $$LedgerTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ledgerTransactions,
          getReferencedColumn: (t) => t.counterpartyId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LedgerTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.ledgerTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> vendorRulesRefs<T extends Object>(
    Expression<T> Function($$VendorRulesTableAnnotationComposer a) f,
  ) {
    final $$VendorRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vendorRules,
      getReferencedColumn: (t) => t.counterpartyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VendorRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.vendorRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CounterpartiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CounterpartiesTable,
          Counterparty,
          $$CounterpartiesTableFilterComposer,
          $$CounterpartiesTableOrderingComposer,
          $$CounterpartiesTableAnnotationComposer,
          $$CounterpartiesTableCreateCompanionBuilder,
          $$CounterpartiesTableUpdateCompanionBuilder,
          (Counterparty, $$CounterpartiesTableReferences),
          Counterparty,
          PrefetchHooks Function({
            bool ledgerTransactionsRefs,
            bool vendorRulesRefs,
          })
        > {
  $$CounterpartiesTableTableManager(
    _$AppDatabase db,
    $CounterpartiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CounterpartiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CounterpartiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CounterpartiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CounterpartiesCompanion(id: id, name: name, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => CounterpartiesCompanion.insert(
                id: id,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CounterpartiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({ledgerTransactionsRefs = false, vendorRulesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ledgerTransactionsRefs) db.ledgerTransactions,
                    if (vendorRulesRefs) db.vendorRules,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ledgerTransactionsRefs)
                        await $_getPrefetchedData<
                          Counterparty,
                          $CounterpartiesTable,
                          LedgerTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$CounterpartiesTableReferences
                              ._ledgerTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CounterpartiesTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.counterpartyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (vendorRulesRefs)
                        await $_getPrefetchedData<
                          Counterparty,
                          $CounterpartiesTable,
                          VendorRule
                        >(
                          currentTable: table,
                          referencedTable: $$CounterpartiesTableReferences
                              ._vendorRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CounterpartiesTableReferences(
                                db,
                                table,
                                p0,
                              ).vendorRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.counterpartyId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CounterpartiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CounterpartiesTable,
      Counterparty,
      $$CounterpartiesTableFilterComposer,
      $$CounterpartiesTableOrderingComposer,
      $$CounterpartiesTableAnnotationComposer,
      $$CounterpartiesTableCreateCompanionBuilder,
      $$CounterpartiesTableUpdateCompanionBuilder,
      (Counterparty, $$CounterpartiesTableReferences),
      Counterparty,
      PrefetchHooks Function({
        bool ledgerTransactionsRefs,
        bool vendorRulesRefs,
      })
    >;
typedef $$LedgerTransactionsTableCreateCompanionBuilder =
    LedgerTransactionsCompanion Function({
      required String id,
      required String counterpartyId,
      required DateTime date,
      required double amount,
      Value<String> currency,
      required String category,
      Value<String?> description,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LedgerTransactionsTableUpdateCompanionBuilder =
    LedgerTransactionsCompanion Function({
      Value<String> id,
      Value<String> counterpartyId,
      Value<DateTime> date,
      Value<double> amount,
      Value<String> currency,
      Value<String> category,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$LedgerTransactionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LedgerTransactionsTable,
          LedgerTransaction
        > {
  $$LedgerTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CounterpartiesTable _counterpartyIdTable(_$AppDatabase db) => db
      .counterparties
      .createAlias('ledger_transactions__counterparty_id__counterparties__id');

  $$CounterpartiesTableProcessedTableManager get counterpartyId {
    final $_column = $_itemColumn<String>('counterparty_id')!;

    final manager = $$CounterpartiesTableTableManager(
      $_db,
      $_db.counterparties,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_counterpartyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LedgerTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerTransactionsTable> {
  $$LedgerTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CounterpartiesTableFilterComposer get counterpartyId {
    final $$CounterpartiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterpartyId,
      referencedTable: $db.counterparties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CounterpartiesTableFilterComposer(
            $db: $db,
            $table: $db.counterparties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerTransactionsTable> {
  $$LedgerTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CounterpartiesTableOrderingComposer get counterpartyId {
    final $$CounterpartiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterpartyId,
      referencedTable: $db.counterparties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CounterpartiesTableOrderingComposer(
            $db: $db,
            $table: $db.counterparties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerTransactionsTable> {
  $$LedgerTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CounterpartiesTableAnnotationComposer get counterpartyId {
    final $$CounterpartiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterpartyId,
      referencedTable: $db.counterparties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CounterpartiesTableAnnotationComposer(
            $db: $db,
            $table: $db.counterparties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerTransactionsTable,
          LedgerTransaction,
          $$LedgerTransactionsTableFilterComposer,
          $$LedgerTransactionsTableOrderingComposer,
          $$LedgerTransactionsTableAnnotationComposer,
          $$LedgerTransactionsTableCreateCompanionBuilder,
          $$LedgerTransactionsTableUpdateCompanionBuilder,
          (LedgerTransaction, $$LedgerTransactionsTableReferences),
          LedgerTransaction,
          PrefetchHooks Function({bool counterpartyId})
        > {
  $$LedgerTransactionsTableTableManager(
    _$AppDatabase db,
    $LedgerTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> counterpartyId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerTransactionsCompanion(
                id: id,
                counterpartyId: counterpartyId,
                date: date,
                amount: amount,
                currency: currency,
                category: category,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String counterpartyId,
                required DateTime date,
                required double amount,
                Value<String> currency = const Value.absent(),
                required String category,
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LedgerTransactionsCompanion.insert(
                id: id,
                counterpartyId: counterpartyId,
                date: date,
                amount: amount,
                currency: currency,
                category: category,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LedgerTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({counterpartyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (counterpartyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.counterpartyId,
                                referencedTable:
                                    $$LedgerTransactionsTableReferences
                                        ._counterpartyIdTable(db),
                                referencedColumn:
                                    $$LedgerTransactionsTableReferences
                                        ._counterpartyIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LedgerTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerTransactionsTable,
      LedgerTransaction,
      $$LedgerTransactionsTableFilterComposer,
      $$LedgerTransactionsTableOrderingComposer,
      $$LedgerTransactionsTableAnnotationComposer,
      $$LedgerTransactionsTableCreateCompanionBuilder,
      $$LedgerTransactionsTableUpdateCompanionBuilder,
      (LedgerTransaction, $$LedgerTransactionsTableReferences),
      LedgerTransaction,
      PrefetchHooks Function({bool counterpartyId})
    >;
typedef $$SyncMetaTableCreateCompanionBuilder =
    SyncMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncMetaTableUpdateCompanionBuilder =
    SyncMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetaTable,
          SyncMetaData,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaData,
            BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
          ),
          SyncMetaData,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetaTable,
      SyncMetaData,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (
        SyncMetaData,
        BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
      ),
      SyncMetaData,
      PrefetchHooks Function()
    >;
typedef $$CalculatorInputsTableCreateCompanionBuilder =
    CalculatorInputsCompanion Function({
      required String key,
      required double value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CalculatorInputsTableUpdateCompanionBuilder =
    CalculatorInputsCompanion Function({
      Value<String> key,
      Value<double> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CalculatorInputsTableFilterComposer
    extends Composer<_$AppDatabase, $CalculatorInputsTable> {
  $$CalculatorInputsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalculatorInputsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalculatorInputsTable> {
  $$CalculatorInputsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalculatorInputsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalculatorInputsTable> {
  $$CalculatorInputsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CalculatorInputsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalculatorInputsTable,
          CalculatorInput,
          $$CalculatorInputsTableFilterComposer,
          $$CalculatorInputsTableOrderingComposer,
          $$CalculatorInputsTableAnnotationComposer,
          $$CalculatorInputsTableCreateCompanionBuilder,
          $$CalculatorInputsTableUpdateCompanionBuilder,
          (
            CalculatorInput,
            BaseReferences<
              _$AppDatabase,
              $CalculatorInputsTable,
              CalculatorInput
            >,
          ),
          CalculatorInput,
          PrefetchHooks Function()
        > {
  $$CalculatorInputsTableTableManager(
    _$AppDatabase db,
    $CalculatorInputsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalculatorInputsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalculatorInputsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalculatorInputsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalculatorInputsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required double value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CalculatorInputsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalculatorInputsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalculatorInputsTable,
      CalculatorInput,
      $$CalculatorInputsTableFilterComposer,
      $$CalculatorInputsTableOrderingComposer,
      $$CalculatorInputsTableAnnotationComposer,
      $$CalculatorInputsTableCreateCompanionBuilder,
      $$CalculatorInputsTableUpdateCompanionBuilder,
      (
        CalculatorInput,
        BaseReferences<_$AppDatabase, $CalculatorInputsTable, CalculatorInput>,
      ),
      CalculatorInput,
      PrefetchHooks Function()
    >;
typedef $$VendorRulesTableCreateCompanionBuilder =
    VendorRulesCompanion Function({
      required String id,
      required String vendorPattern,
      required String counterpartyId,
      required String category,
      Value<int> rowid,
    });
typedef $$VendorRulesTableUpdateCompanionBuilder =
    VendorRulesCompanion Function({
      Value<String> id,
      Value<String> vendorPattern,
      Value<String> counterpartyId,
      Value<String> category,
      Value<int> rowid,
    });

final class $$VendorRulesTableReferences
    extends BaseReferences<_$AppDatabase, $VendorRulesTable, VendorRule> {
  $$VendorRulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CounterpartiesTable _counterpartyIdTable(_$AppDatabase db) => db
      .counterparties
      .createAlias('vendor_rules__counterparty_id__counterparties__id');

  $$CounterpartiesTableProcessedTableManager get counterpartyId {
    final $_column = $_itemColumn<String>('counterparty_id')!;

    final manager = $$CounterpartiesTableTableManager(
      $_db,
      $_db.counterparties,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_counterpartyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VendorRulesTableFilterComposer
    extends Composer<_$AppDatabase, $VendorRulesTable> {
  $$VendorRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorPattern => $composableBuilder(
    column: $table.vendorPattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  $$CounterpartiesTableFilterComposer get counterpartyId {
    final $$CounterpartiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterpartyId,
      referencedTable: $db.counterparties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CounterpartiesTableFilterComposer(
            $db: $db,
            $table: $db.counterparties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VendorRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $VendorRulesTable> {
  $$VendorRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorPattern => $composableBuilder(
    column: $table.vendorPattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  $$CounterpartiesTableOrderingComposer get counterpartyId {
    final $$CounterpartiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterpartyId,
      referencedTable: $db.counterparties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CounterpartiesTableOrderingComposer(
            $db: $db,
            $table: $db.counterparties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VendorRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VendorRulesTable> {
  $$VendorRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vendorPattern => $composableBuilder(
    column: $table.vendorPattern,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  $$CounterpartiesTableAnnotationComposer get counterpartyId {
    final $$CounterpartiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterpartyId,
      referencedTable: $db.counterparties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CounterpartiesTableAnnotationComposer(
            $db: $db,
            $table: $db.counterparties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VendorRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VendorRulesTable,
          VendorRule,
          $$VendorRulesTableFilterComposer,
          $$VendorRulesTableOrderingComposer,
          $$VendorRulesTableAnnotationComposer,
          $$VendorRulesTableCreateCompanionBuilder,
          $$VendorRulesTableUpdateCompanionBuilder,
          (VendorRule, $$VendorRulesTableReferences),
          VendorRule,
          PrefetchHooks Function({bool counterpartyId})
        > {
  $$VendorRulesTableTableManager(_$AppDatabase db, $VendorRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VendorRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VendorRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VendorRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vendorPattern = const Value.absent(),
                Value<String> counterpartyId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VendorRulesCompanion(
                id: id,
                vendorPattern: vendorPattern,
                counterpartyId: counterpartyId,
                category: category,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vendorPattern,
                required String counterpartyId,
                required String category,
                Value<int> rowid = const Value.absent(),
              }) => VendorRulesCompanion.insert(
                id: id,
                vendorPattern: vendorPattern,
                counterpartyId: counterpartyId,
                category: category,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VendorRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({counterpartyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (counterpartyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.counterpartyId,
                                referencedTable: $$VendorRulesTableReferences
                                    ._counterpartyIdTable(db),
                                referencedColumn: $$VendorRulesTableReferences
                                    ._counterpartyIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VendorRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VendorRulesTable,
      VendorRule,
      $$VendorRulesTableFilterComposer,
      $$VendorRulesTableOrderingComposer,
      $$VendorRulesTableAnnotationComposer,
      $$VendorRulesTableCreateCompanionBuilder,
      $$VendorRulesTableUpdateCompanionBuilder,
      (VendorRule, $$VendorRulesTableReferences),
      VendorRule,
      PrefetchHooks Function({bool counterpartyId})
    >;
typedef $$CalculatorSnapshotsTableCreateCompanionBuilder =
    CalculatorSnapshotsCompanion Function({
      required String id,
      required DateTime computedAt,
      required double resultAmount,
      required double ledgersTotal,
      required double apartmentSavings,
      required double cibAccountBalance,
      Value<double> nbeAvailable,
      Value<double> nbeOwed,
      Value<double> cibExplorerWalletAvailable,
      Value<double> cibExplorerWalletOwed,
      Value<double> cibPlatinumAvailable,
      Value<double> cibPlatinumOwed,
      Value<String> customItemsJson,
      Value<String> cardEntriesJson,
      Value<int> rowid,
    });
typedef $$CalculatorSnapshotsTableUpdateCompanionBuilder =
    CalculatorSnapshotsCompanion Function({
      Value<String> id,
      Value<DateTime> computedAt,
      Value<double> resultAmount,
      Value<double> ledgersTotal,
      Value<double> apartmentSavings,
      Value<double> cibAccountBalance,
      Value<double> nbeAvailable,
      Value<double> nbeOwed,
      Value<double> cibExplorerWalletAvailable,
      Value<double> cibExplorerWalletOwed,
      Value<double> cibPlatinumAvailable,
      Value<double> cibPlatinumOwed,
      Value<String> customItemsJson,
      Value<String> cardEntriesJson,
      Value<int> rowid,
    });

class $$CalculatorSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $CalculatorSnapshotsTable> {
  $$CalculatorSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get resultAmount => $composableBuilder(
    column: $table.resultAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ledgersTotal => $composableBuilder(
    column: $table.ledgersTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get apartmentSavings => $composableBuilder(
    column: $table.apartmentSavings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cibAccountBalance => $composableBuilder(
    column: $table.cibAccountBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get nbeAvailable => $composableBuilder(
    column: $table.nbeAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get nbeOwed => $composableBuilder(
    column: $table.nbeOwed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cibExplorerWalletAvailable => $composableBuilder(
    column: $table.cibExplorerWalletAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cibExplorerWalletOwed => $composableBuilder(
    column: $table.cibExplorerWalletOwed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cibPlatinumAvailable => $composableBuilder(
    column: $table.cibPlatinumAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cibPlatinumOwed => $composableBuilder(
    column: $table.cibPlatinumOwed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customItemsJson => $composableBuilder(
    column: $table.customItemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardEntriesJson => $composableBuilder(
    column: $table.cardEntriesJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalculatorSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalculatorSnapshotsTable> {
  $$CalculatorSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get resultAmount => $composableBuilder(
    column: $table.resultAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ledgersTotal => $composableBuilder(
    column: $table.ledgersTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get apartmentSavings => $composableBuilder(
    column: $table.apartmentSavings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cibAccountBalance => $composableBuilder(
    column: $table.cibAccountBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get nbeAvailable => $composableBuilder(
    column: $table.nbeAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get nbeOwed => $composableBuilder(
    column: $table.nbeOwed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cibExplorerWalletAvailable => $composableBuilder(
    column: $table.cibExplorerWalletAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cibExplorerWalletOwed => $composableBuilder(
    column: $table.cibExplorerWalletOwed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cibPlatinumAvailable => $composableBuilder(
    column: $table.cibPlatinumAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cibPlatinumOwed => $composableBuilder(
    column: $table.cibPlatinumOwed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customItemsJson => $composableBuilder(
    column: $table.customItemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardEntriesJson => $composableBuilder(
    column: $table.cardEntriesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalculatorSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalculatorSnapshotsTable> {
  $$CalculatorSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get resultAmount => $composableBuilder(
    column: $table.resultAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ledgersTotal => $composableBuilder(
    column: $table.ledgersTotal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get apartmentSavings => $composableBuilder(
    column: $table.apartmentSavings,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cibAccountBalance => $composableBuilder(
    column: $table.cibAccountBalance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get nbeAvailable => $composableBuilder(
    column: $table.nbeAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<double> get nbeOwed =>
      $composableBuilder(column: $table.nbeOwed, builder: (column) => column);

  GeneratedColumn<double> get cibExplorerWalletAvailable => $composableBuilder(
    column: $table.cibExplorerWalletAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cibExplorerWalletOwed => $composableBuilder(
    column: $table.cibExplorerWalletOwed,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cibPlatinumAvailable => $composableBuilder(
    column: $table.cibPlatinumAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cibPlatinumOwed => $composableBuilder(
    column: $table.cibPlatinumOwed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customItemsJson => $composableBuilder(
    column: $table.customItemsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardEntriesJson => $composableBuilder(
    column: $table.cardEntriesJson,
    builder: (column) => column,
  );
}

class $$CalculatorSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalculatorSnapshotsTable,
          CalculatorSnapshot,
          $$CalculatorSnapshotsTableFilterComposer,
          $$CalculatorSnapshotsTableOrderingComposer,
          $$CalculatorSnapshotsTableAnnotationComposer,
          $$CalculatorSnapshotsTableCreateCompanionBuilder,
          $$CalculatorSnapshotsTableUpdateCompanionBuilder,
          (
            CalculatorSnapshot,
            BaseReferences<
              _$AppDatabase,
              $CalculatorSnapshotsTable,
              CalculatorSnapshot
            >,
          ),
          CalculatorSnapshot,
          PrefetchHooks Function()
        > {
  $$CalculatorSnapshotsTableTableManager(
    _$AppDatabase db,
    $CalculatorSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalculatorSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalculatorSnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CalculatorSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> computedAt = const Value.absent(),
                Value<double> resultAmount = const Value.absent(),
                Value<double> ledgersTotal = const Value.absent(),
                Value<double> apartmentSavings = const Value.absent(),
                Value<double> cibAccountBalance = const Value.absent(),
                Value<double> nbeAvailable = const Value.absent(),
                Value<double> nbeOwed = const Value.absent(),
                Value<double> cibExplorerWalletAvailable = const Value.absent(),
                Value<double> cibExplorerWalletOwed = const Value.absent(),
                Value<double> cibPlatinumAvailable = const Value.absent(),
                Value<double> cibPlatinumOwed = const Value.absent(),
                Value<String> customItemsJson = const Value.absent(),
                Value<String> cardEntriesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalculatorSnapshotsCompanion(
                id: id,
                computedAt: computedAt,
                resultAmount: resultAmount,
                ledgersTotal: ledgersTotal,
                apartmentSavings: apartmentSavings,
                cibAccountBalance: cibAccountBalance,
                nbeAvailable: nbeAvailable,
                nbeOwed: nbeOwed,
                cibExplorerWalletAvailable: cibExplorerWalletAvailable,
                cibExplorerWalletOwed: cibExplorerWalletOwed,
                cibPlatinumAvailable: cibPlatinumAvailable,
                cibPlatinumOwed: cibPlatinumOwed,
                customItemsJson: customItemsJson,
                cardEntriesJson: cardEntriesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime computedAt,
                required double resultAmount,
                required double ledgersTotal,
                required double apartmentSavings,
                required double cibAccountBalance,
                Value<double> nbeAvailable = const Value.absent(),
                Value<double> nbeOwed = const Value.absent(),
                Value<double> cibExplorerWalletAvailable = const Value.absent(),
                Value<double> cibExplorerWalletOwed = const Value.absent(),
                Value<double> cibPlatinumAvailable = const Value.absent(),
                Value<double> cibPlatinumOwed = const Value.absent(),
                Value<String> customItemsJson = const Value.absent(),
                Value<String> cardEntriesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalculatorSnapshotsCompanion.insert(
                id: id,
                computedAt: computedAt,
                resultAmount: resultAmount,
                ledgersTotal: ledgersTotal,
                apartmentSavings: apartmentSavings,
                cibAccountBalance: cibAccountBalance,
                nbeAvailable: nbeAvailable,
                nbeOwed: nbeOwed,
                cibExplorerWalletAvailable: cibExplorerWalletAvailable,
                cibExplorerWalletOwed: cibExplorerWalletOwed,
                cibPlatinumAvailable: cibPlatinumAvailable,
                cibPlatinumOwed: cibPlatinumOwed,
                customItemsJson: customItemsJson,
                cardEntriesJson: cardEntriesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalculatorSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalculatorSnapshotsTable,
      CalculatorSnapshot,
      $$CalculatorSnapshotsTableFilterComposer,
      $$CalculatorSnapshotsTableOrderingComposer,
      $$CalculatorSnapshotsTableAnnotationComposer,
      $$CalculatorSnapshotsTableCreateCompanionBuilder,
      $$CalculatorSnapshotsTableUpdateCompanionBuilder,
      (
        CalculatorSnapshot,
        BaseReferences<
          _$AppDatabase,
          $CalculatorSnapshotsTable,
          CalculatorSnapshot
        >,
      ),
      CalculatorSnapshot,
      PrefetchHooks Function()
    >;
typedef $$CreditCardsTableCreateCompanionBuilder =
    CreditCardsCompanion Function({
      required String id,
      required String name,
      required String bank,
      required double limitAmount,
      Value<String> currency,
      Value<int> sortOrder,
      Value<String?> lastFourDigits,
      Value<int> rowid,
    });
typedef $$CreditCardsTableUpdateCompanionBuilder =
    CreditCardsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> bank,
      Value<double> limitAmount,
      Value<String> currency,
      Value<int> sortOrder,
      Value<String?> lastFourDigits,
      Value<int> rowid,
    });

class $$CreditCardsTableFilterComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bank => $composableBuilder(
    column: $table.bank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get limitAmount => $composableBuilder(
    column: $table.limitAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFourDigits => $composableBuilder(
    column: $table.lastFourDigits,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CreditCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bank => $composableBuilder(
    column: $table.bank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get limitAmount => $composableBuilder(
    column: $table.limitAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFourDigits => $composableBuilder(
    column: $table.lastFourDigits,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CreditCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get bank =>
      $composableBuilder(column: $table.bank, builder: (column) => column);

  GeneratedColumn<double> get limitAmount => $composableBuilder(
    column: $table.limitAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get lastFourDigits => $composableBuilder(
    column: $table.lastFourDigits,
    builder: (column) => column,
  );
}

class $$CreditCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CreditCardsTable,
          CreditCard,
          $$CreditCardsTableFilterComposer,
          $$CreditCardsTableOrderingComposer,
          $$CreditCardsTableAnnotationComposer,
          $$CreditCardsTableCreateCompanionBuilder,
          $$CreditCardsTableUpdateCompanionBuilder,
          (
            CreditCard,
            BaseReferences<_$AppDatabase, $CreditCardsTable, CreditCard>,
          ),
          CreditCard,
          PrefetchHooks Function()
        > {
  $$CreditCardsTableTableManager(_$AppDatabase db, $CreditCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreditCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreditCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> bank = const Value.absent(),
                Value<double> limitAmount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> lastFourDigits = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditCardsCompanion(
                id: id,
                name: name,
                bank: bank,
                limitAmount: limitAmount,
                currency: currency,
                sortOrder: sortOrder,
                lastFourDigits: lastFourDigits,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String bank,
                required double limitAmount,
                Value<String> currency = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> lastFourDigits = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditCardsCompanion.insert(
                id: id,
                name: name,
                bank: bank,
                limitAmount: limitAmount,
                currency: currency,
                sortOrder: sortOrder,
                lastFourDigits: lastFourDigits,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CreditCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CreditCardsTable,
      CreditCard,
      $$CreditCardsTableFilterComposer,
      $$CreditCardsTableOrderingComposer,
      $$CreditCardsTableAnnotationComposer,
      $$CreditCardsTableCreateCompanionBuilder,
      $$CreditCardsTableUpdateCompanionBuilder,
      (
        CreditCard,
        BaseReferences<_$AppDatabase, $CreditCardsTable, CreditCard>,
      ),
      CreditCard,
      PrefetchHooks Function()
    >;
typedef $$LedgerCategoriesTableCreateCompanionBuilder =
    LedgerCategoriesCompanion Function({
      required String id,
      required String name,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$LedgerCategoriesTableUpdateCompanionBuilder =
    LedgerCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$LedgerCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerCategoriesTable> {
  $$LedgerCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LedgerCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerCategoriesTable> {
  $$LedgerCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LedgerCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerCategoriesTable> {
  $$LedgerCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$LedgerCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerCategoriesTable,
          LedgerCategory,
          $$LedgerCategoriesTableFilterComposer,
          $$LedgerCategoriesTableOrderingComposer,
          $$LedgerCategoriesTableAnnotationComposer,
          $$LedgerCategoriesTableCreateCompanionBuilder,
          $$LedgerCategoriesTableUpdateCompanionBuilder,
          (
            LedgerCategory,
            BaseReferences<
              _$AppDatabase,
              $LedgerCategoriesTable,
              LedgerCategory
            >,
          ),
          LedgerCategory,
          PrefetchHooks Function()
        > {
  $$LedgerCategoriesTableTableManager(
    _$AppDatabase db,
    $LedgerCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerCategoriesCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerCategoriesCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LedgerCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerCategoriesTable,
      LedgerCategory,
      $$LedgerCategoriesTableFilterComposer,
      $$LedgerCategoriesTableOrderingComposer,
      $$LedgerCategoriesTableAnnotationComposer,
      $$LedgerCategoriesTableCreateCompanionBuilder,
      $$LedgerCategoriesTableUpdateCompanionBuilder,
      (
        LedgerCategory,
        BaseReferences<_$AppDatabase, $LedgerCategoriesTable, LedgerCategory>,
      ),
      LedgerCategory,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$PriceCacheTableTableManager get priceCache =>
      $$PriceCacheTableTableManager(_db, _db.priceCache);
  $$CounterpartiesTableTableManager get counterparties =>
      $$CounterpartiesTableTableManager(_db, _db.counterparties);
  $$LedgerTransactionsTableTableManager get ledgerTransactions =>
      $$LedgerTransactionsTableTableManager(_db, _db.ledgerTransactions);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
  $$CalculatorInputsTableTableManager get calculatorInputs =>
      $$CalculatorInputsTableTableManager(_db, _db.calculatorInputs);
  $$VendorRulesTableTableManager get vendorRules =>
      $$VendorRulesTableTableManager(_db, _db.vendorRules);
  $$CalculatorSnapshotsTableTableManager get calculatorSnapshots =>
      $$CalculatorSnapshotsTableTableManager(_db, _db.calculatorSnapshots);
  $$CreditCardsTableTableManager get creditCards =>
      $$CreditCardsTableTableManager(_db, _db.creditCards);
  $$LedgerCategoriesTableTableManager get ledgerCategories =>
      $$LedgerCategoriesTableTableManager(_db, _db.ledgerCategories);
}
