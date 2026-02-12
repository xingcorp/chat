// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatDto _$ChatDtoFromJson(Map<String, dynamic> json) {
  return _ChatDto.fromJson(json);
}

/// @nodoc
mixin _$ChatDto {
  String get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'imgUrl')
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get groupType => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int? get lastMessageAt => throw _privateConstructorUsedError;
  String? get lastMessageId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _lastMessageFromJson)
  LastMessageDto? get lastMessage => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _personalConversationFromJson)
  PersonalConversationDto? get personalConversation =>
      throw _privateConstructorUsedError;
  CreatorDto? get creator => throw _privateConstructorUsedError;
  List<MemberDto> get members => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChatDtoCopyWith<ChatDto> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatDtoCopyWith<$Res> {
  factory $ChatDtoCopyWith(ChatDto value, $Res Function(ChatDto) then) =
      _$ChatDtoCopyWithImpl<$Res, ChatDto>;
  @useResult
  $Res call(
      {String id,
      String? name,
      String type,
      String? description,
      @JsonKey(name: 'imgUrl') String? imageUrl,
      String? groupType,
      int createdAt,
      int? lastMessageAt,
      String? lastMessageId,
      @JsonKey(fromJson: _lastMessageFromJson) LastMessageDto? lastMessage,
      @JsonKey(fromJson: _personalConversationFromJson)
      PersonalConversationDto? personalConversation,
      CreatorDto? creator,
      List<MemberDto> members});

  $LastMessageDtoCopyWith<$Res>? get lastMessage;
  $PersonalConversationDtoCopyWith<$Res>? get personalConversation;
  $CreatorDtoCopyWith<$Res>? get creator;
}

/// @nodoc
class _$ChatDtoCopyWithImpl<$Res, $Val extends ChatDto>
    implements $ChatDtoCopyWith<$Res> {
  _$ChatDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? type = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? groupType = freezed,
    Object? createdAt = null,
    Object? lastMessageAt = freezed,
    Object? lastMessageId = freezed,
    Object? lastMessage = freezed,
    Object? personalConversation = freezed,
    Object? creator = freezed,
    Object? members = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      groupType: freezed == groupType
          ? _value.groupType
          : groupType // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as int?,
      lastMessageId: freezed == lastMessageId
          ? _value.lastMessageId
          : lastMessageId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as LastMessageDto?,
      personalConversation: freezed == personalConversation
          ? _value.personalConversation
          : personalConversation // ignore: cast_nullable_to_non_nullable
              as PersonalConversationDto?,
      creator: freezed == creator
          ? _value.creator
          : creator // ignore: cast_nullable_to_non_nullable
              as CreatorDto?,
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<MemberDto>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $LastMessageDtoCopyWith<$Res>? get lastMessage {
    if (_value.lastMessage == null) {
      return null;
    }

    return $LastMessageDtoCopyWith<$Res>(_value.lastMessage!, (value) {
      return _then(_value.copyWith(lastMessage: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $PersonalConversationDtoCopyWith<$Res>? get personalConversation {
    if (_value.personalConversation == null) {
      return null;
    }

    return $PersonalConversationDtoCopyWith<$Res>(_value.personalConversation!,
        (value) {
      return _then(_value.copyWith(personalConversation: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $CreatorDtoCopyWith<$Res>? get creator {
    if (_value.creator == null) {
      return null;
    }

    return $CreatorDtoCopyWith<$Res>(_value.creator!, (value) {
      return _then(_value.copyWith(creator: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ChatDtoImplCopyWith<$Res> implements $ChatDtoCopyWith<$Res> {
  factory _$$ChatDtoImplCopyWith(
          _$ChatDtoImpl value, $Res Function(_$ChatDtoImpl) then) =
      __$$ChatDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? name,
      String type,
      String? description,
      @JsonKey(name: 'imgUrl') String? imageUrl,
      String? groupType,
      int createdAt,
      int? lastMessageAt,
      String? lastMessageId,
      @JsonKey(fromJson: _lastMessageFromJson) LastMessageDto? lastMessage,
      @JsonKey(fromJson: _personalConversationFromJson)
      PersonalConversationDto? personalConversation,
      CreatorDto? creator,
      List<MemberDto> members});

  @override
  $LastMessageDtoCopyWith<$Res>? get lastMessage;
  @override
  $PersonalConversationDtoCopyWith<$Res>? get personalConversation;
  @override
  $CreatorDtoCopyWith<$Res>? get creator;
}

/// @nodoc
class __$$ChatDtoImplCopyWithImpl<$Res>
    extends _$ChatDtoCopyWithImpl<$Res, _$ChatDtoImpl>
    implements _$$ChatDtoImplCopyWith<$Res> {
  __$$ChatDtoImplCopyWithImpl(
      _$ChatDtoImpl _value, $Res Function(_$ChatDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? type = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? groupType = freezed,
    Object? createdAt = null,
    Object? lastMessageAt = freezed,
    Object? lastMessageId = freezed,
    Object? lastMessage = freezed,
    Object? personalConversation = freezed,
    Object? creator = freezed,
    Object? members = null,
  }) {
    return _then(_$ChatDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      groupType: freezed == groupType
          ? _value.groupType
          : groupType // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as int?,
      lastMessageId: freezed == lastMessageId
          ? _value.lastMessageId
          : lastMessageId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as LastMessageDto?,
      personalConversation: freezed == personalConversation
          ? _value.personalConversation
          : personalConversation // ignore: cast_nullable_to_non_nullable
              as PersonalConversationDto?,
      creator: freezed == creator
          ? _value.creator
          : creator // ignore: cast_nullable_to_non_nullable
              as CreatorDto?,
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<MemberDto>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatDtoImpl implements _ChatDto {
  const _$ChatDtoImpl(
      {required this.id,
      this.name,
      required this.type,
      this.description,
      @JsonKey(name: 'imgUrl') this.imageUrl,
      this.groupType,
      required this.createdAt,
      this.lastMessageAt,
      this.lastMessageId,
      @JsonKey(fromJson: _lastMessageFromJson) this.lastMessage,
      @JsonKey(fromJson: _personalConversationFromJson)
      this.personalConversation,
      this.creator,
      final List<MemberDto> members = const []})
      : _members = members;

  factory _$ChatDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String? name;
  @override
  final String type;
  @override
  final String? description;
  @override
  @JsonKey(name: 'imgUrl')
  final String? imageUrl;
  @override
  final String? groupType;
  @override
  final int createdAt;
  @override
  final int? lastMessageAt;
  @override
  final String? lastMessageId;
  @override
  @JsonKey(fromJson: _lastMessageFromJson)
  final LastMessageDto? lastMessage;
  @override
  @JsonKey(fromJson: _personalConversationFromJson)
  final PersonalConversationDto? personalConversation;
  @override
  final CreatorDto? creator;
  final List<MemberDto> _members;
  @override
  @JsonKey()
  List<MemberDto> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  String toString() {
    return 'ChatDto(id: $id, name: $name, type: $type, description: $description, imageUrl: $imageUrl, groupType: $groupType, createdAt: $createdAt, lastMessageAt: $lastMessageAt, lastMessageId: $lastMessageId, lastMessage: $lastMessage, personalConversation: $personalConversation, creator: $creator, members: $members)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.groupType, groupType) ||
                other.groupType == groupType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.lastMessageId, lastMessageId) ||
                other.lastMessageId == lastMessageId) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.personalConversation, personalConversation) ||
                other.personalConversation == personalConversation) &&
            (identical(other.creator, creator) || other.creator == creator) &&
            const DeepCollectionEquality().equals(other._members, _members));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      description,
      imageUrl,
      groupType,
      createdAt,
      lastMessageAt,
      lastMessageId,
      lastMessage,
      personalConversation,
      creator,
      const DeepCollectionEquality().hash(_members));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatDtoImplCopyWith<_$ChatDtoImpl> get copyWith =>
      __$$ChatDtoImplCopyWithImpl<_$ChatDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatDtoImplToJson(
      this,
    );
  }
}

abstract class _ChatDto implements ChatDto {
  const factory _ChatDto(
      {required final String id,
      final String? name,
      required final String type,
      final String? description,
      @JsonKey(name: 'imgUrl') final String? imageUrl,
      final String? groupType,
      required final int createdAt,
      final int? lastMessageAt,
      final String? lastMessageId,
      @JsonKey(fromJson: _lastMessageFromJson)
      final LastMessageDto? lastMessage,
      @JsonKey(fromJson: _personalConversationFromJson)
      final PersonalConversationDto? personalConversation,
      final CreatorDto? creator,
      final List<MemberDto> members}) = _$ChatDtoImpl;

  factory _ChatDto.fromJson(Map<String, dynamic> json) = _$ChatDtoImpl.fromJson;

  @override
  String get id;
  @override
  String? get name;
  @override
  String get type;
  @override
  String? get description;
  @override
  @JsonKey(name: 'imgUrl')
  String? get imageUrl;
  @override
  String? get groupType;
  @override
  int get createdAt;
  @override
  int? get lastMessageAt;
  @override
  String? get lastMessageId;
  @override
  @JsonKey(fromJson: _lastMessageFromJson)
  LastMessageDto? get lastMessage;
  @override
  @JsonKey(fromJson: _personalConversationFromJson)
  PersonalConversationDto? get personalConversation;
  @override
  CreatorDto? get creator;
  @override
  List<MemberDto> get members;
  @override
  @JsonKey(ignore: true)
  _$$ChatDtoImplCopyWith<_$ChatDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LastMessageDto _$LastMessageDtoFromJson(Map<String, dynamic> json) {
  return _LastMessageDto.fromJson(json);
}

/// @nodoc
mixin _$LastMessageDto {
  String get id => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  String? get fileName => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _userBriefFromJson)
  UserBriefDto? get sender => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _mentionToFromJson)
  MentionToDto? get mentionTo => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LastMessageDtoCopyWith<LastMessageDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LastMessageDtoCopyWith<$Res> {
  factory $LastMessageDtoCopyWith(
          LastMessageDto value, $Res Function(LastMessageDto) then) =
      _$LastMessageDtoCopyWithImpl<$Res, LastMessageDto>;
  @useResult
  $Res call(
      {String id,
      String? message,
      String? fileName,
      String? type,
      @JsonKey(fromJson: _userBriefFromJson) UserBriefDto? sender,
      @JsonKey(fromJson: _mentionToFromJson) MentionToDto? mentionTo});

  $UserBriefDtoCopyWith<$Res>? get sender;
  $MentionToDtoCopyWith<$Res>? get mentionTo;
}

/// @nodoc
class _$LastMessageDtoCopyWithImpl<$Res, $Val extends LastMessageDto>
    implements $LastMessageDtoCopyWith<$Res> {
  _$LastMessageDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? message = freezed,
    Object? fileName = freezed,
    Object? type = freezed,
    Object? sender = freezed,
    Object? mentionTo = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      sender: freezed == sender
          ? _value.sender
          : sender // ignore: cast_nullable_to_non_nullable
              as UserBriefDto?,
      mentionTo: freezed == mentionTo
          ? _value.mentionTo
          : mentionTo // ignore: cast_nullable_to_non_nullable
              as MentionToDto?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserBriefDtoCopyWith<$Res>? get sender {
    if (_value.sender == null) {
      return null;
    }

    return $UserBriefDtoCopyWith<$Res>(_value.sender!, (value) {
      return _then(_value.copyWith(sender: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $MentionToDtoCopyWith<$Res>? get mentionTo {
    if (_value.mentionTo == null) {
      return null;
    }

    return $MentionToDtoCopyWith<$Res>(_value.mentionTo!, (value) {
      return _then(_value.copyWith(mentionTo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LastMessageDtoImplCopyWith<$Res>
    implements $LastMessageDtoCopyWith<$Res> {
  factory _$$LastMessageDtoImplCopyWith(_$LastMessageDtoImpl value,
          $Res Function(_$LastMessageDtoImpl) then) =
      __$$LastMessageDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? message,
      String? fileName,
      String? type,
      @JsonKey(fromJson: _userBriefFromJson) UserBriefDto? sender,
      @JsonKey(fromJson: _mentionToFromJson) MentionToDto? mentionTo});

  @override
  $UserBriefDtoCopyWith<$Res>? get sender;
  @override
  $MentionToDtoCopyWith<$Res>? get mentionTo;
}

/// @nodoc
class __$$LastMessageDtoImplCopyWithImpl<$Res>
    extends _$LastMessageDtoCopyWithImpl<$Res, _$LastMessageDtoImpl>
    implements _$$LastMessageDtoImplCopyWith<$Res> {
  __$$LastMessageDtoImplCopyWithImpl(
      _$LastMessageDtoImpl _value, $Res Function(_$LastMessageDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? message = freezed,
    Object? fileName = freezed,
    Object? type = freezed,
    Object? sender = freezed,
    Object? mentionTo = freezed,
  }) {
    return _then(_$LastMessageDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      sender: freezed == sender
          ? _value.sender
          : sender // ignore: cast_nullable_to_non_nullable
              as UserBriefDto?,
      mentionTo: freezed == mentionTo
          ? _value.mentionTo
          : mentionTo // ignore: cast_nullable_to_non_nullable
              as MentionToDto?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LastMessageDtoImpl implements _LastMessageDto {
  const _$LastMessageDtoImpl(
      {required this.id,
      this.message,
      this.fileName,
      this.type,
      @JsonKey(fromJson: _userBriefFromJson) this.sender,
      @JsonKey(fromJson: _mentionToFromJson) this.mentionTo});

  factory _$LastMessageDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$LastMessageDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String? message;
  @override
  final String? fileName;
  @override
  final String? type;
  @override
  @JsonKey(fromJson: _userBriefFromJson)
  final UserBriefDto? sender;
  @override
  @JsonKey(fromJson: _mentionToFromJson)
  final MentionToDto? mentionTo;

  @override
  String toString() {
    return 'LastMessageDto(id: $id, message: $message, fileName: $fileName, type: $type, sender: $sender, mentionTo: $mentionTo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LastMessageDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.sender, sender) || other.sender == sender) &&
            (identical(other.mentionTo, mentionTo) ||
                other.mentionTo == mentionTo));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, message, fileName, type, sender, mentionTo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LastMessageDtoImplCopyWith<_$LastMessageDtoImpl> get copyWith =>
      __$$LastMessageDtoImplCopyWithImpl<_$LastMessageDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LastMessageDtoImplToJson(
      this,
    );
  }
}

abstract class _LastMessageDto implements LastMessageDto {
  const factory _LastMessageDto(
      {required final String id,
      final String? message,
      final String? fileName,
      final String? type,
      @JsonKey(fromJson: _userBriefFromJson) final UserBriefDto? sender,
      @JsonKey(fromJson: _mentionToFromJson)
      final MentionToDto? mentionTo}) = _$LastMessageDtoImpl;

  factory _LastMessageDto.fromJson(Map<String, dynamic> json) =
      _$LastMessageDtoImpl.fromJson;

  @override
  String get id;
  @override
  String? get message;
  @override
  String? get fileName;
  @override
  String? get type;
  @override
  @JsonKey(fromJson: _userBriefFromJson)
  UserBriefDto? get sender;
  @override
  @JsonKey(fromJson: _mentionToFromJson)
  MentionToDto? get mentionTo;
  @override
  @JsonKey(ignore: true)
  _$$LastMessageDtoImplCopyWith<_$LastMessageDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserBriefDto _$UserBriefDtoFromJson(Map<String, dynamic> json) {
  return _UserBriefDto.fromJson(json);
}

/// @nodoc
mixin _$UserBriefDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'fullname')
  String get fullName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserBriefDtoCopyWith<UserBriefDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserBriefDtoCopyWith<$Res> {
  factory $UserBriefDtoCopyWith(
          UserBriefDto value, $Res Function(UserBriefDto) then) =
      _$UserBriefDtoCopyWithImpl<$Res, UserBriefDto>;
  @useResult
  $Res call({String id, @JsonKey(name: 'fullname') String fullName});
}

/// @nodoc
class _$UserBriefDtoCopyWithImpl<$Res, $Val extends UserBriefDto>
    implements $UserBriefDtoCopyWith<$Res> {
  _$UserBriefDtoCopyWithImpl(this._value, this._then);

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
abstract class _$$UserBriefDtoImplCopyWith<$Res>
    implements $UserBriefDtoCopyWith<$Res> {
  factory _$$UserBriefDtoImplCopyWith(
          _$UserBriefDtoImpl value, $Res Function(_$UserBriefDtoImpl) then) =
      __$$UserBriefDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, @JsonKey(name: 'fullname') String fullName});
}

/// @nodoc
class __$$UserBriefDtoImplCopyWithImpl<$Res>
    extends _$UserBriefDtoCopyWithImpl<$Res, _$UserBriefDtoImpl>
    implements _$$UserBriefDtoImplCopyWith<$Res> {
  __$$UserBriefDtoImplCopyWithImpl(
      _$UserBriefDtoImpl _value, $Res Function(_$UserBriefDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
  }) {
    return _then(_$UserBriefDtoImpl(
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
class _$UserBriefDtoImpl implements _UserBriefDto {
  const _$UserBriefDtoImpl(
      {required this.id, @JsonKey(name: 'fullname') required this.fullName});

  factory _$UserBriefDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserBriefDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'fullname')
  final String fullName;

  @override
  String toString() {
    return 'UserBriefDto(id: $id, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserBriefDtoImpl &&
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
  _$$UserBriefDtoImplCopyWith<_$UserBriefDtoImpl> get copyWith =>
      __$$UserBriefDtoImplCopyWithImpl<_$UserBriefDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserBriefDtoImplToJson(
      this,
    );
  }
}

abstract class _UserBriefDto implements UserBriefDto {
  const factory _UserBriefDto(
          {required final String id,
          @JsonKey(name: 'fullname') required final String fullName}) =
      _$UserBriefDtoImpl;

  factory _UserBriefDto.fromJson(Map<String, dynamic> json) =
      _$UserBriefDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'fullname')
  String get fullName;
  @override
  @JsonKey(ignore: true)
  _$$UserBriefDtoImplCopyWith<_$UserBriefDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MentionToDto _$MentionToDtoFromJson(Map<String, dynamic> json) {
  return _MentionToDto.fromJson(json);
}

/// @nodoc
mixin _$MentionToDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'fullname')
  String get fullName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MentionToDtoCopyWith<MentionToDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MentionToDtoCopyWith<$Res> {
  factory $MentionToDtoCopyWith(
          MentionToDto value, $Res Function(MentionToDto) then) =
      _$MentionToDtoCopyWithImpl<$Res, MentionToDto>;
  @useResult
  $Res call({String id, @JsonKey(name: 'fullname') String fullName});
}

/// @nodoc
class _$MentionToDtoCopyWithImpl<$Res, $Val extends MentionToDto>
    implements $MentionToDtoCopyWith<$Res> {
  _$MentionToDtoCopyWithImpl(this._value, this._then);

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
abstract class _$$MentionToDtoImplCopyWith<$Res>
    implements $MentionToDtoCopyWith<$Res> {
  factory _$$MentionToDtoImplCopyWith(
          _$MentionToDtoImpl value, $Res Function(_$MentionToDtoImpl) then) =
      __$$MentionToDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, @JsonKey(name: 'fullname') String fullName});
}

/// @nodoc
class __$$MentionToDtoImplCopyWithImpl<$Res>
    extends _$MentionToDtoCopyWithImpl<$Res, _$MentionToDtoImpl>
    implements _$$MentionToDtoImplCopyWith<$Res> {
  __$$MentionToDtoImplCopyWithImpl(
      _$MentionToDtoImpl _value, $Res Function(_$MentionToDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
  }) {
    return _then(_$MentionToDtoImpl(
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
class _$MentionToDtoImpl implements _MentionToDto {
  const _$MentionToDtoImpl(
      {required this.id, @JsonKey(name: 'fullname') required this.fullName});

  factory _$MentionToDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MentionToDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'fullname')
  final String fullName;

  @override
  String toString() {
    return 'MentionToDto(id: $id, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MentionToDtoImpl &&
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
  _$$MentionToDtoImplCopyWith<_$MentionToDtoImpl> get copyWith =>
      __$$MentionToDtoImplCopyWithImpl<_$MentionToDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MentionToDtoImplToJson(
      this,
    );
  }
}

abstract class _MentionToDto implements MentionToDto {
  const factory _MentionToDto(
          {required final String id,
          @JsonKey(name: 'fullname') required final String fullName}) =
      _$MentionToDtoImpl;

  factory _MentionToDto.fromJson(Map<String, dynamic> json) =
      _$MentionToDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'fullname')
  String get fullName;
  @override
  @JsonKey(ignore: true)
  _$$MentionToDtoImplCopyWith<_$MentionToDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PersonalConversationDto _$PersonalConversationDtoFromJson(
    Map<String, dynamic> json) {
  return _PersonalConversationDto.fromJson(json);
}

/// @nodoc
mixin _$PersonalConversationDto {
  String? get lastMessageReadId => throw _privateConstructorUsedError;
  int get unreadCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PersonalConversationDtoCopyWith<PersonalConversationDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonalConversationDtoCopyWith<$Res> {
  factory $PersonalConversationDtoCopyWith(PersonalConversationDto value,
          $Res Function(PersonalConversationDto) then) =
      _$PersonalConversationDtoCopyWithImpl<$Res, PersonalConversationDto>;
  @useResult
  $Res call({String? lastMessageReadId, int unreadCount});
}

/// @nodoc
class _$PersonalConversationDtoCopyWithImpl<$Res,
        $Val extends PersonalConversationDto>
    implements $PersonalConversationDtoCopyWith<$Res> {
  _$PersonalConversationDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lastMessageReadId = freezed,
    Object? unreadCount = null,
  }) {
    return _then(_value.copyWith(
      lastMessageReadId: freezed == lastMessageReadId
          ? _value.lastMessageReadId
          : lastMessageReadId // ignore: cast_nullable_to_non_nullable
              as String?,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PersonalConversationDtoImplCopyWith<$Res>
    implements $PersonalConversationDtoCopyWith<$Res> {
  factory _$$PersonalConversationDtoImplCopyWith(
          _$PersonalConversationDtoImpl value,
          $Res Function(_$PersonalConversationDtoImpl) then) =
      __$$PersonalConversationDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? lastMessageReadId, int unreadCount});
}

/// @nodoc
class __$$PersonalConversationDtoImplCopyWithImpl<$Res>
    extends _$PersonalConversationDtoCopyWithImpl<$Res,
        _$PersonalConversationDtoImpl>
    implements _$$PersonalConversationDtoImplCopyWith<$Res> {
  __$$PersonalConversationDtoImplCopyWithImpl(
      _$PersonalConversationDtoImpl _value,
      $Res Function(_$PersonalConversationDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lastMessageReadId = freezed,
    Object? unreadCount = null,
  }) {
    return _then(_$PersonalConversationDtoImpl(
      lastMessageReadId: freezed == lastMessageReadId
          ? _value.lastMessageReadId
          : lastMessageReadId // ignore: cast_nullable_to_non_nullable
              as String?,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PersonalConversationDtoImpl implements _PersonalConversationDto {
  const _$PersonalConversationDtoImpl(
      {this.lastMessageReadId, this.unreadCount = 0});

  factory _$PersonalConversationDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonalConversationDtoImplFromJson(json);

  @override
  final String? lastMessageReadId;
  @override
  @JsonKey()
  final int unreadCount;

  @override
  String toString() {
    return 'PersonalConversationDto(lastMessageReadId: $lastMessageReadId, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonalConversationDtoImpl &&
            (identical(other.lastMessageReadId, lastMessageReadId) ||
                other.lastMessageReadId == lastMessageReadId) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, lastMessageReadId, unreadCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonalConversationDtoImplCopyWith<_$PersonalConversationDtoImpl>
      get copyWith => __$$PersonalConversationDtoImplCopyWithImpl<
          _$PersonalConversationDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonalConversationDtoImplToJson(
      this,
    );
  }
}

abstract class _PersonalConversationDto implements PersonalConversationDto {
  const factory _PersonalConversationDto(
      {final String? lastMessageReadId,
      final int unreadCount}) = _$PersonalConversationDtoImpl;

  factory _PersonalConversationDto.fromJson(Map<String, dynamic> json) =
      _$PersonalConversationDtoImpl.fromJson;

  @override
  String? get lastMessageReadId;
  @override
  int get unreadCount;
  @override
  @JsonKey(ignore: true)
  _$$PersonalConversationDtoImplCopyWith<_$PersonalConversationDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}

CreatorDto _$CreatorDtoFromJson(Map<String, dynamic> json) {
  return _CreatorDto.fromJson(json);
}

/// @nodoc
mixin _$CreatorDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'fullname')
  String get fullName => throw _privateConstructorUsedError;
  List<String> get imageUrls => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CreatorDtoCopyWith<CreatorDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorDtoCopyWith<$Res> {
  factory $CreatorDtoCopyWith(
          CreatorDto value, $Res Function(CreatorDto) then) =
      _$CreatorDtoCopyWithImpl<$Res, CreatorDto>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'fullname') String fullName,
      List<String> imageUrls});
}

/// @nodoc
class _$CreatorDtoCopyWithImpl<$Res, $Val extends CreatorDto>
    implements $CreatorDtoCopyWith<$Res> {
  _$CreatorDtoCopyWithImpl(this._value, this._then);

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
abstract class _$$CreatorDtoImplCopyWith<$Res>
    implements $CreatorDtoCopyWith<$Res> {
  factory _$$CreatorDtoImplCopyWith(
          _$CreatorDtoImpl value, $Res Function(_$CreatorDtoImpl) then) =
      __$$CreatorDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'fullname') String fullName,
      List<String> imageUrls});
}

/// @nodoc
class __$$CreatorDtoImplCopyWithImpl<$Res>
    extends _$CreatorDtoCopyWithImpl<$Res, _$CreatorDtoImpl>
    implements _$$CreatorDtoImplCopyWith<$Res> {
  __$$CreatorDtoImplCopyWithImpl(
      _$CreatorDtoImpl _value, $Res Function(_$CreatorDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? imageUrls = null,
  }) {
    return _then(_$CreatorDtoImpl(
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
class _$CreatorDtoImpl implements _CreatorDto {
  const _$CreatorDtoImpl(
      {required this.id,
      @JsonKey(name: 'fullname') required this.fullName,
      final List<String> imageUrls = const []})
      : _imageUrls = imageUrls;

  factory _$CreatorDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorDtoImplFromJson(json);

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
    return 'CreatorDto(id: $id, fullName: $fullName, imageUrls: $imageUrls)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorDtoImpl &&
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
  _$$CreatorDtoImplCopyWith<_$CreatorDtoImpl> get copyWith =>
      __$$CreatorDtoImplCopyWithImpl<_$CreatorDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorDtoImplToJson(
      this,
    );
  }
}

abstract class _CreatorDto implements CreatorDto {
  const factory _CreatorDto(
      {required final String id,
      @JsonKey(name: 'fullname') required final String fullName,
      final List<String> imageUrls}) = _$CreatorDtoImpl;

  factory _CreatorDto.fromJson(Map<String, dynamic> json) =
      _$CreatorDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'fullname')
  String get fullName;
  @override
  List<String> get imageUrls;
  @override
  @JsonKey(ignore: true)
  _$$CreatorDtoImplCopyWith<_$CreatorDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemberDto _$MemberDtoFromJson(Map<String, dynamic> json) {
  return _MemberDto.fromJson(json);
}

/// @nodoc
mixin _$MemberDto {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  bool get admin => throw _privateConstructorUsedError;
  bool get connected => throw _privateConstructorUsedError;
  bool get hide => throw _privateConstructorUsedError;
  int get unreadCount => throw _privateConstructorUsedError;
  String? get lastMessageReadId => throw _privateConstructorUsedError;
  int? get viewMessagesFrom =>
      throw _privateConstructorUsedError; // Timestamp in milliseconds
  UserDto? get user => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MemberDtoCopyWith<MemberDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemberDtoCopyWith<$Res> {
  factory $MemberDtoCopyWith(MemberDto value, $Res Function(MemberDto) then) =
      _$MemberDtoCopyWithImpl<$Res, MemberDto>;
  @useResult
  $Res call(
      {String id,
      String userId,
      bool admin,
      bool connected,
      bool hide,
      int unreadCount,
      String? lastMessageReadId,
      int? viewMessagesFrom,
      UserDto? user});

  $UserDtoCopyWith<$Res>? get user;
}

/// @nodoc
class _$MemberDtoCopyWithImpl<$Res, $Val extends MemberDto>
    implements $MemberDtoCopyWith<$Res> {
  _$MemberDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? admin = null,
    Object? connected = null,
    Object? hide = null,
    Object? unreadCount = null,
    Object? lastMessageReadId = freezed,
    Object? viewMessagesFrom = freezed,
    Object? user = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      admin: null == admin
          ? _value.admin
          : admin // ignore: cast_nullable_to_non_nullable
              as bool,
      connected: null == connected
          ? _value.connected
          : connected // ignore: cast_nullable_to_non_nullable
              as bool,
      hide: null == hide
          ? _value.hide
          : hide // ignore: cast_nullable_to_non_nullable
              as bool,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastMessageReadId: freezed == lastMessageReadId
          ? _value.lastMessageReadId
          : lastMessageReadId // ignore: cast_nullable_to_non_nullable
              as String?,
      viewMessagesFrom: freezed == viewMessagesFrom
          ? _value.viewMessagesFrom
          : viewMessagesFrom // ignore: cast_nullable_to_non_nullable
              as int?,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserDto?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserDtoCopyWith<$Res>? get user {
    if (_value.user == null) {
      return null;
    }

    return $UserDtoCopyWith<$Res>(_value.user!, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MemberDtoImplCopyWith<$Res>
    implements $MemberDtoCopyWith<$Res> {
  factory _$$MemberDtoImplCopyWith(
          _$MemberDtoImpl value, $Res Function(_$MemberDtoImpl) then) =
      __$$MemberDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      bool admin,
      bool connected,
      bool hide,
      int unreadCount,
      String? lastMessageReadId,
      int? viewMessagesFrom,
      UserDto? user});

  @override
  $UserDtoCopyWith<$Res>? get user;
}

/// @nodoc
class __$$MemberDtoImplCopyWithImpl<$Res>
    extends _$MemberDtoCopyWithImpl<$Res, _$MemberDtoImpl>
    implements _$$MemberDtoImplCopyWith<$Res> {
  __$$MemberDtoImplCopyWithImpl(
      _$MemberDtoImpl _value, $Res Function(_$MemberDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? admin = null,
    Object? connected = null,
    Object? hide = null,
    Object? unreadCount = null,
    Object? lastMessageReadId = freezed,
    Object? viewMessagesFrom = freezed,
    Object? user = freezed,
  }) {
    return _then(_$MemberDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      admin: null == admin
          ? _value.admin
          : admin // ignore: cast_nullable_to_non_nullable
              as bool,
      connected: null == connected
          ? _value.connected
          : connected // ignore: cast_nullable_to_non_nullable
              as bool,
      hide: null == hide
          ? _value.hide
          : hide // ignore: cast_nullable_to_non_nullable
              as bool,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastMessageReadId: freezed == lastMessageReadId
          ? _value.lastMessageReadId
          : lastMessageReadId // ignore: cast_nullable_to_non_nullable
              as String?,
      viewMessagesFrom: freezed == viewMessagesFrom
          ? _value.viewMessagesFrom
          : viewMessagesFrom // ignore: cast_nullable_to_non_nullable
              as int?,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserDto?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemberDtoImpl implements _MemberDto {
  const _$MemberDtoImpl(
      {required this.id,
      required this.userId,
      this.admin = false,
      this.connected = false,
      this.hide = false,
      this.unreadCount = 0,
      this.lastMessageReadId,
      this.viewMessagesFrom,
      this.user});

  factory _$MemberDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemberDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  @JsonKey()
  final bool admin;
  @override
  @JsonKey()
  final bool connected;
  @override
  @JsonKey()
  final bool hide;
  @override
  @JsonKey()
  final int unreadCount;
  @override
  final String? lastMessageReadId;
  @override
  final int? viewMessagesFrom;
// Timestamp in milliseconds
  @override
  final UserDto? user;

  @override
  String toString() {
    return 'MemberDto(id: $id, userId: $userId, admin: $admin, connected: $connected, hide: $hide, unreadCount: $unreadCount, lastMessageReadId: $lastMessageReadId, viewMessagesFrom: $viewMessagesFrom, user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemberDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.admin, admin) || other.admin == admin) &&
            (identical(other.connected, connected) ||
                other.connected == connected) &&
            (identical(other.hide, hide) || other.hide == hide) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount) &&
            (identical(other.lastMessageReadId, lastMessageReadId) ||
                other.lastMessageReadId == lastMessageReadId) &&
            (identical(other.viewMessagesFrom, viewMessagesFrom) ||
                other.viewMessagesFrom == viewMessagesFrom) &&
            (identical(other.user, user) || other.user == user));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, admin, connected,
      hide, unreadCount, lastMessageReadId, viewMessagesFrom, user);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MemberDtoImplCopyWith<_$MemberDtoImpl> get copyWith =>
      __$$MemberDtoImplCopyWithImpl<_$MemberDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemberDtoImplToJson(
      this,
    );
  }
}

abstract class _MemberDto implements MemberDto {
  const factory _MemberDto(
      {required final String id,
      required final String userId,
      final bool admin,
      final bool connected,
      final bool hide,
      final int unreadCount,
      final String? lastMessageReadId,
      final int? viewMessagesFrom,
      final UserDto? user}) = _$MemberDtoImpl;

  factory _MemberDto.fromJson(Map<String, dynamic> json) =
      _$MemberDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  bool get admin;
  @override
  bool get connected;
  @override
  bool get hide;
  @override
  int get unreadCount;
  @override
  String? get lastMessageReadId;
  @override
  int? get viewMessagesFrom;
  @override // Timestamp in milliseconds
  UserDto? get user;
  @override
  @JsonKey(ignore: true)
  _$$MemberDtoImplCopyWith<_$MemberDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserDto _$UserDtoFromJson(Map<String, dynamic> json) {
  return _UserDto.fromJson(json);
}

/// @nodoc
mixin _$UserDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'fullname')
  String get fullName => throw _privateConstructorUsedError;
  List<String> get imageUrls => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserDtoCopyWith<UserDto> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserDtoCopyWith<$Res> {
  factory $UserDtoCopyWith(UserDto value, $Res Function(UserDto) then) =
      _$UserDtoCopyWithImpl<$Res, UserDto>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'fullname') String fullName,
      List<String> imageUrls,
      String? email});
}

/// @nodoc
class _$UserDtoCopyWithImpl<$Res, $Val extends UserDto>
    implements $UserDtoCopyWith<$Res> {
  _$UserDtoCopyWithImpl(this._value, this._then);

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
    Object? email = freezed,
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
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserDtoImplCopyWith<$Res> implements $UserDtoCopyWith<$Res> {
  factory _$$UserDtoImplCopyWith(
          _$UserDtoImpl value, $Res Function(_$UserDtoImpl) then) =
      __$$UserDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'fullname') String fullName,
      List<String> imageUrls,
      String? email});
}

/// @nodoc
class __$$UserDtoImplCopyWithImpl<$Res>
    extends _$UserDtoCopyWithImpl<$Res, _$UserDtoImpl>
    implements _$$UserDtoImplCopyWith<$Res> {
  __$$UserDtoImplCopyWithImpl(
      _$UserDtoImpl _value, $Res Function(_$UserDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? imageUrls = null,
    Object? email = freezed,
  }) {
    return _then(_$UserDtoImpl(
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
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserDtoImpl implements _UserDto {
  const _$UserDtoImpl(
      {required this.id,
      @JsonKey(name: 'fullname') required this.fullName,
      final List<String> imageUrls = const [],
      this.email})
      : _imageUrls = imageUrls;

  factory _$UserDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserDtoImplFromJson(json);

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
  final String? email;

  @override
  String toString() {
    return 'UserDto(id: $id, fullName: $fullName, imageUrls: $imageUrls, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            const DeepCollectionEquality()
                .equals(other._imageUrls, _imageUrls) &&
            (identical(other.email, email) || other.email == email));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, fullName,
      const DeepCollectionEquality().hash(_imageUrls), email);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserDtoImplCopyWith<_$UserDtoImpl> get copyWith =>
      __$$UserDtoImplCopyWithImpl<_$UserDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserDtoImplToJson(
      this,
    );
  }
}

abstract class _UserDto implements UserDto {
  const factory _UserDto(
      {required final String id,
      @JsonKey(name: 'fullname') required final String fullName,
      final List<String> imageUrls,
      final String? email}) = _$UserDtoImpl;

  factory _UserDto.fromJson(Map<String, dynamic> json) = _$UserDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'fullname')
  String get fullName;
  @override
  List<String> get imageUrls;
  @override
  String? get email;
  @override
  @JsonKey(ignore: true)
  _$$UserDtoImplCopyWith<_$UserDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatListResponseDto _$ChatListResponseDtoFromJson(Map<String, dynamic> json) {
  return _ChatListResponseDto.fromJson(json);
}

/// @nodoc
mixin _$ChatListResponseDto {
  int get total => throw _privateConstructorUsedError;
  List<ChatDto> get conversations => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChatListResponseDtoCopyWith<ChatListResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatListResponseDtoCopyWith<$Res> {
  factory $ChatListResponseDtoCopyWith(
          ChatListResponseDto value, $Res Function(ChatListResponseDto) then) =
      _$ChatListResponseDtoCopyWithImpl<$Res, ChatListResponseDto>;
  @useResult
  $Res call({int total, List<ChatDto> conversations});
}

/// @nodoc
class _$ChatListResponseDtoCopyWithImpl<$Res, $Val extends ChatListResponseDto>
    implements $ChatListResponseDtoCopyWith<$Res> {
  _$ChatListResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? conversations = null,
  }) {
    return _then(_value.copyWith(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      conversations: null == conversations
          ? _value.conversations
          : conversations // ignore: cast_nullable_to_non_nullable
              as List<ChatDto>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatListResponseDtoImplCopyWith<$Res>
    implements $ChatListResponseDtoCopyWith<$Res> {
  factory _$$ChatListResponseDtoImplCopyWith(_$ChatListResponseDtoImpl value,
          $Res Function(_$ChatListResponseDtoImpl) then) =
      __$$ChatListResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int total, List<ChatDto> conversations});
}

/// @nodoc
class __$$ChatListResponseDtoImplCopyWithImpl<$Res>
    extends _$ChatListResponseDtoCopyWithImpl<$Res, _$ChatListResponseDtoImpl>
    implements _$$ChatListResponseDtoImplCopyWith<$Res> {
  __$$ChatListResponseDtoImplCopyWithImpl(_$ChatListResponseDtoImpl _value,
      $Res Function(_$ChatListResponseDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? conversations = null,
  }) {
    return _then(_$ChatListResponseDtoImpl(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      conversations: null == conversations
          ? _value._conversations
          : conversations // ignore: cast_nullable_to_non_nullable
              as List<ChatDto>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatListResponseDtoImpl implements _ChatListResponseDto {
  const _$ChatListResponseDtoImpl(
      {required this.total, final List<ChatDto> conversations = const []})
      : _conversations = conversations;

  factory _$ChatListResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatListResponseDtoImplFromJson(json);

  @override
  final int total;
  final List<ChatDto> _conversations;
  @override
  @JsonKey()
  List<ChatDto> get conversations {
    if (_conversations is EqualUnmodifiableListView) return _conversations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conversations);
  }

  @override
  String toString() {
    return 'ChatListResponseDto(total: $total, conversations: $conversations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatListResponseDtoImpl &&
            (identical(other.total, total) || other.total == total) &&
            const DeepCollectionEquality()
                .equals(other._conversations, _conversations));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, total, const DeepCollectionEquality().hash(_conversations));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatListResponseDtoImplCopyWith<_$ChatListResponseDtoImpl> get copyWith =>
      __$$ChatListResponseDtoImplCopyWithImpl<_$ChatListResponseDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatListResponseDtoImplToJson(
      this,
    );
  }
}

abstract class _ChatListResponseDto implements ChatListResponseDto {
  const factory _ChatListResponseDto(
      {required final int total,
      final List<ChatDto> conversations}) = _$ChatListResponseDtoImpl;

  factory _ChatListResponseDto.fromJson(Map<String, dynamic> json) =
      _$ChatListResponseDtoImpl.fromJson;

  @override
  int get total;
  @override
  List<ChatDto> get conversations;
  @override
  @JsonKey(ignore: true)
  _$$ChatListResponseDtoImplCopyWith<_$ChatListResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
