// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_release_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GitHubReleaseDto _$GitHubReleaseDtoFromJson(Map<String, dynamic> json) {
  return _GitHubReleaseDto.fromJson(json);
}

/// @nodoc
mixin _$GitHubReleaseDto {
  @JsonKey(name: 'tag_name')
  String get tagName => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'body')
  String get body => throw _privateConstructorUsedError;
  @JsonKey(name: 'html_url')
  String get htmlUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'published_at')
  String get publishedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'prerelease')
  bool get prerelease => throw _privateConstructorUsedError;
  @JsonKey(name: 'draft')
  bool get draft => throw _privateConstructorUsedError;
  @JsonKey(name: 'assets')
  List<GitHubAssetDto> get assets => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GitHubReleaseDtoCopyWith<GitHubReleaseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GitHubReleaseDtoCopyWith<$Res> {
  factory $GitHubReleaseDtoCopyWith(
          GitHubReleaseDto value, $Res Function(GitHubReleaseDto) then) =
      _$GitHubReleaseDtoCopyWithImpl<$Res, GitHubReleaseDto>;
  @useResult
  $Res call(
      {@JsonKey(name: 'tag_name') String tagName,
      @JsonKey(name: 'name') String name,
      @JsonKey(name: 'body') String body,
      @JsonKey(name: 'html_url') String htmlUrl,
      @JsonKey(name: 'published_at') String publishedAt,
      @JsonKey(name: 'prerelease') bool prerelease,
      @JsonKey(name: 'draft') bool draft,
      @JsonKey(name: 'assets') List<GitHubAssetDto> assets});
}

/// @nodoc
class _$GitHubReleaseDtoCopyWithImpl<$Res, $Val extends GitHubReleaseDto>
    implements $GitHubReleaseDtoCopyWith<$Res> {
  _$GitHubReleaseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tagName = null,
    Object? name = null,
    Object? body = null,
    Object? htmlUrl = null,
    Object? publishedAt = null,
    Object? prerelease = null,
    Object? draft = null,
    Object? assets = null,
  }) {
    return _then(_value.copyWith(
      tagName: null == tagName
          ? _value.tagName
          : tagName // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      htmlUrl: null == htmlUrl
          ? _value.htmlUrl
          : htmlUrl // ignore: cast_nullable_to_non_nullable
              as String,
      publishedAt: null == publishedAt
          ? _value.publishedAt
          : publishedAt // ignore: cast_nullable_to_non_nullable
              as String,
      prerelease: null == prerelease
          ? _value.prerelease
          : prerelease // ignore: cast_nullable_to_non_nullable
              as bool,
      draft: null == draft
          ? _value.draft
          : draft // ignore: cast_nullable_to_non_nullable
              as bool,
      assets: null == assets
          ? _value.assets
          : assets // ignore: cast_nullable_to_non_nullable
              as List<GitHubAssetDto>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GitHubReleaseDtoImplCopyWith<$Res>
    implements $GitHubReleaseDtoCopyWith<$Res> {
  factory _$$GitHubReleaseDtoImplCopyWith(_$GitHubReleaseDtoImpl value,
          $Res Function(_$GitHubReleaseDtoImpl) then) =
      __$$GitHubReleaseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'tag_name') String tagName,
      @JsonKey(name: 'name') String name,
      @JsonKey(name: 'body') String body,
      @JsonKey(name: 'html_url') String htmlUrl,
      @JsonKey(name: 'published_at') String publishedAt,
      @JsonKey(name: 'prerelease') bool prerelease,
      @JsonKey(name: 'draft') bool draft,
      @JsonKey(name: 'assets') List<GitHubAssetDto> assets});
}

/// @nodoc
class __$$GitHubReleaseDtoImplCopyWithImpl<$Res>
    extends _$GitHubReleaseDtoCopyWithImpl<$Res, _$GitHubReleaseDtoImpl>
    implements _$$GitHubReleaseDtoImplCopyWith<$Res> {
  __$$GitHubReleaseDtoImplCopyWithImpl(_$GitHubReleaseDtoImpl _value,
      $Res Function(_$GitHubReleaseDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tagName = null,
    Object? name = null,
    Object? body = null,
    Object? htmlUrl = null,
    Object? publishedAt = null,
    Object? prerelease = null,
    Object? draft = null,
    Object? assets = null,
  }) {
    return _then(_$GitHubReleaseDtoImpl(
      tagName: null == tagName
          ? _value.tagName
          : tagName // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      htmlUrl: null == htmlUrl
          ? _value.htmlUrl
          : htmlUrl // ignore: cast_nullable_to_non_nullable
              as String,
      publishedAt: null == publishedAt
          ? _value.publishedAt
          : publishedAt // ignore: cast_nullable_to_non_nullable
              as String,
      prerelease: null == prerelease
          ? _value.prerelease
          : prerelease // ignore: cast_nullable_to_non_nullable
              as bool,
      draft: null == draft
          ? _value.draft
          : draft // ignore: cast_nullable_to_non_nullable
              as bool,
      assets: null == assets
          ? _value._assets
          : assets // ignore: cast_nullable_to_non_nullable
              as List<GitHubAssetDto>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GitHubReleaseDtoImpl implements _GitHubReleaseDto {
  const _$GitHubReleaseDtoImpl(
      {@JsonKey(name: 'tag_name') required this.tagName,
      @JsonKey(name: 'name') required this.name,
      @JsonKey(name: 'body') this.body = '',
      @JsonKey(name: 'html_url') required this.htmlUrl,
      @JsonKey(name: 'published_at') required this.publishedAt,
      @JsonKey(name: 'prerelease') this.prerelease = false,
      @JsonKey(name: 'draft') this.draft = false,
      @JsonKey(name: 'assets') final List<GitHubAssetDto> assets = const []})
      : _assets = assets;

  factory _$GitHubReleaseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GitHubReleaseDtoImplFromJson(json);

  @override
  @JsonKey(name: 'tag_name')
  final String tagName;
  @override
  @JsonKey(name: 'name')
  final String name;
  @override
  @JsonKey(name: 'body')
  final String body;
  @override
  @JsonKey(name: 'html_url')
  final String htmlUrl;
  @override
  @JsonKey(name: 'published_at')
  final String publishedAt;
  @override
  @JsonKey(name: 'prerelease')
  final bool prerelease;
  @override
  @JsonKey(name: 'draft')
  final bool draft;
  final List<GitHubAssetDto> _assets;
  @override
  @JsonKey(name: 'assets')
  List<GitHubAssetDto> get assets {
    if (_assets is EqualUnmodifiableListView) return _assets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assets);
  }

  @override
  String toString() {
    return 'GitHubReleaseDto(tagName: $tagName, name: $name, body: $body, htmlUrl: $htmlUrl, publishedAt: $publishedAt, prerelease: $prerelease, draft: $draft, assets: $assets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GitHubReleaseDtoImpl &&
            (identical(other.tagName, tagName) || other.tagName == tagName) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt) &&
            (identical(other.prerelease, prerelease) ||
                other.prerelease == prerelease) &&
            (identical(other.draft, draft) || other.draft == draft) &&
            const DeepCollectionEquality().equals(other._assets, _assets));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      tagName,
      name,
      body,
      htmlUrl,
      publishedAt,
      prerelease,
      draft,
      const DeepCollectionEquality().hash(_assets));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GitHubReleaseDtoImplCopyWith<_$GitHubReleaseDtoImpl> get copyWith =>
      __$$GitHubReleaseDtoImplCopyWithImpl<_$GitHubReleaseDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GitHubReleaseDtoImplToJson(
      this,
    );
  }
}

abstract class _GitHubReleaseDto implements GitHubReleaseDto {
  const factory _GitHubReleaseDto(
          {@JsonKey(name: 'tag_name') required final String tagName,
          @JsonKey(name: 'name') required final String name,
          @JsonKey(name: 'body') final String body,
          @JsonKey(name: 'html_url') required final String htmlUrl,
          @JsonKey(name: 'published_at') required final String publishedAt,
          @JsonKey(name: 'prerelease') final bool prerelease,
          @JsonKey(name: 'draft') final bool draft,
          @JsonKey(name: 'assets') final List<GitHubAssetDto> assets}) =
      _$GitHubReleaseDtoImpl;

  factory _GitHubReleaseDto.fromJson(Map<String, dynamic> json) =
      _$GitHubReleaseDtoImpl.fromJson;

  @override
  @JsonKey(name: 'tag_name')
  String get tagName;
  @override
  @JsonKey(name: 'name')
  String get name;
  @override
  @JsonKey(name: 'body')
  String get body;
  @override
  @JsonKey(name: 'html_url')
  String get htmlUrl;
  @override
  @JsonKey(name: 'published_at')
  String get publishedAt;
  @override
  @JsonKey(name: 'prerelease')
  bool get prerelease;
  @override
  @JsonKey(name: 'draft')
  bool get draft;
  @override
  @JsonKey(name: 'assets')
  List<GitHubAssetDto> get assets;
  @override
  @JsonKey(ignore: true)
  _$$GitHubReleaseDtoImplCopyWith<_$GitHubReleaseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GitHubAssetDto _$GitHubAssetDtoFromJson(Map<String, dynamic> json) {
  return _GitHubAssetDto.fromJson(json);
}

/// @nodoc
mixin _$GitHubAssetDto {
  @JsonKey(name: 'name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'size')
  int get size => throw _privateConstructorUsedError;
  @JsonKey(name: 'browser_download_url')
  String get browserDownloadUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'content_type')
  String get contentType => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GitHubAssetDtoCopyWith<GitHubAssetDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GitHubAssetDtoCopyWith<$Res> {
  factory $GitHubAssetDtoCopyWith(
          GitHubAssetDto value, $Res Function(GitHubAssetDto) then) =
      _$GitHubAssetDtoCopyWithImpl<$Res, GitHubAssetDto>;
  @useResult
  $Res call(
      {@JsonKey(name: 'name') String name,
      @JsonKey(name: 'size') int size,
      @JsonKey(name: 'browser_download_url') String browserDownloadUrl,
      @JsonKey(name: 'content_type') String contentType});
}

/// @nodoc
class _$GitHubAssetDtoCopyWithImpl<$Res, $Val extends GitHubAssetDto>
    implements $GitHubAssetDtoCopyWith<$Res> {
  _$GitHubAssetDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? size = null,
    Object? browserDownloadUrl = null,
    Object? contentType = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      browserDownloadUrl: null == browserDownloadUrl
          ? _value.browserDownloadUrl
          : browserDownloadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      contentType: null == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GitHubAssetDtoImplCopyWith<$Res>
    implements $GitHubAssetDtoCopyWith<$Res> {
  factory _$$GitHubAssetDtoImplCopyWith(_$GitHubAssetDtoImpl value,
          $Res Function(_$GitHubAssetDtoImpl) then) =
      __$$GitHubAssetDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'name') String name,
      @JsonKey(name: 'size') int size,
      @JsonKey(name: 'browser_download_url') String browserDownloadUrl,
      @JsonKey(name: 'content_type') String contentType});
}

/// @nodoc
class __$$GitHubAssetDtoImplCopyWithImpl<$Res>
    extends _$GitHubAssetDtoCopyWithImpl<$Res, _$GitHubAssetDtoImpl>
    implements _$$GitHubAssetDtoImplCopyWith<$Res> {
  __$$GitHubAssetDtoImplCopyWithImpl(
      _$GitHubAssetDtoImpl _value, $Res Function(_$GitHubAssetDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? size = null,
    Object? browserDownloadUrl = null,
    Object? contentType = null,
  }) {
    return _then(_$GitHubAssetDtoImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      browserDownloadUrl: null == browserDownloadUrl
          ? _value.browserDownloadUrl
          : browserDownloadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      contentType: null == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GitHubAssetDtoImpl implements _GitHubAssetDto {
  const _$GitHubAssetDtoImpl(
      {@JsonKey(name: 'name') required this.name,
      @JsonKey(name: 'size') required this.size,
      @JsonKey(name: 'browser_download_url') required this.browserDownloadUrl,
      @JsonKey(name: 'content_type') this.contentType = ''});

  factory _$GitHubAssetDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GitHubAssetDtoImplFromJson(json);

  @override
  @JsonKey(name: 'name')
  final String name;
  @override
  @JsonKey(name: 'size')
  final int size;
  @override
  @JsonKey(name: 'browser_download_url')
  final String browserDownloadUrl;
  @override
  @JsonKey(name: 'content_type')
  final String contentType;

  @override
  String toString() {
    return 'GitHubAssetDto(name: $name, size: $size, browserDownloadUrl: $browserDownloadUrl, contentType: $contentType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GitHubAssetDtoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.browserDownloadUrl, browserDownloadUrl) ||
                other.browserDownloadUrl == browserDownloadUrl) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, size, browserDownloadUrl, contentType);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GitHubAssetDtoImplCopyWith<_$GitHubAssetDtoImpl> get copyWith =>
      __$$GitHubAssetDtoImplCopyWithImpl<_$GitHubAssetDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GitHubAssetDtoImplToJson(
      this,
    );
  }
}

abstract class _GitHubAssetDto implements GitHubAssetDto {
  const factory _GitHubAssetDto(
          {@JsonKey(name: 'name') required final String name,
          @JsonKey(name: 'size') required final int size,
          @JsonKey(name: 'browser_download_url')
          required final String browserDownloadUrl,
          @JsonKey(name: 'content_type') final String contentType}) =
      _$GitHubAssetDtoImpl;

  factory _GitHubAssetDto.fromJson(Map<String, dynamic> json) =
      _$GitHubAssetDtoImpl.fromJson;

  @override
  @JsonKey(name: 'name')
  String get name;
  @override
  @JsonKey(name: 'size')
  int get size;
  @override
  @JsonKey(name: 'browser_download_url')
  String get browserDownloadUrl;
  @override
  @JsonKey(name: 'content_type')
  String get contentType;
  @override
  @JsonKey(ignore: true)
  _$$GitHubAssetDtoImplCopyWith<_$GitHubAssetDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
