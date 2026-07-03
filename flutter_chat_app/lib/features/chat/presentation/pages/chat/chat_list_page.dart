import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/chat_module.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/navigation/chat_navigation_helper.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/services/presence_service.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/domain/entities/conversation_type_filter.dart';
import 'package:flutter_chat_app/domain/entities/user_presence.dart';
import 'package:flutter_chat_app/features/chat/domain/entities/chat_draft_entity.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat_draft/chat_draft_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/chat_conversation_preview_resolver.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/chat_conversation_tile.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/conversation_type_tab_bar.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/common/dismiss_keyboard_on_tap.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_shimmer.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/lists/app_list_view.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:get_it/get_it.dart';

// Service locator instance
final getIt = GetIt.instance;

/// Chat list page with BLoC integration
class ChatListPage extends BaseStatefulWidget {
  /// Whether to show bottom navigation bar (when used standalone)
  final bool showBottomNavBar;

  /// Constructor
  const ChatListPage({
    super.key,
    this.showBottomNavBar = true,
  });

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends BaseState<ChatListPage> {
  late final ChatBloc _chatBloc;
  late final ChatDraftBloc _chatDraftBloc;
  late final PresenceService _presenceService;
  bool _ownsChatBloc = false;
  bool _ownsChatDraftBloc = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    try {
      _chatBloc = context.read<ChatBloc>();
      _ownsChatBloc = false;
    } catch (_) {
      _chatBloc = getIt<ChatBloc>();
      _ownsChatBloc = true;
    }
    try {
      _chatDraftBloc = context.read<ChatDraftBloc>();
      _ownsChatDraftBloc = false;
    } catch (_) {
      _chatDraftBloc = getIt<ChatDraftBloc>();
      _ownsChatDraftBloc = true;
    }
    _presenceService = getIt<PresenceService>();
    _chatBloc.add(const ChatEvent.loadChats(forceRefresh: false));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    if (_ownsChatBloc) {
      _chatBloc.close();
    }
    if (_ownsChatDraftBloc) {
      _chatDraftBloc.close();
    }
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

  Future<void> _openNewConversation() async {
    final result = await ChatNavigationHelper.navigateToContacts(
      context,
      selectionMode: true,
    );
    final createdChat = result is Chat ? result : null;
    final createdChatId = createdChat?.id.trim() ?? '';
    if (createdChatId.isEmpty) {
      if (result is String && result.trim().isNotEmpty) {
        _chatBloc.add(const ChatEvent.loadChats(forceRefresh: false));
        if (!mounted) {
          return;
        }
        await ChatNavigationHelper.navigateToChatDetail(
          context,
          chatId: result.trim(),
        );
      }
      return;
    }

    final chat = createdChat;
    if (chat == null) {
      return;
    }

    _chatBloc.add(ChatEvent.chatUpdated(chat: chat));
    if (!mounted) {
      return;
    }

    await ChatNavigationHelper.navigateToChatDetail(
      context,
      chatId: createdChatId,
      receiverId: _extractReceiverIdIfPending(chat),
    );
  }

  Future<void> _openCreateGroup() async {
    final result = await ChatNavigationHelper.navigateToCreateGroup(context);
    final createdChat = result is Chat ? result : null;
    final createdChatId = createdChat?.id.trim() ?? '';
    if (createdChatId.isEmpty) {
      if (result is String && result.trim().isNotEmpty) {
        _chatBloc.add(const ChatEvent.loadChats(forceRefresh: false));
        if (!mounted) {
          return;
        }
        await ChatNavigationHelper.navigateToChatDetail(
          context,
          chatId: result.trim(),
        );
      }
      return;
    }

    final chat = createdChat;
    if (chat == null) {
      return;
    }

    _chatBloc.add(ChatEvent.chatUpdated(chat: chat));
    if (!mounted) {
      return;
    }

    await ChatNavigationHelper.navigateToChatDetail(
      context,
      chatId: createdChatId,
    );
  }

  /// Extract receiverId for pending direct chats (temp numeric ID, no members).
  ///
  /// For pending direct chats the conversation doesn't exist on the server yet.
  /// We pass the other participant's userId so [MessageBloc] can auto-create
  /// the conversation on first message via `chatMessageAdd(receiverId)`.
  String? _extractReceiverIdIfPending(Chat chat) {
    // Pending direct chats have a numeric temp ID (no hyphens = not UUID)
    final isPending =
        chat.type == ChatType.direct && !chat.id.contains('-');
    if (!isPending) return null;

    // Try participantIds first (always set on optimistic chat)
    final currentUserId = getIt<CurrentUserProvider>().currentUserId;
    if (chat.participantIds.isNotEmpty) {
      final otherId = chat.participantIds
          .cast<String?>()
          .firstWhere((id) => id != currentUserId, orElse: () => null);
      if (otherId != null && otherId.isNotEmpty) return otherId;
    }

    // Fallback to members (if populated)
    if (chat.members.isNotEmpty) {
      final otherMember = chat.members
          .cast<ConversationMember?>()
          .firstWhere(
              (m) => m?.userId != currentUserId, orElse: () => null);
      return otherMember?.userId;
    }

    return null;
  }

  Future<void> _onRefresh() async {
    if (_isSearching && _searchController.text.trim().isNotEmpty) {
      _chatBloc.add(ChatEvent.searchChats(keyword: _searchController.text));
    } else {
      _chatBloc.add(const ChatEvent.loadChats(forceRefresh: true));
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ChatBloc>.value(value: _chatBloc),
        BlocProvider<ChatDraftBloc>.value(value: _chatDraftBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppDimens.glassBlurSigma,
                sigmaY: AppDimens.glassBlurSigma,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.glassBgDark
                      : AppColors.glassBgLight,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.dividerDarkMode
                          : AppColors.divider,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textPrimaryDarkMode
                        : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.searchConversations,
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textHintDarkMode
                          : AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                  ),
                )
              : AppText(context.l10n.chats),
          actions: [
            IconButton(
              icon: AppIcon.svg(_isSearching ? AppIcons.close : AppIcons.search),
              onPressed: _toggleSearch,
            ),
            PopupMenuButton<String>(
              icon: const AppIcon.svg(AppIcons.add),
              onSelected: (value) async {
                if (value == 'newConversation') {
                  await _openNewConversation();
                  return;
                }
                if (value == 'newGroup') {
                  await _openCreateGroup();
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
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            state.whenOrNull(
              loaded: (chats,
                  hasMore,
                  isLoadingMore,
                  page,
                  pageSize,
                  total,
                  activeFilter,
                  cachedLists,
                  filterPages,
                  filterHasMore,
                  isSyncing) {
                _prefetchPresenceForChats(chats);
              },
              error: (message) {
                AppSnackBar.show(
                  context: context,
                  message: message,
                  type: FeedbackType.error,
                  action: SnackBarAction(
                    label: context.l10n.retryOperation,
                    onPressed: () {
                      _chatBloc.add(
                        const ChatEvent.loadChats(forceRefresh: true),
                      );
                    },
                  ),
                );
              },
            );
          },
          builder: (context, state) {
            return state.when(
              initial: _buildShimmerList,
              loading: _buildShimmerList,
              loaded: (chats,
                  hasMore,
                  isLoadingMore,
                  page,
                  pageSize,
                  total,
                  activeFilter,
                  cachedLists,
                  filterPages,
                  filterHasMore,
                  isSyncing) {
                return BlocBuilder<ChatDraftBloc, ChatDraftState>(
                  builder: (context, draftState) {
                    return Column(
                      children: [
                        DismissKeyboardOnTap(
                          child: ConversationTypeTabBar(
                            activeFilter: activeFilter,
                            onFilterChanged: (filter) {
                              _chatBloc.add(
                                  ChatEvent.changeConversationTypeFilter(
                                      filter: filter));
                            },
                          ),
                        ),
                        if (isSyncing)
                          LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        Expanded(
                          child: isLoadingMore && chats.isEmpty
                              ? Center(
                                  child: AppProgressIndicator.circular(
                                      label: context.l10n.loading),
                                )
                              : AppListView<Chat>(
                                  items: chats,
                                  isLoading: isLoadingMore,
                                  hasMore: hasMore,
                                  onRefresh: _onRefresh,
                                  onLoadMore: () async {
                                    if (isLoadingMore) return;
                                    _chatBloc
                                        .add(const ChatEvent.loadMoreChats());
                                  },
                                  emptyWidget: _buildEmptyState(context,
                                      activeFilter: activeFilter),
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    indent: 68,
                                    endIndent: 0,
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withValues(alpha: 0.2),
                                  ),
                                  itemBuilder: (context, chat, index) {
                                    final item = _buildChatListItem(
                                      context,
                                      chat,
                                      draftState.draftsByConversationId,
                                    );
                                    // Stagger entrance: fade + slide from right
                                    return TweenAnimationBuilder<double>(
                                      key: ValueKey(chat.id),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: Duration(
                                        milliseconds:
                                            AppDimens.durationMedium,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        // Apply delay by keeping value at 0
                                        // until enough time has passed
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(
                                              20 * (1 - value),
                                              0,
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: item,
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
              error: (message) {
                return _buildErrorState(
                  context,
                  message,
                  () {
                    _chatBloc.add(
                      const ChatEvent.loadChats(forceRefresh: true),
                    );
                  },
                );
              },
              conversationActionCompleted: (_, __) {
                return _buildShimmerList();
              },
              chatDetailsLoaded: (chat) {
                // Not used in list view
                return const SizedBox.shrink();
              },
              messagesLoading: (chats) {
                // Not used in list view
                return const SizedBox.shrink();
              },
              messagesLoaded: (chats, chatId, messages) {
                // Not used in list view
                return const SizedBox.shrink();
              },
              messageSending: (chatId, localId) {
                // Not used in list view
                return const SizedBox.shrink();
              },
              messageStatusChanged: (chatId, localId, status, serverId) {
                // Not used in list view
                return const SizedBox.shrink();
              },
              syncing: () {
                // Show syncing indicator
                return DismissKeyboardOnTap(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppProgressIndicator.circular(
                            label: context.l10n.syncing),
                        const SizedBox(height: AppDimens.spaceMedium),
                        AppText(context.l10n.syncing),
                      ],
                    ),
                  ),
                );
              },
              offline: () {
                // Show offline indicator
                return DismissKeyboardOnTap(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon.svg(
                          AppIcons.cloudOff,
                          size: AppDimens.iconSizeXXLarge,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppDimens.spaceMedium),
                        AppText(context.l10n.offline),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        bottomNavigationBar: (!widget.showBottomNavBar ||
                (ChatModule.config?.hideBottomNavBar ?? false))
            ? null
            : BottomNavigationBar(
                currentIndex: 0,
                items: [
                  BottomNavigationBarItem(
                    icon: const AppIcon.svg(AppIcons.navChat),
                    label: context.l10n.chats,
                  ),
                  BottomNavigationBarItem(
                    icon: const AppIcon.svg(AppIcons.navContacts),
                    label: context.l10n.contacts,
                  ),
                  BottomNavigationBarItem(
                    icon: const AppIcon.svg(AppIcons.navSettings),
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

  Widget _buildChatListItem(
    BuildContext context,
    Chat chat,
    Map<String, ChatDraftEntity> draftsByConversationId,
  ) {
    final previewData = ChatConversationPreviewResolver.resolve(
      context: context,
      chat: chat,
      draftsByConversationId: draftsByConversationId,
    );

    return ChatConversationTile(
      chat: chat,
      previewText: previewData.text,
      isDraftPreview: previewData.isDraft,
      onTap: () async {
        if (chat.unreadCount > 0) {
          _chatBloc.add(
            ChatEvent.markMessagesAsRead(
              chatId: chat.id,
              messageIds: const <String>[],
            ),
          );
        }

        await ChatNavigationHelper.navigateToChatDetail(
          context,
          chatId: chat.id,
          receiverId: _extractReceiverIdIfPending(chat),
        );
      },
    );
  }

  void _prefetchPresenceForChats(List<Chat> chats) {
    final currentUserId = getIt<CurrentUserProvider>().currentUserId;
    final userIds = <String>{};
    final seededPresenceByUserId = <String, UserPresence>{};

    for (final chat in chats) {
      if (chat.type != ChatType.direct || chat.members.isEmpty) {
        continue;
      }

      final otherMember = chat.members.firstWhere(
        (member) => member.userId != currentUserId,
        orElse: () => chat.members.first,
      );
      final candidateId = otherMember.userId.trim().isNotEmpty
          ? otherMember.userId.trim()
          : otherMember.id.trim();
      if (candidateId.isNotEmpty) {
        userIds.add(candidateId);
        seededPresenceByUserId[candidateId] = UserPresence(
          userId: candidateId,
          isOnline: otherMember.isConnected,
          lastSeen: otherMember.viewMessagesFrom,
        );
      }
    }

    if (userIds.isEmpty && seededPresenceByUserId.isEmpty) {
      return;
    }

    unawaited(
      _presenceService.fetchPresenceForUsers(
        userIds.toList(growable: false),
        seededPresenceByUserId: seededPresenceByUserId,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context,
      {ConversationTypeFilter activeFilter = ConversationTypeFilter.all}) {
    final message = switch (activeFilter) {
      ConversationTypeFilter.direct => context.l10n.noDirectConversations,
      ConversationTypeFilter.group => context.l10n.noGroupConversations,
      _ => context.l10n.noConversations,
    };
    return DismissKeyboardOnTap(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon.svg(
              AppIcons.emptyChat,
              size: AppDimens.iconSizeXXLarge,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            AppText(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, String message, VoidCallback? retryAction) {
    return DismissKeyboardOnTap(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon.svg(
                AppIcons.errorOutline,
                size: AppDimens.iconSizeXXLarge,
                color: AppColors.error,
              ),
              const SizedBox(height: AppDimens.spaceMedium),
              AppText(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (retryAction != null) ...[
                const SizedBox(height: AppDimens.spaceLarge),
                AppButton.primary(
                  text: context.l10n.retryOperation,
                  icon: AppIcons.refresh,
                  onPressed: retryAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Shimmer skeleton list for loading state (cache-first pattern)
  Widget _buildShimmerList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 68,
        endIndent: 0,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) => AppShimmer.listItem(),
    );
  }
}
