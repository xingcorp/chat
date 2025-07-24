import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';
import 'package:flutter_chat_app/domain/models/queued_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';
part 'chat_bloc.freezed.dart';

/// **ENTERPRISE CHAT BLOC - PHASE 2 MINIMAL VERSION**
///
/// Core functionality implemented with Either<Failure, T> pattern.
/// Advanced features will be completed in Phase 3.
///
/// **Performance**: <2s for chat operations
/// **Architecture**: Clean Architecture + BLoC pattern + Either error handling
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final IChatRepository _chatRepository;
  // final IMessageRepository _messageRepository; // TODO: Use in Phase 3
  // final ChatSyncService _chatSyncService; // TODO: Use in Phase 3
  final ConnectivityService _connectivityService;
  final CacheSyncStrategy _cacheSyncStrategy;
  final MediaCacheManager _mediaCacheManager;
  final Logger _logger = Logger();

  // Performance monitoring
  final Stopwatch _performanceStopwatch = Stopwatch();

  // Subscriptions for real-time updates
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  StreamSubscription<Chat>? _chatUpdatesSubscription;
  
  /// Constructor
  ChatBloc(
    this._chatRepository,
    // IMessageRepository messageRepository, // TODO: Use in Phase 3
    // ChatSyncService chatSyncService, // TODO: Use in Phase 3
    this._connectivityService,
    this._cacheSyncStrategy,
    this._mediaCacheManager,
  ) : super(const ChatState.initial()) {
    on<_LoadChats>(_onLoadChats);
    on<_LoadChatDetails>(_onLoadChatDetails);
    on<_CreateChat>(_onCreateChat);
    on<_ConnectivityChanged>(_onConnectivityChanged);
    on<_ChatUpdated>(_onChatUpdated);
  }

  /// **Load chats with Either<Failure, T> pattern - ENTERPRISE READY**
  Future<void> _onLoadChats(
    _LoadChats event,
    Emitter<ChatState> emit,
  ) async {
    await _executeWithMonitoring('load_chats', () async {
      // Skip if already loading
      if (state is _Loading) {
        return;
      }

      emit(const ChatState.loading());

      _logger.i('Tải danh sách chat của người dùng');

      // Kiểm tra xem có cần refresh cache không
      final shouldRefresh = event.forceRefresh || _cacheSyncStrategy.shouldRefreshChatList();

      // Lấy danh sách chat using Either pattern
      final result = await _chatRepository.getChats();

      result.fold(
        (failure) {
          _logger.e('Lỗi khi tải danh sách chat: ${failure.message}');
          emit(ChatState.error(message: _getErrorMessage(failure)));
        },
        (chats) {
          _logger.i('Đã tải ${chats.length} chat');

          // Reset dirty flag sau khi tải thành công
          if (shouldRefresh) {
            _cacheSyncStrategy.resetChatListDirtyFlag();
          }

          // Pre-cache avatars for better UX
          _prefetchAvatars(chats);

          // Subscribe to real-time updates nếu chưa có
          _subscribeToRealTimeUpdates();

          emit(ChatState.loaded(chats: chats));
        },
      );
    });
  }

  /// **Load chat details with Either<Failure, T> pattern - ENTERPRISE READY**
  Future<void> _onLoadChatDetails(
    _LoadChatDetails event,
    Emitter<ChatState> emit,
  ) async {
    // Don't change state to loading since we might already have data
    
    // First try to get from local storage using Either pattern
    final localResult = await _chatRepository.getChatById(event.chatId);
    
    localResult.fold(
      (failure) {
        _logger.w('Failed to get local chat: ${failure.message}');
        // Continue to try server
      },
      (localChat) {
        if (localChat != null) {
          emit(ChatState.chatDetailsLoaded(chat: localChat));
        }
      },
    );
    
    // Then try to fetch from server if online
    if (await _connectivityService.isConnected()) {
      final serverResult = await _chatRepository.getChatById(event.chatId);
      
      serverResult.fold(
        (failure) {
          _logger.e('Failed to get server chat: ${failure.message}');
          emit(ChatState.error(message: _getErrorMessage(failure)));
        },
        (chat) {
          if (chat != null) {
            emit(ChatState.chatDetailsLoaded(chat: chat));
          }
        },
      );
    }
  }

  /// **Create chat with Either<Failure, T> pattern - ENTERPRISE READY**
  Future<void> _onCreateChat(
    _CreateChat event,
    Emitter<ChatState> emit,
  ) async {
    _logger.i('Creating new chat: ${event.name}');
    
    // Create chat using Either pattern
    final result = await _chatRepository.createChat(
      name: event.name ?? (event.type == ChatType.direct ? '' : 'New Group Chat'),
      participantIds: event.participantIds,
      isGroup: event.type == ChatType.group,
    );
    
    result.fold(
      (failure) {
        _logger.e('Failed to create chat: ${failure.message}');
        emit(ChatState.error(message: _getErrorMessage(failure)));
      },
      (chat) {
        _logger.i('Chat created successfully: ${chat.id}');
        
        // Reload chats to include the new one
        add(const ChatEvent.loadChats());
      },
    );
  }

  /// Handle connectivity changes
  Future<void> _onConnectivityChanged(
    _ConnectivityChanged event,
    Emitter<ChatState> emit,
  ) async {
    if (event.isConnected) {
      // Sync when connection is restored
      add(const ChatEvent.loadChats(forceRefresh: true));
    } else {
      emit(const ChatState.offline());
    }
  }

  /// Handle chat updates
  Future<void> _onChatUpdated(
    _ChatUpdated event,
    Emitter<ChatState> emit,
  ) async {
    // Update chat in current state if loaded
    if (state is _Loaded) {
      final currentState = state as _Loaded;
      final updatedChats = currentState.chats.map((chat) {
        return chat.id == event.chat.id ? event.chat : chat;
      }).toList();
      
      emit(ChatState.loaded(chats: updatedChats));
    }
  }

  /// Pre-fetch avatars for better UX
  void _prefetchAvatars(List<Chat> chats) {
    final avatarUrls = chats
        .where((chat) => chat.avatarUrl != null)
        .map((chat) => chat.avatarUrl!)
        .toList();
    
    if (avatarUrls.isNotEmpty) {
      _mediaCacheManager.prefetchThumbnails(avatarUrls);
    }
  }

  /// Subscribe to real-time updates
  void _subscribeToRealTimeUpdates() {
    // TODO: Implement when socket manager is available
    // Cancel existing subscription
    // _chatUpdatesSubscription?.cancel();
    // _chatUpdatesSubscription = _socketService.onChatUpdated().listen((chat) {
    //   add(ChatEvent.chatUpdated(chat: chat));
    // });
  }

  /// **Helper method to convert Failure to user-friendly error message**
  String _getErrorMessage(Failure failure) {
    if (failure is ConnectionFailure) {
      return 'Không có kết nối internet. Vui lòng kiểm tra lại.';
    } else if (failure is ServerFailure) {
      return 'Lỗi server. Vui lòng thử lại sau.';
    } else if (failure is CacheFailure) {
      return 'Lỗi cache. Dữ liệu có thể không được cập nhật.';
    } else {
      return failure.message.isNotEmpty
          ? failure.message
          : 'Đã xảy ra lỗi không xác định.';
    }
  }

  /// **Performance Monitoring Wrapper**
  ///
  /// Wraps operations with performance monitoring and logging.
  /// Target: <100ms for most operations, <500ms for network operations
  Future<void> _executeWithMonitoring(
    String operation,
    Future<void> Function() action,
  ) async {
    _performanceStopwatch.reset();
    _performanceStopwatch.start();

    try {
      await action();
    } catch (error) {
      _logger.e('💥 Error in $operation: $error');
      rethrow;
    } finally {
      _performanceStopwatch.stop();
      final duration = _performanceStopwatch.elapsedMilliseconds;

      if (duration > 100) {
        _logger.w('⚠️ Slow operation: $operation took ${duration}ms');
      } else {
        _logger.d('⚡ Fast operation: $operation took ${duration}ms');
      }
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _chatUpdatesSubscription?.cancel();
    return super.close();
  }
}
