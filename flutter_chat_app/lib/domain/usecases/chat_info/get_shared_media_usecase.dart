import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_info_repository.dart';

/// UseCase để lấy shared media trong chat
/// Tuân thủ Clean Architecture - Single Responsibility
@injectable
class GetSharedMediaUseCase {
  final IChatInfoRepository _repository;

  GetSharedMediaUseCase(this._repository);

  /// Execute use case
  ///
  /// [chatId] - ID của chat
  /// [type] - Loại media (photo, video, file, link)
  /// [limit] - Giới hạn số lượng (optional)
  /// [offset] - Offset cho pagination (optional)
  Future<Either<Failure, List<SharedMedia>>> call({
    required String chatId,
    required SharedMediaType type,
    int? limit,
    int? offset,
  }) async {
    return await _repository.getSharedMedia(
      chatId: chatId,
      type: type,
      limit: limit,
      offset: offset,
    );
  }
}
