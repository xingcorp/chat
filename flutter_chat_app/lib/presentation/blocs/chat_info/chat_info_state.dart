import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_state.dart';

/// States cho Chat Info BLoC
/// TUÂN THỦ: PHẢI extend BaseState thông qua ChatInfoState

/// Abstract base state cho Chat Info
abstract class ChatInfoState extends BaseState {
  const ChatInfoState();
}

/// Initial state
class ChatInfoInitial extends ChatInfoState {
  const ChatInfoInitial();

  @override
  List<Object?> get props => [];
}

/// Loading state - Inherit từ ChatInfoState (vẫn sử dụng BaseLoading behavior)
class ChatInfoLoading extends ChatInfoState {
  final String? message;

  const ChatInfoLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// State khi load shared media thành công
class ChatInfoSharedMediaLoaded extends ChatInfoState {
  final List<SharedMedia> media;
  final SharedMediaType type;

  const ChatInfoSharedMediaLoaded({
    required this.media,
    required this.type,
  });

  @override
  List<Object?> get props => [media, type];
}

/// State khi load notification settings thành công
class ChatInfoNotificationSettingsLoaded extends ChatInfoState {
  final NotificationSettings settings;

  const ChatInfoNotificationSettingsLoaded({required this.settings});

  @override
  List<Object?> get props => [settings];
}

/// State khi update notification settings thành công
class ChatInfoNotificationSettingsUpdated extends ChatInfoState {
  final NotificationSettings settings;

  const ChatInfoNotificationSettingsUpdated({required this.settings});

  @override
  List<Object?> get props => [settings];
}

/// State khi user bị block
class ChatInfoUserBlocked extends ChatInfoState {
  final String userId;

  const ChatInfoUserBlocked({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// State khi user được unblock
class ChatInfoUserUnblocked extends ChatInfoState {
  final String userId;

  const ChatInfoUserUnblocked({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// State khi check block status
class ChatInfoUserBlockStatusChecked extends ChatInfoState {
  final String userId;
  final bool isBlocked;

  const ChatInfoUserBlockStatusChecked({
    required this.userId,
    required this.isBlocked,
  });

  @override
  List<Object?> get props => [userId, isBlocked];
}

/// State khi report chat thành công
class ChatInfoChatReported extends ChatInfoState {
  const ChatInfoChatReported();

  @override
  List<Object?> get props => [];
}

/// State khi có error - Inherit từ ChatInfoState
class ChatInfoError extends ChatInfoState {
  final String message;
  final Object? error;
  final ErrorType type;
  final bool shouldRetry;

  const ChatInfoError({
    required this.message,
    this.error,
    this.type = ErrorType.general,
    this.shouldRetry = false,
  });

  @override
  List<Object?> get props => [message, error, type, shouldRetry];
}
