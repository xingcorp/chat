import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/network/models/socket_connection_state.dart';
import 'package:flutter_chat_app/core/services/frequent_reaction_service.dart';
import 'package:flutter_chat_app/core/services/location_service.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart'
    hide MessageReaction;
import 'package:flutter_chat_app/core/services/voice_note_playback_manager.dart';
import 'package:flutter_chat_app/core/storage/tombstone_store.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/managers/sync_metadata_manager.dart';
import 'package:flutter_chat_app/data/strategies/gap_detection_logic.dart';
import 'package:flutter_chat_app/domain/repositories/i_attachment_repository.dart';
import 'package:flutter_chat_app/domain/usecases/message/add_reaction_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/delete_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/edit_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/get_messages_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/mark_as_read_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/remove_reaction_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/send_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/notification/send_push_notification_usecase.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_list_transformer.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_state.dart';
import 'package:flutter_chat_app/presentation/blocs/message/socket_event_buffer.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

part 'message_event.dart';
part 'message_state.dart';
part 'message_bloc.freezed.dart';

/// **ENTERPRISE MESSAGE BLOC - CLEAN ARCHITECTURE**
///
/// Updated to use UseCases and proper dependency injection.
/// Follows Clean Architecture with proper separation of concerns.
///
/// **Performance Targets:**
/// - State updates: <50ms
/// - Error handling: Comprehensive with user-friendly messages
/// - Real-time updates: <100ms delivery
@injectable
class MessageBloc extends BaseBloc<MessageEvent, MessageState> {
  // UseCases (Domain Layer)
  final GetMessagesUseCase _getMessages;
  final SendMessageUseCase _sendMessage;
  final EditMessageUseCase _editMessage;
  final DeleteMessageUseCase _deleteMessage;
  final MarkAsReadUseCase _markAsRead;
  final AddReactionUseCase _addReaction;
  final RemoveReactionUseCase _removeReaction;
  final SendPushNotificationUseCase _sendPushNotification;

  // Repositories
  final IAttachmentRepository _attachmentRepository;

  // Services
  final CacheSyncStrategy _cacheSyncStrategy;
  final RealtimeService _realtimeService;
  final ILocationService _locationService;
  final FrequentReactionService _frequentReactionService;
  final TombstoneStore _tombstoneStore;
  final VoiceNotePlaybackManager _voiceNotePlaybackManager;

  // === Phase 2 + 3 Dependencies ===
  final SyncMetadataManager _syncMetadataManager;

  // Logger (injected via DI)
  final AppLogger logger;

  // Map chat ID -> StreamSubscription
  final Map<String, StreamSubscription?> _messageSubscriptions = {};

  // === Phase 2 + 3 Internal State ===
  final SocketEventBuffer<MessageEvent> _socketEventBuffer =
      SocketEventBuffer<MessageEvent>();
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _messageEditedSubscription;
  StreamSubscription? _messageDeletedSubscription;
  StreamSubscription? _messageReactionSubscription;
  StreamSubscription? _readReceiptSubscription;
  CancelableOperation<void>? _backgroundFetchOperation;
  DateTime? _lastBackgroundedAt;

  // Debounced mark-as-read
  Timer? _markAsReadDebouncer;
  DateTime? _lastVoiceDurationPrefetchAt;
  static const Duration _voiceDurationPrefetchThrottle =
      Duration(milliseconds: 220);

  // UI transform context
  String _currentUserId = '';
  bool _isGroupChat = false;
  String? _lastReadMessageId;
  String? _highlightedMessageId;
  String _conversationName = 'Chat';

  // Pending frequent reactions — stored when FetchFrequentReactions resolves
  // before state is MessagesLoaded (race condition on initial load)
  List<String>? _pendingFrequentReactions;

  /// Cập nhật context cho UI transform (gọi từ Page khi mở chat)
  void setTransformContext({
    required String currentUserId,
    bool isGroupChat = false,
    String? lastReadMessageId,
    String? highlightedMessageId,
    String? conversationName,
  }) {
    _currentUserId = currentUserId;
    _isGroupChat = isGroupChat;
    _lastReadMessageId = lastReadMessageId;
    _highlightedMessageId = highlightedMessageId;
    if (conversationName != null) _conversationName = conversationName;
  }

  /// Transform messages thành UI state
  List<MessageUIState> _transformMessages(List<ChatMessage> messages) {
    // Extract members from state for read receipt calculation
    final members = state is MessagesLoaded
        ? (state as MessagesLoaded).conversationMembers
        : const <ConversationMember>[];

    return _transformMessagesWithMembers(messages, members);
  }

  /// Transform messages with explicit members list (for cases where state
  /// hasn't been emitted yet, e.g. UpdateConversationMembers handler)
  List<MessageUIState> _transformMessagesWithMembers(
    List<ChatMessage> messages,
    List<ConversationMember> members,
  ) {
    return MessageListTransformer.transform(
      messages: messages,
      currentUserId: _currentUserId,
      lastReadMessageId: _lastReadMessageId,
      highlightedMessageId: _highlightedMessageId,
      isGroupChat: _isGroupChat,
      members: members,
    );
  }

  /// Apply pending frequent reactions to a freshly emitted MessagesLoaded state.
  MessagesLoaded _applyPendingFrequentReactions(MessagesLoaded loadedState) {
    final pending = _pendingFrequentReactions;
    if (pending != null) {
      _pendingFrequentReactions = null;
      return loadedState.copyWith(frequentReactions: pending);
    }
    return loadedState;
  }

  /// Constructor with UseCases injection
  MessageBloc({
    required GetMessagesUseCase getMessages,
    required SendMessageUseCase sendMessage,
    required EditMessageUseCase editMessage,
    required DeleteMessageUseCase deleteMessage,
    required MarkAsReadUseCase markAsRead,
    required AddReactionUseCase addReaction,
    required RemoveReactionUseCase removeReaction,
    required IAttachmentRepository attachmentRepository,
    required CacheSyncStrategy cacheSyncStrategy,
    required RealtimeService realtimeService,
    required ILocationService locationService,
    required SyncMetadataManager syncMetadataManager,
    required FrequentReactionService frequentReactionService,
    required SendPushNotificationUseCase sendPushNotification,
    required TombstoneStore tombstoneStore,
    required VoiceNotePlaybackManager voiceNotePlaybackManager,
    required this.logger,
  })  : _getMessages = getMessages,
        _sendMessage = sendMessage,
        _editMessage = editMessage,
        _deleteMessage = deleteMessage,
        _markAsRead = markAsRead,
        _addReaction = addReaction,
        _removeReaction = removeReaction,
        _attachmentRepository = attachmentRepository,
        _cacheSyncStrategy = cacheSyncStrategy,
        _realtimeService = realtimeService,
        _locationService = locationService,
        _syncMetadataManager = syncMetadataManager,
        _frequentReactionService = frequentReactionService,
        _sendPushNotification = sendPushNotification,
        _tombstoneStore = tombstoneStore,
        _voiceNotePlaybackManager = voiceNotePlaybackManager,
        super(const MessageState.initial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<SendSticker>(_onSendSticker);
    on<EditMessage>(_onEditMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<MarkChatAsRead>(_onMarkChatAsRead);
    on<PrefetchVisibleVoiceNoteDurations>(
      _onPrefetchVisibleVoiceNoteDurations,
    );
    on<ReceiveRealTimeMessage>(_onReceiveRealTimeMessage);
    on<RefreshMessages>(_onRefreshMessages);
    on<ClearMessages>(_onClearMessages);
    on<ToggleReaction>(_onToggleReaction);
    on<SendMessageWithAttachments>(_onSendMessageWithAttachments);
    on<SendVoiceNote>(_onSendVoiceNote);
    on<RetryVoiceNote>(_onRetryVoiceNote);
    on<SendLocationMessage>(_onSendLocationMessage);

    // Phase 2 + 3 event handlers
    on<_BackgroundFetchCompleted>(_onBackgroundFetchCompleted);
    on<_BackgroundFetchFailed>(_onBackgroundFetchFailed);
    on<_ReconnectionDetected>(_onReconnectionDetected);
    on<AppResumed>(_onAppResumed);
    on<ReceiveMessageEdited>(_onReceiveMessageEdited);
    on<ReceiveMessageDeleted>(_onReceiveMessageDeleted);
    on<ReceiveMessageReaction>(_onReceiveMessageReaction);
    on<ReceiveMessageRead>(_onReceiveMessageRead);
    on<UpdateConversationMembers>(_onUpdateConversationMembers);
    on<ForwardMessage>(_onForwardMessage);
    on<FetchFrequentReactions>(_onFetchFrequentReactions);
    on<JumpToMessage>(_onJumpToMessage);

    // Subscribe to connection state changes for reconnection detection
    _connectionStateSubscription = _realtimeService.connectionState
        .distinct()
        .pairwise()
        .where((pair) =>
            pair.first != SocketConnectionState.connected &&
            pair.last == SocketConnectionState.connected)
        .listen((_) => add(const _ReconnectionDetected()));
  }

  /// **Load messages — Two-Phase Render + Delta Sync**
  ///
  /// Phase 1: Emit local data immediately (< 50ms) with background fetch flag
  /// Phase 2: Background fetch (delta or full) → merge → emit merged state
  /// Fallback: First-time load (no local data) → standard server fetch
  Future<void> _onLoadMessages(
      LoadMessages event, Emitter<MessageState> emit) async {
    // logger.i('[TwoPhase] _onLoadMessages START chatId=${event.chatId} limit=${event.limit} forceRefresh=${event.forceRefresh}');

    // Step 1: Try local data first (Two-Phase Render)
    final localResult = await _getMessages.repository.getMessagesFromLocal(
      event.chatId,
      limit: event.limit,
    );

    final hasLocalData = localResult.fold(
      (_) => false,
      (messages) => messages.isNotEmpty,
    );

    localResult.fold(
      (failure) => logger
          .w('[TwoPhase] getMessagesFromLocal FAILED: ${failure.message}'),
      (messages) {
        final newestTs = messages.isNotEmpty
            ? messages.first.createdAt.toIso8601String()
            : 'N/A';
        logger.d(
            '[TwoPhase] getMessagesFromLocal: count=${messages.length} newest=$newestTs');
      },
    );

    if (hasLocalData && !event.forceRefresh) {
      // === TWO-PHASE RENDER PATH ===
      final localMessages = localResult.fold((_) => <ChatMessage>[], (m) => m);
      // logger.i('[TwoPhase] Taking TWO-PHASE path (hasLocal=true, forceRefresh=false)');

      // Phase 1: Emit local data immediately
      emit(MessageState.loaded(
        chatId: event.chatId,
        messages: localMessages,
        uiMessages: _transformMessages(localMessages),
        hasReachedMax: false,
        dataSource: MessageDataSource.local,
        isBackgroundFetching: true,
        receiverId: event.receiverId,
      ));

      // Apply pending frequent reactions if they arrived before this emit
      final phase1State = state;
      if (phase1State is MessagesLoaded) {
        final updated = _applyPendingFrequentReactions(phase1State);
        if (updated != phase1State) emit(updated);
      }

      // logger.i('[TwoPhase] Phase 1 EMITTED: localCount=${localMessages.length} dataSource=local bgFetching=true blocHashCode=$hashCode');

      // Subscribe to real-time updates
      if (event.subscribeToUpdates) {
        unawaited(_subscribeToMessages(event.chatId));
        _subscribeToEditDeleteReaction(event.chatId);
      } else {
        unawaited(_cancelMessageSubscription(event.chatId));
      }

      // Phase 2: Retry pending messages + background fetch (delta or full)
      unawaited(_retryAndRefresh(event.chatId, event.limit));
    } else {
      // === FIRST-TIME LOAD PATH (Phase 1 behavior) ===
      // logger.i('[TwoPhase] Taking FIRST-TIME path (hasLocal=$hasLocalData, forceRefresh=${event.forceRefresh})');
      emit(MessageState.loading(chatId: event.chatId));

      final result = await _getMessages(
        conversationId: event.chatId,
        limit: event.limit,
      );

      result.fold(
        (failure) {
          // For pending direct chats (no server conversation yet), a remote
          // failure is expected. Emit an empty loaded state so the user can
          // start typing their first message. The conversation will be
          // auto-created by the backend on first message send.
          if (event.receiverId != null) {
            logger.i(
                '[TwoPhase] Pending direct chat — remote load expected to fail. '
                'Emitting empty loaded state for receiverId=${event.receiverId}');
            emit(MessageState.loaded(
              chatId: event.chatId,
              messages: const [],
              uiMessages: const [],
              hasReachedMax: true,
              dataSource: MessageDataSource.local,
              receiverId: event.receiverId,
            ));

            // Subscribe to real-time updates (for when conversation is created)
            if (event.subscribeToUpdates) {
              unawaited(_subscribeToMessages(event.chatId));
              _subscribeToEditDeleteReaction(event.chatId);
            }
            return;
          }

          logger.e('[TwoPhase] First-time load FAILED: ${failure.message}',
              error: failure);
          emit(MessageState.error(
            chatId: event.chatId,
            error: failure.message,
          ));
        },
        (messages) {
          final newestTs = messages.isNotEmpty
              ? messages.first.createdAt.toIso8601String()
              : 'N/A';
          // logger.i('[TwoPhase] First-time load OK: count=${messages.length} newest=$newestTs');

          // Reset dirty flag after successful load
          _cacheSyncStrategy.resetChatMessagesDirtyFlag(event.chatId);

          // Update sync metadata
          unawaited(
              _syncMetadataManager.updateFromMessages(event.chatId, messages));

          // Subscribe to real-time updates
          if (event.subscribeToUpdates) {
            unawaited(_subscribeToMessages(event.chatId));
            _subscribeToEditDeleteReaction(event.chatId);
          } else {
            unawaited(_cancelMessageSubscription(event.chatId));
          }

          emit(MessageState.loaded(
            chatId: event.chatId,
            messages: messages,
            uiMessages: _transformMessages(messages),
            hasReachedMax: messages.length < event.limit,
            dataSource: MessageDataSource.server,
            receiverId: event.receiverId,
          ));

          // Apply pending frequent reactions if they arrived during the await
          final firstLoadState = state;
          if (firstLoadState is MessagesLoaded) {
            final updated = _applyPendingFrequentReactions(firstLoadState);
            if (updated != firstLoadState) emit(updated);
          }
        },
      );
    }
  }

  /// **Load more messages using GetMessagesUseCase (pagination) - CLEAN ARCHITECTURE**
  Future<void> _onLoadMoreMessages(
      LoadMoreMessages event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    // If already reached max, do nothing
    if (currentState.hasReachedMax) return;

    logger.i('Loading more messages for chat: ${currentState.chatId}');

    // Calculate cursor based on oldest message timestamp.
    // Backend supports timestamp-based pagination via filters.from.
    final lastMessageCursor = currentState.messages.isNotEmpty
        ? currentState.messages.last.createdAt.millisecondsSinceEpoch.toString()
        : null;

    // Execute UseCase
    final result = await _getMessages(
      conversationId: currentState.chatId,
      limit: event.limit,
      cursor: lastMessageCursor,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load more messages', error: failure);
        // Don't emit error for pagination — just log and re-emit with a
        // pagination error flag so the page can reset its loading indicator.
        emit(currentState.copyWith(paginationError: failure.message));
      },
      (nextMessages) {
        // logger.i('Loaded ${nextMessages.length} more messages');

        if (nextMessages.isEmpty) {
          // No more messages
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          // Add new messages to current list
          final byId = <String, ChatMessage>{
            for (final m in currentState.messages) m.id: m,
          };
          for (final m in nextMessages) {
            byId[m.id] = m;
          }

          final allMessages = byId.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          emit(currentState.copyWith(
            messages: allMessages,
            uiMessages: _transformMessages(allMessages),
            hasReachedMax: nextMessages.length < event.limit,
          ));
        }
      },
    );
  }

  /// **Jump to message — load messages from target timestamp (matching Angular frontend)**
  ///
  /// Instead of iteratively calling LoadMoreMessages, this loads a page of messages
  /// using the target message's `createdAt` as cursor, then merges with existing messages.
  Future<void> _onJumpToMessage(
      JumpToMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    logger.i(
        'JumpToMessage: loading messages from cursor ${event.createdAtMs} for message ${event.messageId}');

    // Add 1ms to cursor so the target message is included in results.
    // The API returns messages with createdAt < cursor (exclusive),
    // so we need cursor = targetTimestamp + 1 to include the target.
    final inclusiveCursor = event.createdAtMs + 1;

    final result = await _getMessages(
      conversationId: currentState.chatId,
      limit: 50,
      cursor: inclusiveCursor.toString(),
    );

    result.fold(
      (failure) {
        logger.e('JumpToMessage: failed to load messages', error: failure);
      },
      (fetchedMessages) {
        if (fetchedMessages.isEmpty) return;

        // Merge fetched messages with existing ones
        final byId = <String, ChatMessage>{
          for (final m in currentState.messages) m.id: m,
        };
        for (final m in fetchedMessages) {
          byId[m.id] = m;
        }

        final allMessages = byId.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        emit(currentState.copyWith(
          messages: allMessages,
          uiMessages: _transformMessages(allMessages),
        ));
      },
    );
  }

  /// **Send message using SendMessageUseCase - CLEAN ARCHITECTURE**
  ///
  /// Re-reads `state` after await to avoid stale-state race conditions
  /// when concurrent events (background fetch, real-time) modify state
  /// during the API call.
  Future<void> _onSendMessage(
      SendMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentLoaded = state as MessagesLoaded;
    final chatId = currentLoaded.chatId;
    final receiverId = currentLoaded.receiverId;

    logger.i('Sending message in chat: $chatId'
        '${receiverId != null ? ' (pending direct, receiverId=$receiverId)' : ''}');

    // Execute UseCase
    final result = await _sendMessage(
      conversationId: chatId,
      content: event.content,
      senderId: event.senderId,
      type: event.contentType,
      urls: event.attachmentIds,
      replyMessageId: event.replyMessageId,
      receiverId: receiverId,
    );

    // Re-read state after await — it may have changed during the API call
    final freshState = state;
    if (freshState is! MessagesLoaded) {
      logger.w(
          'State changed during sendMessage await (now ${freshState.runtimeType}), skipping emit');
      return;
    }

    result.fold(
      (failure) {
        logger.e('Failed to send message', error: failure);
        emit(MessageState.error(
          chatId: freshState.chatId,
          error: failure.message,
          previousMessages: freshState.messages,
        ));
      },
      (newMessage) {
        logger.i('Message sent successfully: ${newMessage.id}');

        // Deduplicate: check if message already exists (e.g. from real-time echo)
        final alreadyExists =
            freshState.messages.any((m) => m.id == newMessage.id);
        if (alreadyExists) {
          logger.d(
              'Message ${newMessage.id} already in list (real-time echo arrived first)');
          return;
        }

        // For pending direct chats: after first message, the server returns
        // the real conversationId. Update chatId and clear receiverId.
        final serverChatId = newMessage.chatId;
        final wasPendingDirect = freshState.receiverId != null &&
            serverChatId.isNotEmpty &&
            serverChatId != freshState.chatId;

        // Add new message to the beginning of the list
        final allMessages = [newMessage, ...freshState.messages];
        emit(freshState.copyWith(
          chatId: wasPendingDirect ? serverChatId : freshState.chatId,
          messages: allMessages,
          uiMessages: _transformMessages(allMessages),
          receiverId: wasPendingDirect ? null : freshState.receiverId,
        ));

        if (wasPendingDirect) {
          logger.i(
              'Pending direct chat resolved: tempId=${freshState.chatId} → '
              'serverId=$serverChatId. Subscribing to real-time updates.');
          // Subscribe to real-time updates with the real conversation ID
          unawaited(_subscribeToMessages(serverChatId));
          _subscribeToEditDeleteReaction(serverChatId);
        }

        // Mark message list as dirty
        _cacheSyncStrategy.markChatMessagesDirty(freshState.chatId);
        _cacheSyncStrategy.markChatListDirty();

        // Debug: Log mention info
        logger.d(
            'Message mentions check: mentionTo.length=${newMessage.mentionTo.length}, content="${newMessage.content}"');
        if (newMessage.mentionTo.isNotEmpty) {
          logger.d(
              'Mentions: ${newMessage.mentionTo.map((m) => '${m.name}(${m.id})').join(', ')}');
        }

        // Send push notification if message has mentions (fire-and-forget)
        if (newMessage.mentionTo.isNotEmpty) {
          final mentionIds = newMessage.mentionTo.map((m) => m.id).toList();
          final conversationName = _conversationName;

          logger.i(
              'Sending push notification to ${mentionIds.length} mentioned users');

          // Fire-and-forget: don't await, don't block UI
          unawaited(_sendPushNotification.call(
            receiverIds: mentionIds,
            title: conversationName,
            content: newMessage.content,
            metadata: {
              'conversationId': newMessage.chatId,
              'messageId': newMessage.id,
              'type': 'mention',
            },
          ));
        }
      },
    );
  }

  /// Send sticker message with optimistic update.
  Future<void> _onSendSticker(
      SendSticker event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) {
      logger.w('Cannot send sticker - messages not loaded');
      return;
    }

    final currentState = state as MessagesLoaded;
    const uuid = Uuid();
    final clientId = uuid.v4();
    final draftId = 'draft_$clientId';

    ChatMessage? replyMessage;
    if (event.replyMessageId != null && event.replyMessageId!.isNotEmpty) {
      final replyId = event.replyMessageId!;
      final index =
          currentState.messages.indexWhere((message) => message.id == replyId);
      if (index >= 0) {
        replyMessage = currentState.messages[index];
      }
    }

    final optimisticMessage = ChatMessage(
      id: draftId,
      clientId: clientId,
      chatId: currentState.chatId,
      content: event.stickerCode,
      contentType: ContentType.sticker,
      sender: MessageSender(
        id: event.senderId,
        name: '',
        avatar: null,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      replyMessageId: event.replyMessageId,
      replyMessage: replyMessage,
      readBy: const <String>[],
      deliveredTo: const <String>[],
      attachments: const <MessageAttachment>[],
      reactions: const <MessageReaction>[],
      mentionTo: const <MessageSender>[],
      localStatus: MessageStatus.sending,
    );

    final optimisticMessages = <ChatMessage>[
      optimisticMessage,
      ...currentState.messages
    ];
    emit(currentState.copyWith(
      messages: optimisticMessages,
      uiMessages: _transformMessages(optimisticMessages),
    ));

    final result = await _sendMessage(
      conversationId: currentState.chatId,
      content: event.stickerCode,
      senderId: event.senderId,
      type: 'sticker',
      replyMessageId: event.replyMessageId,
      receiverId: currentState.receiverId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to send sticker message', error: failure);
        _markMessageAsFailed(emit, clientId);
      },
      (message) {
        logger.i('Sticker message sent successfully: ${message.id}');
        _replaceDraftWithServerMessage(emit, clientId, message);
        _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
        _cacheSyncStrategy.markChatListDirty();
      },
    );
  }

  /// **Edit message using EditMessageUseCase - CLEAN ARCHITECTURE**
  Future<void> _onEditMessage(
      EditMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    logger.i('Editing message: ${event.messageId}');

    // Execute UseCase
    final result = await _editMessage(
      messageId: event.messageId,
      content: event.content,
    );

    // Re-read state after await
    final freshState = state;
    if (freshState is! MessagesLoaded) return;

    result.fold(
      (failure) {
        logger.e('Failed to edit message', error: failure);
        emit(MessageState.error(
          chatId: freshState.chatId,
          error: failure.message,
          previousMessages: freshState.messages,
        ));
      },
      (_) {
        logger.i('Message edited successfully');

        // Update message in list with new content
        final updatedMessages = freshState.messages.map((msg) {
          if (msg.id == event.messageId) {
            return ChatMessage(
              id: msg.id,
              chatId: msg.chatId,
              sender: msg.sender,
              content: event.content,
              contentType: msg.contentType,
              createdAt: msg.createdAt,
              updatedAt: DateTime.now(),
              editedAt: DateTime.now(),
              readBy: msg.readBy,
              deliveredTo: msg.deliveredTo,
              attachments: msg.attachments,
              reactions: msg.reactions,
            );
          }
          return msg;
        }).toList();

        emit(freshState.copyWith(
          messages: updatedMessages,
          uiMessages: _transformMessages(updatedMessages),
        ));

        _cacheSyncStrategy.markChatMessagesDirty(freshState.chatId);
      },
    );
  }

  /// **Delete message using DeleteMessageUseCase - CLEAN ARCHITECTURE**
  ///
  /// **Hard-delete behavior:** Removes message from list entirely.
  /// Backend permanently deletes the message.
  Future<void> _onDeleteMessage(
      DeleteMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;
    final chatId = currentState.chatId;

    logger.i('Deleting message: ${event.messageId} in chat: $chatId');

    // Store deleted message for potential rollback
    final deletedMessage = currentState.messages.firstWhere(
      (msg) => msg.id == event.messageId,
      orElse: () => throw StateError('Message not found'),
    );

    // Optimistic update: remove message immediately
    final optimisticallyUpdatedMessages = currentState.messages
        .where((msg) => msg.id != event.messageId)
        .toList();

    // Emit optimistic update
    emit(currentState.copyWith(
      messages: optimisticallyUpdatedMessages,
      uiMessages: _transformMessages(optimisticallyUpdatedMessages),
    ));

    final params = DeleteMessageParams(
      chatId: chatId,
      messageId: event.messageId,
    );
    final result = await _deleteMessage(params);

    // Re-read state after await
    final freshState = state;
    if (freshState is! MessagesLoaded) return;

    result.fold(
      (failure) {
        logger.e('Failed to delete message', error: failure);
        // Rollback: restore deleted message to its original position
        final restoredMessages = List<ChatMessage>.from(freshState.messages);
        final insertIndex = restoredMessages.indexWhere(
          (msg) => msg.createdAt.isBefore(deletedMessage.createdAt),
        );
        if (insertIndex == -1) {
          restoredMessages.add(deletedMessage);
        } else {
          restoredMessages.insert(insertIndex, deletedMessage);
        }
        // Re-sort by createdAt descending
        restoredMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        emit(MessageState.error(
          chatId: freshState.chatId,
          error: failure.message,
          previousMessages: restoredMessages,
        ));
      },
      (_) async {
        logger.i('Message deleted successfully (tombstone saved)');

        // Save tombstone for persistence across app restarts
        final tombstone =
            MessageTombstone.fromMessage(deletedMessage, DateTime.now());
        await _tombstoneStore.saveTombstone(tombstone);

        // Mark cache dirty
        _cacheSyncStrategy.markChatMessagesDirty(freshState.chatId);
        _cacheSyncStrategy.markChatListDirty();
      },
    );
  }

  /// **Forward message to another chat**
  ///
  /// Creates a copy of the message in the target chat with forwardedFromMessageId reference.
  Future<void> _onForwardMessage(
      ForwardMessage event, Emitter<MessageState> emit) async {
    // Use message directly from event (UI đã truyền đầy đủ)
    final originalMessage = event.message;

    if (originalMessage.id.isEmpty) {
      logger.w('Cannot forward: message has empty id');
      return;
    }

    logger.i(
        'Forwarding message ${originalMessage.id} to chat ${event.targetChatId}');

    // Execute SendMessageUseCase to forward to target chat
    // Pass forwardedFromMessageId so backend can track the original message
    // Use attachment URLs (not IDs) for media files
    final attachmentUrls = originalMessage.attachments
        .where((a) => a.url.isNotEmpty)
        .map((a) => a.url)
        .toList();

    final result = await _sendMessage(
      conversationId: event.targetChatId,
      content: originalMessage.content,
      senderId: originalMessage.sender.id,
      type: originalMessage.contentType.name,
      urls: attachmentUrls,
      forwardedFromMessageId: originalMessage.id,
    );

    result.fold(
      (failure) {
        logger.e('Failed to forward message', error: failure);
        // Emit error state if we have a current chat context
        state.maybeWhen(
          loaded: (chatId, messages, _, __, ___, ____, _____, ______, _______, ________) {
            emit(MessageState.error(
              chatId: chatId,
              error: failure.message,
              previousMessages: messages,
            ));
          },
          orElse: () {
            // No current chat context, just log
            logger
                .w('Forward failed but no current chat context to emit error');
          },
        );
      },
      (sentMessage) {
        logger.i('Message forwarded successfully to ${event.targetChatId}');
        // Mark chat list as dirty (new message in target chat)
        _cacheSyncStrategy.markChatListDirty();
      },
    );
  }

  /// Fetch frequently used reactions và emit vào state
  Future<void> _onFetchFrequentReactions(
    FetchFrequentReactions event,
    Emitter<MessageState> emit,
  ) async {
    await _frequentReactionService.fetch();
    final reactions = _frequentReactionService.currentReactions;

    if (state is MessagesLoaded) {
      emit((state as MessagesLoaded).copyWith(frequentReactions: reactions));
    } else {
      // State chưa sẵn sàng — lưu tạm để apply khi MessagesLoaded được emit
      _pendingFrequentReactions = reactions;
    }
  }

  /// **Mark chat as read using MarkAsReadUseCase - DEBOUNCED + RETRY**
  ///
  /// Debounces 500ms to avoid excessive API calls when scrolling fast.
  /// Retries up to 2 times with 1 second backoff on failure.
  /// Logs errors silently — never shows error to user (non-critical).
  Future<void> _onMarkChatAsRead(
      MarkChatAsRead event, Emitter<MessageState> emit) async {
    // logger.i('MarkChatAsRead received: ${event.chatId} (debouncing 500ms)');

    // Cancel any existing debounce timer — use latest event data
    _markAsReadDebouncer?.cancel();

    // Start new 500ms debounce timer
    _markAsReadDebouncer = Timer(const Duration(milliseconds: 500), () {
      _executeMarkAsReadWithRetry(event.chatId);
    });
  }

  void _onPrefetchVisibleVoiceNoteDurations(
    PrefetchVisibleVoiceNoteDurations event,
    Emitter<MessageState> emit,
  ) {
    final currentState = state;
    if (currentState is! MessagesLoaded) return;
    if (event.visibleIndices.isEmpty) return;

    final now = DateTime.now();
    final lastPrefetchAt = _lastVoiceDurationPrefetchAt;
    if (lastPrefetchAt != null &&
        now.difference(lastPrefetchAt) < _voiceDurationPrefetchThrottle) {
      return;
    }
    _lastVoiceDurationPrefetchAt = now;

    final prefetchedMessageIds = <String>{};
    for (final index in event.visibleIndices) {
      if (index < 0 || index >= currentState.uiMessages.length) {
        continue;
      }

      final uiState = currentState.uiMessages[index];
      if (!prefetchedMessageIds.add(uiState.id)) continue;

      final sourceUrl = _resolveVoiceNoteSourceForUiState(uiState);
      if (sourceUrl == null) continue;

      unawaited(
        _voiceNotePlaybackManager.prefetchDuration(
          messageId: uiState.id,
          audioUrl: sourceUrl,
        ),
      );
    }
  }

  String? _resolveVoiceNoteSourceForUiState(MessageUIState uiState) {
    if (uiState.itemType != MessageListItemType.message) {
      return null;
    }
    if (uiState.contentType != ContentType.audio) {
      return null;
    }

    final attachments = uiState.attachments;
    if (attachments.length != 1) {
      return null;
    }

    final attachment = attachments.first;
    final isVoiceNoteAttachment =
        attachment.type.trim().toLowerCase() == 'voice_note';
    final isVoiceNoteFromName = _isVoiceNoteFileName(uiState.fileName) ||
        _isVoiceNoteFileName(attachment.name);
    if (!isVoiceNoteAttachment && !isVoiceNoteFromName) {
      return null;
    }

    final sourceUrl = _resolveVoiceNoteSourceUrl(attachment);
    if (sourceUrl.isEmpty) return null;
    return sourceUrl;
  }

  bool _isVoiceNoteFileName(String? fileName) {
    if (fileName == null) return false;
    final normalized = fileName.trim().toLowerCase();
    return normalized.startsWith('voice_note_') && normalized.endsWith('.m4a');
  }

  String _resolveVoiceNoteSourceUrl(MessageAttachment attachment) {
    final remoteUrl = attachment.url.trim();
    if (remoteUrl.isNotEmpty) return remoteUrl;

    final localPath = attachment.localPath?.trim();
    if (localPath != null && localPath.isNotEmpty) {
      return localPath;
    }

    return '';
  }

  /// Execute the actual mark-as-read mutation with retry logic.
  /// Retries up to 2 times with 1 second backoff between attempts.
  Future<void> _executeMarkAsReadWithRetry(String chatId) async {
    const maxRetries = 2;
    const retryBackoff = Duration(seconds: 1);

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      final params = MarkAsReadParams(conversationId: chatId);
      final result = await _markAsRead(params);

      final succeeded = result.fold(
        (failure) {
          if (attempt < maxRetries) {
            logger.w(
              'markChatAsRead failed (attempt ${attempt + 1}/${maxRetries + 1}): '
              '${failure.message}, retrying in ${retryBackoff.inSeconds}s',
            );
          } else {
            logger.e(
              'markChatAsRead failed after ${maxRetries + 1} attempts: ${failure.message}',
              error: failure,
            );
          }
          return false;
        },
        (_) {
          // logger.i('Chat marked as read successfully: $chatId');
          _cacheSyncStrategy.markChatListDirty();
          return true;
        },
      );

      if (succeeded) return;

      // Wait before retry (skip wait on last attempt)
      if (attempt < maxRetries) {
        await Future<void>.delayed(retryBackoff);
      }
    }
  }

  /// Handle real-time message received via WebSocket
  ///
  /// **Enterprise Pattern (WhatsApp/Telegram/Messenger):**
  /// - Messages from SELF: IGNORE (API response is the source of truth)
  /// - Messages from OTHERS: Add to list (with duplicate check)
  ///
  /// This prevents duplicate messages when:
  /// 1. User sends message → API returns → WebSocket echoes back
  /// 2. User sends rapidly → multiple messages have similar timestamps
  void _onReceiveRealTimeMessage(
      ReceiveRealTimeMessage event, Emitter<MessageState> emit) {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    // Only process messages for current chat
    if (event.message.chatId != currentState.chatId) return;

    logger.d('Received real-time message via socket: ${event.message.id}');

    // Check if message already exists in list (exact server ID match)
    final messageExists =
        currentState.messages.any((msg) => msg.id == event.message.id);
    if (messageExists) {
      logger.d(
          'Message ${event.message.id} already exists, ignoring WebSocket echo');
      return;
    }

    // **KEY LOGIC**: If message is from current user, check if we have a pending draft
    // API response will handle our own messages, WebSocket is just an echo
    if (event.message.sender.id == _currentUserId) {
      // Check if we have ANY pending draft (message with clientId that hasn't been replaced yet)
      final hasPendingDraft = currentState.messages
          .any((msg) => msg.clientId != null && msg.localStatus != null);

      if (hasPendingDraft) {
        // We have pending messages being sent via API
        // The API response will update them, ignore WebSocket echo
        logger.d(
            'Ignoring self-message from WebSocket (API will handle): ${event.message.id}');
        return;
      }

      // No pending drafts - this might be a message sent from another device
      // Fall through to add it
      logger.d('Adding self-message from another device: ${event.message.id}');
    }

    // Add new message (from other users or self from another device)
    // For system events (ADD_MEMBER, REMOVE_MEMBER, etc.), socket only sends
    // targetUserIds without names. Enrich with names from current members list.
    final enrichedMessage = _enrichSystemEventTargetNames(
      event.message,
      currentState.conversationMembers,
    );
    final allMessages = [enrichedMessage, ...currentState.messages];
    emit(currentState.copyWith(
      messages: allMessages,
      uiMessages: _transformMessages(allMessages),
    ));

    // Mark message list as dirty
    _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
    _cacheSyncStrategy.markChatListDirty();
  }

  /// Enrich system event messages with target user names from members list.
  ///
  /// Socket events only send `targetUserIds` (no fullName), resulting in
  /// 'Unknown' target names. This resolves names from the current members list.
  /// For REMOVE_MEMBER, the member may already be removed — in that case,
  /// the transformer's fallback to `message.content` handles it.
  ChatMessage _enrichSystemEventTargetNames(
    ChatMessage message,
    List<ConversationMember> members,
  ) {
    // Only enrich system event messages that have unresolved target users
    if (message.targetUsers.isEmpty) return message;
    if (!message.targetUsers
        .any((u) => u.name == 'Unknown' || u.name.trim().isEmpty)) {
      return message;
    }

    // Build lookup map: userId -> fullName
    final memberNameById = <String, String>{
      for (final m in members)
        if (m.userId.isNotEmpty && (m.fullName?.isNotEmpty ?? false))
          m.userId: m.fullName!,
    };

    final enrichedTargets = message.targetUsers.map((u) {
      if (u.name.isNotEmpty && u.name != 'Unknown') return u;
      final resolvedName = memberNameById[u.id];
      if (resolvedName != null) {
        return MessageSender(id: u.id, name: resolvedName, avatar: u.avatar);
      }
      return u;
    }).toList();

    return message.copyWith(targetUsers: enrichedTargets);
  }

  // === Phase 2 + 3: Background Fetch ===

  /// Start background fetch with socket event buffering
  void _startBackgroundFetch(String chatId, int limit) {
    _socketEventBuffer.startBuffering();
    _backgroundFetchOperation?.cancel();
    _backgroundFetchOperation = CancelableOperation.fromFuture(
      _performBackgroundFetch(chatId, limit),
    );
  }

  /// Perform delta sync or full fetch in background
  Future<void> _performBackgroundFetch(String chatId, int limit) async {
    try {
      final lastTimestamp = _syncMetadataManager.getLastKnownTimestamp(chatId);
      // logger.i('[TwoPhase] _performBackgroundFetch chatId=$chatId lastTimestamp=$lastTimestamp limit=$limit');

      Either<Failure, List<ChatMessage>> result;
      bool isDelta = false;

      if (lastTimestamp != null) {
        // Delta sync: only fetch messages since last known timestamp
        // logger.i('[TwoPhase] Doing DELTA sync from=${DateTime.fromMillisecondsSinceEpoch(lastTimestamp).toIso8601String()}');
        result = await _getMessages.repository.getMessagesDelta(
          chatId,
          fromTimestamp: lastTimestamp,
          limit: limit,
        );

        // Gap detection
        final deltaCount = result.fold((_) => 0, (m) => m.length);
        // logger.i('[TwoPhase] Delta result: count=$deltaCount (gap threshold=$limit)');
        if (GapDetectionLogic.hasGap(deltaCount: deltaCount, pageSize: limit)) {
          logger.w(
              '[TwoPhase] Gap detected (deltaCount=$deltaCount >= pageSize=$limit), doing FULL refresh');
          result = await _getMessages(conversationId: chatId, limit: limit);
          isDelta = false;
        } else {
          isDelta = true;
        }
      } else {
        // No timestamp — full load
        // logger.i('[TwoPhase] No lastTimestamp, doing FULL load');
        result = await _getMessages(conversationId: chatId, limit: limit);
        isDelta = false;
      }

      result.fold(
        (failure) {
          logger.e('[TwoPhase] Background fetch FAILED: ${failure.message}');
          add(_BackgroundFetchFailed(chatId: chatId, error: failure.message));
        },
        (messages) {
          final newestTs = messages.isNotEmpty
              ? messages.first.createdAt.toIso8601String()
              : 'N/A';
          final oldestTs = messages.isNotEmpty
              ? messages.last.createdAt.toIso8601String()
              : 'N/A';
          // logger.i('[TwoPhase] Background fetch OK: count=${messages.length} newest=$newestTs oldest=$oldestTs isDelta=$isDelta');
          add(_BackgroundFetchCompleted(
              chatId: chatId,
              serverMessages: messages,
              isDelta: isDelta,
              fetchLimit: limit));
        },
      );
    } catch (e) {
      logger.e('[TwoPhase] Background fetch EXCEPTION', error: e);
      add(_BackgroundFetchFailed(chatId: chatId, error: e.toString()));
    }
  }

  /// Handle background fetch completion — re-read from Isar (upsert already handled dedup)
  ///
  /// Since the repository's _fetchAndCacheFromRemote / getMessagesDelta already
  /// upserts server messages into Isar (with atomic dedup via _resolveExisting),
  /// we simply re-read the merged data from local storage instead of performing
  /// manual MessageMergeStrategy merge. This eliminates the duplicate bug and
  /// simplifies the entire flow.
  Future<void> _onBackgroundFetchCompleted(
    _BackgroundFetchCompleted event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessagesLoaded) {
      logger.w(
          '[TwoPhase] _onBackgroundFetchCompleted: state is NOT MessagesLoaded (${state.runtimeType}), ignoring');
      return;
    }
    final currentState = state as MessagesLoaded;

    // Race condition guard: ignore stale responses for wrong chat
    if (currentState.chatId != event.chatId) {
      logger.w(
          '[TwoPhase] Background fetch completed for WRONG chat: event=${event.chatId} vs current=${currentState.chatId}');
      _socketEventBuffer.stopBuffering();
      return;
    }

    // === KEY CHANGE: Re-read from Isar instead of manual merge ===
    // The repository already upserted server messages into Isar with atomic
    // dedup. We re-read to get the clean, merged, deduplicated list.
    final localResult = await _getMessages.repository.getMessagesFromLocal(
      event.chatId,
      limit: currentState.messages.length > event.fetchLimit
          ? currentState.messages.length
          : event.fetchLimit,
    );

    final merged = localResult.fold(
      (_) => currentState.messages, // On error, keep current state
      (messages) => messages,
    );

    // Apply tombstones (deleted messages) — still needed for hard-delete consistency
    await _tombstoneStore.loadFromDisk(event.chatId);
    final tombstones = _tombstoneStore.getTombstonesForChat(event.chatId);
    final tombstoneIds = tombstones.map((t) => t.messageId).toSet();

    final filteredMerged = tombstoneIds.isEmpty
        ? merged
        : merged.where((m) => !tombstoneIds.contains(m.id)).toList();

    // Preserve optimistic messages (sending/pending) that may not be in Isar yet
    // These are draft messages with clientId that haven't been confirmed by server
    final optimisticMessages = currentState.messages
        .where((m) =>
            m.clientId != null &&
            (m.localStatus == MessageStatus.sending ||
                m.localStatus == MessageStatus.pending ||
                m.localStatus == MessageStatus.failed))
        .toList();

    // Merge: server-synced data from Isar + optimistic messages from BLoC state
    final mergedIds = filteredMerged.map((m) => m.id).toSet();
    final missingOptimistic =
        optimisticMessages.where((m) => !mergedIds.contains(m.id)).toList();

    final finalMessages = [...missingOptimistic, ...filteredMerged];
    finalMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Update sync metadata
    unawaited(_syncMetadataManager.updateFromMessages(event.chatId, finalMessages));
    _cacheSyncStrategy.resetChatMessagesDirtyFlag(event.chatId);

    // hasReachedMax: only meaningful for full page fetch
    final hasReachedMax = event.isDelta
        ? currentState.hasReachedMax
        : event.serverMessages.length < event.fetchLimit;

    emit(currentState.copyWith(
      messages: finalMessages,
      uiMessages: _transformMessages(finalMessages),
      dataSource: MessageDataSource.merged,
      isBackgroundFetching: false,
      hasReachedMax: hasReachedMax,
    ));

    logger.i(
        '[TwoPhase] _onBackgroundFetchCompleted EMITTED: mergedCount=${finalMessages.length} (isar=${filteredMerged.length} + optimistic=${missingOptimistic.length}) dataSource=merged bgFetching=false');

    // Flush buffered socket events
    final bufferedEvents = _socketEventBuffer.stopBuffering();
    if (bufferedEvents.isNotEmpty) {
      logger.i(
          '[TwoPhase] Flushing ${bufferedEvents.length} buffered socket events');
    }
    for (final bufferedEvent in bufferedEvents) {
      add(bufferedEvent);
    }
  }

  /// Handle background fetch failure — keep local data, no error state
  void _onBackgroundFetchFailed(
    _BackgroundFetchFailed event,
    Emitter<MessageState> emit,
  ) {
    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    if (currentState.chatId != event.chatId) {
      _socketEventBuffer.stopBuffering();
      return;
    }

    logger.w(
        '[TwoPhase] Background fetch FAILED for chat ${event.chatId}: ${event.error} — keeping ${currentState.messages.length} local messages');

    emit(currentState.copyWith(
      isBackgroundFetching: false,
    ));

    // Flush buffered socket events
    final bufferedEvents = _socketEventBuffer.stopBuffering();
    if (bufferedEvents.isNotEmpty) {
      logger.i(
          '[TwoPhase] Flushing ${bufferedEvents.length} buffered socket events after failure');
    }
    for (final bufferedEvent in bufferedEvents) {
      add(bufferedEvent);
    }
  }

  // === Phase 3: Socket Event Handlers (Edit/Delete/Reaction) ===

  /// Subscribe to edit/delete/reaction streams from RealtimeService.
  /// Does NOT duplicate room joining — that's handled by _subscribeToMessages.
  void _subscribeToEditDeleteReaction(String chatId) {
    _messageEditedSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _messageReactionSubscription?.cancel();
    _readReceiptSubscription?.cancel();

    _messageEditedSubscription = _realtimeService.messageEditedStream
        .where((msg) => msg.chatId == chatId)
        .listen((msg) => add(ReceiveMessageEdited(msg)));

    _messageDeletedSubscription = _realtimeService.messageDeletedStream
        .where((msg) => msg.chatId == chatId)
        .listen((msg) => add(ReceiveMessageDeleted(msg)));

    _messageReactionSubscription = _realtimeService.messageReactionStream
        .listen((reaction) => add(ReceiveMessageReaction(
              messageId: reaction.messageId,
              code: reaction.code,
              userId: reaction.userId,
              userName: reaction.userName,
              isAdd: reaction.action == ReactionAction.add,
            )));

    _readReceiptSubscription = _realtimeService.readReceiptStream
        .where((receipt) => receipt.chatId == chatId)
        .listen((receipt) => add(ReceiveMessageRead(
              messageId: receipt.messageId,
              readerId: receipt.readerId,
            )));
  }

  /// Handle socket message:edit — update message in state
  void _onReceiveMessageEdited(
      ReceiveMessageEdited event, Emitter<MessageState> emit) {
    if (_socketEventBuffer.bufferIfNeeded(event)) return;

    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    final updatedMessages = currentState.messages.map((msg) {
      if (msg.id == event.editedMessage.id) {
        return event.editedMessage;
      }
      return msg;
    }).toList();

    emit(currentState.copyWith(
      messages: updatedMessages,
      uiMessages: _transformMessages(updatedMessages),
    ));

    unawaited(_syncMetadataManager.updateFromMessages(
      currentState.chatId,
      [event.editedMessage],
    ));
  }

  /// Handle socket message:delete — save tombstone and show deleted message placeholder
  ///
  /// **Tombstone behavior:** Saves deleted message to TombstoneStore
  /// and updates state to show "Tin nhắn đã bị xoá" placeholder.
  Future<void> _onReceiveMessageDeleted(
      ReceiveMessageDeleted event, Emitter<MessageState> emit) async {
    if (_socketEventBuffer.bufferIfNeeded(event)) return;

    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    final deletedMessage = event.deletedMessage;
    final messageId = deletedMessage.id;

    // Save tombstone to store (for persistence across app restarts)
    final tombstone =
        MessageTombstone.fromMessage(deletedMessage, DateTime.now());
    await _tombstoneStore.saveTombstone(tombstone);

    // Check if message exists in current state
    final messageIndex =
        currentState.messages.indexWhere((msg) => msg.id == messageId);

    if (messageIndex == -1) {
      // Message not in current state, add tombstone at correct position
      final updatedMessages = [...currentState.messages];
      updatedMessages.add(deletedMessage.copyWith(
        deletedAt: DateTime.now(),
        content: '', // Clear content for tombstone display
      ));
      updatedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(currentState.copyWith(
        messages: updatedMessages,
        uiMessages: _transformMessages(updatedMessages),
      ));
    } else {
      // Message exists, update it to show as deleted
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == messageId) {
          return msg.copyWith(
            deletedAt: DateTime.now(),
            content: '', // Clear content for tombstone display
          );
        }
        return msg;
      }).toList();

      emit(currentState.copyWith(
        messages: updatedMessages,
        uiMessages: _transformMessages(updatedMessages),
      ));
    }

    logger.d('Message $messageId marked as deleted (tombstone saved)');
  }

  /// Handle socket message:reaction — add/remove reaction on message
  void _onReceiveMessageReaction(
      ReceiveMessageReaction event, Emitter<MessageState> emit) {
    if (_socketEventBuffer.bufferIfNeeded(event)) return;

    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    bool hasChanges = false;
    final updatedMessages = currentState.messages.map((msg) {
      if (msg.id != event.messageId) return msg;

      List<MessageReaction> updatedReactions;
      if (event.isAdd) {
        // Idempotent: skip if this exact reaction (code + userId) already exists.
        // This prevents duplicates when optimistic update already applied the reaction.
        final alreadyExists = msg.reactions.any(
          (r) => r.code == event.code && r.userId == event.userId,
        );
        if (alreadyExists) return msg;

        hasChanges = true;
        updatedReactions = [
          ...msg.reactions,
          MessageReaction(
            code: event.code,
            userId: event.userId,
            userName: event.userName,
            createdAt: DateTime.now(),
          ),
        ];
      } else {
        // Idempotent: only remove if the reaction actually exists.
        final exists = msg.reactions.any(
          (r) => r.code == event.code && r.userId == event.userId,
        );
        if (!exists) return msg;

        hasChanges = true;
        updatedReactions = msg.reactions
            .where((r) => !(r.code == event.code && r.userId == event.userId))
            .toList();
      }

      return msg.copyWith(reactions: updatedReactions);
    }).toList();

    // Only emit if state actually changed to avoid unnecessary rebuilds.
    if (!hasChanges) return;

    emit(currentState.copyWith(
      messages: updatedMessages,
      uiMessages: _transformMessages(updatedMessages),
    ));
  }

  /// Handle socket message:read — add readerId to message's readBy list
  void _onReceiveMessageRead(
      ReceiveMessageRead event, Emitter<MessageState> emit) {
    if (_socketEventBuffer.bufferIfNeeded(event)) return;

    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    // Find the message by messageId
    final messageIndex = currentState.messages.indexWhere(
      (msg) => msg.id == event.messageId,
    );

    if (messageIndex == -1) {
      logger.w(
          'ReceiveMessageRead: messageId=${event.messageId} not found in state, ignoring');
      return;
    }

    final message = currentState.messages[messageIndex];

    // Idempotent: skip if readerId already in readBy
    if (message.readBy.contains(event.readerId)) return;

    // Create updated message with new readBy list
    final updatedMessage = message.copyWith(
      readBy: [...message.readBy, event.readerId],
    );

    // Replace message in list
    final updatedMessages = List<ChatMessage>.from(currentState.messages);
    updatedMessages[messageIndex] = updatedMessage;

    emit(currentState.copyWith(
      messages: updatedMessages,
      uiMessages: _transformMessages(updatedMessages),
    ));
  }

  // === Phase 3: Reconnection & App Resume ===

  /// Handle reconnection — trigger delta sync AND retry pending messages
  void _onReconnectionDetected(
      _ReconnectionDetected event, Emitter<MessageState> emit) {
    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    logger.i(
        'Reconnection detected, triggering delta sync + pending retry for chat ${currentState.chatId}');

    // 1. Retry pending messages first (fire-and-forget),
    //    then refresh UI so sent messages show updated status
    unawaited(_retryAndRefresh(currentState.chatId));
  }

  /// Retry pending messages for [chatId], then trigger a background fetch
  /// so the UI picks up the updated message statuses.
  Future<void> _retryAndRefresh(String chatId, [int limit = 20]) async {
    try {
      final result = await _getMessages.repository.retryPendingMessages(chatId);
      result.fold(
        (failure) =>
            logger.e('Pending message retry failed: ${failure.message}'),
        (count) {
          if (count > 0) {
            logger.i('Retried $count pending messages for chat $chatId');
          }
        },
      );
    } catch (e) {
      logger.e('Pending message retry error', error: e);
    }

    // 2. Always do a delta sync to get new messages from server
    //    (also refreshes UI with updated statuses from step 1)
    _startBackgroundFetch(chatId, limit);
  }

  /// Handle app resume — delta sync if backgrounded > 30 seconds
  void _onAppResumed(AppResumed event, Emitter<MessageState> emit) {
    if (state is! MessagesLoaded) return;
    final currentState = state as MessagesLoaded;

    final now = DateTime.now();
    if (_lastBackgroundedAt != null) {
      final backgroundDuration = now.difference(_lastBackgroundedAt!);
      if (backgroundDuration.inSeconds < 30) {
        logger.d(
            'App resumed after ${backgroundDuration.inSeconds}s, skipping delta sync');
        return;
      }
    }

    logger.i(
        'App resumed after >30s, triggering delta sync for chat ${currentState.chatId}');
    _startBackgroundFetch(currentState.chatId, 20);
  }

  /// Called from Page when app enters background
  void setBackgroundedAt(DateTime time) {
    _lastBackgroundedAt = time;
  }

  /// Handle refresh messages
  Future<void> _onRefreshMessages(
      RefreshMessages event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    add(LoadMessages(
      chatId: (state as MessagesLoaded).chatId,
      forceRefresh: true,
    ));
  }

  /// Handle clear messages
  void _onClearMessages(ClearMessages event, Emitter<MessageState> emit) {
    emit(const MessageState.initial());
  }

  /// **Cancel real-time message subscription - ENTERPRISE CLEANUP**
  ///
  /// **Performance**: <100ms cleanup
  /// **Strategy**: Clean subscription cancellation with room exit
  Future<void> _cancelMessageSubscription(
    String chatId, {
    bool leaveRoom = true,
  }) async {
    final subscription = _messageSubscriptions[chatId];
    if (subscription != null) {
      await subscription.cancel();
      _messageSubscriptions[chatId] = null;
      logger.d('Subscription cancelled for chat: $chatId');
    }

    if (leaveRoom) {
      // Leave chat room to stop receiving updates
      final result = await _realtimeService.leaveChatRoom(chatId);
      result.fold(
        (failure) {
          logger.w('Failed to leave chat room $chatId: ${failure.toString()}');
        },
        (_) {
          logger.d('Successfully left chat room: $chatId');
        },
      );
    }
  }

  /// **Subscribe to real-time messages - ENTERPRISE REAL-TIME**
  ///
  /// **Performance**: <100ms message delivery
  /// **Strategy**: WebSocket subscription with automatic room management
  Future<void> _subscribeToMessages(String chatId) async {
    // logger.i('Subscribing to real-time messages for chat: $chatId');

    // Cancel existing subscription if any
    await _cancelMessageSubscription(chatId);

    // Ensure real-time connection is established
    if (!_realtimeService.isConnected) {
      final connectResult = await _realtimeService.connect();
      final connectOk = connectResult.fold((_) => false, (_) => true);
      if (!connectOk) {
        logger.e(
            'Failed to connect to real-time server before joining chat room $chatId');
        return;
      }
    }

    // Join chat room for real-time updates
    final joinResult = await _realtimeService.joinChatRoom(chatId);
    final joined = joinResult.fold(
      (failure) {
        logger.e('Failed to join chat room $chatId', error: failure);
        return false;
      },
      (_) {
        logger.i('Successfully joined chat room: $chatId');
        return true;
      },
    );

    if (!joined) {
      return;
    }

    // Subscribe to real-time message stream
    _messageSubscriptions[chatId] = _realtimeService.messageStream
        .where((message) => message.chatId == chatId)
        .listen(
      (message) {
        logger.d('Received real-time message: ${message.id} in chat $chatId');
        add(ReceiveRealTimeMessage(message));
      },
      onError: (error) {
        logger.e('Error in real-time message stream: $error');
      },
    );

    logger.i('Real-time subscription established for chat: $chatId');
  }

  /// Handle toggle reaction on message (optimistic update + API call)
  Future<void> _onToggleReaction(
    ToggleReaction event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    logger.i(
        'Toggling reaction ${event.emojiCode} on message ${event.messageId}');

    // Find the target message — abort if not found (don't silently fall back)
    final targetIndex = currentState.messages.indexWhere(
      (msg) => msg.id == event.messageId,
    );
    if (targetIndex == -1) {
      logger.w(
          'ToggleReaction: message ${event.messageId} not found in state, ignoring');
      return;
    }
    final targetMessage = currentState.messages[targetIndex];

    final existingReaction = targetMessage.reactions.where(
      (r) => r.code == event.emojiCode && r.userId == _currentUserId,
    );

    // forceAdd=true (from desktop hover bar): always ADD, never remove
    final isRemoving = !event.forceAdd && existingReaction.isNotEmpty;

    logger.d(
        'ToggleReaction: isRemoving=$isRemoving, forceAdd=${event.forceAdd}, reactions count=${targetMessage.reactions.length}, userId=$_currentUserId');

    // Optimistic update: toggle reaction locally
    final updatedMessages = currentState.messages.map((msg) {
      if (msg.id != event.messageId) return msg;

      List<MessageReaction> updatedReactions;
      if (isRemoving) {
        // Remove reaction
        updatedReactions = msg.reactions
            .where((r) =>
                !(r.code == event.emojiCode && r.userId == _currentUserId))
            .toList();
      } else {
        // Add reaction
        updatedReactions = [
          ...msg.reactions,
          MessageReaction(
            code: event.emojiCode,
            userId: _currentUserId,
            createdAt: DateTime.now(),
          ),
        ];
      }

      return msg.copyWith(reactions: updatedReactions);
    }).toList();

    // Emit optimistic update immediately
    emit(currentState.copyWith(
      messages: updatedMessages,
      uiMessages: _transformMessages(updatedMessages),
    ));

    // Call API to persist reaction on server
    try {
      final result = isRemoving
          ? await _removeReaction(
              messageId: event.messageId,
              code: event.emojiCode,
            )
          : await _addReaction(
              messageId: event.messageId,
              code: event.emojiCode,
            );

      result.fold(
        (failure) {
          logger.e('Failed to toggle reaction', error: failure.message);

          // Rollback optimistic update on failure
          emit(currentState.copyWith(
            messages: currentState.messages,
            uiMessages: _transformMessages(currentState.messages),
          ));

          // Note: Error handling can be improved by adding error field to MessagesLoaded state
        },
        (_) {
          logger.i('Reaction updated successfully');
          // Success - optimistic update already shown
          // Real-time socket will sync the full reaction list with reactors
          _frequentReactionService.invalidateAfterReaction();
        },
      );
    } catch (e, stackTrace) {
      logger.e('Unexpected error toggling reaction',
          error: e, stackTrace: stackTrace);

      // Rollback on unexpected error
      emit(currentState.copyWith(
        messages: currentState.messages,
        uiMessages: _transformMessages(currentState.messages),
      ));
    }
  }

  /// **Send message with file attachments - CLEAN ARCHITECTURE**
  ///
  /// Handles complete flow using enterprise-grade optimistic UI pattern:
  /// 1. Generate unique clientId (UUID) for tracking
  /// 2. Create optimistic message with local file (show immediately)
  /// 3. Upload files to GCP Cloud Storage (show progress)
  /// 4. Send message with uploaded file paths
  /// 5. Replace optimistic message with server response (matched by clientId)
  ///
  /// WebSocket handler will IGNORE messages from self (API response is source of truth)
  Future<void> _onSendMessageWithAttachments(
    SendMessageWithAttachments event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessagesLoaded) {
      logger.w('Cannot send message with attachments - messages not loaded');
      return;
    }

    final currentState = state as MessagesLoaded;
    logger.i('Sending message with ${event.localFilePaths.length} attachments');

    // Generate unique client ID (UUID) for tracking this message
    // This ensures we can match the API response even with rapid sends
    const uuid = Uuid();
    final clientId = uuid.v4();
    final draftId =
        'draft_$clientId'; // Temporary ID until server assigns real one

    // Determine message type from first file
    // Cross-platform: use fileNames on web (path might be blob URL), path on mobile
    // Also handle case where localFilePaths is empty but fileBytes/fileNames provided
    final bool useFileBytes = event.localFilePaths.isEmpty &&
        event.fileBytes != null &&
        event.fileBytes!.isNotEmpty &&
        event.fileNames != null &&
        event.fileNames!.isNotEmpty;

    String extension;
    if ((kIsWeb || useFileBytes) &&
        event.fileNames != null &&
        event.fileNames!.isNotEmpty) {
      extension = event.fileNames!.first.split('.').last.toLowerCase();
    } else {
      // Mobile: extract extension from path
      extension = event.localFilePaths.first.split('.').last.toLowerCase();
    }
    final messageType = _getMessageTypeFromExtension(extension);
    final contentType = _getContentTypeFromExtension(extension);

    // Create attachments with local paths (for immediate display)
    // Cross-platform: use event data on web or when fileBytes provided, File operations on mobile
    final List<MessageAttachment> localAttachments;
    if (useFileBytes) {
      // fileBytes mode: create attachments from bytes (works on any platform)
      localAttachments = List.generate(event.fileBytes!.length, (index) {
        final fileName =
            event.fileNames != null && index < event.fileNames!.length
                ? event.fileNames![index]
                : 'file_$index';
        final fileBytes = Uint8List.fromList(event.fileBytes![index]);
        final fileSize =
            event.fileSizes != null && index < event.fileSizes!.length
                ? event.fileSizes![index]
                : fileBytes.length;

        return MessageAttachment(
          id: 'local_${clientId}_$index',
          url: '',
          type: messageType.toLowerCase(),
          size: fileSize,
          name: fileName,
          localPath: '',
          localBytes: fileBytes,
          uploadProgress: 0.0,
        );
      });
    } else {
      localAttachments = await Future.wait(
        event.localFilePaths.asMap().entries.map((entry) async {
          final index = entry.key;
          final path = entry.value;

          // Get file name - from event on web, from path on mobile
          final fileName = kIsWeb &&
                  event.fileNames != null &&
                  index < event.fileNames!.length
              ? event.fileNames![index]
              : path.split('/').last.split('\\').last;

          // Get file size - from event on web, from File on mobile
          int fileSize = 0;
          if (kIsWeb &&
              event.fileSizes != null &&
              index < event.fileSizes!.length) {
            fileSize = event.fileSizes![index];
          } else if (!kIsWeb) {
            // Mobile only: use dart:io File operations
            final file = File(path);
            fileSize = await file.exists() ? await file.length() : 0;
          }

          // Get file bytes - from event on web (for display during upload)
          Uint8List? fileBytes;
          if (kIsWeb &&
              event.fileBytes != null &&
              index < event.fileBytes!.length) {
            fileBytes = Uint8List.fromList(event.fileBytes![index]);
          }

          return MessageAttachment(
            id: 'local_${clientId}_$index',
            url: '', // Empty - will be filled after upload
            type: messageType.toLowerCase(),
            size: fileSize,
            name: fileName,
            localPath: path,
            localBytes: fileBytes, // Web: bytes for display
            uploadProgress: 0.0, // Starting upload
          );
        }),
      );
    }

    // Step 1: Create optimistic message with sending status and show immediately
    final optimisticMessage = ChatMessage(
      id: draftId,
      clientId: clientId, // Track by clientId for matching
      chatId: currentState.chatId,
      content: event.content,
      contentType: contentType,
      sender: MessageSender(
        id: event.senderId,
        name: '', // Will be filled by transformer
        avatar: null,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      attachments: localAttachments,
      urls: event.localFilePaths, // Use local paths for display
      reactions: const [],
      readBy: const [],
      mentionTo: const [],
      localStatus: MessageStatus.sending, // Optimistic: show as sending
    );

    // Add optimistic message to UI immediately
    var updatedMessages = [optimisticMessage, ...currentState.messages];
    emit(currentState.copyWith(
      messages: updatedMessages,
      uiMessages: _transformMessages(updatedMessages),
    ));

    logger.d('Created optimistic message with clientId: $clientId');

    try {
      // Step 2: Upload all files with progress tracking
      final uploadedUrls = <String>[];
      final int fileCount =
          useFileBytes ? event.fileBytes!.length : event.localFilePaths.length;

      for (var i = 0; i < fileCount; i++) {
        final filePath = !useFileBytes && i < event.localFilePaths.length
            ? event.localFilePaths[i]
            : '';

        // Use bytes when in fileBytes mode or on web
        final bool useBytesForUpload = useFileBytes || kIsWeb;
        final Uint8List? uploadBytes = useBytesForUpload &&
                event.fileBytes != null &&
                i < event.fileBytes!.length
            ? Uint8List.fromList(event.fileBytes![i])
            : null;
        final String? uploadFileName =
            event.fileNames != null && i < event.fileNames!.length
                ? event.fileNames![i]
                : null;

        final result = await _attachmentRepository.uploadAttachment(
          messageId: draftId,
          chatId: currentState.chatId,
          file: useBytesForUpload ? null : File(filePath),
          bytes: uploadBytes,
          fileName: uploadFileName,
          onProgress: (progress) {
            // Update progress for this attachment
            _updateAttachmentProgress(
              emit: emit,
              clientId: clientId,
              attachmentIndex: i,
              progress: progress,
            );
          },
        );

        final url = result.fold(
          (failure) {
            logger.e('Failed to upload file', error: failure);
            throw Exception(failure.message);
          },
          (uploadResult) => uploadResult.url,
        );

        uploadedUrls.add(url);
      }

      logger.i('All files uploaded successfully: ${uploadedUrls.length}');

      // Step 3: Send message with uploaded URLs
      // Get fileName from first file
      final fileName = event.fileNames != null && event.fileNames!.isNotEmpty
          ? event.fileNames!.first
          : event.localFilePaths.isNotEmpty
              ? event.localFilePaths.first.split('/').last.split('\\').last
              : null;

      final result = await _sendMessage(
        conversationId: currentState.chatId,
        content: event.content,
        senderId: event.senderId,
        type: messageType,
        urls: uploadedUrls,
        replyMessageId: event.replyMessageId,
        fileName: fileName,
        receiverId: currentState.receiverId,
      );

      result.fold(
        (failure) {
          logger.e('Failed to send message with attachments', error: failure);
          // Mark message as failed
          _markMessageAsFailed(emit, clientId);
        },
        (message) {
          logger.i(
              'Message sent successfully: ${message.id} (clientId: $clientId)');

          // Step 4: Replace optimistic message with server response
          // Match by clientId to handle rapid sends correctly
          _replaceDraftWithServerMessage(emit, clientId, message);
        },
      );
    } catch (e, stackTrace) {
      logger.e('Error sending message with attachments',
          error: e, stackTrace: stackTrace);
      _markMessageAsFailed(emit, clientId);
    }
  }

  Future<void> _onSendVoiceNote(
    SendVoiceNote event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessagesLoaded) {
      logger.w('Cannot send voice note - messages not loaded');
      return;
    }

    final currentState = state as MessagesLoaded;
    final file = File(event.filePath);
    final fileExists = file.existsSync();
    if (!fileExists) {
      logger.w('Voice note file not found: ${event.filePath}');
      return;
    }

    final isRetry = event.retryDraftMessageId != null;
    ChatMessage? retryDraft;
    if (isRetry) {
      final draftCandidates = currentState.messages
          .where((m) => m.id == event.retryDraftMessageId)
          .toList();
      if (draftCandidates.isNotEmpty) {
        retryDraft = draftCandidates.first;
      }
    }

    const uuid = Uuid();
    final clientId = retryDraft?.clientId ?? uuid.v4();
    final draftId = retryDraft?.id ?? 'draft_$clientId';
    final voiceNoteFileName =
        event.fileName ?? retryDraft?.fileName ?? _buildVoiceNoteFileName();

    ChatMessage? replyMessage;
    if (event.replyMessageId != null && event.replyMessageId!.isNotEmpty) {
      final replyCandidates = currentState.messages
          .where((m) => m.id == event.replyMessageId)
          .toList();
      if (replyCandidates.isNotEmpty) {
        replyMessage = replyCandidates.first;
      }
    }

    int fileSize = 0;
    try {
      fileSize = await file.length();
    } catch (_) {}

    final voiceAttachment = MessageAttachment(
      id: 'local_$clientId',
      url: '',
      type: 'voice_note',
      size: fileSize,
      name: voiceNoteFileName,
      localPath: event.filePath,
      uploadProgress: 0.0,
    );

    List<ChatMessage> updatedMessages;
    if (retryDraft != null) {
      final retryDraftId = retryDraft.id;
      updatedMessages = currentState.messages.map((message) {
        if (message.id != retryDraftId) return message;
        return message.copyWith(
          localStatus: MessageStatus.sending,
          fileName: voiceNoteFileName,
          attachments: [voiceAttachment],
          urls: [event.filePath],
        );
      }).toList();
    } else {
      final optimisticMessage = ChatMessage(
        id: draftId,
        clientId: clientId,
        chatId: currentState.chatId,
        content: '',
        contentType: ContentType.audio,
        sender: MessageSender(
          id: event.senderId,
          name: '',
          avatar: null,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        urls: [event.filePath],
        fileName: voiceNoteFileName,
        replyMessageId: event.replyMessageId,
        replyMessage: replyMessage,
        readBy: const <String>[],
        deliveredTo: const <String>[],
        attachments: [voiceAttachment],
        reactions: const <MessageReaction>[],
        mentionTo: const <MessageSender>[],
        localStatus: MessageStatus.sending,
      );

      updatedMessages = <ChatMessage>[
        optimisticMessage,
        ...currentState.messages,
      ];
    }

    emit(currentState.copyWith(
      messages: updatedMessages,
      uiMessages: _transformMessages(updatedMessages),
    ));

    try {
      final uploadResult = await _attachmentRepository.uploadAttachment(
        messageId: draftId,
        chatId: currentState.chatId,
        file: file,
        fileName: voiceNoteFileName,
        onProgress: (progress) {
          _updateAttachmentProgress(
            emit: emit,
            clientId: clientId,
            attachmentIndex: 0,
            progress: progress,
          );
        },
      );

      final uploadedUrl = uploadResult.fold(
        (failure) {
          throw Exception(failure.message);
        },
        (result) => result.url,
      );

      final sendResult = await _sendMessage(
        conversationId: currentState.chatId,
        content: '',
        senderId: event.senderId,
        type: 'voice_note',
        urls: [uploadedUrl],
        replyMessageId: event.replyMessageId,
        fileName: voiceNoteFileName,
        receiverId: currentState.receiverId,
      );

      await sendResult.fold(
        (failure) async {
          logger.e('Failed to send voice note message', error: failure);
          _markMessageAsFailed(emit, clientId);
        },
        (serverMessage) async {
          final normalizedMessage = _normalizeVoiceNoteMessage(
            serverMessage,
            fileName: voiceNoteFileName,
            fallbackSize: fileSize,
          );
          _replaceDraftWithServerMessage(emit, clientId, normalizedMessage);
          _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
          _cacheSyncStrategy.markChatListDirty();
          await _deleteLocalFile(event.filePath);
        },
      );
    } catch (error, stackTrace) {
      logger.e(
        'Error sending voice note',
        error: error,
        stackTrace: stackTrace,
      );
      _markMessageAsFailed(emit, clientId);
    }
  }

  Future<void> _onRetryVoiceNote(
    RetryVoiceNote event,
    Emitter<MessageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MessagesLoaded) return;

    final failedCandidates = currentState.messages
        .where((m) => m.id == event.draftMessageId)
        .toList();
    final failedMessage =
        failedCandidates.isNotEmpty ? failedCandidates.first : null;

    if (failedMessage == null || failedMessage.status != MessageStatus.failed) {
      return;
    }

    var localPath = failedMessage.attachments
        .map((attachment) => attachment.localPath)
        .whereType<String>()
        .firstWhere(
          (path) => path.trim().isNotEmpty,
          orElse: () => '',
        )
        .trim();
    if (localPath.isEmpty && failedMessage.urls.isNotEmpty) {
      localPath = failedMessage.urls.first;
    }

    if (localPath.isEmpty) {
      logger.w(
        'Retry voice note failed: no local path for draft ${event.draftMessageId}',
      );
      return;
    }

    add(
      SendVoiceNote(
        filePath: localPath,
        senderId: failedMessage.sender.id.isNotEmpty
            ? failedMessage.sender.id
            : _currentUserId,
        durationSeconds: 0,
        replyMessageId: failedMessage.replyMessageId,
        retryDraftMessageId: failedMessage.id,
        fileName: failedMessage.fileName,
      ),
    );
  }

  ChatMessage _normalizeVoiceNoteMessage(
    ChatMessage message, {
    required String fileName,
    required int fallbackSize,
  }) {
    final attachments = message.attachments.isNotEmpty
        ? message.attachments
        : message.urls
            .map(
              (url) => MessageAttachment(
                id: '${message.id}_voice_note',
                url: url,
                type: 'voice_note',
                size: fallbackSize,
                name: fileName,
              ),
            )
            .toList();

    final normalizedAttachments = attachments
        .map(
          (attachment) => attachment.copyWith(
            type: 'voice_note',
            name: attachment.name.isNotEmpty ? attachment.name : fileName,
            size: attachment.size > 0 ? attachment.size : fallbackSize,
            uploadProgress: 1.0,
          ),
        )
        .toList();

    return message.copyWith(
      contentType: ContentType.audio,
      fileName: message.fileName ?? fileName,
      attachments: normalizedAttachments,
    );
  }

  String _buildVoiceNoteFileName() {
    return 'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _deleteLocalFile(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (error, stackTrace) {
      logger.w(
        'Failed to delete local voice note file $path',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Replace draft message with server response, matched by clientId
  void _replaceDraftWithServerMessage(
    Emitter<MessageState> emit,
    String clientId,
    ChatMessage serverMessage,
  ) {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;
    final messages = currentState.messages.map((message) {
      // Match by clientId (not by draftId which could be ambiguous)
      if (message.clientId == clientId) {
        logger.d(
            'Replacing draft (clientId: $clientId) with server message: ${serverMessage.id}');

        // Preserve file size from draft attachments (backend doesn't return size)
        final mergedAttachments =
            serverMessage.attachments.asMap().entries.map((entry) {
          final serverAttachment = entry.value;
          // Find corresponding draft attachment by index or URL
          if (entry.key < message.attachments.length) {
            final draftAttachment = message.attachments[entry.key];
            // If server returns size 0, use the size from draft (read from local file)
            if (serverAttachment.size == 0 && draftAttachment.size > 0) {
              return serverAttachment.copyWith(size: draftAttachment.size);
            }
          }
          return serverAttachment;
        }).toList();

        return serverMessage.copyWith(attachments: mergedAttachments);
      }
      return message;
    }).toList();

    emit(currentState.copyWith(
      messages: messages,
      uiMessages: _transformMessages(messages),
    ));

    // Send push notification if message has mentions (fire-and-forget)
    if (serverMessage.mentionTo.isNotEmpty) {
      final mentionIds = serverMessage.mentionTo.map((m) => m.id).toList();
      final conversationName = _conversationName;

      logger.i(
          'Sending push notification to ${mentionIds.length} mentioned users');

      // Fire-and-forget: don't await, don't block UI
      unawaited(_sendPushNotification.call(
        receiverIds: mentionIds,
        title: conversationName,
        content: serverMessage.content,
        metadata: {
          'conversationId': serverMessage.chatId,
          'messageId': serverMessage.id,
          'type': 'mention',
        },
      ));
    }
  }

  /// Update attachment upload progress (matched by clientId)
  void _updateAttachmentProgress({
    required Emitter<MessageState> emit,
    required String clientId,
    required int attachmentIndex,
    required double progress,
  }) {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;
    final messages = currentState.messages.map((message) {
      // Match by clientId for accurate tracking with rapid sends
      if (message.clientId != clientId) return message;

      final updatedAttachments =
          message.attachments.asMap().entries.map((entry) {
        if (entry.key != attachmentIndex) return entry.value;
        return entry.value.copyWith(uploadProgress: progress);
      }).toList();

      return message.copyWith(attachments: updatedAttachments);
    }).toList();

    emit(currentState.copyWith(
      messages: messages,
      uiMessages: _transformMessages(messages),
    ));
  }

  /// Mark a draft message as failed (matched by clientId)
  void _markMessageAsFailed(Emitter<MessageState> emit, String clientId) {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;
    final messages = currentState.messages.map((message) {
      // Match by clientId for accurate tracking
      if (message.clientId != clientId) return message;
      return message.copyWith(localStatus: MessageStatus.failed);
    }).toList();

    emit(currentState.copyWith(
      messages: messages,
      uiMessages: _transformMessages(messages),
    ));
  }

  /// Get ContentType from file extension
  ContentType _getContentTypeFromExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'heic':
      case 'heif':
        return ContentType.image;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return ContentType.video;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
      case 'ogg':
        return ContentType.audio;
      default:
        return ContentType.file;
    }
  }

  /// **Send location message - CLEAN ARCHITECTURE**
  ///
  /// Handles location sharing:
  /// 1. Get address from coordinates (optional)
  /// 2. Create location data JSON
  /// 3. Send message with type LOCATION
  Future<void> _onSendLocationMessage(
    SendLocationMessage event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessagesLoaded) {
      logger.w('Cannot send location - messages not loaded');
      return;
    }

    final currentState = state as MessagesLoaded;
    logger.i('Sending location message');

    try {
      // Get address from coordinates (optional, for better UX)
      String? locationName = event.locationName;

      if (locationName == null) {
        final addressResult = await _locationService.getAddressFromCoordinates(
          latitude: event.latitude,
          longitude: event.longitude,
        );

        locationName = addressResult.fold(
          (failure) {
            logger.w('Failed to get address');
            return null;
          },
          (address) => address,
        );
      }

      // Create location data JSON
      final locationData = LocationData(
        latitude: event.latitude,
        longitude: event.longitude,
        name: locationName,
        timestamp: DateTime.now(),
      );

      // Send message with type LOCATION
      final result = await _sendMessage(
        conversationId: currentState.chatId,
        content: locationData.toJson(),
        senderId: event.senderId,
        type: 'LOCATION',
        receiverId: currentState.receiverId,
      );

      result.fold(
        (failure) {
          logger.e('Failed to send location message', error: failure);
        },
        (message) {
          logger.i('Location message sent successfully: ${message.id}');

          // Add new message to top of list
          final updatedMessages = [message, ...currentState.messages];
          emit(currentState.copyWith(
            messages: updatedMessages,
            uiMessages: _transformMessages(updatedMessages),
          ));

          // Send push notification if message has mentions (fire-and-forget)
          if (message.mentionTo.isNotEmpty) {
            final mentionIds = message.mentionTo.map((m) => m.id).toList();
            final conversationName = _conversationName;

            logger.i(
                'Sending push notification to ${mentionIds.length} mentioned users');

            // Fire-and-forget: don't await, don't block UI
            unawaited(_sendPushNotification.call(
              receiverIds: mentionIds,
              title: conversationName,
              content: message.content,
              metadata: {
                'conversationId': message.chatId,
                'messageId': message.id,
                'type': 'mention',
              },
            ));
          }
        },
      );
    } catch (e, stackTrace) {
      logger.e('Error sending location message',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Helper: Determine message type from file extension
  String _getMessageTypeFromExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return 'IMAGE';

      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return 'VIDEO';

      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'm4a':
      case 'aac':
        return 'AUDIO';

      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      case 'txt':
        return 'DOC';

      default:
        return 'DOC';
    }
  }

  /// Update conversation members list (dispatched by Page when ConversationDetailBloc emits)
  ///
  /// Re-transforms messages to resolve system event names from updated members
  /// (socket events may arrive before members list is updated)
  void _onUpdateConversationMembers(
    UpdateConversationMembers event,
    Emitter<MessageState> emit,
  ) {
    if (state is MessagesLoaded) {
      final loadedState = state as MessagesLoaded;
      // Update members first, then re-transform so system events resolve names
      final updatedState =
          loadedState.copyWith(conversationMembers: event.members);
      emit(updatedState.copyWith(
        uiMessages: _transformMessagesWithMembers(
          updatedState.messages,
          event.members,
        ),
      ));
      logger.i('[ConvMembers] Updated members: count=${event.members.length}');
    }
  }

  @override
  Future<void> close() async {
    // Cancel debounce timer
    _markAsReadDebouncer?.cancel();

    // Cancel background fetch
    _backgroundFetchOperation?.cancel();

    // Cancel Phase 2 + 3 subscriptions
    _connectionStateSubscription?.cancel();
    _messageEditedSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _messageReactionSubscription?.cancel();
    _readReceiptSubscription?.cancel();

    // Cancel existing Phase 1 subscriptions without leaving rooms.
    // The server should continue broadcasting to the client so ChatBloc
    // (which listens to the global messageStream) can update the chat list.
    for (final chatId in _messageSubscriptions.keys) {
      await _cancelMessageSubscription(chatId, leaveRoom: false);
    }
    _messageSubscriptions.clear();
    return super.close();
  }
}
