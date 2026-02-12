// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_object_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatObjectUploadResponseDto _$ChatObjectUploadResponseDtoFromJson(
    Map<String, dynamic> json) {
  return _ChatObjectUploadResponseDto.fromJson(json);
}

/// @nodoc
mixin _$ChatObjectUploadResponseDto {
  /// Pre-signed GCP Cloud Storage URL for direct upload (PUT request)
  String get uploadUrl => throw _privateConstructorUsedError;

  /// Storage path for referencing uploaded file
  /// Format: MESSAGE/{conversationId}/{timestamp}/{filename}
  String get path => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChatObjectUploadResponseDtoCopyWith<ChatObjectUploadResponseDto>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatObjectUploadResponseDtoCopyWith<$Res> {
  factory $ChatObjectUploadResponseDtoCopyWith(
          ChatObjectUploadResponseDto value,
          $Res Function(ChatObjectUploadResponseDto) then) =
      _$ChatObjectUploadResponseDtoCopyWithImpl<$Res,
          ChatObjectUploadResponseDto>;
  @useResult
  $Res call({String uploadUrl, String path});
}

/// @nodoc
class _$ChatObjectUploadResponseDtoCopyWithImpl<$Res,
        $Val extends ChatObjectUploadResponseDto>
    implements $ChatObjectUploadResponseDtoCopyWith<$Res> {
  _$ChatObjectUploadResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uploadUrl = null,
    Object? path = null,
  }) {
    return _then(_value.copyWith(
      uploadUrl: null == uploadUrl
          ? _value.uploadUrl
          : uploadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatObjectUploadResponseDtoImplCopyWith<$Res>
    implements $ChatObjectUploadResponseDtoCopyWith<$Res> {
  factory _$$ChatObjectUploadResponseDtoImplCopyWith(
          _$ChatObjectUploadResponseDtoImpl value,
          $Res Function(_$ChatObjectUploadResponseDtoImpl) then) =
      __$$ChatObjectUploadResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String uploadUrl, String path});
}

/// @nodoc
class __$$ChatObjectUploadResponseDtoImplCopyWithImpl<$Res>
    extends _$ChatObjectUploadResponseDtoCopyWithImpl<$Res,
        _$ChatObjectUploadResponseDtoImpl>
    implements _$$ChatObjectUploadResponseDtoImplCopyWith<$Res> {
  __$$ChatObjectUploadResponseDtoImplCopyWithImpl(
      _$ChatObjectUploadResponseDtoImpl _value,
      $Res Function(_$ChatObjectUploadResponseDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uploadUrl = null,
    Object? path = null,
  }) {
    return _then(_$ChatObjectUploadResponseDtoImpl(
      uploadUrl: null == uploadUrl
          ? _value.uploadUrl
          : uploadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatObjectUploadResponseDtoImpl
    implements _ChatObjectUploadResponseDto {
  const _$ChatObjectUploadResponseDtoImpl(
      {required this.uploadUrl, required this.path});

  factory _$ChatObjectUploadResponseDtoImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ChatObjectUploadResponseDtoImplFromJson(json);

  /// Pre-signed GCP Cloud Storage URL for direct upload (PUT request)
  @override
  final String uploadUrl;

  /// Storage path for referencing uploaded file
  /// Format: MESSAGE/{conversationId}/{timestamp}/{filename}
  @override
  final String path;

  @override
  String toString() {
    return 'ChatObjectUploadResponseDto(uploadUrl: $uploadUrl, path: $path)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatObjectUploadResponseDtoImpl &&
            (identical(other.uploadUrl, uploadUrl) ||
                other.uploadUrl == uploadUrl) &&
            (identical(other.path, path) || other.path == path));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, uploadUrl, path);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatObjectUploadResponseDtoImplCopyWith<_$ChatObjectUploadResponseDtoImpl>
      get copyWith => __$$ChatObjectUploadResponseDtoImplCopyWithImpl<
          _$ChatObjectUploadResponseDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatObjectUploadResponseDtoImplToJson(
      this,
    );
  }
}

abstract class _ChatObjectUploadResponseDto
    implements ChatObjectUploadResponseDto {
  const factory _ChatObjectUploadResponseDto(
      {required final String uploadUrl,
      required final String path}) = _$ChatObjectUploadResponseDtoImpl;

  factory _ChatObjectUploadResponseDto.fromJson(Map<String, dynamic> json) =
      _$ChatObjectUploadResponseDtoImpl.fromJson;

  @override

  /// Pre-signed GCP Cloud Storage URL for direct upload (PUT request)
  String get uploadUrl;
  @override

  /// Storage path for referencing uploaded file
  /// Format: MESSAGE/{conversationId}/{timestamp}/{filename}
  String get path;
  @override
  @JsonKey(ignore: true)
  _$$ChatObjectUploadResponseDtoImplCopyWith<_$ChatObjectUploadResponseDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ChatObjectGetUrlResponseDto _$ChatObjectGetUrlResponseDtoFromJson(
    Map<String, dynamic> json) {
  return _ChatObjectGetUrlResponseDto.fromJson(json);
}

/// @nodoc
mixin _$ChatObjectGetUrlResponseDto {
  /// Original storage path
  String get path => throw _privateConstructorUsedError;

  /// Firebase CDN download URL
  String get url => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChatObjectGetUrlResponseDtoCopyWith<ChatObjectGetUrlResponseDto>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatObjectGetUrlResponseDtoCopyWith<$Res> {
  factory $ChatObjectGetUrlResponseDtoCopyWith(
          ChatObjectGetUrlResponseDto value,
          $Res Function(ChatObjectGetUrlResponseDto) then) =
      _$ChatObjectGetUrlResponseDtoCopyWithImpl<$Res,
          ChatObjectGetUrlResponseDto>;
  @useResult
  $Res call({String path, String url});
}

/// @nodoc
class _$ChatObjectGetUrlResponseDtoCopyWithImpl<$Res,
        $Val extends ChatObjectGetUrlResponseDto>
    implements $ChatObjectGetUrlResponseDtoCopyWith<$Res> {
  _$ChatObjectGetUrlResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? url = null,
  }) {
    return _then(_value.copyWith(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatObjectGetUrlResponseDtoImplCopyWith<$Res>
    implements $ChatObjectGetUrlResponseDtoCopyWith<$Res> {
  factory _$$ChatObjectGetUrlResponseDtoImplCopyWith(
          _$ChatObjectGetUrlResponseDtoImpl value,
          $Res Function(_$ChatObjectGetUrlResponseDtoImpl) then) =
      __$$ChatObjectGetUrlResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String path, String url});
}

/// @nodoc
class __$$ChatObjectGetUrlResponseDtoImplCopyWithImpl<$Res>
    extends _$ChatObjectGetUrlResponseDtoCopyWithImpl<$Res,
        _$ChatObjectGetUrlResponseDtoImpl>
    implements _$$ChatObjectGetUrlResponseDtoImplCopyWith<$Res> {
  __$$ChatObjectGetUrlResponseDtoImplCopyWithImpl(
      _$ChatObjectGetUrlResponseDtoImpl _value,
      $Res Function(_$ChatObjectGetUrlResponseDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? url = null,
  }) {
    return _then(_$ChatObjectGetUrlResponseDtoImpl(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatObjectGetUrlResponseDtoImpl
    implements _ChatObjectGetUrlResponseDto {
  const _$ChatObjectGetUrlResponseDtoImpl(
      {required this.path, required this.url});

  factory _$ChatObjectGetUrlResponseDtoImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ChatObjectGetUrlResponseDtoImplFromJson(json);

  /// Original storage path
  @override
  final String path;

  /// Firebase CDN download URL
  @override
  final String url;

  @override
  String toString() {
    return 'ChatObjectGetUrlResponseDto(path: $path, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatObjectGetUrlResponseDtoImpl &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, path, url);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatObjectGetUrlResponseDtoImplCopyWith<_$ChatObjectGetUrlResponseDtoImpl>
      get copyWith => __$$ChatObjectGetUrlResponseDtoImplCopyWithImpl<
          _$ChatObjectGetUrlResponseDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatObjectGetUrlResponseDtoImplToJson(
      this,
    );
  }
}

abstract class _ChatObjectGetUrlResponseDto
    implements ChatObjectGetUrlResponseDto {
  const factory _ChatObjectGetUrlResponseDto(
      {required final String path,
      required final String url}) = _$ChatObjectGetUrlResponseDtoImpl;

  factory _ChatObjectGetUrlResponseDto.fromJson(Map<String, dynamic> json) =
      _$ChatObjectGetUrlResponseDtoImpl.fromJson;

  @override

  /// Original storage path
  String get path;
  @override

  /// Firebase CDN download URL
  String get url;
  @override
  @JsonKey(ignore: true)
  _$$ChatObjectGetUrlResponseDtoImplCopyWith<_$ChatObjectGetUrlResponseDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}
