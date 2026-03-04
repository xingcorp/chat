import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/extensions/extensions.dart';
import 'package:flutter_chat_app/core/services/location_service.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/core/services/voice_recorder_service.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/image_compression_helper.dart';
import 'package:flutter_chat_app/domain/entities/sticker.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/data/datasources/user/user_remote_datasource.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat_composer/chat_composer_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat_draft/chat_draft_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/message_search/message_search_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/chat_slash_command_engine.dart';
import 'package:flutter_chat_app/presentation/screens/media/image_preview_screen.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/features/chat/presentation/screens/chat/chat_header.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/attachment_picker_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/chat_message_timeline.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/emoji_picker_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/forward_message_sheet.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/mention_text_field.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/message_item.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/add_member_panel.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/message_search_panel.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/reply_preview.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/typing_indicator.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/conversation_detail/conversation_detail_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/conversation_detail/conversation_detail_event.dart';
import 'package:flutter_chat_app/presentation/blocs/conversation_detail/conversation_detail_state.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_info/chat_info_bloc.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_icon_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/button_enums.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/app_card.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/sticker_picker.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/dialogs/app_alert_dialog.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/chat_info_panel.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:permission_handler/permission_handler.dart';

// Service locator instance
final getIt = GetIt.instance;

class _SendMessageShortcutIntent extends Intent {
  const _SendMessageShortcutIntent();
}

class _DismissChatInputShortcutIntent extends Intent {
  const _DismissChatInputShortcutIntent();
}

class _OpenMessageSearchShortcutIntent extends Intent {
  const _OpenMessageSearchShortcutIntent();
}

class _FocusMessageInputShortcutIntent extends Intent {
  const _FocusMessageInputShortcutIntent();
}

class _CopySelectedMessagesShortcutIntent extends Intent {
  const _CopySelectedMessagesShortcutIntent();
}

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
  final MentionTextEditingController _messageController =
      MentionTextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final ScrollOffsetController _scrollOffsetController =
      ScrollOffsetController();
  final ScrollOffsetListener _scrollOffsetListener =
      ScrollOffsetListener.create();
  late final MessageBloc _messageBloc;
  late final ConversationDetailBloc _convDetailBloc;
  late final ChatComposerBloc _chatComposerBloc;
  late final ChatDraftBloc _chatDraftBloc;
  bool _ownsChatDraftBloc = false;

  Chat? _chat;
  String _currentUserId = '';
  String _currentUserDisplayName = '';
  bool _hasInitializedContext = false;

  static const int _pageSize = 50;
  bool _isLoadingMore = false;
  DateTime? _lastLoadMoreAt;
  String? _oldestMessageIdBeforeLoadMore;
  Timer? _loadMoreSafetyTimer;
  String? _pendingScrollToMessageId;
  int? _pendingScrollCreatedAtMs;
  int _pendingScrollAttempts = 0;
  static const int _maxPendingScrollAttempts = 3;

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
  bool _hasTrackedLatestMessage = false;
  String? _latestMessageId;

  // ══════════════════════════════════════════
  // Highlight state (scroll-to-reply)
  // ══════════════════════════════════════════
  String? _highlightedMessageId;

  // ══════════════════════════════════════════
  // Mark-as-read state
  // ══════════════════════════════════════════
  bool _hasMarkedAsReadOnOpen = false;

  // ══════════════════════════════════════════
  // Voice recording state
  // ══════════════════════════════════════════
  late final VoiceRecorderService _voiceRecorderService;
  StreamSubscription<double>? _recordingAmplitudeSubscription;
  StreamSubscription<String>? _recordingLimitReachedSubscription;
  Timer? _recordingTimer;
  DateTime? _recordingStartedAt;
  bool _isRecordingVoice = false;
  bool _isSlidingToCancel = false;
  double _recordingAmplitude = 0.0;
  Duration _recordingDuration = Duration.zero;
  double? _recordingDragStartDx;
  DateTime? _lastVoiceRecordingHintAt;

  @override
  void initState() {
    super.initState();
    // MessageBloc is a factory in DI, so this instance is unique to this page instance.
    // When chatId changes in desktop view, ValueKey forces a new State instance,
    // ensuring clean state and correct bloc scope.
    _messageBloc = getIt<MessageBloc>();
    _convDetailBloc = getIt<ConversationDetailBloc>();
    _chatComposerBloc = getIt<ChatComposerBloc>();
    try {
      _chatDraftBloc = context.read<ChatDraftBloc>();
      _ownsChatDraftBloc = false;
    } catch (_) {
      _chatDraftBloc = getIt<ChatDraftBloc>();
      _ownsChatDraftBloc = true;
    }
    _voiceRecorderService = getIt<VoiceRecorderService>();
    _messageBloc.add(const FetchFrequentReactions());

    _recordingAmplitudeSubscription =
        _voiceRecorderService.amplitudeStream.listen((amplitude) {
      if (!mounted) return;
      safeSetState(() {
        _recordingAmplitude = amplitude.clamp(0.0, 1.0);
      });
    });
    _recordingLimitReachedSubscription =
        _voiceRecorderService.recordingLimitReachedStream.listen((filePath) {
      _handleVoiceRecordingLimitReached(filePath);
    });

    _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);

    // Initial load
    _messageBloc.add(
      LoadMessages(
        chatId: widget.chatId,
        limit: _pageSize,
        forceRefresh: false,
      ),
    );

    _convDetailBloc.add(LoadConversationDetail(chatId: widget.chatId));
    _setupRealtimeSubscriptions();
    _chatDraftBloc.add(
      ChatDraftConversationOpened(conversationId: widget.chatId),
    );

    // Single listener for efficiency
    _messageController.addListener(_handleControllerChanges);
  }

  void _handleControllerChanges() {
    if (!mounted) return;
    safeSetState(() {});
    _handleTypingIndicator();
    _chatDraftBloc.add(
      ChatDraftInputChanged(
        conversationId: widget.chatId,
        text: _messageController.text,
        mentionNameById: _messageController.mentionNameById,
        isEditMode: _isEditMode,
        isRecordingVoice: _isRecordingVoice,
      ),
    );
  }

  void _handleTypingIndicator() {
    if (!getIt.isRegistered<RealtimeService>()) return;
    final realtimeService = getIt<RealtimeService>();

    _typingDebounceTimer?.cancel();

    if (_messageController.text.isNotEmpty) {
      unawaited(realtimeService.sendTypingIndicator(
        chatId: widget.chatId,
        isTyping: true,
      ));
    }

    _typingDebounceTimer = Timer(const Duration(seconds: 2), () {
      unawaited(realtimeService.sendTypingIndicator(
        chatId: widget.chatId,
        isTyping: false,
      ));
    });
  }

  void _setupRealtimeSubscriptions() {
    if (!getIt.isRegistered<RealtimeService>()) return;
    final realtimeService = getIt<RealtimeService>();

    // Typing
    _typingSubscription = realtimeService.typingStream
        .where((e) => e.chatId == widget.chatId && e.userId != _currentUserId)
        .listen((event) {
      safeSetState(() {
        _isOtherTyping = event.isTyping;
        _typingUserName = event.isTyping ? event.userName : null;
      });
    });

    // Read receipts are handled by MessageBloc (ReceiveMessageRead event)
    // which updates readBy on messages and re-transforms to readReceiptReaders
  }

  void _handleDraftStateChanges(BuildContext context, ChatDraftState state) {
    final draft = state.restoreDraft;
    if (state.restoreConversationId == widget.chatId &&
        draft != null &&
        draft.hasContent) {
      if (_messageController.text.trim().isEmpty) {
        _messageController.updateMentions(draft.mentionNameById);
        _messageController.value = TextEditingValue(
          text: draft.text,
          selection: TextSelection.collapsed(offset: draft.text.length),
        );
      }
      _chatDraftBloc.add(
        ChatDraftRestoreHandled(conversationId: widget.chatId),
      );
    }

    final errorMessage = state.errorMessage;
    if (errorMessage == null || errorMessage.trim().isEmpty) {
      return;
    }

    AppSnackBar.show(
      context: context,
      message: errorMessage,
      type: FeedbackType.warning,
    );
    _chatDraftBloc.add(const ChatDraftErrorCleared());
  }

  void _handleComposerStateChanges(
    BuildContext context,
    ChatComposerState state,
  ) {
    final effect = state.effect;
    if (effect == null) {
      return;
    }

    switch (effect) {
      case ChatComposerShowWarningEffect warningEffect:
        final message = switch (warningEffect.warning) {
          ChatComposerWarning.emptyMessage => context.l10n.messageEmpty,
          ChatComposerWarning.missingSlashArgument =>
            context.l10n.slashCommandMissingArgument,
          ChatComposerWarning.unknownSlashCommand =>
            context.l10n.slashCommandUnknown,
        };

        AppSnackBar.show(
          context: context,
          message: message,
          type: FeedbackType.warning,
        );
        break;

      case ChatComposerEditTextEffect editEffect:
        final editedText =
            _messageController.toBackendMentionFormat(editEffect.text).trim();
        if (editedText.isEmpty) {
          AppSnackBar.show(
            context: context,
            message: context.l10n.messageEmpty,
            type: FeedbackType.warning,
          );
          break;
        }

        _messageBloc.add(EditMessage(
          messageId: editEffect.messageId,
          content: editedText,
        ));
        _cancelEditMode();
        _messageController.clear();
        _chatDraftBloc.add(
          ChatDraftClearRequested(conversationId: widget.chatId),
        );
        break;

      case ChatComposerSendTextEffect sendEffect:
        final messageText =
            _messageController.toBackendMentionFormat(sendEffect.text).trim();
        if (messageText.isEmpty) {
          AppSnackBar.show(
            context: context,
            message: context.l10n.messageEmpty,
            type: FeedbackType.warning,
          );
          break;
        }

        _messageBloc.add(
          SendMessage(
            content: messageText,
            senderId: _currentUserId,
            contentType: 'text',
            attachmentIds: const [],
            replyMessageId: _replyingToMessage?.id,
          ),
        );
        _chatDraftBloc.add(
          ChatDraftMessageQueued(
            conversationId: widget.chatId,
            content: messageText,
            queuedAt: DateTime.now(),
          ),
        );
        _cancelReply();
        _messageController.clear();
        break;

      case ChatComposerMuteActionEffect _:
        _messageController.clear();
        _chatDraftBloc.add(
          ChatDraftClearRequested(conversationId: widget.chatId),
        );
        _cancelReply();
        _handleMuteSlashCommandAction();
        break;

      case ChatComposerDismissEffect dismissEffect:
        switch (dismissEffect.action) {
          case ChatComposerDismissAction.exitSelection:
            _exitSelectionMode();
            break;
          case ChatComposerDismissAction.cancelEditAndClear:
            _cancelEditMode();
            _messageController.clear();
            _chatDraftBloc.add(
              ChatDraftClearRequested(conversationId: widget.chatId),
            );
            break;
          case ChatComposerDismissAction.cancelReply:
            _cancelReply();
            break;
          case ChatComposerDismissAction.none:
            break;
        }
        break;
    }

    _chatComposerBloc.add(const ChatComposerEffectConsumed());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedContext) {
      _hasInitializedContext = true;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _currentUserId = authState.user.id;
        _currentUserDisplayName =
            (authState.user.fullName?.trim().isNotEmpty ?? false)
                ? authState.user.fullName!.trim()
                : authState.user.username;
        _messageBloc.setTransformContext(
          currentUserId: _currentUserId,
          isGroupChat: _chat?.type == ChatType.group,
        );
      }
    }
  }

  /// Detect load-more and scroll-to-bottom FAB via visible item positions.
  void _onPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // --- Load more: check if max visible index is near the end ---
    final state = _messageBloc.state;
    if (state is MessagesLoaded) {
      final maxVisibleIndex =
          positions.map((p) => p.index).reduce((a, b) => a > b ? a : b);
      final totalItems = state.uiMessages.length;

      if (maxVisibleIndex >= totalItems - 3 && !_isLoadingMore) {
        _loadMore();
      }
    }

    // --- Scroll-to-bottom FAB: show when newest message (index 0) is not visible ---
    final minVisibleIndex = positions
        .where((p) => p.itemTrailingEdge > 0 && p.itemLeadingEdge < 1)
        .map((p) => p.index)
        .fold<int?>(null,
            (prev, idx) => prev == null ? idx : (idx < prev ? idx : prev));
    final showFab = minVisibleIndex != null && minVisibleIndex > 2;
    if (showFab != _showScrollToBottom) {
      safeSetState(() {
        _showScrollToBottom = showFab;
        if (!showFab) _newMessageCount = 0;
      });

      // When user scrolls back to bottom (newest messages visible),
      // mark chat as read for any unread messages (Req 5.2).
      // The BLoC's 500ms debounce handles rapid scroll events.
      if (!showFab) {
        _messageBloc.add(MarkChatAsRead(widget.chatId));
      }
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;

    final now = DateTime.now();
    if (_lastLoadMoreAt != null &&
        now.difference(_lastLoadMoreAt!) < const Duration(milliseconds: 700)) {
      return;
    }

    final state = _messageBloc.state;
    if (state is! MessagesLoaded) return;
    if (state.hasReachedMax) return;
    if (state.messages.isEmpty) return;

    _lastLoadMoreAt = now;
    _oldestMessageIdBeforeLoadMore = state.messages.last.id;

    safeSetState(() => _isLoadingMore = true);

    // Safety timer: force-reset if BLoC never responds (e.g. event dropped,
    // network hung). 15s is generous enough for slow connections.
    _loadMoreSafetyTimer?.cancel();
    _loadMoreSafetyTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || !_isLoadingMore) return;
      safeSetState(() => _isLoadingMore = false);
    });

    _messageBloc.add(const LoadMoreMessages(limit: _pageSize));
  }

  @override
  void dispose() {
    _chatDraftBloc.add(
      ChatDraftFlushRequested(
        conversationId: widget.chatId,
        text: _messageController.text,
        mentionNameById: _messageController.mentionNameById,
        isEditMode: _isEditMode,
        isRecordingVoice: _isRecordingVoice,
      ),
    );

    _messageController.removeListener(_handleControllerChanges);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    _messageBloc.close();
    _convDetailBloc.close();
    _chatComposerBloc.close();
    if (_ownsChatDraftBloc) {
      _chatDraftBloc.close();
    }
    _typingSubscription?.cancel();
    _typingDebounceTimer?.cancel();
    _loadMoreSafetyTimer?.cancel();
    _recordingAmplitudeSubscription?.cancel();
    _recordingLimitReachedSubscription?.cancel();
    _recordingTimer?.cancel();
    if (_isRecordingVoice) {
      unawaited(_voiceRecorderService.cancelRecording());
    }
    super.dispose();
  }

  // ══════════════════════════════════════════
  // Actions
  // ══════════════════════════════════════════

  void _sendMessage() {
    _chatComposerBloc.add(
      ChatComposerSendRequested(
        rawInput: _messageController.text,
        actorDisplayName: _currentUserDisplayName.isNotEmpty
            ? _currentUserDisplayName
            : context.l10n.you,
        isEditMode: _isEditMode,
        editingMessageId: _editingMessageId,
      ),
    );
  }

  void _handleMuteSlashCommandAction() {
    if (_chat != null) {
      _showChatInfo();
    }
    AppSnackBar.show(
      context: context,
      message: context.l10n.slashCommandMuteActionHint,
      type: FeedbackType.info,
    );
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

  List<MessageUIState> _getSelectedUiMessages(List<MessageUIState> uiMessages) {
    if (_selectedMessageIds.isEmpty) return const [];
    return uiMessages
        .where((uiMessage) =>
            uiMessage.itemType == MessageListItemType.message &&
            uiMessage.message != null &&
            _selectedMessageIds.contains(uiMessage.id))
        .toList(growable: false);
  }

  List<ChatMessage> _getSelectedMessages(List<MessageUIState> uiMessages) {
    return _getSelectedUiMessages(uiMessages)
        .map((uiMessage) => uiMessage.message!)
        .toList(growable: false);
  }

  bool _canDeleteSelectedMessages(List<MessageUIState> uiMessages) {
    final selectedUiMessages = _getSelectedUiMessages(uiMessages);
    if (selectedUiMessages.isEmpty) return false;
    return selectedUiMessages.every((uiMessage) => uiMessage.isFromCurrentUser);
  }

  void _copySelectedMessages(List<MessageUIState> uiMessages) {
    final contents = _getSelectedUiMessages(uiMessages)
        .where((m) => m.contentType == ContentType.text)
        .map((m) => m.content)
        .where((c) => c.isNotEmpty)
        .join('\n');
    if (contents.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: context.l10n.onlyTextMessagesCanBeCopied,
        type: FeedbackType.info,
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: contents));
    AppSnackBar.show(
      context: context,
      message: context.l10n.messageCopied,
      type: FeedbackType.success,
    );
    _exitSelectionMode();
  }

  void _deleteSelectedMessages() {
    final state = _messageBloc.state;
    if (state is! MessagesLoaded) return;

    final selectedUiMessages = _getSelectedUiMessages(state.uiMessages);
    if (selectedUiMessages.isEmpty) return;

    final canDelete = selectedUiMessages.every((m) => m.isFromCurrentUser);
    if (!canDelete) return;

    final selectedIds =
        selectedUiMessages.map((uiMessage) => uiMessage.id).toList();
    final count = selectedIds.length;

    AppAlertDialog.show<bool>(
      context: context,
      title: context.l10n.deleteMessage,
      content: context.l10n.confirmDeleteMultiple(count),
      actions: [
        AppButton.text(
          text: context.l10n.cancel,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
        AppButton.primary(
          text: context.l10n.delete,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop(true);
          },
        ),
      ],
    ).then((confirmed) {
      if (confirmed != true) return;
      for (final id in selectedIds) {
        _messageBloc.add(DeleteMessage(id));
      }
      _exitSelectionMode();
    });
  }

  bool get _isDesktopKeyboardPlatform {
    if (kIsWeb) return true;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  Widget _buildShortcutHost(Widget child) {
    if (!_isDesktopKeyboardPlatform) {
      return child;
    }

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): _SendMessageShortcutIntent(),
        SingleActivator(LogicalKeyboardKey.escape):
            _DismissChatInputShortcutIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _OpenMessageSearchShortcutIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _OpenMessageSearchShortcutIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _FocusMessageInputShortcutIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _FocusMessageInputShortcutIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyC,
          control: true,
          shift: true,
        ): _CopySelectedMessagesShortcutIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyC,
          meta: true,
          shift: true,
        ): _CopySelectedMessagesShortcutIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SendMessageShortcutIntent:
              CallbackAction<_SendMessageShortcutIntent>(
            onInvoke: (_) {
              _handleSendMessageShortcut();
              return null;
            },
          ),
          _DismissChatInputShortcutIntent:
              CallbackAction<_DismissChatInputShortcutIntent>(
            onInvoke: (_) {
              _handleDismissShortcut();
              return null;
            },
          ),
          _OpenMessageSearchShortcutIntent:
              CallbackAction<_OpenMessageSearchShortcutIntent>(
            onInvoke: (_) {
              _showMessageSearch();
              return null;
            },
          ),
          _FocusMessageInputShortcutIntent:
              CallbackAction<_FocusMessageInputShortcutIntent>(
            onInvoke: (_) {
              if (!_messageFocusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_messageFocusNode);
              }
              return null;
            },
          ),
          _CopySelectedMessagesShortcutIntent:
              CallbackAction<_CopySelectedMessagesShortcutIntent>(
            onInvoke: (_) {
              _handleCopySelectedMessagesShortcut();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          skipTraversal: true,
          child: child,
        ),
      ),
    );
  }

  void _handleSendMessageShortcut() {
    if (!_messageFocusNode.hasFocus) return;
    if (_isSelectionMode || _isRecordingVoice) return;
    if (_messageController.text.trim().isEmpty) return;
    _sendMessage();
  }

  void _handleDismissShortcut() {
    _chatComposerBloc.add(
      ChatComposerDismissShortcutRequested(
        isSelectionMode: _isSelectionMode,
        isEditMode: _isEditMode,
        hasReply: _replyingToMessage != null,
      ),
    );
  }

  void _handleCopySelectedMessagesShortcut() {
    if (!_isSelectionMode) return;
    final state = _messageBloc.state;
    if (state is! MessagesLoaded) return;
    _copySelectedMessages(state.uiMessages);
  }

  void _forwardSelectedMessages() {
    final state = _messageBloc.state;
    if (state is! MessagesLoaded) return;

    final selectedMessages = _getSelectedMessages(state.uiMessages);
    if (selectedMessages.isEmpty) return;

    showForwardMessageSheet(
      context,
      messages: selectedMessages,
      sourceChatId: widget.chatId,
    ).then((_) {
      if (!mounted) return;
      _exitSelectionMode();
    });
  }

  void _scrollToMessage(
      String? targetMessageId, List<MessageUIState> uiMessages) {
    if (targetMessageId == null) return;

    final index = uiMessages.indexWhere((m) => m.id == targetMessageId);
    if (index == -1) {
      _pendingScrollToMessageId = targetMessageId;
      _pendingScrollAttempts = 0;
      _loadMore();
      return;
    }

    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 400),
      alignment: 0.4, // roughly center in viewport
    );

    safeSetState(() => _highlightedMessageId = targetMessageId);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) safeSetState(() => _highlightedMessageId = null);
    });
  }

  void _scrollToBottom() {
    if (!_itemScrollController.isAttached) return;
    _itemScrollController.scrollTo(
      index: 0,
      duration: const Duration(milliseconds: 300),
    );
    safeSetState(() {
      _showScrollToBottom = false;
      _newMessageCount = 0;
    });
  }

  bool _maybeAutoScrollToBottomForOwnMessage(MessagesLoaded state) {
    final latestMessage =
        state.messages.isNotEmpty ? state.messages.first : null;
    final hadSnapshot = _hasTrackedLatestMessage;
    final previousLatestMessageId = _latestMessageId;

    _hasTrackedLatestMessage = true;
    _latestMessageId = latestMessage?.id;

    if (!hadSnapshot || latestMessage == null) return false;
    if (latestMessage.id == previousLatestMessageId) return false;
    if (latestMessage.sender.id != _currentUserId) return false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_itemScrollController.isAttached) return;

      // Keep behavior aligned with Stream's MessageListView:
      // own new message -> snap to bottom index in reverse list.
      _itemScrollController.jumpTo(index: 0);
      safeSetState(() {
        _showScrollToBottom = false;
        _newMessageCount = 0;
      });
    });

    return true;
  }

  Future<void> _onVoiceRecordingLongPressStart(
    LongPressStartDetails details,
  ) async {
    if (_isRecordingVoice) return;

    final permissionResult = await _voiceRecorderService.ensurePermission();
    if (!mounted) return;

    if (permissionResult != VoiceRecorderPermissionResult.granted) {
      await _showMicrophonePermissionDialog(
        isPermanentlyDenied:
            permissionResult == VoiceRecorderPermissionResult.permanentlyDenied,
      );
      return;
    }

    final started = await _voiceRecorderService.startRecording();
    if (!mounted) return;

    if (!started) {
      AppSnackBar.show(
        context: context,
        message: context.l10n.errorOccurred,
        type: FeedbackType.error,
      );
      return;
    }

    _recordingTimer?.cancel();
    safeSetState(() {
      _isRecordingVoice = true;
      _isSlidingToCancel = false;
      _recordingStartedAt = DateTime.now();
      _recordingDuration = Duration.zero;
      _recordingAmplitude = 0.0;
      _recordingDragStartDx = details.globalPosition.dx;
    });

    _recordingTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) {
        final startedAt = _recordingStartedAt;
        if (startedAt == null || !mounted) return;
        safeSetState(() {
          _recordingDuration = DateTime.now().difference(startedAt);
        });
      },
    );
  }

  void _onVoiceRecordingLongPressMoveUpdate(
    LongPressMoveUpdateDetails details,
  ) {
    if (!_isRecordingVoice || _recordingDragStartDx == null) return;
    final dragDistance = _recordingDragStartDx! - details.globalPosition.dx;
    final shouldCancel = dragDistance > AppDimens.spaceXLarge;
    if (shouldCancel == _isSlidingToCancel) return;
    safeSetState(() {
      _isSlidingToCancel = shouldCancel;
    });
  }

  void _onVoiceRecordingTap() {
    if (_isRecordingVoice || !mounted) return;

    final now = DateTime.now();
    final lastHintAt = _lastVoiceRecordingHintAt;
    if (lastHintAt != null &&
        now.difference(lastHintAt) < const Duration(seconds: 2)) {
      return;
    }

    _lastVoiceRecordingHintAt = now;
    AppSnackBar.show(
      context: context,
      message: context.l10n.longPressToRecord,
      type: FeedbackType.info,
    );
  }

  Future<void> _onVoiceRecordingLongPressEnd(
    LongPressEndDetails details,
  ) async {
    if (!_isRecordingVoice) return;
    await _finishVoiceRecording(cancelled: _isSlidingToCancel);
  }

  Future<void> _finishVoiceRecording({
    required bool cancelled,
  }) async {
    if (!_isRecordingVoice) return;

    final secondsToSend = _resolveRecordingSeconds();
    String? filePath;

    if (cancelled) {
      await _voiceRecorderService.cancelRecording();
    } else {
      filePath = await _voiceRecorderService.stopRecording();
    }

    _resetRecordingUiState();

    if (cancelled || filePath == null || filePath.trim().isEmpty) {
      return;
    }

    _messageBloc.add(
      SendVoiceNote(
        filePath: filePath,
        senderId: _currentUserId,
        durationSeconds: secondsToSend,
        replyMessageId: _replyingToMessage?.id,
      ),
    );
    _cancelReply();
  }

  Future<void> _sendVoiceRecordingFromPanel() async {
    await _finishVoiceRecording(cancelled: false);
  }

  Future<void> _cancelVoiceRecordingFromPanel() async {
    await _finishVoiceRecording(cancelled: true);
  }

  void _handleVoiceRecordingLimitReached(String filePath) {
    if (!_isRecordingVoice || !mounted) return;

    final secondsToSend = _resolveRecordingSeconds(fallback: 300);
    _resetRecordingUiState();
    _messageBloc.add(
      SendVoiceNote(
        filePath: filePath,
        senderId: _currentUserId,
        durationSeconds: secondsToSend,
        replyMessageId: _replyingToMessage?.id,
      ),
    );
    _cancelReply();
    AppSnackBar.show(
      context: context,
      message: context.l10n.recordingLimitReached,
      type: FeedbackType.info,
    );
  }

  int _resolveRecordingSeconds({int fallback = 1}) {
    final seconds = _recordingDuration.inSeconds;
    if (seconds <= 0) return fallback;
    if (seconds > 300) return 300;
    return seconds;
  }

  void _resetRecordingUiState() {
    _recordingTimer?.cancel();
    safeSetState(() {
      _isRecordingVoice = false;
      _isSlidingToCancel = false;
      _recordingStartedAt = null;
      _recordingDuration = Duration.zero;
      _recordingAmplitude = 0.0;
      _recordingDragStartDx = null;
    });
  }

  Future<void> _showMicrophonePermissionDialog({
    required bool isPermanentlyDenied,
  }) async {
    await AppAlertDialog.show<void>(
      context: context,
      title: context.l10n.microphonePermissionTitle,
      content: isPermanentlyDenied
          ? context.l10n.microphonePermissionPermanentlyDeniedMessage
          : context.l10n.microphonePermissionMessage,
      actions: [
        AppButton.text(
          text: context.l10n.cancel,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        AppButton.primary(
          text: context.l10n.openSettings,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await openAppSettings();
          },
        ),
      ],
    );
  }

  void _showChatInfo() {
    if (_chat == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<ChatInfoBloc>()),
          BlocProvider<ConversationDetailBloc>.value(value: _convDetailBloc),
        ],
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => ChatInfoPanel(
            chat: _chat!,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    ).then((_) {
      // Refresh conversation detail after info panel closes
      // (members may have been added/removed)
      if (_chat != null) {
        _convDetailBloc.add(LoadConversationDetail(chatId: _chat!.id));
      }
    });
  }

  void _showAddMember() {
    if (_chat == null) return;

    final currentMemberIds = _chat?.members.map((m) => m.userId).toList() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMemberPanel(
        conversationId: widget.chatId,
        currentMemberIds: currentMemberIds,
        onSearchUsers: (query) => _searchUsers(query),
        onAddMembers: (userIds) => _addMembersToGroup(userIds),
      ),
    ).then((result) {
      // Refresh conversation detail after add member panel closes
      if (result == true && _chat != null) {
        _convDetailBloc.add(LoadConversationDetail(chatId: _chat!.id));
      }
    });
  }

  /// Search users for adding to group
  Future<List<SelectableUser>> _searchUsers(String query) async {
    try {
      final userRemoteDataSource = getIt<UserRemoteDataSource>();
      final users = await userRemoteDataSource.searchUsers(query);
      return users
          .map((user) => SelectableUser(
                id: user.serverId,
                name: user.displayName,
                avatarUrl: user.avatarUrl,
              ))
          .toList();
    } catch (e) {
      debugPrint('[AddMember] Error searching users: $e');
      return [];
    }
  }

  /// Add members to group via ConversationDetailBloc
  Future<bool> _addMembersToGroup(List<String> userIds) async {
    _convDetailBloc.add(AddMembersToGroup(
      chatId: widget.chatId,
      userIds: userIds,
    ));

    // Wait for BLoC to process and emit result
    final state = await _convDetailBloc.stream.firstWhere(
      (s) =>
          s is ConversationDetailMembersAdded ||
          s is ConversationDetailLoaded ||
          s is ConversationDetailError,
    );

    return state is! ConversationDetailError;
  }

  void _showMessageSearch() {
    if (_chat == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider(
        create: (_) => getIt<MessageSearchBloc>(),
        child: MessageSearchPanel(
          conversationId: widget.chatId,
          onResultSelected: (result) {
            _jumpToMessage(result.id, result.createdAt);
          },
        ),
      ),
    );
  }

  /// Jump to a specific message by ID from search result
  void _jumpToMessage(String messageId, DateTime createdAt) {
    _pendingScrollToMessageId = messageId;
    _pendingScrollCreatedAtMs = createdAt.millisecondsSinceEpoch;
    _pendingScrollAttempts = 0;

    // Try to scroll immediately if message is already loaded
    _attemptJumpToMessage();
  }

  /// Attempt to jump to pending message
  void _attemptJumpToMessage() {
    if (_pendingScrollToMessageId == null) return;

    final state = _messageBloc.state;
    if (state is! MessagesLoaded) {
      // Messages not loaded yet, _handleBlocStateChanges will retry
      return;
    }

    final messageId = _pendingScrollToMessageId!;
    final messages = state.uiMessages;

    // Find the message index
    int? messageIndex;
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].message?.id == messageId) {
        messageIndex = i;
        break;
      }
    }

    if (messageIndex != null) {
      // Message found — scroll to it and highlight
      _pendingScrollToMessageId = null;
      _pendingScrollCreatedAtMs = null;
      _pendingScrollAttempts = 0;

      _itemScrollController.scrollTo(
        index: messageIndex,
        duration: const Duration(milliseconds: 400),
        alignment: 0.4,
      );

      safeSetState(() => _highlightedMessageId = messageId);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) safeSetState(() => _highlightedMessageId = null);
      });
    } else {
      // Message not found — load messages from target timestamp
      final createdAtMs = _pendingScrollCreatedAtMs;
      if (createdAtMs != null) {
        _messageBloc.add(JumpToMessage(
          messageId: messageId,
          createdAtMs: createdAtMs,
        ));
      } else {
        // Fallback: no timestamp available
        _pendingScrollToMessageId = null;
        _pendingScrollCreatedAtMs = null;
        _pendingScrollAttempts = 0;
        if (mounted) {
          AppSnackBar.show(
            context: context,
            message: context.l10n.messageNotFound,
            type: FeedbackType.warning,
          );
        }
      }
    }
  }

  // ══════════════════════════════════════════
  // Media Handlers
  // ══════════════════════════════════════════

  void _showStickerPicker() {
    StickerPickerBottomSheet.show(
      context,
      onStickerSelected: _sendSticker,
    );
  }

  void _sendSticker(Sticker sticker) {
    _messageBloc.add(
      SendSticker(
        stickerCode: sticker.code,
        senderId: _currentUserId,
        replyMessageId: _replyingToMessage?.id,
      ),
    );
    _cancelReply();
  }

  void _showAttachmentPicker() {
    AttachmentPickerBottomSheet.show(
      context,
      onImageFromCamera: _handleImageFromCamera,
      onImageFromGallery: _handleImageFromGallery,
      onVideoFromGallery: _handleVideoFromGallery,
      onImagesFromGallery: _handleImagesFromGallery,
      onFileSelected: _handleFileSelected,
      onLocationShare: _handleLocationShare,
    );
  }

  void _handleImageFromCamera(File imageFile,
          {Uint8List? bytes, String? name, int? size}) =>
      _processAndSendImage(imageFile, bytes: bytes, name: name, size: size);

  void _handleImageFromGallery(File imageFile,
          {Uint8List? bytes, String? name, int? size}) =>
      _processAndSendImage(imageFile, bytes: bytes, name: name, size: size);

  void _handleVideoFromGallery(File videoFile,
          {Uint8List? bytes, String? name, int? size}) =>
      _handleFileSelected(videoFile, bytes: bytes, name: name, size: size);

  void _handleImagesFromGallery(List<GalleryImageSelection> images) {
    unawaited(_handleImagesFromGalleryAsync(images));
  }

  Future<void> _handleImagesFromGalleryAsync(
      List<GalleryImageSelection> images) async {
    if (images.isEmpty) return;

    if (images.length == 1) {
      final image = images.first;
      _processAndSendImage(
        image.file,
        bytes: image.bytes,
        name: image.name,
        size: image.size,
      );
      return;
    }

    final l10n = context.l10n;

    try {
      if (kIsWeb) {
        final fileBytes = <List<int>>[];
        final fileNames = <String>[];
        final fileSizes = <int>[];

        for (final image in images) {
          if (image.bytes == null) continue;
          fileBytes.add(image.bytes!);
          fileNames.add(image.name);
          fileSizes.add(image.size > 0 ? image.size : image.bytes!.length);
        }

        if (fileBytes.isEmpty) {
          if (!mounted) return;
          AppSnackBar.show(
            context: context,
            message: l10n.errorOccurred,
            type: FeedbackType.error,
          );
          return;
        }

        _messageBloc.add(
          SendMessageWithAttachments(
            content: '',
            senderId: _currentUserId,
            localFilePaths: const [],
            fileBytes: fileBytes,
            fileNames: fileNames,
            fileSizes: fileSizes,
          ),
        );
        return;
      }

      final localFilePaths = <String>[];
      final fileNames = <String>[];
      final fileSizes = <int>[];

      for (final image in images) {
        final compressedImage =
            await ImageCompressionHelper.compressImage(image.file);
        if (!mounted) return;

        final uploadFile = compressedImage ?? image.file;
        if (!uploadFile.existsSync()) continue;

        final filePath = uploadFile.path;
        if (filePath.isEmpty) continue;

        final fileSize = uploadFile.lengthSync();
        final normalizedName = image.name.isNotEmpty
            ? image.name
            : filePath.split(RegExp(r'[\\/]')).last;

        localFilePaths.add(filePath);
        fileNames.add(normalizedName);
        fileSizes.add(fileSize);
      }

      if (localFilePaths.isEmpty) {
        if (!mounted) return;
        AppSnackBar.show(
          context: context,
          message: l10n.imageCompressionFailed,
          type: FeedbackType.error,
        );
        return;
      }

      _messageBloc.add(
        SendMessageWithAttachments(
          content: '',
          senderId: _currentUserId,
          localFilePaths: localFilePaths,
          fileNames: fileNames,
          fileSizes: fileSizes,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: l10n.errorOccurred,
        type: FeedbackType.error,
      );
    }
  }

  void _handleFileSelected(File file,
      {Uint8List? bytes, String? name, int? size}) {
    // Cross-platform: on web, use name as path placeholder; on mobile, use actual path
    final filePath = kIsWeb && name != null ? name : file.path;
    _messageBloc.add(
      SendMessageWithAttachments(
        content: '',
        senderId: _currentUserId,
        localFilePaths: [filePath],
        fileBytes: bytes != null ? [bytes] : null,
        fileNames: name != null ? [name] : null,
        fileSizes: size != null ? [size] : null,
      ),
    );
    // No toast - progress is shown directly in file tile (like image upload)
  }

  Future<void> _handleLocationShare() async {
    final locationService = GetIt.I<ILocationService>();
    final navigator = Navigator.of(context);

    try {
      final hasPermission = await locationService.hasLocationPermission();
      if (!mounted) return;

      if (!hasPermission) {
        final granted = await locationService.requestLocationPermission();
        if (!mounted) return;

        if (!granted) {
          AppSnackBar.show(
            context: context,
            message: 'Location permission denied',
            type: FeedbackType.error,
          );
          return;
        }
      }

      AppSnackBar.show(
        context: context,
        message: 'Getting your location...',
        type: FeedbackType.info,
      );

      final result = await locationService.getCurrentLocation();
      if (!mounted) return;

      result.fold(
        (failure) {
          AppSnackBar.show(
            context: context,
            message: failure.message,
            type: FeedbackType.error,
          );
        },
        (locationData) {
          _messageBloc.add(
            SendLocationMessage(
              senderId: _currentUserId,
              latitude: locationData.latitude,
              longitude: locationData.longitude,
              locationName: locationData.name,
            ),
          );

          AppSnackBar.show(
            context: context,
            message: 'Location sent successfully',
            type: FeedbackType.success,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Failed to share location: $e',
        type: FeedbackType.error,
      );
    } finally {
      // keep reference used to avoid analyzer complaining about unused capture in some configs
      // ignore: unused_local_variable
      final _ = navigator;
    }
  }

  Future<void> _processAndSendImage(File imageFile,
      {Uint8List? bytes, String? name, int? size}) async {
    final l10n = context.l10n;
    var currentFile = imageFile;
    Uint8List? currentBytes = bytes;
    String? currentName = name;

    try {
      while (true) {
        // On web, we already have bytes from picker
        // On mobile, compress image first
        Uint8List? imageBytes = currentBytes;

        if (!kIsWeb) {
          // Mobile: compress image
          final compressedImage =
              await ImageCompressionHelper.compressImage(currentFile);
          if (!mounted) return;

          if (compressedImage == null) {
            AppSnackBar.show(
                context: context,
                message: l10n.imageCompressionFailed,
                type: FeedbackType.error);
            return;
          }

          imageBytes = await compressedImage.readAsBytes();
        }

        // Open preview screen with image for editing before sending
        if (!mounted) return;
        final result = await Navigator.of(context).push<ImagePreviewResult>(
          MaterialPageRoute(
            builder: (ctx) => BlocProvider.value(
              value: context.read<ChatBloc>(),
              child: ImagePreviewScreen(
                imageFile: kIsWeb ? null : currentFile,
                imageBytes: imageBytes,
                fileName: currentName,
                chatId: widget.chatId,
              ),
            ),
          ),
        );

        // User wants to retake - re-open camera
        if (result != null && result.isRetake) {
          if (!mounted) return;
          final picker = ImagePicker();
          final retaken = await picker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
          if (retaken == null || !mounted) return;

          currentFile = File(retaken.path);
          currentBytes = kIsWeb ? await retaken.readAsBytes() : null;
          currentName = retaken.name;
          continue;
        }

        // User cancelled - don't send
        if (result == null || result.isCancelled) return;

        // User sent - send with progress display via SendMessageWithAttachments
        _messageBloc.add(
          SendMessageWithAttachments(
            content: '',
            senderId: _currentUserId,
            localFilePaths: const [],
            fileBytes: [result.editedBytes!],
            fileNames: [
              result.fileName ??
                  'image_${DateTime.now().millisecondsSinceEpoch}.jpg'
            ],
          ),
        );
        return;
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: l10n.errorOccurred,
          type: FeedbackType.error,
        );
      }
    }
  }

  // ══════════════════════════════════════════
  // UI Building
  // ══════════════════════════════════════════

  String _buildReplyInputPreviewText(
    ChatMessage message,
    BuildContext context,
  ) {
    final l10n = context.l10n;
    switch (message.contentType) {
      case ContentType.image:
        return l10n.replyPreviewImage;
      case ContentType.video:
        return l10n.replyPreviewVideo;
      case ContentType.audio:
        return l10n.replyPreviewAudio;
      case ContentType.file:
        return l10n.replyPreviewFile(message.fileName ?? '');
      case ContentType.location:
        return l10n.replyPreviewLocation;
      case ContentType.sticker:
        return l10n.replyPreviewSticker;
      case ContentType.link:
        if (message.content.trim().isEmpty) {
          return l10n.replyPreviewLink;
        }
        return message.content.formatChatMessage(
          mentionNameById: _buildMentionNameById(message),
        );
      case ContentType.event:
        return l10n.replyPreviewSystemEvent;
      case ContentType.text:
        final normalized = message.content.formatChatMessage(
          mentionNameById: _buildMentionNameById(message),
        );
        return normalized.trim().isEmpty ? l10n.noMessages : normalized;
    }
  }

  Map<String, String> _buildMentionNameById(ChatMessage message) {
    final mentionNameById = <String, String>{
      for (final mention in message.mentionTo)
        if (mention.id.trim().isNotEmpty && mention.name.trim().isNotEmpty)
          mention.id.trim(): mention.name.trim(),
    };

    final members = _chat?.members ?? const <ConversationMember>[];
    for (final member in members) {
      final userId = member.userId.trim();
      final fullName = member.fullName?.trim();
      if (userId.isNotEmpty && fullName != null && fullName.isNotEmpty) {
        mentionNameById.putIfAbsent(userId, () => fullName);
      }
    }

    if (!mentionNameById.containsKey('all') &&
        message.content.contains('[@all]')) {
      mentionNameById['all'] = 'All';
    }

    return mentionNameById;
  }

  List<SlashCommandOption> _buildSlashCommandOptions(BuildContext context) {
    return <SlashCommandOption>[
      SlashCommandOption(
        name: ChatSlashCommandEngine.shrugCommand,
        usage: '/${ChatSlashCommandEngine.shrugCommand}',
        description: context.l10n.slashCommandShrugDescription,
      ),
      SlashCommandOption(
        name: ChatSlashCommandEngine.tableflipCommand,
        usage: '/${ChatSlashCommandEngine.tableflipCommand}',
        description: context.l10n.slashCommandTableflipDescription,
      ),
      SlashCommandOption(
        name: ChatSlashCommandEngine.meCommand,
        usage: context.l10n.slashCommandMeUsage,
        description: context.l10n.slashCommandMeDescription,
      ),
      SlashCommandOption(
        name: ChatSlashCommandEngine.muteCommand,
        usage: '/${ChatSlashCommandEngine.muteCommand}',
        description: context.l10n.slashCommandMuteDescription,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final chatTitle = (_chat?.name?.trim().isNotEmpty ?? false)
        ? _chat!.name!.trim()
        : context.l10n.chats;

    return MultiBlocProvider(
      providers: [
        BlocProvider<MessageBloc>.value(value: _messageBloc),
        BlocProvider<ConversationDetailBloc>.value(value: _convDetailBloc),
        BlocProvider<ChatComposerBloc>.value(value: _chatComposerBloc),
        BlocProvider<ChatDraftBloc>.value(value: _chatDraftBloc),
        BlocProvider<ChatBloc>(create: (_) => getIt<ChatBloc>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<ConversationDetailBloc, ConversationDetailState>(
            listener: _handleConversationDetailStateChanges,
          ),
          BlocListener<ChatDraftBloc, ChatDraftState>(
            listener: _handleDraftStateChanges,
          ),
          BlocListener<ChatComposerBloc, ChatComposerState>(
            listener: _handleComposerStateChanges,
          ),
        ],
        child: _buildShortcutHost(
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              appBar: _isSelectionMode
                  ? _buildSelectionAppBar()
                  : _buildNormalAppBar(chatTitle),
              body: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        BlocConsumer<MessageBloc, MessageState>(
                          listener: _handleBlocStateChanges,
                          builder: _buildMessagesList,
                        ),
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
                  TypingIndicatorWithFade(
                    isTyping: _isOtherTyping,
                    displayName: _typingUserName,
                  ),
                  if (_replyingToMessage != null)
                    ReplyInputBar(
                      replyMessage: ReplyMessagePreview(
                        id: _replyingToMessage!.id,
                        senderName: _replyingToMessage!.sender.name,
                        contentType: _replyingToMessage!.contentType,
                        previewText: _buildReplyInputPreviewText(
                          _replyingToMessage!,
                          context,
                        ),
                      ),
                      onCancel: _cancelReply,
                    ),
                  if (_isEditMode) _buildEditModeBar(),
                  _buildMessageInputArea(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleConversationDetailStateChanges(
    BuildContext context,
    ConversationDetailState state,
  ) {
    if (state is ConversationDetailLoaded) {
      final chat = state.chat;
      if (chat != _chat) {
        _chat = chat;
        _messageBloc.setTransformContext(
          currentUserId: _currentUserId,
          isGroupChat: _chat?.type == ChatType.group,
          conversationName: chat.name,
        );
        _messageBloc.add(UpdateConversationMembers(chat.members));
        safeSetState(() {});
      }
    }
  }

  void _handleBlocStateChanges(BuildContext context, MessageState state) {
    if (state is MessagesLoaded) {
      final didAutoScrollForOwnMessage =
          _maybeAutoScrollToBottomForOwnMessage(state);

      // Mark chat as read when first loaded with unread messages (Req 5.1)
      if (!_hasMarkedAsReadOnOpen && state.messages.isNotEmpty) {
        _hasMarkedAsReadOnOpen = true;
        _messageBloc.add(MarkChatAsRead(widget.chatId));
      }

      // Mark as read when new real-time messages arrive and user is at bottom
      if (_hasMarkedAsReadOnOpen &&
          !_showScrollToBottom &&
          state.messages.isNotEmpty) {
        _messageBloc.add(MarkChatAsRead(widget.chatId));
      }

      _chatDraftBloc.add(
        ChatDraftMessageDeliveryChecked(
          conversationId: widget.chatId,
          currentUserId: _currentUserId,
          currentInputText: _messageController.text,
          messages: state.messages,
        ),
      );

      // ── Load-more completion detection ──
      // Only reset _isLoadingMore when load-more ACTUALLY completes, not on
      // every MessagesLoaded emission (real-time messages, background fetch,
      // reactions, etc. all emit MessagesLoaded too).
      //
      // Detection: load-more adds OLDER messages to the end of the list, so
      // the oldest message ID changes. Also covers hasReachedMax and errors.
      if (_isLoadingMore) {
        final oldestId =
            state.messages.isNotEmpty ? state.messages.last.id : null;
        final loadMoreCompleted =
            oldestId != _oldestMessageIdBeforeLoadMore ||
            state.hasReachedMax ||
            state.paginationError != null;

        if (loadMoreCompleted) {
          _loadMoreSafetyTimer?.cancel();
          safeSetState(() => _isLoadingMore = false);

          // Workaround: ScrollablePositionedList with reverse:true doesn't
          // recalculate its internal scroll extent after itemCount increases.
          // A jumpTo on the current visible index forces a full re-layout so
          // the user can keep scrolling to the newly loaded older messages.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              final positions =
                  _itemPositionsListener.itemPositions.value.toList();
              if (positions.isEmpty) return;

              positions.sort((a, b) => b.index.compareTo(a.index));
              final anchor = positions.first;

              _itemScrollController.jumpTo(
                index: anchor.index,
                alignment: anchor.itemLeadingEdge,
              );
            } catch (_) {}
          });
        }
      }

      final pendingId = _pendingScrollToMessageId;
      if (pendingId != null && pendingId.isNotEmpty) {
        final index = state.uiMessages.indexWhere((m) => m.id == pendingId);
        if (index != -1) {
          _pendingScrollToMessageId = null;
          _pendingScrollCreatedAtMs = null;
          _pendingScrollAttempts = 0;

          // Use WidgetsBinding to ensure the list has rebuilt with new data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _itemScrollController.scrollTo(
              index: index,
              duration: const Duration(milliseconds: 400),
              alignment: 0.4,
            );
          });

          safeSetState(() => _highlightedMessageId = pendingId);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) safeSetState(() => _highlightedMessageId = null);
          });
        } else if (_pendingScrollAttempts < _maxPendingScrollAttempts) {
          _pendingScrollAttempts++;
          // Use JumpToMessage with timestamp cursor if available
          final createdAtMs = _pendingScrollCreatedAtMs;
          if (createdAtMs != null) {
            _messageBloc.add(JumpToMessage(
              messageId: pendingId,
              createdAtMs: createdAtMs,
            ));
          } else if (!state.hasReachedMax) {
            safeSetState(() => _isLoadingMore = true);
            _messageBloc.add(const LoadMoreMessages(limit: _pageSize));
          } else {
            _pendingScrollToMessageId = null;
            _pendingScrollCreatedAtMs = null;
            _pendingScrollAttempts = 0;
            AppSnackBar.show(
              context: context,
              message: context.l10n.messageNotFound,
              type: FeedbackType.warning,
            );
          }
        } else {
          _pendingScrollToMessageId = null;
          _pendingScrollCreatedAtMs = null;
          _pendingScrollAttempts = 0;
          AppSnackBar.show(
            context: context,
            message: context.l10n.messageNotFound,
            type: FeedbackType.warning,
          );
        }
      }
      if (_showScrollToBottom && !didAutoScrollForOwnMessage) {
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
          onPressed: () => _messageBloc.add(LoadMessages(
            chatId: widget.chatId,
            limit: _pageSize,
            forceRefresh: true,
          )),
        ),
      );
    }
  }

  Widget _buildMessagesList(BuildContext context, MessageState state) {
    // MessageInitial: bloc just created, local cache lookup in progress.
    // Show nothing (transparent) to avoid a loading-spinner flash when
    // local data will arrive within 1-2 frames.
    if (state is MessageInitial) {
      return const SizedBox.shrink();
    }
    if (state is MessagesLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppProgressIndicator.circular(label: context.l10n.loading),
            const SizedBox(height: AppDimens.spaceMedium),
            AppText(context.l10n.loadingMessages),
          ],
        ),
      );
    } else if (state is MessagesLoaded) {
      if (state.uiMessages.isEmpty) return _buildEmptyState(context);
      return ChatMessageTimeline(
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        scrollOffsetController: _scrollOffsetController,
        scrollOffsetListener: _scrollOffsetListener,
        uiMessages: state.uiMessages,
        hasMore: !state.hasReachedMax,
        isLoadingMore: _isLoadingMore,
        itemBuilder: (context, uiState, allUiMessages) =>
            _buildListItem(context, uiState, allUiMessages),
      );
    } else if (state is MessagesError) {
      return _buildErrorState(
          context,
          state.error,
          () => _messageBloc.add(LoadMessages(
                chatId: widget.chatId,
                limit: _pageSize,
                forceRefresh: true,
              )));
    }
    return Center(child: AppText(context.l10n.errorOccurred));
  }

  Widget _buildEditModeBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
          left: BorderSide(
              color: Theme.of(context).colorScheme.tertiary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.edit,
              size: 16, color: Theme.of(context).colorScheme.tertiary),
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
    );
  }

  Widget _buildMessageInputArea() {
    if (_isRecordingVoice) {
      return _buildVoiceRecordingInputArea();
    }

    final canSendText = _messageController.text.trim().isNotEmpty;

    return AppCard.outlined(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppDimens.paddingSmall),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.add_circle_outline,
            onPressed: _showAttachmentPicker,
            tooltip: context.l10n.attachments,
          ),
          Expanded(
            child: MentionTextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              members: _chat?.members ?? const <ConversationMember>[],
              currentUserId: _currentUserId,
              hint: context.l10n.typeMessage,
              minLines: 1,
              maxLines: 5,
              slashCommands: _buildSlashCommandOptions(context),
            ),
          ),
          AppIconButton(
            icon: Icons.sticky_note_2_outlined,
            onPressed: _showStickerPicker,
            tooltip: context.l10n.stickers,
          ),
          if (canSendText)
            AppIconButton(
              icon: _isEditMode ? Icons.check : Icons.send,
              onPressed: _sendMessage,
              tooltip: _isEditMode ? context.l10n.save : context.l10n.send,
            )
          else if (_isEditMode)
            AppIconButton(
              icon: Icons.check,
              onPressed: null,
              tooltip: context.l10n.save,
            )
          else
            GestureDetector(
              onTap: _onVoiceRecordingTap,
              onLongPressStart: _onVoiceRecordingLongPressStart,
              onLongPressMoveUpdate: _onVoiceRecordingLongPressMoveUpdate,
              onLongPressEnd: _onVoiceRecordingLongPressEnd,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: AppDimens.iconButtonSize,
                height: AppDimens.iconButtonSize,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppColors.textButton,
                  size: AppDimens.iconMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceRecordingInputArea() {
    final isCancelling = _isSlidingToCancel;
    final statusColor = isCancelling ? AppColors.error : AppColors.primary;

    return AppCard.outlined(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppDimens.paddingSmall),
      child: Row(
        children: [
          Icon(
            isCancelling ? Icons.delete_outline_rounded : Icons.mic_rounded,
            color: statusColor,
            size: AppDimens.iconMedium,
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  '${context.l10n.recording} ${_formatVoiceRecordingDuration()}',
                  style: AppTextStyles.bodySmall.copyWith(color: statusColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimens.spaceXSmall),
                _buildRecordingAmplitudeBars(statusColor),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 168),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIconButton(
                      icon: Icons.close_rounded,
                      onPressed: _cancelVoiceRecordingFromPanel,
                      size: ButtonSize.small,
                      tooltip: context.l10n.cancelRecording,
                    ),
                    AppIconButton(
                      icon: Icons.send_rounded,
                      onPressed: _sendVoiceRecordingFromPanel,
                      size: ButtonSize.small,
                      tooltip: context.l10n.send,
                    ),
                  ],
                ),
                if (!isCancelling) ...[
                  const SizedBox(height: AppDimens.spaceXSmall),
                  AppText(
                    '${context.l10n.releaseToSend}\n${context.l10n.slideToCancel}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  AppText(
                    context.l10n.cancelRecording,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingAmplitudeBars(Color color) {
    final normalizedAmplitude = _recordingAmplitude.clamp(0.0, 1.0);

    return SizedBox(
      height: AppDimens.spaceLarge,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List<Widget>.generate(16, (index) {
          final baseCurve = (sin((index / 16) * pi) + 1) / 2;
          final effectiveLevel =
              (0.2 + (normalizedAmplitude * baseCurve)).clamp(0.15, 1.0);
          final barHeight =
              AppDimens.spaceXSmall + (AppDimens.spaceMedium * effectiveLevel);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 3,
              height: barHeight,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatVoiceRecordingDuration() {
    final totalSeconds =
        _recordingDuration.inSeconds > 300 ? 300 : _recordingDuration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  PreferredSizeWidget _buildNormalAppBar(String chatTitle) {
    final subtitleText = _isOtherTyping && _typingUserName != null
        ? context.l10n.isTyping(_typingUserName!)
        : context.l10n.online;

    if (_chat != null) {
      return ChatHeader(
        chat: _chat!,
        onBackPressed: () => Navigator.of(context).pop(),
        onInfoPressed: _showChatInfo,
        onAddMemberPressed:
            _chat!.type == ChatType.group ? _showAddMember : null,
        onSearchPressed: _showMessageSearch,
      );
    }

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(chatTitle,
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          AppText(subtitleText,
              style: AppTextStyles.labelSmall.copyWith(
                  color: _isOtherTyping
                      ? AppColors.primary
                      : AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    final state = _messageBloc.state;
    final uiMessages =
        state is MessagesLoaded ? state.uiMessages : const <MessageUIState>[];
    final selectedUiMessages = _getSelectedUiMessages(uiMessages);
    final canDeleteSelected =
        selectedUiMessages.isNotEmpty && _canDeleteSelectedMessages(uiMessages);

    return AppBar(
      leading: IconButton(
          icon: const Icon(Icons.close), onPressed: _exitSelectionMode),
      title: AppText(context.l10n.selectedCount(_selectedMessageIds.length),
          style: AppTextStyles.titleMedium),
      actions: [
        IconButton(
            icon: const Icon(Icons.copy),
            tooltip: context.l10n.copyMessage,
            onPressed: selectedUiMessages.isEmpty
                ? null
                : () => _copySelectedMessages(uiMessages)),
        IconButton(
            icon: const Icon(Icons.forward),
            tooltip: context.l10n.forwardMessage,
            onPressed:
                selectedUiMessages.isEmpty ? null : _forwardSelectedMessages),
        if (canDeleteSelected)
          IconButton(
              icon: const Icon(Icons.delete),
              tooltip: context.l10n.deleteMessage,
              onPressed: _deleteSelectedMessages),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, MessageUIState uiState,
      List<MessageUIState> allMessages) {
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
                  if (uiState.message != null) _startReply(uiState.message!);
                },
                onReplyPreviewTap: () =>
                    _scrollToMessage(uiState.replyMessage?.id, allMessages),
                isGroupChat: _chat?.type == ChatType.group,
                onLongPress: () {
                  if (!_isSelectionMode && uiState.message != null)
                    _showMessageOptions(
                        context, uiState.message!, uiState.isFromCurrentUser);
                },
                onTap: () {
                  if (_isSelectionMode) _toggleSelection(uiState.id);
                },
                onEditedImageSend: (bytes, fileName) {
                  debugPrint(
                      '[ChatDetailsPage] onEditedImageSend called, bytes=${bytes.length}, fileName=$fileName');
                  _messageBloc.add(
                    SendMessageWithAttachments(
                      content: '',
                      senderId: _currentUserId,
                      localFilePaths: const [],
                      fileBytes: [bytes],
                      fileNames: [fileName],
                    ),
                  );
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
              vertical: AppDimens.paddingXSmall),
          decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
          child: AppText(text,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondary)),
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
              child: Divider(color: AppColors.error.withValues(alpha: 0.5))),
          Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingSmall),
              child: AppText(context.l10n.unreadSeparatorLabel,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.error))),
          Expanded(
              child: Divider(color: AppColors.error.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildSystemEvent(MessageUIState uiState) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppDimens.spaceSmall, horizontal: AppDimens.paddingMedium),
      child: Center(
          child: AppText(uiState.systemEvent?.formattedText ?? uiState.content,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: AppDimens.iconSizeXXLarge, color: AppColors.textSecondary),
          const SizedBox(height: AppDimens.spaceMedium),
          AppText(context.l10n.noMessagesInChat,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, String message, VoidCallback? retryAction) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: AppDimens.iconSizeXXLarge, color: AppColors.error),
            const SizedBox(height: AppDimens.spaceMedium),
            AppText(message,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            if (retryAction != null) ...[
              const SizedBox(height: AppDimens.spaceLarge),
              AppButton.primary(
                  text: context.l10n.retryOperation,
                  icon: Icons.refresh,
                  onPressed: retryAction),
            ],
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(
      BuildContext context, ChatMessage message, bool isCurrentUser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimens.paddingSmall),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final emoji
                              in (_messageBloc.state is MessagesLoaded)
                                  ? (_messageBloc.state as MessagesLoaded)
                                      .frequentReactions
                                  : const <String>[
                                      '👍',
                                      '❤️',
                                      '😂',
                                      '😮',
                                      '😢',
                                      '😡'
                                    ])
                            _buildReactionItem(ctx, emoji, () {
                              Navigator.pop(ctx);
                              _messageBloc.add(ToggleReaction(
                                  messageId: message.id, emojiCode: emoji));
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildAddReactionItem(ctx, () {
                      Navigator.pop(ctx);
                      EmojiPickerBottomSheet.show(this.context,
                          onEmojiSelected: (emoji) => _messageBloc.add(
                              ToggleReaction(
                                  messageId: message.id, emojiCode: emoji)));
                    }),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (message.contentType == ContentType.text)
                _buildActionTile(Icons.copy, ctx.l10n.copyMessage, () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: message.content));
                  AppSnackBar.show(
                      context: this.context,
                      message: this.context.l10n.messageCopied,
                      type: FeedbackType.success);
                }),
              _buildActionTile(Icons.reply, ctx.l10n.replyMessage, () {
                Navigator.pop(ctx);
                _startReply(message);
              }),
              if (isCurrentUser && message.contentType == ContentType.text) ...[
                _buildActionTile(Icons.edit, ctx.l10n.editMessage, () {
                  Navigator.pop(ctx);
                  _startEditMode(message);
                }),
                _buildActionTile(Icons.delete, ctx.l10n.deleteMessage, () {
                  Navigator.pop(ctx);
                  _confirmDeleteMessage(message);
                }),
              ],
              _buildActionTile(Icons.forward, ctx.l10n.forwardMessage, () {
                Navigator.pop(ctx);
                showForwardMessageSheet(
                  this.context,
                  messages: [message],
                  sourceChatId: widget.chatId,
                );
              }),
              _buildActionTile(Icons.checklist, ctx.l10n.selectAll, () {
                Navigator.pop(ctx);
                _enterSelectionMode(message.id);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionItem(
      BuildContext context, String emoji, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildAddReactionItem(BuildContext context, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(999),
        ),
        child:
            Icon(Icons.add, size: 20, color: Theme.of(context).iconTheme.color),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: AppText(title),
      onTap: onTap,
    );
  }

  void _confirmDeleteMessage(ChatMessage message) {
    AppAlertDialog.show<bool>(
      context: context,
      title: context.l10n.deleteMessage,
      content: context.l10n.confirmDelete,
      actions: [
        AppButton.text(
          text: context.l10n.cancel,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
        AppButton.primary(
          text: context.l10n.delete,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop(true);
          },
        ),
      ],
    ).then((confirmed) {
      if (confirmed != true) return;
      _messageBloc.add(DeleteMessage(message.id));
    });
  }
}
