import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/services/chat_sync_service.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';
import 'package:flutter_chat_app/domain/models/queued_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';
part 'chat_bloc.freezed.dart';

/// BLoC for managing chat state and operations
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final IChatRepository _chatRepository;
  final IMessageRepository _messageRepository;
  final ChatSyncService _chatSyncService;
  final ConnectivityService _connectivityService;
  
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectivitySubscription;
  
  /// Constructor
  ChatBloc(
    this._chatRepository,
    this._messageRepository,
    this._chatSyncService,
    this._connectivityService,
  ) : super(const ChatState.initial()) {
    on<_LoadChats>(_onLoadChats);
    on<_LoadChatDetails>(_onLoadChatDetails);
    on<_LoadMessages>(_onLoadMessages);
    on<_SendMessage>(_onSendMessage);
    on<_CreateChat>(_onCreateChat);
    on<_UpdateChat>(_onUpdateChat);
    on<_LeaveChat>(_onLeaveChat);
    on<_AddUsersToChat>(_onAddUsersToChat);
    on<_RemoveUsersFromChat>(_onRemoveUsersFromChat);
    on<_MarkMessagesAsRead>(_onMarkMessagesAsRead);
    on<_SyncChats>(_onSyncChats);
    on<_SyncMessages>(_onSyncMessages);
    on<_NewMessageReceived>(_onNewMessageReceived);
    on<_ConnectivityChanged>(_onConnectivityChanged);
    
    // Listen for new messages from repository
    if (_messageRepository is MessageStreamProvider) {
      final provider = _messageRepository as MessageStreamProvider;
      _messageSubscription = provider.messageStream.listen((message) {
        add(ChatEvent.newMessageReceived(message));
      });
    }
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((connectivityResults) {
      // Extract actual connectivity status from the results
      final isConnected = connectivityResults.any((result) => result != ConnectivityResult.none);
      add(ChatEvent.connectivityChanged(isConnected));
    });
  }
  
  /// Handle loading chats
  Future<void> _onLoadChats(
    _LoadChats event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatState.loading());
    
    try {
      // First try to get from local storage for instant response
      final localChats = await _chatRepository.getChatsFromLocalStorage();
      
      if (localChats.isNotEmpty) {
        emit(ChatState.loaded(chats: localChats));
      }
      
      // Then try to fetch from server if online
      if (await _connectivityService.checkConnected()) {
        final chats = await _chatRepository.getChats();
        emit(ChatState.loaded(chats: chats));
      }
    } catch (e) {
      emit(ChatState.error(message: 'Failed to load chats: $e'));
    }
  }
  
  /// Handle loading chat details
  Future<void> _onLoadChatDetails(
    _LoadChatDetails event,
    Emitter<ChatState> emit,
  ) async {
    // Don't change state to loading since we might already have data
    
    try {
      // First try to get from local storage
      final localChat = await _chatRepository.getChatById(event.chatId);
      
      if (localChat != null) {
        emit(ChatState.chatDetailsLoaded(chat: localChat));
      }
      
      // Then try to fetch from server if online
      if (await _connectivityService.checkConnected()) {
        final chat = await _chatRepository.getChatById(event.chatId);
        if (chat != null) {
          emit(ChatState.chatDetailsLoaded(chat: chat));
        }
      }
    } catch (e) {
      emit(ChatState.error(message: 'Failed to load chat details: $e'));
    }
  }
  
  /// Handle loading messages
  Future<void> _onLoadMessages(
    _LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    // Get current state to preserve chats
    final currentState = state;
    List<Chat>? currentChats;
    
    if (currentState is _Loaded) {
      currentChats = currentState.chats;
    }
    
    emit(ChatState.messagesLoading(chats: currentChats));
    
    try {
      // First try to get from local storage
      final localMessages = await _messageRepository.getMessages(event.chatId);
      
      if (localMessages.isNotEmpty) {
        emit(ChatState.messagesLoaded(
          chats: currentChats,
          chatId: event.chatId,
          messages: localMessages,
        ));
      }
      
      // Then try to fetch from server if online
      if (await _connectivityService.checkConnected()) {
        final messages = await _messageRepository.getMessages(
          event.chatId,
          limit: event.limit,
        );
        
        emit(ChatState.messagesLoaded(
          chats: currentChats,
          chatId: event.chatId,
          messages: messages,
        ));
      }
    } catch (e) {
      emit(ChatState.error(message: 'Failed to load messages: $e'));
    }
  }
  
  /// Handle sending a message
  Future<void> _onSendMessage(
    _SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final message = await _messageRepository.sendMessage(
        chatId: event.chatId,
        content: event.content,
        contentType: event.contentType.toString().split('.').last,
        senderId: 'current_user', // This should ideally come from authentication service
        attachmentIds: event.attachmentIds,
      );
      
      // Update the local chat to have this as the last message
      final chat = await _chatRepository.getChatById(event.chatId);
      if (chat != null) {
        final updatedChat = chat.copyWith(
          lastMessage: message,
          updatedAt: DateTime.now(),
        );
        await _chatRepository.saveChatLocally(updatedChat);
      }
      
      // Synchronize chats to make sure they're up to date
      await _chatSyncService.syncAllChats();
    } catch (e) {
      emit(ChatState.error(message: 'Failed to send message: $e'));
    }
  }
  
  /// Handle creating a new chat
  Future<void> _onCreateChat(
    _CreateChat event,
    Emitter<ChatState> emit,
  ) async {
    try {
      late final Chat chat;
      
      if (event.type == ChatType.direct) {
        // For direct chats, use the appropriate method
        chat = await _chatRepository.createChat(
          name: event.name ?? '',
          participantIds: event.participantIds,
          isGroup: false,
        );
      } else {
        // For group chats
        chat = await _chatRepository.createChat(
          name: event.name ?? 'New Group Chat',
          participantIds: event.participantIds,
          isGroup: true,
        );
      }
      
      // Reload chats to include the new one
      add(const ChatEvent.loadChats());
    } catch (e) {
      emit(ChatState.error(message: 'Failed to create chat: $e'));
    }
  }
  
  /// Handle updating a chat
  Future<void> _onUpdateChat(
    _UpdateChat event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.updateChat(
        chatId: event.chatId,
        name: event.name,
        avatarUrl: event.avatar,
      );
      
      // Reload chat details
      add(ChatEvent.loadChatDetails(chatId: event.chatId));
    } catch (e) {
      emit(ChatState.error(message: 'Failed to update chat: $e'));
    }
  }
  
  /// Handle leaving a chat
  Future<void> _onLeaveChat(
    _LeaveChat event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final success = await _chatRepository.leaveChat(event.chatId);
      
      if (success) {
        // Reload chats to exclude the one left
        add(const ChatEvent.loadChats());
      }
    } catch (e) {
      emit(ChatState.error(message: 'Failed to leave chat: $e'));
    }
  }
  
  /// Handle adding users to a chat
  Future<void> _onAddUsersToChat(
    _AddUsersToChat event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.addParticipants(
        chatId: event.chatId,
        userIds: event.userIds,
      );
      
      // Reload chat details
      add(ChatEvent.loadChatDetails(chatId: event.chatId));
    } catch (e) {
      emit(ChatState.error(message: 'Failed to add users to chat: $e'));
    }
  }
  
  /// Handle removing users from a chat
  Future<void> _onRemoveUsersFromChat(
    _RemoveUsersFromChat event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.removeParticipants(
        chatId: event.chatId,
        userIds: event.userIds,
      );
      
      // Reload chat details
      add(ChatEvent.loadChatDetails(chatId: event.chatId));
    } catch (e) {
      emit(ChatState.error(message: 'Failed to remove users from chat: $e'));
    }
  }
  
  /// Handle marking messages as read
  Future<void> _onMarkMessagesAsRead(
    _MarkMessagesAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Mark all messages in the chat as read
      await _messageRepository.markChatAsRead(event.chatId);
      
      // Reload messages to update read status
      add(ChatEvent.loadMessages(chatId: event.chatId));
    } catch (e) {
      emit(ChatState.error(message: 'Failed to mark messages as read: $e'));
    }
  }
  
  /// Handle synchronizing all chats
  Future<void> _onSyncChats(
    _SyncChats event,
    Emitter<ChatState> emit,
  ) async {
    if (!await _connectivityService.checkConnected()) {
      emit(const ChatState.offline());
      return;
    }
    
    emit(const ChatState.syncing());
    
    try {
      await _chatSyncService.syncAllChats();
      
      // Reload chats
      add(const ChatEvent.loadChats());
    } catch (e) {
      emit(ChatState.error(message: 'Failed to sync chats: $e'));
    }
  }
  
  /// Handle synchronizing messages for a specific chat
  Future<void> _onSyncMessages(
    _SyncMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (!await _connectivityService.checkConnected()) {
      emit(const ChatState.offline());
      return;
    }
    
    try {
      await _chatSyncService.syncChatMessages(event.chatId);
      
      // Reload messages
      add(ChatEvent.loadMessages(chatId: event.chatId));
    } catch (e) {
      emit(ChatState.error(message: 'Failed to sync messages: $e'));
    }
  }
  
  /// Handle receiving a new message
  Future<void> _onNewMessageReceived(
    _NewMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    // Get current state
    final currentState = state;
    
    if (currentState is _MessagesLoaded && 
        currentState.chatId == event.message.chatId) {
      // If we're currently viewing the chat this message belongs to, update messages
      final updatedMessages = List<ChatMessage>.from(currentState.messages)
        ..add(event.message)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      emit(ChatState.messagesLoaded(
        chats: currentState.chats,
        chatId: currentState.chatId,
        messages: updatedMessages,
      ));
      
      // Mark this message as read if it's not from the current user
      // In a real app, you'd check if the sender is not the current user
      await _messageRepository.markAsRead(event.message.id);
    } else if (currentState is _Loaded || currentState is _ChatDetailsLoaded) {
      // If we're viewing the chat list, update it to show the new message
      add(const ChatEvent.loadChats());
    }
  }
  
  /// Handle connectivity changes
  Future<void> _onConnectivityChanged(
    _ConnectivityChanged event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    
    if (event.isConnected) {
      // When connection is restored, sync data
      if (currentState is _Offline) {
        add(const ChatEvent.syncChats());
      }
    } else {
      // When offline, emit offline state
      emit(const ChatState.offline());
    }
  }
  
  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}

/// Mixin to provide message stream for repositories
mixin MessageStreamProvider {
  /// Stream of incoming messages
  Stream<ChatMessage> get messageStream;
} 