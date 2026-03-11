// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_info_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UpdateInfoDtoImpl _$$UpdateInfoDtoImplFromJson(Map<String, dynamic> json) =>
    _$UpdateInfoDtoImpl(
      version: json['version'] as String,
      buildNumber: (json['build_number'] as num).toInt(),
      releaseNotes: json['release_notes'] as String? ?? '',
      releaseDate: json['release_date'] as String,
      forceUpdate: json['force_update'] as bool? ?? false,
      minSupportedVersion: json['min_supported_version'] as String? ?? '0.0.0',
      htmlUrl: json['html_url'] as String?,
      platforms: (json['platforms'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, PlatformUpdateDto.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$$UpdateInfoDtoImplToJson(_$UpdateInfoDtoImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'build_number': instance.buildNumber,
      'release_notes': instance.releaseNotes,
      'release_date': instance.releaseDate,
      'force_update': instance.forceUpdate,
      'min_supported_version': instance.minSupportedVersion,
      'html_url': instance.htmlUrl,
      'platforms': instance.platforms,
    };

_$PlatformUpdateDtoImpl _$$PlatformUpdateDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$PlatformUpdateDtoImpl(
      url: json['url'] as String,
      size: (json['size'] as num).toInt(),
      sha256: json['sha256'] as String,
    );

Map<String, dynamic> _$$PlatformUpdateDtoImplToJson(
        _$PlatformUpdateDtoImpl instance) =>
    <String, dynamic>{
      'url': instance.url,
      'size': instance.size,
      'sha256': instance.sha256,
    };
