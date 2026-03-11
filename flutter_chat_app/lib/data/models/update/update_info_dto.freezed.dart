// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_info_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UpdateInfoDto _$UpdateInfoDtoFromJson(Map<String, dynamic> json) {
  return _UpdateInfoDto.fromJson(json);
}

/// @nodoc
mixin _$UpdateInfoDto {
  @JsonKey(name: 'version')
  String get version => throw _privateConstructorUsedError;
  @JsonKey(name: 'build_number')
  int get buildNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'release_notes')
  String get releaseNotes => throw _privateConstructorUsedError;
  @JsonKey(name: 'release_date')
  String get releaseDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'force_update')
  bool get forceUpdate => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_supported_version')
  String get minSupportedVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'html_url')
  String? get htmlUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'platforms')
  Map<String, PlatformUpdateDto> get platforms =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UpdateInfoDtoCopyWith<UpdateInfoDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateInfoDtoCopyWith<$Res> {
  factory $UpdateInfoDtoCopyWith(
          UpdateInfoDto value, $Res Function(UpdateInfoDto) then) =
      _$UpdateInfoDtoCopyWithImpl<$Res, UpdateInfoDto>;
  @useResult
  $Res call(
      {@JsonKey(name: 'version') String version,
      @JsonKey(name: 'build_number') int buildNumber,
      @JsonKey(name: 'release_notes') String releaseNotes,
      @JsonKey(name: 'release_date') String releaseDate,
      @JsonKey(name: 'force_update') bool forceUpdate,
      @JsonKey(name: 'min_supported_version') String minSupportedVersion,
      @JsonKey(name: 'html_url') String? htmlUrl,
      @JsonKey(name: 'platforms') Map<String, PlatformUpdateDto> platforms});
}

/// @nodoc
class _$UpdateInfoDtoCopyWithImpl<$Res, $Val extends UpdateInfoDto>
    implements $UpdateInfoDtoCopyWith<$Res> {
  _$UpdateInfoDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? buildNumber = null,
    Object? releaseNotes = null,
    Object? releaseDate = null,
    Object? forceUpdate = null,
    Object? minSupportedVersion = null,
    Object? htmlUrl = freezed,
    Object? platforms = null,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      buildNumber: null == buildNumber
          ? _value.buildNumber
          : buildNumber // ignore: cast_nullable_to_non_nullable
              as int,
      releaseNotes: null == releaseNotes
          ? _value.releaseNotes
          : releaseNotes // ignore: cast_nullable_to_non_nullable
              as String,
      releaseDate: null == releaseDate
          ? _value.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as String,
      forceUpdate: null == forceUpdate
          ? _value.forceUpdate
          : forceUpdate // ignore: cast_nullable_to_non_nullable
              as bool,
      minSupportedVersion: null == minSupportedVersion
          ? _value.minSupportedVersion
          : minSupportedVersion // ignore: cast_nullable_to_non_nullable
              as String,
      htmlUrl: freezed == htmlUrl
          ? _value.htmlUrl
          : htmlUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      platforms: null == platforms
          ? _value.platforms
          : platforms // ignore: cast_nullable_to_non_nullable
              as Map<String, PlatformUpdateDto>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UpdateInfoDtoImplCopyWith<$Res>
    implements $UpdateInfoDtoCopyWith<$Res> {
  factory _$$UpdateInfoDtoImplCopyWith(
          _$UpdateInfoDtoImpl value, $Res Function(_$UpdateInfoDtoImpl) then) =
      __$$UpdateInfoDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'version') String version,
      @JsonKey(name: 'build_number') int buildNumber,
      @JsonKey(name: 'release_notes') String releaseNotes,
      @JsonKey(name: 'release_date') String releaseDate,
      @JsonKey(name: 'force_update') bool forceUpdate,
      @JsonKey(name: 'min_supported_version') String minSupportedVersion,
      @JsonKey(name: 'html_url') String? htmlUrl,
      @JsonKey(name: 'platforms') Map<String, PlatformUpdateDto> platforms});
}

/// @nodoc
class __$$UpdateInfoDtoImplCopyWithImpl<$Res>
    extends _$UpdateInfoDtoCopyWithImpl<$Res, _$UpdateInfoDtoImpl>
    implements _$$UpdateInfoDtoImplCopyWith<$Res> {
  __$$UpdateInfoDtoImplCopyWithImpl(
      _$UpdateInfoDtoImpl _value, $Res Function(_$UpdateInfoDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? buildNumber = null,
    Object? releaseNotes = null,
    Object? releaseDate = null,
    Object? forceUpdate = null,
    Object? minSupportedVersion = null,
    Object? htmlUrl = freezed,
    Object? platforms = null,
  }) {
    return _then(_$UpdateInfoDtoImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      buildNumber: null == buildNumber
          ? _value.buildNumber
          : buildNumber // ignore: cast_nullable_to_non_nullable
              as int,
      releaseNotes: null == releaseNotes
          ? _value.releaseNotes
          : releaseNotes // ignore: cast_nullable_to_non_nullable
              as String,
      releaseDate: null == releaseDate
          ? _value.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as String,
      forceUpdate: null == forceUpdate
          ? _value.forceUpdate
          : forceUpdate // ignore: cast_nullable_to_non_nullable
              as bool,
      minSupportedVersion: null == minSupportedVersion
          ? _value.minSupportedVersion
          : minSupportedVersion // ignore: cast_nullable_to_non_nullable
              as String,
      htmlUrl: freezed == htmlUrl
          ? _value.htmlUrl
          : htmlUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      platforms: null == platforms
          ? _value._platforms
          : platforms // ignore: cast_nullable_to_non_nullable
              as Map<String, PlatformUpdateDto>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateInfoDtoImpl implements _UpdateInfoDto {
  const _$UpdateInfoDtoImpl(
      {@JsonKey(name: 'version') required this.version,
      @JsonKey(name: 'build_number') required this.buildNumber,
      @JsonKey(name: 'release_notes') this.releaseNotes = '',
      @JsonKey(name: 'release_date') required this.releaseDate,
      @JsonKey(name: 'force_update') this.forceUpdate = false,
      @JsonKey(name: 'min_supported_version')
      this.minSupportedVersion = '0.0.0',
      @JsonKey(name: 'html_url') this.htmlUrl,
      @JsonKey(name: 'platforms')
      required final Map<String, PlatformUpdateDto> platforms})
      : _platforms = platforms;

  factory _$UpdateInfoDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateInfoDtoImplFromJson(json);

  @override
  @JsonKey(name: 'version')
  final String version;
  @override
  @JsonKey(name: 'build_number')
  final int buildNumber;
  @override
  @JsonKey(name: 'release_notes')
  final String releaseNotes;
  @override
  @JsonKey(name: 'release_date')
  final String releaseDate;
  @override
  @JsonKey(name: 'force_update')
  final bool forceUpdate;
  @override
  @JsonKey(name: 'min_supported_version')
  final String minSupportedVersion;
  @override
  @JsonKey(name: 'html_url')
  final String? htmlUrl;
  final Map<String, PlatformUpdateDto> _platforms;
  @override
  @JsonKey(name: 'platforms')
  Map<String, PlatformUpdateDto> get platforms {
    if (_platforms is EqualUnmodifiableMapView) return _platforms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_platforms);
  }

  @override
  String toString() {
    return 'UpdateInfoDto(version: $version, buildNumber: $buildNumber, releaseNotes: $releaseNotes, releaseDate: $releaseDate, forceUpdate: $forceUpdate, minSupportedVersion: $minSupportedVersion, htmlUrl: $htmlUrl, platforms: $platforms)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateInfoDtoImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.buildNumber, buildNumber) ||
                other.buildNumber == buildNumber) &&
            (identical(other.releaseNotes, releaseNotes) ||
                other.releaseNotes == releaseNotes) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate) &&
            (identical(other.forceUpdate, forceUpdate) ||
                other.forceUpdate == forceUpdate) &&
            (identical(other.minSupportedVersion, minSupportedVersion) ||
                other.minSupportedVersion == minSupportedVersion) &&
            (identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl) &&
            const DeepCollectionEquality()
                .equals(other._platforms, _platforms));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      version,
      buildNumber,
      releaseNotes,
      releaseDate,
      forceUpdate,
      minSupportedVersion,
      htmlUrl,
      const DeepCollectionEquality().hash(_platforms));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateInfoDtoImplCopyWith<_$UpdateInfoDtoImpl> get copyWith =>
      __$$UpdateInfoDtoImplCopyWithImpl<_$UpdateInfoDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateInfoDtoImplToJson(
      this,
    );
  }
}

abstract class _UpdateInfoDto implements UpdateInfoDto {
  const factory _UpdateInfoDto(
      {@JsonKey(name: 'version') required final String version,
      @JsonKey(name: 'build_number') required final int buildNumber,
      @JsonKey(name: 'release_notes') final String releaseNotes,
      @JsonKey(name: 'release_date') required final String releaseDate,
      @JsonKey(name: 'force_update') final bool forceUpdate,
      @JsonKey(name: 'min_supported_version') final String minSupportedVersion,
      @JsonKey(name: 'html_url') final String? htmlUrl,
      @JsonKey(name: 'platforms')
      required final Map<String, PlatformUpdateDto>
          platforms}) = _$UpdateInfoDtoImpl;

  factory _UpdateInfoDto.fromJson(Map<String, dynamic> json) =
      _$UpdateInfoDtoImpl.fromJson;

  @override
  @JsonKey(name: 'version')
  String get version;
  @override
  @JsonKey(name: 'build_number')
  int get buildNumber;
  @override
  @JsonKey(name: 'release_notes')
  String get releaseNotes;
  @override
  @JsonKey(name: 'release_date')
  String get releaseDate;
  @override
  @JsonKey(name: 'force_update')
  bool get forceUpdate;
  @override
  @JsonKey(name: 'min_supported_version')
  String get minSupportedVersion;
  @override
  @JsonKey(name: 'html_url')
  String? get htmlUrl;
  @override
  @JsonKey(name: 'platforms')
  Map<String, PlatformUpdateDto> get platforms;
  @override
  @JsonKey(ignore: true)
  _$$UpdateInfoDtoImplCopyWith<_$UpdateInfoDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlatformUpdateDto _$PlatformUpdateDtoFromJson(Map<String, dynamic> json) {
  return _PlatformUpdateDto.fromJson(json);
}

/// @nodoc
mixin _$PlatformUpdateDto {
  @JsonKey(name: 'url')
  String get url => throw _privateConstructorUsedError;
  @JsonKey(name: 'size')
  int get size => throw _privateConstructorUsedError;
  @JsonKey(name: 'sha256')
  String get sha256 => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlatformUpdateDtoCopyWith<PlatformUpdateDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlatformUpdateDtoCopyWith<$Res> {
  factory $PlatformUpdateDtoCopyWith(
          PlatformUpdateDto value, $Res Function(PlatformUpdateDto) then) =
      _$PlatformUpdateDtoCopyWithImpl<$Res, PlatformUpdateDto>;
  @useResult
  $Res call(
      {@JsonKey(name: 'url') String url,
      @JsonKey(name: 'size') int size,
      @JsonKey(name: 'sha256') String sha256});
}

/// @nodoc
class _$PlatformUpdateDtoCopyWithImpl<$Res, $Val extends PlatformUpdateDto>
    implements $PlatformUpdateDtoCopyWith<$Res> {
  _$PlatformUpdateDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? size = null,
    Object? sha256 = null,
  }) {
    return _then(_value.copyWith(
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      sha256: null == sha256
          ? _value.sha256
          : sha256 // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlatformUpdateDtoImplCopyWith<$Res>
    implements $PlatformUpdateDtoCopyWith<$Res> {
  factory _$$PlatformUpdateDtoImplCopyWith(_$PlatformUpdateDtoImpl value,
          $Res Function(_$PlatformUpdateDtoImpl) then) =
      __$$PlatformUpdateDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'url') String url,
      @JsonKey(name: 'size') int size,
      @JsonKey(name: 'sha256') String sha256});
}

/// @nodoc
class __$$PlatformUpdateDtoImplCopyWithImpl<$Res>
    extends _$PlatformUpdateDtoCopyWithImpl<$Res, _$PlatformUpdateDtoImpl>
    implements _$$PlatformUpdateDtoImplCopyWith<$Res> {
  __$$PlatformUpdateDtoImplCopyWithImpl(_$PlatformUpdateDtoImpl _value,
      $Res Function(_$PlatformUpdateDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? size = null,
    Object? sha256 = null,
  }) {
    return _then(_$PlatformUpdateDtoImpl(
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      sha256: null == sha256
          ? _value.sha256
          : sha256 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlatformUpdateDtoImpl implements _PlatformUpdateDto {
  const _$PlatformUpdateDtoImpl(
      {@JsonKey(name: 'url') required this.url,
      @JsonKey(name: 'size') required this.size,
      @JsonKey(name: 'sha256') required this.sha256});

  factory _$PlatformUpdateDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlatformUpdateDtoImplFromJson(json);

  @override
  @JsonKey(name: 'url')
  final String url;
  @override
  @JsonKey(name: 'size')
  final int size;
  @override
  @JsonKey(name: 'sha256')
  final String sha256;

  @override
  String toString() {
    return 'PlatformUpdateDto(url: $url, size: $size, sha256: $sha256)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlatformUpdateDtoImpl &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.sha256, sha256) || other.sha256 == sha256));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, url, size, sha256);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlatformUpdateDtoImplCopyWith<_$PlatformUpdateDtoImpl> get copyWith =>
      __$$PlatformUpdateDtoImplCopyWithImpl<_$PlatformUpdateDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlatformUpdateDtoImplToJson(
      this,
    );
  }
}

abstract class _PlatformUpdateDto implements PlatformUpdateDto {
  const factory _PlatformUpdateDto(
          {@JsonKey(name: 'url') required final String url,
          @JsonKey(name: 'size') required final int size,
          @JsonKey(name: 'sha256') required final String sha256}) =
      _$PlatformUpdateDtoImpl;

  factory _PlatformUpdateDto.fromJson(Map<String, dynamic> json) =
      _$PlatformUpdateDtoImpl.fromJson;

  @override
  @JsonKey(name: 'url')
  String get url;
  @override
  @JsonKey(name: 'size')
  int get size;
  @override
  @JsonKey(name: 'sha256')
  String get sha256;
  @override
  @JsonKey(ignore: true)
  _$$PlatformUpdateDtoImplCopyWith<_$PlatformUpdateDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
