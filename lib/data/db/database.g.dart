// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $VehiclesTable extends Vehicles
    with TableInfo<$VehiclesTable, VehicleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _currentKmMeta = const VerificationMeta(
    'currentKm',
  );
  @override
  late final GeneratedColumn<int> currentKm = GeneratedColumn<int>(
    'current_km',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _btAddressMeta = const VerificationMeta(
    'btAddress',
  );
  @override
  late final GeneratedColumn<String> btAddress = GeneratedColumn<String>(
    'bt_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _btNameMeta = const VerificationMeta('btName');
  @override
  late final GeneratedColumn<String> btName = GeneratedColumn<String>(
    'bt_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tireFrontBarMeta = const VerificationMeta(
    'tireFrontBar',
  );
  @override
  late final GeneratedColumn<double> tireFrontBar = GeneratedColumn<double>(
    'tire_front_bar',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tireRearBarMeta = const VerificationMeta(
    'tireRearBar',
  );
  @override
  late final GeneratedColumn<double> tireRearBar = GeneratedColumn<double>(
    'tire_rear_bar',
    aliasedName,
    true,
    type: DriftSqlType.double,
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
    brand,
    model,
    year,
    currentKm,
    btAddress,
    btName,
    tireFrontBar,
    tireRearBar,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<VehicleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('current_km')) {
      context.handle(
        _currentKmMeta,
        currentKm.isAcceptableOrUnknown(data['current_km']!, _currentKmMeta),
      );
    } else if (isInserting) {
      context.missing(_currentKmMeta);
    }
    if (data.containsKey('bt_address')) {
      context.handle(
        _btAddressMeta,
        btAddress.isAcceptableOrUnknown(data['bt_address']!, _btAddressMeta),
      );
    }
    if (data.containsKey('bt_name')) {
      context.handle(
        _btNameMeta,
        btName.isAcceptableOrUnknown(data['bt_name']!, _btNameMeta),
      );
    }
    if (data.containsKey('tire_front_bar')) {
      context.handle(
        _tireFrontBarMeta,
        tireFrontBar.isAcceptableOrUnknown(
          data['tire_front_bar']!,
          _tireFrontBarMeta,
        ),
      );
    }
    if (data.containsKey('tire_rear_bar')) {
      context.handle(
        _tireRearBarMeta,
        tireRearBar.isAcceptableOrUnknown(
          data['tire_rear_bar']!,
          _tireRearBarMeta,
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
  VehicleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VehicleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      )!,
      currentKm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_km'],
      )!,
      btAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bt_address'],
      ),
      btName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bt_name'],
      ),
      tireFrontBar: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tire_front_bar'],
      ),
      tireRearBar: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tire_rear_bar'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VehiclesTable createAlias(String alias) {
    return $VehiclesTable(attachedDatabase, alias);
  }
}

class VehicleRow extends DataClass implements Insertable<VehicleRow> {
  final int id;
  final String brand;
  final String model;
  final String year;
  final int currentKm;
  final String? btAddress;
  final String? btName;
  final double? tireFrontBar;
  final double? tireRearBar;
  final DateTime createdAt;
  const VehicleRow({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.currentKm,
    this.btAddress,
    this.btName,
    this.tireFrontBar,
    this.tireRearBar,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['brand'] = Variable<String>(brand);
    map['model'] = Variable<String>(model);
    map['year'] = Variable<String>(year);
    map['current_km'] = Variable<int>(currentKm);
    if (!nullToAbsent || btAddress != null) {
      map['bt_address'] = Variable<String>(btAddress);
    }
    if (!nullToAbsent || btName != null) {
      map['bt_name'] = Variable<String>(btName);
    }
    if (!nullToAbsent || tireFrontBar != null) {
      map['tire_front_bar'] = Variable<double>(tireFrontBar);
    }
    if (!nullToAbsent || tireRearBar != null) {
      map['tire_rear_bar'] = Variable<double>(tireRearBar);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VehiclesCompanion toCompanion(bool nullToAbsent) {
    return VehiclesCompanion(
      id: Value(id),
      brand: Value(brand),
      model: Value(model),
      year: Value(year),
      currentKm: Value(currentKm),
      btAddress: btAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(btAddress),
      btName: btName == null && nullToAbsent
          ? const Value.absent()
          : Value(btName),
      tireFrontBar: tireFrontBar == null && nullToAbsent
          ? const Value.absent()
          : Value(tireFrontBar),
      tireRearBar: tireRearBar == null && nullToAbsent
          ? const Value.absent()
          : Value(tireRearBar),
      createdAt: Value(createdAt),
    );
  }

  factory VehicleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VehicleRow(
      id: serializer.fromJson<int>(json['id']),
      brand: serializer.fromJson<String>(json['brand']),
      model: serializer.fromJson<String>(json['model']),
      year: serializer.fromJson<String>(json['year']),
      currentKm: serializer.fromJson<int>(json['currentKm']),
      btAddress: serializer.fromJson<String?>(json['btAddress']),
      btName: serializer.fromJson<String?>(json['btName']),
      tireFrontBar: serializer.fromJson<double?>(json['tireFrontBar']),
      tireRearBar: serializer.fromJson<double?>(json['tireRearBar']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'brand': serializer.toJson<String>(brand),
      'model': serializer.toJson<String>(model),
      'year': serializer.toJson<String>(year),
      'currentKm': serializer.toJson<int>(currentKm),
      'btAddress': serializer.toJson<String?>(btAddress),
      'btName': serializer.toJson<String?>(btName),
      'tireFrontBar': serializer.toJson<double?>(tireFrontBar),
      'tireRearBar': serializer.toJson<double?>(tireRearBar),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VehicleRow copyWith({
    int? id,
    String? brand,
    String? model,
    String? year,
    int? currentKm,
    Value<String?> btAddress = const Value.absent(),
    Value<String?> btName = const Value.absent(),
    Value<double?> tireFrontBar = const Value.absent(),
    Value<double?> tireRearBar = const Value.absent(),
    DateTime? createdAt,
  }) => VehicleRow(
    id: id ?? this.id,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    year: year ?? this.year,
    currentKm: currentKm ?? this.currentKm,
    btAddress: btAddress.present ? btAddress.value : this.btAddress,
    btName: btName.present ? btName.value : this.btName,
    tireFrontBar: tireFrontBar.present ? tireFrontBar.value : this.tireFrontBar,
    tireRearBar: tireRearBar.present ? tireRearBar.value : this.tireRearBar,
    createdAt: createdAt ?? this.createdAt,
  );
  VehicleRow copyWithCompanion(VehiclesCompanion data) {
    return VehicleRow(
      id: data.id.present ? data.id.value : this.id,
      brand: data.brand.present ? data.brand.value : this.brand,
      model: data.model.present ? data.model.value : this.model,
      year: data.year.present ? data.year.value : this.year,
      currentKm: data.currentKm.present ? data.currentKm.value : this.currentKm,
      btAddress: data.btAddress.present ? data.btAddress.value : this.btAddress,
      btName: data.btName.present ? data.btName.value : this.btName,
      tireFrontBar: data.tireFrontBar.present
          ? data.tireFrontBar.value
          : this.tireFrontBar,
      tireRearBar: data.tireRearBar.present
          ? data.tireRearBar.value
          : this.tireRearBar,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VehicleRow(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('year: $year, ')
          ..write('currentKm: $currentKm, ')
          ..write('btAddress: $btAddress, ')
          ..write('btName: $btName, ')
          ..write('tireFrontBar: $tireFrontBar, ')
          ..write('tireRearBar: $tireRearBar, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    brand,
    model,
    year,
    currentKm,
    btAddress,
    btName,
    tireFrontBar,
    tireRearBar,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VehicleRow &&
          other.id == this.id &&
          other.brand == this.brand &&
          other.model == this.model &&
          other.year == this.year &&
          other.currentKm == this.currentKm &&
          other.btAddress == this.btAddress &&
          other.btName == this.btName &&
          other.tireFrontBar == this.tireFrontBar &&
          other.tireRearBar == this.tireRearBar &&
          other.createdAt == this.createdAt);
}

class VehiclesCompanion extends UpdateCompanion<VehicleRow> {
  final Value<int> id;
  final Value<String> brand;
  final Value<String> model;
  final Value<String> year;
  final Value<int> currentKm;
  final Value<String?> btAddress;
  final Value<String?> btName;
  final Value<double?> tireFrontBar;
  final Value<double?> tireRearBar;
  final Value<DateTime> createdAt;
  const VehiclesCompanion({
    this.id = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.year = const Value.absent(),
    this.currentKm = const Value.absent(),
    this.btAddress = const Value.absent(),
    this.btName = const Value.absent(),
    this.tireFrontBar = const Value.absent(),
    this.tireRearBar = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  VehiclesCompanion.insert({
    this.id = const Value.absent(),
    required String brand,
    this.model = const Value.absent(),
    this.year = const Value.absent(),
    required int currentKm,
    this.btAddress = const Value.absent(),
    this.btName = const Value.absent(),
    this.tireFrontBar = const Value.absent(),
    this.tireRearBar = const Value.absent(),
    required DateTime createdAt,
  }) : brand = Value(brand),
       currentKm = Value(currentKm),
       createdAt = Value(createdAt);
  static Insertable<VehicleRow> custom({
    Expression<int>? id,
    Expression<String>? brand,
    Expression<String>? model,
    Expression<String>? year,
    Expression<int>? currentKm,
    Expression<String>? btAddress,
    Expression<String>? btName,
    Expression<double>? tireFrontBar,
    Expression<double>? tireRearBar,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      if (currentKm != null) 'current_km': currentKm,
      if (btAddress != null) 'bt_address': btAddress,
      if (btName != null) 'bt_name': btName,
      if (tireFrontBar != null) 'tire_front_bar': tireFrontBar,
      if (tireRearBar != null) 'tire_rear_bar': tireRearBar,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  VehiclesCompanion copyWith({
    Value<int>? id,
    Value<String>? brand,
    Value<String>? model,
    Value<String>? year,
    Value<int>? currentKm,
    Value<String?>? btAddress,
    Value<String?>? btName,
    Value<double?>? tireFrontBar,
    Value<double?>? tireRearBar,
    Value<DateTime>? createdAt,
  }) {
    return VehiclesCompanion(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      currentKm: currentKm ?? this.currentKm,
      btAddress: btAddress ?? this.btAddress,
      btName: btName ?? this.btName,
      tireFrontBar: tireFrontBar ?? this.tireFrontBar,
      tireRearBar: tireRearBar ?? this.tireRearBar,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (currentKm.present) {
      map['current_km'] = Variable<int>(currentKm.value);
    }
    if (btAddress.present) {
      map['bt_address'] = Variable<String>(btAddress.value);
    }
    if (btName.present) {
      map['bt_name'] = Variable<String>(btName.value);
    }
    if (tireFrontBar.present) {
      map['tire_front_bar'] = Variable<double>(tireFrontBar.value);
    }
    if (tireRearBar.present) {
      map['tire_rear_bar'] = Variable<double>(tireRearBar.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VehiclesCompanion(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('year: $year, ')
          ..write('currentKm: $currentKm, ')
          ..write('btAddress: $btAddress, ')
          ..write('btName: $btName, ')
          ..write('tireFrontBar: $tireFrontBar, ')
          ..write('tireRearBar: $tireRearBar, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CheckItemsTable extends CheckItems
    with TableInfo<$CheckItemsTable, CheckItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<int> vehicleId = GeneratedColumn<int>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vehicles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _templateKeyMeta = const VerificationMeta(
    'templateKey',
  );
  @override
  late final GeneratedColumn<String> templateKey = GeneratedColumn<String>(
    'template_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _groupKeyMeta = const VerificationMeta(
    'groupKey',
  );
  @override
  late final GeneratedColumn<String> groupKey = GeneratedColumn<String>(
    'group_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduleKindMeta = const VerificationMeta(
    'scheduleKind',
  );
  @override
  late final GeneratedColumn<String> scheduleKind = GeneratedColumn<String>(
    'schedule_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _intervalKmMeta = const VerificationMeta(
    'intervalKm',
  );
  @override
  late final GeneratedColumn<int> intervalKm = GeneratedColumn<int>(
    'interval_km',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seasonalDatesMeta = const VerificationMeta(
    'seasonalDates',
  );
  @override
  late final GeneratedColumn<String> seasonalDates = GeneratedColumn<String>(
    'seasonal_dates',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _measureTypeMeta = const VerificationMeta(
    'measureType',
  );
  @override
  late final GeneratedColumn<String> measureType = GeneratedColumn<String>(
    'measure_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measureJsonMeta = const VerificationMeta(
    'measureJson',
  );
  @override
  late final GeneratedColumn<String> measureJson = GeneratedColumn<String>(
    'measure_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whyMeta = const VerificationMeta('why');
  @override
  late final GeneratedColumn<String> why = GeneratedColumn<String>(
    'why',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _howJsonMeta = const VerificationMeta(
    'howJson',
  );
  @override
  late final GeneratedColumn<String> howJson = GeneratedColumn<String>(
    'how_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('[]'),
  );
  static const VerificationMeta _warnMeta = const VerificationMeta('warn');
  @override
  late final GeneratedColumn<String> warn = GeneratedColumn<String>(
    'warn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceNoteMeta = const VerificationMeta(
    'sourceNote',
  );
  @override
  late final GeneratedColumn<String> sourceNote = GeneratedColumn<String>(
    'source_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifiedMeta = const VerificationMeta(
    'verified',
  );
  @override
  late final GeneratedColumn<String> verified = GeneratedColumn<String>(
    'verified',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('true'),
  );
  static const VerificationMeta _startsFromInstallMeta = const VerificationMeta(
    'startsFromInstall',
  );
  @override
  late final GeneratedColumn<bool> startsFromInstall = GeneratedColumn<bool>(
    'starts_from_install',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("starts_from_install" IN (0, 1))',
    ),
    defaultValue: const Constant<bool>(false),
  );
  static const VerificationMeta _appliesLastServiceMeta =
      const VerificationMeta('appliesLastService');
  @override
  late final GeneratedColumn<bool> appliesLastService = GeneratedColumn<bool>(
    'applies_last_service',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("applies_last_service" IN (0, 1))',
    ),
    defaultValue: const Constant<bool>(false),
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
    defaultValue: const Constant<bool>(true),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastDoneDayMeta = const VerificationMeta(
    'lastDoneDay',
  );
  @override
  late final GeneratedColumn<String> lastDoneDay = GeneratedColumn<String>(
    'last_done_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastDoneKmMeta = const VerificationMeta(
    'lastDoneKm',
  );
  @override
  late final GeneratedColumn<int> lastDoneKm = GeneratedColumn<int>(
    'last_done_km',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastValueMeta = const VerificationMeta(
    'lastValue',
  );
  @override
  late final GeneratedColumn<String> lastValue = GeneratedColumn<String>(
    'last_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snoozeUntilDayMeta = const VerificationMeta(
    'snoozeUntilDay',
  );
  @override
  late final GeneratedColumn<String> snoozeUntilDay = GeneratedColumn<String>(
    'snooze_until_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    templateKey,
    name,
    groupKey,
    scheduleKind,
    intervalDays,
    intervalKm,
    seasonalDates,
    measureType,
    measureJson,
    why,
    howJson,
    warn,
    sourceNote,
    verified,
    startsFromInstall,
    appliesLastService,
    enabled,
    sortOrder,
    lastDoneDay,
    lastDoneKm,
    lastValue,
    snoozeUntilDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('template_key')) {
      context.handle(
        _templateKeyMeta,
        templateKey.isAcceptableOrUnknown(
          data['template_key']!,
          _templateKeyMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('group_key')) {
      context.handle(
        _groupKeyMeta,
        groupKey.isAcceptableOrUnknown(data['group_key']!, _groupKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_groupKeyMeta);
    }
    if (data.containsKey('schedule_kind')) {
      context.handle(
        _scheduleKindMeta,
        scheduleKind.isAcceptableOrUnknown(
          data['schedule_kind']!,
          _scheduleKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduleKindMeta);
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
    if (data.containsKey('interval_km')) {
      context.handle(
        _intervalKmMeta,
        intervalKm.isAcceptableOrUnknown(data['interval_km']!, _intervalKmMeta),
      );
    }
    if (data.containsKey('seasonal_dates')) {
      context.handle(
        _seasonalDatesMeta,
        seasonalDates.isAcceptableOrUnknown(
          data['seasonal_dates']!,
          _seasonalDatesMeta,
        ),
      );
    }
    if (data.containsKey('measure_type')) {
      context.handle(
        _measureTypeMeta,
        measureType.isAcceptableOrUnknown(
          data['measure_type']!,
          _measureTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measureTypeMeta);
    }
    if (data.containsKey('measure_json')) {
      context.handle(
        _measureJsonMeta,
        measureJson.isAcceptableOrUnknown(
          data['measure_json']!,
          _measureJsonMeta,
        ),
      );
    }
    if (data.containsKey('why')) {
      context.handle(
        _whyMeta,
        why.isAcceptableOrUnknown(data['why']!, _whyMeta),
      );
    }
    if (data.containsKey('how_json')) {
      context.handle(
        _howJsonMeta,
        howJson.isAcceptableOrUnknown(data['how_json']!, _howJsonMeta),
      );
    }
    if (data.containsKey('warn')) {
      context.handle(
        _warnMeta,
        warn.isAcceptableOrUnknown(data['warn']!, _warnMeta),
      );
    }
    if (data.containsKey('source_note')) {
      context.handle(
        _sourceNoteMeta,
        sourceNote.isAcceptableOrUnknown(data['source_note']!, _sourceNoteMeta),
      );
    }
    if (data.containsKey('verified')) {
      context.handle(
        _verifiedMeta,
        verified.isAcceptableOrUnknown(data['verified']!, _verifiedMeta),
      );
    }
    if (data.containsKey('starts_from_install')) {
      context.handle(
        _startsFromInstallMeta,
        startsFromInstall.isAcceptableOrUnknown(
          data['starts_from_install']!,
          _startsFromInstallMeta,
        ),
      );
    }
    if (data.containsKey('applies_last_service')) {
      context.handle(
        _appliesLastServiceMeta,
        appliesLastService.isAcceptableOrUnknown(
          data['applies_last_service']!,
          _appliesLastServiceMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('last_done_day')) {
      context.handle(
        _lastDoneDayMeta,
        lastDoneDay.isAcceptableOrUnknown(
          data['last_done_day']!,
          _lastDoneDayMeta,
        ),
      );
    }
    if (data.containsKey('last_done_km')) {
      context.handle(
        _lastDoneKmMeta,
        lastDoneKm.isAcceptableOrUnknown(
          data['last_done_km']!,
          _lastDoneKmMeta,
        ),
      );
    }
    if (data.containsKey('last_value')) {
      context.handle(
        _lastValueMeta,
        lastValue.isAcceptableOrUnknown(data['last_value']!, _lastValueMeta),
      );
    }
    if (data.containsKey('snooze_until_day')) {
      context.handle(
        _snoozeUntilDayMeta,
        snoozeUntilDay.isAcceptableOrUnknown(
          data['snooze_until_day']!,
          _snoozeUntilDayMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {vehicleId, templateKey},
  ];
  @override
  CheckItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_id'],
      )!,
      templateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_key'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      groupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_key'],
      )!,
      scheduleKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_kind'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      ),
      intervalKm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_km'],
      ),
      seasonalDates: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seasonal_dates'],
      ),
      measureType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measure_type'],
      )!,
      measureJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measure_json'],
      ),
      why: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}why'],
      )!,
      howJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}how_json'],
      )!,
      warn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warn'],
      ),
      sourceNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_note'],
      ),
      verified: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verified'],
      )!,
      startsFromInstall: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}starts_from_install'],
      )!,
      appliesLastService: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}applies_last_service'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      lastDoneDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_done_day'],
      ),
      lastDoneKm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_done_km'],
      ),
      lastValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_value'],
      ),
      snoozeUntilDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snooze_until_day'],
      ),
    );
  }

  @override
  $CheckItemsTable createAlias(String alias) {
    return $CheckItemsTable(attachedDatabase, alias);
  }
}

class CheckItemRow extends DataClass implements Insertable<CheckItemRow> {
  final int id;
  final int vehicleId;

  /// Seed `id`; kullanıcı maddesinde null.
  final String? templateKey;
  final String name;

  /// `frequent|monthly|quarterly|service|yearly|seasonal|custom`
  final String groupKey;

  /// `days|km|both|seasonal`
  final String scheduleKind;
  final int? intervalDays;
  final int? intervalKm;

  /// JSON `[{"month":11,"day":1},...]`
  final String? seasonalDates;

  /// `none|level|tires|number`
  final String measureType;

  /// `{"levels":[...]}` | `{"unit":"mm","label":"..."}`
  final String? measureJson;
  final String why;
  final String howJson;
  final String? warn;

  /// Denetim maddesi 14 / K-18 çevresi: seed'in `sourceNote` alanı burada saklanır.
  final String? sourceNote;

  /// `true|partial|false` (seed `verified`).
  final String verified;
  final bool startsFromInstall;
  final bool appliesLastService;
  final bool enabled;
  final int sortOrder;

  /// `yyyy-MM-dd`
  final String? lastDoneDay;
  final int? lastDoneKm;
  final String? lastValue;

  /// `yyyy-MM-dd`
  final String? snoozeUntilDay;
  const CheckItemRow({
    required this.id,
    required this.vehicleId,
    this.templateKey,
    required this.name,
    required this.groupKey,
    required this.scheduleKind,
    this.intervalDays,
    this.intervalKm,
    this.seasonalDates,
    required this.measureType,
    this.measureJson,
    required this.why,
    required this.howJson,
    this.warn,
    this.sourceNote,
    required this.verified,
    required this.startsFromInstall,
    required this.appliesLastService,
    required this.enabled,
    required this.sortOrder,
    this.lastDoneDay,
    this.lastDoneKm,
    this.lastValue,
    this.snoozeUntilDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['vehicle_id'] = Variable<int>(vehicleId);
    if (!nullToAbsent || templateKey != null) {
      map['template_key'] = Variable<String>(templateKey);
    }
    map['name'] = Variable<String>(name);
    map['group_key'] = Variable<String>(groupKey);
    map['schedule_kind'] = Variable<String>(scheduleKind);
    if (!nullToAbsent || intervalDays != null) {
      map['interval_days'] = Variable<int>(intervalDays);
    }
    if (!nullToAbsent || intervalKm != null) {
      map['interval_km'] = Variable<int>(intervalKm);
    }
    if (!nullToAbsent || seasonalDates != null) {
      map['seasonal_dates'] = Variable<String>(seasonalDates);
    }
    map['measure_type'] = Variable<String>(measureType);
    if (!nullToAbsent || measureJson != null) {
      map['measure_json'] = Variable<String>(measureJson);
    }
    map['why'] = Variable<String>(why);
    map['how_json'] = Variable<String>(howJson);
    if (!nullToAbsent || warn != null) {
      map['warn'] = Variable<String>(warn);
    }
    if (!nullToAbsent || sourceNote != null) {
      map['source_note'] = Variable<String>(sourceNote);
    }
    map['verified'] = Variable<String>(verified);
    map['starts_from_install'] = Variable<bool>(startsFromInstall);
    map['applies_last_service'] = Variable<bool>(appliesLastService);
    map['enabled'] = Variable<bool>(enabled);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || lastDoneDay != null) {
      map['last_done_day'] = Variable<String>(lastDoneDay);
    }
    if (!nullToAbsent || lastDoneKm != null) {
      map['last_done_km'] = Variable<int>(lastDoneKm);
    }
    if (!nullToAbsent || lastValue != null) {
      map['last_value'] = Variable<String>(lastValue);
    }
    if (!nullToAbsent || snoozeUntilDay != null) {
      map['snooze_until_day'] = Variable<String>(snoozeUntilDay);
    }
    return map;
  }

  CheckItemsCompanion toCompanion(bool nullToAbsent) {
    return CheckItemsCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      templateKey: templateKey == null && nullToAbsent
          ? const Value.absent()
          : Value(templateKey),
      name: Value(name),
      groupKey: Value(groupKey),
      scheduleKind: Value(scheduleKind),
      intervalDays: intervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDays),
      intervalKm: intervalKm == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalKm),
      seasonalDates: seasonalDates == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonalDates),
      measureType: Value(measureType),
      measureJson: measureJson == null && nullToAbsent
          ? const Value.absent()
          : Value(measureJson),
      why: Value(why),
      howJson: Value(howJson),
      warn: warn == null && nullToAbsent ? const Value.absent() : Value(warn),
      sourceNote: sourceNote == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceNote),
      verified: Value(verified),
      startsFromInstall: Value(startsFromInstall),
      appliesLastService: Value(appliesLastService),
      enabled: Value(enabled),
      sortOrder: Value(sortOrder),
      lastDoneDay: lastDoneDay == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDoneDay),
      lastDoneKm: lastDoneKm == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDoneKm),
      lastValue: lastValue == null && nullToAbsent
          ? const Value.absent()
          : Value(lastValue),
      snoozeUntilDay: snoozeUntilDay == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozeUntilDay),
    );
  }

  factory CheckItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckItemRow(
      id: serializer.fromJson<int>(json['id']),
      vehicleId: serializer.fromJson<int>(json['vehicleId']),
      templateKey: serializer.fromJson<String?>(json['templateKey']),
      name: serializer.fromJson<String>(json['name']),
      groupKey: serializer.fromJson<String>(json['groupKey']),
      scheduleKind: serializer.fromJson<String>(json['scheduleKind']),
      intervalDays: serializer.fromJson<int?>(json['intervalDays']),
      intervalKm: serializer.fromJson<int?>(json['intervalKm']),
      seasonalDates: serializer.fromJson<String?>(json['seasonalDates']),
      measureType: serializer.fromJson<String>(json['measureType']),
      measureJson: serializer.fromJson<String?>(json['measureJson']),
      why: serializer.fromJson<String>(json['why']),
      howJson: serializer.fromJson<String>(json['howJson']),
      warn: serializer.fromJson<String?>(json['warn']),
      sourceNote: serializer.fromJson<String?>(json['sourceNote']),
      verified: serializer.fromJson<String>(json['verified']),
      startsFromInstall: serializer.fromJson<bool>(json['startsFromInstall']),
      appliesLastService: serializer.fromJson<bool>(json['appliesLastService']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      lastDoneDay: serializer.fromJson<String?>(json['lastDoneDay']),
      lastDoneKm: serializer.fromJson<int?>(json['lastDoneKm']),
      lastValue: serializer.fromJson<String?>(json['lastValue']),
      snoozeUntilDay: serializer.fromJson<String?>(json['snoozeUntilDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'vehicleId': serializer.toJson<int>(vehicleId),
      'templateKey': serializer.toJson<String?>(templateKey),
      'name': serializer.toJson<String>(name),
      'groupKey': serializer.toJson<String>(groupKey),
      'scheduleKind': serializer.toJson<String>(scheduleKind),
      'intervalDays': serializer.toJson<int?>(intervalDays),
      'intervalKm': serializer.toJson<int?>(intervalKm),
      'seasonalDates': serializer.toJson<String?>(seasonalDates),
      'measureType': serializer.toJson<String>(measureType),
      'measureJson': serializer.toJson<String?>(measureJson),
      'why': serializer.toJson<String>(why),
      'howJson': serializer.toJson<String>(howJson),
      'warn': serializer.toJson<String?>(warn),
      'sourceNote': serializer.toJson<String?>(sourceNote),
      'verified': serializer.toJson<String>(verified),
      'startsFromInstall': serializer.toJson<bool>(startsFromInstall),
      'appliesLastService': serializer.toJson<bool>(appliesLastService),
      'enabled': serializer.toJson<bool>(enabled),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'lastDoneDay': serializer.toJson<String?>(lastDoneDay),
      'lastDoneKm': serializer.toJson<int?>(lastDoneKm),
      'lastValue': serializer.toJson<String?>(lastValue),
      'snoozeUntilDay': serializer.toJson<String?>(snoozeUntilDay),
    };
  }

  CheckItemRow copyWith({
    int? id,
    int? vehicleId,
    Value<String?> templateKey = const Value.absent(),
    String? name,
    String? groupKey,
    String? scheduleKind,
    Value<int?> intervalDays = const Value.absent(),
    Value<int?> intervalKm = const Value.absent(),
    Value<String?> seasonalDates = const Value.absent(),
    String? measureType,
    Value<String?> measureJson = const Value.absent(),
    String? why,
    String? howJson,
    Value<String?> warn = const Value.absent(),
    Value<String?> sourceNote = const Value.absent(),
    String? verified,
    bool? startsFromInstall,
    bool? appliesLastService,
    bool? enabled,
    int? sortOrder,
    Value<String?> lastDoneDay = const Value.absent(),
    Value<int?> lastDoneKm = const Value.absent(),
    Value<String?> lastValue = const Value.absent(),
    Value<String?> snoozeUntilDay = const Value.absent(),
  }) => CheckItemRow(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    templateKey: templateKey.present ? templateKey.value : this.templateKey,
    name: name ?? this.name,
    groupKey: groupKey ?? this.groupKey,
    scheduleKind: scheduleKind ?? this.scheduleKind,
    intervalDays: intervalDays.present ? intervalDays.value : this.intervalDays,
    intervalKm: intervalKm.present ? intervalKm.value : this.intervalKm,
    seasonalDates: seasonalDates.present
        ? seasonalDates.value
        : this.seasonalDates,
    measureType: measureType ?? this.measureType,
    measureJson: measureJson.present ? measureJson.value : this.measureJson,
    why: why ?? this.why,
    howJson: howJson ?? this.howJson,
    warn: warn.present ? warn.value : this.warn,
    sourceNote: sourceNote.present ? sourceNote.value : this.sourceNote,
    verified: verified ?? this.verified,
    startsFromInstall: startsFromInstall ?? this.startsFromInstall,
    appliesLastService: appliesLastService ?? this.appliesLastService,
    enabled: enabled ?? this.enabled,
    sortOrder: sortOrder ?? this.sortOrder,
    lastDoneDay: lastDoneDay.present ? lastDoneDay.value : this.lastDoneDay,
    lastDoneKm: lastDoneKm.present ? lastDoneKm.value : this.lastDoneKm,
    lastValue: lastValue.present ? lastValue.value : this.lastValue,
    snoozeUntilDay: snoozeUntilDay.present
        ? snoozeUntilDay.value
        : this.snoozeUntilDay,
  );
  CheckItemRow copyWithCompanion(CheckItemsCompanion data) {
    return CheckItemRow(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      templateKey: data.templateKey.present
          ? data.templateKey.value
          : this.templateKey,
      name: data.name.present ? data.name.value : this.name,
      groupKey: data.groupKey.present ? data.groupKey.value : this.groupKey,
      scheduleKind: data.scheduleKind.present
          ? data.scheduleKind.value
          : this.scheduleKind,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      intervalKm: data.intervalKm.present
          ? data.intervalKm.value
          : this.intervalKm,
      seasonalDates: data.seasonalDates.present
          ? data.seasonalDates.value
          : this.seasonalDates,
      measureType: data.measureType.present
          ? data.measureType.value
          : this.measureType,
      measureJson: data.measureJson.present
          ? data.measureJson.value
          : this.measureJson,
      why: data.why.present ? data.why.value : this.why,
      howJson: data.howJson.present ? data.howJson.value : this.howJson,
      warn: data.warn.present ? data.warn.value : this.warn,
      sourceNote: data.sourceNote.present
          ? data.sourceNote.value
          : this.sourceNote,
      verified: data.verified.present ? data.verified.value : this.verified,
      startsFromInstall: data.startsFromInstall.present
          ? data.startsFromInstall.value
          : this.startsFromInstall,
      appliesLastService: data.appliesLastService.present
          ? data.appliesLastService.value
          : this.appliesLastService,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      lastDoneDay: data.lastDoneDay.present
          ? data.lastDoneDay.value
          : this.lastDoneDay,
      lastDoneKm: data.lastDoneKm.present
          ? data.lastDoneKm.value
          : this.lastDoneKm,
      lastValue: data.lastValue.present ? data.lastValue.value : this.lastValue,
      snoozeUntilDay: data.snoozeUntilDay.present
          ? data.snoozeUntilDay.value
          : this.snoozeUntilDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckItemRow(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('templateKey: $templateKey, ')
          ..write('name: $name, ')
          ..write('groupKey: $groupKey, ')
          ..write('scheduleKind: $scheduleKind, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('intervalKm: $intervalKm, ')
          ..write('seasonalDates: $seasonalDates, ')
          ..write('measureType: $measureType, ')
          ..write('measureJson: $measureJson, ')
          ..write('why: $why, ')
          ..write('howJson: $howJson, ')
          ..write('warn: $warn, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('verified: $verified, ')
          ..write('startsFromInstall: $startsFromInstall, ')
          ..write('appliesLastService: $appliesLastService, ')
          ..write('enabled: $enabled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastDoneDay: $lastDoneDay, ')
          ..write('lastDoneKm: $lastDoneKm, ')
          ..write('lastValue: $lastValue, ')
          ..write('snoozeUntilDay: $snoozeUntilDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    vehicleId,
    templateKey,
    name,
    groupKey,
    scheduleKind,
    intervalDays,
    intervalKm,
    seasonalDates,
    measureType,
    measureJson,
    why,
    howJson,
    warn,
    sourceNote,
    verified,
    startsFromInstall,
    appliesLastService,
    enabled,
    sortOrder,
    lastDoneDay,
    lastDoneKm,
    lastValue,
    snoozeUntilDay,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckItemRow &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.templateKey == this.templateKey &&
          other.name == this.name &&
          other.groupKey == this.groupKey &&
          other.scheduleKind == this.scheduleKind &&
          other.intervalDays == this.intervalDays &&
          other.intervalKm == this.intervalKm &&
          other.seasonalDates == this.seasonalDates &&
          other.measureType == this.measureType &&
          other.measureJson == this.measureJson &&
          other.why == this.why &&
          other.howJson == this.howJson &&
          other.warn == this.warn &&
          other.sourceNote == this.sourceNote &&
          other.verified == this.verified &&
          other.startsFromInstall == this.startsFromInstall &&
          other.appliesLastService == this.appliesLastService &&
          other.enabled == this.enabled &&
          other.sortOrder == this.sortOrder &&
          other.lastDoneDay == this.lastDoneDay &&
          other.lastDoneKm == this.lastDoneKm &&
          other.lastValue == this.lastValue &&
          other.snoozeUntilDay == this.snoozeUntilDay);
}

class CheckItemsCompanion extends UpdateCompanion<CheckItemRow> {
  final Value<int> id;
  final Value<int> vehicleId;
  final Value<String?> templateKey;
  final Value<String> name;
  final Value<String> groupKey;
  final Value<String> scheduleKind;
  final Value<int?> intervalDays;
  final Value<int?> intervalKm;
  final Value<String?> seasonalDates;
  final Value<String> measureType;
  final Value<String?> measureJson;
  final Value<String> why;
  final Value<String> howJson;
  final Value<String?> warn;
  final Value<String?> sourceNote;
  final Value<String> verified;
  final Value<bool> startsFromInstall;
  final Value<bool> appliesLastService;
  final Value<bool> enabled;
  final Value<int> sortOrder;
  final Value<String?> lastDoneDay;
  final Value<int?> lastDoneKm;
  final Value<String?> lastValue;
  final Value<String?> snoozeUntilDay;
  const CheckItemsCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.templateKey = const Value.absent(),
    this.name = const Value.absent(),
    this.groupKey = const Value.absent(),
    this.scheduleKind = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.intervalKm = const Value.absent(),
    this.seasonalDates = const Value.absent(),
    this.measureType = const Value.absent(),
    this.measureJson = const Value.absent(),
    this.why = const Value.absent(),
    this.howJson = const Value.absent(),
    this.warn = const Value.absent(),
    this.sourceNote = const Value.absent(),
    this.verified = const Value.absent(),
    this.startsFromInstall = const Value.absent(),
    this.appliesLastService = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastDoneDay = const Value.absent(),
    this.lastDoneKm = const Value.absent(),
    this.lastValue = const Value.absent(),
    this.snoozeUntilDay = const Value.absent(),
  });
  CheckItemsCompanion.insert({
    this.id = const Value.absent(),
    required int vehicleId,
    this.templateKey = const Value.absent(),
    required String name,
    required String groupKey,
    required String scheduleKind,
    this.intervalDays = const Value.absent(),
    this.intervalKm = const Value.absent(),
    this.seasonalDates = const Value.absent(),
    required String measureType,
    this.measureJson = const Value.absent(),
    this.why = const Value.absent(),
    this.howJson = const Value.absent(),
    this.warn = const Value.absent(),
    this.sourceNote = const Value.absent(),
    this.verified = const Value.absent(),
    this.startsFromInstall = const Value.absent(),
    this.appliesLastService = const Value.absent(),
    this.enabled = const Value.absent(),
    required int sortOrder,
    this.lastDoneDay = const Value.absent(),
    this.lastDoneKm = const Value.absent(),
    this.lastValue = const Value.absent(),
    this.snoozeUntilDay = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       name = Value(name),
       groupKey = Value(groupKey),
       scheduleKind = Value(scheduleKind),
       measureType = Value(measureType),
       sortOrder = Value(sortOrder);
  static Insertable<CheckItemRow> custom({
    Expression<int>? id,
    Expression<int>? vehicleId,
    Expression<String>? templateKey,
    Expression<String>? name,
    Expression<String>? groupKey,
    Expression<String>? scheduleKind,
    Expression<int>? intervalDays,
    Expression<int>? intervalKm,
    Expression<String>? seasonalDates,
    Expression<String>? measureType,
    Expression<String>? measureJson,
    Expression<String>? why,
    Expression<String>? howJson,
    Expression<String>? warn,
    Expression<String>? sourceNote,
    Expression<String>? verified,
    Expression<bool>? startsFromInstall,
    Expression<bool>? appliesLastService,
    Expression<bool>? enabled,
    Expression<int>? sortOrder,
    Expression<String>? lastDoneDay,
    Expression<int>? lastDoneKm,
    Expression<String>? lastValue,
    Expression<String>? snoozeUntilDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (templateKey != null) 'template_key': templateKey,
      if (name != null) 'name': name,
      if (groupKey != null) 'group_key': groupKey,
      if (scheduleKind != null) 'schedule_kind': scheduleKind,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (intervalKm != null) 'interval_km': intervalKm,
      if (seasonalDates != null) 'seasonal_dates': seasonalDates,
      if (measureType != null) 'measure_type': measureType,
      if (measureJson != null) 'measure_json': measureJson,
      if (why != null) 'why': why,
      if (howJson != null) 'how_json': howJson,
      if (warn != null) 'warn': warn,
      if (sourceNote != null) 'source_note': sourceNote,
      if (verified != null) 'verified': verified,
      if (startsFromInstall != null) 'starts_from_install': startsFromInstall,
      if (appliesLastService != null)
        'applies_last_service': appliesLastService,
      if (enabled != null) 'enabled': enabled,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (lastDoneDay != null) 'last_done_day': lastDoneDay,
      if (lastDoneKm != null) 'last_done_km': lastDoneKm,
      if (lastValue != null) 'last_value': lastValue,
      if (snoozeUntilDay != null) 'snooze_until_day': snoozeUntilDay,
    });
  }

  CheckItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? vehicleId,
    Value<String?>? templateKey,
    Value<String>? name,
    Value<String>? groupKey,
    Value<String>? scheduleKind,
    Value<int?>? intervalDays,
    Value<int?>? intervalKm,
    Value<String?>? seasonalDates,
    Value<String>? measureType,
    Value<String?>? measureJson,
    Value<String>? why,
    Value<String>? howJson,
    Value<String?>? warn,
    Value<String?>? sourceNote,
    Value<String>? verified,
    Value<bool>? startsFromInstall,
    Value<bool>? appliesLastService,
    Value<bool>? enabled,
    Value<int>? sortOrder,
    Value<String?>? lastDoneDay,
    Value<int?>? lastDoneKm,
    Value<String?>? lastValue,
    Value<String?>? snoozeUntilDay,
  }) {
    return CheckItemsCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      templateKey: templateKey ?? this.templateKey,
      name: name ?? this.name,
      groupKey: groupKey ?? this.groupKey,
      scheduleKind: scheduleKind ?? this.scheduleKind,
      intervalDays: intervalDays ?? this.intervalDays,
      intervalKm: intervalKm ?? this.intervalKm,
      seasonalDates: seasonalDates ?? this.seasonalDates,
      measureType: measureType ?? this.measureType,
      measureJson: measureJson ?? this.measureJson,
      why: why ?? this.why,
      howJson: howJson ?? this.howJson,
      warn: warn ?? this.warn,
      sourceNote: sourceNote ?? this.sourceNote,
      verified: verified ?? this.verified,
      startsFromInstall: startsFromInstall ?? this.startsFromInstall,
      appliesLastService: appliesLastService ?? this.appliesLastService,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
      lastDoneDay: lastDoneDay ?? this.lastDoneDay,
      lastDoneKm: lastDoneKm ?? this.lastDoneKm,
      lastValue: lastValue ?? this.lastValue,
      snoozeUntilDay: snoozeUntilDay ?? this.snoozeUntilDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<int>(vehicleId.value);
    }
    if (templateKey.present) {
      map['template_key'] = Variable<String>(templateKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (groupKey.present) {
      map['group_key'] = Variable<String>(groupKey.value);
    }
    if (scheduleKind.present) {
      map['schedule_kind'] = Variable<String>(scheduleKind.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (intervalKm.present) {
      map['interval_km'] = Variable<int>(intervalKm.value);
    }
    if (seasonalDates.present) {
      map['seasonal_dates'] = Variable<String>(seasonalDates.value);
    }
    if (measureType.present) {
      map['measure_type'] = Variable<String>(measureType.value);
    }
    if (measureJson.present) {
      map['measure_json'] = Variable<String>(measureJson.value);
    }
    if (why.present) {
      map['why'] = Variable<String>(why.value);
    }
    if (howJson.present) {
      map['how_json'] = Variable<String>(howJson.value);
    }
    if (warn.present) {
      map['warn'] = Variable<String>(warn.value);
    }
    if (sourceNote.present) {
      map['source_note'] = Variable<String>(sourceNote.value);
    }
    if (verified.present) {
      map['verified'] = Variable<String>(verified.value);
    }
    if (startsFromInstall.present) {
      map['starts_from_install'] = Variable<bool>(startsFromInstall.value);
    }
    if (appliesLastService.present) {
      map['applies_last_service'] = Variable<bool>(appliesLastService.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (lastDoneDay.present) {
      map['last_done_day'] = Variable<String>(lastDoneDay.value);
    }
    if (lastDoneKm.present) {
      map['last_done_km'] = Variable<int>(lastDoneKm.value);
    }
    if (lastValue.present) {
      map['last_value'] = Variable<String>(lastValue.value);
    }
    if (snoozeUntilDay.present) {
      map['snooze_until_day'] = Variable<String>(snoozeUntilDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckItemsCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('templateKey: $templateKey, ')
          ..write('name: $name, ')
          ..write('groupKey: $groupKey, ')
          ..write('scheduleKind: $scheduleKind, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('intervalKm: $intervalKm, ')
          ..write('seasonalDates: $seasonalDates, ')
          ..write('measureType: $measureType, ')
          ..write('measureJson: $measureJson, ')
          ..write('why: $why, ')
          ..write('howJson: $howJson, ')
          ..write('warn: $warn, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('verified: $verified, ')
          ..write('startsFromInstall: $startsFromInstall, ')
          ..write('appliesLastService: $appliesLastService, ')
          ..write('enabled: $enabled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastDoneDay: $lastDoneDay, ')
          ..write('lastDoneKm: $lastDoneKm, ')
          ..write('lastValue: $lastValue, ')
          ..write('snoozeUntilDay: $snoozeUntilDay')
          ..write(')'))
        .toString();
  }
}

class $CheckLogsTable extends CheckLogs
    with TableInfo<$CheckLogsTable, CheckLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES check_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _doneAtMeta = const VerificationMeta('doneAt');
  @override
  late final GeneratedColumn<DateTime> doneAt = GeneratedColumn<DateTime>(
    'done_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneDayMeta = const VerificationMeta(
    'doneDay',
  );
  @override
  late final GeneratedColumn<String> doneDay = GeneratedColumn<String>(
    'done_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kmMeta = const VerificationMeta('km');
  @override
  late final GeneratedColumn<int> km = GeneratedColumn<int>(
    'km',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('done'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    doneAt,
    doneDay,
    km,
    value,
    note,
    kind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('done_at')) {
      context.handle(
        _doneAtMeta,
        doneAt.isAcceptableOrUnknown(data['done_at']!, _doneAtMeta),
      );
    } else if (isInserting) {
      context.missing(_doneAtMeta);
    }
    if (data.containsKey('done_day')) {
      context.handle(
        _doneDayMeta,
        doneDay.isAcceptableOrUnknown(data['done_day']!, _doneDayMeta),
      );
    } else if (isInserting) {
      context.missing(_doneDayMeta);
    }
    if (data.containsKey('km')) {
      context.handle(_kmMeta, km.isAcceptableOrUnknown(data['km']!, _kmMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheckLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      doneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}done_at'],
      )!,
      doneDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}done_day'],
      )!,
      km: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}km'],
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  $CheckLogsTable createAlias(String alias) {
    return $CheckLogsTable(attachedDatabase, alias);
  }
}

class CheckLogRow extends DataClass implements Insertable<CheckLogRow> {
  final int id;
  final int itemId;
  final DateTime doneAt;

  /// `yyyy-MM-dd`
  final String doneDay;

  /// K-23: gün bazlı bir maddenin düzeltmesinde km bilinmez, uydurulmaz.
  final int? km;
  final String? value;
  final String? note;

  /// K-23: `done` = "Yaptım", `fix` = "Tarih/km düzelt".
  final String kind;
  const CheckLogRow({
    required this.id,
    required this.itemId,
    required this.doneAt,
    required this.doneDay,
    this.km,
    this.value,
    this.note,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['done_at'] = Variable<DateTime>(doneAt);
    map['done_day'] = Variable<String>(doneDay);
    if (!nullToAbsent || km != null) {
      map['km'] = Variable<int>(km);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['kind'] = Variable<String>(kind);
    return map;
  }

  CheckLogsCompanion toCompanion(bool nullToAbsent) {
    return CheckLogsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      doneAt: Value(doneAt),
      doneDay: Value(doneDay),
      km: km == null && nullToAbsent ? const Value.absent() : Value(km),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      kind: Value(kind),
    );
  }

  factory CheckLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckLogRow(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      doneAt: serializer.fromJson<DateTime>(json['doneAt']),
      doneDay: serializer.fromJson<String>(json['doneDay']),
      km: serializer.fromJson<int?>(json['km']),
      value: serializer.fromJson<String?>(json['value']),
      note: serializer.fromJson<String?>(json['note']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'doneAt': serializer.toJson<DateTime>(doneAt),
      'doneDay': serializer.toJson<String>(doneDay),
      'km': serializer.toJson<int?>(km),
      'value': serializer.toJson<String?>(value),
      'note': serializer.toJson<String?>(note),
      'kind': serializer.toJson<String>(kind),
    };
  }

  CheckLogRow copyWith({
    int? id,
    int? itemId,
    DateTime? doneAt,
    String? doneDay,
    Value<int?> km = const Value.absent(),
    Value<String?> value = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? kind,
  }) => CheckLogRow(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    doneAt: doneAt ?? this.doneAt,
    doneDay: doneDay ?? this.doneDay,
    km: km.present ? km.value : this.km,
    value: value.present ? value.value : this.value,
    note: note.present ? note.value : this.note,
    kind: kind ?? this.kind,
  );
  CheckLogRow copyWithCompanion(CheckLogsCompanion data) {
    return CheckLogRow(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
      doneDay: data.doneDay.present ? data.doneDay.value : this.doneDay,
      km: data.km.present ? data.km.value : this.km,
      value: data.value.present ? data.value.value : this.value,
      note: data.note.present ? data.note.value : this.note,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckLogRow(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('doneAt: $doneAt, ')
          ..write('doneDay: $doneDay, ')
          ..write('km: $km, ')
          ..write('value: $value, ')
          ..write('note: $note, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, itemId, doneAt, doneDay, km, value, note, kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckLogRow &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.doneAt == this.doneAt &&
          other.doneDay == this.doneDay &&
          other.km == this.km &&
          other.value == this.value &&
          other.note == this.note &&
          other.kind == this.kind);
}

class CheckLogsCompanion extends UpdateCompanion<CheckLogRow> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<DateTime> doneAt;
  final Value<String> doneDay;
  final Value<int?> km;
  final Value<String?> value;
  final Value<String?> note;
  final Value<String> kind;
  const CheckLogsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.doneDay = const Value.absent(),
    this.km = const Value.absent(),
    this.value = const Value.absent(),
    this.note = const Value.absent(),
    this.kind = const Value.absent(),
  });
  CheckLogsCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required DateTime doneAt,
    required String doneDay,
    this.km = const Value.absent(),
    this.value = const Value.absent(),
    this.note = const Value.absent(),
    this.kind = const Value.absent(),
  }) : itemId = Value(itemId),
       doneAt = Value(doneAt),
       doneDay = Value(doneDay);
  static Insertable<CheckLogRow> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<DateTime>? doneAt,
    Expression<String>? doneDay,
    Expression<int>? km,
    Expression<String>? value,
    Expression<String>? note,
    Expression<String>? kind,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (doneAt != null) 'done_at': doneAt,
      if (doneDay != null) 'done_day': doneDay,
      if (km != null) 'km': km,
      if (value != null) 'value': value,
      if (note != null) 'note': note,
      if (kind != null) 'kind': kind,
    });
  }

  CheckLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<DateTime>? doneAt,
    Value<String>? doneDay,
    Value<int?>? km,
    Value<String?>? value,
    Value<String?>? note,
    Value<String>? kind,
  }) {
    return CheckLogsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      doneAt: doneAt ?? this.doneAt,
      doneDay: doneDay ?? this.doneDay,
      km: km ?? this.km,
      value: value ?? this.value,
      note: note ?? this.note,
      kind: kind ?? this.kind,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<DateTime>(doneAt.value);
    }
    if (doneDay.present) {
      map['done_day'] = Variable<String>(doneDay.value);
    }
    if (km.present) {
      map['km'] = Variable<int>(km.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckLogsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('doneAt: $doneAt, ')
          ..write('doneDay: $doneDay, ')
          ..write('km: $km, ')
          ..write('value: $value, ')
          ..write('note: $note, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }
}

class $TripsTable extends Trips with TableInfo<$TripsTable, TripRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _connectedAtMeta = const VerificationMeta(
    'connectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> connectedAt = GeneratedColumn<DateTime>(
    'connected_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _disconnectedAtMeta = const VerificationMeta(
    'disconnectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> disconnectedAt =
      GeneratedColumn<DateTime>(
        'disconnected_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countedMeta = const VerificationMeta(
    'counted',
  );
  @override
  late final GeneratedColumn<bool> counted = GeneratedColumn<bool>(
    'counted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("counted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _notifiedMeta = const VerificationMeta(
    'notified',
  );
  @override
  late final GeneratedColumn<bool> notified = GeneratedColumn<bool>(
    'notified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notified" IN (0, 1))',
    ),
  );
  static const VerificationMeta _overdueCountMeta = const VerificationMeta(
    'overdueCount',
  );
  @override
  late final GeneratedColumn<int> overdueCount = GeneratedColumn<int>(
    'overdue_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant<int>(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    connectedAt,
    disconnectedAt,
    durationMin,
    counted,
    notified,
    overdueCount,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<TripRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('connected_at')) {
      context.handle(
        _connectedAtMeta,
        connectedAt.isAcceptableOrUnknown(
          data['connected_at']!,
          _connectedAtMeta,
        ),
      );
    }
    if (data.containsKey('disconnected_at')) {
      context.handle(
        _disconnectedAtMeta,
        disconnectedAt.isAcceptableOrUnknown(
          data['disconnected_at']!,
          _disconnectedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disconnectedAtMeta);
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinMeta);
    }
    if (data.containsKey('counted')) {
      context.handle(
        _countedMeta,
        counted.isAcceptableOrUnknown(data['counted']!, _countedMeta),
      );
    } else if (isInserting) {
      context.missing(_countedMeta);
    }
    if (data.containsKey('notified')) {
      context.handle(
        _notifiedMeta,
        notified.isAcceptableOrUnknown(data['notified']!, _notifiedMeta),
      );
    } else if (isInserting) {
      context.missing(_notifiedMeta);
    }
    if (data.containsKey('overdue_count')) {
      context.handle(
        _overdueCountMeta,
        overdueCount.isAcceptableOrUnknown(
          data['overdue_count']!,
          _overdueCountMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TripRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      connectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}connected_at'],
      ),
      disconnectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}disconnected_at'],
      )!,
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      )!,
      counted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}counted'],
      )!,
      notified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notified'],
      )!,
      overdueCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overdue_count'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class TripRow extends DataClass implements Insertable<TripRow> {
  final int id;
  final DateTime? connectedAt;
  final DateTime disconnectedAt;
  final int durationMin;
  final bool counted;
  final bool notified;
  final int overdueCount;

  /// `short_trip|no_snapshot|no_overdue|once_per_day|snoozed|reconnect|fallback|ok`
  final String? note;
  const TripRow({
    required this.id,
    this.connectedAt,
    required this.disconnectedAt,
    required this.durationMin,
    required this.counted,
    required this.notified,
    required this.overdueCount,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || connectedAt != null) {
      map['connected_at'] = Variable<DateTime>(connectedAt);
    }
    map['disconnected_at'] = Variable<DateTime>(disconnectedAt);
    map['duration_min'] = Variable<int>(durationMin);
    map['counted'] = Variable<bool>(counted);
    map['notified'] = Variable<bool>(notified);
    map['overdue_count'] = Variable<int>(overdueCount);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      connectedAt: connectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(connectedAt),
      disconnectedAt: Value(disconnectedAt),
      durationMin: Value(durationMin),
      counted: Value(counted),
      notified: Value(notified),
      overdueCount: Value(overdueCount),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory TripRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripRow(
      id: serializer.fromJson<int>(json['id']),
      connectedAt: serializer.fromJson<DateTime?>(json['connectedAt']),
      disconnectedAt: serializer.fromJson<DateTime>(json['disconnectedAt']),
      durationMin: serializer.fromJson<int>(json['durationMin']),
      counted: serializer.fromJson<bool>(json['counted']),
      notified: serializer.fromJson<bool>(json['notified']),
      overdueCount: serializer.fromJson<int>(json['overdueCount']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'connectedAt': serializer.toJson<DateTime?>(connectedAt),
      'disconnectedAt': serializer.toJson<DateTime>(disconnectedAt),
      'durationMin': serializer.toJson<int>(durationMin),
      'counted': serializer.toJson<bool>(counted),
      'notified': serializer.toJson<bool>(notified),
      'overdueCount': serializer.toJson<int>(overdueCount),
      'note': serializer.toJson<String?>(note),
    };
  }

  TripRow copyWith({
    int? id,
    Value<DateTime?> connectedAt = const Value.absent(),
    DateTime? disconnectedAt,
    int? durationMin,
    bool? counted,
    bool? notified,
    int? overdueCount,
    Value<String?> note = const Value.absent(),
  }) => TripRow(
    id: id ?? this.id,
    connectedAt: connectedAt.present ? connectedAt.value : this.connectedAt,
    disconnectedAt: disconnectedAt ?? this.disconnectedAt,
    durationMin: durationMin ?? this.durationMin,
    counted: counted ?? this.counted,
    notified: notified ?? this.notified,
    overdueCount: overdueCount ?? this.overdueCount,
    note: note.present ? note.value : this.note,
  );
  TripRow copyWithCompanion(TripsCompanion data) {
    return TripRow(
      id: data.id.present ? data.id.value : this.id,
      connectedAt: data.connectedAt.present
          ? data.connectedAt.value
          : this.connectedAt,
      disconnectedAt: data.disconnectedAt.present
          ? data.disconnectedAt.value
          : this.disconnectedAt,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      counted: data.counted.present ? data.counted.value : this.counted,
      notified: data.notified.present ? data.notified.value : this.notified,
      overdueCount: data.overdueCount.present
          ? data.overdueCount.value
          : this.overdueCount,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripRow(')
          ..write('id: $id, ')
          ..write('connectedAt: $connectedAt, ')
          ..write('disconnectedAt: $disconnectedAt, ')
          ..write('durationMin: $durationMin, ')
          ..write('counted: $counted, ')
          ..write('notified: $notified, ')
          ..write('overdueCount: $overdueCount, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    connectedAt,
    disconnectedAt,
    durationMin,
    counted,
    notified,
    overdueCount,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripRow &&
          other.id == this.id &&
          other.connectedAt == this.connectedAt &&
          other.disconnectedAt == this.disconnectedAt &&
          other.durationMin == this.durationMin &&
          other.counted == this.counted &&
          other.notified == this.notified &&
          other.overdueCount == this.overdueCount &&
          other.note == this.note);
}

class TripsCompanion extends UpdateCompanion<TripRow> {
  final Value<int> id;
  final Value<DateTime?> connectedAt;
  final Value<DateTime> disconnectedAt;
  final Value<int> durationMin;
  final Value<bool> counted;
  final Value<bool> notified;
  final Value<int> overdueCount;
  final Value<String?> note;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.connectedAt = const Value.absent(),
    this.disconnectedAt = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.counted = const Value.absent(),
    this.notified = const Value.absent(),
    this.overdueCount = const Value.absent(),
    this.note = const Value.absent(),
  });
  TripsCompanion.insert({
    this.id = const Value.absent(),
    this.connectedAt = const Value.absent(),
    required DateTime disconnectedAt,
    required int durationMin,
    required bool counted,
    required bool notified,
    this.overdueCount = const Value.absent(),
    this.note = const Value.absent(),
  }) : disconnectedAt = Value(disconnectedAt),
       durationMin = Value(durationMin),
       counted = Value(counted),
       notified = Value(notified);
  static Insertable<TripRow> custom({
    Expression<int>? id,
    Expression<DateTime>? connectedAt,
    Expression<DateTime>? disconnectedAt,
    Expression<int>? durationMin,
    Expression<bool>? counted,
    Expression<bool>? notified,
    Expression<int>? overdueCount,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (connectedAt != null) 'connected_at': connectedAt,
      if (disconnectedAt != null) 'disconnected_at': disconnectedAt,
      if (durationMin != null) 'duration_min': durationMin,
      if (counted != null) 'counted': counted,
      if (notified != null) 'notified': notified,
      if (overdueCount != null) 'overdue_count': overdueCount,
      if (note != null) 'note': note,
    });
  }

  TripsCompanion copyWith({
    Value<int>? id,
    Value<DateTime?>? connectedAt,
    Value<DateTime>? disconnectedAt,
    Value<int>? durationMin,
    Value<bool>? counted,
    Value<bool>? notified,
    Value<int>? overdueCount,
    Value<String?>? note,
  }) {
    return TripsCompanion(
      id: id ?? this.id,
      connectedAt: connectedAt ?? this.connectedAt,
      disconnectedAt: disconnectedAt ?? this.disconnectedAt,
      durationMin: durationMin ?? this.durationMin,
      counted: counted ?? this.counted,
      notified: notified ?? this.notified,
      overdueCount: overdueCount ?? this.overdueCount,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (connectedAt.present) {
      map['connected_at'] = Variable<DateTime>(connectedAt.value);
    }
    if (disconnectedAt.present) {
      map['disconnected_at'] = Variable<DateTime>(disconnectedAt.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (counted.present) {
      map['counted'] = Variable<bool>(counted.value);
    }
    if (notified.present) {
      map['notified'] = Variable<bool>(notified.value);
    }
    if (overdueCount.present) {
      map['overdue_count'] = Variable<int>(overdueCount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('connectedAt: $connectedAt, ')
          ..write('disconnectedAt: $disconnectedAt, ')
          ..write('durationMin: $durationMin, ')
          ..write('counted: $counted, ')
          ..write('notified: $notified, ')
          ..write('overdueCount: $overdueCount, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
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
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
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
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
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

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
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
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
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

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
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
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VehiclesTable vehicles = $VehiclesTable(this);
  late final $CheckItemsTable checkItems = $CheckItemsTable(this);
  late final $CheckLogsTable checkLogs = $CheckLogsTable(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final VehicleDao vehicleDao = VehicleDao(this as AppDatabase);
  late final ItemDao itemDao = ItemDao(this as AppDatabase);
  late final LogDao logDao = LogDao(this as AppDatabase);
  late final TripDao tripDao = TripDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vehicles,
    checkItems,
    checkLogs,
    trips,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vehicles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('check_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'check_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('check_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$VehiclesTableCreateCompanionBuilder = VehiclesCompanion Function({
  Value<int> id,
  required String brand,
  Value<String> model,
  Value<String> year,
  required int currentKm,
  Value<String?> btAddress,
  Value<String?> btName,
  Value<double?> tireFrontBar,
  Value<double?> tireRearBar,
  required DateTime createdAt,
});
typedef $$VehiclesTableUpdateCompanionBuilder = VehiclesCompanion Function({
  Value<int> id,
  Value<String> brand,
  Value<String> model,
  Value<String> year,
  Value<int> currentKm,
  Value<String?> btAddress,
  Value<String?> btName,
  Value<double?> tireFrontBar,
  Value<double?> tireRearBar,
  Value<DateTime> createdAt,
});

final class $$VehiclesTableReferences
    extends BaseReferences<_$AppDatabase, $VehiclesTable, VehicleRow> {
  $$VehiclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CheckItemsTable, List<CheckItemRow>>
  _checkItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.checkItems,
    aliasName: 'vehicles__id__check_items__vehicle_id',
  );

  $$CheckItemsTableProcessedTableManager get checkItemsRefs {
    final manager = $$CheckItemsTableTableManager(
      $_db,
      $_db.checkItems,
    ).filter((f) => f.vehicleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_checkItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentKm => $composableBuilder(
    column: $table.currentKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get btAddress => $composableBuilder(
    column: $table.btAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get btName => $composableBuilder(
    column: $table.btName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tireFrontBar => $composableBuilder(
    column: $table.tireFrontBar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tireRearBar => $composableBuilder(
    column: $table.tireRearBar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> checkItemsRefs(
    Expression<bool> Function($$CheckItemsTableFilterComposer f) f,
  ) {
    final $$CheckItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkItems,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckItemsTableFilterComposer(
            $db: $db,
            $table: $db.checkItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentKm => $composableBuilder(
    column: $table.currentKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get btAddress => $composableBuilder(
    column: $table.btAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get btName => $composableBuilder(
    column: $table.btName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tireFrontBar => $composableBuilder(
    column: $table.tireFrontBar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tireRearBar => $composableBuilder(
    column: $table.tireRearBar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get currentKm =>
      $composableBuilder(column: $table.currentKm, builder: (column) => column);

  GeneratedColumn<String> get btAddress =>
      $composableBuilder(column: $table.btAddress, builder: (column) => column);

  GeneratedColumn<String> get btName =>
      $composableBuilder(column: $table.btName, builder: (column) => column);

  GeneratedColumn<double> get tireFrontBar => $composableBuilder(
    column: $table.tireFrontBar,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tireRearBar => $composableBuilder(
    column: $table.tireRearBar,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> checkItemsRefs<T extends Object>(
    Expression<T> Function($$CheckItemsTableAnnotationComposer a) f,
  ) {
    final $$CheckItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkItems,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.checkItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VehiclesTable,
          VehicleRow,
          $$VehiclesTableFilterComposer,
          $$VehiclesTableOrderingComposer,
          $$VehiclesTableAnnotationComposer,
          $$VehiclesTableCreateCompanionBuilder,
          $$VehiclesTableUpdateCompanionBuilder,
          (VehicleRow, $$VehiclesTableReferences),
          VehicleRow,
          PrefetchHooks Function({bool checkItemsRefs})
        > {
  $$VehiclesTableTableManager(_$AppDatabase db, $VehiclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> year = const Value.absent(),
                Value<int> currentKm = const Value.absent(),
                Value<String?> btAddress = const Value.absent(),
                Value<String?> btName = const Value.absent(),
                Value<double?> tireFrontBar = const Value.absent(),
                Value<double?> tireRearBar = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => VehiclesCompanion(
                id: id,
                brand: brand,
                model: model,
                year: year,
                currentKm: currentKm,
                btAddress: btAddress,
                btName: btName,
                tireFrontBar: tireFrontBar,
                tireRearBar: tireRearBar,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String brand,
                Value<String> model = const Value.absent(),
                Value<String> year = const Value.absent(),
                required int currentKm,
                Value<String?> btAddress = const Value.absent(),
                Value<String?> btName = const Value.absent(),
                Value<double?> tireFrontBar = const Value.absent(),
                Value<double?> tireRearBar = const Value.absent(),
                required DateTime createdAt,
              }) => VehiclesCompanion.insert(
                id: id,
                brand: brand,
                model: model,
                year: year,
                currentKm: currentKm,
                btAddress: btAddress,
                btName: btName,
                tireFrontBar: tireFrontBar,
                tireRearBar: tireRearBar,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VehiclesTable, VehicleRow>(table),
                  $$VehiclesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({checkItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (checkItemsRefs) db.checkItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (checkItemsRefs)
                    await $_getPrefetchedData<
                      VehicleRow,
                      $VehiclesTable,
                      CheckItemRow
                    >(
                      currentTable: table,
                      referencedTable: $$VehiclesTableReferences
                          ._checkItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$VehiclesTableReferences(
                        db,
                        table,
                        p0,
                      ).checkItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.vehicleId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$VehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VehiclesTable,
      VehicleRow,
      $$VehiclesTableFilterComposer,
      $$VehiclesTableOrderingComposer,
      $$VehiclesTableAnnotationComposer,
      $$VehiclesTableCreateCompanionBuilder,
      $$VehiclesTableUpdateCompanionBuilder,
      (VehicleRow, $$VehiclesTableReferences),
      VehicleRow,
      PrefetchHooks Function({bool checkItemsRefs})
    >;
typedef $$CheckItemsTableCreateCompanionBuilder = CheckItemsCompanion Function({
  Value<int> id,
  required int vehicleId,
  Value<String?> templateKey,
  required String name,
  required String groupKey,
  required String scheduleKind,
  Value<int?> intervalDays,
  Value<int?> intervalKm,
  Value<String?> seasonalDates,
  required String measureType,
  Value<String?> measureJson,
  Value<String> why,
  Value<String> howJson,
  Value<String?> warn,
  Value<String?> sourceNote,
  Value<String> verified,
  Value<bool> startsFromInstall,
  Value<bool> appliesLastService,
  Value<bool> enabled,
  required int sortOrder,
  Value<String?> lastDoneDay,
  Value<int?> lastDoneKm,
  Value<String?> lastValue,
  Value<String?> snoozeUntilDay,
});
typedef $$CheckItemsTableUpdateCompanionBuilder = CheckItemsCompanion Function({
  Value<int> id,
  Value<int> vehicleId,
  Value<String?> templateKey,
  Value<String> name,
  Value<String> groupKey,
  Value<String> scheduleKind,
  Value<int?> intervalDays,
  Value<int?> intervalKm,
  Value<String?> seasonalDates,
  Value<String> measureType,
  Value<String?> measureJson,
  Value<String> why,
  Value<String> howJson,
  Value<String?> warn,
  Value<String?> sourceNote,
  Value<String> verified,
  Value<bool> startsFromInstall,
  Value<bool> appliesLastService,
  Value<bool> enabled,
  Value<int> sortOrder,
  Value<String?> lastDoneDay,
  Value<int?> lastDoneKm,
  Value<String?> lastValue,
  Value<String?> snoozeUntilDay,
});

final class $$CheckItemsTableReferences
    extends BaseReferences<_$AppDatabase, $CheckItemsTable, CheckItemRow> {
  $$CheckItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VehiclesTable _vehicleIdTable(_$AppDatabase db) =>
      db.vehicles.createAlias('check_items__vehicle_id__vehicles__id');

  $$VehiclesTableProcessedTableManager get vehicleId {
    final $_column = $_itemColumn<int>('vehicle_id')!;

    final manager = $$VehiclesTableTableManager(
      $_db,
      $_db.vehicles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vehicleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CheckLogsTable, List<CheckLogRow>>
  _checkLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.checkLogs,
    aliasName: 'check_items__id__check_logs__item_id',
  );

  $$CheckLogsTableProcessedTableManager get checkLogsRefs {
    final manager = $$CheckLogsTableTableManager(
      $_db,
      $_db.checkLogs,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_checkLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CheckItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CheckItemsTable> {
  $$CheckItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateKey => $composableBuilder(
    column: $table.templateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduleKind => $composableBuilder(
    column: $table.scheduleKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalKm => $composableBuilder(
    column: $table.intervalKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seasonalDates => $composableBuilder(
    column: $table.seasonalDates,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measureType => $composableBuilder(
    column: $table.measureType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measureJson => $composableBuilder(
    column: $table.measureJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get howJson => $composableBuilder(
    column: $table.howJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warn => $composableBuilder(
    column: $table.warn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verified => $composableBuilder(
    column: $table.verified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get startsFromInstall => $composableBuilder(
    column: $table.startsFromInstall,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get appliesLastService => $composableBuilder(
    column: $table.appliesLastService,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastDoneDay => $composableBuilder(
    column: $table.lastDoneDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastDoneKm => $composableBuilder(
    column: $table.lastDoneKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastValue => $composableBuilder(
    column: $table.lastValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snoozeUntilDay => $composableBuilder(
    column: $table.snoozeUntilDay,
    builder: (column) => ColumnFilters(column),
  );

  $$VehiclesTableFilterComposer get vehicleId {
    final $$VehiclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableFilterComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> checkLogsRefs(
    Expression<bool> Function($$CheckLogsTableFilterComposer f) f,
  ) {
    final $$CheckLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkLogs,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckLogsTableFilterComposer(
            $db: $db,
            $table: $db.checkLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CheckItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CheckItemsTable> {
  $$CheckItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateKey => $composableBuilder(
    column: $table.templateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduleKind => $composableBuilder(
    column: $table.scheduleKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalKm => $composableBuilder(
    column: $table.intervalKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seasonalDates => $composableBuilder(
    column: $table.seasonalDates,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measureType => $composableBuilder(
    column: $table.measureType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measureJson => $composableBuilder(
    column: $table.measureJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get howJson => $composableBuilder(
    column: $table.howJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warn => $composableBuilder(
    column: $table.warn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verified => $composableBuilder(
    column: $table.verified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get startsFromInstall => $composableBuilder(
    column: $table.startsFromInstall,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get appliesLastService => $composableBuilder(
    column: $table.appliesLastService,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastDoneDay => $composableBuilder(
    column: $table.lastDoneDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastDoneKm => $composableBuilder(
    column: $table.lastDoneKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastValue => $composableBuilder(
    column: $table.lastValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snoozeUntilDay => $composableBuilder(
    column: $table.snoozeUntilDay,
    builder: (column) => ColumnOrderings(column),
  );

  $$VehiclesTableOrderingComposer get vehicleId {
    final $$VehiclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableOrderingComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheckItemsTable> {
  $$CheckItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateKey => $composableBuilder(
    column: $table.templateKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get groupKey =>
      $composableBuilder(column: $table.groupKey, builder: (column) => column);

  GeneratedColumn<String> get scheduleKind => $composableBuilder(
    column: $table.scheduleKind,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalKm => $composableBuilder(
    column: $table.intervalKm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seasonalDates => $composableBuilder(
    column: $table.seasonalDates,
    builder: (column) => column,
  );

  GeneratedColumn<String> get measureType => $composableBuilder(
    column: $table.measureType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get measureJson => $composableBuilder(
    column: $table.measureJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get why =>
      $composableBuilder(column: $table.why, builder: (column) => column);

  GeneratedColumn<String> get howJson =>
      $composableBuilder(column: $table.howJson, builder: (column) => column);

  GeneratedColumn<String> get warn =>
      $composableBuilder(column: $table.warn, builder: (column) => column);

  GeneratedColumn<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verified =>
      $composableBuilder(column: $table.verified, builder: (column) => column);

  GeneratedColumn<bool> get startsFromInstall => $composableBuilder(
    column: $table.startsFromInstall,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get appliesLastService => $composableBuilder(
    column: $table.appliesLastService,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get lastDoneDay => $composableBuilder(
    column: $table.lastDoneDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastDoneKm => $composableBuilder(
    column: $table.lastDoneKm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastValue =>
      $composableBuilder(column: $table.lastValue, builder: (column) => column);

  GeneratedColumn<String> get snoozeUntilDay => $composableBuilder(
    column: $table.snoozeUntilDay,
    builder: (column) => column,
  );

  $$VehiclesTableAnnotationComposer get vehicleId {
    final $$VehiclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableAnnotationComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> checkLogsRefs<T extends Object>(
    Expression<T> Function($$CheckLogsTableAnnotationComposer a) f,
  ) {
    final $$CheckLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkLogs,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.checkLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CheckItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CheckItemsTable,
          CheckItemRow,
          $$CheckItemsTableFilterComposer,
          $$CheckItemsTableOrderingComposer,
          $$CheckItemsTableAnnotationComposer,
          $$CheckItemsTableCreateCompanionBuilder,
          $$CheckItemsTableUpdateCompanionBuilder,
          (CheckItemRow, $$CheckItemsTableReferences),
          CheckItemRow,
          PrefetchHooks Function({bool vehicleId, bool checkLogsRefs})
        > {
  $$CheckItemsTableTableManager(_$AppDatabase db, $CheckItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> vehicleId = const Value.absent(),
                Value<String?> templateKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> groupKey = const Value.absent(),
                Value<String> scheduleKind = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                Value<int?> intervalKm = const Value.absent(),
                Value<String?> seasonalDates = const Value.absent(),
                Value<String> measureType = const Value.absent(),
                Value<String?> measureJson = const Value.absent(),
                Value<String> why = const Value.absent(),
                Value<String> howJson = const Value.absent(),
                Value<String?> warn = const Value.absent(),
                Value<String?> sourceNote = const Value.absent(),
                Value<String> verified = const Value.absent(),
                Value<bool> startsFromInstall = const Value.absent(),
                Value<bool> appliesLastService = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> lastDoneDay = const Value.absent(),
                Value<int?> lastDoneKm = const Value.absent(),
                Value<String?> lastValue = const Value.absent(),
                Value<String?> snoozeUntilDay = const Value.absent(),
              }) => CheckItemsCompanion(
                id: id,
                vehicleId: vehicleId,
                templateKey: templateKey,
                name: name,
                groupKey: groupKey,
                scheduleKind: scheduleKind,
                intervalDays: intervalDays,
                intervalKm: intervalKm,
                seasonalDates: seasonalDates,
                measureType: measureType,
                measureJson: measureJson,
                why: why,
                howJson: howJson,
                warn: warn,
                sourceNote: sourceNote,
                verified: verified,
                startsFromInstall: startsFromInstall,
                appliesLastService: appliesLastService,
                enabled: enabled,
                sortOrder: sortOrder,
                lastDoneDay: lastDoneDay,
                lastDoneKm: lastDoneKm,
                lastValue: lastValue,
                snoozeUntilDay: snoozeUntilDay,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int vehicleId,
                Value<String?> templateKey = const Value.absent(),
                required String name,
                required String groupKey,
                required String scheduleKind,
                Value<int?> intervalDays = const Value.absent(),
                Value<int?> intervalKm = const Value.absent(),
                Value<String?> seasonalDates = const Value.absent(),
                required String measureType,
                Value<String?> measureJson = const Value.absent(),
                Value<String> why = const Value.absent(),
                Value<String> howJson = const Value.absent(),
                Value<String?> warn = const Value.absent(),
                Value<String?> sourceNote = const Value.absent(),
                Value<String> verified = const Value.absent(),
                Value<bool> startsFromInstall = const Value.absent(),
                Value<bool> appliesLastService = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                required int sortOrder,
                Value<String?> lastDoneDay = const Value.absent(),
                Value<int?> lastDoneKm = const Value.absent(),
                Value<String?> lastValue = const Value.absent(),
                Value<String?> snoozeUntilDay = const Value.absent(),
              }) => CheckItemsCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                templateKey: templateKey,
                name: name,
                groupKey: groupKey,
                scheduleKind: scheduleKind,
                intervalDays: intervalDays,
                intervalKm: intervalKm,
                seasonalDates: seasonalDates,
                measureType: measureType,
                measureJson: measureJson,
                why: why,
                howJson: howJson,
                warn: warn,
                sourceNote: sourceNote,
                verified: verified,
                startsFromInstall: startsFromInstall,
                appliesLastService: appliesLastService,
                enabled: enabled,
                sortOrder: sortOrder,
                lastDoneDay: lastDoneDay,
                lastDoneKm: lastDoneKm,
                lastValue: lastValue,
                snoozeUntilDay: snoozeUntilDay,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CheckItemsTable, CheckItemRow>(table),
                  $$CheckItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({vehicleId = false, checkLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (checkLogsRefs) db.checkLogs],
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
                    if (vehicleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.vehicleId,
                        referencedTable: $$CheckItemsTableReferences
                            ._vehicleIdTable(db),
                        referencedColumn: $$CheckItemsTableReferences
                            ._vehicleIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (checkLogsRefs)
                    await $_getPrefetchedData<
                      CheckItemRow,
                      $CheckItemsTable,
                      CheckLogRow
                    >(
                      currentTable: table,
                      referencedTable: $$CheckItemsTableReferences
                          ._checkLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CheckItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).checkLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.itemId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CheckItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CheckItemsTable,
      CheckItemRow,
      $$CheckItemsTableFilterComposer,
      $$CheckItemsTableOrderingComposer,
      $$CheckItemsTableAnnotationComposer,
      $$CheckItemsTableCreateCompanionBuilder,
      $$CheckItemsTableUpdateCompanionBuilder,
      (CheckItemRow, $$CheckItemsTableReferences),
      CheckItemRow,
      PrefetchHooks Function({bool vehicleId, bool checkLogsRefs})
    >;
typedef $$CheckLogsTableCreateCompanionBuilder = CheckLogsCompanion Function({
  Value<int> id,
  required int itemId,
  required DateTime doneAt,
  required String doneDay,
  Value<int?> km,
  Value<String?> value,
  Value<String?> note,
  Value<String> kind,
});
typedef $$CheckLogsTableUpdateCompanionBuilder = CheckLogsCompanion Function({
  Value<int> id,
  Value<int> itemId,
  Value<DateTime> doneAt,
  Value<String> doneDay,
  Value<int?> km,
  Value<String?> value,
  Value<String?> note,
  Value<String> kind,
});

final class $$CheckLogsTableReferences
    extends BaseReferences<_$AppDatabase, $CheckLogsTable, CheckLogRow> {
  $$CheckLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CheckItemsTable _itemIdTable(_$AppDatabase db) =>
      db.checkItems.createAlias('check_logs__item_id__check_items__id');

  $$CheckItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$CheckItemsTableTableManager(
      $_db,
      $_db.checkItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CheckLogsTableFilterComposer
    extends Composer<_$AppDatabase, $CheckLogsTable> {
  $$CheckLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doneDay => $composableBuilder(
    column: $table.doneDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get km => $composableBuilder(
    column: $table.km,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  $$CheckItemsTableFilterComposer get itemId {
    final $$CheckItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.checkItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckItemsTableFilterComposer(
            $db: $db,
            $table: $db.checkItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $CheckLogsTable> {
  $$CheckLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doneDay => $composableBuilder(
    column: $table.doneDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get km => $composableBuilder(
    column: $table.km,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  $$CheckItemsTableOrderingComposer get itemId {
    final $$CheckItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.checkItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckItemsTableOrderingComposer(
            $db: $db,
            $table: $db.checkItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheckLogsTable> {
  $$CheckLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  GeneratedColumn<String> get doneDay =>
      $composableBuilder(column: $table.doneDay, builder: (column) => column);

  GeneratedColumn<int> get km =>
      $composableBuilder(column: $table.km, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  $$CheckItemsTableAnnotationComposer get itemId {
    final $$CheckItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.checkItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.checkItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CheckLogsTable,
          CheckLogRow,
          $$CheckLogsTableFilterComposer,
          $$CheckLogsTableOrderingComposer,
          $$CheckLogsTableAnnotationComposer,
          $$CheckLogsTableCreateCompanionBuilder,
          $$CheckLogsTableUpdateCompanionBuilder,
          (CheckLogRow, $$CheckLogsTableReferences),
          CheckLogRow,
          PrefetchHooks Function({bool itemId})
        > {
  $$CheckLogsTableTableManager(_$AppDatabase db, $CheckLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<DateTime> doneAt = const Value.absent(),
                Value<String> doneDay = const Value.absent(),
                Value<int?> km = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> kind = const Value.absent(),
              }) => CheckLogsCompanion(
                id: id,
                itemId: itemId,
                doneAt: doneAt,
                doneDay: doneDay,
                km: km,
                value: value,
                note: note,
                kind: kind,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                required DateTime doneAt,
                required String doneDay,
                Value<int?> km = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> kind = const Value.absent(),
              }) => CheckLogsCompanion.insert(
                id: id,
                itemId: itemId,
                doneAt: doneAt,
                doneDay: doneDay,
                km: km,
                value: value,
                note: note,
                kind: kind,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CheckLogsTable, CheckLogRow>(table),
                  $$CheckLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$CheckLogsTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$CheckLogsTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
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

typedef $$CheckLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CheckLogsTable,
      CheckLogRow,
      $$CheckLogsTableFilterComposer,
      $$CheckLogsTableOrderingComposer,
      $$CheckLogsTableAnnotationComposer,
      $$CheckLogsTableCreateCompanionBuilder,
      $$CheckLogsTableUpdateCompanionBuilder,
      (CheckLogRow, $$CheckLogsTableReferences),
      CheckLogRow,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$TripsTableCreateCompanionBuilder = TripsCompanion Function({
  Value<int> id,
  Value<DateTime?> connectedAt,
  required DateTime disconnectedAt,
  required int durationMin,
  required bool counted,
  required bool notified,
  Value<int> overdueCount,
  Value<String?> note,
});
typedef $$TripsTableUpdateCompanionBuilder = TripsCompanion Function({
  Value<int> id,
  Value<DateTime?> connectedAt,
  Value<DateTime> disconnectedAt,
  Value<int> durationMin,
  Value<bool> counted,
  Value<bool> notified,
  Value<int> overdueCount,
  Value<String?> note,
});

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get disconnectedAt => $composableBuilder(
    column: $table.disconnectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get counted => $composableBuilder(
    column: $table.counted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notified => $composableBuilder(
    column: $table.notified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overdueCount => $composableBuilder(
    column: $table.overdueCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get disconnectedAt => $composableBuilder(
    column: $table.disconnectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get counted => $composableBuilder(
    column: $table.counted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notified => $composableBuilder(
    column: $table.notified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overdueCount => $composableBuilder(
    column: $table.overdueCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get disconnectedAt => $composableBuilder(
    column: $table.disconnectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get counted =>
      $composableBuilder(column: $table.counted, builder: (column) => column);

  GeneratedColumn<bool> get notified =>
      $composableBuilder(column: $table.notified, builder: (column) => column);

  GeneratedColumn<int> get overdueCount => $composableBuilder(
    column: $table.overdueCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          TripRow,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (TripRow, BaseReferences<_$AppDatabase, $TripsTable, TripRow>),
          TripRow,
          PrefetchHooks Function()
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> connectedAt = const Value.absent(),
                Value<DateTime> disconnectedAt = const Value.absent(),
                Value<int> durationMin = const Value.absent(),
                Value<bool> counted = const Value.absent(),
                Value<bool> notified = const Value.absent(),
                Value<int> overdueCount = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => TripsCompanion(
                id: id,
                connectedAt: connectedAt,
                disconnectedAt: disconnectedAt,
                durationMin: durationMin,
                counted: counted,
                notified: notified,
                overdueCount: overdueCount,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> connectedAt = const Value.absent(),
                required DateTime disconnectedAt,
                required int durationMin,
                required bool counted,
                required bool notified,
                Value<int> overdueCount = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => TripsCompanion.insert(
                id: id,
                connectedAt: connectedAt,
                disconnectedAt: disconnectedAt,
                durationMin: durationMin,
                counted: counted,
                notified: notified,
                overdueCount: overdueCount,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TripsTable, TripRow>(table),
                  BaseReferences<_$AppDatabase, $TripsTable, TripRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      TripRow,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (TripRow, BaseReferences<_$AppDatabase, $TripsTable, TripRow>),
      TripRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
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

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db, _db.vehicles);
  $$CheckItemsTableTableManager get checkItems =>
      $$CheckItemsTableTableManager(_db, _db.checkItems);
  $$CheckLogsTableTableManager get checkLogs =>
      $$CheckLogsTableTableManager(_db, _db.checkLogs);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
