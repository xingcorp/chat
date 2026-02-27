import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/location_service.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/image_compression_helper.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/data/datasources/user/user_remote_datasource.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/message_search/message_search_bloc.dart';
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
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/app_card.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/dialogs/app_alert_dialog.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/inputs/app_text_field.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/chat_info_panel.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

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
  final MentionTextEditingController _messageController = MentionTextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final ScrollOffsetController _scrollOffsetController = ScrollOffsetController();
  final ScrollOffsetListener _scrollOffsetListener = ScrollOffsetListener.create();
  late final MessageBloc _messageBloc;
  late final ConversationDetailBloc _convDetailBloc;

  Chat? _chat;
  String _currentUserId = '';
  bool _hasInitializedContext = false;

  static const int _pageSize = 50;
  bool _isLoadingMore = false;
  DateTime? _lastLoadMoreAt;
  String? _lastLoadMoreCursor;
  String? _pendingScrollToMessageId;
  int _pendingScrollAttempts = 0;
  static const int _maxPendingScrollAttempts = 20;

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
  // Highlight state (scroll-to-reply)
  // ══════════════════════════════════════════
  String? _highlightedMessageId;

  // ══════════════════════════════════════════
  // Mark-as-read state
  // ══════════════════════════════════════════
  bool _hasMarkedAsReadOnOpen = false;

  @override
  void initState() {
    super.initState();
    // MessageBloc is a factory in DI, so this instance is unique to this page instance.
    // When chatId changes in desktop view, ValueKey forces a new State instance, 
    // ensuring clean state and correct bloc scope.
    _messageBloc = getIt<MessageBloc>();
    _convDetailBloc = getIt<ConversationDetailBloc>();
    _messageBloc.add(const FetchFrequentReactions());

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

    // Single listener for efficiency
    _messageController.addListener(_handleControllerChanges);
  }

  void _handleControllerChanges() {
    if (!mounted) return;
    safeSetState(() {});
    _handleTypingIndicator();
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



  /// Detect load-more and scroll-to-bottom FAB via visible item positions.
  void _onPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // --- Load more: check if max visible index is near the end ---
    final state = _messageBloc.state;
    if (state is MessagesLoaded) {
      final maxVisibleIndex = positions
          .map((p) => p.index)
          .reduce((a, b) => a > b ? a : b);
      final totalItems = state.uiMessages.length;

      if (maxVisibleIndex >= totalItems - 3 && !_isLoadingMore) {
        _loadMore();
      }
    }

    // --- Scroll-to-bottom FAB: show when newest message (index 0) is not visible ---
    final minVisibleIndex = positions
        .where((p) => p.itemTrailingEdge > 0 && p.itemLeadingEdge < 1)
        .map((p) => p.index)
        .fold<int?>(null, (prev, idx) => prev == null ? idx : (idx < prev ? idx : prev));
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
    if (_lastLoadMoreAt != null && now.difference(_lastLoadMoreAt!) < const Duration(milliseconds: 700)) {
      return;
    }

    final state = _messageBloc.state;
    if (state is! MessagesLoaded) return;
    if (state.hasReachedMax) return;

    final cursor = state.messages.isNotEmpty
        ? state.messages.last.createdAt.millisecondsSinceEpoch.toString()
        : null;
    if (cursor != null && cursor == _lastLoadMoreCursor) return;

    _lastLoadMoreAt = now;
    _lastLoadMoreCursor = cursor;

    safeSetState(() => _isLoadingMore = true);
    _messageBloc.add(const LoadMoreMessages(limit: _pageSize));
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleControllerChanges);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    _messageBloc.close();
    _convDetailBloc.close();
    _typingSubscription?.cancel();
    _typingDebounceTimer?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════
  // Actions
  // ══════════════════════════════════════════

  void _sendMessage() {
    final raw = _messageController.text.trim();
    final text = _messageController.toBackendMentionFormat(raw).trim();
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

  void _scrollToMessage(String? targetMessageId, List<MessageUIState> uiMessages) {
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
    _itemScrollController.scrollTo(
      index: 0,
      duration: const Duration(milliseconds: 300),
    );
    safeSetState(() {
      _showScrollToBottom = false;
      _newMessageCount = 0;
    });
  }

  void _showChatInfo() {
    if (_chat == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider(
        create: (_) => getIt<ChatInfoBloc>(),
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
    );
  }

  /// Search users for adding to group
  Future<List<SelectableUser>> _searchUsers(String query) async {
    try {
      final userRemoteDataSource = getIt<UserRemoteDataSource>();
      final users = await userRemoteDataSource.searchUsers(query);
      return users.map((user) => SelectableUser(
        id: user.serverId,
        name: user.displayName,
        avatarUrl: user.avatarUrl,
      )).toList();
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
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) => MessageSearchPanel(
            conversationId: widget.chatId,
            onResultSelected: (result) {
              _jumpToMessage(result.id);
            },
          ),
        ),
      ),
    );
  }

  /// Jump to a specific message by ID from search result
  void _jumpToMessage(String messageId) {
    _pendingScrollToMessageId = messageId;
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
      // Message not found — trigger load-more.
      // _handleBlocStateChanges will handle subsequent retries.
      if (!state.hasReachedMax) {
        _loadMore();
      } else {
        // All messages loaded but target not found
        _pendingScrollToMessageId = null;
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

  void _showAttachmentPicker() {
    AttachmentPickerBottomSheet.show(
      context,
      onImageFromCamera: _handleImageFromCamera,
      onImageFromGallery: _handleImageFromGallery,
      onFileSelected: _handleFileSelected,
      onLocationShare: _handleLocationShare,
    );
  }

  void _handleImageFromCamera(File imageFile, {Uint8List? bytes, String? name, int? size}) =>
      _processAndSendImage(imageFile, bytes: bytes, name: name, size: size);

  void _handleImageFromGallery(File imageFile, {Uint8List? bytes, String? name, int? size}) =>
      _processAndSendImage(imageFile, bytes: bytes, name: name, size: size);

  void _handleFileSelected(File file, {Uint8List? bytes, String? name, int? size}) {
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

  Future<void> _processAndSendImage(File imageFile, {Uint8List? bytes, String? name, int? size}) async {
    final l10n = context.l10n;
    try {
      // On web, we already have bytes from picker - no compression needed
      // On mobile, compress image silently (no toast - progress shows in message bubble)
      if (kIsWeb && bytes != null) {
        // Web: use bytes directly (no compression available)
        _messageBloc.add(
          SendMessageWithAttachments(
            content: '',
            senderId: _currentUserId,
            localFilePaths: [imageFile.path],
            fileBytes: [bytes],
            fileNames: name != null ? [name] : null,
            fileSizes: size != null ? [size] : null,
          ),
        );
        return;
      }

      // Mobile: compress image
      final compressedImage = await ImageCompressionHelper.compressImage(imageFile);
      if (!mounted) return;

      if (compressedImage == null) {
        AppSnackBar.show(context: context, message: l10n.imageCompressionFailed, type: FeedbackType.error);
        return;
      }

      // Send message - progress will be shown in the message bubble itself
      _messageBloc.add(
        SendMessageWithAttachments(
          content: '',
          senderId: _currentUserId,
          localFilePaths: [compressedImage.path],
        ),
      );
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

  Future<void> _onRefresh() async {
    _messageBloc.add(const RefreshMessages());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ══════════════════════════════════════════
  // UI Building
  // ══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final chatTitle = (_chat?.name?.trim().isNotEmpty ?? false)
        ? _chat!.name!.trim()
        : context.l10n.chats;

    return MultiBlocProvider(
      providers: [
        BlocProvider<MessageBloc>.value(value: _messageBloc),
        BlocProvider<ConversationDetailBloc>.value(value: _convDetailBloc),
      ],
      child: BlocListener<ConversationDetailBloc, ConversationDetailState>(
        listener: _handleConversationDetailStateChanges,
        child: GestureDetector(
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
                  previewText: _replyingToMessage!.content,
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
      // Mark chat as read when first loaded with unread messages (Req 5.1)
      if (!_hasMarkedAsReadOnOpen && state.messages.isNotEmpty) {
        _hasMarkedAsReadOnOpen = true;
        _messageBloc.add(MarkChatAsRead(widget.chatId));
      }

      // Mark as read when new real-time messages arrive and user is at bottom
      if (_hasMarkedAsReadOnOpen && !_showScrollToBottom && state.messages.isNotEmpty) {
        _messageBloc.add(MarkChatAsRead(widget.chatId));
      }

      final wasLoadingMore = _isLoadingMore;
      safeSetState(() => _isLoadingMore = false);

      // Workaround: ScrollablePositionedList with reverse:true doesn't
      // recalculate its internal scroll extent after itemCount increases.
      // A jumpTo on the current visible index forces a full re-layout so
      // the user can keep scrolling to the newly loaded older messages.
      if (wasLoadingMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          try {
            final positions =
                _itemPositionsListener.itemPositions.value.toList();
            if (positions.isEmpty) return;

            // Find the topmost visible item (highest index in reverse list
            // = oldest visible message).
            positions.sort((a, b) => b.index.compareTo(a.index));
            final anchor = positions.first;

            _itemScrollController.jumpTo(
              index: anchor.index,
              alignment: anchor.itemLeadingEdge,
            );
          } catch (_) {
          }
        });
      }

      final pendingId = _pendingScrollToMessageId;
      if (pendingId != null && pendingId.isNotEmpty) {
        final index = state.uiMessages.indexWhere((m) => m.id == pendingId);
        if (index != -1) {
          _pendingScrollToMessageId = null;
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
        } else if (!state.hasReachedMax && _pendingScrollAttempts < _maxPendingScrollAttempts) {
          _pendingScrollAttempts++;
          // Bypass _loadMore() throttle — directly request more messages
          // so the pending scroll isn't blocked by the 700ms guard.
          safeSetState(() => _isLoadingMore = true);
          _messageBloc.add(const LoadMoreMessages(limit: _pageSize));
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
      if (_showScrollToBottom) safeSetState(() => _newMessageCount++);
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
        onRefresh: _onRefresh,
        itemBuilder: (context, uiState, allUiMessages) => _buildListItem(context, uiState, allUiMessages),
      );
    } else if (state is MessagesError) {
      return _buildErrorState(context, state.error, () => _messageBloc.add(LoadMessages(
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
          left: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 3),
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
    );
  }

  Widget _buildMessageInputArea() {
    return AppCard.outlined(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppDimens.paddingSmall),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 28.0,
            onPressed: _showAttachmentPicker,
            tooltip: 'Attachments',
          ),
          Expanded(
            child: _chat != null && _chat!.members.isNotEmpty
                ? MentionTextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    members: _chat!.members,
                    currentUserId: _currentUserId,
                    hint: context.l10n.typeMessage,
                    minLines: 1,
                    maxLines: 5,
                    onSubmitted: (_) => _sendMessage(),
                  )
                : AppTextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 5,
                    hint: context.l10n.typeMessage,
                    onSubmitted: (_) => _sendMessage(),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            iconSize: 28.0,
            onPressed: () => EmojiPickerBottomSheet.show(
              context,
              onEmojiSelected: (emoji) => EmojiTextEditingHelper.insertEmoji(_messageController, emoji),
              textController: _messageController,
            ),
            tooltip: 'Insert emoji',
          ),
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.check : Icons.send,
              color: Theme.of(context).colorScheme.primary,
            ),
            iconSize: 28.0,
            onPressed: _messageController.text.trim().isNotEmpty ? _sendMessage : null,
            tooltip: _isEditMode ? context.l10n.save : context.l10n.send,
          ),
        ],
      ),
    );
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
        onAddMemberPressed: _chat!.type == ChatType.group ? _showAddMember : null,
        onSearchPressed: _showMessageSearch,
      );
    }

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(chatTitle, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          AppText(subtitleText, style: AppTextStyles.labelSmall.copyWith(color: _isOtherTyping ? AppColors.primary : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectionMode),
      title: AppText(context.l10n.selectedCount(_selectedMessageIds.length), style: AppTextStyles.titleMedium),
      actions: [
        IconButton(icon: const Icon(Icons.copy), tooltip: context.l10n.copyMessage, onPressed: () {
          final state = _messageBloc.state;
          if (state is MessagesLoaded) _copySelectedMessages(state.uiMessages);
        }),
        IconButton(icon: const Icon(Icons.forward), tooltip: context.l10n.forwardMessage, onPressed: _forwardSelectedMessages),
        IconButton(icon: const Icon(Icons.delete), tooltip: context.l10n.deleteMessage, onPressed: _deleteSelectedMessages),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, MessageUIState uiState, List<MessageUIState> allMessages) {
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
          color: isHighlighted ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (uiState.showDateSeparator) _buildDateSeparator(uiState.dateSeparatorText ?? ''),
              MessageItem(
                uiState: uiState,
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedMessageIds.contains(uiState.id),
                onSelectionChanged: (_) => _toggleSelection(uiState.id),
                onSwipeReply: () { if (uiState.message != null) _startReply(uiState.message!); },
                onReplyPreviewTap: () => _scrollToMessage(uiState.replyMessage?.id, allMessages),
                isGroupChat: _chat?.type == ChatType.group,
                onLongPress: () { if (!_isSelectionMode && uiState.message != null) _showMessageOptions(context, uiState.message!, uiState.isFromCurrentUser); },
                onTap: () { if (_isSelectionMode) _toggleSelection(uiState.id); },
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
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium, vertical: AppDimens.paddingXSmall),
          decoration: BoxDecoration(color: AppColors.textSecondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
          child: AppText(text, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildUnreadSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceSmall),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.error.withValues(alpha: 0.5))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingSmall), child: AppText(context.l10n.unreadSeparatorLabel, style: AppTextStyles.labelSmall.copyWith(color: AppColors.error))),
          Expanded(child: Divider(color: AppColors.error.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildSystemEvent(MessageUIState uiState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceSmall, horizontal: AppDimens.paddingMedium),
      child: Center(child: AppText(uiState.systemEvent?.formattedText ?? uiState.content, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic), textAlign: TextAlign.center)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: AppDimens.iconSizeXXLarge, color: AppColors.textSecondary),
          const SizedBox(height: AppDimens.spaceMedium),
          AppText(context.l10n.noMessagesInChat, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
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
            Icon(Icons.error_outline, size: AppDimens.iconSizeXXLarge, color: AppColors.error),
            const SizedBox(height: AppDimens.spaceMedium),
            AppText(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            if (retryAction != null) ...[
              const SizedBox(height: AppDimens.spaceLarge),
              AppButton.primary(text: context.l10n.retryOperation, icon: Icons.refresh, onPressed: retryAction),
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
                        spacing: 10, runSpacing: 10,
                        children: [
                          for (final emoji in (_messageBloc.state is MessagesLoaded)
                              ? (_messageBloc.state as MessagesLoaded).frequentReactions
                              : const <String>['👍', '❤️', '😂', '😮', '😢', '😡'])
                            _buildReactionItem(ctx, emoji, () {
                              Navigator.pop(ctx);
                              _messageBloc.add(ToggleReaction(messageId: message.id, emojiCode: emoji));
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildAddReactionItem(ctx, () {
                      Navigator.pop(ctx);
                      EmojiPickerBottomSheet.show(this.context, onEmojiSelected: (emoji) => _messageBloc.add(ToggleReaction(messageId: message.id, emojiCode: emoji)));
                    }),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildActionTile(Icons.copy, ctx.l10n.copyMessage, () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: message.content));
                AppSnackBar.show(context: this.context, message: this.context.l10n.messageCopied, type: FeedbackType.success);
              }),
              _buildActionTile(Icons.reply, ctx.l10n.replyMessage, () { Navigator.pop(ctx); _startReply(message); }),
              if (isCurrentUser) ...[
                _buildActionTile(Icons.edit, ctx.l10n.editMessage, () { Navigator.pop(ctx); _startEditMode(message); }),
                _buildActionTile(Icons.delete, ctx.l10n.deleteMessage, () { Navigator.pop(ctx); _confirmDeleteMessage(message); }),
              ],
              _buildActionTile(Icons.forward, ctx.l10n.forwardMessage, () { Navigator.pop(ctx); showForwardMessageSheet(this.context, messages: [message]); }),
              _buildActionTile(Icons.checklist, ctx.l10n.selectAll, () { Navigator.pop(ctx); _enterSelectionMode(message.id); }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionItem(BuildContext context, String emoji, VoidCallback onTap) {
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
        child: Icon(Icons.add, size: 20, color: Theme.of(context).iconTheme.color),
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
            _messageBloc.add(DeleteMessage(message.id));
          },
        ),
      ],
    );
  }
}
