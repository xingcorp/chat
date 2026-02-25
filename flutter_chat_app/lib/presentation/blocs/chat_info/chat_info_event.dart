import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';

part 'chat_info_event.freezed.dart';

/// Events cho Chat Info BLoC
@freezed
class ChatInfoEvent with _$ChatInfoEvent {
  /// Load shared media theo type
  const factory ChatInfoEvent.loadSharedMedia({
    required String chatId,
    required SharedMediaType type,
    int? limit,
    int? offset,
  }) = ChatInfoLoadSharedMedia;

  /// Load notification settings
  const factory ChatInfoEvent.loadNotificationSettings({
    required String chatId,
  }) = ChatInfoLoadNotificationSettings;

  /// Update notification settings
  const factory ChatInfoEvent.updateNotificationSettings({
    required NotificationSettings settings,
  }) = ChatInfoUpdateNotificationSettings;

  /// Mute notifications với duration
  const factory ChatInfoEvent.muteNotifications({
    required String chatId,
    required MuteDuration duration,
  }) = ChatInfoMuteNotifications;

  /// Unmute notifications
  const factory ChatInfoEvent.unmuteNotifications({
    required String chatId,
  }) = ChatInfoUnmuteNotifications;

  /// Block user (direct chat only)
  const factory ChatInfoEvent.blockUser({
    required String userId,
  }) = ChatInfoBlockUser;

  /// Unblock user
  const factory ChatInfoEvent.unblockUser({
    required String userId,
  }) = ChatInfoUnblockUser;

  /// Check if user is blocked
  const factory ChatInfoEvent.checkUserBlocked({
    required String userId,
  }) = ChatInfoCheckUserBlocked;

  /// Report chat/user
  const factory ChatInfoEvent.reportChat({
    required String chatId,
    required String reason,
  }) = ChatInfoReportChat;
}
