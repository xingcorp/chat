import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/date_formatter_service.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_details_page.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/app_card.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/lists/app_list_view.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

// Service locator instance
final getIt = GetIt.instance;

/// Chat list page with BLoC integration
class ChatListPage extends BaseStatefulWidget {
  /// Constructor
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends BaseState<ChatListPage> {
  late final ChatBloc _chatBloc;
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _chatBloc = getIt<ChatBloc>();
    // Load initial conversations
    _chatBloc.add(const ChatEvent.loadChats(forceRefresh: false));
  }

  @override
  void dispose() {
    _chatBloc.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    safeSetState(() {
      _currentPage = 0;
      _isLoadingMore = false;
    });
    _chatBloc.add(const ChatEvent.loadChats(forceRefresh: true));
    
    // Wait for the state to update
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>.value(
      value: _chatBloc,
      child: Scaffold(
        appBar: AppBar(
          title: AppText(context.l10n.chats),
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
              loaded: (chats) {
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
              initial: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppProgressIndicator.circular(label: context.l10n.loading),
                    const SizedBox(height: AppDimens.spaceMedium),
                    AppText(context.l10n.loadingConversations),
                  ],
                ),
              ),
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppProgressIndicator.circular(label: context.l10n.loading),
                    const SizedBox(height: AppDimens.spaceMedium),
                    AppText(context.l10n.loadingConversations),
                  ],
                ),
              ),
              loaded: (chats) {
                return AppListView<Chat>(
                  items: chats,
                  isLoading: _isLoadingMore,
                  hasMore: true,
                  onRefresh: _onRefresh,
                  onLoadMore: () async {
                    if (_isLoadingMore) return;
                    safeSetState(() {
                      _isLoadingMore = true;
                    });
                    _chatBloc.add(
                      const ChatEvent.loadChats(forceRefresh: false),
                    );
                  },
                  emptyWidget: _buildEmptyState(context),
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: AppDimens.spaceHuge,
                  ),
                  itemBuilder: (context, chat, index) {
                    return _buildChatListItem(context, chat);
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppProgressIndicator.circular(label: context.l10n.syncing),
                      const SizedBox(height: AppDimens.spaceMedium),
                      AppText(context.l10n.syncing),
                    ],
                  ),
                );
              },
              offline: () {
                // Show offline indicator
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

    final avatar = Container(
      width: AppDimens.iconSizeXXLarge,
      height: AppDimens.iconSizeXXLarge,
      decoration: BoxDecoration(
        color: isGroup ? AppColors.success : AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimens.radiusCircular),
      ),
      clipBehavior: Clip.antiAlias,
      child: (chat.imgUrl != null && chat.imgUrl!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: chat.imgUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Icon(
                isGroup ? Icons.group : Icons.person,
                color: AppColors.textButton,
              ),
              errorWidget: (context, url, error) => Icon(
                isGroup ? Icons.group : Icons.person,
                color: AppColors.textButton,
              ),
            )
          : Icon(
              isGroup ? Icons.group : Icons.person,
              color: AppColors.textButton,
            ),
    );

    final timeText = chat.lastMessageAt != null
        ? DateFormatterService.formatTimeForMessage(chat.lastMessageAt!)
        : '';

    final unreadBadge = (chat.unreadCount > 0)
        ? Container(
            padding: const EdgeInsets.all(AppDimens.paddingSmall),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: AppText(
              chat.unreadCount.toString(),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textButton,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : const SizedBox.shrink();

    return AppCard.filled(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailsPage(chatId: chat.id),
          ),
        );
      },
      child: Row(
        children: [
          avatar,
          const SizedBox(width: AppDimens.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  chat.name ?? '',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimens.spaceXSmall),
                AppText(
                  chat.lastMessage ?? context.l10n.noMessages,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                timeText,
                style: AppTextStyles.labelSmall.copyWith(
                  color: chat.unreadCount > 0
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimens.spaceXSmall),
              unreadBadge,
            ],
          ),
        ],
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
            size: AppDimens.iconSizeXXLarge,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          AppText(
            context.l10n.noConversations,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
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
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (retryAction != null) ...[
              const SizedBox(height: AppDimens.spaceLarge),
              AppButton.primary(
                text: context.l10n.retryOperation,
                icon: Icons.refresh,
                onPressed: retryAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
} 