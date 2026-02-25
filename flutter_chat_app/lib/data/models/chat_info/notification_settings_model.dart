import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';

part 'notification_settings_model.freezed.dart';
part 'notification_settings_model.g.dart';

/// Model cho notification settings (Data layer)
@freezed
class NotificationSettingsModel with _$NotificationSettingsModel {
  const factory NotificationSettingsModel({
    required String chatId,
    required bool isMuted,
    DateTime? mutedUntil,
    @Default(false) bool mentionOnly,
  }) = _NotificationSettingsModel;

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsModelFromJson(json);

  const NotificationSettingsModel._();

  /// Convert model sang domain entity
  NotificationSettings toEntity() {
    return NotificationSettings(
      chatId: chatId,
      isMuted: isMuted,
      mutedUntil: mutedUntil,
      mentionOnly: mentionOnly,
    );
  }

  /// Convert từ entity sang model
  static NotificationSettingsModel fromEntity(NotificationSettings entity) {
    return NotificationSettingsModel(
      chatId: entity.chatId,
      isMuted: entity.isMuted,
      mutedUntil: entity.mutedUntil,
      mentionOnly: entity.mentionOnly,
    );
  }
}
