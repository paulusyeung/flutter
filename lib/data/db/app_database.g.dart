// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ClientsTable extends Clients with TableInfo<$ClientsTable, ClientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempIdMeta = const VerificationMeta('tempId');
  @override
  late final GeneratedColumn<String> tempId = GeneratedColumn<String>(
    'temp_id',
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
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<String> balance = GeneratedColumn<String>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customValue1Meta = const VerificationMeta(
    'customValue1',
  );
  @override
  late final GeneratedColumn<String> customValue1 = GeneratedColumn<String>(
    'custom_value1',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _customValue2Meta = const VerificationMeta(
    'customValue2',
  );
  @override
  late final GeneratedColumn<String> customValue2 = GeneratedColumn<String>(
    'custom_value2',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _customValue3Meta = const VerificationMeta(
    'customValue3',
  );
  @override
  late final GeneratedColumn<String> customValue3 = GeneratedColumn<String>(
    'custom_value3',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _customValue4Meta = const VerificationMeta(
    'customValue4',
  );
  @override
  late final GeneratedColumn<String> customValue4 = GeneratedColumn<String>(
    'custom_value4',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    tempId,
    name,
    number,
    email,
    displayName,
    balance,
    updatedAt,
    createdAt,
    archivedAt,
    customValue1,
    customValue2,
    customValue3,
    customValue4,
    isDirty,
    isDeleted,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clients';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClientRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('temp_id')) {
      context.handle(
        _tempIdMeta,
        tempId.isAcceptableOrUnknown(data['temp_id']!, _tempIdMeta),
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
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('custom_value1')) {
      context.handle(
        _customValue1Meta,
        customValue1.isAcceptableOrUnknown(
          data['custom_value1']!,
          _customValue1Meta,
        ),
      );
    }
    if (data.containsKey('custom_value2')) {
      context.handle(
        _customValue2Meta,
        customValue2.isAcceptableOrUnknown(
          data['custom_value2']!,
          _customValue2Meta,
        ),
      );
    }
    if (data.containsKey('custom_value3')) {
      context.handle(
        _customValue3Meta,
        customValue3.isAcceptableOrUnknown(
          data['custom_value3']!,
          _customValue3Meta,
        ),
      );
    }
    if (data.containsKey('custom_value4')) {
      context.handle(
        _customValue4Meta,
        customValue4.isAcceptableOrUnknown(
          data['custom_value4']!,
          _customValue4Meta,
        ),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      tempId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temp_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}balance'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived_at'],
      ),
      customValue1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_value1'],
      )!,
      customValue2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_value2'],
      )!,
      customValue3: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_value3'],
      )!,
      customValue4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_value4'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $ClientsTable createAlias(String alias) {
    return $ClientsTable(attachedDatabase, alias);
  }
}

class ClientRow extends DataClass implements Insertable<ClientRow> {
  final String id;
  final String companyId;
  final String? tempId;
  final String name;
  final String number;
  final String email;
  final String displayName;
  final String balance;
  final int updatedAt;
  final int createdAt;
  final int? archivedAt;
  final String customValue1;
  final String customValue2;
  final String customValue3;
  final String customValue4;
  final bool isDirty;
  final bool isDeleted;
  final String payload;
  const ClientRow({
    required this.id,
    required this.companyId,
    this.tempId,
    required this.name,
    required this.number,
    required this.email,
    required this.displayName,
    required this.balance,
    required this.updatedAt,
    required this.createdAt,
    this.archivedAt,
    required this.customValue1,
    required this.customValue2,
    required this.customValue3,
    required this.customValue4,
    required this.isDirty,
    required this.isDeleted,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    if (!nullToAbsent || tempId != null) {
      map['temp_id'] = Variable<String>(tempId);
    }
    map['name'] = Variable<String>(name);
    map['number'] = Variable<String>(number);
    map['email'] = Variable<String>(email);
    map['display_name'] = Variable<String>(displayName);
    map['balance'] = Variable<String>(balance);
    map['updated_at'] = Variable<int>(updatedAt);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    map['custom_value1'] = Variable<String>(customValue1);
    map['custom_value2'] = Variable<String>(customValue2);
    map['custom_value3'] = Variable<String>(customValue3);
    map['custom_value4'] = Variable<String>(customValue4);
    map['is_dirty'] = Variable<bool>(isDirty);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  ClientsCompanion toCompanion(bool nullToAbsent) {
    return ClientsCompanion(
      id: Value(id),
      companyId: Value(companyId),
      tempId: tempId == null && nullToAbsent
          ? const Value.absent()
          : Value(tempId),
      name: Value(name),
      number: Value(number),
      email: Value(email),
      displayName: Value(displayName),
      balance: Value(balance),
      updatedAt: Value(updatedAt),
      createdAt: Value(createdAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      customValue1: Value(customValue1),
      customValue2: Value(customValue2),
      customValue3: Value(customValue3),
      customValue4: Value(customValue4),
      isDirty: Value(isDirty),
      isDeleted: Value(isDeleted),
      payload: Value(payload),
    );
  }

  factory ClientRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientRow(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      tempId: serializer.fromJson<String?>(json['tempId']),
      name: serializer.fromJson<String>(json['name']),
      number: serializer.fromJson<String>(json['number']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String>(json['displayName']),
      balance: serializer.fromJson<String>(json['balance']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      archivedAt: serializer.fromJson<int?>(json['archivedAt']),
      customValue1: serializer.fromJson<String>(json['customValue1']),
      customValue2: serializer.fromJson<String>(json['customValue2']),
      customValue3: serializer.fromJson<String>(json['customValue3']),
      customValue4: serializer.fromJson<String>(json['customValue4']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'tempId': serializer.toJson<String?>(tempId),
      'name': serializer.toJson<String>(name),
      'number': serializer.toJson<String>(number),
      'email': serializer.toJson<String>(email),
      'displayName': serializer.toJson<String>(displayName),
      'balance': serializer.toJson<String>(balance),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'archivedAt': serializer.toJson<int?>(archivedAt),
      'customValue1': serializer.toJson<String>(customValue1),
      'customValue2': serializer.toJson<String>(customValue2),
      'customValue3': serializer.toJson<String>(customValue3),
      'customValue4': serializer.toJson<String>(customValue4),
      'isDirty': serializer.toJson<bool>(isDirty),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'payload': serializer.toJson<String>(payload),
    };
  }

  ClientRow copyWith({
    String? id,
    String? companyId,
    Value<String?> tempId = const Value.absent(),
    String? name,
    String? number,
    String? email,
    String? displayName,
    String? balance,
    int? updatedAt,
    int? createdAt,
    Value<int?> archivedAt = const Value.absent(),
    String? customValue1,
    String? customValue2,
    String? customValue3,
    String? customValue4,
    bool? isDirty,
    bool? isDeleted,
    String? payload,
  }) => ClientRow(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    tempId: tempId.present ? tempId.value : this.tempId,
    name: name ?? this.name,
    number: number ?? this.number,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    balance: balance ?? this.balance,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    customValue1: customValue1 ?? this.customValue1,
    customValue2: customValue2 ?? this.customValue2,
    customValue3: customValue3 ?? this.customValue3,
    customValue4: customValue4 ?? this.customValue4,
    isDirty: isDirty ?? this.isDirty,
    isDeleted: isDeleted ?? this.isDeleted,
    payload: payload ?? this.payload,
  );
  ClientRow copyWithCompanion(ClientsCompanion data) {
    return ClientRow(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      tempId: data.tempId.present ? data.tempId.value : this.tempId,
      name: data.name.present ? data.name.value : this.name,
      number: data.number.present ? data.number.value : this.number,
      email: data.email.present ? data.email.value : this.email,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      balance: data.balance.present ? data.balance.value : this.balance,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      customValue1: data.customValue1.present
          ? data.customValue1.value
          : this.customValue1,
      customValue2: data.customValue2.present
          ? data.customValue2.value
          : this.customValue2,
      customValue3: data.customValue3.present
          ? data.customValue3.value
          : this.customValue3,
      customValue4: data.customValue4.present
          ? data.customValue4.value
          : this.customValue4,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientRow(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('tempId: $tempId, ')
          ..write('name: $name, ')
          ..write('number: $number, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('balance: $balance, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('customValue1: $customValue1, ')
          ..write('customValue2: $customValue2, ')
          ..write('customValue3: $customValue3, ')
          ..write('customValue4: $customValue4, ')
          ..write('isDirty: $isDirty, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    tempId,
    name,
    number,
    email,
    displayName,
    balance,
    updatedAt,
    createdAt,
    archivedAt,
    customValue1,
    customValue2,
    customValue3,
    customValue4,
    isDirty,
    isDeleted,
    payload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientRow &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.tempId == this.tempId &&
          other.name == this.name &&
          other.number == this.number &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.balance == this.balance &&
          other.updatedAt == this.updatedAt &&
          other.createdAt == this.createdAt &&
          other.archivedAt == this.archivedAt &&
          other.customValue1 == this.customValue1 &&
          other.customValue2 == this.customValue2 &&
          other.customValue3 == this.customValue3 &&
          other.customValue4 == this.customValue4 &&
          other.isDirty == this.isDirty &&
          other.isDeleted == this.isDeleted &&
          other.payload == this.payload);
}

class ClientsCompanion extends UpdateCompanion<ClientRow> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String?> tempId;
  final Value<String> name;
  final Value<String> number;
  final Value<String> email;
  final Value<String> displayName;
  final Value<String> balance;
  final Value<int> updatedAt;
  final Value<int> createdAt;
  final Value<int?> archivedAt;
  final Value<String> customValue1;
  final Value<String> customValue2;
  final Value<String> customValue3;
  final Value<String> customValue4;
  final Value<bool> isDirty;
  final Value<bool> isDeleted;
  final Value<String> payload;
  final Value<int> rowid;
  const ClientsCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.tempId = const Value.absent(),
    this.name = const Value.absent(),
    this.number = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.balance = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.customValue1 = const Value.absent(),
    this.customValue2 = const Value.absent(),
    this.customValue3 = const Value.absent(),
    this.customValue4 = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientsCompanion.insert({
    required String id,
    required String companyId,
    this.tempId = const Value.absent(),
    required String name,
    required String number,
    required String email,
    required String displayName,
    required String balance,
    required int updatedAt,
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.customValue1 = const Value.absent(),
    this.customValue2 = const Value.absent(),
    this.customValue3 = const Value.absent(),
    this.customValue4 = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required String payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       name = Value(name),
       number = Value(number),
       email = Value(email),
       displayName = Value(displayName),
       balance = Value(balance),
       updatedAt = Value(updatedAt),
       payload = Value(payload);
  static Insertable<ClientRow> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? tempId,
    Expression<String>? name,
    Expression<String>? number,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? balance,
    Expression<int>? updatedAt,
    Expression<int>? createdAt,
    Expression<int>? archivedAt,
    Expression<String>? customValue1,
    Expression<String>? customValue2,
    Expression<String>? customValue3,
    Expression<String>? customValue4,
    Expression<bool>? isDirty,
    Expression<bool>? isDeleted,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (tempId != null) 'temp_id': tempId,
      if (name != null) 'name': name,
      if (number != null) 'number': number,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (balance != null) 'balance': balance,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (customValue1 != null) 'custom_value1': customValue1,
      if (customValue2 != null) 'custom_value2': customValue2,
      if (customValue3 != null) 'custom_value3': customValue3,
      if (customValue4 != null) 'custom_value4': customValue4,
      if (isDirty != null) 'is_dirty': isDirty,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientsCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String?>? tempId,
    Value<String>? name,
    Value<String>? number,
    Value<String>? email,
    Value<String>? displayName,
    Value<String>? balance,
    Value<int>? updatedAt,
    Value<int>? createdAt,
    Value<int?>? archivedAt,
    Value<String>? customValue1,
    Value<String>? customValue2,
    Value<String>? customValue3,
    Value<String>? customValue4,
    Value<bool>? isDirty,
    Value<bool>? isDeleted,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return ClientsCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      tempId: tempId ?? this.tempId,
      name: name ?? this.name,
      number: number ?? this.number,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      balance: balance ?? this.balance,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      customValue1: customValue1 ?? this.customValue1,
      customValue2: customValue2 ?? this.customValue2,
      customValue3: customValue3 ?? this.customValue3,
      customValue4: customValue4 ?? this.customValue4,
      isDirty: isDirty ?? this.isDirty,
      isDeleted: isDeleted ?? this.isDeleted,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (tempId.present) {
      map['temp_id'] = Variable<String>(tempId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (balance.present) {
      map['balance'] = Variable<String>(balance.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (customValue1.present) {
      map['custom_value1'] = Variable<String>(customValue1.value);
    }
    if (customValue2.present) {
      map['custom_value2'] = Variable<String>(customValue2.value);
    }
    if (customValue3.present) {
      map['custom_value3'] = Variable<String>(customValue3.value);
    }
    if (customValue4.present) {
      map['custom_value4'] = Variable<String>(customValue4.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientsCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('tempId: $tempId, ')
          ..write('name: $name, ')
          ..write('number: $number, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('balance: $balance, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('customValue1: $customValue1, ')
          ..write('customValue2: $customValue2, ')
          ..write('customValue3: $customValue3, ')
          ..write('customValue4: $customValue4, ')
          ..write('isDirty: $isDirty, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mutationKindMeta = const VerificationMeta(
    'mutationKind',
  );
  @override
  late final GeneratedColumn<String> mutationKind = GeneratedColumn<String>(
    'mutation_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastStatusCodeMeta = const VerificationMeta(
    'lastStatusCode',
  );
  @override
  late final GeneratedColumn<int> lastStatusCode = GeneratedColumn<int>(
    'last_status_code',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiresPasswordMeta = const VerificationMeta(
    'requiresPassword',
  );
  @override
  late final GeneratedColumn<bool> requiresPassword = GeneratedColumn<bool>(
    'requires_password',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("requires_password" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    entityType,
    entityId,
    mutationKind,
    payload,
    idempotencyKey,
    attempts,
    nextAttemptAt,
    state,
    lastError,
    lastStatusCode,
    requiresPassword,
    batchId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('mutation_kind')) {
      context.handle(
        _mutationKindMeta,
        mutationKind.isAcceptableOrUnknown(
          data['mutation_kind']!,
          _mutationKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mutationKindMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('last_status_code')) {
      context.handle(
        _lastStatusCodeMeta,
        lastStatusCode.isAcceptableOrUnknown(
          data['last_status_code']!,
          _lastStatusCodeMeta,
        ),
      );
    }
    if (data.containsKey('requires_password')) {
      context.handle(
        _requiresPasswordMeta,
        requiresPassword.isAcceptableOrUnknown(
          data['requires_password']!,
          _requiresPasswordMeta,
        ),
      );
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
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
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      mutationKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      lastStatusCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_status_code'],
      ),
      requiresPassword: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}requires_password'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int id;
  final String companyId;
  final String entityType;
  final String entityId;
  final String mutationKind;
  final String payload;
  final String idempotencyKey;
  final int attempts;
  final int nextAttemptAt;
  final String state;
  final String? lastError;
  final int? lastStatusCode;
  final bool requiresPassword;
  final String? batchId;
  final int createdAt;
  const OutboxRow({
    required this.id,
    required this.companyId,
    required this.entityType,
    required this.entityId,
    required this.mutationKind,
    required this.payload,
    required this.idempotencyKey,
    required this.attempts,
    required this.nextAttemptAt,
    required this.state,
    this.lastError,
    this.lastStatusCode,
    required this.requiresPassword,
    this.batchId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['company_id'] = Variable<String>(companyId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['mutation_kind'] = Variable<String>(mutationKind);
    map['payload'] = Variable<String>(payload);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || lastStatusCode != null) {
      map['last_status_code'] = Variable<int>(lastStatusCode);
    }
    map['requires_password'] = Variable<bool>(requiresPassword);
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      companyId: Value(companyId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      mutationKind: Value(mutationKind),
      payload: Value(payload),
      idempotencyKey: Value(idempotencyKey),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      state: Value(state),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      lastStatusCode: lastStatusCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStatusCode),
      requiresPassword: Value(requiresPassword),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<int>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      mutationKind: serializer.fromJson<String>(json['mutationKind']),
      payload: serializer.fromJson<String>(json['payload']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<int>(json['nextAttemptAt']),
      state: serializer.fromJson<String>(json['state']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      lastStatusCode: serializer.fromJson<int?>(json['lastStatusCode']),
      requiresPassword: serializer.fromJson<bool>(json['requiresPassword']),
      batchId: serializer.fromJson<String?>(json['batchId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'companyId': serializer.toJson<String>(companyId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'mutationKind': serializer.toJson<String>(mutationKind),
      'payload': serializer.toJson<String>(payload),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<int>(nextAttemptAt),
      'state': serializer.toJson<String>(state),
      'lastError': serializer.toJson<String?>(lastError),
      'lastStatusCode': serializer.toJson<int?>(lastStatusCode),
      'requiresPassword': serializer.toJson<bool>(requiresPassword),
      'batchId': serializer.toJson<String?>(batchId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  OutboxRow copyWith({
    int? id,
    String? companyId,
    String? entityType,
    String? entityId,
    String? mutationKind,
    String? payload,
    String? idempotencyKey,
    int? attempts,
    int? nextAttemptAt,
    String? state,
    Value<String?> lastError = const Value.absent(),
    Value<int?> lastStatusCode = const Value.absent(),
    bool? requiresPassword,
    Value<String?> batchId = const Value.absent(),
    int? createdAt,
  }) => OutboxRow(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    mutationKind: mutationKind ?? this.mutationKind,
    payload: payload ?? this.payload,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    state: state ?? this.state,
    lastError: lastError.present ? lastError.value : this.lastError,
    lastStatusCode: lastStatusCode.present
        ? lastStatusCode.value
        : this.lastStatusCode,
    requiresPassword: requiresPassword ?? this.requiresPassword,
    batchId: batchId.present ? batchId.value : this.batchId,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxRow copyWithCompanion(OutboxCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      mutationKind: data.mutationKind.present
          ? data.mutationKind.value
          : this.mutationKind,
      payload: data.payload.present ? data.payload.value : this.payload,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      state: data.state.present ? data.state.value : this.state,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      lastStatusCode: data.lastStatusCode.present
          ? data.lastStatusCode.value
          : this.lastStatusCode,
      requiresPassword: data.requiresPassword.present
          ? data.requiresPassword.value
          : this.requiresPassword,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('mutationKind: $mutationKind, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('state: $state, ')
          ..write('lastError: $lastError, ')
          ..write('lastStatusCode: $lastStatusCode, ')
          ..write('requiresPassword: $requiresPassword, ')
          ..write('batchId: $batchId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    entityType,
    entityId,
    mutationKind,
    payload,
    idempotencyKey,
    attempts,
    nextAttemptAt,
    state,
    lastError,
    lastStatusCode,
    requiresPassword,
    batchId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.mutationKind == this.mutationKind &&
          other.payload == this.payload &&
          other.idempotencyKey == this.idempotencyKey &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.state == this.state &&
          other.lastError == this.lastError &&
          other.lastStatusCode == this.lastStatusCode &&
          other.requiresPassword == this.requiresPassword &&
          other.batchId == this.batchId &&
          other.createdAt == this.createdAt);
}

class OutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> id;
  final Value<String> companyId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> mutationKind;
  final Value<String> payload;
  final Value<String> idempotencyKey;
  final Value<int> attempts;
  final Value<int> nextAttemptAt;
  final Value<String> state;
  final Value<String?> lastError;
  final Value<int?> lastStatusCode;
  final Value<bool> requiresPassword;
  final Value<String?> batchId;
  final Value<int> createdAt;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.mutationKind = const Value.absent(),
    this.payload = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.state = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastStatusCode = const Value.absent(),
    this.requiresPassword = const Value.absent(),
    this.batchId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.id = const Value.absent(),
    required String companyId,
    required String entityType,
    required String entityId,
    required String mutationKind,
    required String payload,
    required String idempotencyKey,
    this.attempts = const Value.absent(),
    required int nextAttemptAt,
    this.state = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastStatusCode = const Value.absent(),
    this.requiresPassword = const Value.absent(),
    this.batchId = const Value.absent(),
    required int createdAt,
  }) : companyId = Value(companyId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       mutationKind = Value(mutationKind),
       payload = Value(payload),
       idempotencyKey = Value(idempotencyKey),
       nextAttemptAt = Value(nextAttemptAt),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<int>? id,
    Expression<String>? companyId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? mutationKind,
    Expression<String>? payload,
    Expression<String>? idempotencyKey,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAt,
    Expression<String>? state,
    Expression<String>? lastError,
    Expression<int>? lastStatusCode,
    Expression<bool>? requiresPassword,
    Expression<String>? batchId,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (mutationKind != null) 'mutation_kind': mutationKind,
      if (payload != null) 'payload': payload,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (state != null) 'state': state,
      if (lastError != null) 'last_error': lastError,
      if (lastStatusCode != null) 'last_status_code': lastStatusCode,
      if (requiresPassword != null) 'requires_password': requiresPassword,
      if (batchId != null) 'batch_id': batchId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? companyId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? mutationKind,
    Value<String>? payload,
    Value<String>? idempotencyKey,
    Value<int>? attempts,
    Value<int>? nextAttemptAt,
    Value<String>? state,
    Value<String?>? lastError,
    Value<int?>? lastStatusCode,
    Value<bool>? requiresPassword,
    Value<String?>? batchId,
    Value<int>? createdAt,
  }) {
    return OutboxCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      mutationKind: mutationKind ?? this.mutationKind,
      payload: payload ?? this.payload,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      state: state ?? this.state,
      lastError: lastError ?? this.lastError,
      lastStatusCode: lastStatusCode ?? this.lastStatusCode,
      requiresPassword: requiresPassword ?? this.requiresPassword,
      batchId: batchId ?? this.batchId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (mutationKind.present) {
      map['mutation_kind'] = Variable<String>(mutationKind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (lastStatusCode.present) {
      map['last_status_code'] = Variable<int>(lastStatusCode.value);
    }
    if (requiresPassword.present) {
      map['requires_password'] = Variable<bool>(requiresPassword.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('mutationKind: $mutationKind, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('state: $state, ')
          ..write('lastError: $lastError, ')
          ..write('lastStatusCode: $lastStatusCode, ')
          ..write('requiresPassword: $requiresPassword, ')
          ..write('batchId: $batchId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $IdRemapTable extends IdRemap with TableInfo<$IdRemapTable, IdRemapRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdRemapTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempIdMeta = const VerificationMeta('tempId');
  @override
  late final GeneratedColumn<String> tempId = GeneratedColumn<String>(
    'temp_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _realIdMeta = const VerificationMeta('realId');
  @override
  late final GeneratedColumn<String> realId = GeneratedColumn<String>(
    'real_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entityType, tempId, realId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'id_remap';
  @override
  VerificationContext validateIntegrity(
    Insertable<IdRemapRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('temp_id')) {
      context.handle(
        _tempIdMeta,
        tempId.isAcceptableOrUnknown(data['temp_id']!, _tempIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tempIdMeta);
    }
    if (data.containsKey('real_id')) {
      context.handle(
        _realIdMeta,
        realId.isAcceptableOrUnknown(data['real_id']!, _realIdMeta),
      );
    } else if (isInserting) {
      context.missing(_realIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {entityType, tempId};
  @override
  IdRemapRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdRemapRow(
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      tempId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temp_id'],
      )!,
      realId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}real_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IdRemapTable createAlias(String alias) {
    return $IdRemapTable(attachedDatabase, alias);
  }
}

class IdRemapRow extends DataClass implements Insertable<IdRemapRow> {
  final String entityType;
  final String tempId;
  final String realId;
  final int createdAt;
  const IdRemapRow({
    required this.entityType,
    required this.tempId,
    required this.realId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['temp_id'] = Variable<String>(tempId);
    map['real_id'] = Variable<String>(realId);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  IdRemapCompanion toCompanion(bool nullToAbsent) {
    return IdRemapCompanion(
      entityType: Value(entityType),
      tempId: Value(tempId),
      realId: Value(realId),
      createdAt: Value(createdAt),
    );
  }

  factory IdRemapRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdRemapRow(
      entityType: serializer.fromJson<String>(json['entityType']),
      tempId: serializer.fromJson<String>(json['tempId']),
      realId: serializer.fromJson<String>(json['realId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'tempId': serializer.toJson<String>(tempId),
      'realId': serializer.toJson<String>(realId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  IdRemapRow copyWith({
    String? entityType,
    String? tempId,
    String? realId,
    int? createdAt,
  }) => IdRemapRow(
    entityType: entityType ?? this.entityType,
    tempId: tempId ?? this.tempId,
    realId: realId ?? this.realId,
    createdAt: createdAt ?? this.createdAt,
  );
  IdRemapRow copyWithCompanion(IdRemapCompanion data) {
    return IdRemapRow(
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      tempId: data.tempId.present ? data.tempId.value : this.tempId,
      realId: data.realId.present ? data.realId.value : this.realId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdRemapRow(')
          ..write('entityType: $entityType, ')
          ..write('tempId: $tempId, ')
          ..write('realId: $realId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityType, tempId, realId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdRemapRow &&
          other.entityType == this.entityType &&
          other.tempId == this.tempId &&
          other.realId == this.realId &&
          other.createdAt == this.createdAt);
}

class IdRemapCompanion extends UpdateCompanion<IdRemapRow> {
  final Value<String> entityType;
  final Value<String> tempId;
  final Value<String> realId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const IdRemapCompanion({
    this.entityType = const Value.absent(),
    this.tempId = const Value.absent(),
    this.realId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdRemapCompanion.insert({
    required String entityType,
    required String tempId,
    required String realId,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       tempId = Value(tempId),
       realId = Value(realId),
       createdAt = Value(createdAt);
  static Insertable<IdRemapRow> custom({
    Expression<String>? entityType,
    Expression<String>? tempId,
    Expression<String>? realId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (tempId != null) 'temp_id': tempId,
      if (realId != null) 'real_id': realId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdRemapCompanion copyWith({
    Value<String>? entityType,
    Value<String>? tempId,
    Value<String>? realId,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return IdRemapCompanion(
      entityType: entityType ?? this.entityType,
      tempId: tempId ?? this.tempId,
      realId: realId ?? this.realId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (tempId.present) {
      map['temp_id'] = Variable<String>(tempId.value);
    }
    if (realId.present) {
      map['real_id'] = Variable<String>(realId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdRemapCompanion(')
          ..write('entityType: $entityType, ')
          ..write('tempId: $tempId, ')
          ..write('realId: $realId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateRowsTable extends SyncStateRows
    with TableInfo<$SyncStateRowsTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> lastUpdatedAt = GeneratedColumn<int>(
    'last_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUpdatedIdMeta = const VerificationMeta(
    'lastUpdatedId',
  );
  @override
  late final GeneratedColumn<String> lastUpdatedId = GeneratedColumn<String>(
    'last_updated_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastFullSyncAtMeta = const VerificationMeta(
    'lastFullSyncAt',
  );
  @override
  late final GeneratedColumn<int> lastFullSyncAt = GeneratedColumn<int>(
    'last_full_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastDeltaSyncAtMeta = const VerificationMeta(
    'lastDeltaSyncAt',
  );
  @override
  late final GeneratedColumn<int> lastDeltaSyncAt = GeneratedColumn<int>(
    'last_delta_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    companyId,
    entityType,
    lastUpdatedAt,
    lastUpdatedId,
    lastFullSyncAt,
    lastDeltaSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_updated_id')) {
      context.handle(
        _lastUpdatedIdMeta,
        lastUpdatedId.isAcceptableOrUnknown(
          data['last_updated_id']!,
          _lastUpdatedIdMeta,
        ),
      );
    }
    if (data.containsKey('last_full_sync_at')) {
      context.handle(
        _lastFullSyncAtMeta,
        lastFullSyncAt.isAcceptableOrUnknown(
          data['last_full_sync_at']!,
          _lastFullSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_delta_sync_at')) {
      context.handle(
        _lastDeltaSyncAtMeta,
        lastDeltaSyncAt.isAcceptableOrUnknown(
          data['last_delta_sync_at']!,
          _lastDeltaSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {companyId, entityType};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_updated_at'],
      ),
      lastUpdatedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_updated_id'],
      ),
      lastFullSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_full_sync_at'],
      ),
      lastDeltaSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_delta_sync_at'],
      ),
    );
  }

  @override
  $SyncStateRowsTable createAlias(String alias) {
    return $SyncStateRowsTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String companyId;
  final String entityType;
  final int? lastUpdatedAt;
  final String? lastUpdatedId;
  final int? lastFullSyncAt;
  final int? lastDeltaSyncAt;
  const SyncStateRow({
    required this.companyId,
    required this.entityType,
    this.lastUpdatedAt,
    this.lastUpdatedId,
    this.lastFullSyncAt,
    this.lastDeltaSyncAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['company_id'] = Variable<String>(companyId);
    map['entity_type'] = Variable<String>(entityType);
    if (!nullToAbsent || lastUpdatedAt != null) {
      map['last_updated_at'] = Variable<int>(lastUpdatedAt);
    }
    if (!nullToAbsent || lastUpdatedId != null) {
      map['last_updated_id'] = Variable<String>(lastUpdatedId);
    }
    if (!nullToAbsent || lastFullSyncAt != null) {
      map['last_full_sync_at'] = Variable<int>(lastFullSyncAt);
    }
    if (!nullToAbsent || lastDeltaSyncAt != null) {
      map['last_delta_sync_at'] = Variable<int>(lastDeltaSyncAt);
    }
    return map;
  }

  SyncStateRowsCompanion toCompanion(bool nullToAbsent) {
    return SyncStateRowsCompanion(
      companyId: Value(companyId),
      entityType: Value(entityType),
      lastUpdatedAt: lastUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdatedAt),
      lastUpdatedId: lastUpdatedId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdatedId),
      lastFullSyncAt: lastFullSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFullSyncAt),
      lastDeltaSyncAt: lastDeltaSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDeltaSyncAt),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      companyId: serializer.fromJson<String>(json['companyId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      lastUpdatedAt: serializer.fromJson<int?>(json['lastUpdatedAt']),
      lastUpdatedId: serializer.fromJson<String?>(json['lastUpdatedId']),
      lastFullSyncAt: serializer.fromJson<int?>(json['lastFullSyncAt']),
      lastDeltaSyncAt: serializer.fromJson<int?>(json['lastDeltaSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'companyId': serializer.toJson<String>(companyId),
      'entityType': serializer.toJson<String>(entityType),
      'lastUpdatedAt': serializer.toJson<int?>(lastUpdatedAt),
      'lastUpdatedId': serializer.toJson<String?>(lastUpdatedId),
      'lastFullSyncAt': serializer.toJson<int?>(lastFullSyncAt),
      'lastDeltaSyncAt': serializer.toJson<int?>(lastDeltaSyncAt),
    };
  }

  SyncStateRow copyWith({
    String? companyId,
    String? entityType,
    Value<int?> lastUpdatedAt = const Value.absent(),
    Value<String?> lastUpdatedId = const Value.absent(),
    Value<int?> lastFullSyncAt = const Value.absent(),
    Value<int?> lastDeltaSyncAt = const Value.absent(),
  }) => SyncStateRow(
    companyId: companyId ?? this.companyId,
    entityType: entityType ?? this.entityType,
    lastUpdatedAt: lastUpdatedAt.present
        ? lastUpdatedAt.value
        : this.lastUpdatedAt,
    lastUpdatedId: lastUpdatedId.present
        ? lastUpdatedId.value
        : this.lastUpdatedId,
    lastFullSyncAt: lastFullSyncAt.present
        ? lastFullSyncAt.value
        : this.lastFullSyncAt,
    lastDeltaSyncAt: lastDeltaSyncAt.present
        ? lastDeltaSyncAt.value
        : this.lastDeltaSyncAt,
  );
  SyncStateRow copyWithCompanion(SyncStateRowsCompanion data) {
    return SyncStateRow(
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
      lastUpdatedId: data.lastUpdatedId.present
          ? data.lastUpdatedId.value
          : this.lastUpdatedId,
      lastFullSyncAt: data.lastFullSyncAt.present
          ? data.lastFullSyncAt.value
          : this.lastFullSyncAt,
      lastDeltaSyncAt: data.lastDeltaSyncAt.present
          ? data.lastDeltaSyncAt.value
          : this.lastDeltaSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('companyId: $companyId, ')
          ..write('entityType: $entityType, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('lastUpdatedId: $lastUpdatedId, ')
          ..write('lastFullSyncAt: $lastFullSyncAt, ')
          ..write('lastDeltaSyncAt: $lastDeltaSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    companyId,
    entityType,
    lastUpdatedAt,
    lastUpdatedId,
    lastFullSyncAt,
    lastDeltaSyncAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.companyId == this.companyId &&
          other.entityType == this.entityType &&
          other.lastUpdatedAt == this.lastUpdatedAt &&
          other.lastUpdatedId == this.lastUpdatedId &&
          other.lastFullSyncAt == this.lastFullSyncAt &&
          other.lastDeltaSyncAt == this.lastDeltaSyncAt);
}

class SyncStateRowsCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> companyId;
  final Value<String> entityType;
  final Value<int?> lastUpdatedAt;
  final Value<String?> lastUpdatedId;
  final Value<int?> lastFullSyncAt;
  final Value<int?> lastDeltaSyncAt;
  final Value<int> rowid;
  const SyncStateRowsCompanion({
    this.companyId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.lastUpdatedId = const Value.absent(),
    this.lastFullSyncAt = const Value.absent(),
    this.lastDeltaSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateRowsCompanion.insert({
    required String companyId,
    required String entityType,
    this.lastUpdatedAt = const Value.absent(),
    this.lastUpdatedId = const Value.absent(),
    this.lastFullSyncAt = const Value.absent(),
    this.lastDeltaSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : companyId = Value(companyId),
       entityType = Value(entityType);
  static Insertable<SyncStateRow> custom({
    Expression<String>? companyId,
    Expression<String>? entityType,
    Expression<int>? lastUpdatedAt,
    Expression<String>? lastUpdatedId,
    Expression<int>? lastFullSyncAt,
    Expression<int>? lastDeltaSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (companyId != null) 'company_id': companyId,
      if (entityType != null) 'entity_type': entityType,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
      if (lastUpdatedId != null) 'last_updated_id': lastUpdatedId,
      if (lastFullSyncAt != null) 'last_full_sync_at': lastFullSyncAt,
      if (lastDeltaSyncAt != null) 'last_delta_sync_at': lastDeltaSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateRowsCompanion copyWith({
    Value<String>? companyId,
    Value<String>? entityType,
    Value<int?>? lastUpdatedAt,
    Value<String?>? lastUpdatedId,
    Value<int?>? lastFullSyncAt,
    Value<int?>? lastDeltaSyncAt,
    Value<int>? rowid,
  }) {
    return SyncStateRowsCompanion(
      companyId: companyId ?? this.companyId,
      entityType: entityType ?? this.entityType,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastUpdatedId: lastUpdatedId ?? this.lastUpdatedId,
      lastFullSyncAt: lastFullSyncAt ?? this.lastFullSyncAt,
      lastDeltaSyncAt: lastDeltaSyncAt ?? this.lastDeltaSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<int>(lastUpdatedAt.value);
    }
    if (lastUpdatedId.present) {
      map['last_updated_id'] = Variable<String>(lastUpdatedId.value);
    }
    if (lastFullSyncAt.present) {
      map['last_full_sync_at'] = Variable<int>(lastFullSyncAt.value);
    }
    if (lastDeltaSyncAt.present) {
      map['last_delta_sync_at'] = Variable<int>(lastDeltaSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRowsCompanion(')
          ..write('companyId: $companyId, ')
          ..write('entityType: $entityType, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('lastUpdatedId: $lastUpdatedId, ')
          ..write('lastFullSyncAt: $lastFullSyncAt, ')
          ..write('lastDeltaSyncAt: $lastDeltaSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaticsTable extends Statics with TableInfo<$StaticsTable, StaticsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaticsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payload, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'statics';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaticsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StaticsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaticsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $StaticsTable createAlias(String alias) {
    return $StaticsTable(attachedDatabase, alias);
  }
}

class StaticsRow extends DataClass implements Insertable<StaticsRow> {
  final int id;
  final String payload;
  final int fetchedAt;
  const StaticsRow({
    required this.id,
    required this.payload,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload'] = Variable<String>(payload);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  StaticsCompanion toCompanion(bool nullToAbsent) {
    return StaticsCompanion(
      id: Value(id),
      payload: Value(payload),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory StaticsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaticsRow(
      id: serializer.fromJson<int>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payload': serializer.toJson<String>(payload),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  StaticsRow copyWith({int? id, String? payload, int? fetchedAt}) => StaticsRow(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  StaticsRow copyWithCompanion(StaticsCompanion data) {
    return StaticsRow(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaticsRow(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaticsRow &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.fetchedAt == this.fetchedAt);
}

class StaticsCompanion extends UpdateCompanion<StaticsRow> {
  final Value<int> id;
  final Value<String> payload;
  final Value<int> fetchedAt;
  const StaticsCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  StaticsCompanion.insert({
    this.id = const Value.absent(),
    required String payload,
    required int fetchedAt,
  }) : payload = Value(payload),
       fetchedAt = Value(fetchedAt);
  static Insertable<StaticsRow> custom({
    Expression<int>? id,
    Expression<String>? payload,
    Expression<int>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  StaticsCompanion copyWith({
    Value<int>? id,
    Value<String>? payload,
    Value<int>? fetchedAt,
  }) {
    return StaticsCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaticsCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class $DraftsTable extends Drafts with TableInfo<$DraftsTable, DraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entityType,
    entityId,
    payload,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
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
  Set<GeneratedColumn> get $primaryKey => {entityType, entityId};
  @override
  DraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftRow(
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DraftsTable createAlias(String alias) {
    return $DraftsTable(attachedDatabase, alias);
  }
}

class DraftRow extends DataClass implements Insertable<DraftRow> {
  final String entityType;
  final String entityId;
  final String payload;
  final int updatedAt;
  const DraftRow({
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DraftsCompanion toCompanion(bool nullToAbsent) {
    return DraftsCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory DraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftRow(
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  DraftRow copyWith({
    String? entityType,
    String? entityId,
    String? payload,
    int? updatedAt,
  }) => DraftRow(
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DraftRow copyWithCompanion(DraftsCompanion data) {
    return DraftRow(
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftRow(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityType, entityId, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftRow &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class DraftsCompanion extends UpdateCompanion<DraftRow> {
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> payload;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DraftsCompanion({
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DraftsCompanion.insert({
    required String entityType,
    required String entityId,
    required String payload,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<DraftRow> custom({
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? payload,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DraftsCompanion copyWith({
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? payload,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DraftsCompanion(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftsCompanion(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NavStateTable extends NavState
    with TableInfo<$NavStateTable, NavStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NavStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentRouteMeta = const VerificationMeta(
    'currentRoute',
  );
  @override
  late final GeneratedColumn<String> currentRoute = GeneratedColumn<String>(
    'current_route',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _selectedCompanyIdMeta = const VerificationMeta(
    'selectedCompanyId',
  );
  @override
  late final GeneratedColumn<String> selectedCompanyId =
      GeneratedColumn<String>(
        'selected_company_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filtersJsonMeta = const VerificationMeta(
    'filtersJson',
  );
  @override
  late final GeneratedColumn<String> filtersJson = GeneratedColumn<String>(
    'filters_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currentRoute,
    selectedCompanyId,
    locale,
    themeMode,
    filtersJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nav_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<NavStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current_route')) {
      context.handle(
        _currentRouteMeta,
        currentRoute.isAcceptableOrUnknown(
          data['current_route']!,
          _currentRouteMeta,
        ),
      );
    }
    if (data.containsKey('selected_company_id')) {
      context.handle(
        _selectedCompanyIdMeta,
        selectedCompanyId.isAcceptableOrUnknown(
          data['selected_company_id']!,
          _selectedCompanyIdMeta,
        ),
      );
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('filters_json')) {
      context.handle(
        _filtersJsonMeta,
        filtersJson.isAcceptableOrUnknown(
          data['filters_json']!,
          _filtersJsonMeta,
        ),
      );
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
  NavStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NavStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currentRoute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_route'],
      ),
      selectedCompanyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_company_id'],
      ),
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      ),
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      ),
      filtersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filters_json'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NavStateTable createAlias(String alias) {
    return $NavStateTable(attachedDatabase, alias);
  }
}

class NavStateData extends DataClass implements Insertable<NavStateData> {
  final int id;
  final String? currentRoute;
  final String? selectedCompanyId;
  final String? locale;
  final String? themeMode;
  final String? filtersJson;
  final int updatedAt;
  const NavStateData({
    required this.id,
    this.currentRoute,
    this.selectedCompanyId,
    this.locale,
    this.themeMode,
    this.filtersJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || currentRoute != null) {
      map['current_route'] = Variable<String>(currentRoute);
    }
    if (!nullToAbsent || selectedCompanyId != null) {
      map['selected_company_id'] = Variable<String>(selectedCompanyId);
    }
    if (!nullToAbsent || locale != null) {
      map['locale'] = Variable<String>(locale);
    }
    if (!nullToAbsent || themeMode != null) {
      map['theme_mode'] = Variable<String>(themeMode);
    }
    if (!nullToAbsent || filtersJson != null) {
      map['filters_json'] = Variable<String>(filtersJson);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  NavStateCompanion toCompanion(bool nullToAbsent) {
    return NavStateCompanion(
      id: Value(id),
      currentRoute: currentRoute == null && nullToAbsent
          ? const Value.absent()
          : Value(currentRoute),
      selectedCompanyId: selectedCompanyId == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedCompanyId),
      locale: locale == null && nullToAbsent
          ? const Value.absent()
          : Value(locale),
      themeMode: themeMode == null && nullToAbsent
          ? const Value.absent()
          : Value(themeMode),
      filtersJson: filtersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(filtersJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory NavStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NavStateData(
      id: serializer.fromJson<int>(json['id']),
      currentRoute: serializer.fromJson<String?>(json['currentRoute']),
      selectedCompanyId: serializer.fromJson<String?>(
        json['selectedCompanyId'],
      ),
      locale: serializer.fromJson<String?>(json['locale']),
      themeMode: serializer.fromJson<String?>(json['themeMode']),
      filtersJson: serializer.fromJson<String?>(json['filtersJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentRoute': serializer.toJson<String?>(currentRoute),
      'selectedCompanyId': serializer.toJson<String?>(selectedCompanyId),
      'locale': serializer.toJson<String?>(locale),
      'themeMode': serializer.toJson<String?>(themeMode),
      'filtersJson': serializer.toJson<String?>(filtersJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  NavStateData copyWith({
    int? id,
    Value<String?> currentRoute = const Value.absent(),
    Value<String?> selectedCompanyId = const Value.absent(),
    Value<String?> locale = const Value.absent(),
    Value<String?> themeMode = const Value.absent(),
    Value<String?> filtersJson = const Value.absent(),
    int? updatedAt,
  }) => NavStateData(
    id: id ?? this.id,
    currentRoute: currentRoute.present ? currentRoute.value : this.currentRoute,
    selectedCompanyId: selectedCompanyId.present
        ? selectedCompanyId.value
        : this.selectedCompanyId,
    locale: locale.present ? locale.value : this.locale,
    themeMode: themeMode.present ? themeMode.value : this.themeMode,
    filtersJson: filtersJson.present ? filtersJson.value : this.filtersJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NavStateData copyWithCompanion(NavStateCompanion data) {
    return NavStateData(
      id: data.id.present ? data.id.value : this.id,
      currentRoute: data.currentRoute.present
          ? data.currentRoute.value
          : this.currentRoute,
      selectedCompanyId: data.selectedCompanyId.present
          ? data.selectedCompanyId.value
          : this.selectedCompanyId,
      locale: data.locale.present ? data.locale.value : this.locale,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      filtersJson: data.filtersJson.present
          ? data.filtersJson.value
          : this.filtersJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NavStateData(')
          ..write('id: $id, ')
          ..write('currentRoute: $currentRoute, ')
          ..write('selectedCompanyId: $selectedCompanyId, ')
          ..write('locale: $locale, ')
          ..write('themeMode: $themeMode, ')
          ..write('filtersJson: $filtersJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    currentRoute,
    selectedCompanyId,
    locale,
    themeMode,
    filtersJson,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NavStateData &&
          other.id == this.id &&
          other.currentRoute == this.currentRoute &&
          other.selectedCompanyId == this.selectedCompanyId &&
          other.locale == this.locale &&
          other.themeMode == this.themeMode &&
          other.filtersJson == this.filtersJson &&
          other.updatedAt == this.updatedAt);
}

class NavStateCompanion extends UpdateCompanion<NavStateData> {
  final Value<int> id;
  final Value<String?> currentRoute;
  final Value<String?> selectedCompanyId;
  final Value<String?> locale;
  final Value<String?> themeMode;
  final Value<String?> filtersJson;
  final Value<int> updatedAt;
  const NavStateCompanion({
    this.id = const Value.absent(),
    this.currentRoute = const Value.absent(),
    this.selectedCompanyId = const Value.absent(),
    this.locale = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.filtersJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NavStateCompanion.insert({
    this.id = const Value.absent(),
    this.currentRoute = const Value.absent(),
    this.selectedCompanyId = const Value.absent(),
    this.locale = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.filtersJson = const Value.absent(),
    required int updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<NavStateData> custom({
    Expression<int>? id,
    Expression<String>? currentRoute,
    Expression<String>? selectedCompanyId,
    Expression<String>? locale,
    Expression<String>? themeMode,
    Expression<String>? filtersJson,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentRoute != null) 'current_route': currentRoute,
      if (selectedCompanyId != null) 'selected_company_id': selectedCompanyId,
      if (locale != null) 'locale': locale,
      if (themeMode != null) 'theme_mode': themeMode,
      if (filtersJson != null) 'filters_json': filtersJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NavStateCompanion copyWith({
    Value<int>? id,
    Value<String?>? currentRoute,
    Value<String?>? selectedCompanyId,
    Value<String?>? locale,
    Value<String?>? themeMode,
    Value<String?>? filtersJson,
    Value<int>? updatedAt,
  }) {
    return NavStateCompanion(
      id: id ?? this.id,
      currentRoute: currentRoute ?? this.currentRoute,
      selectedCompanyId: selectedCompanyId ?? this.selectedCompanyId,
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      filtersJson: filtersJson ?? this.filtersJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currentRoute.present) {
      map['current_route'] = Variable<String>(currentRoute.value);
    }
    if (selectedCompanyId.present) {
      map['selected_company_id'] = Variable<String>(selectedCompanyId.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (filtersJson.present) {
      map['filters_json'] = Variable<String>(filtersJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NavStateCompanion(')
          ..write('id: $id, ')
          ..write('currentRoute: $currentRoute, ')
          ..write('selectedCompanyId: $selectedCompanyId, ')
          ..write('locale: $locale, ')
          ..write('themeMode: $themeMode, ')
          ..write('filtersJson: $filtersJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CompaniesTable extends Companies
    with TableInfo<$CompaniesTable, CompanyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompaniesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _settingsMeta = const VerificationMeta(
    'settings',
  );
  @override
  late final GeneratedColumn<String> settings = GeneratedColumn<String>(
    'settings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionsMeta = const VerificationMeta(
    'permissions',
  );
  @override
  late final GeneratedColumn<String> permissions = GeneratedColumn<String>(
    'permissions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  @override
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAdminMeta = const VerificationMeta(
    'isAdmin',
  );
  @override
  late final GeneratedColumn<bool> isAdmin = GeneratedColumn<bool>(
    'is_admin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_admin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isOwnerMeta = const VerificationMeta(
    'isOwner',
  );
  @override
  late final GeneratedColumn<bool> isOwner = GeneratedColumn<bool>(
    'is_owner',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_owner" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    displayName,
    settings,
    permissions,
    accountId,
    token,
    isAdmin,
    isOwner,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'companies';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompanyRow> instance, {
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
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('settings')) {
      context.handle(
        _settingsMeta,
        settings.isAcceptableOrUnknown(data['settings']!, _settingsMeta),
      );
    } else if (isInserting) {
      context.missing(_settingsMeta);
    }
    if (data.containsKey('permissions')) {
      context.handle(
        _permissionsMeta,
        permissions.isAcceptableOrUnknown(
          data['permissions']!,
          _permissionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_permissionsMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenMeta);
    }
    if (data.containsKey('is_admin')) {
      context.handle(
        _isAdminMeta,
        isAdmin.isAcceptableOrUnknown(data['is_admin']!, _isAdminMeta),
      );
    }
    if (data.containsKey('is_owner')) {
      context.handle(
        _isOwnerMeta,
        isOwner.isAcceptableOrUnknown(data['is_owner']!, _isOwnerMeta),
      );
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
  CompanyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompanyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      settings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings'],
      )!,
      permissions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permissions'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      )!,
      isAdmin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_admin'],
      )!,
      isOwner: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_owner'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CompaniesTable createAlias(String alias) {
    return $CompaniesTable(attachedDatabase, alias);
  }
}

class CompanyRow extends DataClass implements Insertable<CompanyRow> {
  final String id;
  final String name;
  final String? displayName;
  final String settings;
  final String permissions;
  final String accountId;
  final String token;
  final bool isAdmin;
  final bool isOwner;
  final int updatedAt;
  const CompanyRow({
    required this.id,
    required this.name,
    this.displayName,
    required this.settings,
    required this.permissions,
    required this.accountId,
    required this.token,
    required this.isAdmin,
    required this.isOwner,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['settings'] = Variable<String>(settings);
    map['permissions'] = Variable<String>(permissions);
    map['account_id'] = Variable<String>(accountId);
    map['token'] = Variable<String>(token);
    map['is_admin'] = Variable<bool>(isAdmin);
    map['is_owner'] = Variable<bool>(isOwner);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CompaniesCompanion toCompanion(bool nullToAbsent) {
    return CompaniesCompanion(
      id: Value(id),
      name: Value(name),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      settings: Value(settings),
      permissions: Value(permissions),
      accountId: Value(accountId),
      token: Value(token),
      isAdmin: Value(isAdmin),
      isOwner: Value(isOwner),
      updatedAt: Value(updatedAt),
    );
  }

  factory CompanyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompanyRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      settings: serializer.fromJson<String>(json['settings']),
      permissions: serializer.fromJson<String>(json['permissions']),
      accountId: serializer.fromJson<String>(json['accountId']),
      token: serializer.fromJson<String>(json['token']),
      isAdmin: serializer.fromJson<bool>(json['isAdmin']),
      isOwner: serializer.fromJson<bool>(json['isOwner']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String?>(displayName),
      'settings': serializer.toJson<String>(settings),
      'permissions': serializer.toJson<String>(permissions),
      'accountId': serializer.toJson<String>(accountId),
      'token': serializer.toJson<String>(token),
      'isAdmin': serializer.toJson<bool>(isAdmin),
      'isOwner': serializer.toJson<bool>(isOwner),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CompanyRow copyWith({
    String? id,
    String? name,
    Value<String?> displayName = const Value.absent(),
    String? settings,
    String? permissions,
    String? accountId,
    String? token,
    bool? isAdmin,
    bool? isOwner,
    int? updatedAt,
  }) => CompanyRow(
    id: id ?? this.id,
    name: name ?? this.name,
    displayName: displayName.present ? displayName.value : this.displayName,
    settings: settings ?? this.settings,
    permissions: permissions ?? this.permissions,
    accountId: accountId ?? this.accountId,
    token: token ?? this.token,
    isAdmin: isAdmin ?? this.isAdmin,
    isOwner: isOwner ?? this.isOwner,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CompanyRow copyWithCompanion(CompaniesCompanion data) {
    return CompanyRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      settings: data.settings.present ? data.settings.value : this.settings,
      permissions: data.permissions.present
          ? data.permissions.value
          : this.permissions,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      token: data.token.present ? data.token.value : this.token,
      isAdmin: data.isAdmin.present ? data.isAdmin.value : this.isAdmin,
      isOwner: data.isOwner.present ? data.isOwner.value : this.isOwner,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompanyRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('settings: $settings, ')
          ..write('permissions: $permissions, ')
          ..write('accountId: $accountId, ')
          ..write('token: $token, ')
          ..write('isAdmin: $isAdmin, ')
          ..write('isOwner: $isOwner, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    displayName,
    settings,
    permissions,
    accountId,
    token,
    isAdmin,
    isOwner,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompanyRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.settings == this.settings &&
          other.permissions == this.permissions &&
          other.accountId == this.accountId &&
          other.token == this.token &&
          other.isAdmin == this.isAdmin &&
          other.isOwner == this.isOwner &&
          other.updatedAt == this.updatedAt);
}

class CompaniesCompanion extends UpdateCompanion<CompanyRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> displayName;
  final Value<String> settings;
  final Value<String> permissions;
  final Value<String> accountId;
  final Value<String> token;
  final Value<bool> isAdmin;
  final Value<bool> isOwner;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CompaniesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.settings = const Value.absent(),
    this.permissions = const Value.absent(),
    this.accountId = const Value.absent(),
    this.token = const Value.absent(),
    this.isAdmin = const Value.absent(),
    this.isOwner = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompaniesCompanion.insert({
    required String id,
    required String name,
    this.displayName = const Value.absent(),
    required String settings,
    required String permissions,
    required String accountId,
    required String token,
    this.isAdmin = const Value.absent(),
    this.isOwner = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       settings = Value(settings),
       permissions = Value(permissions),
       accountId = Value(accountId),
       token = Value(token),
       updatedAt = Value(updatedAt);
  static Insertable<CompanyRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? settings,
    Expression<String>? permissions,
    Expression<String>? accountId,
    Expression<String>? token,
    Expression<bool>? isAdmin,
    Expression<bool>? isOwner,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (settings != null) 'settings': settings,
      if (permissions != null) 'permissions': permissions,
      if (accountId != null) 'account_id': accountId,
      if (token != null) 'token': token,
      if (isAdmin != null) 'is_admin': isAdmin,
      if (isOwner != null) 'is_owner': isOwner,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompaniesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? displayName,
    Value<String>? settings,
    Value<String>? permissions,
    Value<String>? accountId,
    Value<String>? token,
    Value<bool>? isAdmin,
    Value<bool>? isOwner,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return CompaniesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      settings: settings ?? this.settings,
      permissions: permissions ?? this.permissions,
      accountId: accountId ?? this.accountId,
      token: token ?? this.token,
      isAdmin: isAdmin ?? this.isAdmin,
      isOwner: isOwner ?? this.isOwner,
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
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (settings.present) {
      map['settings'] = Variable<String>(settings.value);
    }
    if (permissions.present) {
      map['permissions'] = Variable<String>(permissions.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (isAdmin.present) {
      map['is_admin'] = Variable<bool>(isAdmin.value);
    }
    if (isOwner.present) {
      map['is_owner'] = Variable<bool>(isOwner.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompaniesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('settings: $settings, ')
          ..write('permissions: $permissions, ')
          ..write('accountId: $accountId, ')
          ..write('token: $token, ')
          ..write('isAdmin: $isAdmin, ')
          ..write('isOwner: $isOwner, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
    'plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numTrialDaysMeta = const VerificationMeta(
    'numTrialDays',
  );
  @override
  late final GeneratedColumn<int> numTrialDays = GeneratedColumn<int>(
    'num_trial_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isHostedMeta = const VerificationMeta(
    'isHosted',
  );
  @override
  late final GeneratedColumn<bool> isHosted = GeneratedColumn<bool>(
    'is_hosted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hosted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _defaultCompanyIdMeta = const VerificationMeta(
    'defaultCompanyId',
  );
  @override
  late final GeneratedColumn<String> defaultCompanyId = GeneratedColumn<String>(
    'default_company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _featuresJsonMeta = const VerificationMeta(
    'featuresJson',
  );
  @override
  late final GeneratedColumn<String> featuresJson = GeneratedColumn<String>(
    'features_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    plan,
    numTrialDays,
    isHosted,
    defaultCompanyId,
    featuresJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('plan')) {
      context.handle(
        _planMeta,
        plan.isAcceptableOrUnknown(data['plan']!, _planMeta),
      );
    } else if (isInserting) {
      context.missing(_planMeta);
    }
    if (data.containsKey('num_trial_days')) {
      context.handle(
        _numTrialDaysMeta,
        numTrialDays.isAcceptableOrUnknown(
          data['num_trial_days']!,
          _numTrialDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_numTrialDaysMeta);
    }
    if (data.containsKey('is_hosted')) {
      context.handle(
        _isHostedMeta,
        isHosted.isAcceptableOrUnknown(data['is_hosted']!, _isHostedMeta),
      );
    }
    if (data.containsKey('default_company_id')) {
      context.handle(
        _defaultCompanyIdMeta,
        defaultCompanyId.isAcceptableOrUnknown(
          data['default_company_id']!,
          _defaultCompanyIdMeta,
        ),
      );
    }
    if (data.containsKey('features_json')) {
      context.handle(
        _featuresJsonMeta,
        featuresJson.isAcceptableOrUnknown(
          data['features_json']!,
          _featuresJsonMeta,
        ),
      );
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
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      plan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan'],
      )!,
      numTrialDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}num_trial_days'],
      )!,
      isHosted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hosted'],
      )!,
      defaultCompanyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_company_id'],
      ),
      featuresJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}features_json'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final String id;
  final String email;
  final String plan;
  final int numTrialDays;
  final bool isHosted;
  final String? defaultCompanyId;
  final String? featuresJson;
  final int updatedAt;
  const AccountRow({
    required this.id,
    required this.email,
    required this.plan,
    required this.numTrialDays,
    required this.isHosted,
    this.defaultCompanyId,
    this.featuresJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['plan'] = Variable<String>(plan);
    map['num_trial_days'] = Variable<int>(numTrialDays);
    map['is_hosted'] = Variable<bool>(isHosted);
    if (!nullToAbsent || defaultCompanyId != null) {
      map['default_company_id'] = Variable<String>(defaultCompanyId);
    }
    if (!nullToAbsent || featuresJson != null) {
      map['features_json'] = Variable<String>(featuresJson);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      email: Value(email),
      plan: Value(plan),
      numTrialDays: Value(numTrialDays),
      isHosted: Value(isHosted),
      defaultCompanyId: defaultCompanyId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultCompanyId),
      featuresJson: featuresJson == null && nullToAbsent
          ? const Value.absent()
          : Value(featuresJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      plan: serializer.fromJson<String>(json['plan']),
      numTrialDays: serializer.fromJson<int>(json['numTrialDays']),
      isHosted: serializer.fromJson<bool>(json['isHosted']),
      defaultCompanyId: serializer.fromJson<String?>(json['defaultCompanyId']),
      featuresJson: serializer.fromJson<String?>(json['featuresJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'plan': serializer.toJson<String>(plan),
      'numTrialDays': serializer.toJson<int>(numTrialDays),
      'isHosted': serializer.toJson<bool>(isHosted),
      'defaultCompanyId': serializer.toJson<String?>(defaultCompanyId),
      'featuresJson': serializer.toJson<String?>(featuresJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AccountRow copyWith({
    String? id,
    String? email,
    String? plan,
    int? numTrialDays,
    bool? isHosted,
    Value<String?> defaultCompanyId = const Value.absent(),
    Value<String?> featuresJson = const Value.absent(),
    int? updatedAt,
  }) => AccountRow(
    id: id ?? this.id,
    email: email ?? this.email,
    plan: plan ?? this.plan,
    numTrialDays: numTrialDays ?? this.numTrialDays,
    isHosted: isHosted ?? this.isHosted,
    defaultCompanyId: defaultCompanyId.present
        ? defaultCompanyId.value
        : this.defaultCompanyId,
    featuresJson: featuresJson.present ? featuresJson.value : this.featuresJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      plan: data.plan.present ? data.plan.value : this.plan,
      numTrialDays: data.numTrialDays.present
          ? data.numTrialDays.value
          : this.numTrialDays,
      isHosted: data.isHosted.present ? data.isHosted.value : this.isHosted,
      defaultCompanyId: data.defaultCompanyId.present
          ? data.defaultCompanyId.value
          : this.defaultCompanyId,
      featuresJson: data.featuresJson.present
          ? data.featuresJson.value
          : this.featuresJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('plan: $plan, ')
          ..write('numTrialDays: $numTrialDays, ')
          ..write('isHosted: $isHosted, ')
          ..write('defaultCompanyId: $defaultCompanyId, ')
          ..write('featuresJson: $featuresJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    plan,
    numTrialDays,
    isHosted,
    defaultCompanyId,
    featuresJson,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.email == this.email &&
          other.plan == this.plan &&
          other.numTrialDays == this.numTrialDays &&
          other.isHosted == this.isHosted &&
          other.defaultCompanyId == this.defaultCompanyId &&
          other.featuresJson == this.featuresJson &&
          other.updatedAt == this.updatedAt);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> plan;
  final Value<int> numTrialDays;
  final Value<bool> isHosted;
  final Value<String?> defaultCompanyId;
  final Value<String?> featuresJson;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.plan = const Value.absent(),
    this.numTrialDays = const Value.absent(),
    this.isHosted = const Value.absent(),
    this.defaultCompanyId = const Value.absent(),
    this.featuresJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String email,
    required String plan,
    required int numTrialDays,
    this.isHosted = const Value.absent(),
    this.defaultCompanyId = const Value.absent(),
    this.featuresJson = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       email = Value(email),
       plan = Value(plan),
       numTrialDays = Value(numTrialDays),
       updatedAt = Value(updatedAt);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? plan,
    Expression<int>? numTrialDays,
    Expression<bool>? isHosted,
    Expression<String>? defaultCompanyId,
    Expression<String>? featuresJson,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (plan != null) 'plan': plan,
      if (numTrialDays != null) 'num_trial_days': numTrialDays,
      if (isHosted != null) 'is_hosted': isHosted,
      if (defaultCompanyId != null) 'default_company_id': defaultCompanyId,
      if (featuresJson != null) 'features_json': featuresJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String>? plan,
    Value<int>? numTrialDays,
    Value<bool>? isHosted,
    Value<String?>? defaultCompanyId,
    Value<String?>? featuresJson,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      plan: plan ?? this.plan,
      numTrialDays: numTrialDays ?? this.numTrialDays,
      isHosted: isHosted ?? this.isHosted,
      defaultCompanyId: defaultCompanyId ?? this.defaultCompanyId,
      featuresJson: featuresJson ?? this.featuresJson,
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
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    if (numTrialDays.present) {
      map['num_trial_days'] = Variable<int>(numTrialDays.value);
    }
    if (isHosted.present) {
      map['is_hosted'] = Variable<bool>(isHosted.value);
    }
    if (defaultCompanyId.present) {
      map['default_company_id'] = Variable<String>(defaultCompanyId.value);
    }
    if (featuresJson.present) {
      map['features_json'] = Variable<String>(featuresJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('plan: $plan, ')
          ..write('numTrialDays: $numTrialDays, ')
          ..write('isHosted: $isHosted, ')
          ..write('defaultCompanyId: $defaultCompanyId, ')
          ..write('featuresJson: $featuresJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverUrlMeta = const VerificationMeta(
    'serverUrl',
  );
  @override
  late final GeneratedColumn<String> serverUrl = GeneratedColumn<String>(
    'server_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadStateMeta = const VerificationMeta(
    'uploadState',
  );
  @override
  late final GeneratedColumn<String> uploadState = GeneratedColumn<String>(
    'upload_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    entityType,
    entityId,
    localPath,
    serverUrl,
    mimeType,
    size,
    uploadState,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('server_url')) {
      context.handle(
        _serverUrlMeta,
        serverUrl.isAcceptableOrUnknown(data['server_url']!, _serverUrlMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('upload_state')) {
      context.handle(
        _uploadStateMeta,
        uploadState.isAcceptableOrUnknown(
          data['upload_state']!,
          _uploadStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_uploadStateMeta);
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
  DocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      serverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_url'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      uploadState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class DocumentRow extends DataClass implements Insertable<DocumentRow> {
  final String id;
  final String companyId;
  final String entityType;
  final String entityId;
  final String? localPath;
  final String? serverUrl;
  final String mimeType;
  final int size;
  final String uploadState;
  final int createdAt;
  const DocumentRow({
    required this.id,
    required this.companyId,
    required this.entityType,
    required this.entityId,
    this.localPath,
    this.serverUrl,
    required this.mimeType,
    required this.size,
    required this.uploadState,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || serverUrl != null) {
      map['server_url'] = Variable<String>(serverUrl);
    }
    map['mime_type'] = Variable<String>(mimeType);
    map['size'] = Variable<int>(size);
    map['upload_state'] = Variable<String>(uploadState);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      companyId: Value(companyId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      serverUrl: serverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUrl),
      mimeType: Value(mimeType),
      size: Value(size),
      uploadState: Value(uploadState),
      createdAt: Value(createdAt),
    );
  }

  factory DocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRow(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      serverUrl: serializer.fromJson<String?>(json['serverUrl']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      size: serializer.fromJson<int>(json['size']),
      uploadState: serializer.fromJson<String>(json['uploadState']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'localPath': serializer.toJson<String?>(localPath),
      'serverUrl': serializer.toJson<String?>(serverUrl),
      'mimeType': serializer.toJson<String>(mimeType),
      'size': serializer.toJson<int>(size),
      'uploadState': serializer.toJson<String>(uploadState),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  DocumentRow copyWith({
    String? id,
    String? companyId,
    String? entityType,
    String? entityId,
    Value<String?> localPath = const Value.absent(),
    Value<String?> serverUrl = const Value.absent(),
    String? mimeType,
    int? size,
    String? uploadState,
    int? createdAt,
  }) => DocumentRow(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    localPath: localPath.present ? localPath.value : this.localPath,
    serverUrl: serverUrl.present ? serverUrl.value : this.serverUrl,
    mimeType: mimeType ?? this.mimeType,
    size: size ?? this.size,
    uploadState: uploadState ?? this.uploadState,
    createdAt: createdAt ?? this.createdAt,
  );
  DocumentRow copyWithCompanion(DocumentsCompanion data) {
    return DocumentRow(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      serverUrl: data.serverUrl.present ? data.serverUrl.value : this.serverUrl,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      size: data.size.present ? data.size.value : this.size,
      uploadState: data.uploadState.present
          ? data.uploadState.value
          : this.uploadState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRow(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('localPath: $localPath, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('mimeType: $mimeType, ')
          ..write('size: $size, ')
          ..write('uploadState: $uploadState, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    entityType,
    entityId,
    localPath,
    serverUrl,
    mimeType,
    size,
    uploadState,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.localPath == this.localPath &&
          other.serverUrl == this.serverUrl &&
          other.mimeType == this.mimeType &&
          other.size == this.size &&
          other.uploadState == this.uploadState &&
          other.createdAt == this.createdAt);
}

class DocumentsCompanion extends UpdateCompanion<DocumentRow> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String?> localPath;
  final Value<String?> serverUrl;
  final Value<String> mimeType;
  final Value<int> size;
  final Value<String> uploadState;
  final Value<int> createdAt;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.serverUrl = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.size = const Value.absent(),
    this.uploadState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String id,
    required String companyId,
    required String entityType,
    required String entityId,
    this.localPath = const Value.absent(),
    this.serverUrl = const Value.absent(),
    required String mimeType,
    required int size,
    required String uploadState,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       mimeType = Value(mimeType),
       size = Value(size),
       uploadState = Value(uploadState),
       createdAt = Value(createdAt);
  static Insertable<DocumentRow> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? localPath,
    Expression<String>? serverUrl,
    Expression<String>? mimeType,
    Expression<int>? size,
    Expression<String>? uploadState,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (localPath != null) 'local_path': localPath,
      if (serverUrl != null) 'server_url': serverUrl,
      if (mimeType != null) 'mime_type': mimeType,
      if (size != null) 'size': size,
      if (uploadState != null) 'upload_state': uploadState,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String?>? localPath,
    Value<String?>? serverUrl,
    Value<String>? mimeType,
    Value<int>? size,
    Value<String>? uploadState,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      localPath: localPath ?? this.localPath,
      serverUrl: serverUrl ?? this.serverUrl,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      uploadState: uploadState ?? this.uploadState,
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
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (serverUrl.present) {
      map['server_url'] = Variable<String>(serverUrl.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (uploadState.present) {
      map['upload_state'] = Variable<String>(uploadState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('localPath: $localPath, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('mimeType: $mimeType, ')
          ..write('size: $size, ')
          ..write('uploadState: $uploadState, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings
    with TableInfo<$UserSettingsTable, UserSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tableColumnsJsonMeta = const VerificationMeta(
    'tableColumnsJson',
  );
  @override
  late final GeneratedColumn<String> tableColumnsJson = GeneratedColumn<String>(
    'table_columns_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _extraJsonMeta = const VerificationMeta(
    'extraJson',
  );
  @override
  late final GeneratedColumn<String> extraJson = GeneratedColumn<String>(
    'extra_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    companyId,
    userId,
    tableColumnsJson,
    extraJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('table_columns_json')) {
      context.handle(
        _tableColumnsJsonMeta,
        tableColumnsJson.isAcceptableOrUnknown(
          data['table_columns_json']!,
          _tableColumnsJsonMeta,
        ),
      );
    }
    if (data.containsKey('extra_json')) {
      context.handle(
        _extraJsonMeta,
        extraJson.isAcceptableOrUnknown(data['extra_json']!, _extraJsonMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {companyId};
  @override
  UserSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSettingsRow(
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      tableColumnsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_columns_json'],
      )!,
      extraJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }
}

class UserSettingsRow extends DataClass implements Insertable<UserSettingsRow> {
  final String companyId;
  final String userId;
  final String tableColumnsJson;
  final String extraJson;
  final int updatedAt;
  const UserSettingsRow({
    required this.companyId,
    required this.userId,
    required this.tableColumnsJson,
    required this.extraJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['company_id'] = Variable<String>(companyId);
    map['user_id'] = Variable<String>(userId);
    map['table_columns_json'] = Variable<String>(tableColumnsJson);
    map['extra_json'] = Variable<String>(extraJson);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      companyId: Value(companyId),
      userId: Value(userId),
      tableColumnsJson: Value(tableColumnsJson),
      extraJson: Value(extraJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSettingsRow(
      companyId: serializer.fromJson<String>(json['companyId']),
      userId: serializer.fromJson<String>(json['userId']),
      tableColumnsJson: serializer.fromJson<String>(json['tableColumnsJson']),
      extraJson: serializer.fromJson<String>(json['extraJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'companyId': serializer.toJson<String>(companyId),
      'userId': serializer.toJson<String>(userId),
      'tableColumnsJson': serializer.toJson<String>(tableColumnsJson),
      'extraJson': serializer.toJson<String>(extraJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  UserSettingsRow copyWith({
    String? companyId,
    String? userId,
    String? tableColumnsJson,
    String? extraJson,
    int? updatedAt,
  }) => UserSettingsRow(
    companyId: companyId ?? this.companyId,
    userId: userId ?? this.userId,
    tableColumnsJson: tableColumnsJson ?? this.tableColumnsJson,
    extraJson: extraJson ?? this.extraJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserSettingsRow copyWithCompanion(UserSettingsCompanion data) {
    return UserSettingsRow(
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      userId: data.userId.present ? data.userId.value : this.userId,
      tableColumnsJson: data.tableColumnsJson.present
          ? data.tableColumnsJson.value
          : this.tableColumnsJson,
      extraJson: data.extraJson.present ? data.extraJson.value : this.extraJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsRow(')
          ..write('companyId: $companyId, ')
          ..write('userId: $userId, ')
          ..write('tableColumnsJson: $tableColumnsJson, ')
          ..write('extraJson: $extraJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(companyId, userId, tableColumnsJson, extraJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSettingsRow &&
          other.companyId == this.companyId &&
          other.userId == this.userId &&
          other.tableColumnsJson == this.tableColumnsJson &&
          other.extraJson == this.extraJson &&
          other.updatedAt == this.updatedAt);
}

class UserSettingsCompanion extends UpdateCompanion<UserSettingsRow> {
  final Value<String> companyId;
  final Value<String> userId;
  final Value<String> tableColumnsJson;
  final Value<String> extraJson;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const UserSettingsCompanion({
    this.companyId = const Value.absent(),
    this.userId = const Value.absent(),
    this.tableColumnsJson = const Value.absent(),
    this.extraJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    required String companyId,
    required String userId,
    this.tableColumnsJson = const Value.absent(),
    this.extraJson = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : companyId = Value(companyId),
       userId = Value(userId),
       updatedAt = Value(updatedAt);
  static Insertable<UserSettingsRow> custom({
    Expression<String>? companyId,
    Expression<String>? userId,
    Expression<String>? tableColumnsJson,
    Expression<String>? extraJson,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (companyId != null) 'company_id': companyId,
      if (userId != null) 'user_id': userId,
      if (tableColumnsJson != null) 'table_columns_json': tableColumnsJson,
      if (extraJson != null) 'extra_json': extraJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserSettingsCompanion copyWith({
    Value<String>? companyId,
    Value<String>? userId,
    Value<String>? tableColumnsJson,
    Value<String>? extraJson,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserSettingsCompanion(
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      tableColumnsJson: tableColumnsJson ?? this.tableColumnsJson,
      extraJson: extraJson ?? this.extraJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (tableColumnsJson.present) {
      map['table_columns_json'] = Variable<String>(tableColumnsJson.value);
    }
    if (extraJson.present) {
      map['extra_json'] = Variable<String>(extraJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('companyId: $companyId, ')
          ..write('userId: $userId, ')
          ..write('tableColumnsJson: $tableColumnsJson, ')
          ..write('extraJson: $extraJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DashboardCacheTable extends DashboardCache
    with TableInfo<$DashboardCacheTable, DashboardCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DashboardCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filterHashMeta = const VerificationMeta(
    'filterHash',
  );
  @override
  late final GeneratedColumn<String> filterHash = GeneratedColumn<String>(
    'filter_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    companyId,
    kind,
    filterHash,
    payload,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dashboard_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<DashboardCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('filter_hash')) {
      context.handle(
        _filterHashMeta,
        filterHash.isAcceptableOrUnknown(data['filter_hash']!, _filterHashMeta),
      );
    } else if (isInserting) {
      context.missing(_filterHashMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
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
  Set<GeneratedColumn> get $primaryKey => {companyId, kind, filterHash};
  @override
  DashboardCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DashboardCacheRow(
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      filterHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_hash'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $DashboardCacheTable createAlias(String alias) {
    return $DashboardCacheTable(attachedDatabase, alias);
  }
}

class DashboardCacheRow extends DataClass
    implements Insertable<DashboardCacheRow> {
  final String companyId;
  final String kind;
  final String filterHash;
  final String payload;
  final int fetchedAt;
  const DashboardCacheRow({
    required this.companyId,
    required this.kind,
    required this.filterHash,
    required this.payload,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['company_id'] = Variable<String>(companyId);
    map['kind'] = Variable<String>(kind);
    map['filter_hash'] = Variable<String>(filterHash);
    map['payload'] = Variable<String>(payload);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  DashboardCacheCompanion toCompanion(bool nullToAbsent) {
    return DashboardCacheCompanion(
      companyId: Value(companyId),
      kind: Value(kind),
      filterHash: Value(filterHash),
      payload: Value(payload),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory DashboardCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DashboardCacheRow(
      companyId: serializer.fromJson<String>(json['companyId']),
      kind: serializer.fromJson<String>(json['kind']),
      filterHash: serializer.fromJson<String>(json['filterHash']),
      payload: serializer.fromJson<String>(json['payload']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'companyId': serializer.toJson<String>(companyId),
      'kind': serializer.toJson<String>(kind),
      'filterHash': serializer.toJson<String>(filterHash),
      'payload': serializer.toJson<String>(payload),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  DashboardCacheRow copyWith({
    String? companyId,
    String? kind,
    String? filterHash,
    String? payload,
    int? fetchedAt,
  }) => DashboardCacheRow(
    companyId: companyId ?? this.companyId,
    kind: kind ?? this.kind,
    filterHash: filterHash ?? this.filterHash,
    payload: payload ?? this.payload,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  DashboardCacheRow copyWithCompanion(DashboardCacheCompanion data) {
    return DashboardCacheRow(
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      kind: data.kind.present ? data.kind.value : this.kind,
      filterHash: data.filterHash.present
          ? data.filterHash.value
          : this.filterHash,
      payload: data.payload.present ? data.payload.value : this.payload,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DashboardCacheRow(')
          ..write('companyId: $companyId, ')
          ..write('kind: $kind, ')
          ..write('filterHash: $filterHash, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(companyId, kind, filterHash, payload, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DashboardCacheRow &&
          other.companyId == this.companyId &&
          other.kind == this.kind &&
          other.filterHash == this.filterHash &&
          other.payload == this.payload &&
          other.fetchedAt == this.fetchedAt);
}

class DashboardCacheCompanion extends UpdateCompanion<DashboardCacheRow> {
  final Value<String> companyId;
  final Value<String> kind;
  final Value<String> filterHash;
  final Value<String> payload;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const DashboardCacheCompanion({
    this.companyId = const Value.absent(),
    this.kind = const Value.absent(),
    this.filterHash = const Value.absent(),
    this.payload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DashboardCacheCompanion.insert({
    required String companyId,
    required String kind,
    required String filterHash,
    required String payload,
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : companyId = Value(companyId),
       kind = Value(kind),
       filterHash = Value(filterHash),
       payload = Value(payload),
       fetchedAt = Value(fetchedAt);
  static Insertable<DashboardCacheRow> custom({
    Expression<String>? companyId,
    Expression<String>? kind,
    Expression<String>? filterHash,
    Expression<String>? payload,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (companyId != null) 'company_id': companyId,
      if (kind != null) 'kind': kind,
      if (filterHash != null) 'filter_hash': filterHash,
      if (payload != null) 'payload': payload,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DashboardCacheCompanion copyWith({
    Value<String>? companyId,
    Value<String>? kind,
    Value<String>? filterHash,
    Value<String>? payload,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return DashboardCacheCompanion(
      companyId: companyId ?? this.companyId,
      kind: kind ?? this.kind,
      filterHash: filterHash ?? this.filterHash,
      payload: payload ?? this.payload,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (filterHash.present) {
      map['filter_hash'] = Variable<String>(filterHash.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DashboardCacheCompanion(')
          ..write('companyId: $companyId, ')
          ..write('kind: $kind, ')
          ..write('filterHash: $filterHash, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ClientsTable clients = $ClientsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $IdRemapTable idRemap = $IdRemapTable(this);
  late final $SyncStateRowsTable syncStateRows = $SyncStateRowsTable(this);
  late final $StaticsTable statics = $StaticsTable(this);
  late final $DraftsTable drafts = $DraftsTable(this);
  late final $NavStateTable navState = $NavStateTable(this);
  late final $CompaniesTable companies = $CompaniesTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  late final $DashboardCacheTable dashboardCache = $DashboardCacheTable(this);
  late final ClientDao clientDao = ClientDao(this as AppDatabase);
  late final OutboxDao outboxDao = OutboxDao(this as AppDatabase);
  late final IdRemapDao idRemapDao = IdRemapDao(this as AppDatabase);
  late final SyncStateDao syncStateDao = SyncStateDao(this as AppDatabase);
  late final StaticsDao staticsDao = StaticsDao(this as AppDatabase);
  late final DraftsDao draftsDao = DraftsDao(this as AppDatabase);
  late final NavStateDao navStateDao = NavStateDao(this as AppDatabase);
  late final CompaniesDao companiesDao = CompaniesDao(this as AppDatabase);
  late final UserSettingsDao userSettingsDao = UserSettingsDao(
    this as AppDatabase,
  );
  late final DashboardCacheDao dashboardCacheDao = DashboardCacheDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    clients,
    outbox,
    idRemap,
    syncStateRows,
    statics,
    drafts,
    navState,
    companies,
    accounts,
    documents,
    userSettings,
    dashboardCache,
  ];
}

typedef $$ClientsTableCreateCompanionBuilder =
    ClientsCompanion Function({
      required String id,
      required String companyId,
      Value<String?> tempId,
      required String name,
      required String number,
      required String email,
      required String displayName,
      required String balance,
      required int updatedAt,
      Value<int> createdAt,
      Value<int?> archivedAt,
      Value<String> customValue1,
      Value<String> customValue2,
      Value<String> customValue3,
      Value<String> customValue4,
      Value<bool> isDirty,
      Value<bool> isDeleted,
      required String payload,
      Value<int> rowid,
    });
typedef $$ClientsTableUpdateCompanionBuilder =
    ClientsCompanion Function({
      Value<String> id,
      Value<String> companyId,
      Value<String?> tempId,
      Value<String> name,
      Value<String> number,
      Value<String> email,
      Value<String> displayName,
      Value<String> balance,
      Value<int> updatedAt,
      Value<int> createdAt,
      Value<int?> archivedAt,
      Value<String> customValue1,
      Value<String> customValue2,
      Value<String> customValue3,
      Value<String> customValue4,
      Value<bool> isDirty,
      Value<bool> isDeleted,
      Value<String> payload,
      Value<int> rowid,
    });

class $$ClientsTableFilterComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableFilterComposer({
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

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customValue1 => $composableBuilder(
    column: $table.customValue1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customValue2 => $composableBuilder(
    column: $table.customValue2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customValue3 => $composableBuilder(
    column: $table.customValue3,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customValue4 => $composableBuilder(
    column: $table.customValue4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableOrderingComposer({
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

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customValue1 => $composableBuilder(
    column: $table.customValue1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customValue2 => $composableBuilder(
    column: $table.customValue2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customValue3 => $composableBuilder(
    column: $table.customValue3,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customValue4 => $composableBuilder(
    column: $table.customValue4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get tempId =>
      $composableBuilder(column: $table.tempId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customValue1 => $composableBuilder(
    column: $table.customValue1,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customValue2 => $composableBuilder(
    column: $table.customValue2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customValue3 => $composableBuilder(
    column: $table.customValue3,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customValue4 => $composableBuilder(
    column: $table.customValue4,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$ClientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientsTable,
          ClientRow,
          $$ClientsTableFilterComposer,
          $$ClientsTableOrderingComposer,
          $$ClientsTableAnnotationComposer,
          $$ClientsTableCreateCompanionBuilder,
          $$ClientsTableUpdateCompanionBuilder,
          (ClientRow, BaseReferences<_$AppDatabase, $ClientsTable, ClientRow>),
          ClientRow,
          PrefetchHooks Function()
        > {
  $$ClientsTableTableManager(_$AppDatabase db, $ClientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String?> tempId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> balance = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<String> customValue1 = const Value.absent(),
                Value<String> customValue2 = const Value.absent(),
                Value<String> customValue3 = const Value.absent(),
                Value<String> customValue4 = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsCompanion(
                id: id,
                companyId: companyId,
                tempId: tempId,
                name: name,
                number: number,
                email: email,
                displayName: displayName,
                balance: balance,
                updatedAt: updatedAt,
                createdAt: createdAt,
                archivedAt: archivedAt,
                customValue1: customValue1,
                customValue2: customValue2,
                customValue3: customValue3,
                customValue4: customValue4,
                isDirty: isDirty,
                isDeleted: isDeleted,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                Value<String?> tempId = const Value.absent(),
                required String name,
                required String number,
                required String email,
                required String displayName,
                required String balance,
                required int updatedAt,
                Value<int> createdAt = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<String> customValue1 = const Value.absent(),
                Value<String> customValue2 = const Value.absent(),
                Value<String> customValue3 = const Value.absent(),
                Value<String> customValue4 = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => ClientsCompanion.insert(
                id: id,
                companyId: companyId,
                tempId: tempId,
                name: name,
                number: number,
                email: email,
                displayName: displayName,
                balance: balance,
                updatedAt: updatedAt,
                createdAt: createdAt,
                archivedAt: archivedAt,
                customValue1: customValue1,
                customValue2: customValue2,
                customValue3: customValue3,
                customValue4: customValue4,
                isDirty: isDirty,
                isDeleted: isDeleted,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientsTable,
      ClientRow,
      $$ClientsTableFilterComposer,
      $$ClientsTableOrderingComposer,
      $$ClientsTableAnnotationComposer,
      $$ClientsTableCreateCompanionBuilder,
      $$ClientsTableUpdateCompanionBuilder,
      (ClientRow, BaseReferences<_$AppDatabase, $ClientsTable, ClientRow>),
      ClientRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> id,
      required String companyId,
      required String entityType,
      required String entityId,
      required String mutationKind,
      required String payload,
      required String idempotencyKey,
      Value<int> attempts,
      required int nextAttemptAt,
      Value<String> state,
      Value<String?> lastError,
      Value<int?> lastStatusCode,
      Value<bool> requiresPassword,
      Value<String?> batchId,
      required int createdAt,
    });
typedef $$OutboxTableUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> id,
      Value<String> companyId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> mutationKind,
      Value<String> payload,
      Value<String> idempotencyKey,
      Value<int> attempts,
      Value<int> nextAttemptAt,
      Value<String> state,
      Value<String?> lastError,
      Value<int?> lastStatusCode,
      Value<bool> requiresPassword,
      Value<String?> batchId,
      Value<int> createdAt,
    });

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
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

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutationKind => $composableBuilder(
    column: $table.mutationKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastStatusCode => $composableBuilder(
    column: $table.lastStatusCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiresPassword => $composableBuilder(
    column: $table.requiresPassword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
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

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutationKind => $composableBuilder(
    column: $table.mutationKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastStatusCode => $composableBuilder(
    column: $table.lastStatusCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiresPassword => $composableBuilder(
    column: $table.requiresPassword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get mutationKind => $composableBuilder(
    column: $table.mutationKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get lastStatusCode => $composableBuilder(
    column: $table.lastStatusCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get requiresPassword => $composableBuilder(
    column: $table.requiresPassword,
    builder: (column) => column,
  );

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxRow,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> mutationKind = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int?> lastStatusCode = const Value.absent(),
                Value<bool> requiresPassword = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => OutboxCompanion(
                id: id,
                companyId: companyId,
                entityType: entityType,
                entityId: entityId,
                mutationKind: mutationKind,
                payload: payload,
                idempotencyKey: idempotencyKey,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                state: state,
                lastError: lastError,
                lastStatusCode: lastStatusCode,
                requiresPassword: requiresPassword,
                batchId: batchId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String companyId,
                required String entityType,
                required String entityId,
                required String mutationKind,
                required String payload,
                required String idempotencyKey,
                Value<int> attempts = const Value.absent(),
                required int nextAttemptAt,
                Value<String> state = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int?> lastStatusCode = const Value.absent(),
                Value<bool> requiresPassword = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                required int createdAt,
              }) => OutboxCompanion.insert(
                id: id,
                companyId: companyId,
                entityType: entityType,
                entityId: entityId,
                mutationKind: mutationKind,
                payload: payload,
                idempotencyKey: idempotencyKey,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                state: state,
                lastError: lastError,
                lastStatusCode: lastStatusCode,
                requiresPassword: requiresPassword,
                batchId: batchId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxRow,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$IdRemapTableCreateCompanionBuilder =
    IdRemapCompanion Function({
      required String entityType,
      required String tempId,
      required String realId,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$IdRemapTableUpdateCompanionBuilder =
    IdRemapCompanion Function({
      Value<String> entityType,
      Value<String> tempId,
      Value<String> realId,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$IdRemapTableFilterComposer
    extends Composer<_$AppDatabase, $IdRemapTable> {
  $$IdRemapTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get realId => $composableBuilder(
    column: $table.realId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IdRemapTableOrderingComposer
    extends Composer<_$AppDatabase, $IdRemapTable> {
  $$IdRemapTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get realId => $composableBuilder(
    column: $table.realId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IdRemapTableAnnotationComposer
    extends Composer<_$AppDatabase, $IdRemapTable> {
  $$IdRemapTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tempId =>
      $composableBuilder(column: $table.tempId, builder: (column) => column);

  GeneratedColumn<String> get realId =>
      $composableBuilder(column: $table.realId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$IdRemapTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IdRemapTable,
          IdRemapRow,
          $$IdRemapTableFilterComposer,
          $$IdRemapTableOrderingComposer,
          $$IdRemapTableAnnotationComposer,
          $$IdRemapTableCreateCompanionBuilder,
          $$IdRemapTableUpdateCompanionBuilder,
          (
            IdRemapRow,
            BaseReferences<_$AppDatabase, $IdRemapTable, IdRemapRow>,
          ),
          IdRemapRow,
          PrefetchHooks Function()
        > {
  $$IdRemapTableTableManager(_$AppDatabase db, $IdRemapTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdRemapTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdRemapTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdRemapTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityType = const Value.absent(),
                Value<String> tempId = const Value.absent(),
                Value<String> realId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IdRemapCompanion(
                entityType: entityType,
                tempId: tempId,
                realId: realId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityType,
                required String tempId,
                required String realId,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => IdRemapCompanion.insert(
                entityType: entityType,
                tempId: tempId,
                realId: realId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IdRemapTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IdRemapTable,
      IdRemapRow,
      $$IdRemapTableFilterComposer,
      $$IdRemapTableOrderingComposer,
      $$IdRemapTableAnnotationComposer,
      $$IdRemapTableCreateCompanionBuilder,
      $$IdRemapTableUpdateCompanionBuilder,
      (IdRemapRow, BaseReferences<_$AppDatabase, $IdRemapTable, IdRemapRow>),
      IdRemapRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateRowsTableCreateCompanionBuilder =
    SyncStateRowsCompanion Function({
      required String companyId,
      required String entityType,
      Value<int?> lastUpdatedAt,
      Value<String?> lastUpdatedId,
      Value<int?> lastFullSyncAt,
      Value<int?> lastDeltaSyncAt,
      Value<int> rowid,
    });
typedef $$SyncStateRowsTableUpdateCompanionBuilder =
    SyncStateRowsCompanion Function({
      Value<String> companyId,
      Value<String> entityType,
      Value<int?> lastUpdatedAt,
      Value<String?> lastUpdatedId,
      Value<int?> lastFullSyncAt,
      Value<int?> lastDeltaSyncAt,
      Value<int> rowid,
    });

class $$SyncStateRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateRowsTable> {
  $$SyncStateRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastUpdatedId => $composableBuilder(
    column: $table.lastUpdatedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastFullSyncAt => $composableBuilder(
    column: $table.lastFullSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastDeltaSyncAt => $composableBuilder(
    column: $table.lastDeltaSyncAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateRowsTable> {
  $$SyncStateRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastUpdatedId => $composableBuilder(
    column: $table.lastUpdatedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastFullSyncAt => $composableBuilder(
    column: $table.lastFullSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastDeltaSyncAt => $composableBuilder(
    column: $table.lastDeltaSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateRowsTable> {
  $$SyncStateRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastUpdatedId => $composableBuilder(
    column: $table.lastUpdatedId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastFullSyncAt => $composableBuilder(
    column: $table.lastFullSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastDeltaSyncAt => $composableBuilder(
    column: $table.lastDeltaSyncAt,
    builder: (column) => column,
  );
}

class $$SyncStateRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateRowsTable,
          SyncStateRow,
          $$SyncStateRowsTableFilterComposer,
          $$SyncStateRowsTableOrderingComposer,
          $$SyncStateRowsTableAnnotationComposer,
          $$SyncStateRowsTableCreateCompanionBuilder,
          $$SyncStateRowsTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateRowsTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateRowsTableTableManager(_$AppDatabase db, $SyncStateRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> companyId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<int?> lastUpdatedAt = const Value.absent(),
                Value<String?> lastUpdatedId = const Value.absent(),
                Value<int?> lastFullSyncAt = const Value.absent(),
                Value<int?> lastDeltaSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateRowsCompanion(
                companyId: companyId,
                entityType: entityType,
                lastUpdatedAt: lastUpdatedAt,
                lastUpdatedId: lastUpdatedId,
                lastFullSyncAt: lastFullSyncAt,
                lastDeltaSyncAt: lastDeltaSyncAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String companyId,
                required String entityType,
                Value<int?> lastUpdatedAt = const Value.absent(),
                Value<String?> lastUpdatedId = const Value.absent(),
                Value<int?> lastFullSyncAt = const Value.absent(),
                Value<int?> lastDeltaSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateRowsCompanion.insert(
                companyId: companyId,
                entityType: entityType,
                lastUpdatedAt: lastUpdatedAt,
                lastUpdatedId: lastUpdatedId,
                lastFullSyncAt: lastFullSyncAt,
                lastDeltaSyncAt: lastDeltaSyncAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateRowsTable,
      SyncStateRow,
      $$SyncStateRowsTableFilterComposer,
      $$SyncStateRowsTableOrderingComposer,
      $$SyncStateRowsTableAnnotationComposer,
      $$SyncStateRowsTableCreateCompanionBuilder,
      $$SyncStateRowsTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateRowsTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$StaticsTableCreateCompanionBuilder =
    StaticsCompanion Function({
      Value<int> id,
      required String payload,
      required int fetchedAt,
    });
typedef $$StaticsTableUpdateCompanionBuilder =
    StaticsCompanion Function({
      Value<int> id,
      Value<String> payload,
      Value<int> fetchedAt,
    });

class $$StaticsTableFilterComposer
    extends Composer<_$AppDatabase, $StaticsTable> {
  $$StaticsTableFilterComposer({
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

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StaticsTableOrderingComposer
    extends Composer<_$AppDatabase, $StaticsTable> {
  $$StaticsTableOrderingComposer({
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

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StaticsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StaticsTable> {
  $$StaticsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$StaticsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StaticsTable,
          StaticsRow,
          $$StaticsTableFilterComposer,
          $$StaticsTableOrderingComposer,
          $$StaticsTableAnnotationComposer,
          $$StaticsTableCreateCompanionBuilder,
          $$StaticsTableUpdateCompanionBuilder,
          (
            StaticsRow,
            BaseReferences<_$AppDatabase, $StaticsTable, StaticsRow>,
          ),
          StaticsRow,
          PrefetchHooks Function()
        > {
  $$StaticsTableTableManager(_$AppDatabase db, $StaticsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StaticsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StaticsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StaticsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
              }) => StaticsCompanion(
                id: id,
                payload: payload,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String payload,
                required int fetchedAt,
              }) => StaticsCompanion.insert(
                id: id,
                payload: payload,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StaticsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StaticsTable,
      StaticsRow,
      $$StaticsTableFilterComposer,
      $$StaticsTableOrderingComposer,
      $$StaticsTableAnnotationComposer,
      $$StaticsTableCreateCompanionBuilder,
      $$StaticsTableUpdateCompanionBuilder,
      (StaticsRow, BaseReferences<_$AppDatabase, $StaticsTable, StaticsRow>),
      StaticsRow,
      PrefetchHooks Function()
    >;
typedef $$DraftsTableCreateCompanionBuilder =
    DraftsCompanion Function({
      required String entityType,
      required String entityId,
      required String payload,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$DraftsTableUpdateCompanionBuilder =
    DraftsCompanion Function({
      Value<String> entityType,
      Value<String> entityId,
      Value<String> payload,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$DraftsTableFilterComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DraftsTable,
          DraftRow,
          $$DraftsTableFilterComposer,
          $$DraftsTableOrderingComposer,
          $$DraftsTableAnnotationComposer,
          $$DraftsTableCreateCompanionBuilder,
          $$DraftsTableUpdateCompanionBuilder,
          (DraftRow, BaseReferences<_$AppDatabase, $DraftsTable, DraftRow>),
          DraftRow,
          PrefetchHooks Function()
        > {
  $$DraftsTableTableManager(_$AppDatabase db, $DraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftsCompanion(
                entityType: entityType,
                entityId: entityId,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityType,
                required String entityId,
                required String payload,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DraftsCompanion.insert(
                entityType: entityType,
                entityId: entityId,
                payload: payload,
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

typedef $$DraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DraftsTable,
      DraftRow,
      $$DraftsTableFilterComposer,
      $$DraftsTableOrderingComposer,
      $$DraftsTableAnnotationComposer,
      $$DraftsTableCreateCompanionBuilder,
      $$DraftsTableUpdateCompanionBuilder,
      (DraftRow, BaseReferences<_$AppDatabase, $DraftsTable, DraftRow>),
      DraftRow,
      PrefetchHooks Function()
    >;
typedef $$NavStateTableCreateCompanionBuilder =
    NavStateCompanion Function({
      Value<int> id,
      Value<String?> currentRoute,
      Value<String?> selectedCompanyId,
      Value<String?> locale,
      Value<String?> themeMode,
      Value<String?> filtersJson,
      required int updatedAt,
    });
typedef $$NavStateTableUpdateCompanionBuilder =
    NavStateCompanion Function({
      Value<int> id,
      Value<String?> currentRoute,
      Value<String?> selectedCompanyId,
      Value<String?> locale,
      Value<String?> themeMode,
      Value<String?> filtersJson,
      Value<int> updatedAt,
    });

class $$NavStateTableFilterComposer
    extends Composer<_$AppDatabase, $NavStateTable> {
  $$NavStateTableFilterComposer({
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

  ColumnFilters<String> get currentRoute => $composableBuilder(
    column: $table.currentRoute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedCompanyId => $composableBuilder(
    column: $table.selectedCompanyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filtersJson => $composableBuilder(
    column: $table.filtersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NavStateTableOrderingComposer
    extends Composer<_$AppDatabase, $NavStateTable> {
  $$NavStateTableOrderingComposer({
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

  ColumnOrderings<String> get currentRoute => $composableBuilder(
    column: $table.currentRoute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedCompanyId => $composableBuilder(
    column: $table.selectedCompanyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filtersJson => $composableBuilder(
    column: $table.filtersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NavStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $NavStateTable> {
  $$NavStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currentRoute => $composableBuilder(
    column: $table.currentRoute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedCompanyId => $composableBuilder(
    column: $table.selectedCompanyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get filtersJson => $composableBuilder(
    column: $table.filtersJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NavStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NavStateTable,
          NavStateData,
          $$NavStateTableFilterComposer,
          $$NavStateTableOrderingComposer,
          $$NavStateTableAnnotationComposer,
          $$NavStateTableCreateCompanionBuilder,
          $$NavStateTableUpdateCompanionBuilder,
          (
            NavStateData,
            BaseReferences<_$AppDatabase, $NavStateTable, NavStateData>,
          ),
          NavStateData,
          PrefetchHooks Function()
        > {
  $$NavStateTableTableManager(_$AppDatabase db, $NavStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NavStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NavStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NavStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> currentRoute = const Value.absent(),
                Value<String?> selectedCompanyId = const Value.absent(),
                Value<String?> locale = const Value.absent(),
                Value<String?> themeMode = const Value.absent(),
                Value<String?> filtersJson = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => NavStateCompanion(
                id: id,
                currentRoute: currentRoute,
                selectedCompanyId: selectedCompanyId,
                locale: locale,
                themeMode: themeMode,
                filtersJson: filtersJson,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> currentRoute = const Value.absent(),
                Value<String?> selectedCompanyId = const Value.absent(),
                Value<String?> locale = const Value.absent(),
                Value<String?> themeMode = const Value.absent(),
                Value<String?> filtersJson = const Value.absent(),
                required int updatedAt,
              }) => NavStateCompanion.insert(
                id: id,
                currentRoute: currentRoute,
                selectedCompanyId: selectedCompanyId,
                locale: locale,
                themeMode: themeMode,
                filtersJson: filtersJson,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NavStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NavStateTable,
      NavStateData,
      $$NavStateTableFilterComposer,
      $$NavStateTableOrderingComposer,
      $$NavStateTableAnnotationComposer,
      $$NavStateTableCreateCompanionBuilder,
      $$NavStateTableUpdateCompanionBuilder,
      (
        NavStateData,
        BaseReferences<_$AppDatabase, $NavStateTable, NavStateData>,
      ),
      NavStateData,
      PrefetchHooks Function()
    >;
typedef $$CompaniesTableCreateCompanionBuilder =
    CompaniesCompanion Function({
      required String id,
      required String name,
      Value<String?> displayName,
      required String settings,
      required String permissions,
      required String accountId,
      required String token,
      Value<bool> isAdmin,
      Value<bool> isOwner,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$CompaniesTableUpdateCompanionBuilder =
    CompaniesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> displayName,
      Value<String> settings,
      Value<String> permissions,
      Value<String> accountId,
      Value<String> token,
      Value<bool> isAdmin,
      Value<bool> isOwner,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$CompaniesTableFilterComposer
    extends Composer<_$AppDatabase, $CompaniesTable> {
  $$CompaniesTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settings => $composableBuilder(
    column: $table.settings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdmin => $composableBuilder(
    column: $table.isAdmin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOwner => $composableBuilder(
    column: $table.isOwner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompaniesTableOrderingComposer
    extends Composer<_$AppDatabase, $CompaniesTable> {
  $$CompaniesTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settings => $composableBuilder(
    column: $table.settings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdmin => $composableBuilder(
    column: $table.isAdmin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOwner => $composableBuilder(
    column: $table.isOwner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompaniesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompaniesTable> {
  $$CompaniesTableAnnotationComposer({
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

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settings =>
      $composableBuilder(column: $table.settings, builder: (column) => column);

  GeneratedColumn<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get token =>
      $composableBuilder(column: $table.token, builder: (column) => column);

  GeneratedColumn<bool> get isAdmin =>
      $composableBuilder(column: $table.isAdmin, builder: (column) => column);

  GeneratedColumn<bool> get isOwner =>
      $composableBuilder(column: $table.isOwner, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CompaniesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompaniesTable,
          CompanyRow,
          $$CompaniesTableFilterComposer,
          $$CompaniesTableOrderingComposer,
          $$CompaniesTableAnnotationComposer,
          $$CompaniesTableCreateCompanionBuilder,
          $$CompaniesTableUpdateCompanionBuilder,
          (
            CompanyRow,
            BaseReferences<_$AppDatabase, $CompaniesTable, CompanyRow>,
          ),
          CompanyRow,
          PrefetchHooks Function()
        > {
  $$CompaniesTableTableManager(_$AppDatabase db, $CompaniesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompaniesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompaniesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompaniesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String> settings = const Value.absent(),
                Value<String> permissions = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> token = const Value.absent(),
                Value<bool> isAdmin = const Value.absent(),
                Value<bool> isOwner = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompaniesCompanion(
                id: id,
                name: name,
                displayName: displayName,
                settings: settings,
                permissions: permissions,
                accountId: accountId,
                token: token,
                isAdmin: isAdmin,
                isOwner: isOwner,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> displayName = const Value.absent(),
                required String settings,
                required String permissions,
                required String accountId,
                required String token,
                Value<bool> isAdmin = const Value.absent(),
                Value<bool> isOwner = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CompaniesCompanion.insert(
                id: id,
                name: name,
                displayName: displayName,
                settings: settings,
                permissions: permissions,
                accountId: accountId,
                token: token,
                isAdmin: isAdmin,
                isOwner: isOwner,
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

typedef $$CompaniesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompaniesTable,
      CompanyRow,
      $$CompaniesTableFilterComposer,
      $$CompaniesTableOrderingComposer,
      $$CompaniesTableAnnotationComposer,
      $$CompaniesTableCreateCompanionBuilder,
      $$CompaniesTableUpdateCompanionBuilder,
      (CompanyRow, BaseReferences<_$AppDatabase, $CompaniesTable, CompanyRow>),
      CompanyRow,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String id,
      required String email,
      required String plan,
      required int numTrialDays,
      Value<bool> isHosted,
      Value<String?> defaultCompanyId,
      Value<String?> featuresJson,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String> plan,
      Value<int> numTrialDays,
      Value<bool> isHosted,
      Value<String?> defaultCompanyId,
      Value<String?> featuresJson,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
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

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numTrialDays => $composableBuilder(
    column: $table.numTrialDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHosted => $composableBuilder(
    column: $table.isHosted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultCompanyId => $composableBuilder(
    column: $table.defaultCompanyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get featuresJson => $composableBuilder(
    column: $table.featuresJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
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

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numTrialDays => $composableBuilder(
    column: $table.numTrialDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHosted => $composableBuilder(
    column: $table.isHosted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultCompanyId => $composableBuilder(
    column: $table.defaultCompanyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get featuresJson => $composableBuilder(
    column: $table.featuresJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);

  GeneratedColumn<int> get numTrialDays => $composableBuilder(
    column: $table.numTrialDays,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isHosted =>
      $composableBuilder(column: $table.isHosted, builder: (column) => column);

  GeneratedColumn<String> get defaultCompanyId => $composableBuilder(
    column: $table.defaultCompanyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get featuresJson => $composableBuilder(
    column: $table.featuresJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (
            AccountRow,
            BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>,
          ),
          AccountRow,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<int> numTrialDays = const Value.absent(),
                Value<bool> isHosted = const Value.absent(),
                Value<String?> defaultCompanyId = const Value.absent(),
                Value<String?> featuresJson = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                email: email,
                plan: plan,
                numTrialDays: numTrialDays,
                isHosted: isHosted,
                defaultCompanyId: defaultCompanyId,
                featuresJson: featuresJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String email,
                required String plan,
                required int numTrialDays,
                Value<bool> isHosted = const Value.absent(),
                Value<String?> defaultCompanyId = const Value.absent(),
                Value<String?> featuresJson = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                email: email,
                plan: plan,
                numTrialDays: numTrialDays,
                isHosted: isHosted,
                defaultCompanyId: defaultCompanyId,
                featuresJson: featuresJson,
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

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>),
      AccountRow,
      PrefetchHooks Function()
    >;
typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      required String id,
      required String companyId,
      required String entityType,
      required String entityId,
      Value<String?> localPath,
      Value<String?> serverUrl,
      required String mimeType,
      required int size,
      required String uploadState,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<String> id,
      Value<String> companyId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String?> localPath,
      Value<String?> serverUrl,
      Value<String> mimeType,
      Value<int> size,
      Value<String> uploadState,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
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

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadState => $composableBuilder(
    column: $table.uploadState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
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

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadState => $composableBuilder(
    column: $table.uploadState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get serverUrl =>
      $composableBuilder(column: $table.serverUrl, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get uploadState => $composableBuilder(
    column: $table.uploadState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          DocumentRow,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (
            DocumentRow,
            BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow>,
          ),
          DocumentRow,
          PrefetchHooks Function()
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> serverUrl = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String> uploadState = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                companyId: companyId,
                entityType: entityType,
                entityId: entityId,
                localPath: localPath,
                serverUrl: serverUrl,
                mimeType: mimeType,
                size: size,
                uploadState: uploadState,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String entityType,
                required String entityId,
                Value<String?> localPath = const Value.absent(),
                Value<String?> serverUrl = const Value.absent(),
                required String mimeType,
                required int size,
                required String uploadState,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                id: id,
                companyId: companyId,
                entityType: entityType,
                entityId: entityId,
                localPath: localPath,
                serverUrl: serverUrl,
                mimeType: mimeType,
                size: size,
                uploadState: uploadState,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      DocumentRow,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (
        DocumentRow,
        BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow>,
      ),
      DocumentRow,
      PrefetchHooks Function()
    >;
typedef $$UserSettingsTableCreateCompanionBuilder =
    UserSettingsCompanion Function({
      required String companyId,
      required String userId,
      Value<String> tableColumnsJson,
      Value<String> extraJson,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$UserSettingsTableUpdateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<String> companyId,
      Value<String> userId,
      Value<String> tableColumnsJson,
      Value<String> extraJson,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$UserSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableColumnsJson => $composableBuilder(
    column: $table.tableColumnsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraJson => $composableBuilder(
    column: $table.extraJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableColumnsJson => $composableBuilder(
    column: $table.tableColumnsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraJson => $composableBuilder(
    column: $table.extraJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get tableColumnsJson => $composableBuilder(
    column: $table.tableColumnsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extraJson =>
      $composableBuilder(column: $table.extraJson, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTable,
          UserSettingsRow,
          $$UserSettingsTableFilterComposer,
          $$UserSettingsTableOrderingComposer,
          $$UserSettingsTableAnnotationComposer,
          $$UserSettingsTableCreateCompanionBuilder,
          $$UserSettingsTableUpdateCompanionBuilder,
          (
            UserSettingsRow,
            BaseReferences<_$AppDatabase, $UserSettingsTable, UserSettingsRow>,
          ),
          UserSettingsRow,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableManager(_$AppDatabase db, $UserSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> companyId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> tableColumnsJson = const Value.absent(),
                Value<String> extraJson = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserSettingsCompanion(
                companyId: companyId,
                userId: userId,
                tableColumnsJson: tableColumnsJson,
                extraJson: extraJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String companyId,
                required String userId,
                Value<String> tableColumnsJson = const Value.absent(),
                Value<String> extraJson = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserSettingsCompanion.insert(
                companyId: companyId,
                userId: userId,
                tableColumnsJson: tableColumnsJson,
                extraJson: extraJson,
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

typedef $$UserSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTable,
      UserSettingsRow,
      $$UserSettingsTableFilterComposer,
      $$UserSettingsTableOrderingComposer,
      $$UserSettingsTableAnnotationComposer,
      $$UserSettingsTableCreateCompanionBuilder,
      $$UserSettingsTableUpdateCompanionBuilder,
      (
        UserSettingsRow,
        BaseReferences<_$AppDatabase, $UserSettingsTable, UserSettingsRow>,
      ),
      UserSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$DashboardCacheTableCreateCompanionBuilder =
    DashboardCacheCompanion Function({
      required String companyId,
      required String kind,
      required String filterHash,
      required String payload,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$DashboardCacheTableUpdateCompanionBuilder =
    DashboardCacheCompanion Function({
      Value<String> companyId,
      Value<String> kind,
      Value<String> filterHash,
      Value<String> payload,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$DashboardCacheTableFilterComposer
    extends Composer<_$AppDatabase, $DashboardCacheTable> {
  $$DashboardCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterHash => $composableBuilder(
    column: $table.filterHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DashboardCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $DashboardCacheTable> {
  $$DashboardCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterHash => $composableBuilder(
    column: $table.filterHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DashboardCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $DashboardCacheTable> {
  $$DashboardCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get filterHash => $composableBuilder(
    column: $table.filterHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$DashboardCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DashboardCacheTable,
          DashboardCacheRow,
          $$DashboardCacheTableFilterComposer,
          $$DashboardCacheTableOrderingComposer,
          $$DashboardCacheTableAnnotationComposer,
          $$DashboardCacheTableCreateCompanionBuilder,
          $$DashboardCacheTableUpdateCompanionBuilder,
          (
            DashboardCacheRow,
            BaseReferences<
              _$AppDatabase,
              $DashboardCacheTable,
              DashboardCacheRow
            >,
          ),
          DashboardCacheRow,
          PrefetchHooks Function()
        > {
  $$DashboardCacheTableTableManager(
    _$AppDatabase db,
    $DashboardCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DashboardCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DashboardCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DashboardCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> companyId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> filterHash = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DashboardCacheCompanion(
                companyId: companyId,
                kind: kind,
                filterHash: filterHash,
                payload: payload,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String companyId,
                required String kind,
                required String filterHash,
                required String payload,
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => DashboardCacheCompanion.insert(
                companyId: companyId,
                kind: kind,
                filterHash: filterHash,
                payload: payload,
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

typedef $$DashboardCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DashboardCacheTable,
      DashboardCacheRow,
      $$DashboardCacheTableFilterComposer,
      $$DashboardCacheTableOrderingComposer,
      $$DashboardCacheTableAnnotationComposer,
      $$DashboardCacheTableCreateCompanionBuilder,
      $$DashboardCacheTableUpdateCompanionBuilder,
      (
        DashboardCacheRow,
        BaseReferences<_$AppDatabase, $DashboardCacheTable, DashboardCacheRow>,
      ),
      DashboardCacheRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ClientsTableTableManager get clients =>
      $$ClientsTableTableManager(_db, _db.clients);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$IdRemapTableTableManager get idRemap =>
      $$IdRemapTableTableManager(_db, _db.idRemap);
  $$SyncStateRowsTableTableManager get syncStateRows =>
      $$SyncStateRowsTableTableManager(_db, _db.syncStateRows);
  $$StaticsTableTableManager get statics =>
      $$StaticsTableTableManager(_db, _db.statics);
  $$DraftsTableTableManager get drafts =>
      $$DraftsTableTableManager(_db, _db.drafts);
  $$NavStateTableTableManager get navState =>
      $$NavStateTableTableManager(_db, _db.navState);
  $$CompaniesTableTableManager get companies =>
      $$CompaniesTableTableManager(_db, _db.companies);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
  $$DashboardCacheTableTableManager get dashboardCache =>
      $$DashboardCacheTableTableManager(_db, _db.dashboardCache);
}
