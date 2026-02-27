import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_conversation_detail_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/conversation_detail/conversation_detail_event.dart';
import 'package:flutter_chat_app/presentation/blocs/conversation_detail/conversation_detail_state.dart';

/// BLoC for conversation detail management (metadata, members, add member).
///
/// Extracted from MessageBloc to follow Single Responsibility Principle.
/// MessageBloc handles messages only; this BLoC handles conversation metadata.
@injectable
class ConversationDetailBloc
    extends BaseBloc<ConversationDetailEvent, ConversationDetailState> {
  final GetConversationDetailUseCase _getConversationDetail;
  final IChatRepository _chatRepository;
  final AppLogger _logger;

  ConversationDetailBloc({
    required GetConversationDetailUseCase getConversationDetail,
    required IChatRepository chatRepository,
    required AppLogger logger,
  })  : _getConversationDetail = getConversationDetail,
        _chatRepository = chatRepository,
        _logger = logger,
        super(const ConversationDetailInitial()) {
    on<LoadConversationDetail>(_onLoadConversationDetail);
    on<AddMembersToGroup>(_onAddMembersToGroup);
  }

  /// Load conversation detail — fetches fresh data via use case
  Future<void> _onLoadConversationDetail(
    LoadConversationDetail event,
    Emitter<ConversationDetailState> emit,
  ) async {
    _logger.i('[ConvDetail] Loading conversation detail: chatId=${event.chatId}');

    final result = await _getConversationDetail(event.chatId);

    result.fold(
      (failure) {
        _logger.e('[ConvDetail] Failed to load conversation detail',
            error: failure);
        emit(ConversationDetailError(
          message: failure.message,
          error: failure,
        ));
      },
      (chat) {
        if (chat == null) {
          _logger.w('[ConvDetail] Use case returned null for chatId=${event.chatId}');
          return;
        }

        _logger.i(
            '[ConvDetail] Loaded: name=${chat.name} members=${chat.members.length}');
        emit(ConversationDetailLoaded(chat: chat));
      },
    );
  }

  /// Add members to group — calls repository, then fetches fresh detail
  Future<void> _onAddMembersToGroup(
    AddMembersToGroup event,
    Emitter<ConversationDetailState> emit,
  ) async {
    _logger.i(
        '[ConvDetail] Adding ${event.userIds.length} members to chat: ${event.chatId}');

    emit(const ConversationDetailLoading(message: 'Adding members...'));

    // Step 1: Add members via repository
    final addResult = await _chatRepository.addParticipants(
      chatId: event.chatId,
      userIds: event.userIds,
    );

    final failed = addResult.fold(
      (failure) {
        _logger.e('[ConvDetail] Failed to add members', error: failure);
        emit(ConversationDetailError(
          message: failure.message,
          error: failure,
        ));
        return true;
      },
      (_) => false,
    );

    if (failed) return;

    // Step 2: Fetch fresh conversation detail after adding members
    final detailResult = await _getConversationDetail(event.chatId);

    detailResult.fold(
      (failure) {
        // Members were added successfully but detail refresh failed.
        // Emit error so UI can inform user to refresh manually.
        _logger.e('[ConvDetail] Members added but detail refresh failed',
            error: failure);
        emit(ConversationDetailError(
          message: failure.message,
          error: failure,
        ));
      },
      (chat) {
        if (chat == null) {
          _logger.w('[ConvDetail] Detail returned null after adding members');
          return;
        }

        _logger.i(
            '[ConvDetail] Members added, refreshed detail: members=${chat.members.length}');

        // Emit transient state for listener (close panel, show success)
        emit(ConversationDetailMembersAdded(chat: chat));
        // Emit persistent state for builder (update UI)
        emit(ConversationDetailLoaded(chat: chat));
      },
    );
  }
}
