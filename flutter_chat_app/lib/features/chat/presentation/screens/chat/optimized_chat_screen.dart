import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// TODO: Removed MediaService - use MediaRepository through MediaBloc instead
// import 'package:flutter_chat_app/core/services/media_service.dart';
import 'package:flutter_chat_app/core/utils/isolate_manager.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_list_transformer.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/message_item.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:get_it/get_it.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// Extension for backward compatibility with MessagesLoaded state checks
extension ChatStateExtension on ChatState {
  /// Check if current state is messagesLoaded (backward compatibility)
  bool get isMessagesLoaded => whenOrNull(messagesLoaded: (_, __, ___) => true) ?? false;

  /// Check if current state is loading (backward compatibility)
  bool get isLoading => whenOrNull(loading: () => true) ?? false;

  /// Check if current state is error (backward compatibility)
  bool get isError => whenOrNull(error: (_) => true) ?? false;

  /// Get error message (backward compatibility)
  String? get errorMessage => whenOrNull(error: (message) => message);

  /// Get messages for a specific chat ID (backward compatibility)
  List<ChatMessage> getMessagesForChat(String chatId) {
    return whenOrNull(
      messagesLoaded: (chats, currentChatId, messages) {
        return currentChatId == chatId ? messages : [];
      },
    ) ?? [];
  }

  /// Get chats list (backward compatibility)
  List<Chat> get chats {
    return whenOrNull(
      loaded: (chats) => chats,
      messagesLoaded: (chats, _, __) => chats ?? [],
    ) ?? [];
  }

  /// Get current chat ID from messagesLoaded state
  String? get currentChatId {
    return whenOrNull(
      messagesLoaded: (_, chatId, __) => chatId,
    );
  }
}

/// Backward compatibility class for MessagesLoaded state checks
class MessagesLoaded {
  final List<Chat>? chats;
  final String chatId;
  final List<ChatMessage> messages;
  final Map<String, List<ChatMessage>> messagesByChatId;

  MessagesLoaded({
    this.chats,
    required this.chatId,
    required this.messages,
  }) : messagesByChatId = {chatId: messages};

  /// Create from ChatState
  static MessagesLoaded? fromChatState(ChatState state) {
    return state.whenOrNull(
      messagesLoaded: (chats, chatId, messages) => MessagesLoaded(
        chats: chats,
        chatId: chatId,
        messages: messages,
      ),
    );
  }
}

class OptimizedChatScreen extends StatefulWidget {
  final String chatId;

  const OptimizedChatScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  State<OptimizedChatScreen> createState() => _OptimizedChatScreenState();
}

class _OptimizedChatScreenState extends State<OptimizedChatScreen> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = AutoScrollController();
  final _isolateManager = GetIt.I<IsolateManager>();
  // TODO: MediaService has been deprecated, use MediaRepository instead
  // final _mediaService = GetIt.I<MediaService>();
  
  bool _isAttachmentMenuOpen = false;
  bool _isRecording = false;
  bool _isTyping = false;
  bool _isLoadingMessages = false;
  String? _replyToMessageId;
  
  // Cached build methods to prevent unnecessary rebuilds
  final Map<String, Widget> _cachedMessageItems = {};
  
  // Memoized widget lists
  List<ChatMessage>? _previousMessages;
  List<Widget>? _cachedMessageWidgets;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialMessages();
    _initializeIsolateManager();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _clearCache();
    super.dispose();
  }
  
  void _clearCache() {
    _cachedMessageItems.clear();
    _cachedMessageWidgets = null;
    _previousMessages = null;
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // TODO: Implement proper mark chat as read with message IDs
      // context.read<ChatBloc>().add(ChatEvent.markMessagesAsRead(chatId: widget.chatId, messageIds: []));
    }
  }
  
  Future<void> _initializeIsolateManager() async {
    await _isolateManager.initialize();
  }
  
  void _loadInitialMessages() {
    context.read<ChatBloc>().add(ChatEvent.loadMessages(
      chatId: widget.chatId,
      limit: 30,
    ));
    
    // Mark chat as read when opened
    // TODO: Implement proper mark chat as read with message IDs
    // context.read<ChatBloc>().add(ChatEvent.markMessagesAsRead(chatId: widget.chatId, messageIds: []));
  }
  
  void _loadMoreMessages() {
    if (_isLoadingMessages) return;
    
    setState(() {
      _isLoadingMessages = true;
    });
    
    final chatBloc = context.read<ChatBloc>();
    final currentState = chatBloc.state;
    
    currentState.whenOrNull(
      messagesLoaded: (chats, chatId, messages) {
        if (messages.isNotEmpty) {
          chatBloc.add(ChatEvent.loadMessages(
            chatId: widget.chatId,
            limit: 30,
            offset: messages.length, // Use offset instead of beforeMessageId
          ));
        }
      },
    );
    
    // Reset loading state after a delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    });
  }
  
  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty && !_isRecording) return;
    
    // Clear text field immediately for better UX
    _messageController.clear();
    
    if (_isRecording) {
      _stopRecordingAndSend();
    } else {
      context.read<ChatBloc>().add(ChatEvent.sendMessage(
        chatId: widget.chatId,
        content: messageText,
        contentType: ContentType.text,
        // TODO: Implement reply functionality
      ));
    }
    
    // Clear reply
    setState(() {
      _replyToMessageId = null;
    });
  }
  
  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    
    // Implement audio recording logic here
  }
  
  void _stopRecordingAndSend() {
    setState(() {
      _isRecording = false;
    });
    
    // Implement logic to stop recording and send audio message
  }
  
  void _handleAttachmentSelection(ContentType type) {
    setState(() {
      _isAttachmentMenuOpen = false;
    });
    
    // Process attachment selection in isolate if needed
    _isolateManager.processInBackground(
      taskType: IsolateTaskType.fileOperation,
      data: {'type': type.toString()},
      params: {'chatId': widget.chatId},
    ).then((result) {
      if (result.isSuccess && result.result != null) {
        // Handle the processed attachment
        final attachmentInfo = result.result as Map<String, dynamic>;
        
        // Now send the message with attachment
        context.read<ChatBloc>().add(ChatEvent.sendMessage(
          chatId: widget.chatId,
          content: '',
          contentType: type,
          attachmentIds: [attachmentInfo['path']], // Use attachmentIds instead of attachments
          // TODO: Implement reply functionality
        ));
        
        // Clear reply
        setState(() {
          _replyToMessageId = null;
        });
      }
    });
  }
  
  void _handleMessageTap(ChatMessage message) {
    // Implement message tap handling
  }
  
  void _handleMessageLongPress(ChatMessage message) {
    // Show message options menu (reply, forward, delete, etc.)
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildMessageOptionsSheet(message),
    );
  }
  
  Widget _buildMessageOptionsSheet(ChatMessage message) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: Text(context.l10n.reply),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _replyToMessageId = message.id;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward),
            title: Text(context.l10n.forward),
            onTap: () {
              Navigator.pop(context);
              // Implement forward logic
            },
          ),
          if (message.isFromCurrentUser)
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text(context.l10n.delete, style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteMessage(message);
              },
            ),
        ],
      ),
    );
  }
  
  void _confirmDeleteMessage(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.delete),
        content: Text(context.l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement proper message deletion
              // Would need MessageBloc or different approach
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chức năng xóa tin nhắn chưa được triển khai')),
              );
            },
            child: Text(context.l10n.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // Memoize message item widgets to prevent unnecessary rebuilds
  List<Widget> _buildMessageList(List<ChatMessage> messages, String currentUserId) {
    // Return cached list if messages haven't changed
    if (_previousMessages != null && 
        _cachedMessageWidgets != null && 
        _areSameMessages(_previousMessages!, messages)) {
      return _cachedMessageWidgets!;
    }
    
    final chatState = context.read<ChatBloc>().state;
    final isGroupChat = chatState.whenOrNull(
          messagesLoaded: (chats, chatId, messages) {
            return chats
                    ?.firstWhere(
                      (c) => c.id == widget.chatId,
                      orElse: () => Chat(id: widget.chatId),
                    )
                    .type ==
                ChatType.group;
          },
        ) ??
        false;

    final uiStates = MessageListTransformer.transform(
      messages: messages,
      currentUserId: currentUserId,
      isGroupChat: isGroupChat,
    );
    
    final widgets = List<Widget>.generate(messages.length, (index) {
      final message = messages[index];
      final uiState = uiStates[index];
      // Use cached widget if available
      if (_cachedMessageItems.containsKey(message.id) && message.status != MessageStatus.sending) {
        return _cachedMessageItems[message.id]!;
      }
      
      // Build and cache new message widget
      final messageWidget = MessageItem(
        key: ValueKey('message_${message.id}'),
        uiState: uiState,
        onTap: () => _handleMessageTap(message),
        onLongPress: () => _handleMessageLongPress(message),
        onReplyPreviewTap: uiState.replyMessage != null
            ? () {
                final targetIndex = messages.indexWhere(
                  (m) => m.id == uiState.replyMessage!.originalMessageId,
                );
                if (targetIndex < 0) return;
                _scrollController.scrollToIndex(
                  targetIndex,
                  preferPosition: AutoScrollPosition.middle,
                  duration: const Duration(milliseconds: 250),
                );
              }
            : null,
      );
      
      // Only cache non-sending messages (since they might update)
      if (message.status != MessageStatus.sending) {
        _cachedMessageItems[message.id] = messageWidget;
      }
      
      return messageWidget;
    });
    
    // Cache for future use
    _previousMessages = List.from(messages);
    _cachedMessageWidgets = widgets;
    
    return widgets;
  }
  
  // Helper to compare message lists
  bool _areSameMessages(List<ChatMessage> previous, List<ChatMessage> current) {
    if (previous.length != current.length) return false;
    
    for (int i = 0; i < previous.length; i++) {
      final prev = previous[i];
      final curr = current[i];
      
      if (prev.id != curr.id || 
          prev.status != curr.status || 
          prev.status != curr.status) {
        return false;
      }
    }
    
    return true;
  }
  
  // Use RepaintBoundary for input area to prevent entire screen rebuild
  Widget _buildInputArea() {
    return RepaintBoundary(
      child: Container(
        // Existing input area code...
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : '';

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ChatBloc, ChatState>(
          buildWhen: (previous, current) {
            if (previous.isMessagesLoaded && current.isMessagesLoaded) {
              return previous.getMessagesForChat(widget.chatId) !=
                     current.getMessagesForChat(widget.chatId);
            }
            return true;
          },
          builder: (context, state) {
            if (state.isMessagesLoaded) {
              final chat = state.chats.firstWhere(
                (c) => c.id == widget.chatId,
                orElse: () => Chat(
                  id: widget.chatId,
                  name: 'Chat',
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat.name ?? context.l10n.chats, style: const TextStyle(fontSize: 16)),
                  // Note: isTyping property not available in current Chat entity
                  // if (chat.isTyping)
                  //   const Text(
                  //     'Typing...',
                  //     style: TextStyle(fontSize: 12),
                  //   ),
                ],
              );
            }

            return Text(context.l10n.chats);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // Implement voice call
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // Implement video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show chat options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Reply preview
          if (_replyToMessageId != null)
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.isMessagesLoaded) {
                  final messages = state.getMessagesForChat(widget.chatId);
                  final replyMessage = messages.firstWhere(
                    (m) => m.id == _replyToMessageId,
                    orElse: () => null as ChatMessage,
                  );
                  
                  if (replyMessage != null) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.grey.shade200,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Trả lời ${replyMessage.senderName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  replyMessage.content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _replyToMessageId = null;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }
                }
                
                return const SizedBox.shrink();
              },
            ),
          
          // Messages list
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (previous, current) {
                if (previous.isMessagesLoaded && current.isMessagesLoaded) {
                  return previous.getMessagesForChat(widget.chatId) !=
                         current.getMessagesForChat(widget.chatId);
                }
                return true;
              },
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.isError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Lỗi: ${state.errorMessage ?? "Lỗi không xác định"}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadInitialMessages,
                          child: Text(context.l10n.retry),
                        ),
                      ],
                    ),
                  );
                }
                
                final List<ChatMessage> messages;
                if (state.isMessagesLoaded) {
                  messages = state.getMessagesForChat(widget.chatId);
                } else {
                  messages = [];
                }
                
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Chưa có tin nhắn nào. Hãy bắt đầu cuộc trò chuyện!'),
                  );
                }
                
                final chatState = context.read<ChatBloc>().state;
                final isGroupChat = chatState.whenOrNull(
                      messagesLoaded: (chats, chatId, messages) {
                        return chats
                                ?.firstWhere(
                                  (c) => c.id == widget.chatId,
                                  orElse: () => Chat(id: widget.chatId),
                                )
                                .type ==
                            ChatType.group;
                      },
                    ) ??
                    false;

                final uiStates = MessageListTransformer.transform(
                  messages: messages,
                  currentUserId: currentUserId,
                  isGroupChat: isGroupChat,
                );

                // Use ListView.builder with key-based items and AutoScrollController
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length + (_isLoadingMessages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoadingMessages && index == 0) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      );
                    }
                    
                    final messageIndex = _isLoadingMessages ? index - 1 : index;
                    if (messageIndex < 0 || messageIndex >= messages.length) {
                      return const SizedBox.shrink();
                    }
                    
                    final message = messages[messageIndex];
                    final uiState = uiStates[messageIndex];
                    
                    return AutoScrollTag(
                      key: ValueKey('message-${message.id}'),
                      controller: _scrollController,
                      index: messageIndex,
                      child: MessageItem(
                        uiState: uiState,
                        onTap: () => _handleMessageTap(message),
                        onLongPress: () => _handleMessageLongPress(message),
                        onReplyPreviewTap: uiState.replyMessage != null
                            ? () {
                                final targetIndex = messages.indexWhere(
                                  (m) =>
                                      m.id ==
                                      uiState.replyMessage!.originalMessageId,
                                );
                                if (targetIndex < 0) return;
                                _scrollController.scrollToIndex(
                                  targetIndex,
                                  preferPosition: AutoScrollPosition.middle,
                                  duration:
                                      const Duration(milliseconds: 250),
                                );
                              }
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Input field
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isAttachmentMenuOpen)
                    _buildAttachmentMenu(),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(_isAttachmentMenuOpen 
                            ? Icons.close 
                            : Icons.add,
                          ),
                          onPressed: () {
                            setState(() {
                              _isAttachmentMenuOpen = !_isAttachmentMenuOpen;
                            });
                          },
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                                    child: TextField(
                                      controller: _messageController,
                                      decoration: InputDecoration(
                                        hintText: context.l10n.typeMessage,
                                        border: InputBorder.none,
                                      ),
                                      maxLines: 5,
                                      minLines: 1,
                                      textCapitalization: TextCapitalization.sentences,
                                      onChanged: (value) {
                                        final isTypingNow = value.isNotEmpty;
                                        if (isTypingNow != _isTyping) {
                                          setState(() {
                                            _isTyping = isTypingNow;
                                          });
                                          
                                          // TODO: Implement typing status notification
                                          // context.read<ChatBloc>().add(ChatEvent.updateTypingStatus(
                                          //   chatId: widget.chatId,
                                          //   isTyping: isTypingNow,
                                          // ));
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  onPressed: () {
                                    _handleAttachmentSelection(ContentType.image);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onLongPress: _startRecording,
                          onLongPressUp: _stopRecordingAndSend,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AppAvatar.initials(
                                name: ' ',
                                size: AvatarSize.large,
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.transparent,
                              ),
                              Icon(
                                _messageController.text.trim().isEmpty
                                    ? (_isRecording ? Icons.stop : Icons.mic)
                                    : Icons.send,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttachmentMenu() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            icon: Icons.photo,
            label: 'Hình ảnh',
            color: Colors.purple,
            onTap: () => _handleAttachmentSelection(ContentType.image),
          ),
          _buildAttachmentOption(
            icon: Icons.videocam,
            label: 'Video',
            color: Colors.red,
            onTap: () => _handleAttachmentSelection(ContentType.video),
          ),
          _buildAttachmentOption(
            icon: Icons.insert_drive_file,
            label: 'Tệp tin',
            color: Colors.blue,
            onTap: () => _handleAttachmentSelection(ContentType.file),
          ),
          _buildAttachmentOption(
            icon: Icons.location_on,
            label: 'Vị trí',
            color: Colors.green,
            onTap: () => _handleAttachmentSelection(ContentType.location),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AppAvatar.initials(
                name: ' ',
                size: AvatarSize.large,
                backgroundColor: color,
                foregroundColor: Colors.transparent,
              ),
              Icon(icon, color: Colors.white),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
  
  // Helper methods for determining message groups
  bool _shouldShowSenderInfo(List<ChatMessage> messages, int index) {
    if (index >= messages.length - 1) return true;
    
    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];
    
    return currentMessage.sender.id != nextMessage.sender.id;
  }
  
  bool _isLastInMessageGroup(List<ChatMessage> messages, int index) {
    if (index <= 0) return true;
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    return currentMessage.sender.id != previousMessage.sender.id;
  }
} 