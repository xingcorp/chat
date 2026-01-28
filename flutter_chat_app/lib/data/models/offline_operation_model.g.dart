// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_operation_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetOfflineOperationModelCollection on Isar {
  IsarCollection<int, OfflineOperationModel> get offlineOperationModels =>
      this.collection();
}

const OfflineOperationModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'OfflineOperationModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'operationId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'type',
        type: IsarType.byte,
        enumMap: {
          "sendMessage": 0,
          "editMessage": 1,
          "deleteMessage": 2,
          "markAsRead": 3,
          "addReaction": 4,
          "removeReaction": 5,
          "createGroup": 6,
          "editGroup": 7,
          "leaveConversation": 8,
          "deleteConversation": 9
        },
      ),
      IsarPropertySchema(
        name: 'data',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'timestamp',
        type: IsarType.dateTime,
      ),
      IsarPropertySchema(
        name: 'retryCount',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'status',
        type: IsarType.byte,
        enumMap: {"pending": 0, "processing": 1, "completed": 2, "failed": 3},
      ),
      IsarPropertySchema(
        name: 'errorMessage',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'lastRetryAt',
        type: IsarType.dateTime,
      ),
      IsarPropertySchema(
        name: 'dataMap',
        type: IsarType.json,
      ),
      IsarPropertySchema(
        name: 'canRetry',
        type: IsarType.bool,
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'operationId',
        properties: [
          "operationId",
        ],
        unique: true,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'timestamp',
        properties: [
          "timestamp",
        ],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, OfflineOperationModel>(
    serialize: serializeOfflineOperationModel,
    deserialize: deserializeOfflineOperationModel,
    deserializeProperty: deserializeOfflineOperationModelProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeOfflineOperationModel(
    IsarWriter writer, OfflineOperationModel object) {
  IsarCore.writeString(writer, 1, object.operationId);
  IsarCore.writeByte(writer, 2, object.type.index);
  IsarCore.writeString(writer, 3, object.data);
  IsarCore.writeLong(
      writer, 4, object.timestamp.toUtc().microsecondsSinceEpoch);
  IsarCore.writeLong(writer, 5, object.retryCount);
  IsarCore.writeByte(writer, 6, object.status.index);
  {
    final value = object.errorMessage;
    if (value == null) {
      IsarCore.writeNull(writer, 7);
    } else {
      IsarCore.writeString(writer, 7, value);
    }
  }
  IsarCore.writeLong(
      writer,
      8,
      object.lastRetryAt?.toUtc().microsecondsSinceEpoch ??
          -9223372036854775808);
  IsarCore.writeString(writer, 9, isarJsonEncode(object.dataMap));
  IsarCore.writeBool(writer, 10, object.canRetry);
  return object.id;
}

@isarProtected
OfflineOperationModel deserializeOfflineOperationModel(IsarReader reader) {
  final int _id;
  _id = IsarCore.readId(reader);
  final String _operationId;
  _operationId = IsarCore.readString(reader, 1) ?? '';
  final OperationType _type;
  {
    if (IsarCore.readNull(reader, 2)) {
      _type = OperationType.sendMessage;
    } else {
      _type = _offlineOperationModelType[IsarCore.readByte(reader, 2)] ??
          OperationType.sendMessage;
    }
  }
  final String _data;
  _data = IsarCore.readString(reader, 3) ?? '';
  final DateTime _timestamp;
  {
    final value = IsarCore.readLong(reader, 4);
    if (value == -9223372036854775808) {
      _timestamp =
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
    } else {
      _timestamp =
          DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }
  final int _retryCount;
  {
    final value = IsarCore.readLong(reader, 5);
    if (value == -9223372036854775808) {
      _retryCount = 0;
    } else {
      _retryCount = value;
    }
  }
  final OperationStatus _status;
  {
    if (IsarCore.readNull(reader, 6)) {
      _status = OperationStatus.pending;
    } else {
      _status = _offlineOperationModelStatus[IsarCore.readByte(reader, 6)] ??
          OperationStatus.pending;
    }
  }
  final String? _errorMessage;
  _errorMessage = IsarCore.readString(reader, 7);
  final DateTime? _lastRetryAt;
  {
    final value = IsarCore.readLong(reader, 8);
    if (value == -9223372036854775808) {
      _lastRetryAt = null;
    } else {
      _lastRetryAt =
          DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }
  final object = OfflineOperationModel(
    id: _id,
    operationId: _operationId,
    type: _type,
    data: _data,
    timestamp: _timestamp,
    retryCount: _retryCount,
    status: _status,
    errorMessage: _errorMessage,
    lastRetryAt: _lastRetryAt,
  );
  return object;
}

@isarProtected
dynamic deserializeOfflineOperationModelProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      {
        if (IsarCore.readNull(reader, 2)) {
          return OperationType.sendMessage;
        } else {
          return _offlineOperationModelType[IsarCore.readByte(reader, 2)] ??
              OperationType.sendMessage;
        }
      }
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 4:
      {
        final value = IsarCore.readLong(reader, 4);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true)
              .toLocal();
        }
      }
    case 5:
      {
        final value = IsarCore.readLong(reader, 5);
        if (value == -9223372036854775808) {
          return 0;
        } else {
          return value;
        }
      }
    case 6:
      {
        if (IsarCore.readNull(reader, 6)) {
          return OperationStatus.pending;
        } else {
          return _offlineOperationModelStatus[IsarCore.readByte(reader, 6)] ??
              OperationStatus.pending;
        }
      }
    case 7:
      return IsarCore.readString(reader, 7);
    case 8:
      {
        final value = IsarCore.readLong(reader, 8);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true)
              .toLocal();
        }
      }
    case 9:
      {
        final json = isarJsonDecode(IsarCore.readString(reader, 9) ?? 'null');
        if (json is Map<String, dynamic>) {
          return json;
        } else {
          return const <String, dynamic>{};
        }
      }
    case 10:
      return IsarCore.readBool(reader, 10);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _OfflineOperationModelUpdate {
  bool call({
    required int id,
    String? operationId,
    OperationType? type,
    String? data,
    DateTime? timestamp,
    int? retryCount,
    OperationStatus? status,
    String? errorMessage,
    DateTime? lastRetryAt,
    bool? canRetry,
  });
}

class _OfflineOperationModelUpdateImpl implements _OfflineOperationModelUpdate {
  const _OfflineOperationModelUpdateImpl(this.collection);

  final IsarCollection<int, OfflineOperationModel> collection;

  @override
  bool call({
    required int id,
    Object? operationId = ignore,
    Object? type = ignore,
    Object? data = ignore,
    Object? timestamp = ignore,
    Object? retryCount = ignore,
    Object? status = ignore,
    Object? errorMessage = ignore,
    Object? lastRetryAt = ignore,
    Object? canRetry = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (operationId != ignore) 1: operationId as String?,
          if (type != ignore) 2: type as OperationType?,
          if (data != ignore) 3: data as String?,
          if (timestamp != ignore) 4: timestamp as DateTime?,
          if (retryCount != ignore) 5: retryCount as int?,
          if (status != ignore) 6: status as OperationStatus?,
          if (errorMessage != ignore) 7: errorMessage as String?,
          if (lastRetryAt != ignore) 8: lastRetryAt as DateTime?,
          if (canRetry != ignore) 10: canRetry as bool?,
        }) >
        0;
  }
}

sealed class _OfflineOperationModelUpdateAll {
  int call({
    required List<int> id,
    String? operationId,
    OperationType? type,
    String? data,
    DateTime? timestamp,
    int? retryCount,
    OperationStatus? status,
    String? errorMessage,
    DateTime? lastRetryAt,
    bool? canRetry,
  });
}

class _OfflineOperationModelUpdateAllImpl
    implements _OfflineOperationModelUpdateAll {
  const _OfflineOperationModelUpdateAllImpl(this.collection);

  final IsarCollection<int, OfflineOperationModel> collection;

  @override
  int call({
    required List<int> id,
    Object? operationId = ignore,
    Object? type = ignore,
    Object? data = ignore,
    Object? timestamp = ignore,
    Object? retryCount = ignore,
    Object? status = ignore,
    Object? errorMessage = ignore,
    Object? lastRetryAt = ignore,
    Object? canRetry = ignore,
  }) {
    return collection.updateProperties(id, {
      if (operationId != ignore) 1: operationId as String?,
      if (type != ignore) 2: type as OperationType?,
      if (data != ignore) 3: data as String?,
      if (timestamp != ignore) 4: timestamp as DateTime?,
      if (retryCount != ignore) 5: retryCount as int?,
      if (status != ignore) 6: status as OperationStatus?,
      if (errorMessage != ignore) 7: errorMessage as String?,
      if (lastRetryAt != ignore) 8: lastRetryAt as DateTime?,
      if (canRetry != ignore) 10: canRetry as bool?,
    });
  }
}

extension OfflineOperationModelUpdate
    on IsarCollection<int, OfflineOperationModel> {
  _OfflineOperationModelUpdate get update =>
      _OfflineOperationModelUpdateImpl(this);

  _OfflineOperationModelUpdateAll get updateAll =>
      _OfflineOperationModelUpdateAllImpl(this);
}

sealed class _OfflineOperationModelQueryUpdate {
  int call({
    String? operationId,
    OperationType? type,
    String? data,
    DateTime? timestamp,
    int? retryCount,
    OperationStatus? status,
    String? errorMessage,
    DateTime? lastRetryAt,
    bool? canRetry,
  });
}

class _OfflineOperationModelQueryUpdateImpl
    implements _OfflineOperationModelQueryUpdate {
  const _OfflineOperationModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<OfflineOperationModel> query;
  final int? limit;

  @override
  int call({
    Object? operationId = ignore,
    Object? type = ignore,
    Object? data = ignore,
    Object? timestamp = ignore,
    Object? retryCount = ignore,
    Object? status = ignore,
    Object? errorMessage = ignore,
    Object? lastRetryAt = ignore,
    Object? canRetry = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (operationId != ignore) 1: operationId as String?,
      if (type != ignore) 2: type as OperationType?,
      if (data != ignore) 3: data as String?,
      if (timestamp != ignore) 4: timestamp as DateTime?,
      if (retryCount != ignore) 5: retryCount as int?,
      if (status != ignore) 6: status as OperationStatus?,
      if (errorMessage != ignore) 7: errorMessage as String?,
      if (lastRetryAt != ignore) 8: lastRetryAt as DateTime?,
      if (canRetry != ignore) 10: canRetry as bool?,
    });
  }
}

extension OfflineOperationModelQueryUpdate on IsarQuery<OfflineOperationModel> {
  _OfflineOperationModelQueryUpdate get updateFirst =>
      _OfflineOperationModelQueryUpdateImpl(this, limit: 1);

  _OfflineOperationModelQueryUpdate get updateAll =>
      _OfflineOperationModelQueryUpdateImpl(this);
}

class _OfflineOperationModelQueryBuilderUpdateImpl
    implements _OfflineOperationModelQueryUpdate {
  const _OfflineOperationModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<OfflineOperationModel, OfflineOperationModel, QOperations>
      query;
  final int? limit;

  @override
  int call({
    Object? operationId = ignore,
    Object? type = ignore,
    Object? data = ignore,
    Object? timestamp = ignore,
    Object? retryCount = ignore,
    Object? status = ignore,
    Object? errorMessage = ignore,
    Object? lastRetryAt = ignore,
    Object? canRetry = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (operationId != ignore) 1: operationId as String?,
        if (type != ignore) 2: type as OperationType?,
        if (data != ignore) 3: data as String?,
        if (timestamp != ignore) 4: timestamp as DateTime?,
        if (retryCount != ignore) 5: retryCount as int?,
        if (status != ignore) 6: status as OperationStatus?,
        if (errorMessage != ignore) 7: errorMessage as String?,
        if (lastRetryAt != ignore) 8: lastRetryAt as DateTime?,
        if (canRetry != ignore) 10: canRetry as bool?,
      });
    } finally {
      q.close();
    }
  }
}

extension OfflineOperationModelQueryBuilderUpdate
    on QueryBuilder<OfflineOperationModel, OfflineOperationModel, QOperations> {
  _OfflineOperationModelQueryUpdate get updateFirst =>
      _OfflineOperationModelQueryBuilderUpdateImpl(this, limit: 1);

  _OfflineOperationModelQueryUpdate get updateAll =>
      _OfflineOperationModelQueryBuilderUpdateImpl(this);
}

const _offlineOperationModelType = {
  0: OperationType.sendMessage,
  1: OperationType.editMessage,
  2: OperationType.deleteMessage,
  3: OperationType.markAsRead,
  4: OperationType.addReaction,
  5: OperationType.removeReaction,
  6: OperationType.createGroup,
  7: OperationType.editGroup,
  8: OperationType.leaveConversation,
  9: OperationType.deleteConversation,
};
const _offlineOperationModelStatus = {
  0: OperationStatus.pending,
  1: OperationStatus.processing,
  2: OperationStatus.completed,
  3: OperationStatus.failed,
};

extension OfflineOperationModelQueryFilter on QueryBuilder<
    OfflineOperationModel, OfflineOperationModel, QFilterCondition> {
  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> operationIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> operationIdGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> operationIdGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> operationIdLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> operationIdLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> operationIdBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> operationIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> operationIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
          QAfterFilterCondition>
      operationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
          QAfterFilterCondition>
      operationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> operationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> operationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> typeEqualTo(
    OperationType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> typeGreaterThan(
    OperationType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> typeGreaterThanOrEqualTo(
    OperationType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> typeLessThan(
    OperationType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> typeLessThanOrEqualTo(
    OperationType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> typeBetween(
    OperationType lower,
    OperationType upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower.index,
          upper: upper.index,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> dataEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> dataGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> dataGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> dataLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> dataLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> dataBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> dataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> dataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
          QAfterFilterCondition>
      dataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
          QAfterFilterCondition>
      dataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 3,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> dataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> dataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> timestampEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> timestampGreaterThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> timestampGreaterThanOrEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> timestampLessThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> timestampLessThanOrEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> retryCountEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 5,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> retryCountGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 5,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> retryCountGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 5,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> retryCountLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 5,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> retryCountLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 5,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> retryCountBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 5,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> statusEqualTo(
    OperationStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 6,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> statusGreaterThan(
    OperationStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 6,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> statusGreaterThanOrEqualTo(
    OperationStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 6,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> statusLessThan(
    OperationStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 6,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> statusLessThanOrEqualTo(
    OperationStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 6,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> statusBetween(
    OperationStatus lower,
    OperationStatus upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 6,
          lower: lower.index,
          upper: upper.index,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 7));
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> errorMessageIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 7));
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> errorMessageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> errorMessageGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> errorMessageGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> errorMessageLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> errorMessageLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> errorMessageBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 7,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> errorMessageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> errorMessageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
          QAfterFilterCondition>
      errorMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
          QAfterFilterCondition>
      errorMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 7,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 7,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 7,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> lastRetryAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 8));
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> lastRetryAtIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 8));
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> lastRetryAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 8,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> lastRetryAtGreaterThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 8,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> lastRetryAtGreaterThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 8,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> lastRetryAtLessThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 8,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> lastRetryAtLessThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 8,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> lastRetryAtBetween(
    DateTime? lower,
    DateTime? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 8,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel,
      QAfterFilterCondition> canRetryEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 10,
          value: value,
        ),
      );
    });
  }
}

extension OfflineOperationModelQueryObject on QueryBuilder<
    OfflineOperationModel, OfflineOperationModel, QFilterCondition> {}

extension OfflineOperationModelQuerySortBy
    on QueryBuilder<OfflineOperationModel, OfflineOperationModel, QSortBy> {
  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByOperationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByOperationIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByData({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByDataDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByErrorMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        7,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByErrorMessageDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        7,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByLastRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByLastRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByDataMap() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByDataMapDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByCanRetry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      sortByCanRetryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc);
    });
  }
}

extension OfflineOperationModelQuerySortThenBy
    on QueryBuilder<OfflineOperationModel, OfflineOperationModel, QSortThenBy> {
  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByOperationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByOperationIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByData({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByDataDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByErrorMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByErrorMessageDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByLastRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByLastRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByDataMap() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByDataMapDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9, sort: Sort.desc);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByCanRetry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterSortBy>
      thenByCanRetryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc);
    });
  }
}

extension OfflineOperationModelQueryWhereDistinct
    on QueryBuilder<OfflineOperationModel, OfflineOperationModel, QDistinct> {
  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterDistinct>
      distinctByOperationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterDistinct>
      distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterDistinct>
      distinctByData({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterDistinct>
      distinctByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterDistinct>
      distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterDistinct>
      distinctByErrorMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(7, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterDistinct>
      distinctByLastRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(8);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterDistinct>
      distinctByDataMap() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(9);
    });
  }

  QueryBuilder<OfflineOperationModel, OfflineOperationModel, QAfterDistinct>
      distinctByCanRetry() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(10);
    });
  }
}

extension OfflineOperationModelQueryProperty1
    on QueryBuilder<OfflineOperationModel, OfflineOperationModel, QProperty> {
  QueryBuilder<OfflineOperationModel, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<OfflineOperationModel, String, QAfterProperty>
      operationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<OfflineOperationModel, OperationType, QAfterProperty>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<OfflineOperationModel, String, QAfterProperty> dataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<OfflineOperationModel, DateTime, QAfterProperty>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<OfflineOperationModel, int, QAfterProperty>
      retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<OfflineOperationModel, OperationStatus, QAfterProperty>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<OfflineOperationModel, String?, QAfterProperty>
      errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<OfflineOperationModel, DateTime?, QAfterProperty>
      lastRetryAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<OfflineOperationModel, Map<String, dynamic>, QAfterProperty>
      dataMapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<OfflineOperationModel, bool, QAfterProperty> canRetryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }
}

extension OfflineOperationModelQueryProperty2<R>
    on QueryBuilder<OfflineOperationModel, R, QAfterProperty> {
  QueryBuilder<OfflineOperationModel, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<OfflineOperationModel, (R, String), QAfterProperty>
      operationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<OfflineOperationModel, (R, OperationType), QAfterProperty>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<OfflineOperationModel, (R, String), QAfterProperty>
      dataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<OfflineOperationModel, (R, DateTime), QAfterProperty>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<OfflineOperationModel, (R, int), QAfterProperty>
      retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<OfflineOperationModel, (R, OperationStatus), QAfterProperty>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<OfflineOperationModel, (R, String?), QAfterProperty>
      errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<OfflineOperationModel, (R, DateTime?), QAfterProperty>
      lastRetryAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<OfflineOperationModel, (R, Map<String, dynamic>), QAfterProperty>
      dataMapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<OfflineOperationModel, (R, bool), QAfterProperty>
      canRetryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }
}

extension OfflineOperationModelQueryProperty3<R1, R2>
    on QueryBuilder<OfflineOperationModel, (R1, R2), QAfterProperty> {
  QueryBuilder<OfflineOperationModel, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<OfflineOperationModel, (R1, R2, String), QOperations>
      operationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<OfflineOperationModel, (R1, R2, OperationType), QOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<OfflineOperationModel, (R1, R2, String), QOperations>
      dataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<OfflineOperationModel, (R1, R2, DateTime), QOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<OfflineOperationModel, (R1, R2, int), QOperations>
      retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<OfflineOperationModel, (R1, R2, OperationStatus), QOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<OfflineOperationModel, (R1, R2, String?), QOperations>
      errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<OfflineOperationModel, (R1, R2, DateTime?), QOperations>
      lastRetryAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<OfflineOperationModel, (R1, R2, Map<String, dynamic>),
      QOperations> dataMapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<OfflineOperationModel, (R1, R2, bool), QOperations>
      canRetryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }
}
