// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
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
  List<GeneratedColumn> get $columns => [id, name, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
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
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
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
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String name;

  /// Manual ordering for display — set to insertion order by default.
  final int sortOrder;
  final DateTime createdAt;
  const Profile({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Profile copyWith({
    String? id,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
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
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

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
  static const VerificationMeta _vehicleTypeMeta = const VerificationMeta(
    'vehicleType',
  );
  @override
  late final GeneratedColumn<String> vehicleType = GeneratedColumn<String>(
    'vehicle_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePriceMeta = const VerificationMeta(
    'purchasePrice',
  );
  @override
  late final GeneratedColumn<double> purchasePrice = GeneratedColumn<double>(
    'purchase_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseCurrencyMeta = const VerificationMeta(
    'purchaseCurrency',
  );
  @override
  late final GeneratedColumn<String> purchaseCurrency = GeneratedColumn<String>(
    'purchase_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
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
    vehicleType,
    purchasePrice,
    purchaseCurrency,
    purchaseDate,
    profileId,
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
    if (data.containsKey('vehicle_type')) {
      context.handle(
        _vehicleTypeMeta,
        vehicleType.isAcceptableOrUnknown(
          data['vehicle_type']!,
          _vehicleTypeMeta,
        ),
      );
    }
    if (data.containsKey('purchase_price')) {
      context.handle(
        _purchasePriceMeta,
        purchasePrice.isAcceptableOrUnknown(
          data['purchase_price']!,
          _purchasePriceMeta,
        ),
      );
    }
    if (data.containsKey('purchase_currency')) {
      context.handle(
        _purchaseCurrencyMeta,
        purchaseCurrency.isAcceptableOrUnknown(
          data['purchase_currency']!,
          _purchaseCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
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
      vehicleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_type'],
      ),
      purchasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_price'],
      ),
      purchaseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_currency'],
      ),
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      ),
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
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

  /// Units held: coins for crypto, grams for metals, shares for stocks, or
  /// an amount denominated in [symbolOrCurrency] for the `currency`
  /// valuation mode (covers both literal cash holdings and a typed-in value
  /// like a car's or a certificate's).
  final double quantity;

  /// Crypto symbol (e.g. `bitcoin`), metal symbol (`XAU_GRAM_<karat>K`/`XAG_GRAM`),
  /// stock ticker (`SYMBOL:EXCHANGE`, e.g. `AAPL:NASDAQ`/`COMI:EGX`), or a
  /// currency code (EGP/USD/EUR/SAR/AED/TRY).
  final String symbolOrCurrency;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 'car' / 'motorcycle' / 'scooter' -- only meaningful when [category] is
  /// AssetCategory.vehicle, picks which icon shows everywhere this asset
  /// displays. Null (including for every non-vehicle asset) falls back to
  /// the generic car icon.
  final String? vehicleType;

  /// What was originally paid for this asset, in [purchaseCurrency] --
  /// optional (null means "not tracked"). Only surfaced in the UI for
  /// gold/silver/real estate/stock/crypto; the column itself is generic so
  /// nothing stops another category from using it later.
  final double? purchasePrice;
  final String? purchaseCurrency;

  /// When this asset was bought -- optional, and (unlike [purchasePrice])
  /// asked for on every category, since "when did I get this" doesn't
  /// depend on whether a gain/loss can be computed for it.
  final DateTime? purchaseDate;

  /// Which [Profiles] row this asset belongs to. Nullable only because
  /// SQLite can't add a NOT NULL column with a dynamic default -- every
  /// insert going forward always stamps a real profile id; the migration
  /// backfills every pre-existing row to the seeded default profile.
  final String? profileId;
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
    this.vehicleType,
    this.purchasePrice,
    this.purchaseCurrency,
    this.purchaseDate,
    this.profileId,
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
    if (!nullToAbsent || vehicleType != null) {
      map['vehicle_type'] = Variable<String>(vehicleType);
    }
    if (!nullToAbsent || purchasePrice != null) {
      map['purchase_price'] = Variable<double>(purchasePrice);
    }
    if (!nullToAbsent || purchaseCurrency != null) {
      map['purchase_currency'] = Variable<String>(purchaseCurrency);
    }
    if (!nullToAbsent || purchaseDate != null) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate);
    }
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
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
      vehicleType: vehicleType == null && nullToAbsent
          ? const Value.absent()
          : Value(vehicleType),
      purchasePrice: purchasePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePrice),
      purchaseCurrency: purchaseCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseCurrency),
      purchaseDate: purchaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDate),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
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
      vehicleType: serializer.fromJson<String?>(json['vehicleType']),
      purchasePrice: serializer.fromJson<double?>(json['purchasePrice']),
      purchaseCurrency: serializer.fromJson<String?>(json['purchaseCurrency']),
      purchaseDate: serializer.fromJson<DateTime?>(json['purchaseDate']),
      profileId: serializer.fromJson<String?>(json['profileId']),
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
      'vehicleType': serializer.toJson<String?>(vehicleType),
      'purchasePrice': serializer.toJson<double?>(purchasePrice),
      'purchaseCurrency': serializer.toJson<String?>(purchaseCurrency),
      'purchaseDate': serializer.toJson<DateTime?>(purchaseDate),
      'profileId': serializer.toJson<String?>(profileId),
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
    Value<String?> vehicleType = const Value.absent(),
    Value<double?> purchasePrice = const Value.absent(),
    Value<String?> purchaseCurrency = const Value.absent(),
    Value<DateTime?> purchaseDate = const Value.absent(),
    Value<String?> profileId = const Value.absent(),
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
    vehicleType: vehicleType.present ? vehicleType.value : this.vehicleType,
    purchasePrice: purchasePrice.present
        ? purchasePrice.value
        : this.purchasePrice,
    purchaseCurrency: purchaseCurrency.present
        ? purchaseCurrency.value
        : this.purchaseCurrency,
    purchaseDate: purchaseDate.present ? purchaseDate.value : this.purchaseDate,
    profileId: profileId.present ? profileId.value : this.profileId,
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
      vehicleType: data.vehicleType.present
          ? data.vehicleType.value
          : this.vehicleType,
      purchasePrice: data.purchasePrice.present
          ? data.purchasePrice.value
          : this.purchasePrice,
      purchaseCurrency: data.purchaseCurrency.present
          ? data.purchaseCurrency.value
          : this.purchaseCurrency,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
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
          ..write('updatedAt: $updatedAt, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('purchaseCurrency: $purchaseCurrency, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('profileId: $profileId')
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
    vehicleType,
    purchasePrice,
    purchaseCurrency,
    purchaseDate,
    profileId,
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
          other.updatedAt == this.updatedAt &&
          other.vehicleType == this.vehicleType &&
          other.purchasePrice == this.purchasePrice &&
          other.purchaseCurrency == this.purchaseCurrency &&
          other.purchaseDate == this.purchaseDate &&
          other.profileId == this.profileId);
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
  final Value<String?> vehicleType;
  final Value<double?> purchasePrice;
  final Value<String?> purchaseCurrency;
  final Value<DateTime?> purchaseDate;
  final Value<String?> profileId;
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
    this.vehicleType = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.purchaseCurrency = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.profileId = const Value.absent(),
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
    this.vehicleType = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.purchaseCurrency = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.profileId = const Value.absent(),
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
    Expression<String>? vehicleType,
    Expression<double>? purchasePrice,
    Expression<String>? purchaseCurrency,
    Expression<DateTime>? purchaseDate,
    Expression<String>? profileId,
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
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      if (purchaseCurrency != null) 'purchase_currency': purchaseCurrency,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (profileId != null) 'profile_id': profileId,
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
    Value<String?>? vehicleType,
    Value<double?>? purchasePrice,
    Value<String?>? purchaseCurrency,
    Value<DateTime?>? purchaseDate,
    Value<String?>? profileId,
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
      vehicleType: vehicleType ?? this.vehicleType,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseCurrency: purchaseCurrency ?? this.purchaseCurrency,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      profileId: profileId ?? this.profileId,
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
    if (vehicleType.present) {
      map['vehicle_type'] = Variable<String>(vehicleType.value);
    }
    if (purchasePrice.present) {
      map['purchase_price'] = Variable<double>(purchasePrice.value);
    }
    if (purchaseCurrency.present) {
      map['purchase_currency'] = Variable<String>(purchaseCurrency.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
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
          ..write('vehicleType: $vehicleType, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('purchaseCurrency: $purchaseCurrency, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('profileId: $profileId, ')
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
  static const VerificationMeta _includeInStatisticsMeta =
      const VerificationMeta('includeInStatistics');
  @override
  late final GeneratedColumn<bool> includeInStatistics = GeneratedColumn<bool>(
    'include_in_statistics',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_in_statistics" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _includeInCalculatorMeta =
      const VerificationMeta('includeInCalculator');
  @override
  late final GeneratedColumn<bool> includeInCalculator = GeneratedColumn<bool>(
    'include_in_calculator',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_in_calculator" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _visibleMeta = const VerificationMeta(
    'visible',
  );
  @override
  late final GeneratedColumn<bool> visible = GeneratedColumn<bool>(
    'visible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("visible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isTabMeta = const VerificationMeta('isTab');
  @override
  late final GeneratedColumn<bool> isTab = GeneratedColumn<bool>(
    'is_tab',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tab" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    includeInStatistics,
    includeInCalculator,
    visible,
    isTab,
    profileId,
  ];
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
    if (data.containsKey('include_in_statistics')) {
      context.handle(
        _includeInStatisticsMeta,
        includeInStatistics.isAcceptableOrUnknown(
          data['include_in_statistics']!,
          _includeInStatisticsMeta,
        ),
      );
    }
    if (data.containsKey('include_in_calculator')) {
      context.handle(
        _includeInCalculatorMeta,
        includeInCalculator.isAcceptableOrUnknown(
          data['include_in_calculator']!,
          _includeInCalculatorMeta,
        ),
      );
    }
    if (data.containsKey('visible')) {
      context.handle(
        _visibleMeta,
        visible.isAcceptableOrUnknown(data['visible']!, _visibleMeta),
      );
    }
    if (data.containsKey('is_tab')) {
      context.handle(
        _isTabMeta,
        isTab.isAcceptableOrUnknown(data['is_tab']!, _isTabMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
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
      includeInStatistics: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_in_statistics'],
      )!,
      includeInCalculator: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_in_calculator'],
      )!,
      visible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}visible'],
      )!,
      isTab: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tab'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
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

  /// Whether this ledger's data appears in the Statistics tab. Defaults to
  /// true so existing ledgers keep behaving exactly as before until the
  /// user explicitly opts one out.
  final bool includeInStatistics;

  /// Whether this ledger's balance is summed into the Calculator tab's
  /// "current liquid cash" total. Defaults to true for the same reason.
  final bool includeInCalculator;

  /// Whether this ledger shows up in the main Ledger list at all. Defaults
  /// to true so every existing ledger keeps showing exactly as before;
  /// setting this to false doesn't archive or delete anything -- the
  /// ledger, its transactions, and its Statistics/Calculator inclusion all
  /// keep working exactly as they do today, it's purely hidden from the
  /// main list until switched back (see the Ledger tab's own "Hidden
  /// ledgers" section for how to find one again).
  final bool visible;

  /// A Tab is the same row-per-payment recording as a Ledger, but never
  /// represents anyone owing anyone anything -- it's just a running log of
  /// money going back and forth (e.g. a shared trip or a running tab with
  /// a friend). Defaults to false so every existing counterparty stays a
  /// normal Ledger. A Tab is always kept out of Statistics and the
  /// Calculator's liquid-cash total regardless of the two flags above --
  /// see `LedgerRepository.addCounterparty`/`updateCounterparty`, which
  /// enforce that even if a caller tries to pass true for either.
  final bool isTab;
  final String? profileId;
  const Counterparty({
    required this.id,
    required this.name,
    required this.includeInStatistics,
    required this.includeInCalculator,
    required this.visible,
    required this.isTab,
    this.profileId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['include_in_statistics'] = Variable<bool>(includeInStatistics);
    map['include_in_calculator'] = Variable<bool>(includeInCalculator);
    map['visible'] = Variable<bool>(visible);
    map['is_tab'] = Variable<bool>(isTab);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    return map;
  }

  CounterpartiesCompanion toCompanion(bool nullToAbsent) {
    return CounterpartiesCompanion(
      id: Value(id),
      name: Value(name),
      includeInStatistics: Value(includeInStatistics),
      includeInCalculator: Value(includeInCalculator),
      visible: Value(visible),
      isTab: Value(isTab),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
    );
  }

  factory Counterparty.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Counterparty(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      includeInStatistics: serializer.fromJson<bool>(
        json['includeInStatistics'],
      ),
      includeInCalculator: serializer.fromJson<bool>(
        json['includeInCalculator'],
      ),
      visible: serializer.fromJson<bool>(json['visible']),
      isTab: serializer.fromJson<bool>(json['isTab']),
      profileId: serializer.fromJson<String?>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'includeInStatistics': serializer.toJson<bool>(includeInStatistics),
      'includeInCalculator': serializer.toJson<bool>(includeInCalculator),
      'visible': serializer.toJson<bool>(visible),
      'isTab': serializer.toJson<bool>(isTab),
      'profileId': serializer.toJson<String?>(profileId),
    };
  }

  Counterparty copyWith({
    String? id,
    String? name,
    bool? includeInStatistics,
    bool? includeInCalculator,
    bool? visible,
    bool? isTab,
    Value<String?> profileId = const Value.absent(),
  }) => Counterparty(
    id: id ?? this.id,
    name: name ?? this.name,
    includeInStatistics: includeInStatistics ?? this.includeInStatistics,
    includeInCalculator: includeInCalculator ?? this.includeInCalculator,
    visible: visible ?? this.visible,
    isTab: isTab ?? this.isTab,
    profileId: profileId.present ? profileId.value : this.profileId,
  );
  Counterparty copyWithCompanion(CounterpartiesCompanion data) {
    return Counterparty(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      includeInStatistics: data.includeInStatistics.present
          ? data.includeInStatistics.value
          : this.includeInStatistics,
      includeInCalculator: data.includeInCalculator.present
          ? data.includeInCalculator.value
          : this.includeInCalculator,
      visible: data.visible.present ? data.visible.value : this.visible,
      isTab: data.isTab.present ? data.isTab.value : this.isTab,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Counterparty(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('includeInStatistics: $includeInStatistics, ')
          ..write('includeInCalculator: $includeInCalculator, ')
          ..write('visible: $visible, ')
          ..write('isTab: $isTab, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    includeInStatistics,
    includeInCalculator,
    visible,
    isTab,
    profileId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Counterparty &&
          other.id == this.id &&
          other.name == this.name &&
          other.includeInStatistics == this.includeInStatistics &&
          other.includeInCalculator == this.includeInCalculator &&
          other.visible == this.visible &&
          other.isTab == this.isTab &&
          other.profileId == this.profileId);
}

class CounterpartiesCompanion extends UpdateCompanion<Counterparty> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> includeInStatistics;
  final Value<bool> includeInCalculator;
  final Value<bool> visible;
  final Value<bool> isTab;
  final Value<String?> profileId;
  final Value<int> rowid;
  const CounterpartiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.includeInStatistics = const Value.absent(),
    this.includeInCalculator = const Value.absent(),
    this.visible = const Value.absent(),
    this.isTab = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CounterpartiesCompanion.insert({
    required String id,
    required String name,
    this.includeInStatistics = const Value.absent(),
    this.includeInCalculator = const Value.absent(),
    this.visible = const Value.absent(),
    this.isTab = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Counterparty> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? includeInStatistics,
    Expression<bool>? includeInCalculator,
    Expression<bool>? visible,
    Expression<bool>? isTab,
    Expression<String>? profileId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (includeInStatistics != null)
        'include_in_statistics': includeInStatistics,
      if (includeInCalculator != null)
        'include_in_calculator': includeInCalculator,
      if (visible != null) 'visible': visible,
      if (isTab != null) 'is_tab': isTab,
      if (profileId != null) 'profile_id': profileId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CounterpartiesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? includeInStatistics,
    Value<bool>? includeInCalculator,
    Value<bool>? visible,
    Value<bool>? isTab,
    Value<String?>? profileId,
    Value<int>? rowid,
  }) {
    return CounterpartiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      includeInStatistics: includeInStatistics ?? this.includeInStatistics,
      includeInCalculator: includeInCalculator ?? this.includeInCalculator,
      visible: visible ?? this.visible,
      isTab: isTab ?? this.isTab,
      profileId: profileId ?? this.profileId,
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
    if (includeInStatistics.present) {
      map['include_in_statistics'] = Variable<bool>(includeInStatistics.value);
    }
    if (includeInCalculator.present) {
      map['include_in_calculator'] = Variable<bool>(includeInCalculator.value);
    }
    if (visible.present) {
      map['visible'] = Variable<bool>(visible.value);
    }
    if (isTab.present) {
      map['is_tab'] = Variable<bool>(isTab.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
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
          ..write('includeInStatistics: $includeInStatistics, ')
          ..write('includeInCalculator: $includeInCalculator, ')
          ..write('visible: $visible, ')
          ..write('isTab: $isTab, ')
          ..write('profileId: $profileId, ')
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
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
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
    profileId,
    source,
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
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
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
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
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

  /// Denormalized from the owning counterparty's own profile, so "every
  /// transaction across every counterparty" queries (the calculator's
  /// combined total) can filter to the active profile without a join.
  final String? profileId;

  /// 'manual' (typed in on this screen) or 'sms' (a vendor-rule auto-match
  /// via `commitSmsQuickAdd`, or a charge confirmed on `SmsReviewScreen`
  /// after tapping its notification) -- shown on the ledger row so a
  /// vendor-rule-matched entry doesn't look indistinguishable from one
  /// typed in by hand. Defaults to 'manual' so every pre-existing row
  /// (all of which really were typed in, since this column didn't exist
  /// before) backfills correctly with no migration logic beyond the
  /// column default.
  final String source;
  const LedgerTransaction({
    required this.id,
    required this.counterpartyId,
    required this.date,
    required this.amount,
    required this.currency,
    required this.category,
    this.description,
    required this.createdAt,
    this.profileId,
    required this.source,
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
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    map['source'] = Variable<String>(source);
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
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      source: Value(source),
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
      profileId: serializer.fromJson<String?>(json['profileId']),
      source: serializer.fromJson<String>(json['source']),
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
      'profileId': serializer.toJson<String?>(profileId),
      'source': serializer.toJson<String>(source),
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
    Value<String?> profileId = const Value.absent(),
    String? source,
  }) => LedgerTransaction(
    id: id ?? this.id,
    counterpartyId: counterpartyId ?? this.counterpartyId,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    category: category ?? this.category,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    profileId: profileId.present ? profileId.value : this.profileId,
    source: source ?? this.source,
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
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      source: data.source.present ? data.source.value : this.source,
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
          ..write('createdAt: $createdAt, ')
          ..write('profileId: $profileId, ')
          ..write('source: $source')
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
    profileId,
    source,
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
          other.createdAt == this.createdAt &&
          other.profileId == this.profileId &&
          other.source == this.source);
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
  final Value<String?> profileId;
  final Value<String> source;
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
    this.profileId = const Value.absent(),
    this.source = const Value.absent(),
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
    this.profileId = const Value.absent(),
    this.source = const Value.absent(),
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
    Expression<String>? profileId,
    Expression<String>? source,
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
      if (profileId != null) 'profile_id': profileId,
      if (source != null) 'source': source,
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
    Value<String?>? profileId,
    Value<String>? source,
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
      profileId: profileId ?? this.profileId,
      source: source ?? this.source,
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
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
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
          ..write('profileId: $profileId, ')
          ..write('source: $source, ')
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
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vendorPattern,
    counterpartyId,
    category,
    profileId,
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
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
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
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
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
  final String? profileId;
  const VendorRule({
    required this.id,
    required this.vendorPattern,
    required this.counterpartyId,
    required this.category,
    this.profileId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vendor_pattern'] = Variable<String>(vendorPattern);
    map['counterparty_id'] = Variable<String>(counterpartyId);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    return map;
  }

  VendorRulesCompanion toCompanion(bool nullToAbsent) {
    return VendorRulesCompanion(
      id: Value(id),
      vendorPattern: Value(vendorPattern),
      counterpartyId: Value(counterpartyId),
      category: Value(category),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
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
      profileId: serializer.fromJson<String?>(json['profileId']),
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
      'profileId': serializer.toJson<String?>(profileId),
    };
  }

  VendorRule copyWith({
    String? id,
    String? vendorPattern,
    String? counterpartyId,
    String? category,
    Value<String?> profileId = const Value.absent(),
  }) => VendorRule(
    id: id ?? this.id,
    vendorPattern: vendorPattern ?? this.vendorPattern,
    counterpartyId: counterpartyId ?? this.counterpartyId,
    category: category ?? this.category,
    profileId: profileId.present ? profileId.value : this.profileId,
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
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VendorRule(')
          ..write('id: $id, ')
          ..write('vendorPattern: $vendorPattern, ')
          ..write('counterpartyId: $counterpartyId, ')
          ..write('category: $category, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, vendorPattern, counterpartyId, category, profileId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VendorRule &&
          other.id == this.id &&
          other.vendorPattern == this.vendorPattern &&
          other.counterpartyId == this.counterpartyId &&
          other.category == this.category &&
          other.profileId == this.profileId);
}

class VendorRulesCompanion extends UpdateCompanion<VendorRule> {
  final Value<String> id;
  final Value<String> vendorPattern;
  final Value<String> counterpartyId;
  final Value<String> category;
  final Value<String?> profileId;
  final Value<int> rowid;
  const VendorRulesCompanion({
    this.id = const Value.absent(),
    this.vendorPattern = const Value.absent(),
    this.counterpartyId = const Value.absent(),
    this.category = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VendorRulesCompanion.insert({
    required String id,
    required String vendorPattern,
    required String counterpartyId,
    required String category,
    this.profileId = const Value.absent(),
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
    Expression<String>? profileId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vendorPattern != null) 'vendor_pattern': vendorPattern,
      if (counterpartyId != null) 'counterparty_id': counterpartyId,
      if (category != null) 'category': category,
      if (profileId != null) 'profile_id': profileId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VendorRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? vendorPattern,
    Value<String>? counterpartyId,
    Value<String>? category,
    Value<String?>? profileId,
    Value<int>? rowid,
  }) {
    return VendorRulesCompanion(
      id: id ?? this.id,
      vendorPattern: vendorPattern ?? this.vendorPattern,
      counterpartyId: counterpartyId ?? this.counterpartyId,
      category: category ?? this.category,
      profileId: profileId ?? this.profileId,
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
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
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
          ..write('profileId: $profileId, ')
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
  static const VerificationMeta _manualInputEntriesJsonMeta =
      const VerificationMeta('manualInputEntriesJson');
  @override
  late final GeneratedColumn<String> manualInputEntriesJson =
      GeneratedColumn<String>(
        'manual_input_entries_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _cardsRecordedMeta = const VerificationMeta(
    'cardsRecorded',
  );
  @override
  late final GeneratedColumn<bool> cardsRecorded = GeneratedColumn<bool>(
    'cards_recorded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cards_recorded" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _manualInputsRecordedMeta =
      const VerificationMeta('manualInputsRecorded');
  @override
  late final GeneratedColumn<bool> manualInputsRecorded = GeneratedColumn<bool>(
    'manual_inputs_recorded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("manual_inputs_recorded" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _bankAccountEntriesJsonMeta =
      const VerificationMeta('bankAccountEntriesJson');
  @override
  late final GeneratedColumn<String> bankAccountEntriesJson =
      GeneratedColumn<String>(
        'bank_account_entries_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
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
    manualInputEntriesJson,
    cardsRecorded,
    manualInputsRecorded,
    bankAccountEntriesJson,
    profileId,
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
    if (data.containsKey('manual_input_entries_json')) {
      context.handle(
        _manualInputEntriesJsonMeta,
        manualInputEntriesJson.isAcceptableOrUnknown(
          data['manual_input_entries_json']!,
          _manualInputEntriesJsonMeta,
        ),
      );
    }
    if (data.containsKey('cards_recorded')) {
      context.handle(
        _cardsRecordedMeta,
        cardsRecorded.isAcceptableOrUnknown(
          data['cards_recorded']!,
          _cardsRecordedMeta,
        ),
      );
    }
    if (data.containsKey('manual_inputs_recorded')) {
      context.handle(
        _manualInputsRecordedMeta,
        manualInputsRecorded.isAcceptableOrUnknown(
          data['manual_inputs_recorded']!,
          _manualInputsRecordedMeta,
        ),
      );
    }
    if (data.containsKey('bank_account_entries_json')) {
      context.handle(
        _bankAccountEntriesJsonMeta,
        bankAccountEntriesJson.isAcceptableOrUnknown(
          data['bank_account_entries_json']!,
          _bankAccountEntriesJsonMeta,
        ),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
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
      manualInputEntriesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manual_input_entries_json'],
      )!,
      cardsRecorded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cards_recorded'],
      )!,
      manualInputsRecorded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}manual_inputs_recorded'],
      )!,
      bankAccountEntriesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_account_entries_json'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
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

  /// JSON-encoded list of per-manual-input entries — one per ManualInput
  /// row that existed at save time (see ManualInputSnapshotEntry). Empty
  /// list (`'[]'`, the default) on every snapshot saved before manual
  /// inputs became user-managed; the fixed apartmentSavings/
  /// cibAccountBalance columns above carry those instead, and are never
  /// written to again by any snapshot saved after this point.
  final String manualInputEntriesJson;

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
  final bool cardsRecorded;

  /// Same idea as [cardsRecorded], for [manualInputEntriesJson].
  final bool manualInputsRecorded;

  /// JSON-encoded list of per-bank-account entries (see
  /// BankAccountSnapshotEntry) -- one per BankAccount row that existed at
  /// save time. Unlike [cardEntriesJson]/[manualInputEntriesJson], bank
  /// accounts have no fixed legacy predecessor to distinguish an empty
  /// list from, so no matching "*Recorded" flag is needed: an empty list
  /// unambiguously means "no bank accounts configured" on every snapshot,
  /// old or new.
  final String bankAccountEntriesJson;
  final String? profileId;
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
    required this.manualInputEntriesJson,
    required this.cardsRecorded,
    required this.manualInputsRecorded,
    required this.bankAccountEntriesJson,
    this.profileId,
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
    map['manual_input_entries_json'] = Variable<String>(manualInputEntriesJson);
    map['cards_recorded'] = Variable<bool>(cardsRecorded);
    map['manual_inputs_recorded'] = Variable<bool>(manualInputsRecorded);
    map['bank_account_entries_json'] = Variable<String>(bankAccountEntriesJson);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
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
      manualInputEntriesJson: Value(manualInputEntriesJson),
      cardsRecorded: Value(cardsRecorded),
      manualInputsRecorded: Value(manualInputsRecorded),
      bankAccountEntriesJson: Value(bankAccountEntriesJson),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
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
      manualInputEntriesJson: serializer.fromJson<String>(
        json['manualInputEntriesJson'],
      ),
      cardsRecorded: serializer.fromJson<bool>(json['cardsRecorded']),
      manualInputsRecorded: serializer.fromJson<bool>(
        json['manualInputsRecorded'],
      ),
      bankAccountEntriesJson: serializer.fromJson<String>(
        json['bankAccountEntriesJson'],
      ),
      profileId: serializer.fromJson<String?>(json['profileId']),
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
      'manualInputEntriesJson': serializer.toJson<String>(
        manualInputEntriesJson,
      ),
      'cardsRecorded': serializer.toJson<bool>(cardsRecorded),
      'manualInputsRecorded': serializer.toJson<bool>(manualInputsRecorded),
      'bankAccountEntriesJson': serializer.toJson<String>(
        bankAccountEntriesJson,
      ),
      'profileId': serializer.toJson<String?>(profileId),
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
    String? manualInputEntriesJson,
    bool? cardsRecorded,
    bool? manualInputsRecorded,
    String? bankAccountEntriesJson,
    Value<String?> profileId = const Value.absent(),
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
    manualInputEntriesJson:
        manualInputEntriesJson ?? this.manualInputEntriesJson,
    cardsRecorded: cardsRecorded ?? this.cardsRecorded,
    manualInputsRecorded: manualInputsRecorded ?? this.manualInputsRecorded,
    bankAccountEntriesJson:
        bankAccountEntriesJson ?? this.bankAccountEntriesJson,
    profileId: profileId.present ? profileId.value : this.profileId,
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
      manualInputEntriesJson: data.manualInputEntriesJson.present
          ? data.manualInputEntriesJson.value
          : this.manualInputEntriesJson,
      cardsRecorded: data.cardsRecorded.present
          ? data.cardsRecorded.value
          : this.cardsRecorded,
      manualInputsRecorded: data.manualInputsRecorded.present
          ? data.manualInputsRecorded.value
          : this.manualInputsRecorded,
      bankAccountEntriesJson: data.bankAccountEntriesJson.present
          ? data.bankAccountEntriesJson.value
          : this.bankAccountEntriesJson,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
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
          ..write('cardEntriesJson: $cardEntriesJson, ')
          ..write('manualInputEntriesJson: $manualInputEntriesJson, ')
          ..write('cardsRecorded: $cardsRecorded, ')
          ..write('manualInputsRecorded: $manualInputsRecorded, ')
          ..write('bankAccountEntriesJson: $bankAccountEntriesJson, ')
          ..write('profileId: $profileId')
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
    manualInputEntriesJson,
    cardsRecorded,
    manualInputsRecorded,
    bankAccountEntriesJson,
    profileId,
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
          other.cardEntriesJson == this.cardEntriesJson &&
          other.manualInputEntriesJson == this.manualInputEntriesJson &&
          other.cardsRecorded == this.cardsRecorded &&
          other.manualInputsRecorded == this.manualInputsRecorded &&
          other.bankAccountEntriesJson == this.bankAccountEntriesJson &&
          other.profileId == this.profileId);
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
  final Value<String> manualInputEntriesJson;
  final Value<bool> cardsRecorded;
  final Value<bool> manualInputsRecorded;
  final Value<String> bankAccountEntriesJson;
  final Value<String?> profileId;
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
    this.manualInputEntriesJson = const Value.absent(),
    this.cardsRecorded = const Value.absent(),
    this.manualInputsRecorded = const Value.absent(),
    this.bankAccountEntriesJson = const Value.absent(),
    this.profileId = const Value.absent(),
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
    this.manualInputEntriesJson = const Value.absent(),
    this.cardsRecorded = const Value.absent(),
    this.manualInputsRecorded = const Value.absent(),
    this.bankAccountEntriesJson = const Value.absent(),
    this.profileId = const Value.absent(),
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
    Expression<String>? manualInputEntriesJson,
    Expression<bool>? cardsRecorded,
    Expression<bool>? manualInputsRecorded,
    Expression<String>? bankAccountEntriesJson,
    Expression<String>? profileId,
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
      if (manualInputEntriesJson != null)
        'manual_input_entries_json': manualInputEntriesJson,
      if (cardsRecorded != null) 'cards_recorded': cardsRecorded,
      if (manualInputsRecorded != null)
        'manual_inputs_recorded': manualInputsRecorded,
      if (bankAccountEntriesJson != null)
        'bank_account_entries_json': bankAccountEntriesJson,
      if (profileId != null) 'profile_id': profileId,
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
    Value<String>? manualInputEntriesJson,
    Value<bool>? cardsRecorded,
    Value<bool>? manualInputsRecorded,
    Value<String>? bankAccountEntriesJson,
    Value<String?>? profileId,
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
      manualInputEntriesJson:
          manualInputEntriesJson ?? this.manualInputEntriesJson,
      cardsRecorded: cardsRecorded ?? this.cardsRecorded,
      manualInputsRecorded: manualInputsRecorded ?? this.manualInputsRecorded,
      bankAccountEntriesJson:
          bankAccountEntriesJson ?? this.bankAccountEntriesJson,
      profileId: profileId ?? this.profileId,
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
    if (manualInputEntriesJson.present) {
      map['manual_input_entries_json'] = Variable<String>(
        manualInputEntriesJson.value,
      );
    }
    if (cardsRecorded.present) {
      map['cards_recorded'] = Variable<bool>(cardsRecorded.value);
    }
    if (manualInputsRecorded.present) {
      map['manual_inputs_recorded'] = Variable<bool>(
        manualInputsRecorded.value,
      );
    }
    if (bankAccountEntriesJson.present) {
      map['bank_account_entries_json'] = Variable<String>(
        bankAccountEntriesJson.value,
      );
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
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
          ..write('manualInputEntriesJson: $manualInputEntriesJson, ')
          ..write('cardsRecorded: $cardsRecorded, ')
          ..write('manualInputsRecorded: $manualInputsRecorded, ')
          ..write('bankAccountEntriesJson: $bankAccountEntriesJson, ')
          ..write('profileId: $profileId, ')
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
  static const VerificationMeta _currentAvailableBalanceMeta =
      const VerificationMeta('currentAvailableBalance');
  @override
  late final GeneratedColumn<double> currentAvailableBalance =
      GeneratedColumn<double>(
        'current_available_balance',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _balanceUpdatedAtMeta = const VerificationMeta(
    'balanceUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> balanceUpdatedAt =
      GeneratedColumn<DateTime>(
        'balance_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _balanceUpdatedSourceMeta =
      const VerificationMeta('balanceUpdatedSource');
  @override
  late final GeneratedColumn<String> balanceUpdatedSource =
      GeneratedColumn<String>(
        'balance_updated_source',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
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
    currentAvailableBalance,
    balanceUpdatedAt,
    balanceUpdatedSource,
    profileId,
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
    if (data.containsKey('current_available_balance')) {
      context.handle(
        _currentAvailableBalanceMeta,
        currentAvailableBalance.isAcceptableOrUnknown(
          data['current_available_balance']!,
          _currentAvailableBalanceMeta,
        ),
      );
    }
    if (data.containsKey('balance_updated_at')) {
      context.handle(
        _balanceUpdatedAtMeta,
        balanceUpdatedAt.isAcceptableOrUnknown(
          data['balance_updated_at']!,
          _balanceUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('balance_updated_source')) {
      context.handle(
        _balanceUpdatedSourceMeta,
        balanceUpdatedSource.isAcceptableOrUnknown(
          data['balance_updated_source']!,
          _balanceUpdatedSourceMeta,
        ),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
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
      currentAvailableBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_available_balance'],
      ),
      balanceUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}balance_updated_at'],
      ),
      balanceUpdatedSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}balance_updated_source'],
      ),
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
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
  /// alerts (e.g. "...ending in 4912") — lets SMS-based balance tracking
  /// know which card a given message is about.
  final String? lastFourDigits;

  /// Available-to-spend balance, kept current by SMS capture (or left null
  /// until the user first types one into the Calculator). Separate from any
  /// particular Calculator session's typed value — this is the card's own
  /// remembered state, in [currency].
  final double? currentAvailableBalance;

  /// When [currentAvailableBalance] was last set -- by a parsed SMS, or by
  /// the user editing the Calculator tab's balance field directly (see
  /// CalculatorScreen's debounced save-back) -- whichever happened most
  /// recently. Null if it's never been touched by either.
  final DateTime? balanceUpdatedAt;

  /// 'sms' or 'manual', matching whichever of the two actually last set
  /// [currentAvailableBalance]/[balanceUpdatedAt] -- shown alongside that
  /// timestamp so "Updated 2h ago" doesn't leave the user guessing whether
  /// that was a real bank alert or their own typed correction. Null exactly
  /// when [balanceUpdatedAt] is (never touched by either yet).
  final String? balanceUpdatedSource;
  final String? profileId;
  const CreditCard({
    required this.id,
    required this.name,
    required this.bank,
    required this.limitAmount,
    required this.currency,
    required this.sortOrder,
    this.lastFourDigits,
    this.currentAvailableBalance,
    this.balanceUpdatedAt,
    this.balanceUpdatedSource,
    this.profileId,
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
    if (!nullToAbsent || currentAvailableBalance != null) {
      map['current_available_balance'] = Variable<double>(
        currentAvailableBalance,
      );
    }
    if (!nullToAbsent || balanceUpdatedAt != null) {
      map['balance_updated_at'] = Variable<DateTime>(balanceUpdatedAt);
    }
    if (!nullToAbsent || balanceUpdatedSource != null) {
      map['balance_updated_source'] = Variable<String>(balanceUpdatedSource);
    }
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
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
      currentAvailableBalance: currentAvailableBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(currentAvailableBalance),
      balanceUpdatedAt: balanceUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(balanceUpdatedAt),
      balanceUpdatedSource: balanceUpdatedSource == null && nullToAbsent
          ? const Value.absent()
          : Value(balanceUpdatedSource),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
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
      currentAvailableBalance: serializer.fromJson<double?>(
        json['currentAvailableBalance'],
      ),
      balanceUpdatedAt: serializer.fromJson<DateTime?>(
        json['balanceUpdatedAt'],
      ),
      balanceUpdatedSource: serializer.fromJson<String?>(
        json['balanceUpdatedSource'],
      ),
      profileId: serializer.fromJson<String?>(json['profileId']),
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
      'currentAvailableBalance': serializer.toJson<double?>(
        currentAvailableBalance,
      ),
      'balanceUpdatedAt': serializer.toJson<DateTime?>(balanceUpdatedAt),
      'balanceUpdatedSource': serializer.toJson<String?>(balanceUpdatedSource),
      'profileId': serializer.toJson<String?>(profileId),
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
    Value<double?> currentAvailableBalance = const Value.absent(),
    Value<DateTime?> balanceUpdatedAt = const Value.absent(),
    Value<String?> balanceUpdatedSource = const Value.absent(),
    Value<String?> profileId = const Value.absent(),
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
    currentAvailableBalance: currentAvailableBalance.present
        ? currentAvailableBalance.value
        : this.currentAvailableBalance,
    balanceUpdatedAt: balanceUpdatedAt.present
        ? balanceUpdatedAt.value
        : this.balanceUpdatedAt,
    balanceUpdatedSource: balanceUpdatedSource.present
        ? balanceUpdatedSource.value
        : this.balanceUpdatedSource,
    profileId: profileId.present ? profileId.value : this.profileId,
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
      currentAvailableBalance: data.currentAvailableBalance.present
          ? data.currentAvailableBalance.value
          : this.currentAvailableBalance,
      balanceUpdatedAt: data.balanceUpdatedAt.present
          ? data.balanceUpdatedAt.value
          : this.balanceUpdatedAt,
      balanceUpdatedSource: data.balanceUpdatedSource.present
          ? data.balanceUpdatedSource.value
          : this.balanceUpdatedSource,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
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
          ..write('lastFourDigits: $lastFourDigits, ')
          ..write('currentAvailableBalance: $currentAvailableBalance, ')
          ..write('balanceUpdatedAt: $balanceUpdatedAt, ')
          ..write('balanceUpdatedSource: $balanceUpdatedSource, ')
          ..write('profileId: $profileId')
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
    currentAvailableBalance,
    balanceUpdatedAt,
    balanceUpdatedSource,
    profileId,
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
          other.lastFourDigits == this.lastFourDigits &&
          other.currentAvailableBalance == this.currentAvailableBalance &&
          other.balanceUpdatedAt == this.balanceUpdatedAt &&
          other.balanceUpdatedSource == this.balanceUpdatedSource &&
          other.profileId == this.profileId);
}

class CreditCardsCompanion extends UpdateCompanion<CreditCard> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> bank;
  final Value<double> limitAmount;
  final Value<String> currency;
  final Value<int> sortOrder;
  final Value<String?> lastFourDigits;
  final Value<double?> currentAvailableBalance;
  final Value<DateTime?> balanceUpdatedAt;
  final Value<String?> balanceUpdatedSource;
  final Value<String?> profileId;
  final Value<int> rowid;
  const CreditCardsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.bank = const Value.absent(),
    this.limitAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastFourDigits = const Value.absent(),
    this.currentAvailableBalance = const Value.absent(),
    this.balanceUpdatedAt = const Value.absent(),
    this.balanceUpdatedSource = const Value.absent(),
    this.profileId = const Value.absent(),
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
    this.currentAvailableBalance = const Value.absent(),
    this.balanceUpdatedAt = const Value.absent(),
    this.balanceUpdatedSource = const Value.absent(),
    this.profileId = const Value.absent(),
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
    Expression<double>? currentAvailableBalance,
    Expression<DateTime>? balanceUpdatedAt,
    Expression<String>? balanceUpdatedSource,
    Expression<String>? profileId,
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
      if (currentAvailableBalance != null)
        'current_available_balance': currentAvailableBalance,
      if (balanceUpdatedAt != null) 'balance_updated_at': balanceUpdatedAt,
      if (balanceUpdatedSource != null)
        'balance_updated_source': balanceUpdatedSource,
      if (profileId != null) 'profile_id': profileId,
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
    Value<double?>? currentAvailableBalance,
    Value<DateTime?>? balanceUpdatedAt,
    Value<String?>? balanceUpdatedSource,
    Value<String?>? profileId,
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
      currentAvailableBalance:
          currentAvailableBalance ?? this.currentAvailableBalance,
      balanceUpdatedAt: balanceUpdatedAt ?? this.balanceUpdatedAt,
      balanceUpdatedSource: balanceUpdatedSource ?? this.balanceUpdatedSource,
      profileId: profileId ?? this.profileId,
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
    if (currentAvailableBalance.present) {
      map['current_available_balance'] = Variable<double>(
        currentAvailableBalance.value,
      );
    }
    if (balanceUpdatedAt.present) {
      map['balance_updated_at'] = Variable<DateTime>(balanceUpdatedAt.value);
    }
    if (balanceUpdatedSource.present) {
      map['balance_updated_source'] = Variable<String>(
        balanceUpdatedSource.value,
      );
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
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
          ..write('currentAvailableBalance: $currentAvailableBalance, ')
          ..write('balanceUpdatedAt: $balanceUpdatedAt, ')
          ..write('balanceUpdatedSource: $balanceUpdatedSource, ')
          ..write('profileId: $profileId, ')
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
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, icon, profileId];
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
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
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
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
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

  /// A single emoji representing this category, picked from a fixed set in
  /// Settings -> Categories & icons. Null falls back to a generic receipt
  /// glyph wherever it's displayed.
  final String? icon;
  final String? profileId;
  const LedgerCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.icon,
    this.profileId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    return map;
  }

  LedgerCategoriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
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
      icon: serializer.fromJson<String?>(json['icon']),
      profileId: serializer.fromJson<String?>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'icon': serializer.toJson<String?>(icon),
      'profileId': serializer.toJson<String?>(profileId),
    };
  }

  LedgerCategory copyWith({
    String? id,
    String? name,
    int? sortOrder,
    Value<String?> icon = const Value.absent(),
    Value<String?> profileId = const Value.absent(),
  }) => LedgerCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    icon: icon.present ? icon.value : this.icon,
    profileId: profileId.present ? profileId.value : this.profileId,
  );
  LedgerCategory copyWithCompanion(LedgerCategoriesCompanion data) {
    return LedgerCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      icon: data.icon.present ? data.icon.value : this.icon,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('icon: $icon, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, icon, profileId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.icon == this.icon &&
          other.profileId == this.profileId);
}

class LedgerCategoriesCompanion extends UpdateCompanion<LedgerCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<String?> icon;
  final Value<String?> profileId;
  final Value<int> rowid;
  const LedgerCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.icon = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerCategoriesCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    this.icon = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<LedgerCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<String>? icon,
    Expression<String>? profileId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (icon != null) 'icon': icon,
      if (profileId != null) 'profile_id': profileId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<String?>? icon,
    Value<String?>? profileId,
    Value<int>? rowid,
  }) {
    return LedgerCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      icon: icon ?? this.icon,
      profileId: profileId ?? this.profileId,
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
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
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
          ..write('icon: $icon, ')
          ..write('profileId: $profileId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ManualInputsTable extends ManualInputs
    with TableInfo<$ManualInputsTable, ManualInput> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManualInputsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _isAdditionMeta = const VerificationMeta(
    'isAddition',
  );
  @override
  late final GeneratedColumn<bool> isAddition = GeneratedColumn<bool>(
    'is_addition',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_addition" IN (0, 1))',
    ),
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
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  static const VerificationMeta _currentValueMeta = const VerificationMeta(
    'currentValue',
  );
  @override
  late final GeneratedColumn<double> currentValue = GeneratedColumn<double>(
    'current_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    isAddition,
    currency,
    sortOrder,
    profileId,
    currentValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manual_inputs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ManualInput> instance, {
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
    if (data.containsKey('is_addition')) {
      context.handle(
        _isAdditionMeta,
        isAddition.isAcceptableOrUnknown(data['is_addition']!, _isAdditionMeta),
      );
    } else if (isInserting) {
      context.missing(_isAdditionMeta);
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
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('current_value')) {
      context.handle(
        _currentValueMeta,
        currentValue.isAcceptableOrUnknown(
          data['current_value']!,
          _currentValueMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ManualInput map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ManualInput(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isAddition: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_addition'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
      currentValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_value'],
      ),
    );
  }

  @override
  $ManualInputsTable createAlias(String alias) {
    return $ManualInputsTable(attachedDatabase, alias);
  }
}

class ManualInput extends DataClass implements Insertable<ManualInput> {
  final String id;
  final String name;
  final bool isAddition;
  final String currency;

  /// Manual ordering for display — set to insertion order by default, but
  /// not tied to it, so a future "reorder" gesture has somewhere to write.
  final int sortOrder;
  final String? profileId;

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
  final double? currentValue;
  const ManualInput({
    required this.id,
    required this.name,
    required this.isAddition,
    required this.currency,
    required this.sortOrder,
    this.profileId,
    this.currentValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_addition'] = Variable<bool>(isAddition);
    map['currency'] = Variable<String>(currency);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    if (!nullToAbsent || currentValue != null) {
      map['current_value'] = Variable<double>(currentValue);
    }
    return map;
  }

  ManualInputsCompanion toCompanion(bool nullToAbsent) {
    return ManualInputsCompanion(
      id: Value(id),
      name: Value(name),
      isAddition: Value(isAddition),
      currency: Value(currency),
      sortOrder: Value(sortOrder),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      currentValue: currentValue == null && nullToAbsent
          ? const Value.absent()
          : Value(currentValue),
    );
  }

  factory ManualInput.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ManualInput(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isAddition: serializer.fromJson<bool>(json['isAddition']),
      currency: serializer.fromJson<String>(json['currency']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      profileId: serializer.fromJson<String?>(json['profileId']),
      currentValue: serializer.fromJson<double?>(json['currentValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'isAddition': serializer.toJson<bool>(isAddition),
      'currency': serializer.toJson<String>(currency),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'profileId': serializer.toJson<String?>(profileId),
      'currentValue': serializer.toJson<double?>(currentValue),
    };
  }

  ManualInput copyWith({
    String? id,
    String? name,
    bool? isAddition,
    String? currency,
    int? sortOrder,
    Value<String?> profileId = const Value.absent(),
    Value<double?> currentValue = const Value.absent(),
  }) => ManualInput(
    id: id ?? this.id,
    name: name ?? this.name,
    isAddition: isAddition ?? this.isAddition,
    currency: currency ?? this.currency,
    sortOrder: sortOrder ?? this.sortOrder,
    profileId: profileId.present ? profileId.value : this.profileId,
    currentValue: currentValue.present ? currentValue.value : this.currentValue,
  );
  ManualInput copyWithCompanion(ManualInputsCompanion data) {
    return ManualInput(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isAddition: data.isAddition.present
          ? data.isAddition.value
          : this.isAddition,
      currency: data.currency.present ? data.currency.value : this.currency,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      currentValue: data.currentValue.present
          ? data.currentValue.value
          : this.currentValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ManualInput(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isAddition: $isAddition, ')
          ..write('currency: $currency, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('profileId: $profileId, ')
          ..write('currentValue: $currentValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    isAddition,
    currency,
    sortOrder,
    profileId,
    currentValue,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManualInput &&
          other.id == this.id &&
          other.name == this.name &&
          other.isAddition == this.isAddition &&
          other.currency == this.currency &&
          other.sortOrder == this.sortOrder &&
          other.profileId == this.profileId &&
          other.currentValue == this.currentValue);
}

class ManualInputsCompanion extends UpdateCompanion<ManualInput> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isAddition;
  final Value<String> currency;
  final Value<int> sortOrder;
  final Value<String?> profileId;
  final Value<double?> currentValue;
  final Value<int> rowid;
  const ManualInputsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isAddition = const Value.absent(),
    this.currency = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.profileId = const Value.absent(),
    this.currentValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ManualInputsCompanion.insert({
    required String id,
    required String name,
    required bool isAddition,
    this.currency = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.profileId = const Value.absent(),
    this.currentValue = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       isAddition = Value(isAddition);
  static Insertable<ManualInput> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? isAddition,
    Expression<String>? currency,
    Expression<int>? sortOrder,
    Expression<String>? profileId,
    Expression<double>? currentValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isAddition != null) 'is_addition': isAddition,
      if (currency != null) 'currency': currency,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (profileId != null) 'profile_id': profileId,
      if (currentValue != null) 'current_value': currentValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ManualInputsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? isAddition,
    Value<String>? currency,
    Value<int>? sortOrder,
    Value<String?>? profileId,
    Value<double?>? currentValue,
    Value<int>? rowid,
  }) {
    return ManualInputsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isAddition: isAddition ?? this.isAddition,
      currency: currency ?? this.currency,
      sortOrder: sortOrder ?? this.sortOrder,
      profileId: profileId ?? this.profileId,
      currentValue: currentValue ?? this.currentValue,
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
    if (isAddition.present) {
      map['is_addition'] = Variable<bool>(isAddition.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (currentValue.present) {
      map['current_value'] = Variable<double>(currentValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManualInputsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isAddition: $isAddition, ')
          ..write('currency: $currency, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('profileId: $profileId, ')
          ..write('currentValue: $currentValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringPaymentsTable extends RecurringPayments
    with TableInfo<$RecurringPaymentsTable, RecurringPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringPaymentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _isExactAmountMeta = const VerificationMeta(
    'isExactAmount',
  );
  @override
  late final GeneratedColumn<bool> isExactAmount = GeneratedColumn<bool>(
    'is_exact_amount',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_exact_amount" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _dayOfMonthMeta = const VerificationMeta(
    'dayOfMonth',
  );
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
    'day_of_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalAnchorDateMeta =
      const VerificationMeta('intervalAnchorDate');
  @override
  late final GeneratedColumn<DateTime> intervalAnchorDate =
      GeneratedColumn<DateTime>(
        'interval_anchor_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _yearlyMonthMeta = const VerificationMeta(
    'yearlyMonth',
  );
  @override
  late final GeneratedColumn<int> yearlyMonth = GeneratedColumn<int>(
    'yearly_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearlyDayMeta = const VerificationMeta(
    'yearlyDay',
  );
  @override
  late final GeneratedColumn<int> yearlyDay = GeneratedColumn<int>(
    'yearly_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPaidAtMeta = const VerificationMeta(
    'lastPaidAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPaidAt = GeneratedColumn<DateTime>(
    'last_paid_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  static const VerificationMeta _paymentModeMeta = const VerificationMeta(
    'paymentMode',
  );
  @override
  late final GeneratedColumn<String> paymentMode = GeneratedColumn<String>(
    'payment_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amount,
    currency,
    isExactAmount,
    dayOfMonth,
    sortOrder,
    profileId,
    frequency,
    intervalDays,
    intervalAnchorDate,
    yearlyMonth,
    yearlyDay,
    lastPaidAt,
    notes,
    paymentMode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringPayment> instance, {
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
    if (data.containsKey('is_exact_amount')) {
      context.handle(
        _isExactAmountMeta,
        isExactAmount.isAcceptableOrUnknown(
          data['is_exact_amount']!,
          _isExactAmountMeta,
        ),
      );
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
        _dayOfMonthMeta,
        dayOfMonth.isAcceptableOrUnknown(
          data['day_of_month']!,
          _dayOfMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayOfMonthMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('interval_anchor_date')) {
      context.handle(
        _intervalAnchorDateMeta,
        intervalAnchorDate.isAcceptableOrUnknown(
          data['interval_anchor_date']!,
          _intervalAnchorDateMeta,
        ),
      );
    }
    if (data.containsKey('yearly_month')) {
      context.handle(
        _yearlyMonthMeta,
        yearlyMonth.isAcceptableOrUnknown(
          data['yearly_month']!,
          _yearlyMonthMeta,
        ),
      );
    }
    if (data.containsKey('yearly_day')) {
      context.handle(
        _yearlyDayMeta,
        yearlyDay.isAcceptableOrUnknown(data['yearly_day']!, _yearlyDayMeta),
      );
    }
    if (data.containsKey('last_paid_at')) {
      context.handle(
        _lastPaidAtMeta,
        lastPaidAt.isAcceptableOrUnknown(
          data['last_paid_at']!,
          _lastPaidAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('payment_mode')) {
      context.handle(
        _paymentModeMeta,
        paymentMode.isAcceptableOrUnknown(
          data['payment_mode']!,
          _paymentModeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringPayment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      isExactAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_exact_amount'],
      )!,
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      ),
      intervalAnchorDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}interval_anchor_date'],
      ),
      yearlyMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yearly_month'],
      ),
      yearlyDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yearly_day'],
      ),
      lastPaidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_paid_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      paymentMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_mode'],
      )!,
    );
  }

  @override
  $RecurringPaymentsTable createAlias(String alias) {
    return $RecurringPaymentsTable(attachedDatabase, alias);
  }
}

class RecurringPayment extends DataClass
    implements Insertable<RecurringPayment> {
  final String id;
  final String name;
  final double amount;
  final String currency;

  /// True when [amount] is the exact charge every month; false when it's
  /// only a floor -- a usage-based bill that's never less than this but can
  /// run higher (e.g. a metered utility). Surfaced as a small "min." badge
  /// wherever this shows; still summed at face value into the tab's
  /// monthly total either way, since that's the best available estimate
  /// without knowing the real bill in advance.
  final bool isExactAmount;

  /// Day of the month (1-31) this bills on -- not a full date, since the
  /// whole point is "every month on this day," not one specific
  /// occurrence. A day past a shorter month's own last day (e.g. 31 in
  /// February) is left for display logic to clamp, not stored specially.
  /// Only meaningful when [frequency] is 'monthly'; for any other
  /// frequency this still holds a value (never null -- see the column's
  /// own NOT NULL constraint, kept rather than loosened to avoid an
  /// ALTER-driven migration) but it's a meaningless placeholder the app
  /// never reads.
  final int dayOfMonth;

  /// Manual ordering for display — set to insertion order by default, but
  /// not tied to it, so a future "reorder" gesture has somewhere to write.
  final int sortOrder;
  final String? profileId;

  /// 'monthly' | 'interval' | 'yearly' -- see
  /// core/models/recurring_payment_frequency.dart. Defaults to 'monthly'
  /// so every row created before this column existed (the only kind that
  /// existed then) keeps reading correctly with no backfill needed.
  final String frequency;

  /// Only meaningful when [frequency] is 'interval': how many days between
  /// occurrences (e.g. 10 for "every 10 days").
  final int? intervalDays;

  /// Only meaningful when [frequency] is 'interval': the date the interval
  /// counts from. The due date is always computed fresh as the next
  /// multiple of [intervalDays] on/after this anchor (see
  /// recurring_payment_due.dart) rather than stored and advanced, so it
  /// can never drift out of sync with a missed "mark as paid" tap.
  final DateTime? intervalAnchorDate;

  /// Only meaningful when [frequency] is 'yearly': the month (1-12) this
  /// bills on every year.
  final int? yearlyMonth;

  /// Only meaningful when [frequency] is 'yearly': the day of that month
  /// (1-31), clamped the same way [dayOfMonth] is for a shorter month.
  final int? yearlyDay;

  /// When the user last tapped "mark as paid" -- drives the green
  /// paid/pending state and the total card's paid/pending split. Compared
  /// against the *current* billing cycle (recurring_payment_due.dart), not
  /// just "is this non-null", so a paid-mark from a previous cycle
  /// automatically reads as pending again once a new one comes due.
  final DateTime? lastPaidAt;

  /// Free-text notes -- e.g. account numbers, a reason the amount varies,
  /// anything the fixed fields above don't capture. Optional, shown under
  /// the name wherever this payment displays.
  final String? notes;

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
  final String paymentMode;
  const RecurringPayment({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.isExactAmount,
    required this.dayOfMonth,
    required this.sortOrder,
    this.profileId,
    required this.frequency,
    this.intervalDays,
    this.intervalAnchorDate,
    this.yearlyMonth,
    this.yearlyDay,
    this.lastPaidAt,
    this.notes,
    required this.paymentMode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['is_exact_amount'] = Variable<bool>(isExactAmount);
    map['day_of_month'] = Variable<int>(dayOfMonth);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    map['frequency'] = Variable<String>(frequency);
    if (!nullToAbsent || intervalDays != null) {
      map['interval_days'] = Variable<int>(intervalDays);
    }
    if (!nullToAbsent || intervalAnchorDate != null) {
      map['interval_anchor_date'] = Variable<DateTime>(intervalAnchorDate);
    }
    if (!nullToAbsent || yearlyMonth != null) {
      map['yearly_month'] = Variable<int>(yearlyMonth);
    }
    if (!nullToAbsent || yearlyDay != null) {
      map['yearly_day'] = Variable<int>(yearlyDay);
    }
    if (!nullToAbsent || lastPaidAt != null) {
      map['last_paid_at'] = Variable<DateTime>(lastPaidAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['payment_mode'] = Variable<String>(paymentMode);
    return map;
  }

  RecurringPaymentsCompanion toCompanion(bool nullToAbsent) {
    return RecurringPaymentsCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      currency: Value(currency),
      isExactAmount: Value(isExactAmount),
      dayOfMonth: Value(dayOfMonth),
      sortOrder: Value(sortOrder),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      frequency: Value(frequency),
      intervalDays: intervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDays),
      intervalAnchorDate: intervalAnchorDate == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalAnchorDate),
      yearlyMonth: yearlyMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(yearlyMonth),
      yearlyDay: yearlyDay == null && nullToAbsent
          ? const Value.absent()
          : Value(yearlyDay),
      lastPaidAt: lastPaidAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPaidAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      paymentMode: Value(paymentMode),
    );
  }

  factory RecurringPayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringPayment(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      isExactAmount: serializer.fromJson<bool>(json['isExactAmount']),
      dayOfMonth: serializer.fromJson<int>(json['dayOfMonth']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      profileId: serializer.fromJson<String?>(json['profileId']),
      frequency: serializer.fromJson<String>(json['frequency']),
      intervalDays: serializer.fromJson<int?>(json['intervalDays']),
      intervalAnchorDate: serializer.fromJson<DateTime?>(
        json['intervalAnchorDate'],
      ),
      yearlyMonth: serializer.fromJson<int?>(json['yearlyMonth']),
      yearlyDay: serializer.fromJson<int?>(json['yearlyDay']),
      lastPaidAt: serializer.fromJson<DateTime?>(json['lastPaidAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      paymentMode: serializer.fromJson<String>(json['paymentMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'isExactAmount': serializer.toJson<bool>(isExactAmount),
      'dayOfMonth': serializer.toJson<int>(dayOfMonth),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'profileId': serializer.toJson<String?>(profileId),
      'frequency': serializer.toJson<String>(frequency),
      'intervalDays': serializer.toJson<int?>(intervalDays),
      'intervalAnchorDate': serializer.toJson<DateTime?>(intervalAnchorDate),
      'yearlyMonth': serializer.toJson<int?>(yearlyMonth),
      'yearlyDay': serializer.toJson<int?>(yearlyDay),
      'lastPaidAt': serializer.toJson<DateTime?>(lastPaidAt),
      'notes': serializer.toJson<String?>(notes),
      'paymentMode': serializer.toJson<String>(paymentMode),
    };
  }

  RecurringPayment copyWith({
    String? id,
    String? name,
    double? amount,
    String? currency,
    bool? isExactAmount,
    int? dayOfMonth,
    int? sortOrder,
    Value<String?> profileId = const Value.absent(),
    String? frequency,
    Value<int?> intervalDays = const Value.absent(),
    Value<DateTime?> intervalAnchorDate = const Value.absent(),
    Value<int?> yearlyMonth = const Value.absent(),
    Value<int?> yearlyDay = const Value.absent(),
    Value<DateTime?> lastPaidAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? paymentMode,
  }) => RecurringPayment(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    isExactAmount: isExactAmount ?? this.isExactAmount,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    sortOrder: sortOrder ?? this.sortOrder,
    profileId: profileId.present ? profileId.value : this.profileId,
    frequency: frequency ?? this.frequency,
    intervalDays: intervalDays.present ? intervalDays.value : this.intervalDays,
    intervalAnchorDate: intervalAnchorDate.present
        ? intervalAnchorDate.value
        : this.intervalAnchorDate,
    yearlyMonth: yearlyMonth.present ? yearlyMonth.value : this.yearlyMonth,
    yearlyDay: yearlyDay.present ? yearlyDay.value : this.yearlyDay,
    lastPaidAt: lastPaidAt.present ? lastPaidAt.value : this.lastPaidAt,
    notes: notes.present ? notes.value : this.notes,
    paymentMode: paymentMode ?? this.paymentMode,
  );
  RecurringPayment copyWithCompanion(RecurringPaymentsCompanion data) {
    return RecurringPayment(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      isExactAmount: data.isExactAmount.present
          ? data.isExactAmount.value
          : this.isExactAmount,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      intervalAnchorDate: data.intervalAnchorDate.present
          ? data.intervalAnchorDate.value
          : this.intervalAnchorDate,
      yearlyMonth: data.yearlyMonth.present
          ? data.yearlyMonth.value
          : this.yearlyMonth,
      yearlyDay: data.yearlyDay.present ? data.yearlyDay.value : this.yearlyDay,
      lastPaidAt: data.lastPaidAt.present
          ? data.lastPaidAt.value
          : this.lastPaidAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      paymentMode: data.paymentMode.present
          ? data.paymentMode.value
          : this.paymentMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringPayment(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('isExactAmount: $isExactAmount, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('profileId: $profileId, ')
          ..write('frequency: $frequency, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('intervalAnchorDate: $intervalAnchorDate, ')
          ..write('yearlyMonth: $yearlyMonth, ')
          ..write('yearlyDay: $yearlyDay, ')
          ..write('lastPaidAt: $lastPaidAt, ')
          ..write('notes: $notes, ')
          ..write('paymentMode: $paymentMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    currency,
    isExactAmount,
    dayOfMonth,
    sortOrder,
    profileId,
    frequency,
    intervalDays,
    intervalAnchorDate,
    yearlyMonth,
    yearlyDay,
    lastPaidAt,
    notes,
    paymentMode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringPayment &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.isExactAmount == this.isExactAmount &&
          other.dayOfMonth == this.dayOfMonth &&
          other.sortOrder == this.sortOrder &&
          other.profileId == this.profileId &&
          other.frequency == this.frequency &&
          other.intervalDays == this.intervalDays &&
          other.intervalAnchorDate == this.intervalAnchorDate &&
          other.yearlyMonth == this.yearlyMonth &&
          other.yearlyDay == this.yearlyDay &&
          other.lastPaidAt == this.lastPaidAt &&
          other.notes == this.notes &&
          other.paymentMode == this.paymentMode);
}

class RecurringPaymentsCompanion extends UpdateCompanion<RecurringPayment> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> amount;
  final Value<String> currency;
  final Value<bool> isExactAmount;
  final Value<int> dayOfMonth;
  final Value<int> sortOrder;
  final Value<String?> profileId;
  final Value<String> frequency;
  final Value<int?> intervalDays;
  final Value<DateTime?> intervalAnchorDate;
  final Value<int?> yearlyMonth;
  final Value<int?> yearlyDay;
  final Value<DateTime?> lastPaidAt;
  final Value<String?> notes;
  final Value<String> paymentMode;
  final Value<int> rowid;
  const RecurringPaymentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.isExactAmount = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.profileId = const Value.absent(),
    this.frequency = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.intervalAnchorDate = const Value.absent(),
    this.yearlyMonth = const Value.absent(),
    this.yearlyDay = const Value.absent(),
    this.lastPaidAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.paymentMode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringPaymentsCompanion.insert({
    required String id,
    required String name,
    required double amount,
    this.currency = const Value.absent(),
    this.isExactAmount = const Value.absent(),
    required int dayOfMonth,
    this.sortOrder = const Value.absent(),
    this.profileId = const Value.absent(),
    this.frequency = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.intervalAnchorDate = const Value.absent(),
    this.yearlyMonth = const Value.absent(),
    this.yearlyDay = const Value.absent(),
    this.lastPaidAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.paymentMode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       amount = Value(amount),
       dayOfMonth = Value(dayOfMonth);
  static Insertable<RecurringPayment> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<bool>? isExactAmount,
    Expression<int>? dayOfMonth,
    Expression<int>? sortOrder,
    Expression<String>? profileId,
    Expression<String>? frequency,
    Expression<int>? intervalDays,
    Expression<DateTime>? intervalAnchorDate,
    Expression<int>? yearlyMonth,
    Expression<int>? yearlyDay,
    Expression<DateTime>? lastPaidAt,
    Expression<String>? notes,
    Expression<String>? paymentMode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (isExactAmount != null) 'is_exact_amount': isExactAmount,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (profileId != null) 'profile_id': profileId,
      if (frequency != null) 'frequency': frequency,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (intervalAnchorDate != null)
        'interval_anchor_date': intervalAnchorDate,
      if (yearlyMonth != null) 'yearly_month': yearlyMonth,
      if (yearlyDay != null) 'yearly_day': yearlyDay,
      if (lastPaidAt != null) 'last_paid_at': lastPaidAt,
      if (notes != null) 'notes': notes,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringPaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? amount,
    Value<String>? currency,
    Value<bool>? isExactAmount,
    Value<int>? dayOfMonth,
    Value<int>? sortOrder,
    Value<String?>? profileId,
    Value<String>? frequency,
    Value<int?>? intervalDays,
    Value<DateTime?>? intervalAnchorDate,
    Value<int?>? yearlyMonth,
    Value<int?>? yearlyDay,
    Value<DateTime?>? lastPaidAt,
    Value<String?>? notes,
    Value<String>? paymentMode,
    Value<int>? rowid,
  }) {
    return RecurringPaymentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      isExactAmount: isExactAmount ?? this.isExactAmount,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      sortOrder: sortOrder ?? this.sortOrder,
      profileId: profileId ?? this.profileId,
      frequency: frequency ?? this.frequency,
      intervalDays: intervalDays ?? this.intervalDays,
      intervalAnchorDate: intervalAnchorDate ?? this.intervalAnchorDate,
      yearlyMonth: yearlyMonth ?? this.yearlyMonth,
      yearlyDay: yearlyDay ?? this.yearlyDay,
      lastPaidAt: lastPaidAt ?? this.lastPaidAt,
      notes: notes ?? this.notes,
      paymentMode: paymentMode ?? this.paymentMode,
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
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (isExactAmount.present) {
      map['is_exact_amount'] = Variable<bool>(isExactAmount.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (intervalAnchorDate.present) {
      map['interval_anchor_date'] = Variable<DateTime>(
        intervalAnchorDate.value,
      );
    }
    if (yearlyMonth.present) {
      map['yearly_month'] = Variable<int>(yearlyMonth.value);
    }
    if (yearlyDay.present) {
      map['yearly_day'] = Variable<int>(yearlyDay.value);
    }
    if (lastPaidAt.present) {
      map['last_paid_at'] = Variable<DateTime>(lastPaidAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (paymentMode.present) {
      map['payment_mode'] = Variable<String>(paymentMode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('isExactAmount: $isExactAmount, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('profileId: $profileId, ')
          ..write('frequency: $frequency, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('intervalAnchorDate: $intervalAnchorDate, ')
          ..write('yearlyMonth: $yearlyMonth, ')
          ..write('yearlyDay: $yearlyDay, ')
          ..write('lastPaidAt: $lastPaidAt, ')
          ..write('notes: $notes, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringPaymentHistoryTable extends RecurringPaymentHistory
    with TableInfo<$RecurringPaymentHistoryTable, RecurringPaymentHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringPaymentHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAmountMeta = const VerificationMeta(
    'paidAmount',
  );
  @override
  late final GeneratedColumn<double> paidAmount = GeneratedColumn<double>(
    'paid_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    year,
    month,
    currency,
    totalAmount,
    paidAmount,
    recordedAt,
    itemsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_payment_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringPaymentHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('paid_amount')) {
      context.handle(
        _paidAmountMeta,
        paidAmount.isAcceptableOrUnknown(data['paid_amount']!, _paidAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAmountMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringPaymentHistoryData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringPaymentHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      paidAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}paid_amount'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
    );
  }

  @override
  $RecurringPaymentHistoryTable createAlias(String alias) {
    return $RecurringPaymentHistoryTable(attachedDatabase, alias);
  }
}

class RecurringPaymentHistoryData extends DataClass
    implements Insertable<RecurringPaymentHistoryData> {
  final String id;
  final String? profileId;

  /// The recorded month, as a plain calendar year/month pair rather than a
  /// full date -- this row represents an entire month, not one instant in
  /// it, and (unlike a single int count of months) stays unambiguous
  /// across year boundaries.
  final int year;

  /// 1-12.
  final int month;
  final String currency;
  final double totalAmount;
  final double paidAmount;
  final DateTime recordedAt;

  /// JSON-encoded list of `{name, amount, paid}` -- one per payment that
  /// was due this month, each `amount` already converted to the
  /// settlement currency at record time (see
  /// RecurringPaymentHistoryItem). Empty list (`'[]'`, the default) on
  /// every row recorded before this per-item breakdown existed --
  /// distinguishable from a genuinely-empty month by `totalAmount > 0`,
  /// since ensureRecorded never inserts a row at all when nothing was due
  /// (see that method's own doc comment), so a real recorded total always
  /// implies at least one contributing item.
  final String itemsJson;
  const RecurringPaymentHistoryData({
    required this.id,
    this.profileId,
    required this.year,
    required this.month,
    required this.currency,
    required this.totalAmount,
    required this.paidAmount,
    required this.recordedAt,
    required this.itemsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['currency'] = Variable<String>(currency);
    map['total_amount'] = Variable<double>(totalAmount);
    map['paid_amount'] = Variable<double>(paidAmount);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['items_json'] = Variable<String>(itemsJson);
    return map;
  }

  RecurringPaymentHistoryCompanion toCompanion(bool nullToAbsent) {
    return RecurringPaymentHistoryCompanion(
      id: Value(id),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      year: Value(year),
      month: Value(month),
      currency: Value(currency),
      totalAmount: Value(totalAmount),
      paidAmount: Value(paidAmount),
      recordedAt: Value(recordedAt),
      itemsJson: Value(itemsJson),
    );
  }

  factory RecurringPaymentHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringPaymentHistoryData(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String?>(json['profileId']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      currency: serializer.fromJson<String>(json['currency']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      paidAmount: serializer.fromJson<double>(json['paidAmount']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String?>(profileId),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'currency': serializer.toJson<String>(currency),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'paidAmount': serializer.toJson<double>(paidAmount),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'itemsJson': serializer.toJson<String>(itemsJson),
    };
  }

  RecurringPaymentHistoryData copyWith({
    String? id,
    Value<String?> profileId = const Value.absent(),
    int? year,
    int? month,
    String? currency,
    double? totalAmount,
    double? paidAmount,
    DateTime? recordedAt,
    String? itemsJson,
  }) => RecurringPaymentHistoryData(
    id: id ?? this.id,
    profileId: profileId.present ? profileId.value : this.profileId,
    year: year ?? this.year,
    month: month ?? this.month,
    currency: currency ?? this.currency,
    totalAmount: totalAmount ?? this.totalAmount,
    paidAmount: paidAmount ?? this.paidAmount,
    recordedAt: recordedAt ?? this.recordedAt,
    itemsJson: itemsJson ?? this.itemsJson,
  );
  RecurringPaymentHistoryData copyWithCompanion(
    RecurringPaymentHistoryCompanion data,
  ) {
    return RecurringPaymentHistoryData(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      currency: data.currency.present ? data.currency.value : this.currency,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      paidAmount: data.paidAmount.present
          ? data.paidAmount.value
          : this.paidAmount,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringPaymentHistoryData(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('currency: $currency, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('itemsJson: $itemsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    year,
    month,
    currency,
    totalAmount,
    paidAmount,
    recordedAt,
    itemsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringPaymentHistoryData &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.year == this.year &&
          other.month == this.month &&
          other.currency == this.currency &&
          other.totalAmount == this.totalAmount &&
          other.paidAmount == this.paidAmount &&
          other.recordedAt == this.recordedAt &&
          other.itemsJson == this.itemsJson);
}

class RecurringPaymentHistoryCompanion
    extends UpdateCompanion<RecurringPaymentHistoryData> {
  final Value<String> id;
  final Value<String?> profileId;
  final Value<int> year;
  final Value<int> month;
  final Value<String> currency;
  final Value<double> totalAmount;
  final Value<double> paidAmount;
  final Value<DateTime> recordedAt;
  final Value<String> itemsJson;
  final Value<int> rowid;
  const RecurringPaymentHistoryCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.currency = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringPaymentHistoryCompanion.insert({
    required String id,
    this.profileId = const Value.absent(),
    required int year,
    required int month,
    this.currency = const Value.absent(),
    required double totalAmount,
    required double paidAmount,
    required DateTime recordedAt,
    this.itemsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       year = Value(year),
       month = Value(month),
       totalAmount = Value(totalAmount),
       paidAmount = Value(paidAmount),
       recordedAt = Value(recordedAt);
  static Insertable<RecurringPaymentHistoryData> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<int>? year,
    Expression<int>? month,
    Expression<String>? currency,
    Expression<double>? totalAmount,
    Expression<double>? paidAmount,
    Expression<DateTime>? recordedAt,
    Expression<String>? itemsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (currency != null) 'currency': currency,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (itemsJson != null) 'items_json': itemsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringPaymentHistoryCompanion copyWith({
    Value<String>? id,
    Value<String?>? profileId,
    Value<int>? year,
    Value<int>? month,
    Value<String>? currency,
    Value<double>? totalAmount,
    Value<double>? paidAmount,
    Value<DateTime>? recordedAt,
    Value<String>? itemsJson,
    Value<int>? rowid,
  }) {
    return RecurringPaymentHistoryCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      year: year ?? this.year,
      month: month ?? this.month,
      currency: currency ?? this.currency,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      recordedAt: recordedAt ?? this.recordedAt,
      itemsJson: itemsJson ?? this.itemsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<double>(paidAmount.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringPaymentHistoryCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('currency: $currency, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BankAccountsTable extends BankAccounts
    with TableInfo<$BankAccountsTable, BankAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BankAccountsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _accountNumberMeta = const VerificationMeta(
    'accountNumber',
  );
  @override
  late final GeneratedColumn<String> accountNumber = GeneratedColumn<String>(
    'account_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentAvailableBalanceMeta =
      const VerificationMeta('currentAvailableBalance');
  @override
  late final GeneratedColumn<double> currentAvailableBalance =
      GeneratedColumn<double>(
        'current_available_balance',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    bank,
    currency,
    sortOrder,
    accountNumber,
    currentAvailableBalance,
    profileId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bank_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<BankAccount> instance, {
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
    if (data.containsKey('account_number')) {
      context.handle(
        _accountNumberMeta,
        accountNumber.isAcceptableOrUnknown(
          data['account_number']!,
          _accountNumberMeta,
        ),
      );
    }
    if (data.containsKey('current_available_balance')) {
      context.handle(
        _currentAvailableBalanceMeta,
        currentAvailableBalance.isAcceptableOrUnknown(
          data['current_available_balance']!,
          _currentAvailableBalanceMeta,
        ),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BankAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BankAccount(
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
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      accountNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_number'],
      ),
      currentAvailableBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_available_balance'],
      ),
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
    );
  }

  @override
  $BankAccountsTable createAlias(String alias) {
    return $BankAccountsTable(attachedDatabase, alias);
  }
}

class BankAccount extends DataClass implements Insertable<BankAccount> {
  final String id;
  final String name;
  final String bank;
  final String currency;

  /// Manual ordering for display — set to insertion order by default, but
  /// not tied to it, so a future "reorder" gesture has somewhere to write.
  final int sortOrder;
  final String? accountNumber;

  /// Available balance, kept current by a debounced save-back the moment
  /// the user edits it in the Calculator tab -- mirroring
  /// [CreditCards.currentAvailableBalance]'s own doc comment (and the
  /// "reset itself" bug it fixes) exactly, since this is the same kind of
  /// field. Null until the user first types a value in.
  final double? currentAvailableBalance;
  final String? profileId;
  const BankAccount({
    required this.id,
    required this.name,
    required this.bank,
    required this.currency,
    required this.sortOrder,
    this.accountNumber,
    this.currentAvailableBalance,
    this.profileId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['bank'] = Variable<String>(bank);
    map['currency'] = Variable<String>(currency);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || accountNumber != null) {
      map['account_number'] = Variable<String>(accountNumber);
    }
    if (!nullToAbsent || currentAvailableBalance != null) {
      map['current_available_balance'] = Variable<double>(
        currentAvailableBalance,
      );
    }
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    return map;
  }

  BankAccountsCompanion toCompanion(bool nullToAbsent) {
    return BankAccountsCompanion(
      id: Value(id),
      name: Value(name),
      bank: Value(bank),
      currency: Value(currency),
      sortOrder: Value(sortOrder),
      accountNumber: accountNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(accountNumber),
      currentAvailableBalance: currentAvailableBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(currentAvailableBalance),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
    );
  }

  factory BankAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BankAccount(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      bank: serializer.fromJson<String>(json['bank']),
      currency: serializer.fromJson<String>(json['currency']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      accountNumber: serializer.fromJson<String?>(json['accountNumber']),
      currentAvailableBalance: serializer.fromJson<double?>(
        json['currentAvailableBalance'],
      ),
      profileId: serializer.fromJson<String?>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'bank': serializer.toJson<String>(bank),
      'currency': serializer.toJson<String>(currency),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'accountNumber': serializer.toJson<String?>(accountNumber),
      'currentAvailableBalance': serializer.toJson<double?>(
        currentAvailableBalance,
      ),
      'profileId': serializer.toJson<String?>(profileId),
    };
  }

  BankAccount copyWith({
    String? id,
    String? name,
    String? bank,
    String? currency,
    int? sortOrder,
    Value<String?> accountNumber = const Value.absent(),
    Value<double?> currentAvailableBalance = const Value.absent(),
    Value<String?> profileId = const Value.absent(),
  }) => BankAccount(
    id: id ?? this.id,
    name: name ?? this.name,
    bank: bank ?? this.bank,
    currency: currency ?? this.currency,
    sortOrder: sortOrder ?? this.sortOrder,
    accountNumber: accountNumber.present
        ? accountNumber.value
        : this.accountNumber,
    currentAvailableBalance: currentAvailableBalance.present
        ? currentAvailableBalance.value
        : this.currentAvailableBalance,
    profileId: profileId.present ? profileId.value : this.profileId,
  );
  BankAccount copyWithCompanion(BankAccountsCompanion data) {
    return BankAccount(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      bank: data.bank.present ? data.bank.value : this.bank,
      currency: data.currency.present ? data.currency.value : this.currency,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      accountNumber: data.accountNumber.present
          ? data.accountNumber.value
          : this.accountNumber,
      currentAvailableBalance: data.currentAvailableBalance.present
          ? data.currentAvailableBalance.value
          : this.currentAvailableBalance,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BankAccount(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bank: $bank, ')
          ..write('currency: $currency, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('currentAvailableBalance: $currentAvailableBalance, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    bank,
    currency,
    sortOrder,
    accountNumber,
    currentAvailableBalance,
    profileId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BankAccount &&
          other.id == this.id &&
          other.name == this.name &&
          other.bank == this.bank &&
          other.currency == this.currency &&
          other.sortOrder == this.sortOrder &&
          other.accountNumber == this.accountNumber &&
          other.currentAvailableBalance == this.currentAvailableBalance &&
          other.profileId == this.profileId);
}

class BankAccountsCompanion extends UpdateCompanion<BankAccount> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> bank;
  final Value<String> currency;
  final Value<int> sortOrder;
  final Value<String?> accountNumber;
  final Value<double?> currentAvailableBalance;
  final Value<String?> profileId;
  final Value<int> rowid;
  const BankAccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.bank = const Value.absent(),
    this.currency = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.currentAvailableBalance = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BankAccountsCompanion.insert({
    required String id,
    required String name,
    required String bank,
    this.currency = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.currentAvailableBalance = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       bank = Value(bank);
  static Insertable<BankAccount> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? bank,
    Expression<String>? currency,
    Expression<int>? sortOrder,
    Expression<String>? accountNumber,
    Expression<double>? currentAvailableBalance,
    Expression<String>? profileId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (bank != null) 'bank': bank,
      if (currency != null) 'currency': currency,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (accountNumber != null) 'account_number': accountNumber,
      if (currentAvailableBalance != null)
        'current_available_balance': currentAvailableBalance,
      if (profileId != null) 'profile_id': profileId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BankAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? bank,
    Value<String>? currency,
    Value<int>? sortOrder,
    Value<String?>? accountNumber,
    Value<double?>? currentAvailableBalance,
    Value<String?>? profileId,
    Value<int>? rowid,
  }) {
    return BankAccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      bank: bank ?? this.bank,
      currency: currency ?? this.currency,
      sortOrder: sortOrder ?? this.sortOrder,
      accountNumber: accountNumber ?? this.accountNumber,
      currentAvailableBalance:
          currentAvailableBalance ?? this.currentAvailableBalance,
      profileId: profileId ?? this.profileId,
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
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (accountNumber.present) {
      map['account_number'] = Variable<String>(accountNumber.value);
    }
    if (currentAvailableBalance.present) {
      map['current_available_balance'] = Variable<double>(
        currentAvailableBalance.value,
      );
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BankAccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bank: $bank, ')
          ..write('currency: $currency, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('currentAvailableBalance: $currentAvailableBalance, ')
          ..write('profileId: $profileId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BanksTable extends Banks with TableInfo<$BanksTable, Bank> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BanksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, profileId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'banks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bank> instance, {
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
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bank map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bank(
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
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
    );
  }

  @override
  $BanksTable createAlias(String alias) {
    return $BanksTable(attachedDatabase, alias);
  }
}

class Bank extends DataClass implements Insertable<Bank> {
  final String id;
  final String name;
  final int sortOrder;
  final String? profileId;
  const Bank({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.profileId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    return map;
  }

  BanksCompanion toCompanion(bool nullToAbsent) {
    return BanksCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
    );
  }

  factory Bank.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bank(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      profileId: serializer.fromJson<String?>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'profileId': serializer.toJson<String?>(profileId),
    };
  }

  Bank copyWith({
    String? id,
    String? name,
    int? sortOrder,
    Value<String?> profileId = const Value.absent(),
  }) => Bank(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    profileId: profileId.present ? profileId.value : this.profileId,
  );
  Bank copyWithCompanion(BanksCompanion data) {
    return Bank(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bank(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, profileId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bank &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.profileId == this.profileId);
}

class BanksCompanion extends UpdateCompanion<Bank> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<String?> profileId;
  final Value<int> rowid;
  const BanksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BanksCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Bank> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<String>? profileId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (profileId != null) 'profile_id': profileId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BanksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<String?>? profileId,
    Value<int>? rowid,
  }) {
    return BanksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      profileId: profileId ?? this.profileId,
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
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BanksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('profileId: $profileId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmsRulesTable extends SmsRules with TableInfo<$SmsRulesTable, SmsRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmsRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankIdMeta = const VerificationMeta('bankId');
  @override
  late final GeneratedColumn<String> bankId = GeneratedColumn<String>(
    'bank_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES banks (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleTextMeta = const VerificationMeta(
    'sampleText',
  );
  @override
  late final GeneratedColumn<String> sampleText = GeneratedColumn<String>(
    'sample_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentsJsonMeta = const VerificationMeta(
    'segmentsJson',
  );
  @override
  late final GeneratedColumn<String> segmentsJson = GeneratedColumn<String>(
    'segments_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetCounterpartyIdMeta =
      const VerificationMeta('targetCounterpartyId');
  @override
  late final GeneratedColumn<String> targetCounterpartyId =
      GeneratedColumn<String>(
        'target_counterparty_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES counterparties (id)',
        ),
      );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notifyOnMatchMeta = const VerificationMeta(
    'notifyOnMatch',
  );
  @override
  late final GeneratedColumn<bool> notifyOnMatch = GeneratedColumn<bool>(
    'notify_on_match',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_on_match" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _matchModeMeta = const VerificationMeta(
    'matchMode',
  );
  @override
  late final GeneratedColumn<String> matchMode = GeneratedColumn<String>(
    'match_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('strict'),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bankId,
    name,
    operation,
    sampleText,
    segmentsJson,
    targetCounterpartyId,
    currency,
    notifyOnMatch,
    matchMode,
    enabled,
    createdAt,
    profileId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sms_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmsRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bank_id')) {
      context.handle(
        _bankIdMeta,
        bankId.isAcceptableOrUnknown(data['bank_id']!, _bankIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bankIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('sample_text')) {
      context.handle(
        _sampleTextMeta,
        sampleText.isAcceptableOrUnknown(data['sample_text']!, _sampleTextMeta),
      );
    } else if (isInserting) {
      context.missing(_sampleTextMeta);
    }
    if (data.containsKey('segments_json')) {
      context.handle(
        _segmentsJsonMeta,
        segmentsJson.isAcceptableOrUnknown(
          data['segments_json']!,
          _segmentsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_segmentsJsonMeta);
    }
    if (data.containsKey('target_counterparty_id')) {
      context.handle(
        _targetCounterpartyIdMeta,
        targetCounterpartyId.isAcceptableOrUnknown(
          data['target_counterparty_id']!,
          _targetCounterpartyIdMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('notify_on_match')) {
      context.handle(
        _notifyOnMatchMeta,
        notifyOnMatch.isAcceptableOrUnknown(
          data['notify_on_match']!,
          _notifyOnMatchMeta,
        ),
      );
    }
    if (data.containsKey('match_mode')) {
      context.handle(
        _matchModeMeta,
        matchMode.isAcceptableOrUnknown(data['match_mode']!, _matchModeMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
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
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmsRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmsRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bankId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      sampleText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sample_text'],
      )!,
      segmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segments_json'],
      )!,
      targetCounterpartyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_counterparty_id'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      ),
      notifyOnMatch: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_on_match'],
      )!,
      matchMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_mode'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
    );
  }

  @override
  $SmsRulesTable createAlias(String alias) {
    return $SmsRulesTable(attachedDatabase, alias);
  }
}

class SmsRule extends DataClass implements Insertable<SmsRule> {
  final String id;
  final String bankId;

  /// User-given label (e.g. "Amazon refund") shown instead of the generic
  /// operation name in the rules list -- optional, since [operation] alone
  /// is still a perfectly fine label for a rule with only one obvious
  /// purpose.
  final String? name;

  /// 'creditCardBalance' | 'bankAccountBalance' | 'ledgerPayment'.
  final String operation;

  /// The real SMS this rule was built from -- concatenating every segment
  /// in [segmentsJson] reconstructs this exactly, but this column is kept
  /// too since it's what the edit screen actually displays and re-marks.
  final String sampleText;

  /// JSON-encoded list of `{type, text, tag, role}` segments -- see
  /// `SmsRuleSegment` -- in order, alternating literal text this rule
  /// requires to appear with the variable portions (card/account number,
  /// value, vendor, sender) it extracts.
  final String segmentsJson;

  /// Only meaningful for a 'ledgerPayment' rule -- which ledger a match
  /// adds its entry to. An SMS never names one of the user's own ledgers,
  /// so this is picked once, at rule-creation time, the same way a Vendor
  /// Rule already worked.
  final String? targetCounterpartyId;

  /// For a 'ledgerPayment' rule, the currency its ledger entries default to
  /// when the message itself doesn't carry a recognized `currency` tag
  /// match. For a balance rule, unused directly -- a matched `currency` is
  /// only ever compared against the card's/account's own currency to
  /// decide whether a conversion is needed, never stored.
  final String? currency;

  /// Whether a local notification is shown when this rule successfully
  /// applies to a real incoming SMS.
  final bool notifyOnMatch;

  /// 'strict' (default) requires every un-tagged part of the sample to
  /// appear in a real SMS essentially verbatim (whitespace aside) --
  /// 'flexible' keeps only a couple of words immediately next to each tag
  /// as an anchor and treats longer untagged stretches as "anything goes
  /// here", tolerating a date, an extra sentence, or other wording a
  /// single sample can't predict. See `compileSmsRulePattern`.
  final String matchMode;

  /// Whether this rule is actually applied to incoming SMS -- a disabled
  /// rule is skipped by matching entirely (see `_matchAllRules`), without
  /// deleting it, so a rule that's temporarily wrong or noisy can be
  /// switched off and back on instead of being rebuilt from scratch.
  final bool enabled;
  final DateTime createdAt;
  final String? profileId;
  const SmsRule({
    required this.id,
    required this.bankId,
    this.name,
    required this.operation,
    required this.sampleText,
    required this.segmentsJson,
    this.targetCounterpartyId,
    this.currency,
    required this.notifyOnMatch,
    required this.matchMode,
    required this.enabled,
    required this.createdAt,
    this.profileId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bank_id'] = Variable<String>(bankId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['operation'] = Variable<String>(operation);
    map['sample_text'] = Variable<String>(sampleText);
    map['segments_json'] = Variable<String>(segmentsJson);
    if (!nullToAbsent || targetCounterpartyId != null) {
      map['target_counterparty_id'] = Variable<String>(targetCounterpartyId);
    }
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    map['notify_on_match'] = Variable<bool>(notifyOnMatch);
    map['match_mode'] = Variable<String>(matchMode);
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    return map;
  }

  SmsRulesCompanion toCompanion(bool nullToAbsent) {
    return SmsRulesCompanion(
      id: Value(id),
      bankId: Value(bankId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      operation: Value(operation),
      sampleText: Value(sampleText),
      segmentsJson: Value(segmentsJson),
      targetCounterpartyId: targetCounterpartyId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetCounterpartyId),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      notifyOnMatch: Value(notifyOnMatch),
      matchMode: Value(matchMode),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
    );
  }

  factory SmsRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmsRule(
      id: serializer.fromJson<String>(json['id']),
      bankId: serializer.fromJson<String>(json['bankId']),
      name: serializer.fromJson<String?>(json['name']),
      operation: serializer.fromJson<String>(json['operation']),
      sampleText: serializer.fromJson<String>(json['sampleText']),
      segmentsJson: serializer.fromJson<String>(json['segmentsJson']),
      targetCounterpartyId: serializer.fromJson<String?>(
        json['targetCounterpartyId'],
      ),
      currency: serializer.fromJson<String?>(json['currency']),
      notifyOnMatch: serializer.fromJson<bool>(json['notifyOnMatch']),
      matchMode: serializer.fromJson<String>(json['matchMode']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      profileId: serializer.fromJson<String?>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bankId': serializer.toJson<String>(bankId),
      'name': serializer.toJson<String?>(name),
      'operation': serializer.toJson<String>(operation),
      'sampleText': serializer.toJson<String>(sampleText),
      'segmentsJson': serializer.toJson<String>(segmentsJson),
      'targetCounterpartyId': serializer.toJson<String?>(targetCounterpartyId),
      'currency': serializer.toJson<String?>(currency),
      'notifyOnMatch': serializer.toJson<bool>(notifyOnMatch),
      'matchMode': serializer.toJson<String>(matchMode),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'profileId': serializer.toJson<String?>(profileId),
    };
  }

  SmsRule copyWith({
    String? id,
    String? bankId,
    Value<String?> name = const Value.absent(),
    String? operation,
    String? sampleText,
    String? segmentsJson,
    Value<String?> targetCounterpartyId = const Value.absent(),
    Value<String?> currency = const Value.absent(),
    bool? notifyOnMatch,
    String? matchMode,
    bool? enabled,
    DateTime? createdAt,
    Value<String?> profileId = const Value.absent(),
  }) => SmsRule(
    id: id ?? this.id,
    bankId: bankId ?? this.bankId,
    name: name.present ? name.value : this.name,
    operation: operation ?? this.operation,
    sampleText: sampleText ?? this.sampleText,
    segmentsJson: segmentsJson ?? this.segmentsJson,
    targetCounterpartyId: targetCounterpartyId.present
        ? targetCounterpartyId.value
        : this.targetCounterpartyId,
    currency: currency.present ? currency.value : this.currency,
    notifyOnMatch: notifyOnMatch ?? this.notifyOnMatch,
    matchMode: matchMode ?? this.matchMode,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt ?? this.createdAt,
    profileId: profileId.present ? profileId.value : this.profileId,
  );
  SmsRule copyWithCompanion(SmsRulesCompanion data) {
    return SmsRule(
      id: data.id.present ? data.id.value : this.id,
      bankId: data.bankId.present ? data.bankId.value : this.bankId,
      name: data.name.present ? data.name.value : this.name,
      operation: data.operation.present ? data.operation.value : this.operation,
      sampleText: data.sampleText.present
          ? data.sampleText.value
          : this.sampleText,
      segmentsJson: data.segmentsJson.present
          ? data.segmentsJson.value
          : this.segmentsJson,
      targetCounterpartyId: data.targetCounterpartyId.present
          ? data.targetCounterpartyId.value
          : this.targetCounterpartyId,
      currency: data.currency.present ? data.currency.value : this.currency,
      notifyOnMatch: data.notifyOnMatch.present
          ? data.notifyOnMatch.value
          : this.notifyOnMatch,
      matchMode: data.matchMode.present ? data.matchMode.value : this.matchMode,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmsRule(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('name: $name, ')
          ..write('operation: $operation, ')
          ..write('sampleText: $sampleText, ')
          ..write('segmentsJson: $segmentsJson, ')
          ..write('targetCounterpartyId: $targetCounterpartyId, ')
          ..write('currency: $currency, ')
          ..write('notifyOnMatch: $notifyOnMatch, ')
          ..write('matchMode: $matchMode, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bankId,
    name,
    operation,
    sampleText,
    segmentsJson,
    targetCounterpartyId,
    currency,
    notifyOnMatch,
    matchMode,
    enabled,
    createdAt,
    profileId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmsRule &&
          other.id == this.id &&
          other.bankId == this.bankId &&
          other.name == this.name &&
          other.operation == this.operation &&
          other.sampleText == this.sampleText &&
          other.segmentsJson == this.segmentsJson &&
          other.targetCounterpartyId == this.targetCounterpartyId &&
          other.currency == this.currency &&
          other.notifyOnMatch == this.notifyOnMatch &&
          other.matchMode == this.matchMode &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt &&
          other.profileId == this.profileId);
}

class SmsRulesCompanion extends UpdateCompanion<SmsRule> {
  final Value<String> id;
  final Value<String> bankId;
  final Value<String?> name;
  final Value<String> operation;
  final Value<String> sampleText;
  final Value<String> segmentsJson;
  final Value<String?> targetCounterpartyId;
  final Value<String?> currency;
  final Value<bool> notifyOnMatch;
  final Value<String> matchMode;
  final Value<bool> enabled;
  final Value<DateTime> createdAt;
  final Value<String?> profileId;
  final Value<int> rowid;
  const SmsRulesCompanion({
    this.id = const Value.absent(),
    this.bankId = const Value.absent(),
    this.name = const Value.absent(),
    this.operation = const Value.absent(),
    this.sampleText = const Value.absent(),
    this.segmentsJson = const Value.absent(),
    this.targetCounterpartyId = const Value.absent(),
    this.currency = const Value.absent(),
    this.notifyOnMatch = const Value.absent(),
    this.matchMode = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmsRulesCompanion.insert({
    required String id,
    required String bankId,
    this.name = const Value.absent(),
    required String operation,
    required String sampleText,
    required String segmentsJson,
    this.targetCounterpartyId = const Value.absent(),
    this.currency = const Value.absent(),
    this.notifyOnMatch = const Value.absent(),
    this.matchMode = const Value.absent(),
    this.enabled = const Value.absent(),
    required DateTime createdAt,
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bankId = Value(bankId),
       operation = Value(operation),
       sampleText = Value(sampleText),
       segmentsJson = Value(segmentsJson),
       createdAt = Value(createdAt);
  static Insertable<SmsRule> custom({
    Expression<String>? id,
    Expression<String>? bankId,
    Expression<String>? name,
    Expression<String>? operation,
    Expression<String>? sampleText,
    Expression<String>? segmentsJson,
    Expression<String>? targetCounterpartyId,
    Expression<String>? currency,
    Expression<bool>? notifyOnMatch,
    Expression<String>? matchMode,
    Expression<bool>? enabled,
    Expression<DateTime>? createdAt,
    Expression<String>? profileId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bankId != null) 'bank_id': bankId,
      if (name != null) 'name': name,
      if (operation != null) 'operation': operation,
      if (sampleText != null) 'sample_text': sampleText,
      if (segmentsJson != null) 'segments_json': segmentsJson,
      if (targetCounterpartyId != null)
        'target_counterparty_id': targetCounterpartyId,
      if (currency != null) 'currency': currency,
      if (notifyOnMatch != null) 'notify_on_match': notifyOnMatch,
      if (matchMode != null) 'match_mode': matchMode,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (profileId != null) 'profile_id': profileId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmsRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? bankId,
    Value<String?>? name,
    Value<String>? operation,
    Value<String>? sampleText,
    Value<String>? segmentsJson,
    Value<String?>? targetCounterpartyId,
    Value<String?>? currency,
    Value<bool>? notifyOnMatch,
    Value<String>? matchMode,
    Value<bool>? enabled,
    Value<DateTime>? createdAt,
    Value<String?>? profileId,
    Value<int>? rowid,
  }) {
    return SmsRulesCompanion(
      id: id ?? this.id,
      bankId: bankId ?? this.bankId,
      name: name ?? this.name,
      operation: operation ?? this.operation,
      sampleText: sampleText ?? this.sampleText,
      segmentsJson: segmentsJson ?? this.segmentsJson,
      targetCounterpartyId: targetCounterpartyId ?? this.targetCounterpartyId,
      currency: currency ?? this.currency,
      notifyOnMatch: notifyOnMatch ?? this.notifyOnMatch,
      matchMode: matchMode ?? this.matchMode,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      profileId: profileId ?? this.profileId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bankId.present) {
      map['bank_id'] = Variable<String>(bankId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (sampleText.present) {
      map['sample_text'] = Variable<String>(sampleText.value);
    }
    if (segmentsJson.present) {
      map['segments_json'] = Variable<String>(segmentsJson.value);
    }
    if (targetCounterpartyId.present) {
      map['target_counterparty_id'] = Variable<String>(
        targetCounterpartyId.value,
      );
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (notifyOnMatch.present) {
      map['notify_on_match'] = Variable<bool>(notifyOnMatch.value);
    }
    if (matchMode.present) {
      map['match_mode'] = Variable<String>(matchMode.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmsRulesCompanion(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('name: $name, ')
          ..write('operation: $operation, ')
          ..write('sampleText: $sampleText, ')
          ..write('segmentsJson: $segmentsJson, ')
          ..write('targetCounterpartyId: $targetCounterpartyId, ')
          ..write('currency: $currency, ')
          ..write('notifyOnMatch: $notifyOnMatch, ')
          ..write('matchMode: $matchMode, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('profileId: $profileId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
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
  late final $ManualInputsTable manualInputs = $ManualInputsTable(this);
  late final $RecurringPaymentsTable recurringPayments =
      $RecurringPaymentsTable(this);
  late final $RecurringPaymentHistoryTable recurringPaymentHistory =
      $RecurringPaymentHistoryTable(this);
  late final $BankAccountsTable bankAccounts = $BankAccountsTable(this);
  late final $BanksTable banks = $BanksTable(this);
  late final $SmsRulesTable smsRules = $SmsRulesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
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
    manualInputs,
    recurringPayments,
    recurringPaymentHistory,
    bankAccounts,
    banks,
    smsRules,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String id,
      required String name,
      Value<int> sortOrder,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $ProfilesTable, Profile> {
  $$ProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AssetsTable, List<Asset>> _assetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.assets,
    aliasName: 'profiles__id__assets__profile_id',
  );

  $$AssetsTableProcessedTableManager get assetsRefs {
    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CounterpartiesTable, List<Counterparty>>
  _counterpartiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.counterparties,
    aliasName: 'profiles__id__counterparties__profile_id',
  );

  $$CounterpartiesTableProcessedTableManager get counterpartiesRefs {
    final manager = $$CounterpartiesTableTableManager(
      $_db,
      $_db.counterparties,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_counterpartiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LedgerTransactionsTable, List<LedgerTransaction>>
  _ledgerTransactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ledgerTransactions,
        aliasName: 'profiles__id__ledger_transactions__profile_id',
      );

  $$LedgerTransactionsTableProcessedTableManager get ledgerTransactionsRefs {
    final manager = $$LedgerTransactionsTableTableManager(
      $_db,
      $_db.ledgerTransactions,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

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
    aliasName: 'profiles__id__vendor_rules__profile_id',
  );

  $$VendorRulesTableProcessedTableManager get vendorRulesRefs {
    final manager = $$VendorRulesTableTableManager(
      $_db,
      $_db.vendorRules,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_vendorRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CalculatorSnapshotsTable,
    List<CalculatorSnapshot>
  >
  _calculatorSnapshotsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.calculatorSnapshots,
        aliasName: 'profiles__id__calculator_snapshots__profile_id',
      );

  $$CalculatorSnapshotsTableProcessedTableManager get calculatorSnapshotsRefs {
    final manager = $$CalculatorSnapshotsTableTableManager(
      $_db,
      $_db.calculatorSnapshots,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _calculatorSnapshotsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CreditCardsTable, List<CreditCard>>
  _creditCardsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.creditCards,
    aliasName: 'profiles__id__credit_cards__profile_id',
  );

  $$CreditCardsTableProcessedTableManager get creditCardsRefs {
    final manager = $$CreditCardsTableTableManager(
      $_db,
      $_db.creditCards,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_creditCardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LedgerCategoriesTable, List<LedgerCategory>>
  _ledgerCategoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerCategories,
    aliasName: 'profiles__id__ledger_categories__profile_id',
  );

  $$LedgerCategoriesTableProcessedTableManager get ledgerCategoriesRefs {
    final manager = $$LedgerCategoriesTableTableManager(
      $_db,
      $_db.ledgerCategories,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ledgerCategoriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ManualInputsTable, List<ManualInput>>
  _manualInputsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.manualInputs,
    aliasName: 'profiles__id__manual_inputs__profile_id',
  );

  $$ManualInputsTableProcessedTableManager get manualInputsRefs {
    final manager = $$ManualInputsTableTableManager(
      $_db,
      $_db.manualInputs,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_manualInputsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecurringPaymentsTable, List<RecurringPayment>>
  _recurringPaymentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recurringPayments,
        aliasName: 'profiles__id__recurring_payments__profile_id',
      );

  $$RecurringPaymentsTableProcessedTableManager get recurringPaymentsRefs {
    final manager = $$RecurringPaymentsTableTableManager(
      $_db,
      $_db.recurringPayments,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recurringPaymentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $RecurringPaymentHistoryTable,
    List<RecurringPaymentHistoryData>
  >
  _recurringPaymentHistoryRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recurringPaymentHistory,
        aliasName: 'profiles__id__recurring_payment_history__profile_id',
      );

  $$RecurringPaymentHistoryTableProcessedTableManager
  get recurringPaymentHistoryRefs {
    final manager = $$RecurringPaymentHistoryTableTableManager(
      $_db,
      $_db.recurringPaymentHistory,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recurringPaymentHistoryRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BankAccountsTable, List<BankAccount>>
  _bankAccountsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bankAccounts,
    aliasName: 'profiles__id__bank_accounts__profile_id',
  );

  $$BankAccountsTableProcessedTableManager get bankAccountsRefs {
    final manager = $$BankAccountsTableTableManager(
      $_db,
      $_db.bankAccounts,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bankAccountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BanksTable, List<Bank>> _banksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.banks,
    aliasName: 'profiles__id__banks__profile_id',
  );

  $$BanksTableProcessedTableManager get banksRefs {
    final manager = $$BanksTableTableManager(
      $_db,
      $_db.banks,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_banksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SmsRulesTable, List<SmsRule>> _smsRulesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.smsRules,
    aliasName: 'profiles__id__sms_rules__profile_id',
  );

  $$SmsRulesTableProcessedTableManager get smsRulesRefs {
    final manager = $$SmsRulesTableTableManager(
      $_db,
      $_db.smsRules,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_smsRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> assetsRefs(
    Expression<bool> Function($$AssetsTableFilterComposer f) f,
  ) {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> counterpartiesRefs(
    Expression<bool> Function($$CounterpartiesTableFilterComposer f) f,
  ) {
    final $$CounterpartiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.counterparties,
      getReferencedColumn: (t) => t.profileId,
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
    return f(composer);
  }

  Expression<bool> ledgerTransactionsRefs(
    Expression<bool> Function($$LedgerTransactionsTableFilterComposer f) f,
  ) {
    final $$LedgerTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.profileId,
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
      getReferencedColumn: (t) => t.profileId,
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

  Expression<bool> calculatorSnapshotsRefs(
    Expression<bool> Function($$CalculatorSnapshotsTableFilterComposer f) f,
  ) {
    final $$CalculatorSnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calculatorSnapshots,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalculatorSnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.calculatorSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> creditCardsRefs(
    Expression<bool> Function($$CreditCardsTableFilterComposer f) f,
  ) {
    final $$CreditCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.creditCards,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditCardsTableFilterComposer(
            $db: $db,
            $table: $db.creditCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ledgerCategoriesRefs(
    Expression<bool> Function($$LedgerCategoriesTableFilterComposer f) f,
  ) {
    final $$LedgerCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> manualInputsRefs(
    Expression<bool> Function($$ManualInputsTableFilterComposer f) f,
  ) {
    final $$ManualInputsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.manualInputs,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ManualInputsTableFilterComposer(
            $db: $db,
            $table: $db.manualInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recurringPaymentsRefs(
    Expression<bool> Function($$RecurringPaymentsTableFilterComposer f) f,
  ) {
    final $$RecurringPaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurringPayments,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringPaymentsTableFilterComposer(
            $db: $db,
            $table: $db.recurringPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recurringPaymentHistoryRefs(
    Expression<bool> Function($$RecurringPaymentHistoryTableFilterComposer f) f,
  ) {
    final $$RecurringPaymentHistoryTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recurringPaymentHistory,
          getReferencedColumn: (t) => t.profileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecurringPaymentHistoryTableFilterComposer(
                $db: $db,
                $table: $db.recurringPaymentHistory,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> bankAccountsRefs(
    Expression<bool> Function($$BankAccountsTableFilterComposer f) f,
  ) {
    final $$BankAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bankAccounts,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BankAccountsTableFilterComposer(
            $db: $db,
            $table: $db.bankAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> banksRefs(
    Expression<bool> Function($$BanksTableFilterComposer f) f,
  ) {
    final $$BanksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.banks,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BanksTableFilterComposer(
            $db: $db,
            $table: $db.banks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> smsRulesRefs(
    Expression<bool> Function($$SmsRulesTableFilterComposer f) f,
  ) {
    final $$SmsRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.smsRules,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmsRulesTableFilterComposer(
            $db: $db,
            $table: $db.smsRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> assetsRefs<T extends Object>(
    Expression<T> Function($$AssetsTableAnnotationComposer a) f,
  ) {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> counterpartiesRefs<T extends Object>(
    Expression<T> Function($$CounterpartiesTableAnnotationComposer a) f,
  ) {
    final $$CounterpartiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.counterparties,
      getReferencedColumn: (t) => t.profileId,
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
    return f(composer);
  }

  Expression<T> ledgerTransactionsRefs<T extends Object>(
    Expression<T> Function($$LedgerTransactionsTableAnnotationComposer a) f,
  ) {
    final $$LedgerTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ledgerTransactions,
          getReferencedColumn: (t) => t.profileId,
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
      getReferencedColumn: (t) => t.profileId,
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

  Expression<T> calculatorSnapshotsRefs<T extends Object>(
    Expression<T> Function($$CalculatorSnapshotsTableAnnotationComposer a) f,
  ) {
    final $$CalculatorSnapshotsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.calculatorSnapshots,
          getReferencedColumn: (t) => t.profileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CalculatorSnapshotsTableAnnotationComposer(
                $db: $db,
                $table: $db.calculatorSnapshots,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> creditCardsRefs<T extends Object>(
    Expression<T> Function($$CreditCardsTableAnnotationComposer a) f,
  ) {
    final $$CreditCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.creditCards,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.creditCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ledgerCategoriesRefs<T extends Object>(
    Expression<T> Function($$LedgerCategoriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> manualInputsRefs<T extends Object>(
    Expression<T> Function($$ManualInputsTableAnnotationComposer a) f,
  ) {
    final $$ManualInputsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.manualInputs,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ManualInputsTableAnnotationComposer(
            $db: $db,
            $table: $db.manualInputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recurringPaymentsRefs<T extends Object>(
    Expression<T> Function($$RecurringPaymentsTableAnnotationComposer a) f,
  ) {
    final $$RecurringPaymentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recurringPayments,
          getReferencedColumn: (t) => t.profileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecurringPaymentsTableAnnotationComposer(
                $db: $db,
                $table: $db.recurringPayments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> recurringPaymentHistoryRefs<T extends Object>(
    Expression<T> Function($$RecurringPaymentHistoryTableAnnotationComposer a)
    f,
  ) {
    final $$RecurringPaymentHistoryTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recurringPaymentHistory,
          getReferencedColumn: (t) => t.profileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecurringPaymentHistoryTableAnnotationComposer(
                $db: $db,
                $table: $db.recurringPaymentHistory,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> bankAccountsRefs<T extends Object>(
    Expression<T> Function($$BankAccountsTableAnnotationComposer a) f,
  ) {
    final $$BankAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bankAccounts,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BankAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.bankAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> banksRefs<T extends Object>(
    Expression<T> Function($$BanksTableAnnotationComposer a) f,
  ) {
    final $$BanksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.banks,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BanksTableAnnotationComposer(
            $db: $db,
            $table: $db.banks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> smsRulesRefs<T extends Object>(
    Expression<T> Function($$SmsRulesTableAnnotationComposer a) f,
  ) {
    final $$SmsRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.smsRules,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmsRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.smsRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, $$ProfilesTableReferences),
          Profile,
          PrefetchHooks Function({
            bool assetsRefs,
            bool counterpartiesRefs,
            bool ledgerTransactionsRefs,
            bool vendorRulesRefs,
            bool calculatorSnapshotsRefs,
            bool creditCardsRefs,
            bool ledgerCategoriesRefs,
            bool manualInputsRefs,
            bool recurringPaymentsRefs,
            bool recurringPaymentHistoryRefs,
            bool bankAccountsRefs,
            bool banksRefs,
            bool smsRulesRefs,
          })
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                assetsRefs = false,
                counterpartiesRefs = false,
                ledgerTransactionsRefs = false,
                vendorRulesRefs = false,
                calculatorSnapshotsRefs = false,
                creditCardsRefs = false,
                ledgerCategoriesRefs = false,
                manualInputsRefs = false,
                recurringPaymentsRefs = false,
                recurringPaymentHistoryRefs = false,
                bankAccountsRefs = false,
                banksRefs = false,
                smsRulesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (assetsRefs) db.assets,
                    if (counterpartiesRefs) db.counterparties,
                    if (ledgerTransactionsRefs) db.ledgerTransactions,
                    if (vendorRulesRefs) db.vendorRules,
                    if (calculatorSnapshotsRefs) db.calculatorSnapshots,
                    if (creditCardsRefs) db.creditCards,
                    if (ledgerCategoriesRefs) db.ledgerCategories,
                    if (manualInputsRefs) db.manualInputs,
                    if (recurringPaymentsRefs) db.recurringPayments,
                    if (recurringPaymentHistoryRefs) db.recurringPaymentHistory,
                    if (bankAccountsRefs) db.bankAccounts,
                    if (banksRefs) db.banks,
                    if (smsRulesRefs) db.smsRules,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (assetsRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          Asset
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._assetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).assetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (counterpartiesRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          Counterparty
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._counterpartiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).counterpartiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ledgerTransactionsRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          LedgerTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._ledgerTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (vendorRulesRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          VendorRule
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._vendorRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).vendorRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (calculatorSnapshotsRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          CalculatorSnapshot
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._calculatorSnapshotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).calculatorSnapshotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (creditCardsRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          CreditCard
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._creditCardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).creditCardsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ledgerCategoriesRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          LedgerCategory
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._ledgerCategoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerCategoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (manualInputsRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          ManualInput
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._manualInputsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).manualInputsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recurringPaymentsRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          RecurringPayment
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._recurringPaymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).recurringPaymentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recurringPaymentHistoryRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          RecurringPaymentHistoryData
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._recurringPaymentHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).recurringPaymentHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bankAccountsRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          BankAccount
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._bankAccountsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).bankAccountsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (banksRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          Bank
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._banksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).banksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (smsRulesRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          SmsRule
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._smsRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).smsRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
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

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, $$ProfilesTableReferences),
      Profile,
      PrefetchHooks Function({
        bool assetsRefs,
        bool counterpartiesRefs,
        bool ledgerTransactionsRefs,
        bool vendorRulesRefs,
        bool calculatorSnapshotsRefs,
        bool creditCardsRefs,
        bool ledgerCategoriesRefs,
        bool manualInputsRefs,
        bool recurringPaymentsRefs,
        bool recurringPaymentHistoryRefs,
        bool bankAccountsRefs,
        bool banksRefs,
        bool smsRulesRefs,
      })
    >;
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
      Value<String?> vehicleType,
      Value<double?> purchasePrice,
      Value<String?> purchaseCurrency,
      Value<DateTime?> purchaseDate,
      Value<String?> profileId,
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
      Value<String?> vehicleType,
      Value<double?> purchasePrice,
      Value<String?> purchaseCurrency,
      Value<DateTime?> purchaseDate,
      Value<String?> profileId,
      Value<int> rowid,
    });

final class $$AssetsTableReferences
    extends BaseReferences<_$AppDatabase, $AssetsTable, Asset> {
  $$AssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('assets__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  ColumnFilters<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseCurrency => $composableBuilder(
    column: $table.purchaseCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseCurrency => $composableBuilder(
    column: $table.purchaseCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseCurrency => $composableBuilder(
    column: $table.purchaseCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (Asset, $$AssetsTableReferences),
          Asset,
          PrefetchHooks Function({bool profileId})
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
                Value<String?> vehicleType = const Value.absent(),
                Value<double?> purchasePrice = const Value.absent(),
                Value<String?> purchaseCurrency = const Value.absent(),
                Value<DateTime?> purchaseDate = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
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
                vehicleType: vehicleType,
                purchasePrice: purchasePrice,
                purchaseCurrency: purchaseCurrency,
                purchaseDate: purchaseDate,
                profileId: profileId,
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
                Value<String?> vehicleType = const Value.absent(),
                Value<double?> purchasePrice = const Value.absent(),
                Value<String?> purchaseCurrency = const Value.absent(),
                Value<DateTime?> purchaseDate = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
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
                vehicleType: vehicleType,
                purchasePrice: purchasePrice,
                purchaseCurrency: purchaseCurrency,
                purchaseDate: purchaseDate,
                profileId: profileId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AssetsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
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
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$AssetsTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$AssetsTableReferences
                                    ._profileIdTable(db)
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
      (Asset, $$AssetsTableReferences),
      Asset,
      PrefetchHooks Function({bool profileId})
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
      Value<bool> includeInStatistics,
      Value<bool> includeInCalculator,
      Value<bool> visible,
      Value<bool> isTab,
      Value<String?> profileId,
      Value<int> rowid,
    });
typedef $$CounterpartiesTableUpdateCompanionBuilder =
    CounterpartiesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> includeInStatistics,
      Value<bool> includeInCalculator,
      Value<bool> visible,
      Value<bool> isTab,
      Value<String?> profileId,
      Value<int> rowid,
    });

final class $$CounterpartiesTableReferences
    extends BaseReferences<_$AppDatabase, $CounterpartiesTable, Counterparty> {
  $$CounterpartiesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('counterparties__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

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

  static MultiTypedResultKey<$SmsRulesTable, List<SmsRule>> _smsRulesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.smsRules,
    aliasName: 'counterparties__id__sms_rules__target_counterparty_id',
  );

  $$SmsRulesTableProcessedTableManager get smsRulesRefs {
    final manager = $$SmsRulesTableTableManager($_db, $_db.smsRules).filter(
      (f) => f.targetCounterpartyId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_smsRulesRefsTable($_db));
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

  ColumnFilters<bool> get includeInStatistics => $composableBuilder(
    column: $table.includeInStatistics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get includeInCalculator => $composableBuilder(
    column: $table.includeInCalculator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get visible => $composableBuilder(
    column: $table.visible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTab => $composableBuilder(
    column: $table.isTab,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

  Expression<bool> smsRulesRefs(
    Expression<bool> Function($$SmsRulesTableFilterComposer f) f,
  ) {
    final $$SmsRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.smsRules,
      getReferencedColumn: (t) => t.targetCounterpartyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmsRulesTableFilterComposer(
            $db: $db,
            $table: $db.smsRules,
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

  ColumnOrderings<bool> get includeInStatistics => $composableBuilder(
    column: $table.includeInStatistics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeInCalculator => $composableBuilder(
    column: $table.includeInCalculator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get visible => $composableBuilder(
    column: $table.visible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTab => $composableBuilder(
    column: $table.isTab,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<bool> get includeInStatistics => $composableBuilder(
    column: $table.includeInStatistics,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get includeInCalculator => $composableBuilder(
    column: $table.includeInCalculator,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get visible =>
      $composableBuilder(column: $table.visible, builder: (column) => column);

  GeneratedColumn<bool> get isTab =>
      $composableBuilder(column: $table.isTab, builder: (column) => column);

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

  Expression<T> smsRulesRefs<T extends Object>(
    Expression<T> Function($$SmsRulesTableAnnotationComposer a) f,
  ) {
    final $$SmsRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.smsRules,
      getReferencedColumn: (t) => t.targetCounterpartyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmsRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.smsRules,
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
            bool profileId,
            bool ledgerTransactionsRefs,
            bool vendorRulesRefs,
            bool smsRulesRefs,
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
                Value<bool> includeInStatistics = const Value.absent(),
                Value<bool> includeInCalculator = const Value.absent(),
                Value<bool> visible = const Value.absent(),
                Value<bool> isTab = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CounterpartiesCompanion(
                id: id,
                name: name,
                includeInStatistics: includeInStatistics,
                includeInCalculator: includeInCalculator,
                visible: visible,
                isTab: isTab,
                profileId: profileId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> includeInStatistics = const Value.absent(),
                Value<bool> includeInCalculator = const Value.absent(),
                Value<bool> visible = const Value.absent(),
                Value<bool> isTab = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CounterpartiesCompanion.insert(
                id: id,
                name: name,
                includeInStatistics: includeInStatistics,
                includeInCalculator: includeInCalculator,
                visible: visible,
                isTab: isTab,
                profileId: profileId,
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
              ({
                profileId = false,
                ledgerTransactionsRefs = false,
                vendorRulesRefs = false,
                smsRulesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ledgerTransactionsRefs) db.ledgerTransactions,
                    if (vendorRulesRefs) db.vendorRules,
                    if (smsRulesRefs) db.smsRules,
                  ],
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
                        if (profileId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.profileId,
                                    referencedTable:
                                        $$CounterpartiesTableReferences
                                            ._profileIdTable(db),
                                    referencedColumn:
                                        $$CounterpartiesTableReferences
                                            ._profileIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
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
                      if (smsRulesRefs)
                        await $_getPrefetchedData<
                          Counterparty,
                          $CounterpartiesTable,
                          SmsRule
                        >(
                          currentTable: table,
                          referencedTable: $$CounterpartiesTableReferences
                              ._smsRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CounterpartiesTableReferences(
                                db,
                                table,
                                p0,
                              ).smsRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.targetCounterpartyId == item.id,
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
        bool profileId,
        bool ledgerTransactionsRefs,
        bool vendorRulesRefs,
        bool smsRulesRefs,
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
      Value<String?> profileId,
      Value<String> source,
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
      Value<String?> profileId,
      Value<String> source,
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

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('ledger_transactions__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
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

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
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

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
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

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
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

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
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

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

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

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
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
          PrefetchHooks Function({bool counterpartyId, bool profileId})
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
                Value<String?> profileId = const Value.absent(),
                Value<String> source = const Value.absent(),
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
                profileId: profileId,
                source: source,
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
                Value<String?> profileId = const Value.absent(),
                Value<String> source = const Value.absent(),
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
                profileId: profileId,
                source: source,
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
          prefetchHooksCallback: ({counterpartyId = false, profileId = false}) {
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
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable:
                                    $$LedgerTransactionsTableReferences
                                        ._profileIdTable(db),
                                referencedColumn:
                                    $$LedgerTransactionsTableReferences
                                        ._profileIdTable(db)
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
      PrefetchHooks Function({bool counterpartyId, bool profileId})
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
      Value<String?> profileId,
      Value<int> rowid,
    });
typedef $$VendorRulesTableUpdateCompanionBuilder =
    VendorRulesCompanion Function({
      Value<String> id,
      Value<String> vendorPattern,
      Value<String> counterpartyId,
      Value<String> category,
      Value<String?> profileId,
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

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('vendor_rules__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
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

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
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

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
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

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
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
          PrefetchHooks Function({bool counterpartyId, bool profileId})
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
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VendorRulesCompanion(
                id: id,
                vendorPattern: vendorPattern,
                counterpartyId: counterpartyId,
                category: category,
                profileId: profileId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vendorPattern,
                required String counterpartyId,
                required String category,
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VendorRulesCompanion.insert(
                id: id,
                vendorPattern: vendorPattern,
                counterpartyId: counterpartyId,
                category: category,
                profileId: profileId,
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
          prefetchHooksCallback: ({counterpartyId = false, profileId = false}) {
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
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$VendorRulesTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$VendorRulesTableReferences
                                    ._profileIdTable(db)
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
      PrefetchHooks Function({bool counterpartyId, bool profileId})
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
      Value<String> manualInputEntriesJson,
      Value<bool> cardsRecorded,
      Value<bool> manualInputsRecorded,
      Value<String> bankAccountEntriesJson,
      Value<String?> profileId,
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
      Value<String> manualInputEntriesJson,
      Value<bool> cardsRecorded,
      Value<bool> manualInputsRecorded,
      Value<String> bankAccountEntriesJson,
      Value<String?> profileId,
      Value<int> rowid,
    });

final class $$CalculatorSnapshotsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CalculatorSnapshotsTable,
          CalculatorSnapshot
        > {
  $$CalculatorSnapshotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('calculator_snapshots__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  ColumnFilters<String> get manualInputEntriesJson => $composableBuilder(
    column: $table.manualInputEntriesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cardsRecorded => $composableBuilder(
    column: $table.cardsRecorded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get manualInputsRecorded => $composableBuilder(
    column: $table.manualInputsRecorded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankAccountEntriesJson => $composableBuilder(
    column: $table.bankAccountEntriesJson,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<String> get manualInputEntriesJson => $composableBuilder(
    column: $table.manualInputEntriesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cardsRecorded => $composableBuilder(
    column: $table.cardsRecorded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get manualInputsRecorded => $composableBuilder(
    column: $table.manualInputsRecorded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankAccountEntriesJson => $composableBuilder(
    column: $table.bankAccountEntriesJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get manualInputEntriesJson => $composableBuilder(
    column: $table.manualInputEntriesJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cardsRecorded => $composableBuilder(
    column: $table.cardsRecorded,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get manualInputsRecorded => $composableBuilder(
    column: $table.manualInputsRecorded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankAccountEntriesJson => $composableBuilder(
    column: $table.bankAccountEntriesJson,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (CalculatorSnapshot, $$CalculatorSnapshotsTableReferences),
          CalculatorSnapshot,
          PrefetchHooks Function({bool profileId})
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
                Value<String> manualInputEntriesJson = const Value.absent(),
                Value<bool> cardsRecorded = const Value.absent(),
                Value<bool> manualInputsRecorded = const Value.absent(),
                Value<String> bankAccountEntriesJson = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
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
                manualInputEntriesJson: manualInputEntriesJson,
                cardsRecorded: cardsRecorded,
                manualInputsRecorded: manualInputsRecorded,
                bankAccountEntriesJson: bankAccountEntriesJson,
                profileId: profileId,
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
                Value<String> manualInputEntriesJson = const Value.absent(),
                Value<bool> cardsRecorded = const Value.absent(),
                Value<bool> manualInputsRecorded = const Value.absent(),
                Value<String> bankAccountEntriesJson = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
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
                manualInputEntriesJson: manualInputEntriesJson,
                cardsRecorded: cardsRecorded,
                manualInputsRecorded: manualInputsRecorded,
                bankAccountEntriesJson: bankAccountEntriesJson,
                profileId: profileId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CalculatorSnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
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
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable:
                                    $$CalculatorSnapshotsTableReferences
                                        ._profileIdTable(db),
                                referencedColumn:
                                    $$CalculatorSnapshotsTableReferences
                                        ._profileIdTable(db)
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
      (CalculatorSnapshot, $$CalculatorSnapshotsTableReferences),
      CalculatorSnapshot,
      PrefetchHooks Function({bool profileId})
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
      Value<double?> currentAvailableBalance,
      Value<DateTime?> balanceUpdatedAt,
      Value<String?> balanceUpdatedSource,
      Value<String?> profileId,
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
      Value<double?> currentAvailableBalance,
      Value<DateTime?> balanceUpdatedAt,
      Value<String?> balanceUpdatedSource,
      Value<String?> profileId,
      Value<int> rowid,
    });

final class $$CreditCardsTableReferences
    extends BaseReferences<_$AppDatabase, $CreditCardsTable, CreditCard> {
  $$CreditCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('credit_cards__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  ColumnFilters<double> get currentAvailableBalance => $composableBuilder(
    column: $table.currentAvailableBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get balanceUpdatedAt => $composableBuilder(
    column: $table.balanceUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get balanceUpdatedSource => $composableBuilder(
    column: $table.balanceUpdatedSource,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<double> get currentAvailableBalance => $composableBuilder(
    column: $table.currentAvailableBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get balanceUpdatedAt => $composableBuilder(
    column: $table.balanceUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get balanceUpdatedSource => $composableBuilder(
    column: $table.balanceUpdatedSource,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<double> get currentAvailableBalance => $composableBuilder(
    column: $table.currentAvailableBalance,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get balanceUpdatedAt => $composableBuilder(
    column: $table.balanceUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get balanceUpdatedSource => $composableBuilder(
    column: $table.balanceUpdatedSource,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (CreditCard, $$CreditCardsTableReferences),
          CreditCard,
          PrefetchHooks Function({bool profileId})
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
                Value<double?> currentAvailableBalance = const Value.absent(),
                Value<DateTime?> balanceUpdatedAt = const Value.absent(),
                Value<String?> balanceUpdatedSource = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditCardsCompanion(
                id: id,
                name: name,
                bank: bank,
                limitAmount: limitAmount,
                currency: currency,
                sortOrder: sortOrder,
                lastFourDigits: lastFourDigits,
                currentAvailableBalance: currentAvailableBalance,
                balanceUpdatedAt: balanceUpdatedAt,
                balanceUpdatedSource: balanceUpdatedSource,
                profileId: profileId,
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
                Value<double?> currentAvailableBalance = const Value.absent(),
                Value<DateTime?> balanceUpdatedAt = const Value.absent(),
                Value<String?> balanceUpdatedSource = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditCardsCompanion.insert(
                id: id,
                name: name,
                bank: bank,
                limitAmount: limitAmount,
                currency: currency,
                sortOrder: sortOrder,
                lastFourDigits: lastFourDigits,
                currentAvailableBalance: currentAvailableBalance,
                balanceUpdatedAt: balanceUpdatedAt,
                balanceUpdatedSource: balanceUpdatedSource,
                profileId: profileId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CreditCardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
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
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$CreditCardsTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$CreditCardsTableReferences
                                    ._profileIdTable(db)
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
      (CreditCard, $$CreditCardsTableReferences),
      CreditCard,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$LedgerCategoriesTableCreateCompanionBuilder =
    LedgerCategoriesCompanion Function({
      required String id,
      required String name,
      Value<int> sortOrder,
      Value<String?> icon,
      Value<String?> profileId,
      Value<int> rowid,
    });
typedef $$LedgerCategoriesTableUpdateCompanionBuilder =
    LedgerCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<String?> icon,
      Value<String?> profileId,
      Value<int> rowid,
    });

final class $$LedgerCategoriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $LedgerCategoriesTable, LedgerCategory> {
  $$LedgerCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('ledger_categories__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (LedgerCategory, $$LedgerCategoriesTableReferences),
          LedgerCategory,
          PrefetchHooks Function({bool profileId})
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
                Value<String?> icon = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerCategoriesCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                icon: icon,
                profileId: profileId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerCategoriesCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                icon: icon,
                profileId: profileId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LedgerCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
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
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable:
                                    $$LedgerCategoriesTableReferences
                                        ._profileIdTable(db),
                                referencedColumn:
                                    $$LedgerCategoriesTableReferences
                                        ._profileIdTable(db)
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
      (LedgerCategory, $$LedgerCategoriesTableReferences),
      LedgerCategory,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$ManualInputsTableCreateCompanionBuilder =
    ManualInputsCompanion Function({
      required String id,
      required String name,
      required bool isAddition,
      Value<String> currency,
      Value<int> sortOrder,
      Value<String?> profileId,
      Value<double?> currentValue,
      Value<int> rowid,
    });
typedef $$ManualInputsTableUpdateCompanionBuilder =
    ManualInputsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> isAddition,
      Value<String> currency,
      Value<int> sortOrder,
      Value<String?> profileId,
      Value<double?> currentValue,
      Value<int> rowid,
    });

final class $$ManualInputsTableReferences
    extends BaseReferences<_$AppDatabase, $ManualInputsTable, ManualInput> {
  $$ManualInputsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('manual_inputs__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ManualInputsTableFilterComposer
    extends Composer<_$AppDatabase, $ManualInputsTable> {
  $$ManualInputsTableFilterComposer({
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

  ColumnFilters<bool> get isAddition => $composableBuilder(
    column: $table.isAddition,
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

  ColumnFilters<double> get currentValue => $composableBuilder(
    column: $table.currentValue,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ManualInputsTableOrderingComposer
    extends Composer<_$AppDatabase, $ManualInputsTable> {
  $$ManualInputsTableOrderingComposer({
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

  ColumnOrderings<bool> get isAddition => $composableBuilder(
    column: $table.isAddition,
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

  ColumnOrderings<double> get currentValue => $composableBuilder(
    column: $table.currentValue,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ManualInputsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ManualInputsTable> {
  $$ManualInputsTableAnnotationComposer({
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

  GeneratedColumn<bool> get isAddition => $composableBuilder(
    column: $table.isAddition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<double> get currentValue => $composableBuilder(
    column: $table.currentValue,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ManualInputsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ManualInputsTable,
          ManualInput,
          $$ManualInputsTableFilterComposer,
          $$ManualInputsTableOrderingComposer,
          $$ManualInputsTableAnnotationComposer,
          $$ManualInputsTableCreateCompanionBuilder,
          $$ManualInputsTableUpdateCompanionBuilder,
          (ManualInput, $$ManualInputsTableReferences),
          ManualInput,
          PrefetchHooks Function({bool profileId})
        > {
  $$ManualInputsTableTableManager(_$AppDatabase db, $ManualInputsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManualInputsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ManualInputsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ManualInputsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isAddition = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<double?> currentValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManualInputsCompanion(
                id: id,
                name: name,
                isAddition: isAddition,
                currency: currency,
                sortOrder: sortOrder,
                profileId: profileId,
                currentValue: currentValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required bool isAddition,
                Value<String> currency = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<double?> currentValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManualInputsCompanion.insert(
                id: id,
                name: name,
                isAddition: isAddition,
                currency: currency,
                sortOrder: sortOrder,
                profileId: profileId,
                currentValue: currentValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ManualInputsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
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
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$ManualInputsTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$ManualInputsTableReferences
                                    ._profileIdTable(db)
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

typedef $$ManualInputsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ManualInputsTable,
      ManualInput,
      $$ManualInputsTableFilterComposer,
      $$ManualInputsTableOrderingComposer,
      $$ManualInputsTableAnnotationComposer,
      $$ManualInputsTableCreateCompanionBuilder,
      $$ManualInputsTableUpdateCompanionBuilder,
      (ManualInput, $$ManualInputsTableReferences),
      ManualInput,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$RecurringPaymentsTableCreateCompanionBuilder =
    RecurringPaymentsCompanion Function({
      required String id,
      required String name,
      required double amount,
      Value<String> currency,
      Value<bool> isExactAmount,
      required int dayOfMonth,
      Value<int> sortOrder,
      Value<String?> profileId,
      Value<String> frequency,
      Value<int?> intervalDays,
      Value<DateTime?> intervalAnchorDate,
      Value<int?> yearlyMonth,
      Value<int?> yearlyDay,
      Value<DateTime?> lastPaidAt,
      Value<String?> notes,
      Value<String> paymentMode,
      Value<int> rowid,
    });
typedef $$RecurringPaymentsTableUpdateCompanionBuilder =
    RecurringPaymentsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> amount,
      Value<String> currency,
      Value<bool> isExactAmount,
      Value<int> dayOfMonth,
      Value<int> sortOrder,
      Value<String?> profileId,
      Value<String> frequency,
      Value<int?> intervalDays,
      Value<DateTime?> intervalAnchorDate,
      Value<int?> yearlyMonth,
      Value<int?> yearlyDay,
      Value<DateTime?> lastPaidAt,
      Value<String?> notes,
      Value<String> paymentMode,
      Value<int> rowid,
    });

final class $$RecurringPaymentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecurringPaymentsTable,
          RecurringPayment
        > {
  $$RecurringPaymentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('recurring_payments__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecurringPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringPaymentsTable> {
  $$RecurringPaymentsTableFilterComposer({
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

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExactAmount => $composableBuilder(
    column: $table.isExactAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get intervalAnchorDate => $composableBuilder(
    column: $table.intervalAnchorDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yearlyMonth => $composableBuilder(
    column: $table.yearlyMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yearlyDay => $composableBuilder(
    column: $table.yearlyDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPaidAt => $composableBuilder(
    column: $table.lastPaidAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringPaymentsTable> {
  $$RecurringPaymentsTableOrderingComposer({
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

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExactAmount => $composableBuilder(
    column: $table.isExactAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get intervalAnchorDate => $composableBuilder(
    column: $table.intervalAnchorDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yearlyMonth => $composableBuilder(
    column: $table.yearlyMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yearlyDay => $composableBuilder(
    column: $table.yearlyDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPaidAt => $composableBuilder(
    column: $table.lastPaidAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringPaymentsTable> {
  $$RecurringPaymentsTableAnnotationComposer({
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

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get isExactAmount => $composableBuilder(
    column: $table.isExactAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get intervalAnchorDate => $composableBuilder(
    column: $table.intervalAnchorDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get yearlyMonth => $composableBuilder(
    column: $table.yearlyMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get yearlyDay =>
      $composableBuilder(column: $table.yearlyDay, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPaidAt => $composableBuilder(
    column: $table.lastPaidAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringPaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringPaymentsTable,
          RecurringPayment,
          $$RecurringPaymentsTableFilterComposer,
          $$RecurringPaymentsTableOrderingComposer,
          $$RecurringPaymentsTableAnnotationComposer,
          $$RecurringPaymentsTableCreateCompanionBuilder,
          $$RecurringPaymentsTableUpdateCompanionBuilder,
          (RecurringPayment, $$RecurringPaymentsTableReferences),
          RecurringPayment,
          PrefetchHooks Function({bool profileId})
        > {
  $$RecurringPaymentsTableTableManager(
    _$AppDatabase db,
    $RecurringPaymentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringPaymentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<bool> isExactAmount = const Value.absent(),
                Value<int> dayOfMonth = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                Value<DateTime?> intervalAnchorDate = const Value.absent(),
                Value<int?> yearlyMonth = const Value.absent(),
                Value<int?> yearlyDay = const Value.absent(),
                Value<DateTime?> lastPaidAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> paymentMode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringPaymentsCompanion(
                id: id,
                name: name,
                amount: amount,
                currency: currency,
                isExactAmount: isExactAmount,
                dayOfMonth: dayOfMonth,
                sortOrder: sortOrder,
                profileId: profileId,
                frequency: frequency,
                intervalDays: intervalDays,
                intervalAnchorDate: intervalAnchorDate,
                yearlyMonth: yearlyMonth,
                yearlyDay: yearlyDay,
                lastPaidAt: lastPaidAt,
                notes: notes,
                paymentMode: paymentMode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double amount,
                Value<String> currency = const Value.absent(),
                Value<bool> isExactAmount = const Value.absent(),
                required int dayOfMonth,
                Value<int> sortOrder = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                Value<DateTime?> intervalAnchorDate = const Value.absent(),
                Value<int?> yearlyMonth = const Value.absent(),
                Value<int?> yearlyDay = const Value.absent(),
                Value<DateTime?> lastPaidAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> paymentMode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringPaymentsCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                currency: currency,
                isExactAmount: isExactAmount,
                dayOfMonth: dayOfMonth,
                sortOrder: sortOrder,
                profileId: profileId,
                frequency: frequency,
                intervalDays: intervalDays,
                intervalAnchorDate: intervalAnchorDate,
                yearlyMonth: yearlyMonth,
                yearlyDay: yearlyDay,
                lastPaidAt: lastPaidAt,
                notes: notes,
                paymentMode: paymentMode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecurringPaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
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
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable:
                                    $$RecurringPaymentsTableReferences
                                        ._profileIdTable(db),
                                referencedColumn:
                                    $$RecurringPaymentsTableReferences
                                        ._profileIdTable(db)
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

typedef $$RecurringPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringPaymentsTable,
      RecurringPayment,
      $$RecurringPaymentsTableFilterComposer,
      $$RecurringPaymentsTableOrderingComposer,
      $$RecurringPaymentsTableAnnotationComposer,
      $$RecurringPaymentsTableCreateCompanionBuilder,
      $$RecurringPaymentsTableUpdateCompanionBuilder,
      (RecurringPayment, $$RecurringPaymentsTableReferences),
      RecurringPayment,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$RecurringPaymentHistoryTableCreateCompanionBuilder =
    RecurringPaymentHistoryCompanion Function({
      required String id,
      Value<String?> profileId,
      required int year,
      required int month,
      Value<String> currency,
      required double totalAmount,
      required double paidAmount,
      required DateTime recordedAt,
      Value<String> itemsJson,
      Value<int> rowid,
    });
typedef $$RecurringPaymentHistoryTableUpdateCompanionBuilder =
    RecurringPaymentHistoryCompanion Function({
      Value<String> id,
      Value<String?> profileId,
      Value<int> year,
      Value<int> month,
      Value<String> currency,
      Value<double> totalAmount,
      Value<double> paidAmount,
      Value<DateTime> recordedAt,
      Value<String> itemsJson,
      Value<int> rowid,
    });

final class $$RecurringPaymentHistoryTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecurringPaymentHistoryTable,
          RecurringPaymentHistoryData
        > {
  $$RecurringPaymentHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _profileIdTable(_$AppDatabase db) => db.profiles
      .createAlias('recurring_payment_history__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecurringPaymentHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringPaymentHistoryTable> {
  $$RecurringPaymentHistoryTableFilterComposer({
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

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringPaymentHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringPaymentHistoryTable> {
  $$RecurringPaymentHistoryTableOrderingComposer({
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

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringPaymentHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringPaymentHistoryTable> {
  $$RecurringPaymentHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringPaymentHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringPaymentHistoryTable,
          RecurringPaymentHistoryData,
          $$RecurringPaymentHistoryTableFilterComposer,
          $$RecurringPaymentHistoryTableOrderingComposer,
          $$RecurringPaymentHistoryTableAnnotationComposer,
          $$RecurringPaymentHistoryTableCreateCompanionBuilder,
          $$RecurringPaymentHistoryTableUpdateCompanionBuilder,
          (
            RecurringPaymentHistoryData,
            $$RecurringPaymentHistoryTableReferences,
          ),
          RecurringPaymentHistoryData,
          PrefetchHooks Function({bool profileId})
        > {
  $$RecurringPaymentHistoryTableTableManager(
    _$AppDatabase db,
    $RecurringPaymentHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringPaymentHistoryTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RecurringPaymentHistoryTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RecurringPaymentHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<double> paidAmount = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringPaymentHistoryCompanion(
                id: id,
                profileId: profileId,
                year: year,
                month: month,
                currency: currency,
                totalAmount: totalAmount,
                paidAmount: paidAmount,
                recordedAt: recordedAt,
                itemsJson: itemsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> profileId = const Value.absent(),
                required int year,
                required int month,
                Value<String> currency = const Value.absent(),
                required double totalAmount,
                required double paidAmount,
                required DateTime recordedAt,
                Value<String> itemsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringPaymentHistoryCompanion.insert(
                id: id,
                profileId: profileId,
                year: year,
                month: month,
                currency: currency,
                totalAmount: totalAmount,
                paidAmount: paidAmount,
                recordedAt: recordedAt,
                itemsJson: itemsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecurringPaymentHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
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
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable:
                                    $$RecurringPaymentHistoryTableReferences
                                        ._profileIdTable(db),
                                referencedColumn:
                                    $$RecurringPaymentHistoryTableReferences
                                        ._profileIdTable(db)
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

typedef $$RecurringPaymentHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringPaymentHistoryTable,
      RecurringPaymentHistoryData,
      $$RecurringPaymentHistoryTableFilterComposer,
      $$RecurringPaymentHistoryTableOrderingComposer,
      $$RecurringPaymentHistoryTableAnnotationComposer,
      $$RecurringPaymentHistoryTableCreateCompanionBuilder,
      $$RecurringPaymentHistoryTableUpdateCompanionBuilder,
      (RecurringPaymentHistoryData, $$RecurringPaymentHistoryTableReferences),
      RecurringPaymentHistoryData,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$BankAccountsTableCreateCompanionBuilder =
    BankAccountsCompanion Function({
      required String id,
      required String name,
      required String bank,
      Value<String> currency,
      Value<int> sortOrder,
      Value<String?> accountNumber,
      Value<double?> currentAvailableBalance,
      Value<String?> profileId,
      Value<int> rowid,
    });
typedef $$BankAccountsTableUpdateCompanionBuilder =
    BankAccountsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> bank,
      Value<String> currency,
      Value<int> sortOrder,
      Value<String?> accountNumber,
      Value<double?> currentAvailableBalance,
      Value<String?> profileId,
      Value<int> rowid,
    });

final class $$BankAccountsTableReferences
    extends BaseReferences<_$AppDatabase, $BankAccountsTable, BankAccount> {
  $$BankAccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('bank_accounts__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BankAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $BankAccountsTable> {
  $$BankAccountsTableFilterComposer({
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

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentAvailableBalance => $composableBuilder(
    column: $table.currentAvailableBalance,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BankAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $BankAccountsTable> {
  $$BankAccountsTableOrderingComposer({
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

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentAvailableBalance => $composableBuilder(
    column: $table.currentAvailableBalance,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BankAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BankAccountsTable> {
  $$BankAccountsTableAnnotationComposer({
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

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentAvailableBalance => $composableBuilder(
    column: $table.currentAvailableBalance,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BankAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BankAccountsTable,
          BankAccount,
          $$BankAccountsTableFilterComposer,
          $$BankAccountsTableOrderingComposer,
          $$BankAccountsTableAnnotationComposer,
          $$BankAccountsTableCreateCompanionBuilder,
          $$BankAccountsTableUpdateCompanionBuilder,
          (BankAccount, $$BankAccountsTableReferences),
          BankAccount,
          PrefetchHooks Function({bool profileId})
        > {
  $$BankAccountsTableTableManager(_$AppDatabase db, $BankAccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BankAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BankAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BankAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> bank = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> accountNumber = const Value.absent(),
                Value<double?> currentAvailableBalance = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BankAccountsCompanion(
                id: id,
                name: name,
                bank: bank,
                currency: currency,
                sortOrder: sortOrder,
                accountNumber: accountNumber,
                currentAvailableBalance: currentAvailableBalance,
                profileId: profileId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String bank,
                Value<String> currency = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> accountNumber = const Value.absent(),
                Value<double?> currentAvailableBalance = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BankAccountsCompanion.insert(
                id: id,
                name: name,
                bank: bank,
                currency: currency,
                sortOrder: sortOrder,
                accountNumber: accountNumber,
                currentAvailableBalance: currentAvailableBalance,
                profileId: profileId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BankAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
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
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$BankAccountsTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$BankAccountsTableReferences
                                    ._profileIdTable(db)
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

typedef $$BankAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BankAccountsTable,
      BankAccount,
      $$BankAccountsTableFilterComposer,
      $$BankAccountsTableOrderingComposer,
      $$BankAccountsTableAnnotationComposer,
      $$BankAccountsTableCreateCompanionBuilder,
      $$BankAccountsTableUpdateCompanionBuilder,
      (BankAccount, $$BankAccountsTableReferences),
      BankAccount,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$BanksTableCreateCompanionBuilder =
    BanksCompanion Function({
      required String id,
      required String name,
      Value<int> sortOrder,
      Value<String?> profileId,
      Value<int> rowid,
    });
typedef $$BanksTableUpdateCompanionBuilder =
    BanksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<String?> profileId,
      Value<int> rowid,
    });

final class $$BanksTableReferences
    extends BaseReferences<_$AppDatabase, $BanksTable, Bank> {
  $$BanksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('banks__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SmsRulesTable, List<SmsRule>> _smsRulesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.smsRules,
    aliasName: 'banks__id__sms_rules__bank_id',
  );

  $$SmsRulesTableProcessedTableManager get smsRulesRefs {
    final manager = $$SmsRulesTableTableManager(
      $_db,
      $_db.smsRules,
    ).filter((f) => f.bankId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_smsRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BanksTableFilterComposer extends Composer<_$AppDatabase, $BanksTable> {
  $$BanksTableFilterComposer({
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

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> smsRulesRefs(
    Expression<bool> Function($$SmsRulesTableFilterComposer f) f,
  ) {
    final $$SmsRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.smsRules,
      getReferencedColumn: (t) => t.bankId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmsRulesTableFilterComposer(
            $db: $db,
            $table: $db.smsRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BanksTableOrderingComposer
    extends Composer<_$AppDatabase, $BanksTable> {
  $$BanksTableOrderingComposer({
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

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BanksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BanksTable> {
  $$BanksTableAnnotationComposer({
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

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> smsRulesRefs<T extends Object>(
    Expression<T> Function($$SmsRulesTableAnnotationComposer a) f,
  ) {
    final $$SmsRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.smsRules,
      getReferencedColumn: (t) => t.bankId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmsRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.smsRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BanksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BanksTable,
          Bank,
          $$BanksTableFilterComposer,
          $$BanksTableOrderingComposer,
          $$BanksTableAnnotationComposer,
          $$BanksTableCreateCompanionBuilder,
          $$BanksTableUpdateCompanionBuilder,
          (Bank, $$BanksTableReferences),
          Bank,
          PrefetchHooks Function({bool profileId, bool smsRulesRefs})
        > {
  $$BanksTableTableManager(_$AppDatabase db, $BanksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BanksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BanksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BanksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BanksCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                profileId: profileId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BanksCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                profileId: profileId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BanksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false, smsRulesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (smsRulesRefs) db.smsRules],
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
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$BanksTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$BanksTableReferences
                                    ._profileIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (smsRulesRefs)
                    await $_getPrefetchedData<Bank, $BanksTable, SmsRule>(
                      currentTable: table,
                      referencedTable: $$BanksTableReferences
                          ._smsRulesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BanksTableReferences(db, table, p0).smsRulesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.bankId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BanksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BanksTable,
      Bank,
      $$BanksTableFilterComposer,
      $$BanksTableOrderingComposer,
      $$BanksTableAnnotationComposer,
      $$BanksTableCreateCompanionBuilder,
      $$BanksTableUpdateCompanionBuilder,
      (Bank, $$BanksTableReferences),
      Bank,
      PrefetchHooks Function({bool profileId, bool smsRulesRefs})
    >;
typedef $$SmsRulesTableCreateCompanionBuilder =
    SmsRulesCompanion Function({
      required String id,
      required String bankId,
      Value<String?> name,
      required String operation,
      required String sampleText,
      required String segmentsJson,
      Value<String?> targetCounterpartyId,
      Value<String?> currency,
      Value<bool> notifyOnMatch,
      Value<String> matchMode,
      Value<bool> enabled,
      required DateTime createdAt,
      Value<String?> profileId,
      Value<int> rowid,
    });
typedef $$SmsRulesTableUpdateCompanionBuilder =
    SmsRulesCompanion Function({
      Value<String> id,
      Value<String> bankId,
      Value<String?> name,
      Value<String> operation,
      Value<String> sampleText,
      Value<String> segmentsJson,
      Value<String?> targetCounterpartyId,
      Value<String?> currency,
      Value<bool> notifyOnMatch,
      Value<String> matchMode,
      Value<bool> enabled,
      Value<DateTime> createdAt,
      Value<String?> profileId,
      Value<int> rowid,
    });

final class $$SmsRulesTableReferences
    extends BaseReferences<_$AppDatabase, $SmsRulesTable, SmsRule> {
  $$SmsRulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BanksTable _bankIdTable(_$AppDatabase db) =>
      db.banks.createAlias('sms_rules__bank_id__banks__id');

  $$BanksTableProcessedTableManager get bankId {
    final $_column = $_itemColumn<String>('bank_id')!;

    final manager = $$BanksTableTableManager(
      $_db,
      $_db.banks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bankIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CounterpartiesTable _targetCounterpartyIdTable(_$AppDatabase db) => db
      .counterparties
      .createAlias('sms_rules__target_counterparty_id__counterparties__id');

  $$CounterpartiesTableProcessedTableManager? get targetCounterpartyId {
    final $_column = $_itemColumn<String>('target_counterparty_id');
    if ($_column == null) return null;
    final manager = $$CounterpartiesTableTableManager(
      $_db,
      $_db.counterparties,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _targetCounterpartyIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('sms_rules__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<String>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SmsRulesTableFilterComposer
    extends Composer<_$AppDatabase, $SmsRulesTable> {
  $$SmsRulesTableFilterComposer({
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

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sampleText => $composableBuilder(
    column: $table.sampleText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyOnMatch => $composableBuilder(
    column: $table.notifyOnMatch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchMode => $composableBuilder(
    column: $table.matchMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BanksTableFilterComposer get bankId {
    final $$BanksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bankId,
      referencedTable: $db.banks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BanksTableFilterComposer(
            $db: $db,
            $table: $db.banks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CounterpartiesTableFilterComposer get targetCounterpartyId {
    final $$CounterpartiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetCounterpartyId,
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

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmsRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $SmsRulesTable> {
  $$SmsRulesTableOrderingComposer({
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

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sampleText => $composableBuilder(
    column: $table.sampleText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyOnMatch => $composableBuilder(
    column: $table.notifyOnMatch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchMode => $composableBuilder(
    column: $table.matchMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BanksTableOrderingComposer get bankId {
    final $$BanksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bankId,
      referencedTable: $db.banks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BanksTableOrderingComposer(
            $db: $db,
            $table: $db.banks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CounterpartiesTableOrderingComposer get targetCounterpartyId {
    final $$CounterpartiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetCounterpartyId,
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

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmsRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmsRulesTable> {
  $$SmsRulesTableAnnotationComposer({
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

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get sampleText => $composableBuilder(
    column: $table.sampleText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get notifyOnMatch => $composableBuilder(
    column: $table.notifyOnMatch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchMode =>
      $composableBuilder(column: $table.matchMode, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BanksTableAnnotationComposer get bankId {
    final $$BanksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bankId,
      referencedTable: $db.banks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BanksTableAnnotationComposer(
            $db: $db,
            $table: $db.banks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CounterpartiesTableAnnotationComposer get targetCounterpartyId {
    final $$CounterpartiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetCounterpartyId,
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

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmsRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmsRulesTable,
          SmsRule,
          $$SmsRulesTableFilterComposer,
          $$SmsRulesTableOrderingComposer,
          $$SmsRulesTableAnnotationComposer,
          $$SmsRulesTableCreateCompanionBuilder,
          $$SmsRulesTableUpdateCompanionBuilder,
          (SmsRule, $$SmsRulesTableReferences),
          SmsRule,
          PrefetchHooks Function({
            bool bankId,
            bool targetCounterpartyId,
            bool profileId,
          })
        > {
  $$SmsRulesTableTableManager(_$AppDatabase db, $SmsRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmsRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmsRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmsRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bankId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> sampleText = const Value.absent(),
                Value<String> segmentsJson = const Value.absent(),
                Value<String?> targetCounterpartyId = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<bool> notifyOnMatch = const Value.absent(),
                Value<String> matchMode = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsRulesCompanion(
                id: id,
                bankId: bankId,
                name: name,
                operation: operation,
                sampleText: sampleText,
                segmentsJson: segmentsJson,
                targetCounterpartyId: targetCounterpartyId,
                currency: currency,
                notifyOnMatch: notifyOnMatch,
                matchMode: matchMode,
                enabled: enabled,
                createdAt: createdAt,
                profileId: profileId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bankId,
                Value<String?> name = const Value.absent(),
                required String operation,
                required String sampleText,
                required String segmentsJson,
                Value<String?> targetCounterpartyId = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<bool> notifyOnMatch = const Value.absent(),
                Value<String> matchMode = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                required DateTime createdAt,
                Value<String?> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsRulesCompanion.insert(
                id: id,
                bankId: bankId,
                name: name,
                operation: operation,
                sampleText: sampleText,
                segmentsJson: segmentsJson,
                targetCounterpartyId: targetCounterpartyId,
                currency: currency,
                notifyOnMatch: notifyOnMatch,
                matchMode: matchMode,
                enabled: enabled,
                createdAt: createdAt,
                profileId: profileId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SmsRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bankId = false,
                targetCounterpartyId = false,
                profileId = false,
              }) {
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
                        if (bankId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bankId,
                                    referencedTable: $$SmsRulesTableReferences
                                        ._bankIdTable(db),
                                    referencedColumn: $$SmsRulesTableReferences
                                        ._bankIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (targetCounterpartyId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.targetCounterpartyId,
                                    referencedTable: $$SmsRulesTableReferences
                                        ._targetCounterpartyIdTable(db),
                                    referencedColumn: $$SmsRulesTableReferences
                                        ._targetCounterpartyIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (profileId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.profileId,
                                    referencedTable: $$SmsRulesTableReferences
                                        ._profileIdTable(db),
                                    referencedColumn: $$SmsRulesTableReferences
                                        ._profileIdTable(db)
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

typedef $$SmsRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmsRulesTable,
      SmsRule,
      $$SmsRulesTableFilterComposer,
      $$SmsRulesTableOrderingComposer,
      $$SmsRulesTableAnnotationComposer,
      $$SmsRulesTableCreateCompanionBuilder,
      $$SmsRulesTableUpdateCompanionBuilder,
      (SmsRule, $$SmsRulesTableReferences),
      SmsRule,
      PrefetchHooks Function({
        bool bankId,
        bool targetCounterpartyId,
        bool profileId,
      })
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
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
  $$ManualInputsTableTableManager get manualInputs =>
      $$ManualInputsTableTableManager(_db, _db.manualInputs);
  $$RecurringPaymentsTableTableManager get recurringPayments =>
      $$RecurringPaymentsTableTableManager(_db, _db.recurringPayments);
  $$RecurringPaymentHistoryTableTableManager get recurringPaymentHistory =>
      $$RecurringPaymentHistoryTableTableManager(
        _db,
        _db.recurringPaymentHistory,
      );
  $$BankAccountsTableTableManager get bankAccounts =>
      $$BankAccountsTableTableManager(_db, _db.bankAccounts);
  $$BanksTableTableManager get banks =>
      $$BanksTableTableManager(_db, _db.banks);
  $$SmsRulesTableTableManager get smsRules =>
      $$SmsRulesTableTableManager(_db, _db.smsRules);
}
