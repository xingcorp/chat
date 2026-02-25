import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_info_repository.dart';

/// UseCase để cập nhật notification settings
@injectable
class UpdateNotificationSettingsUseCase {
  final IChatInfoRepository _repository;

  UpdateNotificationSettingsUseCase(this._repository);

  /// Execute use case
  ///
  /// [chatId] - ID của chat
  /// [settings] - Settings mới cần cập nhật
  Future<Either<Failure, NotificationSettings>> call({
    required String chatId,
    required NotificationSettings settings,
  }) async {
    return await _repository.updateNotificationSettings(
      chatId: chatId,
      settings: settings,
    );
  }
}
