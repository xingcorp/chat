import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_info_repository.dart';

/// UseCase để lấy notification settings
@injectable
class GetNotificationSettingsUseCase {
  final IChatInfoRepository _repository;

  GetNotificationSettingsUseCase(this._repository);

  Future<Either<Failure, NotificationSettings>> call({
    required String chatId,
  }) async {
    return await _repository.getNotificationSettings(chatId: chatId);
  }
}
