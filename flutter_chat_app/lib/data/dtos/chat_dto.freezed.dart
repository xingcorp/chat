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
  CreatorDto? get creator => throw _privateConstructorUsedError;
  List<MemberDto> get members => throw _privateConstructorUsedError;

  /// Serializes this ChatDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      CreatorDto? creator,
      List<MemberDto> members});

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

  /// Create a copy of ChatDto
  /// with the given fields replaced by the non-null parameter values.
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

  /// Create a copy of ChatDto
  /// with the given fields replaced by the non-null parameter values.
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
      CreatorDto? creator,
      List<MemberDto> members});

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

  /// Create a copy of ChatDto
  /// with the given fields replaced by the non-null parameter values.
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
    return 'ChatDto(id: $id, name: $name, type: $type, description: $description, imageUrl: $imageUrl, groupType: $groupType, createdAt: $createdAt, lastMessageAt: $lastMessageAt, lastMessageId: $lastMessageId, creator: $creator, members: $members)';
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
            (identical(other.creator, creator) || other.creator == creator) &&
            const DeepCollectionEquality().equals(other._members, _members));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
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
      creator,
      const DeepCollectionEquality().hash(_members));

  /// Create a copy of ChatDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
  CreatorDto? get creator;
  @override
  List<MemberDto> get members;

  /// Create a copy of ChatDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatDtoImplCopyWith<_$ChatDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatorDto _$CreatorDtoFromJson(Map<String, dynamic> json) {
  return _CreatorDto.fromJson(json);
}

/// @nodoc
mixin _$CreatorDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'fullname')
  String get fullName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Serializes this CreatorDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatorDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      String? avatarUrl});
}

/// @nodoc
class _$CreatorDtoCopyWithImpl<$Res, $Val extends CreatorDto>
    implements $CreatorDtoCopyWith<$Res> {
  _$CreatorDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatorDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? avatarUrl = freezed,
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
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
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
      String? avatarUrl});
}

/// @nodoc
class __$$CreatorDtoImplCopyWithImpl<$Res>
    extends _$CreatorDtoCopyWithImpl<$Res, _$CreatorDtoImpl>
    implements _$$CreatorDtoImplCopyWith<$Res> {
  __$$CreatorDtoImplCopyWithImpl(
      _$CreatorDtoImpl _value, $Res Function(_$CreatorDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of CreatorDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? avatarUrl = freezed,
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
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorDtoImpl implements _CreatorDto {
  const _$CreatorDtoImpl(
      {required this.id,
      @JsonKey(name: 'fullname') required this.fullName,
      this.avatarUrl});

  factory _$CreatorDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'fullname')
  final String fullName;
  @override
  final String? avatarUrl;

  @override
  String toString() {
    return 'CreatorDto(id: $id, fullName: $fullName, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, fullName, avatarUrl);

  /// Create a copy of CreatorDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      final String? avatarUrl}) = _$CreatorDtoImpl;

  factory _CreatorDto.fromJson(Map<String, dynamic> json) =
      _$CreatorDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'fullname')
  String get fullName;
  @override
  String? get avatarUrl;

  /// Create a copy of CreatorDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
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
  UserDto? get user => throw _privateConstructorUsedError;

  /// Serializes this MemberDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemberDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Create a copy of MemberDto
  /// with the given fields replaced by the non-null parameter values.
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
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserDto?,
    ) as $Val);
  }

  /// Create a copy of MemberDto
  /// with the given fields replaced by the non-null parameter values.
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

  /// Create a copy of MemberDto
  /// with the given fields replaced by the non-null parameter values.
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
  final UserDto? user;

  @override
  String toString() {
    return 'MemberDto(id: $id, userId: $userId, admin: $admin, connected: $connected, hide: $hide, unreadCount: $unreadCount, lastMessageReadId: $lastMessageReadId, user: $user)';
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
            (identical(other.user, user) || other.user == user));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, admin, connected,
      hide, unreadCount, lastMessageReadId, user);

  /// Create a copy of MemberDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
  UserDto? get user;

  /// Create a copy of MemberDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
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
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;

  /// Serializes this UserDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      String? avatarUrl,
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

  /// Create a copy of UserDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? avatarUrl = freezed,
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
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
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
      String? avatarUrl,
      String? email});
}

/// @nodoc
class __$$UserDtoImplCopyWithImpl<$Res>
    extends _$UserDtoCopyWithImpl<$Res, _$UserDtoImpl>
    implements _$$UserDtoImplCopyWith<$Res> {
  __$$UserDtoImplCopyWithImpl(
      _$UserDtoImpl _value, $Res Function(_$UserDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? avatarUrl = freezed,
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
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
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
      this.avatarUrl,
      this.email});

  factory _$UserDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'fullname')
  final String fullName;
  @override
  final String? avatarUrl;
  @override
  final String? email;

  @override
  String toString() {
    return 'UserDto(id: $id, fullName: $fullName, avatarUrl: $avatarUrl, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.email, email) || other.email == email));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, fullName, avatarUrl, email);

  /// Create a copy of UserDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      final String? avatarUrl,
      final String? email}) = _$UserDtoImpl;

  factory _UserDto.fromJson(Map<String, dynamic> json) = _$UserDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'fullname')
  String get fullName;
  @override
  String? get avatarUrl;
  @override
  String? get email;

  /// Create a copy of UserDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Serializes this ChatListResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatListResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Create a copy of ChatListResponseDto
  /// with the given fields replaced by the non-null parameter values.
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

  /// Create a copy of ChatListResponseDto
  /// with the given fields replaced by the non-null parameter values.
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, total, const DeepCollectionEquality().hash(_conversations));

  /// Create a copy of ChatListResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Create a copy of ChatListResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatListResponseDtoImplCopyWith<_$ChatListResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
