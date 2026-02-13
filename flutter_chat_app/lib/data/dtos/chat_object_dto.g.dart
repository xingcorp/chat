// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_object_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PresignedUrlDataDtoImpl _$$PresignedUrlDataDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$PresignedUrlDataDtoImpl(
      id: json['id'] as String,
      presignedUrl: json['presignedUrl'] as String,
      path: json['path'] as String,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$$PresignedUrlDataDtoImplToJson(
        _$PresignedUrlDataDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'presignedUrl': instance.presignedUrl,
      'path': instance.path,
      'url': instance.url,
    };

_$StorageUploadResponseDtoImpl _$$StorageUploadResponseDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$StorageUploadResponseDtoImpl(
      data: (json['data'] as List<dynamic>)
          .map((e) => PresignedUrlDataDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$StorageUploadResponseDtoImplToJson(
        _$StorageUploadResponseDtoImpl instance) =>
    <String, dynamic>{
      'data': instance.data,
    };

_$ChatObjectGetUrlResponseDtoImpl _$$ChatObjectGetUrlResponseDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatObjectGetUrlResponseDtoImpl(
      path: json['path'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$$ChatObjectGetUrlResponseDtoImplToJson(
        _$ChatObjectGetUrlResponseDtoImpl instance) =>
    <String, dynamic>{
      'path': instance.path,
      'url': instance.url,
    };

_$ChatObjectUploadResponseDtoImpl _$$ChatObjectUploadResponseDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatObjectUploadResponseDtoImpl(
      uploadUrl: json['uploadUrl'] as String,
      path: json['path'] as String,
    );

Map<String, dynamic> _$$ChatObjectUploadResponseDtoImplToJson(
        _$ChatObjectUploadResponseDtoImpl instance) =>
    <String, dynamic>{
      'uploadUrl': instance.uploadUrl,
      'path': instance.path,
    };
