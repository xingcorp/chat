import 'package:freezed_annotation/freezed_annotation.dart';

part 'github_release_dto.freezed.dart';
part 'github_release_dto.g.dart';

/// DTO mapping the GitHub Releases API response.
@freezed
class GitHubReleaseDto with _$GitHubReleaseDto {
  const factory GitHubReleaseDto({
    @JsonKey(name: 'tag_name') required String tagName,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'body') @Default('') String body,
    @JsonKey(name: 'html_url') required String htmlUrl,
    @JsonKey(name: 'published_at') required String publishedAt,
    @JsonKey(name: 'prerelease') @Default(false) bool prerelease,
    @JsonKey(name: 'draft') @Default(false) bool draft,
    @JsonKey(name: 'assets') @Default([]) List<GitHubAssetDto> assets,
  }) = _GitHubReleaseDto;

  factory GitHubReleaseDto.fromJson(Map<String, dynamic> json) =>
      _$GitHubReleaseDtoFromJson(json);
}

/// DTO for a single GitHub Release asset.
@freezed
class GitHubAssetDto with _$GitHubAssetDto {
  const factory GitHubAssetDto({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'size') required int size,
    @JsonKey(name: 'browser_download_url') required String browserDownloadUrl,
    @JsonKey(name: 'content_type') @Default('') String contentType,
  }) = _GitHubAssetDto;

  factory GitHubAssetDto.fromJson(Map<String, dynamic> json) =>
      _$GitHubAssetDtoFromJson(json);
}
