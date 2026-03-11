import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_info_dto.freezed.dart';
part 'update_info_dto.g.dart';

/// DTO for the fallback JSON endpoint format:
/// ```json
/// {
///   "version": "2.1.0",
///   "build_number": 92,
///   "release_notes": "## What's New\n- ...",
///   "release_date": "2026-03-10T12:00:00Z",
///   "force_update": false,
///   "min_supported_version": "1.8.0",
///   "platforms": {
///     "windows": { "url": "...", "size": 52428800, "sha256": "abc123..." },
///     "macos":   { "url": "...", "size": 67108864, "sha256": "def456..." }
///   }
/// }
/// ```
@freezed
class UpdateInfoDto with _$UpdateInfoDto {
  const factory UpdateInfoDto({
    @JsonKey(name: 'version') required String version,
    @JsonKey(name: 'build_number') required int buildNumber,
    @JsonKey(name: 'release_notes') @Default('') String releaseNotes,
    @JsonKey(name: 'release_date') required String releaseDate,
    @JsonKey(name: 'force_update') @Default(false) bool forceUpdate,
    @JsonKey(name: 'min_supported_version') @Default('0.0.0') String minSupportedVersion,
    @JsonKey(name: 'html_url') String? htmlUrl,
    @JsonKey(name: 'platforms') required Map<String, PlatformUpdateDto> platforms,
  }) = _UpdateInfoDto;

  factory UpdateInfoDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateInfoDtoFromJson(json);
}

/// Platform-specific download info within [UpdateInfoDto].
@freezed
class PlatformUpdateDto with _$PlatformUpdateDto {
  const factory PlatformUpdateDto({
    @JsonKey(name: 'url') required String url,
    @JsonKey(name: 'size') required int size,
    @JsonKey(name: 'sha256') required String sha256,
  }) = _PlatformUpdateDto;

  factory PlatformUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$PlatformUpdateDtoFromJson(json);
}
