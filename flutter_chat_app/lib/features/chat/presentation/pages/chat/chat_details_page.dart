import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/location_service.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/image_compression_helper.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_conversation_detail_usecase.dart';
import 'package:flutter_chat_app/features/chat/data/datasources/chat/chat_remote_datasource.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/message_search/message_search_bloc.dart';
import 'package:flutter_chat_app/data/datasources/user/user_remote_datasource.dart';
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
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/read_receipt_avatars.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/reply_preview.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/typing_indicator.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
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
  late final AutoScrollController _scrollController;
  late final MessageBloc _messageBloc;
  late final GetConversationDetailUseCase _getConversationDetail;
  Chat? _chat;
  String _currentUserId = '';
  bool _hasInitializedContext = false;

  static const List<String> _quickReactions = <String>[
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
  ];

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
    // MessageBloc is a factory in DI, so this instance is unique to this page instance.
    // When chatId changes in desktop view, ValueKey forces a new State instance, 
    // ensuring clean state and correct bloc scope.
    _messageBloc = getIt<MessageBloc>();
    _getConversationDetail = getIt<GetConversationDetailUseCase>();

    _scrollController = AutoScrollController(axis: Axis.vertical);
    _scrollController.addListener(_onScroll);

    // Initial load
    _messageBloc.add(
      LoadMessages(
        chatId: widget.chatId,
        limit: _pageSize,
        forceRefresh: false,
      ),
    );

    unawaited(_loadChatHeader());
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

    // Read receipts
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
    if (!mounted) return;
    
    result.fold(
      (_) {},
      (chat) {
        if (chat == null) return;
        safeSetState(() {
          _chat = chat;
        });

        _messageController.updateMentions({
          for (final m in chat.members)
            if (m.userId.isNotEmpty && (m.fullName?.trim().isNotEmpty ?? false))
              m.userId: m.fullName!.trim(),
        });

        _messageBloc.setTransformContext(
          currentUserId: _currentUserId,
          isGroupChat: chat.type == ChatType.group,
        );
      },
    );
  }

  void _onScroll() {
    if (_isProgrammaticScroll) return;
    final position = _scrollController.position;
    if (position.hasPixels) {
      if (position.extentAfter < 200) {
        _loadMore();
      }
    }

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
    _messageController.removeListener(_handleControllerChanges);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _messageBloc.close();
    _typingSubscription?.cancel();
    _readReceiptSubscription?.cancel();
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
    );
  }

  void _showAddMember() {
    if (_chat == null) return;
    
    final currentMemberIds = _chat?.members.map((m) => m.userId).toList() ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => AddMemberPanel(
          conversationId: widget.chatId,
          currentMemberIds: currentMemberIds,
          onSearchUsers: (query) => _searchUsers(query),
          onAddMembers: (userIds) => _addMembersToGroup(userIds),
        ),
      ),
    ).then((result) {
      // If members were added successfully, refresh chat info
      if (result == true) {
        _refreshChatInfo();
      }
    });
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

  /// Add members to group via API
  Future<bool> _addMembersToGroup(List<String> userIds) async {
    try {
      // Use the remote data source directly to add members
      final remoteDataSource = getIt<IChatRemoteDataSource>();
      await remoteDataSource.addMembersToGroup(
        conversationId: widget.chatId,
        memberIds: userIds,
      );
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorOccurred),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  /// Refresh chat info after adding members
  void _refreshChatInfo() {
    // Reload chat header info
    _loadChatHeader();
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
      // Messages not loaded yet, will retry later
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
      // Message found, scroll to it
      _isProgrammaticScroll = true;
      _scrollController.scrollToIndex(
        messageIndex,
        preferPosition: AutoScrollPosition.middle,
      ).then((_) {
        if (mounted) {
          setState(() {
            _isProgrammaticScroll = false;
            _pendingScrollToMessageId = null;
          });
        }
      });
    } else {
      // Message not found, increment attempts
      _pendingScrollAttempts++;
      if (_pendingScrollAttempts < _maxPendingScrollAttempts) {
        // Retry after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _attemptJumpToMessage();
        });
      } else {
        // Max attempts reached, give up
        _pendingScrollToMessageId = null;
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

    return BlocProvider<MessageBloc>.value(
      value: _messageBloc,
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
    );
  }

  void _handleBlocStateChanges(BuildContext context, MessageState state) {
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
        } else if (!state.hasReachedMax && _pendingScrollAttempts < _maxPendingScrollAttempts) {
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
    if (state is MessageInitial || state is MessagesLoading) {
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
        scrollController: _scrollController,
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
                readReceipts: _readReceipts[uiState.id],
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
                          for (final emoji in _quickReactions)
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
