// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_object_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
