// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shared_media_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SharedMediaModel _$SharedMediaModelFromJson(Map<String, dynamic> json) {
  return _SharedMediaModel.fromJson(json);
}

/// @nodoc
mixin _$SharedMediaModel {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  String? get fileName => throw _privateConstructorUsedError;
  int? get fileSize => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String get senderName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SharedMediaModelCopyWith<SharedMediaModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SharedMediaModelCopyWith<$Res> {
  factory $SharedMediaModelCopyWith(
          SharedMediaModel value, $Res Function(SharedMediaModel) then) =
      _$SharedMediaModelCopyWithImpl<$Res, SharedMediaModel>;
  @useResult
  $Res call(
      {String id,
      String type,
      String url,
      String? thumbnailUrl,
      String? fileName,
      int? fileSize,
      DateTime createdAt,
      String senderId,
      String senderName});
}

/// @nodoc
class _$SharedMediaModelCopyWithImpl<$Res, $Val extends SharedMediaModel>
    implements $SharedMediaModelCopyWith<$Res> {
  _$SharedMediaModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? url = null,
    Object? thumbnailUrl = freezed,
    Object? fileName = freezed,
    Object? fileSize = freezed,
    Object? createdAt = null,
    Object? senderId = null,
    Object? senderName = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: null == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SharedMediaModelImplCopyWith<$Res>
    implements $SharedMediaModelCopyWith<$Res> {
  factory _$$SharedMediaModelImplCopyWith(_$SharedMediaModelImpl value,
          $Res Function(_$SharedMediaModelImpl) then) =
      __$$SharedMediaModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String type,
      String url,
      String? thumbnailUrl,
      String? fileName,
      int? fileSize,
      DateTime createdAt,
      String senderId,
      String senderName});
}

/// @nodoc
class __$$SharedMediaModelImplCopyWithImpl<$Res>
    extends _$SharedMediaModelCopyWithImpl<$Res, _$SharedMediaModelImpl>
    implements _$$SharedMediaModelImplCopyWith<$Res> {
  __$$SharedMediaModelImplCopyWithImpl(_$SharedMediaModelImpl _value,
      $Res Function(_$SharedMediaModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? url = null,
    Object? thumbnailUrl = freezed,
    Object? fileName = freezed,
    Object? fileSize = freezed,
    Object? createdAt = null,
    Object? senderId = null,
    Object? senderName = null,
  }) {
    return _then(_$SharedMediaModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: null == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SharedMediaModelImpl extends _SharedMediaModel {
  const _$SharedMediaModelImpl(
      {required this.id,
      required this.type,
      required this.url,
      this.thumbnailUrl,
      this.fileName,
      this.fileSize,
      required this.createdAt,
      required this.senderId,
      required this.senderName})
      : super._();

  factory _$SharedMediaModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SharedMediaModelImplFromJson(json);

  @override
  final String id;
  @override
  final String type;
  @override
  final String url;
  @override
  final String? thumbnailUrl;
  @override
  final String? fileName;
  @override
  final int? fileSize;
  @override
  final DateTime createdAt;
  @override
  final String senderId;
  @override
  final String senderName;

  @override
  String toString() {
    return 'SharedMediaModel(id: $id, type: $type, url: $url, thumbnailUrl: $thumbnailUrl, fileName: $fileName, fileSize: $fileSize, createdAt: $createdAt, senderId: $senderId, senderName: $senderName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SharedMediaModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, type, url, thumbnailUrl,
      fileName, fileSize, createdAt, senderId, senderName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SharedMediaModelImplCopyWith<_$SharedMediaModelImpl> get copyWith =>
      __$$SharedMediaModelImplCopyWithImpl<_$SharedMediaModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SharedMediaModelImplToJson(
      this,
    );
  }
}

abstract class _SharedMediaModel extends SharedMediaModel {
  const factory _SharedMediaModel(
      {required final String id,
      required final String type,
      required final String url,
      final String? thumbnailUrl,
      final String? fileName,
      final int? fileSize,
      required final DateTime createdAt,
      required final String senderId,
      required final String senderName}) = _$SharedMediaModelImpl;
  const _SharedMediaModel._() : super._();

  factory _SharedMediaModel.fromJson(Map<String, dynamic> json) =
      _$SharedMediaModelImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  String get url;
  @override
  String? get thumbnailUrl;
  @override
  String? get fileName;
  @override
  int? get fileSize;
  @override
  DateTime get createdAt;
  @override
  String get senderId;
  @override
  String get senderName;
  @override
  @JsonKey(ignore: true)
  _$$SharedMediaModelImplCopyWith<_$SharedMediaModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
