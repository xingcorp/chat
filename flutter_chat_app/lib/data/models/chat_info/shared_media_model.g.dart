// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_media_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SharedMediaModelImpl _$$SharedMediaModelImplFromJson(
        Map<String, dynamic> json) =>
    _$SharedMediaModelImpl(
      id: json['id'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
    );

Map<String, dynamic> _$$SharedMediaModelImplToJson(
        _$SharedMediaModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'url': instance.url,
      'thumbnailUrl': instance.thumbnailUrl,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'createdAt': instance.createdAt.toIso8601String(),
      'senderId': instance.senderId,
      'senderName': instance.senderName,
    };
