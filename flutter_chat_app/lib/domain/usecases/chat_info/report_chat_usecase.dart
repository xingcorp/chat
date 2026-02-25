import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_info_repository.dart';

/// UseCase để report chat/user
@injectable
class ReportChatUseCase {
  final IChatInfoRepository _repository;

  ReportChatUseCase(this._repository);

  /// Execute use case
  ///
  /// [chatId] - ID của chat
  /// [reason] - Lý do report
  Future<Either<Failure, void>> call({
    required String chatId,
    required String reason,
  }) async {
    return await _repository.reportChat(
      chatId: chatId,
      reason: reason,
    );
  }
}
