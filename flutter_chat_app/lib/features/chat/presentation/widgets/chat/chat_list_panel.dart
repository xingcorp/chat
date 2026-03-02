import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/extensions/extensions.dart';
import 'package:flutter_chat_app/core/navigation/chat_navigation_helper.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/domain/entities/conversation_type_filter.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/chat_conversation_tile.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/conversation_type_tab_bar.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/lists/app_list_view.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class ChatListPanel extends BaseStatefulWidget {
  const ChatListPanel({super.key, this.onChatSelected});

  final ValueChanged<String>? onChatSelected;

  @override
  State<ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends BaseState<ChatListPanel> {
  late final ChatBloc _chatBloc;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoadingMore = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _chatBloc = getIt<ChatBloc>();
    _chatBloc.add(const ChatEvent.loadChats(forceRefresh: false));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _chatBloc.close();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.trim().isEmpty) {
        _chatBloc.add(const ChatEvent.clearSearch());
      } else {
        _chatBloc.add(ChatEvent.searchChats(keyword: value));
      }
    });
  }

  void _toggleSearch() {
    safeSetState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _chatBloc.add(const ChatEvent.clearSearch());
      }
    });
  }

  Future<void> _onRefresh() async {
    safeSetState(() {
      _isLoadingMore = false;
    });
    if (_isSearching && _searchController.text.trim().isNotEmpty) {
      _chatBloc.add(ChatEvent.searchChats(keyword: _searchController.text));
    } else {
      _chatBloc.add(const ChatEvent.loadChats(forceRefresh: true));
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>.value(
      value: _chatBloc,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            SizedBox(
              height: kToolbarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingSmall),
                child: Row(
                  children: [
                    Expanded(
                      child: _isSearching
                          ? TextField(
                              controller: _searchController,
                              autofocus: true,
                              onChanged: _onSearchChanged,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: context.l10n.searchConversations,
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                              ),
                            )
                          : AppText(context.l10n.chats),
                    ),
                    IconButton(
                      icon: Icon(_isSearching ? Icons.close : Icons.search),
                      onPressed: _toggleSearch,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.add),
                      onSelected: (value) {
                        switch (value) {
                          case 'newConversation':
                            ChatNavigationHelper.navigateToContacts(context);
                          case 'newGroup':
                            ChatNavigationHelper.navigateToCreateGroup(context);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'newConversation',
                          child: AppText(context.l10n.newConversation),
                        ),
                        PopupMenuItem(
                          value: 'newGroup',
                          child: AppText(context.l10n.createNewGroup),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, state) {
                  state.whenOrNull(
                    loaded: (chats, hasMore, isLoadingMore, page, pageSize, total, activeFilter, cachedLists, filterPages, filterHasMore, isSyncing) {
                      safeSetState(() {
                        _isLoadingMore = false;
                      });
                    },
                    error: (message) {
                      safeSetState(() {
                        _isLoadingMore = false;
                      });
                      AppSnackBar.show(
                        context: context,
                        message: message,
                        type: FeedbackType.error,
                        action: SnackBarAction(
                          label: context.l10n.retryOperation,
                          onPressed: () {
                            _chatBloc.add(const ChatEvent.loadChats(forceRefresh: true));
                          },
                        ),
                      );
                    },
                  );
                },
                builder: (context, state) {
                  return state.when(
                    initial: () => _buildLoading(context),
                    loading: () => _buildLoading(context),
                    loaded: (chats, hasMore, isLoadingMore, page, pageSize, total, activeFilter, cachedLists, filterPages, filterHasMore, isSyncing) {
                      return Column(
                        children: [
                          ConversationTypeTabBar(
                            activeFilter: activeFilter,
                            onFilterChanged: (filter) {
                              _chatBloc.add(ChatEvent.changeConversationTypeFilter(filter: filter));
                            },
                          ),
                          Expanded(
                            child: isLoadingMore && chats.isEmpty
                                ? Center(
                                    child: AppProgressIndicator.circular(label: context.l10n.loading),
                                  )
                                : AppListView<Chat>(
                                    items: chats,
                                    isLoading: isLoadingMore,
                                    hasMore: hasMore,
                                    onRefresh: _onRefresh,
                                    onLoadMore: () async {
                                      if (isLoadingMore) return;
                                      _chatBloc.add(const ChatEvent.loadMoreChats());
                                    },
                                    emptyWidget: _buildEmptyState(context, activeFilter: activeFilter),
                                    separatorBuilder: (context, index) => const Divider(
                                      height: 1,
                                      indent: AppDimens.spaceHuge,
                                    ),
                                    itemBuilder: (context, chat, index) {
                                      return _buildChatListItem(context, chat);
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                    error: (message) {
                      return _buildErrorState(
                        context,
                        message,
                        () {
                          _chatBloc.add(const ChatEvent.loadChats(forceRefresh: true));
                        },
                      );
                    },
                    chatDetailsLoaded: (_) => const SizedBox.shrink(),
                    messagesLoading: (_) => const SizedBox.shrink(),
                    messagesLoaded: (_, __, ___) => const SizedBox.shrink(),
                    messageSending: (_, __) => const SizedBox.shrink(),
                    messageStatusChanged: (_, __, ___, ____) => const SizedBox.shrink(),
                    syncing: () => _buildLoading(context),
                    offline: () => _buildOfflineState(context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppProgressIndicator.circular(label: context.l10n.loading),
          const SizedBox(height: AppDimens.spaceMedium),
          AppText(context.l10n.loadingConversations),
        ],
      ),
    );
  }

  Widget _buildChatListItem(BuildContext context, Chat chat) {
    final previewText = (chat.lastMessagePreview ?? context.l10n.noMessages).formatChatMessage(
      mentionNameById: {
        for (final m in chat.members)
          if ((m.userId).isNotEmpty && (m.fullName?.trim().isNotEmpty ?? false))
            m.userId: m.fullName!.trim(),
      },
    );

    return ChatConversationTile(
      chat: chat,
      previewText: previewText,
      onTap: () async {
        if (chat.unreadCount > 0) {
          _chatBloc.add(
            ChatEvent.markMessagesAsRead(
              chatId: chat.id,
              messageIds: const <String>[],
            ),
          );
        }

        final onChatSelected = widget.onChatSelected;
        if (onChatSelected != null) {
          onChatSelected(chat.id);
          return;
        }

        await ChatNavigationHelper.navigateToChatDetail(
          context,
          chatId: chat.id,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, {ConversationTypeFilter activeFilter = ConversationTypeFilter.all}) {
    final message = switch (activeFilter) {
      ConversationTypeFilter.direct => context.l10n.noDirectConversations,
      ConversationTypeFilter.group => context.l10n.noGroupConversations,
      _ => context.l10n.noConversations,
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: AppDimens.iconSizeXXLarge,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          AppText(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message, VoidCallback? retryAction) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimens.iconSizeXXLarge,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            AppText(
              message,
              textAlign: TextAlign.center,
            ),
            if (retryAction != null) ...[
              const SizedBox(height: AppDimens.spaceLarge),
              TextButton(
                onPressed: retryAction,
                child: Text(context.l10n.retryOperation),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: AppDimens.iconSizeXXLarge,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          AppText(context.l10n.offline),
        ],
      ),
    );
  }
}
