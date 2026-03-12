// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_draft_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetChatDraftModelCollection on Isar {
  IsarCollection<int, ChatDraftModel> get chatDraftModels => this.collection();
}

const ChatDraftModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'ChatDraftModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'conversationId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'text',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'updatedAt',
        type: IsarType.dateTime,
      ),
      IsarPropertySchema(
        name: 'mentionNameByIdJson',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'contentDelta',
        type: IsarType.string,
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
  converter: IsarObjectConverter<int, ChatDraftModel>(
    serialize: serializeChatDraftModel,
    deserialize: deserializeChatDraftModel,
    deserializeProperty: deserializeChatDraftModelProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeChatDraftModel(IsarWriter writer, ChatDraftModel object) {
  IsarCore.writeString(writer, 1, object.conversationId);
  IsarCore.writeString(writer, 2, object.text);
  IsarCore.writeLong(
      writer, 3, object.updatedAt.toUtc().microsecondsSinceEpoch);
  IsarCore.writeString(writer, 4, object.mentionNameByIdJson);
  {
    final value = object.contentDelta;
    if (value == null) {
      IsarCore.writeNull(writer, 5);
    } else {
      IsarCore.writeString(writer, 5, value);
    }
  }
  return object.id;
}

@isarProtected
ChatDraftModel deserializeChatDraftModel(IsarReader reader) {
  final int _id;
  _id = IsarCore.readId(reader);
  final String _conversationId;
  _conversationId = IsarCore.readString(reader, 1) ?? '';
  final String _text;
  _text = IsarCore.readString(reader, 2) ?? '';
  final DateTime _updatedAt;
  {
    final value = IsarCore.readLong(reader, 3);
    if (value == -9223372036854775808) {
      _updatedAt =
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
    } else {
      _updatedAt =
          DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }
  final String _mentionNameByIdJson;
  _mentionNameByIdJson = IsarCore.readString(reader, 4) ?? '';
  final String? _contentDelta;
  _contentDelta = IsarCore.readString(reader, 5);
  final object = ChatDraftModel(
    id: _id,
    conversationId: _conversationId,
    text: _text,
    updatedAt: _updatedAt,
    mentionNameByIdJson: _mentionNameByIdJson,
    contentDelta: _contentDelta,
  );
  return object;
}

@isarProtected
dynamic deserializeChatDraftModelProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      {
        final value = IsarCore.readLong(reader, 3);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true)
              .toLocal();
        }
      }
    case 4:
      return IsarCore.readString(reader, 4) ?? '';
    case 5:
      return IsarCore.readString(reader, 5);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _ChatDraftModelUpdate {
  bool call({
    required int id,
    String? conversationId,
    String? text,
    DateTime? updatedAt,
    String? mentionNameByIdJson,
    String? contentDelta,
  });
}

class _ChatDraftModelUpdateImpl implements _ChatDraftModelUpdate {
  const _ChatDraftModelUpdateImpl(this.collection);

  final IsarCollection<int, ChatDraftModel> collection;

  @override
  bool call({
    required int id,
    Object? conversationId = ignore,
    Object? text = ignore,
    Object? updatedAt = ignore,
    Object? mentionNameByIdJson = ignore,
    Object? contentDelta = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (conversationId != ignore) 1: conversationId as String?,
          if (text != ignore) 2: text as String?,
          if (updatedAt != ignore) 3: updatedAt as DateTime?,
          if (mentionNameByIdJson != ignore) 4: mentionNameByIdJson as String?,
          if (contentDelta != ignore) 5: contentDelta as String?,
        }) >
        0;
  }
}

sealed class _ChatDraftModelUpdateAll {
  int call({
    required List<int> id,
    String? conversationId,
    String? text,
    DateTime? updatedAt,
    String? mentionNameByIdJson,
    String? contentDelta,
  });
}

class _ChatDraftModelUpdateAllImpl implements _ChatDraftModelUpdateAll {
  const _ChatDraftModelUpdateAllImpl(this.collection);

  final IsarCollection<int, ChatDraftModel> collection;

  @override
  int call({
    required List<int> id,
    Object? conversationId = ignore,
    Object? text = ignore,
    Object? updatedAt = ignore,
    Object? mentionNameByIdJson = ignore,
    Object? contentDelta = ignore,
  }) {
    return collection.updateProperties(id, {
      if (conversationId != ignore) 1: conversationId as String?,
      if (text != ignore) 2: text as String?,
      if (updatedAt != ignore) 3: updatedAt as DateTime?,
      if (mentionNameByIdJson != ignore) 4: mentionNameByIdJson as String?,
      if (contentDelta != ignore) 5: contentDelta as String?,
    });
  }
}

extension ChatDraftModelUpdate on IsarCollection<int, ChatDraftModel> {
  _ChatDraftModelUpdate get update => _ChatDraftModelUpdateImpl(this);

  _ChatDraftModelUpdateAll get updateAll => _ChatDraftModelUpdateAllImpl(this);
}

sealed class _ChatDraftModelQueryUpdate {
  int call({
    String? conversationId,
    String? text,
    DateTime? updatedAt,
    String? mentionNameByIdJson,
    String? contentDelta,
  });
}

class _ChatDraftModelQueryUpdateImpl implements _ChatDraftModelQueryUpdate {
  const _ChatDraftModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<ChatDraftModel> query;
  final int? limit;

  @override
  int call({
    Object? conversationId = ignore,
    Object? text = ignore,
    Object? updatedAt = ignore,
    Object? mentionNameByIdJson = ignore,
    Object? contentDelta = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (conversationId != ignore) 1: conversationId as String?,
      if (text != ignore) 2: text as String?,
      if (updatedAt != ignore) 3: updatedAt as DateTime?,
      if (mentionNameByIdJson != ignore) 4: mentionNameByIdJson as String?,
      if (contentDelta != ignore) 5: contentDelta as String?,
    });
  }
}

extension ChatDraftModelQueryUpdate on IsarQuery<ChatDraftModel> {
  _ChatDraftModelQueryUpdate get updateFirst =>
      _ChatDraftModelQueryUpdateImpl(this, limit: 1);

  _ChatDraftModelQueryUpdate get updateAll =>
      _ChatDraftModelQueryUpdateImpl(this);
}

class _ChatDraftModelQueryBuilderUpdateImpl
    implements _ChatDraftModelQueryUpdate {
  const _ChatDraftModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<ChatDraftModel, ChatDraftModel, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? conversationId = ignore,
    Object? text = ignore,
    Object? updatedAt = ignore,
    Object? mentionNameByIdJson = ignore,
    Object? contentDelta = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (conversationId != ignore) 1: conversationId as String?,
        if (text != ignore) 2: text as String?,
        if (updatedAt != ignore) 3: updatedAt as DateTime?,
        if (mentionNameByIdJson != ignore) 4: mentionNameByIdJson as String?,
        if (contentDelta != ignore) 5: contentDelta as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension ChatDraftModelQueryBuilderUpdate
    on QueryBuilder<ChatDraftModel, ChatDraftModel, QOperations> {
  _ChatDraftModelQueryUpdate get updateFirst =>
      _ChatDraftModelQueryBuilderUpdateImpl(this, limit: 1);

  _ChatDraftModelQueryUpdate get updateAll =>
      _ChatDraftModelQueryBuilderUpdateImpl(this);
}

extension ChatDraftModelQueryFilter
    on QueryBuilder<ChatDraftModel, ChatDraftModel, QFilterCondition> {
  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      textGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      textGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      textLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      textLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      textBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      updatedAtEqualTo(
    DateTime value,
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value,
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      updatedAtGreaterThanOrEqualTo(
    DateTime value,
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value,
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      updatedAtLessThanOrEqualTo(
    DateTime value,
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper,
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

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      mentionNameByIdJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      mentionNameByIdJsonGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      mentionNameByIdJsonGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      mentionNameByIdJsonLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      mentionNameByIdJsonLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      mentionNameByIdJsonBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      mentionNameByIdJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      mentionNameByIdJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      mentionNameByIdJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      mentionNameByIdJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 4,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      mentionNameByIdJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      mentionNameByIdJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 5,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 5,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterFilterCondition>
      contentDeltaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }
}

extension ChatDraftModelQueryObject
    on QueryBuilder<ChatDraftModel, ChatDraftModel, QFilterCondition> {}

extension ChatDraftModelQuerySortBy
    on QueryBuilder<ChatDraftModel, ChatDraftModel, QSortBy> {
  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy>
      sortByConversationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy>
      sortByConversationIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy> sortByText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy> sortByTextDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy>
      sortByMentionNameByIdJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy>
      sortByMentionNameByIdJsonDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy> sortByContentDelta(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        5,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy>
      sortByContentDeltaDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        5,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension ChatDraftModelQuerySortThenBy
    on QueryBuilder<ChatDraftModel, ChatDraftModel, QSortThenBy> {
  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy>
      thenByConversationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy>
      thenByConversationIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy> thenByText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy> thenByTextDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy>
      thenByMentionNameByIdJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy>
      thenByMentionNameByIdJsonDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy> thenByContentDelta(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterSortBy>
      thenByContentDeltaDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension ChatDraftModelQueryWhereDistinct
    on QueryBuilder<ChatDraftModel, ChatDraftModel, QDistinct> {
  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterDistinct>
      distinctByConversationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterDistinct> distinctByText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterDistinct>
      distinctByMentionNameByIdJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatDraftModel, ChatDraftModel, QAfterDistinct>
      distinctByContentDelta({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5, caseSensitive: caseSensitive);
    });
  }
}

extension ChatDraftModelQueryProperty1
    on QueryBuilder<ChatDraftModel, ChatDraftModel, QProperty> {
  QueryBuilder<ChatDraftModel, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ChatDraftModel, String, QAfterProperty>
      conversationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ChatDraftModel, String, QAfterProperty> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ChatDraftModel, DateTime, QAfterProperty> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ChatDraftModel, String, QAfterProperty>
      mentionNameByIdJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<ChatDraftModel, String?, QAfterProperty> contentDeltaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

extension ChatDraftModelQueryProperty2<R>
    on QueryBuilder<ChatDraftModel, R, QAfterProperty> {
  QueryBuilder<ChatDraftModel, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ChatDraftModel, (R, String), QAfterProperty>
      conversationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ChatDraftModel, (R, String), QAfterProperty> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ChatDraftModel, (R, DateTime), QAfterProperty>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ChatDraftModel, (R, String), QAfterProperty>
      mentionNameByIdJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<ChatDraftModel, (R, String?), QAfterProperty>
      contentDeltaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

extension ChatDraftModelQueryProperty3<R1, R2>
    on QueryBuilder<ChatDraftModel, (R1, R2), QAfterProperty> {
  QueryBuilder<ChatDraftModel, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ChatDraftModel, (R1, R2, String), QOperations>
      conversationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ChatDraftModel, (R1, R2, String), QOperations> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ChatDraftModel, (R1, R2, DateTime), QOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ChatDraftModel, (R1, R2, String), QOperations>
      mentionNameByIdJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<ChatDraftModel, (R1, R2, String?), QOperations>
      contentDeltaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}
