import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/message_item.dart';
import 'package:get_it/get_it.dart';

// Service locator instance
final getIt = GetIt.instance;

/// Chat details page with MessageBloc integration
class ChatDetailsPage extends BaseStatefulWidget {
  /// Chat ID
  final String chatId;
  
  /// Constructor
  const ChatDetailsPage({
    super.key,
    required this.chatId,
  }) : super();

  @override
  State<ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends BaseState<ChatDetailsPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  late final MessageBloc _messageBloc;
  
  static const int _pageSize = 50;
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    _messageBloc = getIt<MessageBloc>();
    _scrollController.addListener(_onScroll);
    // Load initial messages
    _messageBloc.add(
      LoadMessages(
        chatId: widget.chatId,
        limit: _pageSize,
        forceRefresh: false,
      ),
    );
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _messageBloc.close();
    super.dispose();
  }
  
  void _onScroll() {
    if (_isLoadingMore) return;
    
    // Load more when scrolled to top (reverse list)
    if (_scrollController.position.pixels <= _scrollController.position.minScrollExtent + 100) {
      final state = _messageBloc.state;
      // Check if state has more messages to load
      if (state is MessagesLoaded) {
        safeSetState(() {
          _isLoadingMore = true;
        });
        _messageBloc.add(
          const LoadMoreMessages(limit: _pageSize),
        );
      }
    }
  }
  
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.messageEmpty)),
      );
      return;
    }
    
    // TODO: Get current user ID from auth state
    final currentUserId = 'current_user_id'; // Placeholder
    
    _messageBloc.add(
      SendMessage(
        content: text,
        senderId: currentUserId,
        contentType: 'text',
        attachmentIds: const [],
      ),
    );
    
    _messageController.clear();
    _messageFocusNode.requestFocus();
    
    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _onRefresh() async {
    _messageBloc.add(
      const RefreshMessages(),
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MessageBloc>.value(
      value: _messageBloc,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.chatTitle(widget.chatId),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      context.l10n.online,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () {
                // TODO: Start video call
              },
            ),
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {
                // TODO: Start voice call
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                // TODO: Handle menu selection
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'viewProfile',
                  child: Text(context.l10n.viewInfo),
                ),
                PopupMenuItem(
                  value: 'search',
                  child: Text(context.l10n.search),
                ),
                PopupMenuItem(
                  value: 'mute',
                  child: Text(context.l10n.muteNotifications),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Chat messages
            Expanded(
              child: BlocConsumer<MessageBloc, MessageState>(
                listener: (context, state) {
                  if (state is MessagesLoaded) {
                    safeSetState(() {
                      _isLoadingMore = false;
                    });
                  } else if (state is MessagesError) {
                    safeSetState(() {
                      _isLoadingMore = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error),
                        action: SnackBarAction(
                          label: context.l10n.retryOperation,
                          onPressed: () {
                            _messageBloc.add(
                              LoadMessages(
                                chatId: widget.chatId,
                                limit: _pageSize,
                                forceRefresh: true,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is MessageInitial || state is MessagesLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(context.l10n.loadingMessages),
                        ],
                      ),
                    );
                  } else if (state is MessagesLoaded) {
                    final messages = state.messages;
                    final hasMore = !state.hasReachedMax;
                    
                    if (messages.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        reverse: true, // Show newest messages at bottom
                        itemCount: messages.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isLoadingMore && index == messages.length) {
                            // Loading more indicator at top
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 8),
                                    Text(context.l10n.loadingMore),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          final message = messages[index];
                          final isCurrentUser = message.isFromCurrentUser;
                          
                          return MessageItem(
                            message: message,
                            onLongPress: () {
                              _showMessageOptions(context, message, isCurrentUser);
                            },
                          );
                        },
                      ),
                    );
                  } else if (state is MessagesError) {
                    return _buildErrorState(
                      context,
                      state.error,
                      () {
                        context.read<MessageBloc>().add(
                          LoadMessages(
                            chatId: widget.chatId,
                            limit: _pageSize,
                            forceRefresh: true,
                          ),
                        );
                      },
                    );
                  }
                  
                  // Fallback for unknown state
                  return Center(
                    child: Text('Unknown state: ${state.runtimeType}'),
                  );
                },
              ),
            ),
            
            // Message input
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // TODO: Show attachment options
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      decoration: InputDecoration(
                        hintText: context.l10n.typeMessage,
                        border: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 5,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    onPressed: () {
                      // TODO: Show emoji picker
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noMessagesInChat,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message, VoidCallback? retryAction) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (retryAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: retryAction,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retryOperation),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showMessageOptions(BuildContext context, ChatMessage message, bool isCurrentUser) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(context.l10n.copyMessage),
              onTap: () {
                // TODO: Copy message to clipboard
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.messageCopied)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text(context.l10n.replyMessage),
              onTap: () {
                // TODO: Reply to message
                Navigator.pop(context);
              },
            ),
            if (isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(context.l10n.editMessage),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(context.l10n.deleteMessage),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMessage(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.forward),
              title: Text(context.l10n.forwardMessage),
              onTap: () {
                // TODO: Forward message
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _editMessage(ChatMessage message) {
    _messageController.text = message.content;
    _messageFocusNode.requestFocus();
    // TODO: Set edit mode and update send button to save button
  }
  
  void _confirmDeleteMessage(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteMessage),
        content: Text(context.l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MessageBloc>().add(
                DeleteMessage(message.id),
              );
            },
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }
} 