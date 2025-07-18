import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

part 'typing_event.dart';
part 'typing_state.dart';

/// **ENTERPRISE TYPING INDICATOR BLOC**
///
/// Manages typing indicators and live chat features with RealtimeService integration
/// and Either<Failure, T> error handling for enterprise-grade reliability.
///
/// **Performance Targets:**
/// - Typing indicator delivery: <50ms
/// - Typing timeout: 3s after last keystroke
/// - Memory usage: <10MB for typing management
/// - Real-time responsiveness: <100ms
///
/// **Architecture**: Clean Architecture + BLoC pattern + Either error handling
@injectable
class TypingBloc extends Bloc<TypingEvent, TypingState> {
  final RealtimeService _realtimeService;
  final Logger _logger = Logger();

  // Active typing timers for auto-stop
  final Map<String, Timer> _typingTimers = {};
  
  // Active subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];
  
  // Currently typing users per chat
  final Map<String, Set<TypingUser>> _typingUsers = {};

  /// Constructor
  TypingBloc({
    required RealtimeService realtimeService,
  }) : _realtimeService = realtimeService,
       super(TypingStateX.initial) {
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<ReceiveTypingIndicator>(_onReceiveTypingIndicator);
    on<JoinChatForTyping>(_onJoinChatForTyping);
    on<LeaveChatForTyping>(_onLeaveChatForTyping);
    on<ClearTypingIndicators>(_onClearTypingIndicators);
    
    _initializeTypingSubscription();
  }

  /// **Start typing indicator - REAL-TIME TYPING**
  ///
  /// **Performance**: <50ms typing indicator emission
  /// **Strategy**: Immediate emission with auto-stop timer
  Future<void> _onStartTyping(
    StartTyping event,
    Emitter<TypingState> emit,
  ) async {
    _logger.t('Starting typing indicator for chat: ${event.chatId}');

    // Cancel existing timer for this chat
    _typingTimers[event.chatId]?.cancel();

    // Send typing indicator to server
    final result = await _realtimeService.sendTypingIndicator(
      chatId: event.chatId,
      isTyping: true,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to send typing indicator: ${failure.message}');
        emit(TypingStateX.error(message: _getErrorMessage(failure)));
      },
      (success) {
        _logger.t('Typing indicator sent successfully');
        
        // Emit typing state
        emit(TypingStateX.typing(chatId: event.chatId));
        
        // Set auto-stop timer (3 seconds)
        _typingTimers[event.chatId] = Timer(const Duration(seconds: 3), () {
          add(StopTyping(chatId: event.chatId));
        });
      },
    );
  }

  /// **Stop typing indicator - REAL-TIME TYPING**
  ///
  /// **Performance**: <50ms typing stop emission
  /// **Strategy**: Immediate stop with timer cleanup
  Future<void> _onStopTyping(
    StopTyping event,
    Emitter<TypingState> emit,
  ) async {
    _logger.t('Stopping typing indicator for chat: ${event.chatId}');

    // Cancel timer
    _typingTimers[event.chatId]?.cancel();
    _typingTimers.remove(event.chatId);

    // Send stop typing indicator to server
    final result = await _realtimeService.sendTypingIndicator(
      chatId: event.chatId,
      isTyping: false,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to send stop typing indicator: ${failure.message}');
        // Don't emit error for stop typing failures
      },
      (success) {
        _logger.t('Stop typing indicator sent successfully');
      },
    );

    // Always emit stopped state locally
    emit(TypingStateX.stopped(chatId: event.chatId));
  }

  /// **Receive typing indicator from other users - REAL-TIME UPDATES**
  ///
  /// **Performance**: <50ms typing indicator processing
  /// **Strategy**: Immediate state update with user management
  Future<void> _onReceiveTypingIndicator(
    ReceiveTypingIndicator event,
    Emitter<TypingState> emit,
  ) async {
    final indicator = event.indicator;
    _logger.t('Received typing indicator: ${indicator.userId} - ${indicator.isTyping} in ${indicator.chatId}');

    // Get current typing users for this chat
    final chatTypingUsers = _typingUsers[indicator.chatId] ?? <TypingUser>{};
    
    final typingUser = TypingUser(
      userId: indicator.userId,
      userName: indicator.userName,
    );

    if (indicator.isTyping) {
      // Add user to typing list
      chatTypingUsers.add(typingUser);
      _typingUsers[indicator.chatId] = chatTypingUsers;
      
      emit(TypingStateX.usersTyping(
        chatId: indicator.chatId,
        typingUsers: chatTypingUsers.toList(),
      ));
    } else {
      // Remove user from typing list
      chatTypingUsers.removeWhere((user) => user.userId == indicator.userId);
      _typingUsers[indicator.chatId] = chatTypingUsers;
      
      if (chatTypingUsers.isEmpty) {
        emit(TypingStateX.noOneTyping(chatId: indicator.chatId));
      } else {
        emit(TypingStateX.usersTyping(
          chatId: indicator.chatId,
          typingUsers: chatTypingUsers.toList(),
        ));
      }
    }
  }

  /// **Join chat for typing indicators - ROOM MANAGEMENT**
  ///
  /// **Performance**: <500ms room join
  /// **Strategy**: Real-time service room management
  Future<void> _onJoinChatForTyping(
    JoinChatForTyping event,
    Emitter<TypingState> emit,
  ) async {
    _logger.i('Joining chat for typing indicators: ${event.chatId}');

    final result = await _realtimeService.joinChatRoom(event.chatId);

    result.fold(
      (failure) {
        _logger.e('Failed to join chat for typing: ${failure.message}');
        emit(TypingStateX.error(message: _getErrorMessage(failure)));
      },
      (success) {
        _logger.i('Successfully joined chat for typing: ${event.chatId}');
        emit(TypingStateX.joined(chatId: event.chatId));
      },
    );
  }

  /// **Leave chat for typing indicators - ROOM CLEANUP**
  ///
  /// **Performance**: <500ms room leave
  /// **Strategy**: Clean room exit with state cleanup
  Future<void> _onLeaveChatForTyping(
    LeaveChatForTyping event,
    Emitter<TypingState> emit,
  ) async {
    _logger.i('Leaving chat for typing indicators: ${event.chatId}');

    // Cancel any active typing timer
    _typingTimers[event.chatId]?.cancel();
    _typingTimers.remove(event.chatId);

    // Clear typing users for this chat
    _typingUsers.remove(event.chatId);

    final result = await _realtimeService.leaveChatRoom(event.chatId);

    result.fold(
      (failure) {
        _logger.e('Failed to leave chat for typing: ${failure.message}');
        // Don't emit error for leave failures
      },
      (success) {
        _logger.i('Successfully left chat for typing: ${event.chatId}');
      },
    );

    // Always emit left state locally
    emit(TypingStateX.left(chatId: event.chatId));
  }

  /// **Clear typing indicators for chat - STATE CLEANUP**
  ///
  /// **Performance**: <50ms state cleanup
  /// **Strategy**: Immediate local state cleanup
  Future<void> _onClearTypingIndicators(
    ClearTypingIndicators event,
    Emitter<TypingState> emit,
  ) async {
    _logger.t('Clearing typing indicators for chat: ${event.chatId}');

    // Cancel timer
    _typingTimers[event.chatId]?.cancel();
    _typingTimers.remove(event.chatId);

    // Clear typing users
    _typingUsers.remove(event.chatId);

    // Emit cleared state
    emit(TypingStateX.noOneTyping(chatId: event.chatId));
  }

  /// **Initialize typing indicator subscription - ENTERPRISE REAL-TIME**
  void _initializeTypingSubscription() {
    _logger.i('Initializing typing indicator subscription');

    // Subscribe to typing indicators from real-time service
    _subscriptions.add(
      _realtimeService.typingStream.listen(
        (indicator) {
          add(ReceiveTypingIndicator(indicator: indicator));
        },
        onError: (error) {
          _logger.e('Error in typing indicator stream: $error');
        },
      ),
    );

    _logger.i('Typing indicator subscription initialized');
  }

  /// **Helper method to convert Failure to user-friendly error message**
  String _getErrorMessage(Failure failure) {
    if (failure is ConnectionFailure) {
      return 'Không có kết nối internet. Typing indicator có thể không hoạt động.';
    } else if (failure is ServerFailure) {
      return 'Lỗi server. Typing indicator có thể không hoạt động.';
    } else {
      return failure.message.isNotEmpty
          ? failure.message
          : 'Lỗi typing indicator không xác định.';
    }
  }

  @override
  Future<void> close() {
    _logger.i('Closing TypingBloc');

    // Cancel all timers
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();

    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Clear typing users
    _typingUsers.clear();

    return super.close();
  }
}

/// **Typing user data class**
class TypingUser extends Equatable {
  final String userId;
  final String userName;

  const TypingUser({
    required this.userId,
    required this.userName,
  });

  @override
  List<Object> get props => [userId, userName];
}
