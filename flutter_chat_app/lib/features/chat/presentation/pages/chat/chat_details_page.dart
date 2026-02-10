import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as flyer_ui;
import 'package:flutter_chat_core/flutter_chat_core.dart' as flyer;

import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_conversation_detail_usecase.dart';
import 'package:flutter_chat_app/features/chat/presentation/adapters/adapters.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_chat_app/presentation/widgets/design_system/dialogs/app_alert_dialog.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

// Service locator instance
final getIt = GetIt.instance;

/// Chat details page using Flyer Chat UI with adapter pattern.
///
/// Bridges [MessageBloc] (domain/BLoC layer) → [ChatControllerAdapter] → Flyer Chat widget.
class ChatDetailsPage extends BaseStatefulWidget {
  final String chatId;

  const ChatDetailsPage({
    super.key,
    required this.chatId,
  }) : super();

  @override
  State<ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends BaseState<ChatDetailsPage> {
  late final MessageBloc _messageBloc;
  late final GetConversationDetailUseCase _getConversationDetail;
  late final ChatControllerAdapter _chatController;
  late final FlyerUserResolver _userResolver;
  late final String _currentUserId;

  Chat? _chat;
  StreamSubscription<MessageState>? _blocSubscription;

  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();

    // Resolve current user ID from AuthBloc
    final authState = context.read<AuthBloc>().state;
    _currentUserId = authState is AuthAuthenticated ? authState.user.id : '';

    _messageBloc = getIt<MessageBloc>();
    _getConversationDetail = getIt<GetConversationDetailUseCase>();

    // Create per-page adapter instances
    _userResolver = FlyerUserResolver();
    _chatController = ChatControllerAdapter(
      mapper: getIt<FlyerMessageMapper>(),
      resolver: _userResolver,
      currentUserId: _currentUserId,
    );

    // Listen to BLoC state changes and sync to Flyer adapter
    _blocSubscription = _messageBloc.stream.listen(_onBlocStateChanged);

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
        _userResolver.seedFromChat(chat);
        safeSetState(() {
          _chat = chat;
        });
      },
    );
  }

  /// Sync BLoC state → ChatControllerAdapter whenever messages change.
  void _onBlocStateChanged(MessageState state) {
    if (state is MessagesLoaded && state.chatId == widget.chatId) {
      _chatController.syncMessages(state.messages);
    }
  }

  @override
  void dispose() {
    _blocSubscription?.cancel();
    _chatController.dispose();
    _messageBloc.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Flyer Chat callbacks
  // ---------------------------------------------------------------------------

  void _onMessageSend(String text) {
    if (text.trim().isEmpty) return;

    _messageBloc.add(
      SendMessage(
        content: text.trim(),
        senderId: _currentUserId,
        contentType: 'text',
        attachmentIds: const [],
      ),
    );
  }

  void _onMessageTap(
    BuildContext context,
    flyer.Message message, {
    required int index,
    required TapUpDetails details,
  }) {
    // Reserved for future: open media viewer, link preview, etc.
  }

  void _onMessageLongPress(
    BuildContext context,
    flyer.Message message, {
    required int index,
    required LongPressStartDetails details,
  }) {
    // Find the corresponding domain message
    final state = _messageBloc.state;
    if (state is! MessagesLoaded) return;

    final domainMessage = state.messages
        .cast<ChatMessage?>()
        .firstWhere((m) => m?.id == message.id, orElse: () => null);
    if (domainMessage == null) return;

    final isCurrentUser = domainMessage.sender.id == _currentUserId;
    _showMessageOptions(context, domainMessage, isCurrentUser);
  }

  void _onAttachmentTap() {
    // Reserved for Phase 4: Media & Attachments
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
        body: BlocConsumer<MessageBloc, MessageState>(
          listener: (context, state) {
            if (state is MessagesError) {
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
                child: AppProgressIndicator.circular(
                  label: context.l10n.loading,
                ),
              );
            }

            if (state is MessagesError && state.previousMessages == null) {
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

            // MessagesLoaded or MessagesError with previousMessages
            return flyer_ui.Chat(
              currentUserId: _currentUserId,
              resolveUser: _userResolver.resolve,
              chatController: _chatController,
              theme: flyer.ChatTheme.fromThemeData(Theme.of(context)),
              onMessageSend: _onMessageSend,
              onMessageTap: _onMessageTap,
              onMessageLongPress: _onMessageLongPress,
              onAttachmentTap: _onAttachmentTap,
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    VoidCallback? retryAction,
  ) {
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

  void _showMessageOptions(
    BuildContext context,
    ChatMessage message,
    bool isCurrentUser,
  ) {
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
                Navigator.pop(context);
              },
            ),
            if (isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: AppText(context.l10n.editMessage),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement edit via Flyer composer
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
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
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
