import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/features/chat/data/datasources/chat/chat_local_datasource.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:injectable/injectable.dart';

/// Parameters for [PersistIncomingMessageUseCase]
class PersistIncomingMessageParams {
  final ChatMessage message;
  final Chat updatedChat;

  const PersistIncomingMessageParams({
    required this.message,
    required this.updatedChat,
  });
}

/// Persists an incoming real-time message and updated chat to local storage (Isar).
///
/// Called fire-and-forget from ChatBloc._onNewMessageReceived to ensure
/// local cache stays in sync with real-time state without blocking UI.
///
/// Uses [ChatLocalDataSource.saveMessage] which saves the message to Isar
/// and updates the chat preview. Then [saveChat] persists the BLoC-computed
/// preview with correct unreadCount.
@injectable
class PersistIncomingMessageUseCase {
  final ChatLocalDataSource _localDataSource;
  final AppLogger _logger;

  const PersistIncomingMessageUseCase({
    required ChatLocalDataSource localDataSource,
    required AppLogger logger,
  })  : _localDataSource = localDataSource,
        _logger = logger;

  Future<Either<Failure, void>> call(PersistIncomingMessageParams params) async {
    try {
      _logger.d('PersistIncomingMessage: Saving message ${params.message.id} '
          'for chat ${params.updatedChat.id}');

      // 1. Save message to Isar DB
      await _localDataSource.saveMessage(
        params.updatedChat.id,
        params.message,
      );

      // 2. Save updated chat with BLoC-computed preview, unreadCount, lastMessageTime
      // This overwrites the preview set by saveMessage() with the richer
      // BLoC-formatted preview (mention resolution, media labels, etc.)
      await _localDataSource.saveChat(params.updatedChat);

      _logger.d('PersistIncomingMessage: Success');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.error('PersistIncomingMessage: Failed to persist', e, stackTrace);
      return Left(CacheFailure(message: 'Failed to persist incoming message: $e'));
    }
  }
}
