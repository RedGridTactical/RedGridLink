// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _securityModeMeta =
      const VerificationMeta('securityMode');
  @override
  late final GeneratedColumn<String> securityMode = GeneratedColumn<String>(
      'security_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _pinMeta = const VerificationMeta('pin');
  @override
  late final GeneratedColumn<String> pin = GeneratedColumn<String>(
      'pin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sessionKeyMeta =
      const VerificationMeta('sessionKey');
  @override
  late final GeneratedColumn<String> sessionKey = GeneratedColumn<String>(
      'session_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _operationalModeMeta =
      const VerificationMeta('operationalMode');
  @override
  late final GeneratedColumn<String> operationalMode = GeneratedColumn<String>(
      'operational_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('sar'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        securityMode,
        pin,
        sessionKey,
        createdAt,
        operationalMode,
        isActive
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<Session> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('security_mode')) {
      context.handle(
          _securityModeMeta,
          securityMode.isAcceptableOrUnknown(
              data['security_mode']!, _securityModeMeta));
    }
    if (data.containsKey('pin')) {
      context.handle(
          _pinMeta, pin.isAcceptableOrUnknown(data['pin']!, _pinMeta));
    }
    if (data.containsKey('session_key')) {
      context.handle(
          _sessionKeyMeta,
          sessionKey.isAcceptableOrUnknown(
              data['session_key']!, _sessionKeyMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('operational_mode')) {
      context.handle(
          _operationalModeMeta,
          operationalMode.isAcceptableOrUnknown(
              data['operational_mode']!, _operationalModeMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      securityMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}security_mode'])!,
      pin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pin']),
      sessionKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_key']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      operationalMode: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}operational_mode'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  /// Unique session ID (UUID v4).
  final String id;

  /// Human-readable session name.
  final String name;

  /// Security mode: open, pin, or qr.
  final String securityMode;

  /// Optional 4-digit PIN (for pin security mode).
  final String? pin;

  /// Optional session encryption key (for qr security mode).
  final String? sessionKey;

  /// When the session was created.
  final DateTime createdAt;

  /// Operational mode: sar, backcountry, hunting, or training.
  final String operationalMode;

  /// Whether this session is currently active.
  final bool isActive;
  const Session(
      {required this.id,
      required this.name,
      required this.securityMode,
      this.pin,
      this.sessionKey,
      required this.createdAt,
      required this.operationalMode,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['security_mode'] = Variable<String>(securityMode);
    if (!nullToAbsent || pin != null) {
      map['pin'] = Variable<String>(pin);
    }
    if (!nullToAbsent || sessionKey != null) {
      map['session_key'] = Variable<String>(sessionKey);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['operational_mode'] = Variable<String>(operationalMode);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      name: Value(name),
      securityMode: Value(securityMode),
      pin: pin == null && nullToAbsent ? const Value.absent() : Value(pin),
      sessionKey: sessionKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionKey),
      createdAt: Value(createdAt),
      operationalMode: Value(operationalMode),
      isActive: Value(isActive),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      securityMode: serializer.fromJson<String>(json['securityMode']),
      pin: serializer.fromJson<String?>(json['pin']),
      sessionKey: serializer.fromJson<String?>(json['sessionKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      operationalMode: serializer.fromJson<String>(json['operationalMode']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'securityMode': serializer.toJson<String>(securityMode),
      'pin': serializer.toJson<String?>(pin),
      'sessionKey': serializer.toJson<String?>(sessionKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'operationalMode': serializer.toJson<String>(operationalMode),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Session copyWith(
          {String? id,
          String? name,
          String? securityMode,
          Value<String?> pin = const Value.absent(),
          Value<String?> sessionKey = const Value.absent(),
          DateTime? createdAt,
          String? operationalMode,
          bool? isActive}) =>
      Session(
        id: id ?? this.id,
        name: name ?? this.name,
        securityMode: securityMode ?? this.securityMode,
        pin: pin.present ? pin.value : this.pin,
        sessionKey: sessionKey.present ? sessionKey.value : this.sessionKey,
        createdAt: createdAt ?? this.createdAt,
        operationalMode: operationalMode ?? this.operationalMode,
        isActive: isActive ?? this.isActive,
      );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      securityMode: data.securityMode.present
          ? data.securityMode.value
          : this.securityMode,
      pin: data.pin.present ? data.pin.value : this.pin,
      sessionKey:
          data.sessionKey.present ? data.sessionKey.value : this.sessionKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      operationalMode: data.operationalMode.present
          ? data.operationalMode.value
          : this.operationalMode,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('securityMode: $securityMode, ')
          ..write('pin: $pin, ')
          ..write('sessionKey: $sessionKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('operationalMode: $operationalMode, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, securityMode, pin, sessionKey,
      createdAt, operationalMode, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.name == this.name &&
          other.securityMode == this.securityMode &&
          other.pin == this.pin &&
          other.sessionKey == this.sessionKey &&
          other.createdAt == this.createdAt &&
          other.operationalMode == this.operationalMode &&
          other.isActive == this.isActive);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> securityMode;
  final Value<String?> pin;
  final Value<String?> sessionKey;
  final Value<DateTime> createdAt;
  final Value<String> operationalMode;
  final Value<bool> isActive;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.securityMode = const Value.absent(),
    this.pin = const Value.absent(),
    this.sessionKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.operationalMode = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.securityMode = const Value.absent(),
    this.pin = const Value.absent(),
    this.sessionKey = const Value.absent(),
    required DateTime createdAt,
    this.operationalMode = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? securityMode,
    Expression<String>? pin,
    Expression<String>? sessionKey,
    Expression<DateTime>? createdAt,
    Expression<String>? operationalMode,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (securityMode != null) 'security_mode': securityMode,
      if (pin != null) 'pin': pin,
      if (sessionKey != null) 'session_key': sessionKey,
      if (createdAt != null) 'created_at': createdAt,
      if (operationalMode != null) 'operational_mode': operationalMode,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? securityMode,
      Value<String?>? pin,
      Value<String?>? sessionKey,
      Value<DateTime>? createdAt,
      Value<String>? operationalMode,
      Value<bool>? isActive,
      Value<int>? rowid}) {
    return SessionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      securityMode: securityMode ?? this.securityMode,
      pin: pin ?? this.pin,
      sessionKey: sessionKey ?? this.sessionKey,
      createdAt: createdAt ?? this.createdAt,
      operationalMode: operationalMode ?? this.operationalMode,
      isActive: isActive ?? this.isActive,
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
    if (securityMode.present) {
      map['security_mode'] = Variable<String>(securityMode.value);
    }
    if (pin.present) {
      map['pin'] = Variable<String>(pin.value);
    }
    if (sessionKey.present) {
      map['session_key'] = Variable<String>(sessionKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (operationalMode.present) {
      map['operational_mode'] = Variable<String>(operationalMode.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('securityMode: $securityMode, ')
          ..write('pin: $pin, ')
          ..write('sessionKey: $sessionKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('operationalMode: $operationalMode, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeersTable extends Peers with TableInfo<$PeersTable, Peer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceTypeMeta =
      const VerificationMeta('deviceType');
  @override
  late final GeneratedColumn<String> deviceType = GeneratedColumn<String>(
      'device_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('unknown'));
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _altitudeMeta =
      const VerificationMeta('altitude');
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
      'altitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
      'speed', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _headingMeta =
      const VerificationMeta('heading');
  @override
  late final GeneratedColumn<double> heading = GeneratedColumn<double>(
      'heading', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _accuracyMeta =
      const VerificationMeta('accuracy');
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
      'accuracy', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _mgrsRawMeta =
      const VerificationMeta('mgrsRaw');
  @override
  late final GeneratedColumn<String> mgrsRaw = GeneratedColumn<String>(
      'mgrs_raw', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSeenMeta =
      const VerificationMeta('lastSeen');
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
      'last_seen', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isConnectedMeta =
      const VerificationMeta('isConnected');
  @override
  late final GeneratedColumn<bool> isConnected = GeneratedColumn<bool>(
      'is_connected', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_connected" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _batteryLevelMeta =
      const VerificationMeta('batteryLevel');
  @override
  late final GeneratedColumn<int> batteryLevel = GeneratedColumn<int>(
      'battery_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _syncModeMeta =
      const VerificationMeta('syncMode');
  @override
  late final GeneratedColumn<String> syncMode = GeneratedColumn<String>(
      'sync_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('expedition'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sessionId,
        displayName,
        deviceType,
        lat,
        lon,
        altitude,
        speed,
        heading,
        accuracy,
        mgrsRaw,
        lastSeen,
        isConnected,
        batteryLevel,
        syncMode
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'peers';
  @override
  VerificationContext validateIntegrity(Insertable<Peer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('device_type')) {
      context.handle(
          _deviceTypeMeta,
          deviceType.isAcceptableOrUnknown(
              data['device_type']!, _deviceTypeMeta));
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    }
    if (data.containsKey('altitude')) {
      context.handle(_altitudeMeta,
          altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta));
    }
    if (data.containsKey('speed')) {
      context.handle(
          _speedMeta, speed.isAcceptableOrUnknown(data['speed']!, _speedMeta));
    }
    if (data.containsKey('heading')) {
      context.handle(_headingMeta,
          heading.isAcceptableOrUnknown(data['heading']!, _headingMeta));
    }
    if (data.containsKey('accuracy')) {
      context.handle(_accuracyMeta,
          accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta));
    }
    if (data.containsKey('mgrs_raw')) {
      context.handle(_mgrsRawMeta,
          mgrsRaw.isAcceptableOrUnknown(data['mgrs_raw']!, _mgrsRawMeta));
    }
    if (data.containsKey('last_seen')) {
      context.handle(_lastSeenMeta,
          lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta));
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('is_connected')) {
      context.handle(
          _isConnectedMeta,
          isConnected.isAcceptableOrUnknown(
              data['is_connected']!, _isConnectedMeta));
    }
    if (data.containsKey('battery_level')) {
      context.handle(
          _batteryLevelMeta,
          batteryLevel.isAcceptableOrUnknown(
              data['battery_level']!, _batteryLevelMeta));
    }
    if (data.containsKey('sync_mode')) {
      context.handle(_syncModeMeta,
          syncMode.isAcceptableOrUnknown(data['sync_mode']!, _syncModeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Peer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Peer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      deviceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_type'])!,
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat']),
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon']),
      altitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}altitude']),
      speed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}speed']),
      heading: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}heading']),
      accuracy: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}accuracy']),
      mgrsRaw: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mgrs_raw']),
      lastSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_seen'])!,
      isConnected: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_connected'])!,
      batteryLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}battery_level']),
      syncMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_mode'])!,
    );
  }

  @override
  $PeersTable createAlias(String alias) {
    return $PeersTable(attachedDatabase, alias);
  }
}

class Peer extends DataClass implements Insertable<Peer> {
  /// Unique peer ID (UUID v4).
  final String id;

  /// Foreign key to sessions table.
  final String sessionId;

  /// User-configured display name.
  final String displayName;

  /// Device platform: android, ios, or unknown.
  final String deviceType;

  /// GPS latitude.
  final double? lat;

  /// GPS longitude.
  final double? lon;

  /// GPS altitude in meters.
  final double? altitude;

  /// Speed in m/s.
  final double? speed;

  /// Compass heading in degrees.
  final double? heading;

  /// GPS accuracy in meters.
  final double? accuracy;

  /// Raw MGRS coordinate string.
  final String? mgrsRaw;

  /// Last time a position update was received.
  final DateTime lastSeen;

  /// Whether the peer is currently connected.
  final bool isConnected;

  /// Battery level 0-100.
  final int? batteryLevel;

  /// Sync mode: expedition or active.
  final String syncMode;
  const Peer(
      {required this.id,
      required this.sessionId,
      required this.displayName,
      required this.deviceType,
      this.lat,
      this.lon,
      this.altitude,
      this.speed,
      this.heading,
      this.accuracy,
      this.mgrsRaw,
      required this.lastSeen,
      required this.isConnected,
      this.batteryLevel,
      required this.syncMode});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['display_name'] = Variable<String>(displayName);
    map['device_type'] = Variable<String>(deviceType);
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lon != null) {
      map['lon'] = Variable<double>(lon);
    }
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    if (!nullToAbsent || heading != null) {
      map['heading'] = Variable<double>(heading);
    }
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    if (!nullToAbsent || mgrsRaw != null) {
      map['mgrs_raw'] = Variable<String>(mgrsRaw);
    }
    map['last_seen'] = Variable<DateTime>(lastSeen);
    map['is_connected'] = Variable<bool>(isConnected);
    if (!nullToAbsent || batteryLevel != null) {
      map['battery_level'] = Variable<int>(batteryLevel);
    }
    map['sync_mode'] = Variable<String>(syncMode);
    return map;
  }

  PeersCompanion toCompanion(bool nullToAbsent) {
    return PeersCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      displayName: Value(displayName),
      deviceType: Value(deviceType),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lon: lon == null && nullToAbsent ? const Value.absent() : Value(lon),
      altitude: altitude == null && nullToAbsent
          ? const Value.absent()
          : Value(altitude),
      speed:
          speed == null && nullToAbsent ? const Value.absent() : Value(speed),
      heading: heading == null && nullToAbsent
          ? const Value.absent()
          : Value(heading),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      mgrsRaw: mgrsRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(mgrsRaw),
      lastSeen: Value(lastSeen),
      isConnected: Value(isConnected),
      batteryLevel: batteryLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryLevel),
      syncMode: Value(syncMode),
    );
  }

  factory Peer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Peer(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      deviceType: serializer.fromJson<String>(json['deviceType']),
      lat: serializer.fromJson<double?>(json['lat']),
      lon: serializer.fromJson<double?>(json['lon']),
      altitude: serializer.fromJson<double?>(json['altitude']),
      speed: serializer.fromJson<double?>(json['speed']),
      heading: serializer.fromJson<double?>(json['heading']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      mgrsRaw: serializer.fromJson<String?>(json['mgrsRaw']),
      lastSeen: serializer.fromJson<DateTime>(json['lastSeen']),
      isConnected: serializer.fromJson<bool>(json['isConnected']),
      batteryLevel: serializer.fromJson<int?>(json['batteryLevel']),
      syncMode: serializer.fromJson<String>(json['syncMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'displayName': serializer.toJson<String>(displayName),
      'deviceType': serializer.toJson<String>(deviceType),
      'lat': serializer.toJson<double?>(lat),
      'lon': serializer.toJson<double?>(lon),
      'altitude': serializer.toJson<double?>(altitude),
      'speed': serializer.toJson<double?>(speed),
      'heading': serializer.toJson<double?>(heading),
      'accuracy': serializer.toJson<double?>(accuracy),
      'mgrsRaw': serializer.toJson<String?>(mgrsRaw),
      'lastSeen': serializer.toJson<DateTime>(lastSeen),
      'isConnected': serializer.toJson<bool>(isConnected),
      'batteryLevel': serializer.toJson<int?>(batteryLevel),
      'syncMode': serializer.toJson<String>(syncMode),
    };
  }

  Peer copyWith(
          {String? id,
          String? sessionId,
          String? displayName,
          String? deviceType,
          Value<double?> lat = const Value.absent(),
          Value<double?> lon = const Value.absent(),
          Value<double?> altitude = const Value.absent(),
          Value<double?> speed = const Value.absent(),
          Value<double?> heading = const Value.absent(),
          Value<double?> accuracy = const Value.absent(),
          Value<String?> mgrsRaw = const Value.absent(),
          DateTime? lastSeen,
          bool? isConnected,
          Value<int?> batteryLevel = const Value.absent(),
          String? syncMode}) =>
      Peer(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        displayName: displayName ?? this.displayName,
        deviceType: deviceType ?? this.deviceType,
        lat: lat.present ? lat.value : this.lat,
        lon: lon.present ? lon.value : this.lon,
        altitude: altitude.present ? altitude.value : this.altitude,
        speed: speed.present ? speed.value : this.speed,
        heading: heading.present ? heading.value : this.heading,
        accuracy: accuracy.present ? accuracy.value : this.accuracy,
        mgrsRaw: mgrsRaw.present ? mgrsRaw.value : this.mgrsRaw,
        lastSeen: lastSeen ?? this.lastSeen,
        isConnected: isConnected ?? this.isConnected,
        batteryLevel:
            batteryLevel.present ? batteryLevel.value : this.batteryLevel,
        syncMode: syncMode ?? this.syncMode,
      );
  Peer copyWithCompanion(PeersCompanion data) {
    return Peer(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      deviceType:
          data.deviceType.present ? data.deviceType.value : this.deviceType,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      speed: data.speed.present ? data.speed.value : this.speed,
      heading: data.heading.present ? data.heading.value : this.heading,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      mgrsRaw: data.mgrsRaw.present ? data.mgrsRaw.value : this.mgrsRaw,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      isConnected:
          data.isConnected.present ? data.isConnected.value : this.isConnected,
      batteryLevel: data.batteryLevel.present
          ? data.batteryLevel.value
          : this.batteryLevel,
      syncMode: data.syncMode.present ? data.syncMode.value : this.syncMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Peer(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('displayName: $displayName, ')
          ..write('deviceType: $deviceType, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('altitude: $altitude, ')
          ..write('speed: $speed, ')
          ..write('heading: $heading, ')
          ..write('accuracy: $accuracy, ')
          ..write('mgrsRaw: $mgrsRaw, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('isConnected: $isConnected, ')
          ..write('batteryLevel: $batteryLevel, ')
          ..write('syncMode: $syncMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      sessionId,
      displayName,
      deviceType,
      lat,
      lon,
      altitude,
      speed,
      heading,
      accuracy,
      mgrsRaw,
      lastSeen,
      isConnected,
      batteryLevel,
      syncMode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Peer &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.displayName == this.displayName &&
          other.deviceType == this.deviceType &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.altitude == this.altitude &&
          other.speed == this.speed &&
          other.heading == this.heading &&
          other.accuracy == this.accuracy &&
          other.mgrsRaw == this.mgrsRaw &&
          other.lastSeen == this.lastSeen &&
          other.isConnected == this.isConnected &&
          other.batteryLevel == this.batteryLevel &&
          other.syncMode == this.syncMode);
}

class PeersCompanion extends UpdateCompanion<Peer> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> displayName;
  final Value<String> deviceType;
  final Value<double?> lat;
  final Value<double?> lon;
  final Value<double?> altitude;
  final Value<double?> speed;
  final Value<double?> heading;
  final Value<double?> accuracy;
  final Value<String?> mgrsRaw;
  final Value<DateTime> lastSeen;
  final Value<bool> isConnected;
  final Value<int?> batteryLevel;
  final Value<String> syncMode;
  final Value<int> rowid;
  const PeersCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.deviceType = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.altitude = const Value.absent(),
    this.speed = const Value.absent(),
    this.heading = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.mgrsRaw = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.isConnected = const Value.absent(),
    this.batteryLevel = const Value.absent(),
    this.syncMode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeersCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required String displayName,
    this.deviceType = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.altitude = const Value.absent(),
    this.speed = const Value.absent(),
    this.heading = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.mgrsRaw = const Value.absent(),
    required DateTime lastSeen,
    this.isConnected = const Value.absent(),
    this.batteryLevel = const Value.absent(),
    this.syncMode = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : sessionId = Value(sessionId),
        displayName = Value(displayName),
        lastSeen = Value(lastSeen);
  static Insertable<Peer> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? displayName,
    Expression<String>? deviceType,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? altitude,
    Expression<double>? speed,
    Expression<double>? heading,
    Expression<double>? accuracy,
    Expression<String>? mgrsRaw,
    Expression<DateTime>? lastSeen,
    Expression<bool>? isConnected,
    Expression<int>? batteryLevel,
    Expression<String>? syncMode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (displayName != null) 'display_name': displayName,
      if (deviceType != null) 'device_type': deviceType,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (accuracy != null) 'accuracy': accuracy,
      if (mgrsRaw != null) 'mgrs_raw': mgrsRaw,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (isConnected != null) 'is_connected': isConnected,
      if (batteryLevel != null) 'battery_level': batteryLevel,
      if (syncMode != null) 'sync_mode': syncMode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeersCompanion copyWith(
      {Value<String>? id,
      Value<String>? sessionId,
      Value<String>? displayName,
      Value<String>? deviceType,
      Value<double?>? lat,
      Value<double?>? lon,
      Value<double?>? altitude,
      Value<double?>? speed,
      Value<double?>? heading,
      Value<double?>? accuracy,
      Value<String?>? mgrsRaw,
      Value<DateTime>? lastSeen,
      Value<bool>? isConnected,
      Value<int?>? batteryLevel,
      Value<String>? syncMode,
      Value<int>? rowid}) {
    return PeersCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      displayName: displayName ?? this.displayName,
      deviceType: deviceType ?? this.deviceType,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      mgrsRaw: mgrsRaw ?? this.mgrsRaw,
      lastSeen: lastSeen ?? this.lastSeen,
      isConnected: isConnected ?? this.isConnected,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      syncMode: syncMode ?? this.syncMode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (deviceType.present) {
      map['device_type'] = Variable<String>(deviceType.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (heading.present) {
      map['heading'] = Variable<double>(heading.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (mgrsRaw.present) {
      map['mgrs_raw'] = Variable<String>(mgrsRaw.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (isConnected.present) {
      map['is_connected'] = Variable<bool>(isConnected.value);
    }
    if (batteryLevel.present) {
      map['battery_level'] = Variable<int>(batteryLevel.value);
    }
    if (syncMode.present) {
      map['sync_mode'] = Variable<String>(syncMode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeersCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('displayName: $displayName, ')
          ..write('deviceType: $deviceType, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('altitude: $altitude, ')
          ..write('speed: $speed, ')
          ..write('heading: $heading, ')
          ..write('accuracy: $accuracy, ')
          ..write('mgrsRaw: $mgrsRaw, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('isConnected: $isConnected, ')
          ..write('batteryLevel: $batteryLevel, ')
          ..write('syncMode: $syncMode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MarkersTable extends Markers with TableInfo<$MarkersTable, Marker> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MarkersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _mgrsMeta = const VerificationMeta('mgrs');
  @override
  late final GeneratedColumn<String> mgrs = GeneratedColumn<String>(
      'mgrs', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('waypoint'));
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0xFFFF0000));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sessionId,
        lat,
        lon,
        mgrs,
        label,
        icon,
        createdBy,
        createdAt,
        color,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'markers';
  @override
  VerificationContext validateIntegrity(Insertable<Marker> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('mgrs')) {
      context.handle(
          _mgrsMeta, mgrs.isAcceptableOrUnknown(data['mgrs']!, _mgrsMeta));
    } else if (isInserting) {
      context.missing(_mgrsMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Marker map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Marker(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id']),
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon'])!,
      mgrs: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mgrs'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $MarkersTable createAlias(String alias) {
    return $MarkersTable(attachedDatabase, alias);
  }
}

class Marker extends DataClass implements Insertable<Marker> {
  /// Unique marker ID (UUID v4).
  final String id;

  /// Foreign key to sessions table (nullable for standalone markers).
  final String? sessionId;

  /// GPS latitude.
  final double lat;

  /// GPS longitude.
  final double lon;

  /// MGRS coordinate string.
  final String mgrs;

  /// User-assigned label.
  final String label;

  /// Icon type: waypoint, danger, camp, rally, find, checkpoint, stand, custom.
  final String icon;

  /// ID of the peer that created this marker.
  final String createdBy;

  /// When the marker was created.
  final DateTime createdAt;

  /// Color as an ARGB integer.
  final int color;

  /// Whether this marker has been synced to peers.
  final bool isSynced;
  const Marker(
      {required this.id,
      this.sessionId,
      required this.lat,
      required this.lon,
      required this.mgrs,
      required this.label,
      required this.icon,
      required this.createdBy,
      required this.createdAt,
      required this.color,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['mgrs'] = Variable<String>(mgrs);
    map['label'] = Variable<String>(label);
    map['icon'] = Variable<String>(icon);
    map['created_by'] = Variable<String>(createdBy);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['color'] = Variable<int>(color);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  MarkersCompanion toCompanion(bool nullToAbsent) {
    return MarkersCompanion(
      id: Value(id),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      lat: Value(lat),
      lon: Value(lon),
      mgrs: Value(mgrs),
      label: Value(label),
      icon: Value(icon),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      color: Value(color),
      isSynced: Value(isSynced),
    );
  }

  factory Marker.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Marker(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      mgrs: serializer.fromJson<String>(json['mgrs']),
      label: serializer.fromJson<String>(json['label']),
      icon: serializer.fromJson<String>(json['icon']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      color: serializer.fromJson<int>(json['color']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String?>(sessionId),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'mgrs': serializer.toJson<String>(mgrs),
      'label': serializer.toJson<String>(label),
      'icon': serializer.toJson<String>(icon),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'color': serializer.toJson<int>(color),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  Marker copyWith(
          {String? id,
          Value<String?> sessionId = const Value.absent(),
          double? lat,
          double? lon,
          String? mgrs,
          String? label,
          String? icon,
          String? createdBy,
          DateTime? createdAt,
          int? color,
          bool? isSynced}) =>
      Marker(
        id: id ?? this.id,
        sessionId: sessionId.present ? sessionId.value : this.sessionId,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        mgrs: mgrs ?? this.mgrs,
        label: label ?? this.label,
        icon: icon ?? this.icon,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        color: color ?? this.color,
        isSynced: isSynced ?? this.isSynced,
      );
  Marker copyWithCompanion(MarkersCompanion data) {
    return Marker(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      mgrs: data.mgrs.present ? data.mgrs.value : this.mgrs,
      label: data.label.present ? data.label.value : this.label,
      icon: data.icon.present ? data.icon.value : this.icon,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      color: data.color.present ? data.color.value : this.color,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Marker(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('mgrs: $mgrs, ')
          ..write('label: $label, ')
          ..write('icon: $icon, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('color: $color, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, lat, lon, mgrs, label, icon,
      createdBy, createdAt, color, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Marker &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.mgrs == this.mgrs &&
          other.label == this.label &&
          other.icon == this.icon &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.color == this.color &&
          other.isSynced == this.isSynced);
}

class MarkersCompanion extends UpdateCompanion<Marker> {
  final Value<String> id;
  final Value<String?> sessionId;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String> mgrs;
  final Value<String> label;
  final Value<String> icon;
  final Value<String> createdBy;
  final Value<DateTime> createdAt;
  final Value<int> color;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const MarkersCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.mgrs = const Value.absent(),
    this.label = const Value.absent(),
    this.icon = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.color = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MarkersCompanion.insert({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    required double lat,
    required double lon,
    required String mgrs,
    required String label,
    this.icon = const Value.absent(),
    required String createdBy,
    required DateTime createdAt,
    this.color = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : lat = Value(lat),
        lon = Value(lon),
        mgrs = Value(mgrs),
        label = Value(label),
        createdBy = Value(createdBy),
        createdAt = Value(createdAt);
  static Insertable<Marker> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? mgrs,
    Expression<String>? label,
    Expression<String>? icon,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<int>? color,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (mgrs != null) 'mgrs': mgrs,
      if (label != null) 'label': label,
      if (icon != null) 'icon': icon,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (color != null) 'color': color,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MarkersCompanion copyWith(
      {Value<String>? id,
      Value<String?>? sessionId,
      Value<double>? lat,
      Value<double>? lon,
      Value<String>? mgrs,
      Value<String>? label,
      Value<String>? icon,
      Value<String>? createdBy,
      Value<DateTime>? createdAt,
      Value<int>? color,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return MarkersCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      mgrs: mgrs ?? this.mgrs,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (mgrs.present) {
      map['mgrs'] = Variable<String>(mgrs.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MarkersCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('mgrs: $mgrs, ')
          ..write('label: $label, ')
          ..write('icon: $icon, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('color: $color, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _altitudeMeta =
      const VerificationMeta('altitude');
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
      'altitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
      'speed', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _headingMeta =
      const VerificationMeta('heading');
  @override
  late final GeneratedColumn<double> heading = GeneratedColumn<double>(
      'heading', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _accuracyMeta =
      const VerificationMeta('accuracy');
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
      'accuracy', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, sessionId, lat, lon, altitude, speed, heading, accuracy, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(Insertable<Track> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('altitude')) {
      context.handle(_altitudeMeta,
          altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta));
    }
    if (data.containsKey('speed')) {
      context.handle(
          _speedMeta, speed.isAcceptableOrUnknown(data['speed']!, _speedMeta));
    }
    if (data.containsKey('heading')) {
      context.handle(_headingMeta,
          heading.isAcceptableOrUnknown(data['heading']!, _headingMeta));
    }
    if (data.containsKey('accuracy')) {
      context.handle(_accuracyMeta,
          accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id']),
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon'])!,
      altitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}altitude']),
      speed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}speed']),
      heading: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}heading']),
      accuracy: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}accuracy']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends DataClass implements Insertable<Track> {
  /// Auto-incrementing integer primary key.
  final int id;

  /// Foreign key to sessions table (nullable for standalone tracks).
  final String? sessionId;

  /// GPS latitude.
  final double lat;

  /// GPS longitude.
  final double lon;

  /// GPS altitude in meters.
  final double? altitude;

  /// Speed in m/s.
  final double? speed;

  /// Compass heading in degrees.
  final double? heading;

  /// GPS accuracy in meters.
  final double? accuracy;

  /// When this track point was recorded.
  final DateTime timestamp;
  const Track(
      {required this.id,
      this.sessionId,
      required this.lat,
      required this.lon,
      this.altitude,
      this.speed,
      this.heading,
      this.accuracy,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    if (!nullToAbsent || heading != null) {
      map['heading'] = Variable<double>(heading);
    }
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      lat: Value(lat),
      lon: Value(lon),
      altitude: altitude == null && nullToAbsent
          ? const Value.absent()
          : Value(altitude),
      speed:
          speed == null && nullToAbsent ? const Value.absent() : Value(speed),
      heading: heading == null && nullToAbsent
          ? const Value.absent()
          : Value(heading),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      timestamp: Value(timestamp),
    );
  }

  factory Track.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      altitude: serializer.fromJson<double?>(json['altitude']),
      speed: serializer.fromJson<double?>(json['speed']),
      heading: serializer.fromJson<double?>(json['heading']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String?>(sessionId),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'altitude': serializer.toJson<double?>(altitude),
      'speed': serializer.toJson<double?>(speed),
      'heading': serializer.toJson<double?>(heading),
      'accuracy': serializer.toJson<double?>(accuracy),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  Track copyWith(
          {int? id,
          Value<String?> sessionId = const Value.absent(),
          double? lat,
          double? lon,
          Value<double?> altitude = const Value.absent(),
          Value<double?> speed = const Value.absent(),
          Value<double?> heading = const Value.absent(),
          Value<double?> accuracy = const Value.absent(),
          DateTime? timestamp}) =>
      Track(
        id: id ?? this.id,
        sessionId: sessionId.present ? sessionId.value : this.sessionId,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        altitude: altitude.present ? altitude.value : this.altitude,
        speed: speed.present ? speed.value : this.speed,
        heading: heading.present ? heading.value : this.heading,
        accuracy: accuracy.present ? accuracy.value : this.accuracy,
        timestamp: timestamp ?? this.timestamp,
      );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      speed: data.speed.present ? data.speed.value : this.speed,
      heading: data.heading.present ? data.heading.value : this.heading,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('altitude: $altitude, ')
          ..write('speed: $speed, ')
          ..write('heading: $heading, ')
          ..write('accuracy: $accuracy, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, sessionId, lat, lon, altitude, speed, heading, accuracy, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.altitude == this.altitude &&
          other.speed == this.speed &&
          other.heading == this.heading &&
          other.accuracy == this.accuracy &&
          other.timestamp == this.timestamp);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<int> id;
  final Value<String?> sessionId;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double?> altitude;
  final Value<double?> speed;
  final Value<double?> heading;
  final Value<double?> accuracy;
  final Value<DateTime> timestamp;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.altitude = const Value.absent(),
    this.speed = const Value.absent(),
    this.heading = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  TracksCompanion.insert({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    required double lat,
    required double lon,
    this.altitude = const Value.absent(),
    this.speed = const Value.absent(),
    this.heading = const Value.absent(),
    this.accuracy = const Value.absent(),
    required DateTime timestamp,
  })  : lat = Value(lat),
        lon = Value(lon),
        timestamp = Value(timestamp);
  static Insertable<Track> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? altitude,
    Expression<double>? speed,
    Expression<double>? heading,
    Expression<double>? accuracy,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (accuracy != null) 'accuracy': accuracy,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  TracksCompanion copyWith(
      {Value<int>? id,
      Value<String?>? sessionId,
      Value<double>? lat,
      Value<double>? lon,
      Value<double?>? altitude,
      Value<double?>? speed,
      Value<double?>? heading,
      Value<double?>? accuracy,
      Value<DateTime>? timestamp}) {
    return TracksCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (heading.present) {
      map['heading'] = Variable<double>(heading.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('altitude: $altitude, ')
          ..write('speed: $speed, ')
          ..write('heading: $heading, ')
          ..write('accuracy: $accuracy, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $AnnotationsTable extends Annotations
    with TableInfo<$AnnotationsTable, Annotation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pointsJsonMeta =
      const VerificationMeta('pointsJson');
  @override
  late final GeneratedColumn<String> pointsJson = GeneratedColumn<String>(
      'points_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0xFFFF0000));
  static const VerificationMeta _strokeWidthMeta =
      const VerificationMeta('strokeWidth');
  @override
  late final GeneratedColumn<double> strokeWidth = GeneratedColumn<double>(
      'stroke_width', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(2.0));
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sessionId,
        type,
        pointsJson,
        color,
        strokeWidth,
        label,
        createdBy,
        createdAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(Insertable<Annotation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('points_json')) {
      context.handle(
          _pointsJsonMeta,
          pointsJson.isAcceptableOrUnknown(
              data['points_json']!, _pointsJsonMeta));
    } else if (isInserting) {
      context.missing(_pointsJsonMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('stroke_width')) {
      context.handle(
          _strokeWidthMeta,
          strokeWidth.isAcceptableOrUnknown(
              data['stroke_width']!, _strokeWidthMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Annotation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Annotation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      pointsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}points_json'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      strokeWidth: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stroke_width'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label']),
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }
}

class Annotation extends DataClass implements Insertable<Annotation> {
  /// Unique annotation ID (UUID v4).
  final String id;

  /// Foreign key to sessions table (nullable for standalone annotations).
  final String? sessionId;

  /// Geometry type: polyline or polygon.
  final String type;

  /// JSON-encoded array of {lat, lon} points.
  final String pointsJson;

  /// Color as an ARGB integer.
  final int color;

  /// Line stroke width.
  final double strokeWidth;

  /// Optional label.
  final String? label;

  /// ID of the peer that created this annotation.
  final String createdBy;

  /// When the annotation was created.
  final DateTime createdAt;

  /// Whether this annotation has been synced to peers.
  final bool isSynced;
  const Annotation(
      {required this.id,
      this.sessionId,
      required this.type,
      required this.pointsJson,
      required this.color,
      required this.strokeWidth,
      this.label,
      required this.createdBy,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['type'] = Variable<String>(type);
    map['points_json'] = Variable<String>(pointsJson);
    map['color'] = Variable<int>(color);
    map['stroke_width'] = Variable<double>(strokeWidth);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  AnnotationsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationsCompanion(
      id: Value(id),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      type: Value(type),
      pointsJson: Value(pointsJson),
      color: Value(color),
      strokeWidth: Value(strokeWidth),
      label:
          label == null && nullToAbsent ? const Value.absent() : Value(label),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory Annotation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Annotation(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      type: serializer.fromJson<String>(json['type']),
      pointsJson: serializer.fromJson<String>(json['pointsJson']),
      color: serializer.fromJson<int>(json['color']),
      strokeWidth: serializer.fromJson<double>(json['strokeWidth']),
      label: serializer.fromJson<String?>(json['label']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String?>(sessionId),
      'type': serializer.toJson<String>(type),
      'pointsJson': serializer.toJson<String>(pointsJson),
      'color': serializer.toJson<int>(color),
      'strokeWidth': serializer.toJson<double>(strokeWidth),
      'label': serializer.toJson<String?>(label),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  Annotation copyWith(
          {String? id,
          Value<String?> sessionId = const Value.absent(),
          String? type,
          String? pointsJson,
          int? color,
          double? strokeWidth,
          Value<String?> label = const Value.absent(),
          String? createdBy,
          DateTime? createdAt,
          bool? isSynced}) =>
      Annotation(
        id: id ?? this.id,
        sessionId: sessionId.present ? sessionId.value : this.sessionId,
        type: type ?? this.type,
        pointsJson: pointsJson ?? this.pointsJson,
        color: color ?? this.color,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        label: label.present ? label.value : this.label,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  Annotation copyWithCompanion(AnnotationsCompanion data) {
    return Annotation(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      type: data.type.present ? data.type.value : this.type,
      pointsJson:
          data.pointsJson.present ? data.pointsJson.value : this.pointsJson,
      color: data.color.present ? data.color.value : this.color,
      strokeWidth:
          data.strokeWidth.present ? data.strokeWidth.value : this.strokeWidth,
      label: data.label.present ? data.label.value : this.label,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Annotation(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('type: $type, ')
          ..write('pointsJson: $pointsJson, ')
          ..write('color: $color, ')
          ..write('strokeWidth: $strokeWidth, ')
          ..write('label: $label, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, type, pointsJson, color,
      strokeWidth, label, createdBy, createdAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Annotation &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.type == this.type &&
          other.pointsJson == this.pointsJson &&
          other.color == this.color &&
          other.strokeWidth == this.strokeWidth &&
          other.label == this.label &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class AnnotationsCompanion extends UpdateCompanion<Annotation> {
  final Value<String> id;
  final Value<String?> sessionId;
  final Value<String> type;
  final Value<String> pointsJson;
  final Value<int> color;
  final Value<double> strokeWidth;
  final Value<String?> label;
  final Value<String> createdBy;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const AnnotationsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.type = const Value.absent(),
    this.pointsJson = const Value.absent(),
    this.color = const Value.absent(),
    this.strokeWidth = const Value.absent(),
    this.label = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnotationsCompanion.insert({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    required String type,
    required String pointsJson,
    this.color = const Value.absent(),
    this.strokeWidth = const Value.absent(),
    this.label = const Value.absent(),
    required String createdBy,
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : type = Value(type),
        pointsJson = Value(pointsJson),
        createdBy = Value(createdBy),
        createdAt = Value(createdAt);
  static Insertable<Annotation> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? type,
    Expression<String>? pointsJson,
    Expression<int>? color,
    Expression<double>? strokeWidth,
    Expression<String>? label,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (type != null) 'type': type,
      if (pointsJson != null) 'points_json': pointsJson,
      if (color != null) 'color': color,
      if (strokeWidth != null) 'stroke_width': strokeWidth,
      if (label != null) 'label': label,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnotationsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? sessionId,
      Value<String>? type,
      Value<String>? pointsJson,
      Value<int>? color,
      Value<double>? strokeWidth,
      Value<String?>? label,
      Value<String>? createdBy,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return AnnotationsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      type: type ?? this.type,
      pointsJson: pointsJson ?? this.pointsJson,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      label: label ?? this.label,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (pointsJson.present) {
      map['points_json'] = Variable<String>(pointsJson.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (strokeWidth.present) {
      map['stroke_width'] = Variable<double>(strokeWidth.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('type: $type, ')
          ..write('pointsJson: $pointsJson, ')
          ..write('color: $color, ')
          ..write('strokeWidth: $strokeWidth, ')
          ..write('label: $label, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MapRegionsTable extends MapRegions
    with TableInfo<$MapRegionsTable, MapRegion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MapRegionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _boundsNorthMeta =
      const VerificationMeta('boundsNorth');
  @override
  late final GeneratedColumn<double> boundsNorth = GeneratedColumn<double>(
      'bounds_north', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _boundsSouthMeta =
      const VerificationMeta('boundsSouth');
  @override
  late final GeneratedColumn<double> boundsSouth = GeneratedColumn<double>(
      'bounds_south', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _boundsEastMeta =
      const VerificationMeta('boundsEast');
  @override
  late final GeneratedColumn<double> boundsEast = GeneratedColumn<double>(
      'bounds_east', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _boundsWestMeta =
      const VerificationMeta('boundsWest');
  @override
  late final GeneratedColumn<double> boundsWest = GeneratedColumn<double>(
      'bounds_west', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _minZoomMeta =
      const VerificationMeta('minZoom');
  @override
  late final GeneratedColumn<int> minZoom = GeneratedColumn<int>(
      'min_zoom', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _maxZoomMeta =
      const VerificationMeta('maxZoom');
  @override
  late final GeneratedColumn<int> maxZoom = GeneratedColumn<int>(
      'max_zoom', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
      'downloaded_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        boundsNorth,
        boundsSouth,
        boundsEast,
        boundsWest,
        minZoom,
        maxZoom,
        sizeBytes,
        downloadedAt,
        filePath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'map_regions';
  @override
  VerificationContext validateIntegrity(Insertable<MapRegion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('bounds_north')) {
      context.handle(
          _boundsNorthMeta,
          boundsNorth.isAcceptableOrUnknown(
              data['bounds_north']!, _boundsNorthMeta));
    } else if (isInserting) {
      context.missing(_boundsNorthMeta);
    }
    if (data.containsKey('bounds_south')) {
      context.handle(
          _boundsSouthMeta,
          boundsSouth.isAcceptableOrUnknown(
              data['bounds_south']!, _boundsSouthMeta));
    } else if (isInserting) {
      context.missing(_boundsSouthMeta);
    }
    if (data.containsKey('bounds_east')) {
      context.handle(
          _boundsEastMeta,
          boundsEast.isAcceptableOrUnknown(
              data['bounds_east']!, _boundsEastMeta));
    } else if (isInserting) {
      context.missing(_boundsEastMeta);
    }
    if (data.containsKey('bounds_west')) {
      context.handle(
          _boundsWestMeta,
          boundsWest.isAcceptableOrUnknown(
              data['bounds_west']!, _boundsWestMeta));
    } else if (isInserting) {
      context.missing(_boundsWestMeta);
    }
    if (data.containsKey('min_zoom')) {
      context.handle(_minZoomMeta,
          minZoom.isAcceptableOrUnknown(data['min_zoom']!, _minZoomMeta));
    } else if (isInserting) {
      context.missing(_minZoomMeta);
    }
    if (data.containsKey('max_zoom')) {
      context.handle(_maxZoomMeta,
          maxZoom.isAcceptableOrUnknown(data['max_zoom']!, _maxZoomMeta));
    } else if (isInserting) {
      context.missing(_maxZoomMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
          _downloadedAtMeta,
          downloadedAt.isAcceptableOrUnknown(
              data['downloaded_at']!, _downloadedAtMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MapRegion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MapRegion(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      boundsNorth: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bounds_north'])!,
      boundsSouth: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bounds_south'])!,
      boundsEast: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bounds_east'])!,
      boundsWest: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bounds_west'])!,
      minZoom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_zoom'])!,
      maxZoom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_zoom'])!,
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes']),
      downloadedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}downloaded_at']),
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path']),
    );
  }

  @override
  $MapRegionsTable createAlias(String alias) {
    return $MapRegionsTable(attachedDatabase, alias);
  }
}

class MapRegion extends DataClass implements Insertable<MapRegion> {
  /// Unique region ID (UUID v4).
  final String id;

  /// Human-readable region name.
  final String name;

  /// Northern boundary latitude.
  final double boundsNorth;

  /// Southern boundary latitude.
  final double boundsSouth;

  /// Eastern boundary longitude.
  final double boundsEast;

  /// Western boundary longitude.
  final double boundsWest;

  /// Minimum zoom level.
  final int minZoom;

  /// Maximum zoom level.
  final int maxZoom;

  /// File size in bytes (null until downloaded).
  final int? sizeBytes;

  /// When the region was downloaded (null if not yet downloaded).
  final DateTime? downloadedAt;

  /// File system path to the downloaded tile data.
  final String? filePath;
  const MapRegion(
      {required this.id,
      required this.name,
      required this.boundsNorth,
      required this.boundsSouth,
      required this.boundsEast,
      required this.boundsWest,
      required this.minZoom,
      required this.maxZoom,
      this.sizeBytes,
      this.downloadedAt,
      this.filePath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['bounds_north'] = Variable<double>(boundsNorth);
    map['bounds_south'] = Variable<double>(boundsSouth);
    map['bounds_east'] = Variable<double>(boundsEast);
    map['bounds_west'] = Variable<double>(boundsWest);
    map['min_zoom'] = Variable<int>(minZoom);
    map['max_zoom'] = Variable<int>(maxZoom);
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || downloadedAt != null) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    return map;
  }

  MapRegionsCompanion toCompanion(bool nullToAbsent) {
    return MapRegionsCompanion(
      id: Value(id),
      name: Value(name),
      boundsNorth: Value(boundsNorth),
      boundsSouth: Value(boundsSouth),
      boundsEast: Value(boundsEast),
      boundsWest: Value(boundsWest),
      minZoom: Value(minZoom),
      maxZoom: Value(maxZoom),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      downloadedAt: downloadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedAt),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
    );
  }

  factory MapRegion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MapRegion(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      boundsNorth: serializer.fromJson<double>(json['boundsNorth']),
      boundsSouth: serializer.fromJson<double>(json['boundsSouth']),
      boundsEast: serializer.fromJson<double>(json['boundsEast']),
      boundsWest: serializer.fromJson<double>(json['boundsWest']),
      minZoom: serializer.fromJson<int>(json['minZoom']),
      maxZoom: serializer.fromJson<int>(json['maxZoom']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      downloadedAt: serializer.fromJson<DateTime?>(json['downloadedAt']),
      filePath: serializer.fromJson<String?>(json['filePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'boundsNorth': serializer.toJson<double>(boundsNorth),
      'boundsSouth': serializer.toJson<double>(boundsSouth),
      'boundsEast': serializer.toJson<double>(boundsEast),
      'boundsWest': serializer.toJson<double>(boundsWest),
      'minZoom': serializer.toJson<int>(minZoom),
      'maxZoom': serializer.toJson<int>(maxZoom),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'downloadedAt': serializer.toJson<DateTime?>(downloadedAt),
      'filePath': serializer.toJson<String?>(filePath),
    };
  }

  MapRegion copyWith(
          {String? id,
          String? name,
          double? boundsNorth,
          double? boundsSouth,
          double? boundsEast,
          double? boundsWest,
          int? minZoom,
          int? maxZoom,
          Value<int?> sizeBytes = const Value.absent(),
          Value<DateTime?> downloadedAt = const Value.absent(),
          Value<String?> filePath = const Value.absent()}) =>
      MapRegion(
        id: id ?? this.id,
        name: name ?? this.name,
        boundsNorth: boundsNorth ?? this.boundsNorth,
        boundsSouth: boundsSouth ?? this.boundsSouth,
        boundsEast: boundsEast ?? this.boundsEast,
        boundsWest: boundsWest ?? this.boundsWest,
        minZoom: minZoom ?? this.minZoom,
        maxZoom: maxZoom ?? this.maxZoom,
        sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
        downloadedAt:
            downloadedAt.present ? downloadedAt.value : this.downloadedAt,
        filePath: filePath.present ? filePath.value : this.filePath,
      );
  MapRegion copyWithCompanion(MapRegionsCompanion data) {
    return MapRegion(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      boundsNorth:
          data.boundsNorth.present ? data.boundsNorth.value : this.boundsNorth,
      boundsSouth:
          data.boundsSouth.present ? data.boundsSouth.value : this.boundsSouth,
      boundsEast:
          data.boundsEast.present ? data.boundsEast.value : this.boundsEast,
      boundsWest:
          data.boundsWest.present ? data.boundsWest.value : this.boundsWest,
      minZoom: data.minZoom.present ? data.minZoom.value : this.minZoom,
      maxZoom: data.maxZoom.present ? data.maxZoom.value : this.maxZoom,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MapRegion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('boundsNorth: $boundsNorth, ')
          ..write('boundsSouth: $boundsSouth, ')
          ..write('boundsEast: $boundsEast, ')
          ..write('boundsWest: $boundsWest, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('filePath: $filePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      boundsNorth,
      boundsSouth,
      boundsEast,
      boundsWest,
      minZoom,
      maxZoom,
      sizeBytes,
      downloadedAt,
      filePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MapRegion &&
          other.id == this.id &&
          other.name == this.name &&
          other.boundsNorth == this.boundsNorth &&
          other.boundsSouth == this.boundsSouth &&
          other.boundsEast == this.boundsEast &&
          other.boundsWest == this.boundsWest &&
          other.minZoom == this.minZoom &&
          other.maxZoom == this.maxZoom &&
          other.sizeBytes == this.sizeBytes &&
          other.downloadedAt == this.downloadedAt &&
          other.filePath == this.filePath);
}

class MapRegionsCompanion extends UpdateCompanion<MapRegion> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> boundsNorth;
  final Value<double> boundsSouth;
  final Value<double> boundsEast;
  final Value<double> boundsWest;
  final Value<int> minZoom;
  final Value<int> maxZoom;
  final Value<int?> sizeBytes;
  final Value<DateTime?> downloadedAt;
  final Value<String?> filePath;
  final Value<int> rowid;
  const MapRegionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.boundsNorth = const Value.absent(),
    this.boundsSouth = const Value.absent(),
    this.boundsEast = const Value.absent(),
    this.boundsWest = const Value.absent(),
    this.minZoom = const Value.absent(),
    this.maxZoom = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.filePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MapRegionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double boundsNorth,
    required double boundsSouth,
    required double boundsEast,
    required double boundsWest,
    required int minZoom,
    required int maxZoom,
    this.sizeBytes = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.filePath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        boundsNorth = Value(boundsNorth),
        boundsSouth = Value(boundsSouth),
        boundsEast = Value(boundsEast),
        boundsWest = Value(boundsWest),
        minZoom = Value(minZoom),
        maxZoom = Value(maxZoom);
  static Insertable<MapRegion> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? boundsNorth,
    Expression<double>? boundsSouth,
    Expression<double>? boundsEast,
    Expression<double>? boundsWest,
    Expression<int>? minZoom,
    Expression<int>? maxZoom,
    Expression<int>? sizeBytes,
    Expression<DateTime>? downloadedAt,
    Expression<String>? filePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (boundsNorth != null) 'bounds_north': boundsNorth,
      if (boundsSouth != null) 'bounds_south': boundsSouth,
      if (boundsEast != null) 'bounds_east': boundsEast,
      if (boundsWest != null) 'bounds_west': boundsWest,
      if (minZoom != null) 'min_zoom': minZoom,
      if (maxZoom != null) 'max_zoom': maxZoom,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (filePath != null) 'file_path': filePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MapRegionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<double>? boundsNorth,
      Value<double>? boundsSouth,
      Value<double>? boundsEast,
      Value<double>? boundsWest,
      Value<int>? minZoom,
      Value<int>? maxZoom,
      Value<int?>? sizeBytes,
      Value<DateTime?>? downloadedAt,
      Value<String?>? filePath,
      Value<int>? rowid}) {
    return MapRegionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      boundsNorth: boundsNorth ?? this.boundsNorth,
      boundsSouth: boundsSouth ?? this.boundsSouth,
      boundsEast: boundsEast ?? this.boundsEast,
      boundsWest: boundsWest ?? this.boundsWest,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      filePath: filePath ?? this.filePath,
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
    if (boundsNorth.present) {
      map['bounds_north'] = Variable<double>(boundsNorth.value);
    }
    if (boundsSouth.present) {
      map['bounds_south'] = Variable<double>(boundsSouth.value);
    }
    if (boundsEast.present) {
      map['bounds_east'] = Variable<double>(boundsEast.value);
    }
    if (boundsWest.present) {
      map['bounds_west'] = Variable<double>(boundsWest.value);
    }
    if (minZoom.present) {
      map['min_zoom'] = Variable<int>(minZoom.value);
    }
    if (maxZoom.present) {
      map['max_zoom'] = Variable<int>(maxZoom.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MapRegionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('boundsNorth: $boundsNorth, ')
          ..write('boundsSouth: $boundsSouth, ')
          ..write('boundsEast: $boundsEast, ')
          ..write('boundsWest: $boundsWest, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('filePath: $filePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $PeersTable peers = $PeersTable(this);
  late final $MarkersTable markers = $MarkersTable(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $AnnotationsTable annotations = $AnnotationsTable(this);
  late final $MapRegionsTable mapRegions = $MapRegionsTable(this);
  late final SessionsDao sessionsDao = SessionsDao(this as AppDatabase);
  late final PeersDao peersDao = PeersDao(this as AppDatabase);
  late final MarkersDao markersDao = MarkersDao(this as AppDatabase);
  late final TracksDao tracksDao = TracksDao(this as AppDatabase);
  late final AnnotationsDao annotationsDao =
      AnnotationsDao(this as AppDatabase);
  late final MapRegionsDao mapRegionsDao = MapRegionsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [sessions, peers, markers, tracks, annotations, mapRegions];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  required String name,
  Value<String> securityMode,
  Value<String?> pin,
  Value<String?> sessionKey,
  required DateTime createdAt,
  Value<String> operationalMode,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> securityMode,
  Value<String?> pin,
  Value<String?> sessionKey,
  Value<DateTime> createdAt,
  Value<String> operationalMode,
  Value<bool> isActive,
  Value<int> rowid,
});

class $$SessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder> {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SessionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SessionsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> securityMode = const Value.absent(),
            Value<String?> pin = const Value.absent(),
            Value<String?> sessionKey = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> operationalMode = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            name: name,
            securityMode: securityMode,
            pin: pin,
            sessionKey: sessionKey,
            createdAt: createdAt,
            operationalMode: operationalMode,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String name,
            Value<String> securityMode = const Value.absent(),
            Value<String?> pin = const Value.absent(),
            Value<String?> sessionKey = const Value.absent(),
            required DateTime createdAt,
            Value<String> operationalMode = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion.insert(
            id: id,
            name: name,
            securityMode: securityMode,
            pin: pin,
            sessionKey: sessionKey,
            createdAt: createdAt,
            operationalMode: operationalMode,
            isActive: isActive,
            rowid: rowid,
          ),
        ));
}

class $$SessionsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get securityMode => $state.composableBuilder(
      column: $state.table.securityMode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get pin => $state.composableBuilder(
      column: $state.table.pin,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sessionKey => $state.composableBuilder(
      column: $state.table.sessionKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get operationalMode => $state.composableBuilder(
      column: $state.table.operationalMode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SessionsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get securityMode => $state.composableBuilder(
      column: $state.table.securityMode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get pin => $state.composableBuilder(
      column: $state.table.pin,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sessionKey => $state.composableBuilder(
      column: $state.table.sessionKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get operationalMode => $state.composableBuilder(
      column: $state.table.operationalMode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$PeersTableCreateCompanionBuilder = PeersCompanion Function({
  Value<String> id,
  required String sessionId,
  required String displayName,
  Value<String> deviceType,
  Value<double?> lat,
  Value<double?> lon,
  Value<double?> altitude,
  Value<double?> speed,
  Value<double?> heading,
  Value<double?> accuracy,
  Value<String?> mgrsRaw,
  required DateTime lastSeen,
  Value<bool> isConnected,
  Value<int?> batteryLevel,
  Value<String> syncMode,
  Value<int> rowid,
});
typedef $$PeersTableUpdateCompanionBuilder = PeersCompanion Function({
  Value<String> id,
  Value<String> sessionId,
  Value<String> displayName,
  Value<String> deviceType,
  Value<double?> lat,
  Value<double?> lon,
  Value<double?> altitude,
  Value<double?> speed,
  Value<double?> heading,
  Value<double?> accuracy,
  Value<String?> mgrsRaw,
  Value<DateTime> lastSeen,
  Value<bool> isConnected,
  Value<int?> batteryLevel,
  Value<String> syncMode,
  Value<int> rowid,
});

class $$PeersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PeersTable,
    Peer,
    $$PeersTableFilterComposer,
    $$PeersTableOrderingComposer,
    $$PeersTableCreateCompanionBuilder,
    $$PeersTableUpdateCompanionBuilder> {
  $$PeersTableTableManager(_$AppDatabase db, $PeersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PeersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PeersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> deviceType = const Value.absent(),
            Value<double?> lat = const Value.absent(),
            Value<double?> lon = const Value.absent(),
            Value<double?> altitude = const Value.absent(),
            Value<double?> speed = const Value.absent(),
            Value<double?> heading = const Value.absent(),
            Value<double?> accuracy = const Value.absent(),
            Value<String?> mgrsRaw = const Value.absent(),
            Value<DateTime> lastSeen = const Value.absent(),
            Value<bool> isConnected = const Value.absent(),
            Value<int?> batteryLevel = const Value.absent(),
            Value<String> syncMode = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PeersCompanion(
            id: id,
            sessionId: sessionId,
            displayName: displayName,
            deviceType: deviceType,
            lat: lat,
            lon: lon,
            altitude: altitude,
            speed: speed,
            heading: heading,
            accuracy: accuracy,
            mgrsRaw: mgrsRaw,
            lastSeen: lastSeen,
            isConnected: isConnected,
            batteryLevel: batteryLevel,
            syncMode: syncMode,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String sessionId,
            required String displayName,
            Value<String> deviceType = const Value.absent(),
            Value<double?> lat = const Value.absent(),
            Value<double?> lon = const Value.absent(),
            Value<double?> altitude = const Value.absent(),
            Value<double?> speed = const Value.absent(),
            Value<double?> heading = const Value.absent(),
            Value<double?> accuracy = const Value.absent(),
            Value<String?> mgrsRaw = const Value.absent(),
            required DateTime lastSeen,
            Value<bool> isConnected = const Value.absent(),
            Value<int?> batteryLevel = const Value.absent(),
            Value<String> syncMode = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PeersCompanion.insert(
            id: id,
            sessionId: sessionId,
            displayName: displayName,
            deviceType: deviceType,
            lat: lat,
            lon: lon,
            altitude: altitude,
            speed: speed,
            heading: heading,
            accuracy: accuracy,
            mgrsRaw: mgrsRaw,
            lastSeen: lastSeen,
            isConnected: isConnected,
            batteryLevel: batteryLevel,
            syncMode: syncMode,
            rowid: rowid,
          ),
        ));
}

class $$PeersTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PeersTable> {
  $$PeersTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sessionId => $state.composableBuilder(
      column: $state.table.sessionId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get displayName => $state.composableBuilder(
      column: $state.table.displayName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get deviceType => $state.composableBuilder(
      column: $state.table.deviceType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get lat => $state.composableBuilder(
      column: $state.table.lat,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get lon => $state.composableBuilder(
      column: $state.table.lon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get altitude => $state.composableBuilder(
      column: $state.table.altitude,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get speed => $state.composableBuilder(
      column: $state.table.speed,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get heading => $state.composableBuilder(
      column: $state.table.heading,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get accuracy => $state.composableBuilder(
      column: $state.table.accuracy,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get mgrsRaw => $state.composableBuilder(
      column: $state.table.mgrsRaw,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastSeen => $state.composableBuilder(
      column: $state.table.lastSeen,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isConnected => $state.composableBuilder(
      column: $state.table.isConnected,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get batteryLevel => $state.composableBuilder(
      column: $state.table.batteryLevel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncMode => $state.composableBuilder(
      column: $state.table.syncMode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PeersTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PeersTable> {
  $$PeersTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sessionId => $state.composableBuilder(
      column: $state.table.sessionId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get displayName => $state.composableBuilder(
      column: $state.table.displayName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get deviceType => $state.composableBuilder(
      column: $state.table.deviceType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get lat => $state.composableBuilder(
      column: $state.table.lat,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get lon => $state.composableBuilder(
      column: $state.table.lon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get altitude => $state.composableBuilder(
      column: $state.table.altitude,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get speed => $state.composableBuilder(
      column: $state.table.speed,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get heading => $state.composableBuilder(
      column: $state.table.heading,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get accuracy => $state.composableBuilder(
      column: $state.table.accuracy,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get mgrsRaw => $state.composableBuilder(
      column: $state.table.mgrsRaw,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastSeen => $state.composableBuilder(
      column: $state.table.lastSeen,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isConnected => $state.composableBuilder(
      column: $state.table.isConnected,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get batteryLevel => $state.composableBuilder(
      column: $state.table.batteryLevel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncMode => $state.composableBuilder(
      column: $state.table.syncMode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$MarkersTableCreateCompanionBuilder = MarkersCompanion Function({
  Value<String> id,
  Value<String?> sessionId,
  required double lat,
  required double lon,
  required String mgrs,
  required String label,
  Value<String> icon,
  required String createdBy,
  required DateTime createdAt,
  Value<int> color,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$MarkersTableUpdateCompanionBuilder = MarkersCompanion Function({
  Value<String> id,
  Value<String?> sessionId,
  Value<double> lat,
  Value<double> lon,
  Value<String> mgrs,
  Value<String> label,
  Value<String> icon,
  Value<String> createdBy,
  Value<DateTime> createdAt,
  Value<int> color,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$MarkersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MarkersTable,
    Marker,
    $$MarkersTableFilterComposer,
    $$MarkersTableOrderingComposer,
    $$MarkersTableCreateCompanionBuilder,
    $$MarkersTableUpdateCompanionBuilder> {
  $$MarkersTableTableManager(_$AppDatabase db, $MarkersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MarkersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$MarkersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lon = const Value.absent(),
            Value<String> mgrs = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<String> createdBy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MarkersCompanion(
            id: id,
            sessionId: sessionId,
            lat: lat,
            lon: lon,
            mgrs: mgrs,
            label: label,
            icon: icon,
            createdBy: createdBy,
            createdAt: createdAt,
            color: color,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            required double lat,
            required double lon,
            required String mgrs,
            required String label,
            Value<String> icon = const Value.absent(),
            required String createdBy,
            required DateTime createdAt,
            Value<int> color = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MarkersCompanion.insert(
            id: id,
            sessionId: sessionId,
            lat: lat,
            lon: lon,
            mgrs: mgrs,
            label: label,
            icon: icon,
            createdBy: createdBy,
            createdAt: createdAt,
            color: color,
            isSynced: isSynced,
            rowid: rowid,
          ),
        ));
}

class $$MarkersTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MarkersTable> {
  $$MarkersTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sessionId => $state.composableBuilder(
      column: $state.table.sessionId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get lat => $state.composableBuilder(
      column: $state.table.lat,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get lon => $state.composableBuilder(
      column: $state.table.lon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get mgrs => $state.composableBuilder(
      column: $state.table.mgrs,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get label => $state.composableBuilder(
      column: $state.table.label,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdBy => $state.composableBuilder(
      column: $state.table.createdBy,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$MarkersTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MarkersTable> {
  $$MarkersTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sessionId => $state.composableBuilder(
      column: $state.table.sessionId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get lat => $state.composableBuilder(
      column: $state.table.lat,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get lon => $state.composableBuilder(
      column: $state.table.lon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get mgrs => $state.composableBuilder(
      column: $state.table.mgrs,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get label => $state.composableBuilder(
      column: $state.table.label,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdBy => $state.composableBuilder(
      column: $state.table.createdBy,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  Value<String?> sessionId,
  required double lat,
  required double lon,
  Value<double?> altitude,
  Value<double?> speed,
  Value<double?> heading,
  Value<double?> accuracy,
  required DateTime timestamp,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  Value<String?> sessionId,
  Value<double> lat,
  Value<double> lon,
  Value<double?> altitude,
  Value<double?> speed,
  Value<double?> heading,
  Value<double?> accuracy,
  Value<DateTime> timestamp,
});

class $$TracksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TracksTable,
    Track,
    $$TracksTableFilterComposer,
    $$TracksTableOrderingComposer,
    $$TracksTableCreateCompanionBuilder,
    $$TracksTableUpdateCompanionBuilder> {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TracksTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TracksTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lon = const Value.absent(),
            Value<double?> altitude = const Value.absent(),
            Value<double?> speed = const Value.absent(),
            Value<double?> heading = const Value.absent(),
            Value<double?> accuracy = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              TracksCompanion(
            id: id,
            sessionId: sessionId,
            lat: lat,
            lon: lon,
            altitude: altitude,
            speed: speed,
            heading: heading,
            accuracy: accuracy,
            timestamp: timestamp,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            required double lat,
            required double lon,
            Value<double?> altitude = const Value.absent(),
            Value<double?> speed = const Value.absent(),
            Value<double?> heading = const Value.absent(),
            Value<double?> accuracy = const Value.absent(),
            required DateTime timestamp,
          }) =>
              TracksCompanion.insert(
            id: id,
            sessionId: sessionId,
            lat: lat,
            lon: lon,
            altitude: altitude,
            speed: speed,
            heading: heading,
            accuracy: accuracy,
            timestamp: timestamp,
          ),
        ));
}

class $$TracksTableFilterComposer
    extends FilterComposer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sessionId => $state.composableBuilder(
      column: $state.table.sessionId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get lat => $state.composableBuilder(
      column: $state.table.lat,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get lon => $state.composableBuilder(
      column: $state.table.lon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get altitude => $state.composableBuilder(
      column: $state.table.altitude,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get speed => $state.composableBuilder(
      column: $state.table.speed,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get heading => $state.composableBuilder(
      column: $state.table.heading,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get accuracy => $state.composableBuilder(
      column: $state.table.accuracy,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$TracksTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sessionId => $state.composableBuilder(
      column: $state.table.sessionId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get lat => $state.composableBuilder(
      column: $state.table.lat,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get lon => $state.composableBuilder(
      column: $state.table.lon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get altitude => $state.composableBuilder(
      column: $state.table.altitude,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get speed => $state.composableBuilder(
      column: $state.table.speed,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get heading => $state.composableBuilder(
      column: $state.table.heading,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get accuracy => $state.composableBuilder(
      column: $state.table.accuracy,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$AnnotationsTableCreateCompanionBuilder = AnnotationsCompanion
    Function({
  Value<String> id,
  Value<String?> sessionId,
  required String type,
  required String pointsJson,
  Value<int> color,
  Value<double> strokeWidth,
  Value<String?> label,
  required String createdBy,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$AnnotationsTableUpdateCompanionBuilder = AnnotationsCompanion
    Function({
  Value<String> id,
  Value<String?> sessionId,
  Value<String> type,
  Value<String> pointsJson,
  Value<int> color,
  Value<double> strokeWidth,
  Value<String?> label,
  Value<String> createdBy,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$AnnotationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AnnotationsTable,
    Annotation,
    $$AnnotationsTableFilterComposer,
    $$AnnotationsTableOrderingComposer,
    $$AnnotationsTableCreateCompanionBuilder,
    $$AnnotationsTableUpdateCompanionBuilder> {
  $$AnnotationsTableTableManager(_$AppDatabase db, $AnnotationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AnnotationsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AnnotationsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> pointsJson = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<double> strokeWidth = const Value.absent(),
            Value<String?> label = const Value.absent(),
            Value<String> createdBy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnnotationsCompanion(
            id: id,
            sessionId: sessionId,
            type: type,
            pointsJson: pointsJson,
            color: color,
            strokeWidth: strokeWidth,
            label: label,
            createdBy: createdBy,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            required String type,
            required String pointsJson,
            Value<int> color = const Value.absent(),
            Value<double> strokeWidth = const Value.absent(),
            Value<String?> label = const Value.absent(),
            required String createdBy,
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnnotationsCompanion.insert(
            id: id,
            sessionId: sessionId,
            type: type,
            pointsJson: pointsJson,
            color: color,
            strokeWidth: strokeWidth,
            label: label,
            createdBy: createdBy,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
        ));
}

class $$AnnotationsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sessionId => $state.composableBuilder(
      column: $state.table.sessionId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get pointsJson => $state.composableBuilder(
      column: $state.table.pointsJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get strokeWidth => $state.composableBuilder(
      column: $state.table.strokeWidth,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get label => $state.composableBuilder(
      column: $state.table.label,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdBy => $state.composableBuilder(
      column: $state.table.createdBy,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AnnotationsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sessionId => $state.composableBuilder(
      column: $state.table.sessionId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get pointsJson => $state.composableBuilder(
      column: $state.table.pointsJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get strokeWidth => $state.composableBuilder(
      column: $state.table.strokeWidth,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get label => $state.composableBuilder(
      column: $state.table.label,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdBy => $state.composableBuilder(
      column: $state.table.createdBy,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$MapRegionsTableCreateCompanionBuilder = MapRegionsCompanion Function({
  Value<String> id,
  required String name,
  required double boundsNorth,
  required double boundsSouth,
  required double boundsEast,
  required double boundsWest,
  required int minZoom,
  required int maxZoom,
  Value<int?> sizeBytes,
  Value<DateTime?> downloadedAt,
  Value<String?> filePath,
  Value<int> rowid,
});
typedef $$MapRegionsTableUpdateCompanionBuilder = MapRegionsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<double> boundsNorth,
  Value<double> boundsSouth,
  Value<double> boundsEast,
  Value<double> boundsWest,
  Value<int> minZoom,
  Value<int> maxZoom,
  Value<int?> sizeBytes,
  Value<DateTime?> downloadedAt,
  Value<String?> filePath,
  Value<int> rowid,
});

class $$MapRegionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MapRegionsTable,
    MapRegion,
    $$MapRegionsTableFilterComposer,
    $$MapRegionsTableOrderingComposer,
    $$MapRegionsTableCreateCompanionBuilder,
    $$MapRegionsTableUpdateCompanionBuilder> {
  $$MapRegionsTableTableManager(_$AppDatabase db, $MapRegionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MapRegionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$MapRegionsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> boundsNorth = const Value.absent(),
            Value<double> boundsSouth = const Value.absent(),
            Value<double> boundsEast = const Value.absent(),
            Value<double> boundsWest = const Value.absent(),
            Value<int> minZoom = const Value.absent(),
            Value<int> maxZoom = const Value.absent(),
            Value<int?> sizeBytes = const Value.absent(),
            Value<DateTime?> downloadedAt = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MapRegionsCompanion(
            id: id,
            name: name,
            boundsNorth: boundsNorth,
            boundsSouth: boundsSouth,
            boundsEast: boundsEast,
            boundsWest: boundsWest,
            minZoom: minZoom,
            maxZoom: maxZoom,
            sizeBytes: sizeBytes,
            downloadedAt: downloadedAt,
            filePath: filePath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String name,
            required double boundsNorth,
            required double boundsSouth,
            required double boundsEast,
            required double boundsWest,
            required int minZoom,
            required int maxZoom,
            Value<int?> sizeBytes = const Value.absent(),
            Value<DateTime?> downloadedAt = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MapRegionsCompanion.insert(
            id: id,
            name: name,
            boundsNorth: boundsNorth,
            boundsSouth: boundsSouth,
            boundsEast: boundsEast,
            boundsWest: boundsWest,
            minZoom: minZoom,
            maxZoom: maxZoom,
            sizeBytes: sizeBytes,
            downloadedAt: downloadedAt,
            filePath: filePath,
            rowid: rowid,
          ),
        ));
}

class $$MapRegionsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MapRegionsTable> {
  $$MapRegionsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get boundsNorth => $state.composableBuilder(
      column: $state.table.boundsNorth,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get boundsSouth => $state.composableBuilder(
      column: $state.table.boundsSouth,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get boundsEast => $state.composableBuilder(
      column: $state.table.boundsEast,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get boundsWest => $state.composableBuilder(
      column: $state.table.boundsWest,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get minZoom => $state.composableBuilder(
      column: $state.table.minZoom,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get maxZoom => $state.composableBuilder(
      column: $state.table.maxZoom,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get sizeBytes => $state.composableBuilder(
      column: $state.table.sizeBytes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get downloadedAt => $state.composableBuilder(
      column: $state.table.downloadedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get filePath => $state.composableBuilder(
      column: $state.table.filePath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$MapRegionsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MapRegionsTable> {
  $$MapRegionsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get boundsNorth => $state.composableBuilder(
      column: $state.table.boundsNorth,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get boundsSouth => $state.composableBuilder(
      column: $state.table.boundsSouth,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get boundsEast => $state.composableBuilder(
      column: $state.table.boundsEast,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get boundsWest => $state.composableBuilder(
      column: $state.table.boundsWest,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get minZoom => $state.composableBuilder(
      column: $state.table.minZoom,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get maxZoom => $state.composableBuilder(
      column: $state.table.maxZoom,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sizeBytes => $state.composableBuilder(
      column: $state.table.sizeBytes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get downloadedAt => $state.composableBuilder(
      column: $state.table.downloadedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get filePath => $state.composableBuilder(
      column: $state.table.filePath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$PeersTableTableManager get peers =>
      $$PeersTableTableManager(_db, _db.peers);
  $$MarkersTableTableManager get markers =>
      $$MarkersTableTableManager(_db, _db.markers);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db, _db.annotations);
  $$MapRegionsTableTableManager get mapRegions =>
      $$MapRegionsTableTableManager(_db, _db.mapRegions);
}
