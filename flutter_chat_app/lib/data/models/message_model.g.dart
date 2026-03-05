// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetMessageModelCollection on Isar {
  IsarCollection<int, MessageModel> get messageModels => this.collection();
}

const MessageModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'MessageModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'serverId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'localId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'chatId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'senderId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'readBy',
        type: IsarType.stringList,
      ),
      IsarPropertySchema(
        name: 'content',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'type',
        type: IsarType.byte,
        enumMap: {
          "text": 0,
          "image": 1,
          "video": 2,
          "audio": 3,
          "file": 4,
          "location": 5,
          "contact": 6,
          "system": 7,
          "sticker": 8
        },
      ),
      IsarPropertySchema(
        name: 'status',
        type: IsarType.byte,
        enumMap: {
          "pending": 0,
          "sending": 1,
          "sent": 2,
          "delivered": 3,
          "read": 4,
          "failed": 5
        },
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
        name: 'editedAt',
        type: IsarType.dateTime,
      ),
      IsarPropertySchema(
        name: 'deletedAt',
        type: IsarType.dateTime,
      ),
      IsarPropertySchema(
        name: 'urls',
        type: IsarType.stringList,
      ),
      IsarPropertySchema(
        name: 'fileName',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'forwardedFromMessageId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'mentionToJson',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'replyToMessageId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'metadata',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'isDeleted',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'isPinned',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'retryCount',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'errorMessage',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'metadataMap',
        type: IsarType.json,
      ),
      IsarPropertySchema(
        name: 'isMultimedia',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'isDisplayableMedia',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'isEditable',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'mediaDuration',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'fileSize',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'fileMimeType',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'mediaPath',
        type: IsarType.string,
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
        name: 'localId',
        properties: [
          "localId",
        ],
        unique: true,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'chatId',
        properties: [
          "chatId",
        ],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'senderId',
        properties: [
          "senderId",
        ],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'status',
        properties: [
          "status",
        ],
        unique: false,
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
  converter: IsarObjectConverter<int, MessageModel>(
    serialize: serializeMessageModel,
    deserialize: deserializeMessageModel,
    deserializeProperty: deserializeMessageModelProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeMessageModel(IsarWriter writer, MessageModel object) {
  {
    final value = object.serverId;
    if (value == null) {
      IsarCore.writeNull(writer, 1);
    } else {
      IsarCore.writeString(writer, 1, value);
    }
  }
  IsarCore.writeString(writer, 2, object.localId);
  IsarCore.writeString(writer, 3, object.chatId);
  IsarCore.writeString(writer, 4, object.senderId);
  {
    final list = object.readBy;
    final listWriter = IsarCore.beginList(writer, 5, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  IsarCore.writeString(writer, 6, object.content);
  IsarCore.writeByte(writer, 7, object.type.index);
  IsarCore.writeByte(writer, 8, object.status.index);
  IsarCore.writeLong(
      writer, 9, object.createdAt.toUtc().microsecondsSinceEpoch);
  IsarCore.writeLong(writer, 10,
      object.updatedAt?.toUtc().microsecondsSinceEpoch ?? -9223372036854775808);
  IsarCore.writeLong(writer, 11,
      object.editedAt?.toUtc().microsecondsSinceEpoch ?? -9223372036854775808);
  IsarCore.writeLong(writer, 12,
      object.deletedAt?.toUtc().microsecondsSinceEpoch ?? -9223372036854775808);
  {
    final list = object.urls;
    final listWriter = IsarCore.beginList(writer, 13, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  {
    final value = object.fileName;
    if (value == null) {
      IsarCore.writeNull(writer, 14);
    } else {
      IsarCore.writeString(writer, 14, value);
    }
  }
  {
    final value = object.forwardedFromMessageId;
    if (value == null) {
      IsarCore.writeNull(writer, 15);
    } else {
      IsarCore.writeString(writer, 15, value);
    }
  }
  {
    final value = object.mentionToJson;
    if (value == null) {
      IsarCore.writeNull(writer, 16);
    } else {
      IsarCore.writeString(writer, 16, value);
    }
  }
  {
    final value = object.replyToMessageId;
    if (value == null) {
      IsarCore.writeNull(writer, 17);
    } else {
      IsarCore.writeString(writer, 17, value);
    }
  }
  {
    final value = object.metadata;
    if (value == null) {
      IsarCore.writeNull(writer, 18);
    } else {
      IsarCore.writeString(writer, 18, value);
    }
  }
  IsarCore.writeBool(writer, 19, object.isDeleted);
  IsarCore.writeBool(writer, 20, object.isPinned);
  IsarCore.writeLong(writer, 21, object.retryCount);
  {
    final value = object.errorMessage;
    if (value == null) {
      IsarCore.writeNull(writer, 22);
    } else {
      IsarCore.writeString(writer, 22, value);
    }
  }
  IsarCore.writeString(writer, 23, isarJsonEncode(object.metadataMap));
  IsarCore.writeBool(writer, 24, object.isMultimedia);
  IsarCore.writeBool(writer, 25, object.isDisplayableMedia);
  IsarCore.writeBool(writer, 26, object.isEditable);
  IsarCore.writeLong(writer, 27, object.mediaDuration ?? -9223372036854775808);
  IsarCore.writeLong(writer, 28, object.fileSize ?? -9223372036854775808);
  {
    final value = object.fileMimeType;
    if (value == null) {
      IsarCore.writeNull(writer, 29);
    } else {
      IsarCore.writeString(writer, 29, value);
    }
  }
  {
    final value = object.mediaPath;
    if (value == null) {
      IsarCore.writeNull(writer, 30);
    } else {
      IsarCore.writeString(writer, 30, value);
    }
  }
  return object.id;
}

@isarProtected
MessageModel deserializeMessageModel(IsarReader reader) {
  final int _id;
  _id = IsarCore.readId(reader);
  final String? _serverId;
  _serverId = IsarCore.readString(reader, 1);
  final String _localId;
  _localId = IsarCore.readString(reader, 2) ?? '';
  final String _chatId;
  _chatId = IsarCore.readString(reader, 3) ?? '';
  final String _senderId;
  _senderId = IsarCore.readString(reader, 4) ?? '';
  final List<String> _readBy;
  {
    final length = IsarCore.readList(reader, 5, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _readBy = const [];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        _readBy = list;
      }
    }
  }
  final String _content;
  _content = IsarCore.readString(reader, 6) ?? '';
  final MessageType _type;
  {
    if (IsarCore.readNull(reader, 7)) {
      _type = MessageType.text;
    } else {
      _type =
          _messageModelType[IsarCore.readByte(reader, 7)] ?? MessageType.text;
    }
  }
  final MessageStatus _status;
  {
    if (IsarCore.readNull(reader, 8)) {
      _status = MessageStatus.pending;
    } else {
      _status = _messageModelStatus[IsarCore.readByte(reader, 8)] ??
          MessageStatus.pending;
    }
  }
  final DateTime _createdAt;
  {
    final value = IsarCore.readLong(reader, 9);
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
    final value = IsarCore.readLong(reader, 10);
    if (value == -9223372036854775808) {
      _updatedAt = null;
    } else {
      _updatedAt =
          DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }
  final DateTime? _editedAt;
  {
    final value = IsarCore.readLong(reader, 11);
    if (value == -9223372036854775808) {
      _editedAt = null;
    } else {
      _editedAt =
          DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }
  final DateTime? _deletedAt;
  {
    final value = IsarCore.readLong(reader, 12);
    if (value == -9223372036854775808) {
      _deletedAt = null;
    } else {
      _deletedAt =
          DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }
  final List<String> _urls;
  {
    final length = IsarCore.readList(reader, 13, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _urls = const [];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        _urls = list;
      }
    }
  }
  final String? _fileName;
  _fileName = IsarCore.readString(reader, 14);
  final String? _forwardedFromMessageId;
  _forwardedFromMessageId = IsarCore.readString(reader, 15);
  final String? _mentionToJson;
  _mentionToJson = IsarCore.readString(reader, 16);
  final String? _replyToMessageId;
  _replyToMessageId = IsarCore.readString(reader, 17);
  final String? _metadata;
  _metadata = IsarCore.readString(reader, 18);
  final bool _isDeleted;
  _isDeleted = IsarCore.readBool(reader, 19);
  final bool _isPinned;
  _isPinned = IsarCore.readBool(reader, 20);
  final int _retryCount;
  {
    final value = IsarCore.readLong(reader, 21);
    if (value == -9223372036854775808) {
      _retryCount = 0;
    } else {
      _retryCount = value;
    }
  }
  final String? _errorMessage;
  _errorMessage = IsarCore.readString(reader, 22);
  final object = MessageModel(
    id: _id,
    serverId: _serverId,
    localId: _localId,
    chatId: _chatId,
    senderId: _senderId,
    readBy: _readBy,
    content: _content,
    type: _type,
    status: _status,
    createdAt: _createdAt,
    updatedAt: _updatedAt,
    editedAt: _editedAt,
    deletedAt: _deletedAt,
    urls: _urls,
    fileName: _fileName,
    forwardedFromMessageId: _forwardedFromMessageId,
    mentionToJson: _mentionToJson,
    replyToMessageId: _replyToMessageId,
    metadata: _metadata,
    isDeleted: _isDeleted,
    isPinned: _isPinned,
    retryCount: _retryCount,
    errorMessage: _errorMessage,
  );
  return object;
}

@isarProtected
dynamic deserializeMessageModelProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1);
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 4:
      return IsarCore.readString(reader, 4) ?? '';
    case 5:
      {
        final length = IsarCore.readList(reader, 5, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return const [];
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
    case 6:
      return IsarCore.readString(reader, 6) ?? '';
    case 7:
      {
        if (IsarCore.readNull(reader, 7)) {
          return MessageType.text;
        } else {
          return _messageModelType[IsarCore.readByte(reader, 7)] ??
              MessageType.text;
        }
      }
    case 8:
      {
        if (IsarCore.readNull(reader, 8)) {
          return MessageStatus.pending;
        } else {
          return _messageModelStatus[IsarCore.readByte(reader, 8)] ??
              MessageStatus.pending;
        }
      }
    case 9:
      {
        final value = IsarCore.readLong(reader, 9);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true)
              .toLocal();
        }
      }
    case 10:
      {
        final value = IsarCore.readLong(reader, 10);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true)
              .toLocal();
        }
      }
    case 11:
      {
        final value = IsarCore.readLong(reader, 11);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true)
              .toLocal();
        }
      }
    case 12:
      {
        final value = IsarCore.readLong(reader, 12);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true)
              .toLocal();
        }
      }
    case 13:
      {
        final length = IsarCore.readList(reader, 13, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return const [];
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
    case 14:
      return IsarCore.readString(reader, 14);
    case 15:
      return IsarCore.readString(reader, 15);
    case 16:
      return IsarCore.readString(reader, 16);
    case 17:
      return IsarCore.readString(reader, 17);
    case 18:
      return IsarCore.readString(reader, 18);
    case 19:
      return IsarCore.readBool(reader, 19);
    case 20:
      return IsarCore.readBool(reader, 20);
    case 21:
      {
        final value = IsarCore.readLong(reader, 21);
        if (value == -9223372036854775808) {
          return 0;
        } else {
          return value;
        }
      }
    case 22:
      return IsarCore.readString(reader, 22);
    case 23:
      {
        final json = isarJsonDecode(IsarCore.readString(reader, 23) ?? 'null');
        if (json is Map<String, dynamic>) {
          return json;
        } else {
          return null;
        }
      }
    case 24:
      return IsarCore.readBool(reader, 24);
    case 25:
      return IsarCore.readBool(reader, 25);
    case 26:
      return IsarCore.readBool(reader, 26);
    case 27:
      {
        final value = IsarCore.readLong(reader, 27);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return value;
        }
      }
    case 28:
      {
        final value = IsarCore.readLong(reader, 28);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return value;
        }
      }
    case 29:
      return IsarCore.readString(reader, 29);
    case 30:
      return IsarCore.readString(reader, 30);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _MessageModelUpdate {
  bool call({
    required int id,
    String? serverId,
    String? localId,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? editedAt,
    DateTime? deletedAt,
    String? fileName,
    String? forwardedFromMessageId,
    String? mentionToJson,
    String? replyToMessageId,
    String? metadata,
    bool? isDeleted,
    bool? isPinned,
    int? retryCount,
    String? errorMessage,
    bool? isMultimedia,
    bool? isDisplayableMedia,
    bool? isEditable,
    int? mediaDuration,
    int? fileSize,
    String? fileMimeType,
    String? mediaPath,
  });
}

class _MessageModelUpdateImpl implements _MessageModelUpdate {
  const _MessageModelUpdateImpl(this.collection);

  final IsarCollection<int, MessageModel> collection;

  @override
  bool call({
    required int id,
    Object? serverId = ignore,
    Object? localId = ignore,
    Object? chatId = ignore,
    Object? senderId = ignore,
    Object? content = ignore,
    Object? type = ignore,
    Object? status = ignore,
    Object? createdAt = ignore,
    Object? updatedAt = ignore,
    Object? editedAt = ignore,
    Object? deletedAt = ignore,
    Object? fileName = ignore,
    Object? forwardedFromMessageId = ignore,
    Object? mentionToJson = ignore,
    Object? replyToMessageId = ignore,
    Object? metadata = ignore,
    Object? isDeleted = ignore,
    Object? isPinned = ignore,
    Object? retryCount = ignore,
    Object? errorMessage = ignore,
    Object? isMultimedia = ignore,
    Object? isDisplayableMedia = ignore,
    Object? isEditable = ignore,
    Object? mediaDuration = ignore,
    Object? fileSize = ignore,
    Object? fileMimeType = ignore,
    Object? mediaPath = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (serverId != ignore) 1: serverId as String?,
          if (localId != ignore) 2: localId as String?,
          if (chatId != ignore) 3: chatId as String?,
          if (senderId != ignore) 4: senderId as String?,
          if (content != ignore) 6: content as String?,
          if (type != ignore) 7: type as MessageType?,
          if (status != ignore) 8: status as MessageStatus?,
          if (createdAt != ignore) 9: createdAt as DateTime?,
          if (updatedAt != ignore) 10: updatedAt as DateTime?,
          if (editedAt != ignore) 11: editedAt as DateTime?,
          if (deletedAt != ignore) 12: deletedAt as DateTime?,
          if (fileName != ignore) 14: fileName as String?,
          if (forwardedFromMessageId != ignore)
            15: forwardedFromMessageId as String?,
          if (mentionToJson != ignore) 16: mentionToJson as String?,
          if (replyToMessageId != ignore) 17: replyToMessageId as String?,
          if (metadata != ignore) 18: metadata as String?,
          if (isDeleted != ignore) 19: isDeleted as bool?,
          if (isPinned != ignore) 20: isPinned as bool?,
          if (retryCount != ignore) 21: retryCount as int?,
          if (errorMessage != ignore) 22: errorMessage as String?,
          if (isMultimedia != ignore) 24: isMultimedia as bool?,
          if (isDisplayableMedia != ignore) 25: isDisplayableMedia as bool?,
          if (isEditable != ignore) 26: isEditable as bool?,
          if (mediaDuration != ignore) 27: mediaDuration as int?,
          if (fileSize != ignore) 28: fileSize as int?,
          if (fileMimeType != ignore) 29: fileMimeType as String?,
          if (mediaPath != ignore) 30: mediaPath as String?,
        }) >
        0;
  }
}

sealed class _MessageModelUpdateAll {
  int call({
    required List<int> id,
    String? serverId,
    String? localId,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? editedAt,
    DateTime? deletedAt,
    String? fileName,
    String? forwardedFromMessageId,
    String? mentionToJson,
    String? replyToMessageId,
    String? metadata,
    bool? isDeleted,
    bool? isPinned,
    int? retryCount,
    String? errorMessage,
    bool? isMultimedia,
    bool? isDisplayableMedia,
    bool? isEditable,
    int? mediaDuration,
    int? fileSize,
    String? fileMimeType,
    String? mediaPath,
  });
}

class _MessageModelUpdateAllImpl implements _MessageModelUpdateAll {
  const _MessageModelUpdateAllImpl(this.collection);

  final IsarCollection<int, MessageModel> collection;

  @override
  int call({
    required List<int> id,
    Object? serverId = ignore,
    Object? localId = ignore,
    Object? chatId = ignore,
    Object? senderId = ignore,
    Object? content = ignore,
    Object? type = ignore,
    Object? status = ignore,
    Object? createdAt = ignore,
    Object? updatedAt = ignore,
    Object? editedAt = ignore,
    Object? deletedAt = ignore,
    Object? fileName = ignore,
    Object? forwardedFromMessageId = ignore,
    Object? mentionToJson = ignore,
    Object? replyToMessageId = ignore,
    Object? metadata = ignore,
    Object? isDeleted = ignore,
    Object? isPinned = ignore,
    Object? retryCount = ignore,
    Object? errorMessage = ignore,
    Object? isMultimedia = ignore,
    Object? isDisplayableMedia = ignore,
    Object? isEditable = ignore,
    Object? mediaDuration = ignore,
    Object? fileSize = ignore,
    Object? fileMimeType = ignore,
    Object? mediaPath = ignore,
  }) {
    return collection.updateProperties(id, {
      if (serverId != ignore) 1: serverId as String?,
      if (localId != ignore) 2: localId as String?,
      if (chatId != ignore) 3: chatId as String?,
      if (senderId != ignore) 4: senderId as String?,
      if (content != ignore) 6: content as String?,
      if (type != ignore) 7: type as MessageType?,
      if (status != ignore) 8: status as MessageStatus?,
      if (createdAt != ignore) 9: createdAt as DateTime?,
      if (updatedAt != ignore) 10: updatedAt as DateTime?,
      if (editedAt != ignore) 11: editedAt as DateTime?,
      if (deletedAt != ignore) 12: deletedAt as DateTime?,
      if (fileName != ignore) 14: fileName as String?,
      if (forwardedFromMessageId != ignore)
        15: forwardedFromMessageId as String?,
      if (mentionToJson != ignore) 16: mentionToJson as String?,
      if (replyToMessageId != ignore) 17: replyToMessageId as String?,
      if (metadata != ignore) 18: metadata as String?,
      if (isDeleted != ignore) 19: isDeleted as bool?,
      if (isPinned != ignore) 20: isPinned as bool?,
      if (retryCount != ignore) 21: retryCount as int?,
      if (errorMessage != ignore) 22: errorMessage as String?,
      if (isMultimedia != ignore) 24: isMultimedia as bool?,
      if (isDisplayableMedia != ignore) 25: isDisplayableMedia as bool?,
      if (isEditable != ignore) 26: isEditable as bool?,
      if (mediaDuration != ignore) 27: mediaDuration as int?,
      if (fileSize != ignore) 28: fileSize as int?,
      if (fileMimeType != ignore) 29: fileMimeType as String?,
      if (mediaPath != ignore) 30: mediaPath as String?,
    });
  }
}

extension MessageModelUpdate on IsarCollection<int, MessageModel> {
  _MessageModelUpdate get update => _MessageModelUpdateImpl(this);

  _MessageModelUpdateAll get updateAll => _MessageModelUpdateAllImpl(this);
}

sealed class _MessageModelQueryUpdate {
  int call({
    String? serverId,
    String? localId,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? editedAt,
    DateTime? deletedAt,
    String? fileName,
    String? forwardedFromMessageId,
    String? mentionToJson,
    String? replyToMessageId,
    String? metadata,
    bool? isDeleted,
    bool? isPinned,
    int? retryCount,
    String? errorMessage,
    bool? isMultimedia,
    bool? isDisplayableMedia,
    bool? isEditable,
    int? mediaDuration,
    int? fileSize,
    String? fileMimeType,
    String? mediaPath,
  });
}

class _MessageModelQueryUpdateImpl implements _MessageModelQueryUpdate {
  const _MessageModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<MessageModel> query;
  final int? limit;

  @override
  int call({
    Object? serverId = ignore,
    Object? localId = ignore,
    Object? chatId = ignore,
    Object? senderId = ignore,
    Object? content = ignore,
    Object? type = ignore,
    Object? status = ignore,
    Object? createdAt = ignore,
    Object? updatedAt = ignore,
    Object? editedAt = ignore,
    Object? deletedAt = ignore,
    Object? fileName = ignore,
    Object? forwardedFromMessageId = ignore,
    Object? mentionToJson = ignore,
    Object? replyToMessageId = ignore,
    Object? metadata = ignore,
    Object? isDeleted = ignore,
    Object? isPinned = ignore,
    Object? retryCount = ignore,
    Object? errorMessage = ignore,
    Object? isMultimedia = ignore,
    Object? isDisplayableMedia = ignore,
    Object? isEditable = ignore,
    Object? mediaDuration = ignore,
    Object? fileSize = ignore,
    Object? fileMimeType = ignore,
    Object? mediaPath = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (serverId != ignore) 1: serverId as String?,
      if (localId != ignore) 2: localId as String?,
      if (chatId != ignore) 3: chatId as String?,
      if (senderId != ignore) 4: senderId as String?,
      if (content != ignore) 6: content as String?,
      if (type != ignore) 7: type as MessageType?,
      if (status != ignore) 8: status as MessageStatus?,
      if (createdAt != ignore) 9: createdAt as DateTime?,
      if (updatedAt != ignore) 10: updatedAt as DateTime?,
      if (editedAt != ignore) 11: editedAt as DateTime?,
      if (deletedAt != ignore) 12: deletedAt as DateTime?,
      if (fileName != ignore) 14: fileName as String?,
      if (forwardedFromMessageId != ignore)
        15: forwardedFromMessageId as String?,
      if (mentionToJson != ignore) 16: mentionToJson as String?,
      if (replyToMessageId != ignore) 17: replyToMessageId as String?,
      if (metadata != ignore) 18: metadata as String?,
      if (isDeleted != ignore) 19: isDeleted as bool?,
      if (isPinned != ignore) 20: isPinned as bool?,
      if (retryCount != ignore) 21: retryCount as int?,
      if (errorMessage != ignore) 22: errorMessage as String?,
      if (isMultimedia != ignore) 24: isMultimedia as bool?,
      if (isDisplayableMedia != ignore) 25: isDisplayableMedia as bool?,
      if (isEditable != ignore) 26: isEditable as bool?,
      if (mediaDuration != ignore) 27: mediaDuration as int?,
      if (fileSize != ignore) 28: fileSize as int?,
      if (fileMimeType != ignore) 29: fileMimeType as String?,
      if (mediaPath != ignore) 30: mediaPath as String?,
    });
  }
}

extension MessageModelQueryUpdate on IsarQuery<MessageModel> {
  _MessageModelQueryUpdate get updateFirst =>
      _MessageModelQueryUpdateImpl(this, limit: 1);

  _MessageModelQueryUpdate get updateAll => _MessageModelQueryUpdateImpl(this);
}

class _MessageModelQueryBuilderUpdateImpl implements _MessageModelQueryUpdate {
  const _MessageModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<MessageModel, MessageModel, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? serverId = ignore,
    Object? localId = ignore,
    Object? chatId = ignore,
    Object? senderId = ignore,
    Object? content = ignore,
    Object? type = ignore,
    Object? status = ignore,
    Object? createdAt = ignore,
    Object? updatedAt = ignore,
    Object? editedAt = ignore,
    Object? deletedAt = ignore,
    Object? fileName = ignore,
    Object? forwardedFromMessageId = ignore,
    Object? mentionToJson = ignore,
    Object? replyToMessageId = ignore,
    Object? metadata = ignore,
    Object? isDeleted = ignore,
    Object? isPinned = ignore,
    Object? retryCount = ignore,
    Object? errorMessage = ignore,
    Object? isMultimedia = ignore,
    Object? isDisplayableMedia = ignore,
    Object? isEditable = ignore,
    Object? mediaDuration = ignore,
    Object? fileSize = ignore,
    Object? fileMimeType = ignore,
    Object? mediaPath = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (serverId != ignore) 1: serverId as String?,
        if (localId != ignore) 2: localId as String?,
        if (chatId != ignore) 3: chatId as String?,
        if (senderId != ignore) 4: senderId as String?,
        if (content != ignore) 6: content as String?,
        if (type != ignore) 7: type as MessageType?,
        if (status != ignore) 8: status as MessageStatus?,
        if (createdAt != ignore) 9: createdAt as DateTime?,
        if (updatedAt != ignore) 10: updatedAt as DateTime?,
        if (editedAt != ignore) 11: editedAt as DateTime?,
        if (deletedAt != ignore) 12: deletedAt as DateTime?,
        if (fileName != ignore) 14: fileName as String?,
        if (forwardedFromMessageId != ignore)
          15: forwardedFromMessageId as String?,
        if (mentionToJson != ignore) 16: mentionToJson as String?,
        if (replyToMessageId != ignore) 17: replyToMessageId as String?,
        if (metadata != ignore) 18: metadata as String?,
        if (isDeleted != ignore) 19: isDeleted as bool?,
        if (isPinned != ignore) 20: isPinned as bool?,
        if (retryCount != ignore) 21: retryCount as int?,
        if (errorMessage != ignore) 22: errorMessage as String?,
        if (isMultimedia != ignore) 24: isMultimedia as bool?,
        if (isDisplayableMedia != ignore) 25: isDisplayableMedia as bool?,
        if (isEditable != ignore) 26: isEditable as bool?,
        if (mediaDuration != ignore) 27: mediaDuration as int?,
        if (fileSize != ignore) 28: fileSize as int?,
        if (fileMimeType != ignore) 29: fileMimeType as String?,
        if (mediaPath != ignore) 30: mediaPath as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension MessageModelQueryBuilderUpdate
    on QueryBuilder<MessageModel, MessageModel, QOperations> {
  _MessageModelQueryUpdate get updateFirst =>
      _MessageModelQueryBuilderUpdateImpl(this, limit: 1);

  _MessageModelQueryUpdate get updateAll =>
      _MessageModelQueryBuilderUpdateImpl(this);
}

const _messageModelType = {
  0: MessageType.text,
  1: MessageType.image,
  2: MessageType.video,
  3: MessageType.audio,
  4: MessageType.file,
  5: MessageType.location,
  6: MessageType.contact,
  7: MessageType.system,
  8: MessageType.sticker,
};
const _messageModelStatus = {
  0: MessageStatus.pending,
  1: MessageStatus.sending,
  2: MessageStatus.sent,
  3: MessageStatus.delivered,
  4: MessageStatus.read,
  5: MessageStatus.failed,
};

extension MessageModelQueryFilter
    on QueryBuilder<MessageModel, MessageModel, QFilterCondition> {
  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdEqualTo(
    String? value, {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdGreaterThan(
    String? value, {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdGreaterThanOrEqualTo(
    String? value, {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdLessThan(
    String? value, {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdLessThanOrEqualTo(
    String? value, {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdStartsWith(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdEndsWith(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      localIdEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      localIdGreaterThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      localIdGreaterThanOrEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      localIdLessThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      localIdLessThanOrEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      localIdBetween(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      localIdStartsWith(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      localIdEndsWith(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      localIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      localIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      localIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      localIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> chatIdEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      chatIdGreaterThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      chatIdGreaterThanOrEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      chatIdLessThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      chatIdLessThanOrEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> chatIdBetween(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      chatIdStartsWith(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      chatIdEndsWith(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      chatIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> chatIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      chatIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      chatIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      senderIdEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      senderIdGreaterThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      senderIdGreaterThanOrEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      senderIdLessThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      senderIdLessThanOrEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      senderIdBetween(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      senderIdStartsWith(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      senderIdEndsWith(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      senderIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      senderIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      senderIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      senderIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByElementEqualTo(
    String value, {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByElementGreaterThan(
    String value, {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByElementGreaterThanOrEqualTo(
    String value, {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByElementLessThan(
    String value, {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByElementLessThanOrEqualTo(
    String value, {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByElementBetween(
    String lower,
    String upper, {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByElementStartsWith(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByElementEndsWith(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByElementContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByElementMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByIsEmpty() {
    return not().readByIsNotEmpty();
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      readByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 5, value: null),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      contentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      contentGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      contentGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      contentLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      contentLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      contentBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 6,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      contentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      contentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 6,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 6,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 6,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> typeEqualTo(
    MessageType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 7,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      typeGreaterThan(
    MessageType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 7,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      typeGreaterThanOrEqualTo(
    MessageType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 7,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> typeLessThan(
    MessageType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 7,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      typeLessThanOrEqualTo(
    MessageType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 7,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> typeBetween(
    MessageType lower,
    MessageType upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 7,
          lower: lower.index,
          upper: upper.index,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> statusEqualTo(
    MessageStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 8,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      statusGreaterThan(
    MessageStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 8,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      statusGreaterThanOrEqualTo(
    MessageStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 8,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      statusLessThan(
    MessageStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 8,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      statusLessThanOrEqualTo(
    MessageStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 8,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> statusBetween(
    MessageStatus lower,
    MessageStatus upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 8,
          lower: lower.index,
          upper: upper.index,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 9,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 9,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      createdAtGreaterThanOrEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 9,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 9,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      createdAtLessThanOrEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 9,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 9,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 10));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 10));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      updatedAtEqualTo(
    DateTime? value,
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 10,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      updatedAtGreaterThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 10,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 10,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      updatedAtLessThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 10,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 10,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      editedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 11));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      editedAtIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 11));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      editedAtEqualTo(
    DateTime? value,
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      editedAtGreaterThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 11,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      editedAtGreaterThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 11,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      editedAtLessThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 11,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      editedAtLessThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 11,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      editedAtBetween(
    DateTime? lower,
    DateTime? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 11,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 12));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 12));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      deletedAtEqualTo(
    DateTime? value,
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      deletedAtGreaterThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 12,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      deletedAtGreaterThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 12,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      deletedAtLessThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 12,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      deletedAtLessThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 12,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      deletedAtBetween(
    DateTime? lower,
    DateTime? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 12,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsElementGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsElementGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsElementLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsElementLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsElementBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 13,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 13,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 13,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 13,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsIsEmpty() {
    return not().urlsIsNotEmpty();
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      urlsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 13, value: null),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 14));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 14));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 14,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 14,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 14,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 14,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 14,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 14,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 14,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 14,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 14,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 14,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 14,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 14,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 15));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 15));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdGreaterThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdGreaterThanOrEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdLessThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdLessThanOrEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdBetween(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdStartsWith(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdEndsWith(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdContains(String value,
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdMatches(String pattern,
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 15,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      forwardedFromMessageIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 15,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 16));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 16));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 16,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 16,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 16,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 16,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 16,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 16,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 16,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 16,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 16,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 16,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 16,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mentionToJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 16,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 17));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 17));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 17,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 17,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 17,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 17,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 17,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 17,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 17,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 17,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 17,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 17,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 17,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      replyToMessageIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 17,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 18));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 18));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 18,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 18,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 18,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 18,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 18,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 18,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 18,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 18,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 18,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 18,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 18,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      metadataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 18,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      isDeletedEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      isPinnedEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      retryCountEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      retryCountGreaterThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      retryCountGreaterThanOrEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      retryCountLessThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      retryCountLessThanOrEqualTo(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      retryCountBetween(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 22));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 22));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 22,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 22,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 22,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 22,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 22,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 22,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 22,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 22,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 22,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 22,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 22,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 22,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      isMultimediaEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 24,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      isDisplayableMediaEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 25,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      isEditableEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 26,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaDurationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 27));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaDurationIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 27));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaDurationEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 27,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaDurationGreaterThan(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 27,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaDurationGreaterThanOrEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 27,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaDurationLessThan(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 27,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaDurationLessThanOrEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 27,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaDurationBetween(
    int? lower,
    int? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 27,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileSizeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 28));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileSizeIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 28));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileSizeEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 28,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileSizeGreaterThan(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 28,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileSizeGreaterThanOrEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 28,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileSizeLessThan(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 28,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileSizeLessThanOrEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 28,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileSizeBetween(
    int? lower,
    int? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 28,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 29));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 29));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 29,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 29,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 29,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 29,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 29,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 29,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 29,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 29,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 29,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 29,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 29,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      fileMimeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 29,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 30));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 30));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 30,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 30,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 30,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 30,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 30,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 30,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 30,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 30,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 30,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 30,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 30,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
      mediaPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 30,
          value: '',
        ),
      );
    });
  }
}

extension MessageModelQueryObject
    on QueryBuilder<MessageModel, MessageModel, QFilterCondition> {}

extension MessageModelQuerySortBy
    on QueryBuilder<MessageModel, MessageModel, QSortBy> {
  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByServerIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByLocalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByLocalIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByChatId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByChatIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortBySenderId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortBySenderIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        6,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByContentDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        6,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByEditedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByEditedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByFileName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        14,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByFileNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        14,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      sortByForwardedFromMessageId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        15,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      sortByForwardedFromMessageIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        15,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByMentionToJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        16,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      sortByMentionToJsonDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        16,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByReplyToMessageId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        17,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      sortByReplyToMessageIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        17,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByMetadata(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        18,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByMetadataDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        18,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(19);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(19, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(20);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(20, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(21);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      sortByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(21, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByErrorMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        22,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByErrorMessageDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        22,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByMetadataMap() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(23);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      sortByMetadataMapDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(23, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsMultimedia() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(24);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      sortByIsMultimediaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(24, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      sortByIsDisplayableMedia() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(25);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      sortByIsDisplayableMediaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(25, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsEditable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(26);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      sortByIsEditableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(26, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByMediaDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(27);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      sortByMediaDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(27, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(28);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByFileSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(28, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByFileMimeType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        29,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByFileMimeTypeDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        29,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByMediaPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        30,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByMediaPathDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        30,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension MessageModelQuerySortThenBy
    on QueryBuilder<MessageModel, MessageModel, QSortThenBy> {
  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByServerIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByLocalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByLocalIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByChatId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByChatIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenBySenderId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenBySenderIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByContentDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByEditedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByEditedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByFileName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByFileNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      thenByForwardedFromMessageId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(15, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      thenByForwardedFromMessageIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(15, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByMentionToJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(16, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      thenByMentionToJsonDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(16, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByReplyToMessageId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(17, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      thenByReplyToMessageIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(17, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByMetadata(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(18, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByMetadataDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(18, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(19);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(19, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(20);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(20, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(21);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      thenByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(21, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByErrorMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(22, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByErrorMessageDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(22, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByMetadataMap() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(23);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      thenByMetadataMapDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(23, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsMultimedia() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(24);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      thenByIsMultimediaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(24, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      thenByIsDisplayableMedia() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(25);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      thenByIsDisplayableMediaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(25, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsEditable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(26);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      thenByIsEditableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(26, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByMediaDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(27);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
      thenByMediaDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(27, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(28);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByFileSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(28, sort: Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByFileMimeType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(29, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByFileMimeTypeDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(29, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByMediaPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(30, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByMediaPathDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(30, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension MessageModelQueryWhereDistinct
    on QueryBuilder<MessageModel, MessageModel, QDistinct> {
  QueryBuilder<MessageModel, MessageModel, QAfterDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct> distinctByLocalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct> distinctByChatId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct> distinctBySenderId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct> distinctByReadBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct> distinctByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(7);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(8);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(9);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(10);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByEditedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(11);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(12);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct> distinctByUrls() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(13);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct> distinctByFileName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(14, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByForwardedFromMessageId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(15, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByMentionToJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(16, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByReplyToMessageId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(17, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct> distinctByMetadata(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(18, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(19);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(20);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(21);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByErrorMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(22, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByMetadataMap() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(23);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByIsMultimedia() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(24);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByIsDisplayableMedia() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(25);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByIsEditable() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(26);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByMediaDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(27);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(28);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct>
      distinctByFileMimeType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(29, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterDistinct> distinctByMediaPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(30, caseSensitive: caseSensitive);
    });
  }
}

extension MessageModelQueryProperty1
    on QueryBuilder<MessageModel, MessageModel, QProperty> {
  QueryBuilder<MessageModel, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<MessageModel, String?, QAfterProperty> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<MessageModel, String, QAfterProperty> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<MessageModel, String, QAfterProperty> chatIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<MessageModel, String, QAfterProperty> senderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<MessageModel, List<String>, QAfterProperty> readByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<MessageModel, String, QAfterProperty> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<MessageModel, MessageType, QAfterProperty> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<MessageModel, MessageStatus, QAfterProperty> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<MessageModel, DateTime, QAfterProperty> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<MessageModel, DateTime?, QAfterProperty> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<MessageModel, DateTime?, QAfterProperty> editedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<MessageModel, DateTime?, QAfterProperty> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<MessageModel, List<String>, QAfterProperty> urlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }

  QueryBuilder<MessageModel, String?, QAfterProperty> fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(14);
    });
  }

  QueryBuilder<MessageModel, String?, QAfterProperty>
      forwardedFromMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(15);
    });
  }

  QueryBuilder<MessageModel, String?, QAfterProperty> mentionToJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(16);
    });
  }

  QueryBuilder<MessageModel, String?, QAfterProperty>
      replyToMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(17);
    });
  }

  QueryBuilder<MessageModel, String?, QAfterProperty> metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(18);
    });
  }

  QueryBuilder<MessageModel, bool, QAfterProperty> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(19);
    });
  }

  QueryBuilder<MessageModel, bool, QAfterProperty> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(20);
    });
  }

  QueryBuilder<MessageModel, int, QAfterProperty> retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(21);
    });
  }

  QueryBuilder<MessageModel, String?, QAfterProperty> errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(22);
    });
  }

  QueryBuilder<MessageModel, Map<String, dynamic>?, QAfterProperty>
      metadataMapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(23);
    });
  }

  QueryBuilder<MessageModel, bool, QAfterProperty> isMultimediaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(24);
    });
  }

  QueryBuilder<MessageModel, bool, QAfterProperty>
      isDisplayableMediaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(25);
    });
  }

  QueryBuilder<MessageModel, bool, QAfterProperty> isEditableProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(26);
    });
  }

  QueryBuilder<MessageModel, int?, QAfterProperty> mediaDurationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(27);
    });
  }

  QueryBuilder<MessageModel, int?, QAfterProperty> fileSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(28);
    });
  }

  QueryBuilder<MessageModel, String?, QAfterProperty> fileMimeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(29);
    });
  }

  QueryBuilder<MessageModel, String?, QAfterProperty> mediaPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(30);
    });
  }
}

extension MessageModelQueryProperty2<R>
    on QueryBuilder<MessageModel, R, QAfterProperty> {
  QueryBuilder<MessageModel, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<MessageModel, (R, String?), QAfterProperty> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<MessageModel, (R, String), QAfterProperty> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<MessageModel, (R, String), QAfterProperty> chatIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<MessageModel, (R, String), QAfterProperty> senderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<MessageModel, (R, List<String>), QAfterProperty>
      readByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<MessageModel, (R, String), QAfterProperty> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<MessageModel, (R, MessageType), QAfterProperty> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<MessageModel, (R, MessageStatus), QAfterProperty>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<MessageModel, (R, DateTime), QAfterProperty>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<MessageModel, (R, DateTime?), QAfterProperty>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<MessageModel, (R, DateTime?), QAfterProperty>
      editedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<MessageModel, (R, DateTime?), QAfterProperty>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<MessageModel, (R, List<String>), QAfterProperty> urlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }

  QueryBuilder<MessageModel, (R, String?), QAfterProperty> fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(14);
    });
  }

  QueryBuilder<MessageModel, (R, String?), QAfterProperty>
      forwardedFromMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(15);
    });
  }

  QueryBuilder<MessageModel, (R, String?), QAfterProperty>
      mentionToJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(16);
    });
  }

  QueryBuilder<MessageModel, (R, String?), QAfterProperty>
      replyToMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(17);
    });
  }

  QueryBuilder<MessageModel, (R, String?), QAfterProperty> metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(18);
    });
  }

  QueryBuilder<MessageModel, (R, bool), QAfterProperty> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(19);
    });
  }

  QueryBuilder<MessageModel, (R, bool), QAfterProperty> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(20);
    });
  }

  QueryBuilder<MessageModel, (R, int), QAfterProperty> retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(21);
    });
  }

  QueryBuilder<MessageModel, (R, String?), QAfterProperty>
      errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(22);
    });
  }

  QueryBuilder<MessageModel, (R, Map<String, dynamic>?), QAfterProperty>
      metadataMapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(23);
    });
  }

  QueryBuilder<MessageModel, (R, bool), QAfterProperty> isMultimediaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(24);
    });
  }

  QueryBuilder<MessageModel, (R, bool), QAfterProperty>
      isDisplayableMediaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(25);
    });
  }

  QueryBuilder<MessageModel, (R, bool), QAfterProperty> isEditableProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(26);
    });
  }

  QueryBuilder<MessageModel, (R, int?), QAfterProperty>
      mediaDurationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(27);
    });
  }

  QueryBuilder<MessageModel, (R, int?), QAfterProperty> fileSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(28);
    });
  }

  QueryBuilder<MessageModel, (R, String?), QAfterProperty>
      fileMimeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(29);
    });
  }

  QueryBuilder<MessageModel, (R, String?), QAfterProperty> mediaPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(30);
    });
  }
}

extension MessageModelQueryProperty3<R1, R2>
    on QueryBuilder<MessageModel, (R1, R2), QAfterProperty> {
  QueryBuilder<MessageModel, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String?), QOperations>
      serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String), QOperations> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String), QOperations> chatIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String), QOperations> senderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, List<String>), QOperations>
      readByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String), QOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, MessageType), QOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, MessageStatus), QOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, DateTime), QOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, DateTime?), QOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, DateTime?), QOperations>
      editedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, DateTime?), QOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, List<String>), QOperations>
      urlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String?), QOperations>
      fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(14);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String?), QOperations>
      forwardedFromMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(15);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String?), QOperations>
      mentionToJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(16);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String?), QOperations>
      replyToMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(17);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String?), QOperations>
      metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(18);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, bool), QOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(19);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, bool), QOperations> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(20);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, int), QOperations> retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(21);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String?), QOperations>
      errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(22);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, Map<String, dynamic>?), QOperations>
      metadataMapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(23);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, bool), QOperations>
      isMultimediaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(24);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, bool), QOperations>
      isDisplayableMediaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(25);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, bool), QOperations> isEditableProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(26);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, int?), QOperations>
      mediaDurationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(27);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, int?), QOperations> fileSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(28);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String?), QOperations>
      fileMimeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(29);
    });
  }

  QueryBuilder<MessageModel, (R1, R2, String?), QOperations>
      mediaPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(30);
    });
  }
}
