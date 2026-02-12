import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/pagination/page_request.dart';
import 'package:flutter_chat_app/core/pagination/paged_result.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Get Conversations Use Case
///
/// Retrieves list of conversations for the current user.
/// Implements offline-first strategy through repository.
///
/// **Requirements**: 2.1, 2.16, 2.17, 2.18
@injectable
class GetConversationsUseCase {
  final IChatRepository _repository;
  final AppLogger _logger;

  const GetConversationsUseCase({
    required IChatRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// Execute use case to get conversations
  ///
  /// Returns Either<Failure, PagedResult<Chat>>
  /// - Left: Failure (NetworkFailure, ServerFailure, etc.)
  /// - Right: PagedResult of Chat entities
  Future<Either<Failure, PagedResult<Chat>>> call(PageRequest request) async {
    _logger.info('GetConversationsUseCase: Starting operation');

    try {
      final result = await _repository.getChatsPage(request);

      return result.fold(
        (failure) {
          _logger.error('GetConversationsUseCase: Failed', failure);
          return Left(failure);
        },
        (paged) {
          _logger.info('GetConversationsUseCase: Success', {
            'count': paged.items.length,
            'total': paged.total,
            'page': request.page,
            'size': request.size,
          });
          return Right(paged);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('GetConversationsUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
