import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_conversation_detail_usecase.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/message_item.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/app_card.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/dialogs/app_alert_dialog.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/inputs/app_text_field.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/lists/app_list_view.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

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
  late final MessageBloc _messageBloc;
  late final GetConversationDetailUseCase _getConversationDetail;
  Chat? _chat;
  
  static const int _pageSize = 50;
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    _messageBloc = getIt<MessageBloc>();
    _getConversationDetail = getIt<GetConversationDetailUseCase>();
    // Load initial messages
    _messageBloc.add(
      LoadMessages(
        chatId: widget.chatId,
        limit: _pageSize,
        forceRefresh: false,
      ),
    );

    _loadChatHeader();
  }

  Future<void> _loadChatHeader() async {
    final result = await _getConversationDetail(widget.chatId);
    result.fold(
      (_) {},
      (chat) {
        if (chat == null) return;
        safeSetState(() {
          _chat = chat;
        });
      },
    );
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _messageBloc.close();
    super.dispose();
  }
  
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: context.l10n.messageEmpty,
        type: FeedbackType.warning,
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
  }
  
  Future<void> _onRefresh() async {
    _messageBloc.add(
      const RefreshMessages(),
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final chatTitle = (_chat?.name?.trim().isNotEmpty ?? false)
        ? _chat!.name!.trim()
        : context.l10n.chats;

    return BlocProvider<MessageBloc>.value(
      value: _messageBloc,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width: AppDimens.iconSizeLarge,
                height: AppDimens.iconSizeLarge,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCircular),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.textButton,
                  size: AppDimens.iconSizeMedium,
                ),
              ),
              const SizedBox(width: AppDimens.spaceSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      chatTitle,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppText(
                      context.l10n.online,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    AppSnackBar.show(
                      context: context,
                      message: state.error,
                      type: FeedbackType.error,
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
                    );
                  }
                },
                builder: (context, state) {
                  if (state is MessageInitial || state is MessagesLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppProgressIndicator.circular(
                            label: context.l10n.loading,
                          ),
                          const SizedBox(height: AppDimens.spaceMedium),
                          AppText(context.l10n.loadingMessages),
                        ],
                      ),
                    );
                  } else if (state is MessagesLoaded) {
                    final messages = state.messages;
                    final hasMore = !state.hasReachedMax;
                    
                    if (messages.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return AppListView<ChatMessage>(
                      items: messages,
                      reverse: true,
                      isLoading: _isLoadingMore,
                      hasMore: hasMore,
                      onRefresh: _onRefresh,
                      onLoadMore: () async {
                        if (_isLoadingMore) return;
                        safeSetState(() {
                          _isLoadingMore = true;
                        });
                        _messageBloc.add(
                          const LoadMoreMessages(limit: _pageSize),
                        );
                      },
                      padding: const EdgeInsets.all(AppDimens.paddingSmall),
                      itemBuilder: (context, message, index) {
                        final isCurrentUser = message.isFromCurrentUser;
                        return MessageItem(
                          message: message,
                          onLongPress: () {
                            _showMessageOptions(context, message, isCurrentUser);
                          },
                        );
                      },
                    );
                  } else if (state is MessagesError) {
                    return _buildErrorState(
                      context,
                      state.error,
                      () {
                        _messageBloc.add(
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
                    child: AppText(context.l10n.errorOccurred),
                  );
                },
              ),
            ),
            
            // Message input
            AppCard.outlined(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(AppDimens.paddingSmall),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // TODO: Show attachment options
                    },
                  ),
                  Expanded(
                    child: AppTextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      hint: context.l10n.typeMessage,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    onPressed: () {
                      // TODO: Show emoji picker
                    },
                  ),
                  AppButton.primary(
                    text: context.l10n.send,
                    icon: Icons.send,
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
            size: AppDimens.iconSizeXXLarge,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          AppText(
            context.l10n.noMessagesInChat,
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
  
  void _showMessageOptions(BuildContext context, ChatMessage message, bool isCurrentUser) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: AppText(context.l10n.copyMessage),
              onTap: () {
                // TODO: Copy message to clipboard
                Navigator.pop(context);
                AppSnackBar.show(
                  context: context,
                  message: context.l10n.messageCopied,
                  type: FeedbackType.success,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: AppText(context.l10n.replyMessage),
              onTap: () {
                // TODO: Reply to message
                Navigator.pop(context);
              },
            ),
            if (isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: AppText(context.l10n.editMessage),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: AppText(context.l10n.deleteMessage),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMessage(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.forward),
              title: AppText(context.l10n.forwardMessage),
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
    // TODO: Set edit mode and update send button to save button
  }
  
  void _confirmDeleteMessage(ChatMessage message) {
    AppAlertDialog.show(
      context: context,
      title: context.l10n.deleteMessage,
      content: context.l10n.confirmDelete,
      actions: [
        AppButton.text(
          text: context.l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          text: context.l10n.delete,
          onPressed: () {
            Navigator.pop(context);
            _messageBloc.add(
              DeleteMessage(message.id),
            );
          },
        ),
      ],
    );
  }
} 