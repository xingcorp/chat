import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/presentation/widgets/chat/message_item.dart';
import 'package:flutter_chat_app/core/monitoring/analytics_service.dart';
import 'package:get_it/get_it.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';

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
  
  /// Controller for programmatically scrolling to specific messages
  final AutoScrollController? scrollController;
  
  /// Called when user starts/stops scrolling
  final Function(bool isScrolling)? onScrollStateChanged;
  
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
    this.scrollController,
    this.onScrollStateChanged,
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
  
  final _performanceMonitor = GetIt.I<PerformanceMonitor>();
  final _analytics = GetIt.I<AnalyticsService>();
  
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
    
    _performanceMonitor.startTrace('scroll_to_message');
    _scrollController.scrollToIndex(
      index,
      preferPosition: AutoScrollPosition.middle,
      duration: animated ? _scrollDuration : Duration.zero,
    ).then((_) {
      _performanceMonitor.stopTrace('scroll_to_message');
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
  
  void _scrollToBottomIfNeeded() {
    // If we have a pending message to scroll to, do that instead
    if (_scrollToMessageId != null) {
      scrollToMessage(_scrollToMessageId!, animated: true);
      _scrollToMessageId = null;
      return;
    }
    
    // Otherwise scroll to bottom for initial load
    _scrollToBottom(animated: false);
  }
  
  /// Track which messages are currently visible on screen
  void _trackVisibleMessages(String messageId, bool isVisible) {
    if (isVisible) {
      _visibleMessageIds.add(messageId);
    } else {
      _visibleMessageIds.remove(messageId);
    }
    
    // Report to analytics which messages are visible
    if (_visibleMessageIds.isNotEmpty) {
      widget.onMessagesVisible?.call(_visibleMessageIds.toList());
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _handleScroll();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        reverse: true, // Display newest messages at the bottom
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.messages.length + (widget.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the top when loading more
          if (widget.isLoadingMore && index == 0) {
            return Container(
              key: const Key(_loadMoreTag),
              height: 50,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            );
          }
          
          final messageIndex = widget.isLoadingMore ? index - 1 : index;
          if (messageIndex < 0 || messageIndex >= widget.messages.length) {
            return const SizedBox.shrink();
          }
          
          final message = widget.messages[messageIndex];
          final showSenderInfo = widget.isGroupChat && 
                               !message.isFromCurrentUser && 
                               _shouldShowSenderInfo(messageIndex);
          
          final isLastInGroup = _isLastInMessageGroup(messageIndex);
          
          return AutoScrollTag(
            key: ValueKey('message-${message.id}'),
            controller: _scrollController,
            index: messageIndex,
            child: VisibilityDetector(
              key: ValueKey('visibility-${message.id}'),
              onVisibilityChanged: (info) {
                // Consider a message visible if at least 30% is showing
                final isVisible = info.visibleFraction > 0.3;
                _trackVisibleMessages(message.id, isVisible);
              },
              child: MessageItem(
                message: message,
                onTap: widget.onMessageTap != null ? 
                  () => widget.onMessageTap!(message) : null,
                onLongPress: widget.onMessageLongPress != null ? 
                  () => widget.onMessageLongPress!(message) : null,
                isLastInGroup: isLastInGroup,
                showSenderInfo: showSenderInfo,
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Determine if this message should show sender info
  bool _shouldShowSenderInfo(int index) {
    if (index >= widget.messages.length - 1) return true;
    
    final currentMessage = widget.messages[index];
    final nextMessage = widget.messages[index + 1];
    
    // Show sender info if this is the first message from this sender
    // after messages from other senders
    return currentMessage.sender.id != nextMessage.sender.id;
  }
  
  /// Determine if this message is the last in a group of messages from the same sender
  bool _isLastInMessageGroup(int index) {
    if (index <= 0) return true;
    
    final currentMessage = widget.messages[index];
    final previousMessage = widget.messages[index - 1];
    
    // Last in group if next message is from a different sender
    return currentMessage.sender.id != previousMessage.sender.id;
  }
} 