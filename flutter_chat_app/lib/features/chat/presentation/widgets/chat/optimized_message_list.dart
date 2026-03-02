import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/message_item.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_list_transformer.dart';
import 'package:flutter_chat_app/core/monitoring/i_analytics_service.dart';
import 'package:get_it/get_it.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_chat_app/core/monitoring/i_performance_monitor.dart';

/// Widget for displaying a large list of messages with performance optimization
class OptimizedMessageList extends StatefulWidget {
  /// List of messages to display
  final List<ChatMessage> messages;
  
  /// Called when a message is tapped
  final Function(ChatMessage message)? onMessageTap;
  
  /// Called when a message is long-pressed
  final Function(ChatMessage message)? onMessageLongPress;
  
  /// Called when user scrolls to load more messages
  final VoidCallback? onLoadMore;
  
  /// Called when messages become visible on screen
  final Function(List<String> messageIds)? onMessagesVisible;
  
  /// Called when all new messages have been viewed
  final VoidCallback? onAllNewMessagesRead;
  
  /// Whether the list is loading more messages
  final bool isLoadingMore;
  
  /// ID of the current user
  final String currentUserId;
  
  /// Whether this is a group chat (affects message display)
  final bool isGroupChat;
  
  /// Conversation members for read receipt display
  final List<ConversationMember> members;
  
  /// Controller for programmatically scrolling to specific messages
  final AutoScrollController? scrollController;
  
  /// Called when user starts/stops scrolling
  final Function(bool isScrolling)? onScrollStateChanged;
  
  /// Average height estimate for message items (used for optimization)
  final double estimatedItemHeight;
  
  const OptimizedMessageList({
    Key? key,
    required this.messages,
    this.onMessageTap,
    this.onMessageLongPress,
    this.onLoadMore,
    this.onMessagesVisible,
    this.onAllNewMessagesRead,
    this.isLoadingMore = false,
    required this.currentUserId,
    this.isGroupChat = false,
    this.members = const [],
    this.scrollController,
    this.onScrollStateChanged,
    this.estimatedItemHeight = 80.0,
  }) : super(key: key);
  
  @override
  State<OptimizedMessageList> createState() => _OptimizedMessageListState();
}

class _OptimizedMessageListState extends State<OptimizedMessageList> with TickerProviderStateMixin {
  static const double _loadMoreThreshold = 200.0;
  static const String _loadMoreTag = 'loadMore';
  static const Duration _scrollDuration = Duration(milliseconds: 300);
  
  final Set<String> _visibleMessageIds = {};
  late AutoScrollController _scrollController;
  bool _isScrolling = false;
  Timer? _scrollingTimer;
  bool _hasRequestedLoadMore = false;
  String? _scrollToMessageId;
  bool _isScrollControllerAttached = false;
  
  final _performanceMonitor = GetIt.I<IPerformanceMonitor>();
  final _analytics = GetIt.I<IAnalyticsService>();
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? AutoScrollController(
      viewportBoundaryGetter: () => Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: Axis.vertical,
    );
    
    // We need to add a small delay to allow the widget to be built
    // before attempting to scroll to a specific message
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _isScrollControllerAttached = true;
      _scrollToBottomIfNeeded();
    });
  }
  
  @override
  void didUpdateWidget(OptimizedMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Use the provided scrollController if it changes
    if (widget.scrollController != null && widget.scrollController != _scrollController) {
      _scrollController = widget.scrollController!;
    }
    
    // Schedule a scroll to bottom if new messages from current user were added
    if (widget.messages.length > oldWidget.messages.length) {
      final newMessages = widget.messages.take(widget.messages.length - oldWidget.messages.length);
      final hasNewMessagesFromCurrentUser = newMessages.any((m) => m.sender.id == widget.currentUserId);
      
      if (hasNewMessagesFromCurrentUser) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(animated: true);
        });
      }
    }
  }
  
  @override
  void dispose() {
    _scrollingTimer?.cancel();
    // Only dispose the controller if we created it
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
  
  void _handleScroll() {
    // Track scrolling state for UI effects
    if (!_isScrolling) {
      setState(() {
        _isScrolling = true;
      });
      widget.onScrollStateChanged?.call(true);
    }
    
    _scrollingTimer?.cancel();
    _scrollingTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isScrolling = false;
        });
        widget.onScrollStateChanged?.call(false);
      }
    });
    
    // Load more messages when scrolling to the top
    if (!_hasRequestedLoadMore && 
        _scrollController.position.pixels <= _loadMoreThreshold &&
        !widget.isLoadingMore) {
      _hasRequestedLoadMore = true;
      widget.onLoadMore?.call();
      
      // Reset the flag after a delay to prevent multiple calls
      Future.delayed(const Duration(seconds: 2), () {
        _hasRequestedLoadMore = false;
      });
    }
  }
  
  /// Scroll to a specific message by index
  void scrollToIndex(int index, {bool animated = true}) {
    if (!_isScrollControllerAttached || !mounted) return;
    
    _performanceMonitor.startTrace(TraceType.custom, customTraceName: 'scroll_to_message');
    _scrollController.scrollToIndex(
      index,
      preferPosition: AutoScrollPosition.middle,
      duration: animated ? _scrollDuration : Duration.zero,
    ).then((_) {
      _performanceMonitor.stopTrace(TraceType.custom, customTraceName: 'scroll_to_message');
    });
  }
  
  /// Scroll to a specific message by ID
  Future<bool> scrollToMessage(String messageId, {bool animated = true}) async {
    if (!_isScrollControllerAttached || !mounted) return false;
    
    final index = widget.messages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      scrollToIndex(index, animated: animated);
      return true;
    }
    
    // Message not loaded yet, save for later
    _scrollToMessageId = messageId;
    return false;
  }
  
  /// Scroll to the bottom of the list
  Future<void> _scrollToBottom({bool animated = false}) async {
    if (!_isScrollControllerAttached || !mounted) return;
    
    if (widget.messages.isEmpty) return;
    
    final lastIndex = widget.messages.length - 1;
    scrollToIndex(lastIndex, animated: animated);
  }
  
  /// Check if we need to scroll to bottom on initial load
  void _scrollToBottomIfNeeded() {
    if (widget.messages.isEmpty) return;
    
    // If we have a specific message to scroll to, try to do that first
    if (_scrollToMessageId != null) {
      scrollToMessage(_scrollToMessageId!, animated: false).then((found) {
        if (found) {
          _scrollToMessageId = null;
        }
      });
      return;
    }
    
    // Otherwise scroll to bottom if there are recent messages from current user
    final recentMessages = widget.messages.reversed.take(10);
    if (recentMessages.any((m) => m.sender.id == widget.currentUserId)) {
      _scrollToBottom(animated: false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return Center(child: Text(context.l10n.noMessages));
    }

    final uiStates = MessageListTransformer.transform(
      messages: widget.messages,
      currentUserId: widget.currentUserId,
      isGroupChat: widget.isGroupChat,
      members: widget.members,
    );
    
    // Performance trace
    _performanceMonitor.startTrace(TraceType.custom,
      customTraceName: 'render_message_list',
      attributes: {'count': widget.messages.length.toString()});
    
    Widget messageList = ListView.builder(
      // Key performance optimizations here:
      cacheExtent: MediaQuery.of(context).size.height * 2, // Increase cache for smoother scrolling
      physics: const AlwaysScrollableScrollPhysics(),
      reverse: true,
      controller: _scrollController,
      itemCount: widget.messages.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the top when loading more messages
        if (widget.isLoadingMore && index == 0) {
          return const Center(
            key: ValueKey(_loadMoreTag),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Adjust index to account for loading indicator
        final messageIndex = widget.isLoadingMore ? index - 1 : index;
        if (messageIndex < 0 || messageIndex >= widget.messages.length) {
          return const SizedBox.shrink();
        }
        
        final message = widget.messages[messageIndex];
        final uiState = uiStates[messageIndex];
        
        // Wrap each message in RepaintBoundary for render optimization
        return RepaintBoundary(
          child: AutoScrollTag(
            key: ValueKey('message_scroll_${message.id}'),
            controller: _scrollController,
            index: messageIndex,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: VisibilityDetector(
                key: ValueKey('visibility_${message.id}'),
                onVisibilityChanged: (visibilityInfo) {
                  // Track which messages are visible
                  if (visibilityInfo.visibleFraction > 0.7) {
                    _visibleMessageIds.add(message.id);
                    widget.onMessagesVisible?.call([message.id]);
                  } else {
                    _visibleMessageIds.remove(message.id);
                  }
                },
                child: MessageItem(
                  uiState: uiState,
                  onTap: widget.onMessageTap != null ? () => widget.onMessageTap!(message) : null,
                  onLongPress: widget.onMessageLongPress != null ? () => widget.onMessageLongPress!(message) : null,
                  onReplyPreviewTap: uiState.replyMessage != null
                      ? () {
                          final targetIndex = widget.messages.indexWhere(
                            (m) =>
                                m.id == uiState.replyMessage!.originalMessageId,
                          );
                          if (targetIndex < 0) return;
                          _scrollController.scrollToIndex(
                            targetIndex,
                            preferPosition: AutoScrollPosition.middle,
                            duration: const Duration(milliseconds: 250),
                          );
                        }
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
    
    // Wrap the list in a NotificationListener to detect scrolling
    messageList = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _handleScroll();
        }
        return false;
      },
      child: messageList,
    );
    
    // Stop the performance trace after building
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _performanceMonitor.stopTrace(TraceType.custom, customTraceName: 'render_message_list');
    });
    
    return messageList;
  }
} 