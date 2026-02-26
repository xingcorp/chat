// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_metadata_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetSyncMetadataModelCollection on Isar {
  IsarCollection<int, SyncMetadataModel> get syncMetadataModels =>
      this.collection();
}

const SyncMetadataModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'SyncMetadataModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'conversationId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'lastKnownTimestamp',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'lastSyncTime',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'updatedAt',
        type: IsarType.long,
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'conversationId',
        properties: [
          "conversationId",
        ],
        unique: true,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'updatedAt',
        properties: [
          "updatedAt",
        ],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, SyncMetadataModel>(
    serialize: serializeSyncMetadataModel,
    deserialize: deserializeSyncMetadataModel,
    deserializeProperty: deserializeSyncMetadataModelProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeSyncMetadataModel(IsarWriter writer, SyncMetadataModel object) {
  IsarCore.writeString(writer, 1, object.conversationId);
  IsarCore.writeLong(writer, 2, object.lastKnownTimestamp);
  IsarCore.writeLong(writer, 3, object.lastSyncTime);
  IsarCore.writeLong(writer, 4, object.updatedAt);
  return object.id;
}

@isarProtected
SyncMetadataModel deserializeSyncMetadataModel(IsarReader reader) {
  final int _id;
  _id = IsarCore.readId(reader);
  final String _conversationId;
  _conversationId = IsarCore.readString(reader, 1) ?? '';
  final int _lastKnownTimestamp;
  _lastKnownTimestamp = IsarCore.readLong(reader, 2);
  final int _lastSyncTime;
  _lastSyncTime = IsarCore.readLong(reader, 3);
  final int _updatedAt;
  _updatedAt = IsarCore.readLong(reader, 4);
  final object = SyncMetadataModel(
    id: _id,
    conversationId: _conversationId,
    lastKnownTimestamp: _lastKnownTimestamp,
    lastSyncTime: _lastSyncTime,
    updatedAt: _updatedAt,
  );
  return object;
}

@isarProtected
dynamic deserializeSyncMetadataModelProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readLong(reader, 2);
    case 3:
      return IsarCore.readLong(reader, 3);
    case 4:
      return IsarCore.readLong(reader, 4);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _SyncMetadataModelUpdate {
  bool call({
    required int id,
    String? conversationId,
    int? lastKnownTimestamp,
    int? lastSyncTime,
    int? updatedAt,
  });
}

class _SyncMetadataModelUpdateImpl implements _SyncMetadataModelUpdate {
  const _SyncMetadataModelUpdateImpl(this.collection);

  final IsarCollection<int, SyncMetadataModel> collection;

  @override
  bool call({
    required int id,
    Object? conversationId = ignore,
    Object? lastKnownTimestamp = ignore,
    Object? lastSyncTime = ignore,
    Object? updatedAt = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (conversationId != ignore) 1: conversationId as String?,
          if (lastKnownTimestamp != ignore) 2: lastKnownTimestamp as int?,
          if (lastSyncTime != ignore) 3: lastSyncTime as int?,
          if (updatedAt != ignore) 4: updatedAt as int?,
        }) >
        0;
  }
}

sealed class _SyncMetadataModelUpdateAll {
  int call({
    required List<int> id,
    String? conversationId,
    int? lastKnownTimestamp,
    int? lastSyncTime,
    int? updatedAt,
  });
}

class _SyncMetadataModelUpdateAllImpl implements _SyncMetadataModelUpdateAll {
  const _SyncMetadataModelUpdateAllImpl(this.collection);

  final IsarCollection<int, SyncMetadataModel> collection;

  @override
  int call({
    required List<int> id,
    Object? conversationId = ignore,
    Object? lastKnownTimestamp = ignore,
    Object? lastSyncTime = ignore,
    Object? updatedAt = ignore,
  }) {
    return collection.updateProperties(id, {
      if (conversationId != ignore) 1: conversationId as String?,
      if (lastKnownTimestamp != ignore) 2: lastKnownTimestamp as int?,
      if (lastSyncTime != ignore) 3: lastSyncTime as int?,
      if (updatedAt != ignore) 4: updatedAt as int?,
    });
  }
}

extension SyncMetadataModelUpdate on IsarCollection<int, SyncMetadataModel> {
  _SyncMetadataModelUpdate get update => _SyncMetadataModelUpdateImpl(this);

  _SyncMetadataModelUpdateAll get updateAll =>
      _SyncMetadataModelUpdateAllImpl(this);
}

sealed class _SyncMetadataModelQueryUpdate {
  int call({
    String? conversationId,
    int? lastKnownTimestamp,
    int? lastSyncTime,
    int? updatedAt,
  });
}

class _SyncMetadataModelQueryUpdateImpl
    implements _SyncMetadataModelQueryUpdate {
  const _SyncMetadataModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<SyncMetadataModel> query;
  final int? limit;

  @override
  int call({
    Object? conversationId = ignore,
    Object? lastKnownTimestamp = ignore,
    Object? lastSyncTime = ignore,
    Object? updatedAt = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (conversationId != ignore) 1: conversationId as String?,
      if (lastKnownTimestamp != ignore) 2: lastKnownTimestamp as int?,
      if (lastSyncTime != ignore) 3: lastSyncTime as int?,
      if (updatedAt != ignore) 4: updatedAt as int?,
    });
  }
}

extension SyncMetadataModelQueryUpdate on IsarQuery<SyncMetadataModel> {
  _SyncMetadataModelQueryUpdate get updateFirst =>
      _SyncMetadataModelQueryUpdateImpl(this, limit: 1);

  _SyncMetadataModelQueryUpdate get updateAll =>
      _SyncMetadataModelQueryUpdateImpl(this);
}

class _SyncMetadataModelQueryBuilderUpdateImpl
    implements _SyncMetadataModelQueryUpdate {
  const _SyncMetadataModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<SyncMetadataModel, SyncMetadataModel, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? conversationId = ignore,
    Object? lastKnownTimestamp = ignore,
    Object? lastSyncTime = ignore,
    Object? updatedAt = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (conversationId != ignore) 1: conversationId as String?,
        if (lastKnownTimestamp != ignore) 2: lastKnownTimestamp as int?,
        if (lastSyncTime != ignore) 3: lastSyncTime as int?,
        if (updatedAt != ignore) 4: updatedAt as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension SyncMetadataModelQueryBuilderUpdate
    on QueryBuilder<SyncMetadataModel, SyncMetadataModel, QOperations> {
  _SyncMetadataModelQueryUpdate get updateFirst =>
      _SyncMetadataModelQueryBuilderUpdateImpl(this, limit: 1);

  _SyncMetadataModelQueryUpdate get updateAll =>
      _SyncMetadataModelQueryBuilderUpdateImpl(this);
}

extension SyncMetadataModelQueryFilter
    on QueryBuilder<SyncMetadataModel, SyncMetadataModel, QFilterCondition> {
  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      idEqualTo(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      idLessThanOrEqualTo(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      conversationIdEqualTo(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      conversationIdGreaterThan(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      conversationIdGreaterThanOrEqualTo(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      conversationIdLessThan(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      conversationIdLessThanOrEqualTo(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      conversationIdBetween(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      conversationIdStartsWith(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      conversationIdEndsWith(
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      conversationIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      conversationIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      conversationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      conversationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      lastKnownTimestampEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      lastKnownTimestampGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      lastKnownTimestampGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      lastKnownTimestampLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      lastKnownTimestampLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      lastKnownTimestampBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      lastSyncTimeEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      lastSyncTimeGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      lastSyncTimeGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      lastSyncTimeLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      lastSyncTimeLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      lastSyncTimeBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      updatedAtEqualTo(
    int value,
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    int value,
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      updatedAtGreaterThanOrEqualTo(
    int value,
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      updatedAtLessThan(
    int value,
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      updatedAtLessThanOrEqualTo(
    int value,
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

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterFilterCondition>
      updatedAtBetween(
    int lower,
    int upper,
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
}

extension SyncMetadataModelQueryObject
    on QueryBuilder<SyncMetadataModel, SyncMetadataModel, QFilterCondition> {}

extension SyncMetadataModelQuerySortBy
    on QueryBuilder<SyncMetadataModel, SyncMetadataModel, QSortBy> {
  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      sortByConversationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      sortByConversationIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      sortByLastKnownTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      sortByLastKnownTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      sortByLastSyncTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      sortByLastSyncTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }
}

extension SyncMetadataModelQuerySortThenBy
    on QueryBuilder<SyncMetadataModel, SyncMetadataModel, QSortThenBy> {
  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      thenByConversationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      thenByConversationIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      thenByLastKnownTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      thenByLastKnownTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      thenByLastSyncTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      thenByLastSyncTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }
}

extension SyncMetadataModelQueryWhereDistinct
    on QueryBuilder<SyncMetadataModel, SyncMetadataModel, QDistinct> {
  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterDistinct>
      distinctByConversationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterDistinct>
      distinctByLastKnownTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterDistinct>
      distinctByLastSyncTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<SyncMetadataModel, SyncMetadataModel, QAfterDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }
}

extension SyncMetadataModelQueryProperty1
    on QueryBuilder<SyncMetadataModel, SyncMetadataModel, QProperty> {
  QueryBuilder<SyncMetadataModel, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<SyncMetadataModel, String, QAfterProperty>
      conversationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<SyncMetadataModel, int, QAfterProperty>
      lastKnownTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<SyncMetadataModel, int, QAfterProperty> lastSyncTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<SyncMetadataModel, int, QAfterProperty> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension SyncMetadataModelQueryProperty2<R>
    on QueryBuilder<SyncMetadataModel, R, QAfterProperty> {
  QueryBuilder<SyncMetadataModel, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<SyncMetadataModel, (R, String), QAfterProperty>
      conversationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<SyncMetadataModel, (R, int), QAfterProperty>
      lastKnownTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<SyncMetadataModel, (R, int), QAfterProperty>
      lastSyncTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<SyncMetadataModel, (R, int), QAfterProperty>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension SyncMetadataModelQueryProperty3<R1, R2>
    on QueryBuilder<SyncMetadataModel, (R1, R2), QAfterProperty> {
  QueryBuilder<SyncMetadataModel, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<SyncMetadataModel, (R1, R2, String), QOperations>
      conversationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<SyncMetadataModel, (R1, R2, int), QOperations>
      lastKnownTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<SyncMetadataModel, (R1, R2, int), QOperations>
      lastSyncTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<SyncMetadataModel, (R1, R2, int), QOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}
