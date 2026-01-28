import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/di/enterprise_injection.dart';
import 'package:flutter_chat_app/core/services/date_formatter_service.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/presentation/pages/chat/chat_details_page.dart';

/// Chat list page with BLoC integration
class ChatListPage extends StatefulWidget {
  /// Constructor
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial conversations
    context.read<ChatBloc>().add(const ChatEvent.loadChats(page: 0, size: _pageSize));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Load more when scrolled to 80% of the list
    if (currentScroll >= maxScroll * 0.8) {
      final state = context.read<ChatBloc>().state;
      state.whenOrNull(
        loaded: (chats, hasMore, currentPage) {
          if (hasMore) {
            setState(() {
              _isLoadingMore = true;
              _currentPage = currentPage + 1;
            });
            context.read<ChatBloc>().add(
              ChatEvent.loadChats(page: _currentPage, size: _pageSize),
            );
          }
        },
      );
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _currentPage = 0;
      _isLoadingMore = false;
    });
    context.read<ChatBloc>().add(const ChatEvent.loadChats(page: 0, size: _pageSize));
    
    // Wait for the state to update
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.chats),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Navigate to search page
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'newGroup') {
                  // TODO: Navigate to create group page
                } else if (value == 'settings') {
                  // TODO: Navigate to settings page
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'newGroup',
                  child: Text(context.l10n.createNewGroup),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Text(context.l10n.settingsTitle),
                ),
              ],
            ),
          ],
        ),
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            state.whenOrNull(
              loaded: (chats, hasMore, currentPage) {
                setState(() {
                  _isLoadingMore = false;
                });
              },
              error: (failure, operation, retryAction) {
                setState(() {
                  _isLoadingMore = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(failure.message),
                    action: retryAction != null
                        ? SnackBarAction(
                            label: context.l10n.retryOperation,
                            onPressed: retryAction,
                          )
                        : null,
                  ),
                );
              },
            );
          },
          builder: (context, state) {
            return state.when(
              initial: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(context.l10n.loadingConversations),
                  ],
                ),
              ),
              loading: (operation) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(operation ?? context.l10n.loadingConversations),
                  ],
                ),
              ),
              loaded: (chats, hasMore, currentPage) {
                if (chats.isEmpty) {
                  return _buildEmptyState(context);
                }
                
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: chats.length + (hasMore ? 1 : 0),
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: 72,
                    ),
                    itemBuilder: (context, index) {
                      if (index >= chats.length) {
                        // Loading more indicator
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
                      
                      final chat = chats[index];
                      return _buildChatListItem(context, chat);
                    },
                  ),
                );
              },
              error: (failure, operation, retryAction) {
                return _buildErrorState(context, failure.message, retryAction);
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Navigate to contacts or new chat
          },
          child: const Icon(Icons.chat),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat),
              label: context.l10n.chats,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.contacts),
              label: context.l10n.contacts,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: context.l10n.settingsTitle,
            ),
          ],
          onTap: (index) {
            // TODO: Handle navigation
          },
        ),
      ),
    );
  }

  Widget _buildChatListItem(BuildContext context, Chat chat) {
    final isGroup = chat.type == ChatType.group || chat.type == ChatType.channel;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isGroup ? Colors.green : Colors.blue,
        radius: 24,
        child: chat.imgUrl != null && chat.imgUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CachedNetworkImage(
                  imageUrl: chat.imgUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Icon(
                    isGroup ? Icons.group : Icons.person,
                    color: Colors.white,
                  ),
                  errorWidget: (context, url, error) => Icon(
                    isGroup ? Icons.group : Icons.person,
                    color: Colors.white,
                  ),
                ),
              )
            : Icon(
                isGroup ? Icons.group : Icons.person,
                color: Colors.white,
              ),
      ),
      title: Text(
        chat.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        chat.lastMessage ?? context.l10n.noMessages,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            chat.lastMessageAt != null
                ? DateFormatterService.formatTimeForMessage(chat.lastMessageAt!)
                : '',
            style: TextStyle(
              fontSize: 12,
              color: chat.unreadCount > 0 ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailsPage(chatId: chat.id),
          ),
        );
      },
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
            context.l10n.noConversations,
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
} 