import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/image_compression_helper.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_conversation_detail_usecase.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/features/chat/presentation/screens/chat/chat_header.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/forward_message_sheet.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/read_receipt_avatars.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/reply_preview.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/typing_indicator.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/message_item.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/emoji_picker_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/attachment_picker_widget.dart';
import 'package:get_it/get_it.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'dart:io';

import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/app_card.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/dialogs/app_alert_dialog.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/inputs/app_text_field.dart';
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
  late final AutoScrollController _scrollController;
  late final MessageBloc _messageBloc;
  late final GetConversationDetailUseCase _getConversationDetail;
  Chat? _chat;
  String _currentUserId = '';
  bool _hasInitializedContext = false;

  bool _isProgrammaticScroll = false;

  static const int _pageSize = 50;
  bool _isLoadingMore = false;
  DateTime? _lastLoadMoreAt;
  String? _lastLoadMoreCursor;
  String? _pendingScrollToMessageId;
  int _pendingScrollAttempts = 0;
  static const int _maxPendingScrollAttempts = 8;

  // ══════════════════════════════════════════
  // Reply / Edit state
  // ══════════════════════════════════════════
  ChatMessage? _replyingToMessage;
  bool _isEditMode = false;
  String? _editingMessageId;

  // ══════════════════════════════════════════
  // Selection mode state
  // ══════════════════════════════════════════
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

  // ══════════════════════════════════════════
  // Typing indicator state
  // ══════════════════════════════════════════
  bool _isOtherTyping = false;
  String? _typingUserName;
  StreamSubscription? _typingSubscription;
  Timer? _typingDebounceTimer;

  // ══════════════════════════════════════════
  // Scroll-to-bottom FAB state
  // ══════════════════════════════════════════
  bool _showScrollToBottom = false;
  int _newMessageCount = 0;

  // ══════════════════════════════════════════
  // Read receipts state
  // ══════════════════════════════════════════
  final Map<String, List<ReaderInfo>> _readReceipts = {};
  StreamSubscription? _readReceiptSubscription;

  // ══════════════════════════════════════════
  // Highlight state (scroll-to-reply)
  // ══════════════════════════════════════════
  String? _highlightedMessageId;

  @override
  void initState() {
    super.initState();
    _messageBloc = getIt<MessageBloc>();
    _getConversationDetail = getIt<GetConversationDetailUseCase>();

    _scrollController = AutoScrollController(axis: Axis.vertical);
    _scrollController.addListener(_onScroll);

    // Load initial messages
    _messageBloc.add(
      LoadMessages(
        chatId: widget.chatId,
        limit: _pageSize,
        forceRefresh: false,
      ),
    );

    _loadChatHeader();
    _setupTypingSubscription();
    _setupReadReceiptSubscription();
    _setupTypingDebounce();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedContext) {
      _hasInitializedContext = true;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _currentUserId = authState.user.id;
        _messageBloc.setTransformContext(
          currentUserId: _currentUserId,
          isGroupChat: _chat?.type == ChatType.group,
        );
      }
    }
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
        _messageBloc.setTransformContext(
          currentUserId: _currentUserId,
          isGroupChat: chat.type == ChatType.group,
        );
      },
    );
  }

  void _setupTypingSubscription() {
    if (!getIt.isRegistered<RealtimeService>()) return;
    final realtimeService = getIt<RealtimeService>();
    _typingSubscription = realtimeService.typingStream
        .where((e) => e.chatId == widget.chatId && e.userId != _currentUserId)
        .listen((event) {
      safeSetState(() {
        _isOtherTyping = event.isTyping;
        _typingUserName = event.isTyping ? event.userName : null;
      });
    });
  }

  void _setupReadReceiptSubscription() {
    if (!getIt.isRegistered<RealtimeService>()) return;
    final realtimeService = getIt<RealtimeService>();
    _readReceiptSubscription = realtimeService.readReceiptStream
        .where((e) => e.chatId == widget.chatId)
        .listen((event) {
      safeSetState(() {
        final readers = _readReceipts[event.messageId] ?? [];
        if (!readers.any((r) => r.userId == event.readerId)) {
          readers.add(ReaderInfo(
            userId: event.readerId,
            name: event.readerName,
          ));
          _readReceipts[event.messageId] = readers;
        }
      });
    });
  }

  void _setupTypingDebounce() {
    _messageController.addListener(() {
      if (!getIt.isRegistered<RealtimeService>()) return;
      final realtimeService = getIt<RealtimeService>();

      _typingDebounceTimer?.cancel();

      if (_messageController.text.isNotEmpty) {
        realtimeService.sendTypingIndicator(
          chatId: widget.chatId,
          isTyping: true,
        );
      }

      _typingDebounceTimer = Timer(const Duration(seconds: 2), () {
        realtimeService.sendTypingIndicator(
          chatId: widget.chatId,
          isTyping: false,
        );
      });
    });
  }

  void _onScroll() {
    if (_isProgrammaticScroll) return;
    // Pagination: load more when near top (reverse list)
    final position = _scrollController.position;
    if (position.hasPixels) {
      // For reverse lists, "top" means nearing maxScrollExtent.
      // Using extentAfter is more robust than maxScrollExtent ratios and also
      // works when maxScrollExtent == 0 (short lists).
      if (position.extentAfter < 200) {
        _loadMore();
      }
    }

    // Scroll-to-bottom FAB visibility
    final showFab = _scrollController.offset > 200;
    if (showFab != _showScrollToBottom) {
      safeSetState(() {
        _showScrollToBottom = showFab;
        if (!showFab) _newMessageCount = 0;
      });
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;

    final now = DateTime.now();
    if (_lastLoadMoreAt != null && now.difference(_lastLoadMoreAt!) < const Duration(milliseconds: 700)) {
      return;
    }

    final state = _messageBloc.state;
    if (state is! MessagesLoaded) return;
    if (state.hasReachedMax) return;

    final cursor = state.messages.isNotEmpty
        ? state.messages.last.createdAt.millisecondsSinceEpoch.toString()
        : null;
    if (cursor != null && cursor == _lastLoadMoreCursor) {
      return;
    }

    _lastLoadMoreAt = now;
    _lastLoadMoreCursor = cursor;

    safeSetState(() => _isLoadingMore = true);
    _messageBloc.add(const LoadMoreMessages(limit: _pageSize));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageBloc.close();
    _typingSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _typingDebounceTimer?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════
  // Send / Edit / Reply
  // ══════════════════════════════════════════

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

    if (_isEditMode && _editingMessageId != null) {
      _messageBloc.add(EditMessage(
        messageId: _editingMessageId!,
        content: text,
      ));
      _cancelEditMode();
    } else {
      _messageBloc.add(
        SendMessage(
          content: text,
          senderId: _currentUserId,
          contentType: 'text',
          attachmentIds: const [],
          replyMessageId: _replyingToMessage?.id,
        ),
      );
      _cancelReply();
    }

    _messageController.clear();
  }

  void _startReply(ChatMessage message) {
    safeSetState(() {
      _replyingToMessage = message;
      _isEditMode = false;
      _editingMessageId = null;
    });
  }

  void _cancelReply() {
    safeSetState(() => _replyingToMessage = null);
  }

  void _startEditMode(ChatMessage message) {
    safeSetState(() {
      _isEditMode = true;
      _editingMessageId = message.id;
      _replyingToMessage = null;
    });
    _messageController.text = message.content;
  }

  void _cancelEditMode() {
    safeSetState(() {
      _isEditMode = false;
      _editingMessageId = null;
    });
  }

  // ══════════════════════════════════════════
  // Selection mode
  // ══════════════════════════════════════════

  void _enterSelectionMode(String messageId) {
    safeSetState(() {
      _isSelectionMode = true;
      _selectedMessageIds.add(messageId);
    });
  }

  void _exitSelectionMode() {
    safeSetState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _toggleSelection(String messageId) {
    safeSetState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _copySelectedMessages(List<MessageUIState> uiMessages) {
    final contents = uiMessages
        .where((m) => _selectedMessageIds.contains(m.id))
        .map((m) => m.content)
        .where((c) => c.isNotEmpty)
        .join('\n');
    Clipboard.setData(ClipboardData(text: contents));
    AppSnackBar.show(
      context: context,
      message: context.l10n.messageCopied,
      type: FeedbackType.success,
    );
    _exitSelectionMode();
  }

  void _deleteSelectedMessages() {
    final count = _selectedMessageIds.length;
    AppAlertDialog.show(
      context: context,
      title: context.l10n.deleteMessage,
      content: context.l10n.confirmDeleteMultiple(count),
      actions: [
        AppButton.text(
          text: context.l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          text: context.l10n.delete,
          onPressed: () {
            Navigator.pop(context);
            for (final id in _selectedMessageIds) {
              _messageBloc.add(DeleteMessage(id));
            }
            _exitSelectionMode();
          },
        ),
      ],
    );
  }

  void _forwardSelectedMessages() {
    showForwardMessageSheet(context);
    _exitSelectionMode();
  }

  // ══════════════════════════════════════════
  // Scroll-to-message
  // ══════════════════════════════════════════

  void _scrollToMessage(String? targetMessageId, List<MessageUIState> uiMessages) {
    if (targetMessageId == null) return;

    final index = uiMessages.indexWhere((m) => m.id == targetMessageId);
    if (index == -1) {
      _pendingScrollToMessageId = targetMessageId;
      _pendingScrollAttempts = 0;
      _loadMore();
      return;
    }

    _scrollController.scrollToIndex(
      index,
      preferPosition: AutoScrollPosition.middle,
      duration: const Duration(milliseconds: 400),
    );

    _isProgrammaticScroll = true;
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      _isProgrammaticScroll = false;
    });

    // Highlight for 2 seconds
    safeSetState(() => _highlightedMessageId = targetMessageId);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) safeSetState(() => _highlightedMessageId = null);
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    safeSetState(() {
      _showScrollToBottom = false;
      _newMessageCount = 0;
    });
  }

  // ══════════════════════════════════════════
  // Attachment handlers
  // ══════════════════════════════════════════

  /// Show attachment picker bottom sheet
  void _showAttachmentPicker() {
    AttachmentPickerBottomSheet.show(
      context,
      onImageFromCamera: _handleImageFromCamera,
      onImageFromGallery: _handleImageFromGallery,
      onFileSelected: _handleFileSelected,
      onLocationShare: _handleLocationShare,
    );
  }

  Future<void> _handleImageFromCamera(File imageFile) async {
    await _processAndSendImage(imageFile);
  }

  Future<void> _handleImageFromGallery(File imageFile) async {
    await _processAndSendImage(imageFile);
  }

  Future<void> _handleFileSelected(File file) async {
    AppSnackBar.show(
      context: context,
      message: 'File upload: ${file.path}',
      type: FeedbackType.info,
    );
  }

  void _handleLocationShare() {
    AppSnackBar.show(
      context: context,
      message: context.l10n.shareLocation,
      type: FeedbackType.info,
    );
  }

  /// Process and send image with compression
  Future<void> _processAndSendImage(File imageFile) async {
    try {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: context.l10n.compressing,
          type: FeedbackType.info,
        );
      }

      final compressedImage = await ImageCompressionHelper.compressImage(imageFile);

      if (compressedImage == null) {
        if (mounted) {
          AppSnackBar.show(
            context: context,
            message: context.l10n.imageCompressionFailed,
            type: FeedbackType.error,
          );
        }
        return;
      }

      if (mounted) {
        final fileSize = await compressedImage.length();
        final formattedSize = ImageCompressionHelper.formatFileSize(fileSize);

        AppSnackBar.show(
          context: context,
          message: 'Image ready to upload: $formattedSize',
          type: FeedbackType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: context.l10n.errorOccurred,
          type: FeedbackType.error,
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    _messageBloc.add(const RefreshMessages());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ══════════════════════════════════════════
  // Build methods
  // ══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final chatTitle = (_chat?.name?.trim().isNotEmpty ?? false)
        ? _chat!.name!.trim()
        : context.l10n.chats;

    return BlocProvider<MessageBloc>.value(
      value: _messageBloc,
      child: Scaffold(
        appBar: _isSelectionMode
            ? _buildSelectionAppBar()
            : _buildNormalAppBar(chatTitle),
        body: Column(
          children: [
            // Chat messages
            Expanded(
              child: Stack(
                children: [
                  BlocConsumer<MessageBloc, MessageState>(
                    listener: (context, state) {
                      if (state is MessagesLoaded) {
                        safeSetState(() => _isLoadingMore = false);

                        final pendingId = _pendingScrollToMessageId;
                        if (pendingId != null && pendingId.isNotEmpty) {
                          final index = state.uiMessages.indexWhere((m) => m.id == pendingId);
                          if (index != -1) {
                            _pendingScrollToMessageId = null;
                            _pendingScrollAttempts = 0;
                            _scrollController.scrollToIndex(
                              index,
                              preferPosition: AutoScrollPosition.middle,
                              duration: const Duration(milliseconds: 400),
                            );
                            _isProgrammaticScroll = true;
                            Future.delayed(const Duration(milliseconds: 550), () {
                              if (!mounted) return;
                              _isProgrammaticScroll = false;
                            });
                          } else {
                            if (!state.hasReachedMax && _pendingScrollAttempts < _maxPendingScrollAttempts) {
                              _pendingScrollAttempts++;
                              _loadMore();
                            } else {
                              _pendingScrollToMessageId = null;
                              _pendingScrollAttempts = 0;
                              AppSnackBar.show(
                                context: context,
                                message: context.l10n.messageNotFound,
                                type: FeedbackType.warning,
                              );
                            }
                          }
                        }

                        // Track new messages when scrolled up
                        if (_showScrollToBottom) {
                          safeSetState(() => _newMessageCount++);
                        }
                      } else if (state is MessagesError) {
                        safeSetState(() => _isLoadingMore = false);
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
                        final uiMessages = state.uiMessages;
                        final hasMore = !state.hasReachedMax;

                        if (uiMessages.isEmpty) {
                          return _buildEmptyState(context);
                        }

                        return RefreshIndicator(
                          onRefresh: _onRefresh,
                          child: ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(AppDimens.paddingSmall),
                            itemCount: uiMessages.length + (hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Loading indicator at the top (end of reverse list)
                              if (hasMore && index == uiMessages.length) {
                                return _isLoadingMore
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }

                              final uiState = uiMessages[index];
                              return AutoScrollTag(
                                key: ValueKey(uiState.id.isNotEmpty ? uiState.id : 'item_$index'),
                                controller: _scrollController,
                                index: index,
                                child: _buildListItem(context, uiState, uiMessages),
                              );
                            },
                          ),
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

                  // Scroll-to-bottom FAB
                  if (_showScrollToBottom)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Badge(
                        isLabelVisible: _newMessageCount > 0,
                        label: Text('$_newMessageCount'),
                        child: FloatingActionButton.small(
                          heroTag: 'scrollToBottom',
                          onPressed: _scrollToBottom,
                          tooltip: context.l10n.scrollToBottom,
                          child: const Icon(Icons.keyboard_arrow_down),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Typing indicator
            TypingIndicatorWithFade(
              isTyping: _isOtherTyping,
              displayName: _typingUserName,
            ),

            // Reply input bar
            if (_replyingToMessage != null)
              ReplyInputBar(
                replyMessage: ReplyMessagePreview(
                  id: _replyingToMessage!.id,
                  senderName: _replyingToMessage!.sender.name,
                  contentType: _replyingToMessage!.contentType,
                  previewText: _replyingToMessage!.content,
                ),
                onCancel: _cancelReply,
              ),

            // Edit mode bar
            if (_isEditMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.tertiary,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.editingMessage,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        _cancelEditMode();
                        _messageController.clear();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
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
                    onPressed: _showAttachmentPicker,
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
                      EmojiPickerBottomSheet.show(
                        context,
                        onEmojiSelected: (emoji) {
                          EmojiTextEditingHelper.insertEmoji(
                            _messageController,
                            emoji,
                          );
                        },
                        textController: _messageController,
                      );
                    },
                  ),
                  AppButton.primary(
                    text: _isEditMode ? context.l10n.save : context.l10n.send,
                    icon: _isEditMode ? Icons.check : Icons.send,
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

  PreferredSizeWidget _buildNormalAppBar(String chatTitle) {
    final subtitleText = _isOtherTyping && _typingUserName != null
        ? context.l10n.isTyping(_typingUserName!)
        : context.l10n.online;

    final chat = _chat;
    if (chat != null) {
      return ChatHeader(
        chat: chat,
        onBackPressed: () => Navigator.of(context).pop(),
        onInfoPressed: () {},
      );
    }

    return AppBar(
      title: Column(
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
            subtitleText,
            style: AppTextStyles.labelSmall.copyWith(
              color: _isOtherTyping ? AppColors.primary : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () {},
        ),
        PopupMenuButton<String>(
          onSelected: (value) {},
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
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: AppText(
        context.l10n.selectedCount(_selectedMessageIds.length),
        style: AppTextStyles.titleMedium,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: context.l10n.copyMessage,
          onPressed: () {
            final state = _messageBloc.state;
            if (state is MessagesLoaded) {
              _copySelectedMessages(state.uiMessages);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.forward),
          tooltip: context.l10n.forwardMessage,
          onPressed: _forwardSelectedMessages,
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: context.l10n.deleteMessage,
          onPressed: _deleteSelectedMessages,
        ),
      ],
    );
  }

  Widget _buildListItem(
    BuildContext context,
    MessageUIState uiState,
    List<MessageUIState> allMessages,
  ) {
    switch (uiState.itemType) {
      case MessageListItemType.dateSeparator:
        return _buildDateSeparator(uiState.dateSeparatorText ?? '');
      case MessageListItemType.unreadSeparator:
        return _buildUnreadSeparator();
      case MessageListItemType.systemEvent:
        return _buildSystemEvent(uiState);
      case MessageListItemType.message:
        final isHighlighted = _highlightedMessageId == uiState.id;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: isHighlighted
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (uiState.showDateSeparator)
                _buildDateSeparator(uiState.dateSeparatorText ?? ''),
              MessageItem(
                uiState: uiState,
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedMessageIds.contains(uiState.id),
                onSelectionChanged: (_) => _toggleSelection(uiState.id),
                onSwipeReply: () {
                  if (uiState.message != null) {
                    _startReply(uiState.message!);
                  }
                },
                onReplyPreviewTap: () {
                  _scrollToMessage(uiState.replyMessage?.id, allMessages);
                },
                readReceipts: _readReceipts[uiState.id],
                onLongPress: () {
                  if (_isSelectionMode) return;
                  if (uiState.message != null) {
                    _showMessageOptions(
                      context,
                      uiState.message!,
                      uiState.isFromCurrentUser,
                    );
                  }
                },
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(uiState.id);
                  }
                },
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDateSeparator(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceSmall),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMedium,
            vertical: AppDimens.paddingXSmall,
          ),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          child: AppText(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceSmall),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: AppColors.error.withOpacity(0.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingSmall,
            ),
            child: AppText(
              context.l10n.unreadSeparatorLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: AppColors.error.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemEvent(MessageUIState uiState) {
    final text = uiState.systemEvent?.formattedText ?? uiState.content;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.spaceSmall,
        horizontal: AppDimens.paddingMedium,
      ),
      child: Center(
        child: AppText(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
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
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: AppText(ctx.l10n.copyMessage),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: message.content));
                AppSnackBar.show(
                  context: this.context,
                  message: this.context.l10n.messageCopied,
                  type: FeedbackType.success,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: AppText(ctx.l10n.replyMessage),
              onTap: () {
                Navigator.pop(ctx);
                _startReply(message);
              },
            ),
            if (isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: AppText(ctx.l10n.editMessage),
                onTap: () {
                  Navigator.pop(ctx);
                  _startEditMode(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: AppText(ctx.l10n.deleteMessage),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteMessage(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.forward),
              title: AppText(ctx.l10n.forwardMessage),
              onTap: () {
                Navigator.pop(ctx);
                showForwardMessageSheet(this.context, messages: [message]);
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: AppText(ctx.l10n.selectAll),
              onTap: () {
                Navigator.pop(ctx);
                _enterSelectionMode(message.id);
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
