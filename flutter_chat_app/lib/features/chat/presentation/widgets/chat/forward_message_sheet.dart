import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Bottom sheet for selecting a chat to forward a message to.
///
/// Displays search + scrollable chat list using ChatBloc state.
class ForwardMessageSheet extends StatefulWidget {
  final List<ChatMessage>? messagesToForward;
  final String? sourceChatId;

  const ForwardMessageSheet({
    Key? key,
    this.messagesToForward,
    this.sourceChatId,
  }) : super(key: key);

  @override
  State<ForwardMessageSheet> createState() => _ForwardMessageSheetState();
}

class _ForwardMessageSheetState extends State<ForwardMessageSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chatBloc = context.read<ChatBloc>();
      final s = chatBloc.state;
      final needsLoad = s.maybeWhen(
        initial: () => true,
        offline: () => true,
        error: (_) => true,
        orElse: () => false,
      );

      if (needsLoad) {
        chatBloc.add(const ChatEvent.loadChats());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _handleForwardToChat(String targetChatId) {
    if (widget.messagesToForward == null || widget.messagesToForward!.isEmpty) return;
    
    for (final message in widget.messagesToForward!) {
      context.read<MessageBloc>().add(ForwardMessage(
        message: message,
        targetChatId: targetChatId,
        sourceChatId: widget.sourceChatId,
      ));
    }
    
    Navigator.of(context).pop();
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.forwardMessage),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final chatState = context.watch<ChatBloc>().state;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.forwardTo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchConversations,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),
            const Divider(height: 1),
            // Chat list from ChatBloc
            Expanded(
              child: chatState.maybeWhen(
                loading: () => const Center(child: CircularProgressIndicator()),
                loaded: (chats, _, __, ___, ____, _____, _______, ________, _________, __________) {
                  final filteredChats = chats.where((chat) {
                    if (_searchQuery.isEmpty) return true;
                    final chatName = chat.name ?? '';
                    return chatName.toLowerCase().contains(_searchQuery);
                  }).toList();
                  
                  if (filteredChats.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: theme.disabledColor),
                            const SizedBox(height: 16),
                            Text(
                              l10n.selectChat,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      final chatName = chat.name ?? '';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            chatName.isNotEmpty ? chatName[0].toUpperCase() : '?',
                            style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                        title: Text(chatName.isEmpty ? 'Unknown' : chatName),
                        subtitle: Text(
                          chat.lastMessage ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _handleForwardToChat(chat.id),
                      );
                    },
                  );
                },
                messagesLoaded: (chats, _, __) {
                  final filteredChats = (chats ?? []).where((chat) {
                    if (_searchQuery.isEmpty) return true;
                    final chatName = chat.name ?? '';
                    return chatName.toLowerCase().contains(_searchQuery);
                  }).toList();
                  
                  if (filteredChats.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forward_to_inbox, size: 48, color: theme.disabledColor),
                            const SizedBox(height: 16),
                            Text(
                              l10n.selectChat,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      final chatName = chat.name ?? '';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            chatName.isNotEmpty ? chatName[0].toUpperCase() : '?',
                            style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                        title: Text(chatName.isEmpty ? 'Unknown' : chatName),
                        subtitle: Text(
                          chat.lastMessage ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _handleForwardToChat(chat.id),
                      );
                    },
                  );
                },
                error: (msg) => Center(child: Text(msg)),
                orElse: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.forward_to_inbox,
                          size: 48,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.selectChat,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            context
                                .read<ChatBloc>()
                                .add(const ChatEvent.loadChats(forceRefresh: true));
                          },
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Show the forward message bottom sheet
Future<void> showForwardMessageSheet(
  BuildContext context, {
  List<ChatMessage>? messages,
  String? sourceChatId,
}) {
  ChatBloc chatBloc;
  MessageBloc messageBloc;
  try {
    chatBloc = context.read<ChatBloc>();
  } catch (_) {
    chatBloc = GetIt.instance<ChatBloc>();
  }
  try {
    messageBloc = context.read<MessageBloc>();
  } catch (_) {
    messageBloc = GetIt.instance<MessageBloc>();
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: chatBloc),
        BlocProvider.value(value: messageBloc),
      ],
      child: ForwardMessageSheet(
        messagesToForward: messages,
        sourceChatId: sourceChatId,
      ),
    ),
  );
}
