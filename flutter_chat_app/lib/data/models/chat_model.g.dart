// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetChatModelCollection on Isar {
  IsarCollection<int, ChatModel> get chatModels => this.collection();
}

const ChatModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'ChatModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'serverId',
      type: IsarType.string,
    ),
      IsarPropertySchema(
        name: 'name',
      type: IsarType.string,
    ),
      IsarPropertySchema(
        name: 'type',
        type: IsarType.byte,
        enumMap: {"direct": 0, "group": 1, "channel": 2},
      ),
      IsarPropertySchema(
        name: 'lastMessageId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'lastMessagePreview',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'lastMessageTime',
      type: IsarType.dateTime,
    ),
      IsarPropertySchema(
        name: 'unreadCount',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'participantIds',
        type: IsarType.stringList,
      ),
      IsarPropertySchema(
        name: 'adminId',
      type: IsarType.string,
    ),
      IsarPropertySchema(
        name: 'avatarUrl',
      type: IsarType.string,
    ),
      IsarPropertySchema(
        name: 'isMuted',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'isPinned',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'createdAt',
      type: IsarType.dateTime,
    ),
      IsarPropertySchema(
        name: 'updatedAt',
        type: IsarType.dateTime,
      ),
      IsarPropertySchema(
        name: 'metadata',
      type: IsarType.string,
    ),
      IsarPropertySchema(
        name: 'metadataMap',
        type: IsarType.json,
      ),
      IsarPropertySchema(
        name: 'hasMessages',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'isGroup',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'isDirect',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'isChannel',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'participantCount',
      type: IsarType.long,
    ),
      IsarPropertySchema(
        name: 'isActive',
        type: IsarType.bool,
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'serverId',
      properties: [
          "serverId",
        ],
        unique: true,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'createdAt',
      properties: [
          "createdAt",
        ],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, ChatModel>(
    serialize: serializeChatModel,
    deserialize: deserializeChatModel,
    deserializeProperty: deserializeChatModelProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeChatModel(IsarWriter writer, ChatModel object) {
  IsarCore.writeString(writer, 1, object.serverId);
  {
    final value = object.name;
    if (value == null) {
      IsarCore.writeNull(writer, 2);
    } else {
      IsarCore.writeString(writer, 2, value);
    }
  }
  IsarCore.writeByte(writer, 3, object.type.index);
  {
    final value = object.lastMessageId;
    if (value == null) {
      IsarCore.writeNull(writer, 4);
    } else {
      IsarCore.writeString(writer, 4, value);
    }
  }
  {
    final value = object.lastMessagePreview;
    if (value == null) {
      IsarCore.writeNull(writer, 5);
    } else {
      IsarCore.writeString(writer, 5, value);
    }
  }
  IsarCore.writeLong(
      writer,
      6,
      object.lastMessageTime?.toUtc().microsecondsSinceEpoch ??
          -9223372036854775808);
  IsarCore.writeLong(writer, 7, object.unreadCount);
  {
    final list = object.participantIds;
    final listWriter = IsarCore.beginList(writer, 8, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  {
    final value = object.adminId;
    if (value == null) {
      IsarCore.writeNull(writer, 9);
    } else {
      IsarCore.writeString(writer, 9, value);
    }
  }
  {
    final value = object.avatarUrl;
    if (value == null) {
      IsarCore.writeNull(writer, 10);
    } else {
      IsarCore.writeString(writer, 10, value);
    }
  }
  IsarCore.writeBool(writer, 11, object.isMuted);
  IsarCore.writeBool(writer, 12, object.isPinned);
  IsarCore.writeLong(
      writer, 13, object.createdAt.toUtc().microsecondsSinceEpoch);
  IsarCore.writeLong(writer, 14,
      object.updatedAt?.toUtc().microsecondsSinceEpoch ?? -9223372036854775808);
  {
    final value = object.metadata;
    if (value == null) {
      IsarCore.writeNull(writer, 15);
    } else {
      IsarCore.writeString(writer, 15, value);
    }
  }
  IsarCore.writeString(writer, 16, isarJsonEncode(object.metadataMap));
  IsarCore.writeBool(writer, 17, object.hasMessages);
  IsarCore.writeBool(writer, 18, object.isGroup);
  IsarCore.writeBool(writer, 19, object.isDirect);
  IsarCore.writeBool(writer, 20, object.isChannel);
  IsarCore.writeLong(writer, 21, object.participantCount);
  IsarCore.writeBool(writer, 22, object.isActive);
  return object.id;
}

@isarProtected
ChatModel deserializeChatModel(IsarReader reader) {
  final int _id;
  _id = IsarCore.readId(reader);
  final String _serverId;
  _serverId = IsarCore.readString(reader, 1) ?? '';
  final String? _name;
  _name = IsarCore.readString(reader, 2);
  final ChatType _type;
  {
    if (IsarCore.readNull(reader, 3)) {
      _type = ChatType.direct;
    } else {
      _type = _chatModelType[IsarCore.readByte(reader, 3)] ?? ChatType.direct;
    }
  }
  final String? _lastMessageId;
  _lastMessageId = IsarCore.readString(reader, 4);
  final String? _lastMessagePreview;
  _lastMessagePreview = IsarCore.readString(reader, 5);
  final DateTime? _lastMessageTime;
  {
    final value = IsarCore.readLong(reader, 6);
    if (value == -9223372036854775808) {
      _lastMessageTime = null;
    } else {
      _lastMessageTime =
          DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }
  final int _unreadCount;
  {
    final value = IsarCore.readLong(reader, 7);
    if (value == -9223372036854775808) {
      _unreadCount = 0;
    } else {
      _unreadCount = value;
    }
  }
  final List<String> _participantIds;
  {
    final length = IsarCore.readList(reader, 8, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _participantIds = const <String>[];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        _participantIds = list;
      }
    }
  }
  final String? _adminId;
  _adminId = IsarCore.readString(reader, 9);
  final String? _avatarUrl;
  _avatarUrl = IsarCore.readString(reader, 10);
  final bool _isMuted;
  _isMuted = IsarCore.readBool(reader, 11);
  final bool _isPinned;
  _isPinned = IsarCore.readBool(reader, 12);
  final DateTime _createdAt;
  {
    final value = IsarCore.readLong(reader, 13);
    if (value == -9223372036854775808) {
      _createdAt =
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
    } else {
      _createdAt =
          DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }
  final DateTime? _updatedAt;
  {
    final value = IsarCore.readLong(reader, 14);
    if (value == -9223372036854775808) {
      _updatedAt = null;
    } else {
      _updatedAt =
          DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }
  final String? _metadata;
  _metadata = IsarCore.readString(reader, 15);
  final object = ChatModel(
    id: _id,
    serverId: _serverId,
    name: _name,
    type: _type,
    lastMessageId: _lastMessageId,
    lastMessagePreview: _lastMessagePreview,
    lastMessageTime: _lastMessageTime,
    unreadCount: _unreadCount,
    participantIds: _participantIds,
    adminId: _adminId,
    avatarUrl: _avatarUrl,
    isMuted: _isMuted,
    isPinned: _isPinned,
    createdAt: _createdAt,
    updatedAt: _updatedAt,
    metadata: _metadata,
  );
  return object;
}

@isarProtected
dynamic deserializeChatModelProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2);
    case 3:
      {
        if (IsarCore.readNull(reader, 3)) {
          return ChatType.direct;
        } else {
          return _chatModelType[IsarCore.readByte(reader, 3)] ??
              ChatType.direct;
        }
      }
    case 4:
      return IsarCore.readString(reader, 4);
    case 5:
      return IsarCore.readString(reader, 5);
    case 6:
      {
        final value = IsarCore.readLong(reader, 6);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true)
              .toLocal();
        }
      }
    case 7:
      {
        final value = IsarCore.readLong(reader, 7);
        if (value == -9223372036854775808) {
          return 0;
        } else {
          return value;
        }
      }
    case 8:
      {
        final length = IsarCore.readList(reader, 8, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return const <String>[];
          } else {
            final list = List<String>.filled(length, '', growable: true);
            for (var i = 0; i < length; i++) {
              list[i] = IsarCore.readString(reader, i) ?? '';
            }
            IsarCore.freeReader(reader);
            return list;
          }
        }
      }
    case 9:
      return IsarCore.readString(reader, 9);
    case 10:
      return IsarCore.readString(reader, 10);
    case 11:
      return IsarCore.readBool(reader, 11);
    case 12:
      return IsarCore.readBool(reader, 12);
    case 13:
      {
        final value = IsarCore.readLong(reader, 13);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true)
              .toLocal();
        }
      }
    case 14:
      {
        final value = IsarCore.readLong(reader, 14);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true)
              .toLocal();
        }
      }
    case 15:
      return IsarCore.readString(reader, 15);
    case 16:
      {
        final json = isarJsonDecode(IsarCore.readString(reader, 16) ?? 'null');
        if (json is Map<String, dynamic>) {
          return json;
        } else {
          return null;
        }
      }
    case 17:
      return IsarCore.readBool(reader, 17);
    case 18:
      return IsarCore.readBool(reader, 18);
    case 19:
      return IsarCore.readBool(reader, 19);
    case 20:
      return IsarCore.readBool(reader, 20);
    case 21:
      return IsarCore.readLong(reader, 21);
    case 22:
      return IsarCore.readBool(reader, 22);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _ChatModelUpdate {
  bool call({
    required int id,
    String? serverId,
    String? name,
    ChatType? type,
    String? lastMessageId,
    String? lastMessagePreview,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? adminId,
    String? avatarUrl,
    bool? isMuted,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? metadata,
    bool? hasMessages,
    bool? isGroup,
    bool? isDirect,
    bool? isChannel,
    int? participantCount,
    bool? isActive,
  });
}

class _ChatModelUpdateImpl implements _ChatModelUpdate {
  const _ChatModelUpdateImpl(this.collection);

  final IsarCollection<int, ChatModel> collection;

  @override
  bool call({
    required int id,
    Object? serverId = ignore,
    Object? name = ignore,
    Object? type = ignore,
    Object? lastMessageId = ignore,
    Object? lastMessagePreview = ignore,
    Object? lastMessageTime = ignore,
    Object? unreadCount = ignore,
    Object? adminId = ignore,
    Object? avatarUrl = ignore,
    Object? isMuted = ignore,
    Object? isPinned = ignore,
    Object? createdAt = ignore,
    Object? updatedAt = ignore,
    Object? metadata = ignore,
    Object? hasMessages = ignore,
    Object? isGroup = ignore,
    Object? isDirect = ignore,
    Object? isChannel = ignore,
    Object? participantCount = ignore,
    Object? isActive = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (serverId != ignore) 1: serverId as String?,
          if (name != ignore) 2: name as String?,
          if (type != ignore) 3: type as ChatType?,
          if (lastMessageId != ignore) 4: lastMessageId as String?,
          if (lastMessagePreview != ignore) 5: lastMessagePreview as String?,
          if (lastMessageTime != ignore) 6: lastMessageTime as DateTime?,
          if (unreadCount != ignore) 7: unreadCount as int?,
          if (adminId != ignore) 9: adminId as String?,
          if (avatarUrl != ignore) 10: avatarUrl as String?,
          if (isMuted != ignore) 11: isMuted as bool?,
          if (isPinned != ignore) 12: isPinned as bool?,
          if (createdAt != ignore) 13: createdAt as DateTime?,
          if (updatedAt != ignore) 14: updatedAt as DateTime?,
          if (metadata != ignore) 15: metadata as String?,
          if (hasMessages != ignore) 17: hasMessages as bool?,
          if (isGroup != ignore) 18: isGroup as bool?,
          if (isDirect != ignore) 19: isDirect as bool?,
          if (isChannel != ignore) 20: isChannel as bool?,
          if (participantCount != ignore) 21: participantCount as int?,
          if (isActive != ignore) 22: isActive as bool?,
        }) >
        0;
  }
}

sealed class _ChatModelUpdateAll {
  int call({
    required List<int> id,
    String? serverId,
    String? name,
    ChatType? type,
    String? lastMessageId,
    String? lastMessagePreview,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? adminId,
    String? avatarUrl,
    bool? isMuted,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? metadata,
    bool? hasMessages,
    bool? isGroup,
    bool? isDirect,
    bool? isChannel,
    int? participantCount,
    bool? isActive,
  });
}

class _ChatModelUpdateAllImpl implements _ChatModelUpdateAll {
  const _ChatModelUpdateAllImpl(this.collection);

  final IsarCollection<int, ChatModel> collection;

  @override
  int call({
    required List<int> id,
    Object? serverId = ignore,
    Object? name = ignore,
    Object? type = ignore,
    Object? lastMessageId = ignore,
    Object? lastMessagePreview = ignore,
    Object? lastMessageTime = ignore,
    Object? unreadCount = ignore,
    Object? adminId = ignore,
    Object? avatarUrl = ignore,
    Object? isMuted = ignore,
    Object? isPinned = ignore,
    Object? createdAt = ignore,
    Object? updatedAt = ignore,
    Object? metadata = ignore,
    Object? hasMessages = ignore,
    Object? isGroup = ignore,
    Object? isDirect = ignore,
    Object? isChannel = ignore,
    Object? participantCount = ignore,
    Object? isActive = ignore,
  }) {
    return collection.updateProperties(id, {
      if (serverId != ignore) 1: serverId as String?,
      if (name != ignore) 2: name as String?,
      if (type != ignore) 3: type as ChatType?,
      if (lastMessageId != ignore) 4: lastMessageId as String?,
      if (lastMessagePreview != ignore) 5: lastMessagePreview as String?,
      if (lastMessageTime != ignore) 6: lastMessageTime as DateTime?,
      if (unreadCount != ignore) 7: unreadCount as int?,
      if (adminId != ignore) 9: adminId as String?,
      if (avatarUrl != ignore) 10: avatarUrl as String?,
      if (isMuted != ignore) 11: isMuted as bool?,
      if (isPinned != ignore) 12: isPinned as bool?,
      if (createdAt != ignore) 13: createdAt as DateTime?,
      if (updatedAt != ignore) 14: updatedAt as DateTime?,
      if (metadata != ignore) 15: metadata as String?,
      if (hasMessages != ignore) 17: hasMessages as bool?,
      if (isGroup != ignore) 18: isGroup as bool?,
      if (isDirect != ignore) 19: isDirect as bool?,
      if (isChannel != ignore) 20: isChannel as bool?,
      if (participantCount != ignore) 21: participantCount as int?,
      if (isActive != ignore) 22: isActive as bool?,
    });
  }
}

extension ChatModelUpdate on IsarCollection<int, ChatModel> {
  _ChatModelUpdate get update => _ChatModelUpdateImpl(this);

  _ChatModelUpdateAll get updateAll => _ChatModelUpdateAllImpl(this);
}

sealed class _ChatModelQueryUpdate {
  int call({
    String? serverId,
    String? name,
    ChatType? type,
    String? lastMessageId,
    String? lastMessagePreview,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? adminId,
    String? avatarUrl,
    bool? isMuted,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? metadata,
    bool? hasMessages,
    bool? isGroup,
    bool? isDirect,
    bool? isChannel,
    int? participantCount,
    bool? isActive,
  });
}

class _ChatModelQueryUpdateImpl implements _ChatModelQueryUpdate {
  const _ChatModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<ChatModel> query;
  final int? limit;

  @override
  int call({
    Object? serverId = ignore,
    Object? name = ignore,
    Object? type = ignore,
    Object? lastMessageId = ignore,
    Object? lastMessagePreview = ignore,
    Object? lastMessageTime = ignore,
    Object? unreadCount = ignore,
    Object? adminId = ignore,
    Object? avatarUrl = ignore,
    Object? isMuted = ignore,
    Object? isPinned = ignore,
    Object? createdAt = ignore,
    Object? updatedAt = ignore,
    Object? metadata = ignore,
    Object? hasMessages = ignore,
    Object? isGroup = ignore,
    Object? isDirect = ignore,
    Object? isChannel = ignore,
    Object? participantCount = ignore,
    Object? isActive = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (serverId != ignore) 1: serverId as String?,
      if (name != ignore) 2: name as String?,
      if (type != ignore) 3: type as ChatType?,
      if (lastMessageId != ignore) 4: lastMessageId as String?,
      if (lastMessagePreview != ignore) 5: lastMessagePreview as String?,
      if (lastMessageTime != ignore) 6: lastMessageTime as DateTime?,
      if (unreadCount != ignore) 7: unreadCount as int?,
      if (adminId != ignore) 9: adminId as String?,
      if (avatarUrl != ignore) 10: avatarUrl as String?,
      if (isMuted != ignore) 11: isMuted as bool?,
      if (isPinned != ignore) 12: isPinned as bool?,
      if (createdAt != ignore) 13: createdAt as DateTime?,
      if (updatedAt != ignore) 14: updatedAt as DateTime?,
      if (metadata != ignore) 15: metadata as String?,
      if (hasMessages != ignore) 17: hasMessages as bool?,
      if (isGroup != ignore) 18: isGroup as bool?,
      if (isDirect != ignore) 19: isDirect as bool?,
      if (isChannel != ignore) 20: isChannel as bool?,
      if (participantCount != ignore) 21: participantCount as int?,
      if (isActive != ignore) 22: isActive as bool?,
    });
  }
}

extension ChatModelQueryUpdate on IsarQuery<ChatModel> {
  _ChatModelQueryUpdate get updateFirst =>
      _ChatModelQueryUpdateImpl(this, limit: 1);

  _ChatModelQueryUpdate get updateAll => _ChatModelQueryUpdateImpl(this);
}

class _ChatModelQueryBuilderUpdateImpl implements _ChatModelQueryUpdate {
  const _ChatModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<ChatModel, ChatModel, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? serverId = ignore,
    Object? name = ignore,
    Object? type = ignore,
    Object? lastMessageId = ignore,
    Object? lastMessagePreview = ignore,
    Object? lastMessageTime = ignore,
    Object? unreadCount = ignore,
    Object? adminId = ignore,
    Object? avatarUrl = ignore,
    Object? isMuted = ignore,
    Object? isPinned = ignore,
    Object? createdAt = ignore,
    Object? updatedAt = ignore,
    Object? metadata = ignore,
    Object? hasMessages = ignore,
    Object? isGroup = ignore,
    Object? isDirect = ignore,
    Object? isChannel = ignore,
    Object? participantCount = ignore,
    Object? isActive = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (serverId != ignore) 1: serverId as String?,
        if (name != ignore) 2: name as String?,
        if (type != ignore) 3: type as ChatType?,
        if (lastMessageId != ignore) 4: lastMessageId as String?,
        if (lastMessagePreview != ignore) 5: lastMessagePreview as String?,
        if (lastMessageTime != ignore) 6: lastMessageTime as DateTime?,
        if (unreadCount != ignore) 7: unreadCount as int?,
        if (adminId != ignore) 9: adminId as String?,
        if (avatarUrl != ignore) 10: avatarUrl as String?,
        if (isMuted != ignore) 11: isMuted as bool?,
        if (isPinned != ignore) 12: isPinned as bool?,
        if (createdAt != ignore) 13: createdAt as DateTime?,
        if (updatedAt != ignore) 14: updatedAt as DateTime?,
        if (metadata != ignore) 15: metadata as String?,
        if (hasMessages != ignore) 17: hasMessages as bool?,
        if (isGroup != ignore) 18: isGroup as bool?,
        if (isDirect != ignore) 19: isDirect as bool?,
        if (isChannel != ignore) 20: isChannel as bool?,
        if (participantCount != ignore) 21: participantCount as int?,
        if (isActive != ignore) 22: isActive as bool?,
      });
    } finally {
      q.close();
    }
  }
}

extension ChatModelQueryBuilderUpdate
    on QueryBuilder<ChatModel, ChatModel, QOperations> {
  _ChatModelQueryUpdate get updateFirst =>
      _ChatModelQueryBuilderUpdateImpl(this, limit: 1);

  _ChatModelQueryUpdate get updateAll => _ChatModelQueryBuilderUpdateImpl(this);
}

const _chatModelType = {
  0: ChatType.direct,
  1: ChatType.group,
  2: ChatType.channel,
};

extension ChatModelQueryFilter
    on QueryBuilder<ChatModel, ChatModel, QFilterCondition> {
  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> idLessThanOrEqualTo(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> serverIdEqualTo(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> serverIdGreaterThan(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      serverIdGreaterThanOrEqualTo(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> serverIdLessThan(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      serverIdLessThanOrEqualTo(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> serverIdBetween(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> serverIdStartsWith(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> serverIdEndsWith(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> serverIdContains(
      String value,
      {bool caseSensitive = true}) {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> serverIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> nameIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> nameEqualTo(
    String? value, {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> nameGreaterThan(
    String? value, {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      nameGreaterThanOrEqualTo(
    String? value, {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> nameLessThan(
    String? value, {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      nameLessThanOrEqualTo(
    String? value, {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> typeEqualTo(
    ChatType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 3,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> typeGreaterThan(
    ChatType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      typeGreaterThanOrEqualTo(
    ChatType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> typeLessThan(
    ChatType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 3,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      typeLessThanOrEqualTo(
    ChatType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> typeBetween(
    ChatType lower,
    ChatType upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower.index,
          upper: upper.index,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdEqualTo(
    String? value, {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdGreaterThan(
    String? value, {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdGreaterThanOrEqualTo(
    String? value, {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdLessThan(
    String? value, {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdLessThanOrEqualTo(
    String? value, {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdStartsWith(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdEndsWith(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 4,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 4,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewEqualTo(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewGreaterThan(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewGreaterThanOrEqualTo(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewLessThan(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewLessThanOrEqualTo(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewBetween(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewStartsWith(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewEndsWith(
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 5,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessagePreviewIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 5,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageTimeIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageTimeEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 6,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageTimeGreaterThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 6,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageTimeGreaterThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 6,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageTimeLessThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 6,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageTimeLessThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 6,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      lastMessageTimeBetween(
    DateTime? lower,
    DateTime? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 6,
        lower: lower,
        upper: upper,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> unreadCountEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 7,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      unreadCountGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 7,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      unreadCountGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 7,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> unreadCountLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 7,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      unreadCountLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 7,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> unreadCountBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 7,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 8,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsElementGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 8,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsElementGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 8,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsElementLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsElementLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsElementBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 8,
        lower: lower,
        upper: upper,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 8,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 8,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 8,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsElementMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 8,
        wildcard: pattern,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 8,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 8,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsIsEmpty() {
    return not().participantIdsIsNotEmpty();
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 8, value: null),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> adminIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 9));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> adminIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 9));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> adminIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 9,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> adminIdGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 9,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      adminIdGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 9,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> adminIdLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 9,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      adminIdLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 9,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> adminIdBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 9,
        lower: lower,
        upper: upper,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> adminIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 9,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> adminIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 9,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> adminIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 9,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> adminIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 9,
        wildcard: pattern,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> adminIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 9,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      adminIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 9,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> avatarUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 10));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      avatarUrlIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 10));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> avatarUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 10,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      avatarUrlGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 10,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      avatarUrlGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 10,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> avatarUrlLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 10,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      avatarUrlLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 10,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> avatarUrlBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 10,
        lower: lower,
        upper: upper,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> avatarUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 10,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> avatarUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 10,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> avatarUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 10,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> avatarUrlMatches(
      String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 10,
        wildcard: pattern,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> avatarUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 10,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      avatarUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 10,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> isMutedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 11,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> isPinnedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 12,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 13,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 13,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      createdAtGreaterThanOrEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 13,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> createdAtLessThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 13,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      createdAtLessThanOrEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 13,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 13,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 14));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 14));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> updatedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 14,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 14,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      updatedAtGreaterThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 14,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> updatedAtLessThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 14,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      updatedAtLessThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 14,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> updatedAtBetween(
    DateTime? lower,
    DateTime? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 14,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> metadataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 15));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      metadataIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 15));
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> metadataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 15,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> metadataGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 15,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      metadataGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 15,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> metadataLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 15,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      metadataLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 15,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> metadataBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 15,
        lower: lower,
        upper: upper,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> metadataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 15,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> metadataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 15,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> metadataContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 15,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> metadataMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 15,
        wildcard: pattern,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> metadataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 15,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      metadataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 15,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> hasMessagesEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 17,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> isGroupEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 18,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> isDirectEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 19,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> isChannelEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 20,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantCountEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 21,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantCountGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 21,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantCountGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 21,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantCountLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 21,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantCountLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 21,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition>
      participantCountBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 21,
        lower: lower,
        upper: upper,
        ),
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterFilterCondition> isActiveEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 22,
          value: value,
        ),
      );
    });
  }
}

extension ChatModelQueryObject
    on QueryBuilder<ChatModel, ChatModel, QFilterCondition> {}

extension ChatModelQuerySortBy on QueryBuilder<ChatModel, ChatModel, QSortBy> {
  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByServerIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByLastMessageId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByLastMessageIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByLastMessagePreview(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        5,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByLastMessagePreviewDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        5,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByLastMessageTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByLastMessageTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByUnreadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByAdminId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        9,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByAdminIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        9,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByAvatarUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        10,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByAvatarUrlDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        10,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIsMuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIsMutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByMetadata(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        15,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByMetadataDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        15,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByMetadataMap() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(16);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByMetadataMapDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(16, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByHasMessages() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(17);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByHasMessagesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(17, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIsGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(18);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIsGroupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(18, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIsDirect() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(19);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIsDirectDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(19, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIsChannel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(20);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIsChannelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(20, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByParticipantCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(21);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy>
      sortByParticipantCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(21, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(22);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(22, sort: Sort.desc);
    });
  }
}

extension ChatModelQuerySortThenBy
    on QueryBuilder<ChatModel, ChatModel, QSortThenBy> {
  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByServerIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByLastMessageId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByLastMessageIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByLastMessagePreview(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByLastMessagePreviewDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByLastMessageTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByLastMessageTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByUnreadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByAdminId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByAdminIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByAvatarUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByAvatarUrlDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIsMuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIsMutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByMetadata(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(15, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByMetadataDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(15, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByMetadataMap() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(16);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByMetadataMapDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(16, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByHasMessages() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(17);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByHasMessagesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(17, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIsGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(18);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIsGroupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(18, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIsDirect() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(19);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIsDirectDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(19, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIsChannel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(20);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIsChannelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(20, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByParticipantCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(21);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy>
      thenByParticipantCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(21, sort: Sort.desc);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(22);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterSortBy> thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(22, sort: Sort.desc);
    });
  }
}

extension ChatModelQueryWhereDistinct
    on QueryBuilder<ChatModel, ChatModel, QDistinct> {
  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByLastMessageId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct>
      distinctByLastMessagePreview({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct>
      distinctByLastMessageTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(7);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct>
      distinctByParticipantIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(8);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByAdminId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(9, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByAvatarUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(10, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByIsMuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(11);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(12);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(13);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(14);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByMetadata(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(15, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByMetadataMap() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(16);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByHasMessages() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(17);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByIsGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(18);
    });
}

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByIsDirect() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(19);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByIsChannel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(20);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct>
      distinctByParticipantCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(21);
    });
  }

  QueryBuilder<ChatModel, ChatModel, QAfterDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(22);
    });
  }
  }

extension ChatModelQueryProperty1
    on QueryBuilder<ChatModel, ChatModel, QProperty> {
  QueryBuilder<ChatModel, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ChatModel, String, QAfterProperty> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ChatModel, String?, QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ChatModel, ChatType, QAfterProperty> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ChatModel, String?, QAfterProperty> lastMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<ChatModel, String?, QAfterProperty>
      lastMessagePreviewProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<ChatModel, DateTime?, QAfterProperty> lastMessageTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<ChatModel, int, QAfterProperty> unreadCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<ChatModel, List<String>, QAfterProperty>
      participantIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<ChatModel, String?, QAfterProperty> adminIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<ChatModel, String?, QAfterProperty> avatarUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<ChatModel, bool, QAfterProperty> isMutedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<ChatModel, bool, QAfterProperty> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<ChatModel, DateTime, QAfterProperty> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }

  QueryBuilder<ChatModel, DateTime?, QAfterProperty> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(14);
    });
  }

  QueryBuilder<ChatModel, String?, QAfterProperty> metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(15);
    });
  }

  QueryBuilder<ChatModel, Map<String, dynamic>?, QAfterProperty>
      metadataMapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(16);
    });
  }

  QueryBuilder<ChatModel, bool, QAfterProperty> hasMessagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(17);
    });
  }

  QueryBuilder<ChatModel, bool, QAfterProperty> isGroupProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(18);
    });
  }

  QueryBuilder<ChatModel, bool, QAfterProperty> isDirectProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(19);
    });
  }

  QueryBuilder<ChatModel, bool, QAfterProperty> isChannelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(20);
    });
  }

  QueryBuilder<ChatModel, int, QAfterProperty> participantCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(21);
    });
  }

  QueryBuilder<ChatModel, bool, QAfterProperty> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(22);
    });
  }
}

extension ChatModelQueryProperty2<R>
    on QueryBuilder<ChatModel, R, QAfterProperty> {
  QueryBuilder<ChatModel, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ChatModel, (R, String), QAfterProperty> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ChatModel, (R, String?), QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ChatModel, (R, ChatType), QAfterProperty> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ChatModel, (R, String?), QAfterProperty>
      lastMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<ChatModel, (R, String?), QAfterProperty>
      lastMessagePreviewProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<ChatModel, (R, DateTime?), QAfterProperty>
      lastMessageTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<ChatModel, (R, int), QAfterProperty> unreadCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<ChatModel, (R, List<String>), QAfterProperty>
      participantIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<ChatModel, (R, String?), QAfterProperty> adminIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<ChatModel, (R, String?), QAfterProperty> avatarUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<ChatModel, (R, bool), QAfterProperty> isMutedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<ChatModel, (R, bool), QAfterProperty> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<ChatModel, (R, DateTime), QAfterProperty> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }

  QueryBuilder<ChatModel, (R, DateTime?), QAfterProperty> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(14);
    });
  }

  QueryBuilder<ChatModel, (R, String?), QAfterProperty> metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(15);
    });
  }

  QueryBuilder<ChatModel, (R, Map<String, dynamic>?), QAfterProperty>
      metadataMapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(16);
    });
  }

  QueryBuilder<ChatModel, (R, bool), QAfterProperty> hasMessagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(17);
    });
  }

  QueryBuilder<ChatModel, (R, bool), QAfterProperty> isGroupProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(18);
    });
  }

  QueryBuilder<ChatModel, (R, bool), QAfterProperty> isDirectProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(19);
    });
  }

  QueryBuilder<ChatModel, (R, bool), QAfterProperty> isChannelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(20);
    });
  }

  QueryBuilder<ChatModel, (R, int), QAfterProperty> participantCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(21);
    });
  }

  QueryBuilder<ChatModel, (R, bool), QAfterProperty> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(22);
    });
  }
}

extension ChatModelQueryProperty3<R1, R2>
    on QueryBuilder<ChatModel, (R1, R2), QAfterProperty> {
  QueryBuilder<ChatModel, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, String), QOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, String?), QOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, ChatType), QOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, String?), QOperations>
      lastMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, String?), QOperations>
      lastMessagePreviewProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, DateTime?), QOperations>
      lastMessageTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, int), QOperations> unreadCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, List<String>), QOperations>
      participantIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, String?), QOperations> adminIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, String?), QOperations> avatarUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, bool), QOperations> isMutedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, bool), QOperations> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, DateTime), QOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, DateTime?), QOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(14);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, String?), QOperations> metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(15);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, Map<String, dynamic>?), QOperations>
      metadataMapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(16);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, bool), QOperations> hasMessagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(17);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, bool), QOperations> isGroupProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(18);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, bool), QOperations> isDirectProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(19);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, bool), QOperations> isChannelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(20);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, int), QOperations>
      participantCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(21);
    });
  }

  QueryBuilder<ChatModel, (R1, R2, bool), QOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(22);
    });
  }
}
