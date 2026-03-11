// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_release_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GitHubReleaseDtoImpl _$$GitHubReleaseDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$GitHubReleaseDtoImpl(
      tagName: json['tag_name'] as String,
      name: json['name'] as String,
      body: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String,
      publishedAt: json['published_at'] as String,
      prerelease: json['prerelease'] as bool? ?? false,
      draft: json['draft'] as bool? ?? false,
      assets: (json['assets'] as List<dynamic>?)
              ?.map((e) => GitHubAssetDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$GitHubReleaseDtoImplToJson(
        _$GitHubReleaseDtoImpl instance) =>
    <String, dynamic>{
      'tag_name': instance.tagName,
      'name': instance.name,
      'body': instance.body,
      'html_url': instance.htmlUrl,
      'published_at': instance.publishedAt,
      'prerelease': instance.prerelease,
      'draft': instance.draft,
      'assets': instance.assets,
    };

_$GitHubAssetDtoImpl _$$GitHubAssetDtoImplFromJson(Map<String, dynamic> json) =>
    _$GitHubAssetDtoImpl(
      name: json['name'] as String,
      size: (json['size'] as num).toInt(),
      browserDownloadUrl: json['browser_download_url'] as String,
      contentType: json['content_type'] as String? ?? '',
    );

Map<String, dynamic> _$$GitHubAssetDtoImplToJson(
        _$GitHubAssetDtoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'size': instance.size,
      'browser_download_url': instance.browserDownloadUrl,
      'content_type': instance.contentType,
    };
