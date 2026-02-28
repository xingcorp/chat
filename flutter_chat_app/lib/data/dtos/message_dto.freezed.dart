// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MessageDto _$MessageDtoFromJson(Map<String, dynamic> json) {
  return _MessageDto.fromJson(json);
}

/// @nodoc
mixin _$MessageDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'message')
  String get content => throw _privateConstructorUsedError;
  List<String> get urls => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int? get editAt => throw _privateConstructorUsedError;
  int? get deletedAt => throw _privateConstructorUsedError;
  String? get replyMessageId => throw _privateConstructorUsedError;
  ReplyMessageDto? get replyMessage => throw _privateConstructorUsedError;
  String? get forwardedFromMessageId => throw _privateConstructorUsedError;
  MessageDto? get forwardedFromMessage => throw _privateConstructorUsedError;
  String? get fileName => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  SenderDto? get sender => throw _privateConstructorUsedError;
  @JsonKey(name: 'conversationId')
  String get chatId => throw _privateConstructorUsedError;
  List<String> get readerIds => throw _privateConstructorUsedError;
  List<ReactionDto> get reactions => throw _privateConstructorUsedError;
  List<MentionDto> get mentionTo =>
      throw _privateConstructorUsedError; // System event fields (khớp Angular: ConversationActionType)
  String? get actionType => throw _privateConstructorUsedError;
  String? get actorId => throw _privateConstructorUsedError;
  SenderDto? get actor => throw _privateConstructorUsedError;
  List<String> get targetUserIds => throw _privateConstructorUsedError;
  List<SenderDto> get targetUsers => throw _privateConstructorUsedError;
  String? get newValue => throw _privateConstructorUsedError;
  String? get oldValue => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MessageDtoCopyWith<MessageDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageDtoCopyWith<$Res> {
  factory $MessageDtoCopyWith(
          MessageDto value, $Res Function(MessageDto) then) =
      _$MessageDtoCopyWithImpl<$Res, MessageDto>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'message') String content,
      List<String> urls,
      String type,
      int createdAt,
      int? editAt,
      int? deletedAt,
      String? replyMessageId,
      ReplyMessageDto? replyMessage,
      String? forwardedFromMessageId,
      MessageDto? forwardedFromMessage,
      String? fileName,
      String senderId,
      SenderDto? sender,
      @JsonKey(name: 'conversationId') String chatId,
      List<String> readerIds,
      List<ReactionDto> reactions,
      List<MentionDto> mentionTo,
      String? actionType,
      String? actorId,
      SenderDto? actor,
      List<String> targetUserIds,
      List<SenderDto> targetUsers,
      String? newValue,
      String? oldValue});

  $ReplyMessageDtoCopyWith<$Res>? get replyMessage;
  $MessageDtoCopyWith<$Res>? get forwardedFromMessage;
  $SenderDtoCopyWith<$Res>? get sender;
  $SenderDtoCopyWith<$Res>? get actor;
}

/// @nodoc
class _$MessageDtoCopyWithImpl<$Res, $Val extends MessageDto>
    implements $MessageDtoCopyWith<$Res> {
  _$MessageDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? urls = null,
    Object? type = null,
    Object? createdAt = null,
    Object? editAt = freezed,
    Object? deletedAt = freezed,
    Object? replyMessageId = freezed,
    Object? replyMessage = freezed,
    Object? forwardedFromMessageId = freezed,
    Object? forwardedFromMessage = freezed,
    Object? fileName = freezed,
    Object? senderId = null,
    Object? sender = freezed,
    Object? chatId = null,
    Object? readerIds = null,
    Object? reactions = null,
    Object? mentionTo = null,
    Object? actionType = freezed,
    Object? actorId = freezed,
    Object? actor = freezed,
    Object? targetUserIds = null,
    Object? targetUsers = null,
    Object? newValue = freezed,
    Object? oldValue = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      urls: null == urls
          ? _value.urls
          : urls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      editAt: freezed == editAt
          ? _value.editAt
          : editAt // ignore: cast_nullable_to_non_nullable
              as int?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as int?,
      replyMessageId: freezed == replyMessageId
          ? _value.replyMessageId
          : replyMessageId // ignore: cast_nullable_to_non_nullable
              as String?,
      replyMessage: freezed == replyMessage
          ? _value.replyMessage
          : replyMessage // ignore: cast_nullable_to_non_nullable
              as ReplyMessageDto?,
      forwardedFromMessageId: freezed == forwardedFromMessageId
          ? _value.forwardedFromMessageId
          : forwardedFromMessageId // ignore: cast_nullable_to_non_nullable
              as String?,
      forwardedFromMessage: freezed == forwardedFromMessage
          ? _value.forwardedFromMessage
          : forwardedFromMessage // ignore: cast_nullable_to_non_nullable
              as MessageDto?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      sender: freezed == sender
          ? _value.sender
          : sender // ignore: cast_nullable_to_non_nullable
              as SenderDto?,
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      readerIds: null == readerIds
          ? _value.readerIds
          : readerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      reactions: null == reactions
          ? _value.reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as List<ReactionDto>,
      mentionTo: null == mentionTo
          ? _value.mentionTo
          : mentionTo // ignore: cast_nullable_to_non_nullable
              as List<MentionDto>,
      actionType: freezed == actionType
          ? _value.actionType
          : actionType // ignore: cast_nullable_to_non_nullable
              as String?,
      actorId: freezed == actorId
          ? _value.actorId
          : actorId // ignore: cast_nullable_to_non_nullable
              as String?,
      actor: freezed == actor
          ? _value.actor
          : actor // ignore: cast_nullable_to_non_nullable
              as SenderDto?,
      targetUserIds: null == targetUserIds
          ? _value.targetUserIds
          : targetUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      targetUsers: null == targetUsers
          ? _value.targetUsers
          : targetUsers // ignore: cast_nullable_to_non_nullable
              as List<SenderDto>,
      newValue: freezed == newValue
          ? _value.newValue
          : newValue // ignore: cast_nullable_to_non_nullable
              as String?,
      oldValue: freezed == oldValue
          ? _value.oldValue
          : oldValue // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ReplyMessageDtoCopyWith<$Res>? get replyMessage {
    if (_value.replyMessage == null) {
      return null;
    }

    return $ReplyMessageDtoCopyWith<$Res>(_value.replyMessage!, (value) {
      return _then(_value.copyWith(replyMessage: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $MessageDtoCopyWith<$Res>? get forwardedFromMessage {
    if (_value.forwardedFromMessage == null) {
      return null;
    }

    return $MessageDtoCopyWith<$Res>(_value.forwardedFromMessage!, (value) {
      return _then(_value.copyWith(forwardedFromMessage: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $SenderDtoCopyWith<$Res>? get sender {
    if (_value.sender == null) {
      return null;
    }

    return $SenderDtoCopyWith<$Res>(_value.sender!, (value) {
      return _then(_value.copyWith(sender: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $SenderDtoCopyWith<$Res>? get actor {
    if (_value.actor == null) {
      return null;
    }

    return $SenderDtoCopyWith<$Res>(_value.actor!, (value) {
      return _then(_value.copyWith(actor: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MessageDtoImplCopyWith<$Res>
    implements $MessageDtoCopyWith<$Res> {
  factory _$$MessageDtoImplCopyWith(
          _$MessageDtoImpl value, $Res Function(_$MessageDtoImpl) then) =
      __$$MessageDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'message') String content,
      List<String> urls,
      String type,
      int createdAt,
      int? editAt,
      int? deletedAt,
      String? replyMessageId,
      ReplyMessageDto? replyMessage,
      String? forwardedFromMessageId,
      MessageDto? forwardedFromMessage,
      String? fileName,
      String senderId,
      SenderDto? sender,
      @JsonKey(name: 'conversationId') String chatId,
      List<String> readerIds,
      List<ReactionDto> reactions,
      List<MentionDto> mentionTo,
      String? actionType,
      String? actorId,
      SenderDto? actor,
      List<String> targetUserIds,
      List<SenderDto> targetUsers,
      String? newValue,
      String? oldValue});

  @override
  $ReplyMessageDtoCopyWith<$Res>? get replyMessage;
  @override
  $MessageDtoCopyWith<$Res>? get forwardedFromMessage;
  @override
  $SenderDtoCopyWith<$Res>? get sender;
  @override
  $SenderDtoCopyWith<$Res>? get actor;
}

/// @nodoc
class __$$MessageDtoImplCopyWithImpl<$Res>
    extends _$MessageDtoCopyWithImpl<$Res, _$MessageDtoImpl>
    implements _$$MessageDtoImplCopyWith<$Res> {
  __$$MessageDtoImplCopyWithImpl(
      _$MessageDtoImpl _value, $Res Function(_$MessageDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? urls = null,
    Object? type = null,
    Object? createdAt = null,
    Object? editAt = freezed,
    Object? deletedAt = freezed,
    Object? replyMessageId = freezed,
    Object? replyMessage = freezed,
    Object? forwardedFromMessageId = freezed,
    Object? forwardedFromMessage = freezed,
    Object? fileName = freezed,
    Object? senderId = null,
    Object? sender = freezed,
    Object? chatId = null,
    Object? readerIds = null,
    Object? reactions = null,
    Object? mentionTo = null,
    Object? actionType = freezed,
    Object? actorId = freezed,
    Object? actor = freezed,
    Object? targetUserIds = null,
    Object? targetUsers = null,
    Object? newValue = freezed,
    Object? oldValue = freezed,
  }) {
    return _then(_$MessageDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      urls: null == urls
          ? _value._urls
          : urls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      editAt: freezed == editAt
          ? _value.editAt
          : editAt // ignore: cast_nullable_to_non_nullable
              as int?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as int?,
      replyMessageId: freezed == replyMessageId
          ? _value.replyMessageId
          : replyMessageId // ignore: cast_nullable_to_non_nullable
              as String?,
      replyMessage: freezed == replyMessage
          ? _value.replyMessage
          : replyMessage // ignore: cast_nullable_to_non_nullable
              as ReplyMessageDto?,
      forwardedFromMessageId: freezed == forwardedFromMessageId
          ? _value.forwardedFromMessageId
          : forwardedFromMessageId // ignore: cast_nullable_to_non_nullable
              as String?,
      forwardedFromMessage: freezed == forwardedFromMessage
          ? _value.forwardedFromMessage
          : forwardedFromMessage // ignore: cast_nullable_to_non_nullable
              as MessageDto?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      sender: freezed == sender
          ? _value.sender
          : sender // ignore: cast_nullable_to_non_nullable
              as SenderDto?,
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      readerIds: null == readerIds
          ? _value._readerIds
          : readerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      reactions: null == reactions
          ? _value._reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as List<ReactionDto>,
      mentionTo: null == mentionTo
          ? _value._mentionTo
          : mentionTo // ignore: cast_nullable_to_non_nullable
              as List<MentionDto>,
      actionType: freezed == actionType
          ? _value.actionType
          : actionType // ignore: cast_nullable_to_non_nullable
              as String?,
      actorId: freezed == actorId
          ? _value.actorId
          : actorId // ignore: cast_nullable_to_non_nullable
              as String?,
      actor: freezed == actor
          ? _value.actor
          : actor // ignore: cast_nullable_to_non_nullable
              as SenderDto?,
      targetUserIds: null == targetUserIds
          ? _value._targetUserIds
          : targetUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      targetUsers: null == targetUsers
          ? _value._targetUsers
          : targetUsers // ignore: cast_nullable_to_non_nullable
              as List<SenderDto>,
      newValue: freezed == newValue
          ? _value.newValue
          : newValue // ignore: cast_nullable_to_non_nullable
              as String?,
      oldValue: freezed == oldValue
          ? _value.oldValue
          : oldValue // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageDtoImpl implements _MessageDto {
  const _$MessageDtoImpl(
      {required this.id,
      @JsonKey(name: 'message') required this.content,
      final List<String> urls = const [],
      required this.type,
      required this.createdAt,
      this.editAt,
      this.deletedAt,
      this.replyMessageId,
      this.replyMessage,
      this.forwardedFromMessageId,
      this.forwardedFromMessage,
      this.fileName,
      required this.senderId,
      this.sender,
      @JsonKey(name: 'conversationId') required this.chatId,
      final List<String> readerIds = const [],
      final List<ReactionDto> reactions = const [],
      final List<MentionDto> mentionTo = const [],
      this.actionType,
      this.actorId,
      this.actor,
      final List<String> targetUserIds = const [],
      final List<SenderDto> targetUsers = const [],
      this.newValue,
      this.oldValue})
      : _urls = urls,
        _readerIds = readerIds,
        _reactions = reactions,
        _mentionTo = mentionTo,
        _targetUserIds = targetUserIds,
        _targetUsers = targetUsers;

  factory _$MessageDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'message')
  final String content;
  final List<String> _urls;
  @override
  @JsonKey()
  List<String> get urls {
    if (_urls is EqualUnmodifiableListView) return _urls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_urls);
  }

  @override
  final String type;
  @override
  final int createdAt;
  @override
  final int? editAt;
  @override
  final int? deletedAt;
  @override
  final String? replyMessageId;
  @override
  final ReplyMessageDto? replyMessage;
  @override
  final String? forwardedFromMessageId;
  @override
  final MessageDto? forwardedFromMessage;
  @override
  final String? fileName;
  @override
  final String senderId;
  @override
  final SenderDto? sender;
  @override
  @JsonKey(name: 'conversationId')
  final String chatId;
  final List<String> _readerIds;
  @override
  @JsonKey()
  List<String> get readerIds {
    if (_readerIds is EqualUnmodifiableListView) return _readerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_readerIds);
  }

  final List<ReactionDto> _reactions;
  @override
  @JsonKey()
  List<ReactionDto> get reactions {
    if (_reactions is EqualUnmodifiableListView) return _reactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reactions);
  }

  final List<MentionDto> _mentionTo;
  @override
  @JsonKey()
  List<MentionDto> get mentionTo {
    if (_mentionTo is EqualUnmodifiableListView) return _mentionTo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mentionTo);
  }

// System event fields (khớp Angular: ConversationActionType)
  @override
  final String? actionType;
  @override
  final String? actorId;
  @override
  final SenderDto? actor;
  final List<String> _targetUserIds;
  @override
  @JsonKey()
  List<String> get targetUserIds {
    if (_targetUserIds is EqualUnmodifiableListView) return _targetUserIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_targetUserIds);
  }

  final List<SenderDto> _targetUsers;
  @override
  @JsonKey()
  List<SenderDto> get targetUsers {
    if (_targetUsers is EqualUnmodifiableListView) return _targetUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_targetUsers);
  }

  @override
  final String? newValue;
  @override
  final String? oldValue;

  @override
  String toString() {
    return 'MessageDto(id: $id, content: $content, urls: $urls, type: $type, createdAt: $createdAt, editAt: $editAt, deletedAt: $deletedAt, replyMessageId: $replyMessageId, replyMessage: $replyMessage, forwardedFromMessageId: $forwardedFromMessageId, forwardedFromMessage: $forwardedFromMessage, fileName: $fileName, senderId: $senderId, sender: $sender, chatId: $chatId, readerIds: $readerIds, reactions: $reactions, mentionTo: $mentionTo, actionType: $actionType, actorId: $actorId, actor: $actor, targetUserIds: $targetUserIds, targetUsers: $targetUsers, newValue: $newValue, oldValue: $oldValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(other._urls, _urls) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.editAt, editAt) || other.editAt == editAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.replyMessageId, replyMessageId) ||
                other.replyMessageId == replyMessageId) &&
            (identical(other.replyMessage, replyMessage) ||
                other.replyMessage == replyMessage) &&
            (identical(other.forwardedFromMessageId, forwardedFromMessageId) ||
                other.forwardedFromMessageId == forwardedFromMessageId) &&
            (identical(other.forwardedFromMessage, forwardedFromMessage) ||
                other.forwardedFromMessage == forwardedFromMessage) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.sender, sender) || other.sender == sender) &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            const DeepCollectionEquality()
                .equals(other._readerIds, _readerIds) &&
            const DeepCollectionEquality()
                .equals(other._reactions, _reactions) &&
            const DeepCollectionEquality()
                .equals(other._mentionTo, _mentionTo) &&
            (identical(other.actionType, actionType) ||
                other.actionType == actionType) &&
            (identical(other.actorId, actorId) || other.actorId == actorId) &&
            (identical(other.actor, actor) || other.actor == actor) &&
            const DeepCollectionEquality()
                .equals(other._targetUserIds, _targetUserIds) &&
            const DeepCollectionEquality()
                .equals(other._targetUsers, _targetUsers) &&
            (identical(other.newValue, newValue) ||
                other.newValue == newValue) &&
            (identical(other.oldValue, oldValue) ||
                other.oldValue == oldValue));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        content,
        const DeepCollectionEquality().hash(_urls),
        type,
        createdAt,
        editAt,
        deletedAt,
        replyMessageId,
        replyMessage,
        forwardedFromMessageId,
        forwardedFromMessage,
        fileName,
        senderId,
        sender,
        chatId,
        const DeepCollectionEquality().hash(_readerIds),
        const DeepCollectionEquality().hash(_reactions),
        const DeepCollectionEquality().hash(_mentionTo),
        actionType,
        actorId,
        actor,
        const DeepCollectionEquality().hash(_targetUserIds),
        const DeepCollectionEquality().hash(_targetUsers),
        newValue,
        oldValue
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageDtoImplCopyWith<_$MessageDtoImpl> get copyWith =>
      __$$MessageDtoImplCopyWithImpl<_$MessageDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageDtoImplToJson(
      this,
    );
  }
}

abstract class _MessageDto implements MessageDto {
  const factory _MessageDto(
      {required final String id,
      @JsonKey(name: 'message') required final String content,
      final List<String> urls,
      required final String type,
      required final int createdAt,
      final int? editAt,
      final int? deletedAt,
      final String? replyMessageId,
      final ReplyMessageDto? replyMessage,
      final String? forwardedFromMessageId,
      final MessageDto? forwardedFromMessage,
      final String? fileName,
      required final String senderId,
      final SenderDto? sender,
      @JsonKey(name: 'conversationId') required final String chatId,
      final List<String> readerIds,
      final List<ReactionDto> reactions,
      final List<MentionDto> mentionTo,
      final String? actionType,
      final String? actorId,
      final SenderDto? actor,
      final List<String> targetUserIds,
      final List<SenderDto> targetUsers,
      final String? newValue,
      final String? oldValue}) = _$MessageDtoImpl;

  factory _MessageDto.fromJson(Map<String, dynamic> json) =
      _$MessageDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'message')
  String get content;
  @override
  List<String> get urls;
  @override
  String get type;
  @override
  int get createdAt;
  @override
  int? get editAt;
  @override
  int? get deletedAt;
  @override
  String? get replyMessageId;
  @override
  ReplyMessageDto? get replyMessage;
  @override
  String? get forwardedFromMessageId;
  @override
  MessageDto? get forwardedFromMessage;
  @override
  String? get fileName;
  @override
  String get senderId;
  @override
  SenderDto? get sender;
  @override
  @JsonKey(name: 'conversationId')
  String get chatId;
  @override
  List<String> get readerIds;
  @override
  List<ReactionDto> get reactions;
  @override
  List<MentionDto> get mentionTo;
  @override // System event fields (khớp Angular: ConversationActionType)
  String? get actionType;
  @override
  String? get actorId;
  @override
  SenderDto? get actor;
  @override
  List<String> get targetUserIds;
  @override
  List<SenderDto> get targetUsers;
  @override
  String? get newValue;
  @override
  String? get oldValue;
  @override
  @JsonKey(ignore: true)
  _$$MessageDtoImplCopyWith<_$MessageDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SenderDto _$SenderDtoFromJson(Map<String, dynamic> json) {
  return _SenderDto.fromJson(json);
}

/// @nodoc
mixin _$SenderDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'fullname')
  String get fullName => throw _privateConstructorUsedError;
  List<String> get imageUrls => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SenderDtoCopyWith<SenderDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SenderDtoCopyWith<$Res> {
  factory $SenderDtoCopyWith(SenderDto value, $Res Function(SenderDto) then) =
      _$SenderDtoCopyWithImpl<$Res, SenderDto>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'fullname') String fullName,
      List<String> imageUrls});
}

/// @nodoc
class _$SenderDtoCopyWithImpl<$Res, $Val extends SenderDto>
    implements $SenderDtoCopyWith<$Res> {
  _$SenderDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? imageUrls = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrls: null == imageUrls
          ? _value.imageUrls
          : imageUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SenderDtoImplCopyWith<$Res>
    implements $SenderDtoCopyWith<$Res> {
  factory _$$SenderDtoImplCopyWith(
          _$SenderDtoImpl value, $Res Function(_$SenderDtoImpl) then) =
      __$$SenderDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'fullname') String fullName,
      List<String> imageUrls});
}

/// @nodoc
class __$$SenderDtoImplCopyWithImpl<$Res>
    extends _$SenderDtoCopyWithImpl<$Res, _$SenderDtoImpl>
    implements _$$SenderDtoImplCopyWith<$Res> {
  __$$SenderDtoImplCopyWithImpl(
      _$SenderDtoImpl _value, $Res Function(_$SenderDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? imageUrls = null,
  }) {
    return _then(_$SenderDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrls: null == imageUrls
          ? _value._imageUrls
          : imageUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SenderDtoImpl implements _SenderDto {
  const _$SenderDtoImpl(
      {required this.id,
      @JsonKey(name: 'fullname') required this.fullName,
      final List<String> imageUrls = const []})
      : _imageUrls = imageUrls;

  factory _$SenderDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SenderDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'fullname')
  final String fullName;
  final List<String> _imageUrls;
  @override
  @JsonKey()
  List<String> get imageUrls {
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imageUrls);
  }

  @override
  String toString() {
    return 'SenderDto(id: $id, fullName: $fullName, imageUrls: $imageUrls)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SenderDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            const DeepCollectionEquality()
                .equals(other._imageUrls, _imageUrls));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, fullName,
      const DeepCollectionEquality().hash(_imageUrls));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SenderDtoImplCopyWith<_$SenderDtoImpl> get copyWith =>
      __$$SenderDtoImplCopyWithImpl<_$SenderDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SenderDtoImplToJson(
      this,
    );
  }
}

abstract class _SenderDto implements SenderDto {
  const factory _SenderDto(
      {required final String id,
      @JsonKey(name: 'fullname') required final String fullName,
      final List<String> imageUrls}) = _$SenderDtoImpl;

  factory _SenderDto.fromJson(Map<String, dynamic> json) =
      _$SenderDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'fullname')
  String get fullName;
  @override
  List<String> get imageUrls;
  @override
  @JsonKey(ignore: true)
  _$$SenderDtoImplCopyWith<_$SenderDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReplyMessageDto _$ReplyMessageDtoFromJson(Map<String, dynamic> json) {
  return _ReplyMessageDto.fromJson(json);
}

/// @nodoc
mixin _$ReplyMessageDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'message')
  String get content => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  List<String> get urls => throw _privateConstructorUsedError;
  String? get fileName => throw _privateConstructorUsedError;
  List<MentionDto> get mentionTo => throw _privateConstructorUsedError;
  SenderDto? get sender => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReplyMessageDtoCopyWith<ReplyMessageDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReplyMessageDtoCopyWith<$Res> {
  factory $ReplyMessageDtoCopyWith(
          ReplyMessageDto value, $Res Function(ReplyMessageDto) then) =
      _$ReplyMessageDtoCopyWithImpl<$Res, ReplyMessageDto>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'message') String content,
      String? type,
      List<String> urls,
      String? fileName,
      List<MentionDto> mentionTo,
      SenderDto? sender});

  $SenderDtoCopyWith<$Res>? get sender;
}

/// @nodoc
class _$ReplyMessageDtoCopyWithImpl<$Res, $Val extends ReplyMessageDto>
    implements $ReplyMessageDtoCopyWith<$Res> {
  _$ReplyMessageDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? type = freezed,
    Object? urls = null,
    Object? fileName = freezed,
    Object? mentionTo = null,
    Object? sender = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      urls: null == urls
          ? _value.urls
          : urls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      mentionTo: null == mentionTo
          ? _value.mentionTo
          : mentionTo // ignore: cast_nullable_to_non_nullable
              as List<MentionDto>,
      sender: freezed == sender
          ? _value.sender
          : sender // ignore: cast_nullable_to_non_nullable
              as SenderDto?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SenderDtoCopyWith<$Res>? get sender {
    if (_value.sender == null) {
      return null;
    }

    return $SenderDtoCopyWith<$Res>(_value.sender!, (value) {
      return _then(_value.copyWith(sender: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ReplyMessageDtoImplCopyWith<$Res>
    implements $ReplyMessageDtoCopyWith<$Res> {
  factory _$$ReplyMessageDtoImplCopyWith(_$ReplyMessageDtoImpl value,
          $Res Function(_$ReplyMessageDtoImpl) then) =
      __$$ReplyMessageDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'message') String content,
      String? type,
      List<String> urls,
      String? fileName,
      List<MentionDto> mentionTo,
      SenderDto? sender});

  @override
  $SenderDtoCopyWith<$Res>? get sender;
}

/// @nodoc
class __$$ReplyMessageDtoImplCopyWithImpl<$Res>
    extends _$ReplyMessageDtoCopyWithImpl<$Res, _$ReplyMessageDtoImpl>
    implements _$$ReplyMessageDtoImplCopyWith<$Res> {
  __$$ReplyMessageDtoImplCopyWithImpl(
      _$ReplyMessageDtoImpl _value, $Res Function(_$ReplyMessageDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? type = freezed,
    Object? urls = null,
    Object? fileName = freezed,
    Object? mentionTo = null,
    Object? sender = freezed,
  }) {
    return _then(_$ReplyMessageDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      urls: null == urls
          ? _value._urls
          : urls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      mentionTo: null == mentionTo
          ? _value._mentionTo
          : mentionTo // ignore: cast_nullable_to_non_nullable
              as List<MentionDto>,
      sender: freezed == sender
          ? _value.sender
          : sender // ignore: cast_nullable_to_non_nullable
              as SenderDto?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReplyMessageDtoImpl implements _ReplyMessageDto {
  const _$ReplyMessageDtoImpl(
      {required this.id,
      @JsonKey(name: 'message') required this.content,
      this.type,
      final List<String> urls = const [],
      this.fileName,
      final List<MentionDto> mentionTo = const [],
      this.sender})
      : _urls = urls,
        _mentionTo = mentionTo;

  factory _$ReplyMessageDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReplyMessageDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'message')
  final String content;
  @override
  final String? type;
  final List<String> _urls;
  @override
  @JsonKey()
  List<String> get urls {
    if (_urls is EqualUnmodifiableListView) return _urls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_urls);
  }

  @override
  final String? fileName;
  final List<MentionDto> _mentionTo;
  @override
  @JsonKey()
  List<MentionDto> get mentionTo {
    if (_mentionTo is EqualUnmodifiableListView) return _mentionTo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mentionTo);
  }

  @override
  final SenderDto? sender;

  @override
  String toString() {
    return 'ReplyMessageDto(id: $id, content: $content, type: $type, urls: $urls, fileName: $fileName, mentionTo: $mentionTo, sender: $sender)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplyMessageDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._urls, _urls) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            const DeepCollectionEquality()
                .equals(other._mentionTo, _mentionTo) &&
            (identical(other.sender, sender) || other.sender == sender));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      content,
      type,
      const DeepCollectionEquality().hash(_urls),
      fileName,
      const DeepCollectionEquality().hash(_mentionTo),
      sender);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplyMessageDtoImplCopyWith<_$ReplyMessageDtoImpl> get copyWith =>
      __$$ReplyMessageDtoImplCopyWithImpl<_$ReplyMessageDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReplyMessageDtoImplToJson(
      this,
    );
  }
}

abstract class _ReplyMessageDto implements ReplyMessageDto {
  const factory _ReplyMessageDto(
      {required final String id,
      @JsonKey(name: 'message') required final String content,
      final String? type,
      final List<String> urls,
      final String? fileName,
      final List<MentionDto> mentionTo,
      final SenderDto? sender}) = _$ReplyMessageDtoImpl;

  factory _ReplyMessageDto.fromJson(Map<String, dynamic> json) =
      _$ReplyMessageDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'message')
  String get content;
  @override
  String? get type;
  @override
  List<String> get urls;
  @override
  String? get fileName;
  @override
  List<MentionDto> get mentionTo;
  @override
  SenderDto? get sender;
  @override
  @JsonKey(ignore: true)
  _$$ReplyMessageDtoImplCopyWith<_$ReplyMessageDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReactionDto _$ReactionDtoFromJson(Map<String, dynamic> json) {
  return _ReactionDto.fromJson(json);
}

/// @nodoc
mixin _$ReactionDto {
  String get code => throw _privateConstructorUsedError;
  List<String> get reactorIds => throw _privateConstructorUsedError;
  List<UserReactionDto> get reactors => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReactionDtoCopyWith<ReactionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReactionDtoCopyWith<$Res> {
  factory $ReactionDtoCopyWith(
          ReactionDto value, $Res Function(ReactionDto) then) =
      _$ReactionDtoCopyWithImpl<$Res, ReactionDto>;
  @useResult
  $Res call(
      {String code, List<String> reactorIds, List<UserReactionDto> reactors});
}

/// @nodoc
class _$ReactionDtoCopyWithImpl<$Res, $Val extends ReactionDto>
    implements $ReactionDtoCopyWith<$Res> {
  _$ReactionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? reactorIds = null,
    Object? reactors = null,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      reactorIds: null == reactorIds
          ? _value.reactorIds
          : reactorIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      reactors: null == reactors
          ? _value.reactors
          : reactors // ignore: cast_nullable_to_non_nullable
              as List<UserReactionDto>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReactionDtoImplCopyWith<$Res>
    implements $ReactionDtoCopyWith<$Res> {
  factory _$$ReactionDtoImplCopyWith(
          _$ReactionDtoImpl value, $Res Function(_$ReactionDtoImpl) then) =
      __$$ReactionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String code, List<String> reactorIds, List<UserReactionDto> reactors});
}

/// @nodoc
class __$$ReactionDtoImplCopyWithImpl<$Res>
    extends _$ReactionDtoCopyWithImpl<$Res, _$ReactionDtoImpl>
    implements _$$ReactionDtoImplCopyWith<$Res> {
  __$$ReactionDtoImplCopyWithImpl(
      _$ReactionDtoImpl _value, $Res Function(_$ReactionDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? reactorIds = null,
    Object? reactors = null,
  }) {
    return _then(_$ReactionDtoImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      reactorIds: null == reactorIds
          ? _value._reactorIds
          : reactorIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      reactors: null == reactors
          ? _value._reactors
          : reactors // ignore: cast_nullable_to_non_nullable
              as List<UserReactionDto>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReactionDtoImpl implements _ReactionDto {
  const _$ReactionDtoImpl(
      {required this.code,
      final List<String> reactorIds = const [],
      final List<UserReactionDto> reactors = const []})
      : _reactorIds = reactorIds,
        _reactors = reactors;

  factory _$ReactionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReactionDtoImplFromJson(json);

  @override
  final String code;
  final List<String> _reactorIds;
  @override
  @JsonKey()
  List<String> get reactorIds {
    if (_reactorIds is EqualUnmodifiableListView) return _reactorIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reactorIds);
  }

  final List<UserReactionDto> _reactors;
  @override
  @JsonKey()
  List<UserReactionDto> get reactors {
    if (_reactors is EqualUnmodifiableListView) return _reactors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reactors);
  }

  @override
  String toString() {
    return 'ReactionDto(code: $code, reactorIds: $reactorIds, reactors: $reactors)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReactionDtoImpl &&
            (identical(other.code, code) || other.code == code) &&
            const DeepCollectionEquality()
                .equals(other._reactorIds, _reactorIds) &&
            const DeepCollectionEquality().equals(other._reactors, _reactors));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      code,
      const DeepCollectionEquality().hash(_reactorIds),
      const DeepCollectionEquality().hash(_reactors));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReactionDtoImplCopyWith<_$ReactionDtoImpl> get copyWith =>
      __$$ReactionDtoImplCopyWithImpl<_$ReactionDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReactionDtoImplToJson(
      this,
    );
  }
}

abstract class _ReactionDto implements ReactionDto {
  const factory _ReactionDto(
      {required final String code,
      final List<String> reactorIds,
      final List<UserReactionDto> reactors}) = _$ReactionDtoImpl;

  factory _ReactionDto.fromJson(Map<String, dynamic> json) =
      _$ReactionDtoImpl.fromJson;

  @override
  String get code;
  @override
  List<String> get reactorIds;
  @override
  List<UserReactionDto> get reactors;
  @override
  @JsonKey(ignore: true)
  _$$ReactionDtoImplCopyWith<_$ReactionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserReactionDto _$UserReactionDtoFromJson(Map<String, dynamic> json) {
  return _UserReactionDto.fromJson(json);
}

/// @nodoc
mixin _$UserReactionDto {
  @JsonKey(name: 'fullname')
  String get fullName => throw _privateConstructorUsedError;
  List<String> get imageUrls => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserReactionDtoCopyWith<UserReactionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserReactionDtoCopyWith<$Res> {
  factory $UserReactionDtoCopyWith(
          UserReactionDto value, $Res Function(UserReactionDto) then) =
      _$UserReactionDtoCopyWithImpl<$Res, UserReactionDto>;
  @useResult
  $Res call(
      {@JsonKey(name: 'fullname') String fullName, List<String> imageUrls});
}

/// @nodoc
class _$UserReactionDtoCopyWithImpl<$Res, $Val extends UserReactionDto>
    implements $UserReactionDtoCopyWith<$Res> {
  _$UserReactionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fullName = null,
    Object? imageUrls = null,
  }) {
    return _then(_value.copyWith(
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrls: null == imageUrls
          ? _value.imageUrls
          : imageUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserReactionDtoImplCopyWith<$Res>
    implements $UserReactionDtoCopyWith<$Res> {
  factory _$$UserReactionDtoImplCopyWith(_$UserReactionDtoImpl value,
          $Res Function(_$UserReactionDtoImpl) then) =
      __$$UserReactionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'fullname') String fullName, List<String> imageUrls});
}

/// @nodoc
class __$$UserReactionDtoImplCopyWithImpl<$Res>
    extends _$UserReactionDtoCopyWithImpl<$Res, _$UserReactionDtoImpl>
    implements _$$UserReactionDtoImplCopyWith<$Res> {
  __$$UserReactionDtoImplCopyWithImpl(
      _$UserReactionDtoImpl _value, $Res Function(_$UserReactionDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fullName = null,
    Object? imageUrls = null,
  }) {
    return _then(_$UserReactionDtoImpl(
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrls: null == imageUrls
          ? _value._imageUrls
          : imageUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserReactionDtoImpl implements _UserReactionDto {
  const _$UserReactionDtoImpl(
      {@JsonKey(name: 'fullname') required this.fullName,
      final List<String> imageUrls = const []})
      : _imageUrls = imageUrls;

  factory _$UserReactionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserReactionDtoImplFromJson(json);

  @override
  @JsonKey(name: 'fullname')
  final String fullName;
  final List<String> _imageUrls;
  @override
  @JsonKey()
  List<String> get imageUrls {
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imageUrls);
  }

  @override
  String toString() {
    return 'UserReactionDto(fullName: $fullName, imageUrls: $imageUrls)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserReactionDtoImpl &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            const DeepCollectionEquality()
                .equals(other._imageUrls, _imageUrls));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, fullName, const DeepCollectionEquality().hash(_imageUrls));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserReactionDtoImplCopyWith<_$UserReactionDtoImpl> get copyWith =>
      __$$UserReactionDtoImplCopyWithImpl<_$UserReactionDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserReactionDtoImplToJson(
      this,
    );
  }
}

abstract class _UserReactionDto implements UserReactionDto {
  const factory _UserReactionDto(
      {@JsonKey(name: 'fullname') required final String fullName,
      final List<String> imageUrls}) = _$UserReactionDtoImpl;

  factory _UserReactionDto.fromJson(Map<String, dynamic> json) =
      _$UserReactionDtoImpl.fromJson;

  @override
  @JsonKey(name: 'fullname')
  String get fullName;
  @override
  List<String> get imageUrls;
  @override
  @JsonKey(ignore: true)
  _$$UserReactionDtoImplCopyWith<_$UserReactionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MentionDto _$MentionDtoFromJson(Map<String, dynamic> json) {
  return _MentionDto.fromJson(json);
}

/// @nodoc
mixin _$MentionDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'fullname')
  String get fullName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MentionDtoCopyWith<MentionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MentionDtoCopyWith<$Res> {
  factory $MentionDtoCopyWith(
          MentionDto value, $Res Function(MentionDto) then) =
      _$MentionDtoCopyWithImpl<$Res, MentionDto>;
  @useResult
  $Res call({String id, @JsonKey(name: 'fullname') String fullName});
}

/// @nodoc
class _$MentionDtoCopyWithImpl<$Res, $Val extends MentionDto>
    implements $MentionDtoCopyWith<$Res> {
  _$MentionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MentionDtoImplCopyWith<$Res>
    implements $MentionDtoCopyWith<$Res> {
  factory _$$MentionDtoImplCopyWith(
          _$MentionDtoImpl value, $Res Function(_$MentionDtoImpl) then) =
      __$$MentionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, @JsonKey(name: 'fullname') String fullName});
}

/// @nodoc
class __$$MentionDtoImplCopyWithImpl<$Res>
    extends _$MentionDtoCopyWithImpl<$Res, _$MentionDtoImpl>
    implements _$$MentionDtoImplCopyWith<$Res> {
  __$$MentionDtoImplCopyWithImpl(
      _$MentionDtoImpl _value, $Res Function(_$MentionDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
  }) {
    return _then(_$MentionDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MentionDtoImpl implements _MentionDto {
  const _$MentionDtoImpl(
      {required this.id, @JsonKey(name: 'fullname') required this.fullName});

  factory _$MentionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MentionDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'fullname')
  final String fullName;

  @override
  String toString() {
    return 'MentionDto(id: $id, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MentionDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, fullName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MentionDtoImplCopyWith<_$MentionDtoImpl> get copyWith =>
      __$$MentionDtoImplCopyWithImpl<_$MentionDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MentionDtoImplToJson(
      this,
    );
  }
}

abstract class _MentionDto implements MentionDto {
  const factory _MentionDto(
          {required final String id,
          @JsonKey(name: 'fullname') required final String fullName}) =
      _$MentionDtoImpl;

  factory _MentionDto.fromJson(Map<String, dynamic> json) =
      _$MentionDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'fullname')
  String get fullName;
  @override
  @JsonKey(ignore: true)
  _$$MentionDtoImplCopyWith<_$MentionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MessageListResponseDto _$MessageListResponseDtoFromJson(
    Map<String, dynamic> json) {
  return _MessageListResponseDto.fromJson(json);
}

/// @nodoc
mixin _$MessageListResponseDto {
  LastKeyDto? get lastKey => throw _privateConstructorUsedError;
  List<MessageDto> get messages => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MessageListResponseDtoCopyWith<MessageListResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageListResponseDtoCopyWith<$Res> {
  factory $MessageListResponseDtoCopyWith(MessageListResponseDto value,
          $Res Function(MessageListResponseDto) then) =
      _$MessageListResponseDtoCopyWithImpl<$Res, MessageListResponseDto>;
  @useResult
  $Res call({LastKeyDto? lastKey, List<MessageDto> messages});

  $LastKeyDtoCopyWith<$Res>? get lastKey;
}

/// @nodoc
class _$MessageListResponseDtoCopyWithImpl<$Res,
        $Val extends MessageListResponseDto>
    implements $MessageListResponseDtoCopyWith<$Res> {
  _$MessageListResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lastKey = freezed,
    Object? messages = null,
  }) {
    return _then(_value.copyWith(
      lastKey: freezed == lastKey
          ? _value.lastKey
          : lastKey // ignore: cast_nullable_to_non_nullable
              as LastKeyDto?,
      messages: null == messages
          ? _value.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<MessageDto>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $LastKeyDtoCopyWith<$Res>? get lastKey {
    if (_value.lastKey == null) {
      return null;
    }

    return $LastKeyDtoCopyWith<$Res>(_value.lastKey!, (value) {
      return _then(_value.copyWith(lastKey: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MessageListResponseDtoImplCopyWith<$Res>
    implements $MessageListResponseDtoCopyWith<$Res> {
  factory _$$MessageListResponseDtoImplCopyWith(
          _$MessageListResponseDtoImpl value,
          $Res Function(_$MessageListResponseDtoImpl) then) =
      __$$MessageListResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({LastKeyDto? lastKey, List<MessageDto> messages});

  @override
  $LastKeyDtoCopyWith<$Res>? get lastKey;
}

/// @nodoc
class __$$MessageListResponseDtoImplCopyWithImpl<$Res>
    extends _$MessageListResponseDtoCopyWithImpl<$Res,
        _$MessageListResponseDtoImpl>
    implements _$$MessageListResponseDtoImplCopyWith<$Res> {
  __$$MessageListResponseDtoImplCopyWithImpl(
      _$MessageListResponseDtoImpl _value,
      $Res Function(_$MessageListResponseDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lastKey = freezed,
    Object? messages = null,
  }) {
    return _then(_$MessageListResponseDtoImpl(
      lastKey: freezed == lastKey
          ? _value.lastKey
          : lastKey // ignore: cast_nullable_to_non_nullable
              as LastKeyDto?,
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<MessageDto>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageListResponseDtoImpl implements _MessageListResponseDto {
  const _$MessageListResponseDtoImpl(
      {this.lastKey, final List<MessageDto> messages = const []})
      : _messages = messages;

  factory _$MessageListResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageListResponseDtoImplFromJson(json);

  @override
  final LastKeyDto? lastKey;
  final List<MessageDto> _messages;
  @override
  @JsonKey()
  List<MessageDto> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  String toString() {
    return 'MessageListResponseDto(lastKey: $lastKey, messages: $messages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageListResponseDtoImpl &&
            (identical(other.lastKey, lastKey) || other.lastKey == lastKey) &&
            const DeepCollectionEquality().equals(other._messages, _messages));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, lastKey, const DeepCollectionEquality().hash(_messages));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageListResponseDtoImplCopyWith<_$MessageListResponseDtoImpl>
      get copyWith => __$$MessageListResponseDtoImplCopyWithImpl<
          _$MessageListResponseDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageListResponseDtoImplToJson(
      this,
    );
  }
}

abstract class _MessageListResponseDto implements MessageListResponseDto {
  const factory _MessageListResponseDto(
      {final LastKeyDto? lastKey,
      final List<MessageDto> messages}) = _$MessageListResponseDtoImpl;

  factory _MessageListResponseDto.fromJson(Map<String, dynamic> json) =
      _$MessageListResponseDtoImpl.fromJson;

  @override
  LastKeyDto? get lastKey;
  @override
  List<MessageDto> get messages;
  @override
  @JsonKey(ignore: true)
  _$$MessageListResponseDtoImplCopyWith<_$MessageListResponseDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}

LastKeyDto _$LastKeyDtoFromJson(Map<String, dynamic> json) {
  return _LastKeyDto.fromJson(json);
}

/// @nodoc
mixin _$LastKeyDto {
  @JsonKey(name: 'conversationId')
  String get chatId => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LastKeyDtoCopyWith<LastKeyDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LastKeyDtoCopyWith<$Res> {
  factory $LastKeyDtoCopyWith(
          LastKeyDto value, $Res Function(LastKeyDto) then) =
      _$LastKeyDtoCopyWithImpl<$Res, LastKeyDto>;
  @useResult
  $Res call({@JsonKey(name: 'conversationId') String chatId, int createdAt});
}

/// @nodoc
class _$LastKeyDtoCopyWithImpl<$Res, $Val extends LastKeyDto>
    implements $LastKeyDtoCopyWith<$Res> {
  _$LastKeyDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LastKeyDtoImplCopyWith<$Res>
    implements $LastKeyDtoCopyWith<$Res> {
  factory _$$LastKeyDtoImplCopyWith(
          _$LastKeyDtoImpl value, $Res Function(_$LastKeyDtoImpl) then) =
      __$$LastKeyDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'conversationId') String chatId, int createdAt});
}

/// @nodoc
class __$$LastKeyDtoImplCopyWithImpl<$Res>
    extends _$LastKeyDtoCopyWithImpl<$Res, _$LastKeyDtoImpl>
    implements _$$LastKeyDtoImplCopyWith<$Res> {
  __$$LastKeyDtoImplCopyWithImpl(
      _$LastKeyDtoImpl _value, $Res Function(_$LastKeyDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? createdAt = null,
  }) {
    return _then(_$LastKeyDtoImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LastKeyDtoImpl implements _LastKeyDto {
  const _$LastKeyDtoImpl(
      {@JsonKey(name: 'conversationId') required this.chatId,
      required this.createdAt});

  factory _$LastKeyDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$LastKeyDtoImplFromJson(json);

  @override
  @JsonKey(name: 'conversationId')
  final String chatId;
  @override
  final int createdAt;

  @override
  String toString() {
    return 'LastKeyDto(chatId: $chatId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LastKeyDtoImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, chatId, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LastKeyDtoImplCopyWith<_$LastKeyDtoImpl> get copyWith =>
      __$$LastKeyDtoImplCopyWithImpl<_$LastKeyDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LastKeyDtoImplToJson(
      this,
    );
  }
}

abstract class _LastKeyDto implements LastKeyDto {
  const factory _LastKeyDto(
      {@JsonKey(name: 'conversationId') required final String chatId,
      required final int createdAt}) = _$LastKeyDtoImpl;

  factory _LastKeyDto.fromJson(Map<String, dynamic> json) =
      _$LastKeyDtoImpl.fromJson;

  @override
  @JsonKey(name: 'conversationId')
  String get chatId;
  @override
  int get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$LastKeyDtoImplCopyWith<_$LastKeyDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
