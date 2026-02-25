// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationSettingsModelImpl _$$NotificationSettingsModelImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationSettingsModelImpl(
      chatId: json['chatId'] as String,
      isMuted: json['isMuted'] as bool,
      mutedUntil: json['mutedUntil'] == null
          ? null
          : DateTime.parse(json['mutedUntil'] as String),
      mentionOnly: json['mentionOnly'] as bool? ?? false,
    );

Map<String, dynamic> _$$NotificationSettingsModelImplToJson(
        _$NotificationSettingsModelImpl instance) =>
    <String, dynamic>{
      'chatId': instance.chatId,
      'isMuted': instance.isMuted,
      'mutedUntil': instance.mutedUntil?.toIso8601String(),
      'mentionOnly': instance.mentionOnly,
    };
