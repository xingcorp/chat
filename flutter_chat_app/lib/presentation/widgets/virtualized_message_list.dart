import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/presentation/widgets/message_item.dart';
import 'package:logger/logger.dart';

/// **ENTERPRISE VIRTUALIZED MESSAGE LIST**
///
/// High-performance message list widget with virtualization for handling
/// thousands of messages while maintaining <50MB memory usage per conversation.
///
/// **Performance Targets:**
/// - Memory usage: <50MB for 10,000+ messages
/// - Scroll performance: 60 FPS smooth scrolling
/// - Initial load: <500ms for any conversation size
/// - Message rendering: <16ms per message
///
/// **Features:**
/// - Virtual scrolling with dynamic item heights
/// - Intelligent preloading and caching
/// - Memory-efficient message rendering
/// - Smooth scroll animations
/// - Auto-scroll to new messages
///
/// **Architecture**: Optimized widget with enterprise memory management
class VirtualizedMessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final ScrollController? scrollController;
  final Function(ChatMessage)? onMessageTap;
  final Function(ChatMessage)? onMessageLongPress;
  final Function()? onLoadMore;
  final bool isLoading;
  final bool hasMore;
  final EdgeInsets? padding;
  final bool reverse;
  final bool autoScrollToBottom;

  const VirtualizedMessageList({
    Key? key,
    required this.messages,
    this.scrollController,
    this.onMessageTap,
    this.onMessageLongPress,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = false,
    this.padding,
    this.reverse = true,
    this.autoScrollToBottom = true,
  }) : super(key: key);

  @override
  State<VirtualizedMessageList> createState() => _VirtualizedMessageListState();
}

class _VirtualizedMessageListState extends State<VirtualizedMessageList>
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  
  // Scroll management
  late ScrollController _scrollController;
  bool _isScrollControllerInternal = false;
  
  // Virtualization parameters
  static const int _preloadBuffer = 20; // Messages to preload above/below viewport
  static const int _maxCachedMessages = 100; // Maximum messages to keep in memory
  static const double _estimatedItemHeight = 80.0; // Estimated message height
  
  // Performance tracking
  final Map<int, double> _itemHeights = {}; // Cache of actual item heights
  final Set<int> _visibleIndices = {}; // Currently visible message indices
  final Map<int, Widget> _cachedWidgets = {}; // Cached message widgets
  
  // Scroll state
  double _scrollOffset = 0.0;
  bool _isScrolling = false;
  Timer? _scrollEndTimer;
  
  // Auto-scroll management
  bool _shouldAutoScroll = true;
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    _initializeScrollController();
    _logger.d('VirtualizedMessageList initialized with ${widget.messages.length} messages');
  }

  @override
  void didUpdateWidget(VirtualizedMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle new messages
    if (widget.messages.length > oldWidget.messages.length) {
      _handleNewMessages(oldWidget.messages.length);
    }
    
    // Clear cache if messages changed significantly
    if (widget.messages.length != oldWidget.messages.length) {
      _optimizeCache();
    }
  }

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    
    if (_isScrollControllerInternal) {
      _scrollController.dispose();
    }
    
    // Clear caches
    _itemHeights.clear();
    _visibleIndices.clear();
    _cachedWidgets.clear();
    
    _logger.d('VirtualizedMessageList disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: CustomScrollView(
        controller: _scrollController,
        reverse: widget.reverse,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Load more indicator at top
          if (widget.hasMore && !widget.reverse)
            SliverToBoxAdapter(
              child: _buildLoadMoreIndicator(),
            ),
          
          // Virtualized message list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              _buildMessageItem,
              childCount: widget.messages.length,
              findChildIndexCallback: _findChildIndex,
            ),
          ),
          
          // Load more indicator at bottom
          if (widget.hasMore && widget.reverse)
            SliverToBoxAdapter(
              child: _buildLoadMoreIndicator(),
            ),
          
          // Bottom padding
          if (widget.padding != null)
            SliverPadding(
              padding: EdgeInsets.only(bottom: widget.padding!.bottom),
            ),
        ],
      ),
    );
  }

  /// **Initialize scroll controller - PERFORMANCE SETUP**
  void _initializeScrollController() {
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _isScrollControllerInternal = true;
    }

    _scrollController.addListener(_onScroll);
  }

  /// **Handle scroll events - VIRTUALIZATION LOGIC**
  void _onScroll() {
    final offset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;
    
    // Update scroll state
    _scrollOffset = offset;
    _isScrolling = true;
    _isAtBottom = offset <= 100; // Consider "at bottom" if within 100px
    
    // Reset scroll end timer
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(milliseconds: 150), () {
      _isScrolling = false;
      _optimizeCache();
    });

    // Update visible indices for virtualization
    _updateVisibleIndices();
    
    // Handle load more
    if (widget.hasMore && widget.onLoadMore != null) {
      if (widget.reverse && offset >= maxScroll - 200) {
        // Load more at top (reverse list)
        widget.onLoadMore!();
      } else if (!widget.reverse && offset <= 200) {
        // Load more at top (normal list)
        widget.onLoadMore!();
      }
    }
  }

  /// **Handle scroll notifications - PERFORMANCE MONITORING**
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _shouldAutoScroll = false;
    } else if (notification is ScrollEndNotification) {
      // Re-enable auto-scroll if user scrolled to bottom
      if (_isAtBottom) {
        _shouldAutoScroll = true;
      }
    }
    
    return false;
  }

  /// **Update visible indices for virtualization - MEMORY OPTIMIZATION**
  void _updateVisibleIndices() {
    if (widget.messages.isEmpty) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    final scrollOffset = _scrollController.offset;
    
    // Calculate visible range with buffer
    final startOffset = scrollOffset - (_preloadBuffer * _estimatedItemHeight);
    final endOffset = scrollOffset + viewportHeight + (_preloadBuffer * _estimatedItemHeight);
    
    // Find visible message indices
    final newVisibleIndices = <int>{};
    double currentOffset = 0.0;
    
    for (int i = 0; i < widget.messages.length; i++) {
      final itemHeight = _itemHeights[i] ?? _estimatedItemHeight;
      final itemStart = currentOffset;
      final itemEnd = currentOffset + itemHeight;
      
      // Check if item is in visible range
      if (itemEnd >= startOffset && itemStart <= endOffset) {
        newVisibleIndices.add(i);
      }
      
      currentOffset += itemHeight;
      
      // Early exit if we're past the visible range
      if (itemStart > endOffset) break;
    }
    
    // Update visible indices
    _visibleIndices.clear();
    _visibleIndices.addAll(newVisibleIndices);
    
    _logger.t('Updated visible indices: ${_visibleIndices.length} messages visible');
  }

  /// **Build message item with caching - PERFORMANCE OPTIMIZATION**
  Widget? _buildMessageItem(BuildContext context, int index) {
    if (index >= widget.messages.length) return null;
    
    final message = widget.messages[index];
    
    // Use cached widget if available and not scrolling
    if (!_isScrolling && _cachedWidgets.containsKey(index)) {
      return _cachedWidgets[index];
    }
    
    // Build new message widget
    final messageWidget = _buildOptimizedMessageItem(message, index);
    
    // Cache widget if within visible range
    if (_visibleIndices.contains(index)) {
      _cachedWidgets[index] = messageWidget;
    }
    
    return messageWidget;
  }

  /// **Build optimized message item - MEMORY EFFICIENT**
  Widget _buildOptimizedMessageItem(ChatMessage message, int index) {
    return MeasuredWidget(
      onHeightMeasured: (height) {
        _itemHeights[index] = height;
      },
      child: MessageItem(
        message: message,
        sender: message.sender,
        isCurrentUser: message.isFromCurrentUser,
        onTap: widget.onMessageTap != null
            ? () => widget.onMessageTap!(message)
            : null,
        onLongPress: widget.onMessageLongPress != null
            ? () => widget.onMessageLongPress!(message)
            : null,
      ),
    );
  }

  /// **Handle new messages - AUTO-SCROLL LOGIC**
  void _handleNewMessages(int previousCount) {
    if (!mounted) return;
    
    final newMessageCount = widget.messages.length - previousCount;
    _logger.d('Handling $newMessageCount new messages');
    
    // Auto-scroll to bottom if enabled and user is at bottom
    if (widget.autoScrollToBottom && _shouldAutoScroll && _isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  /// **Scroll to bottom - SMOOTH ANIMATION**
  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    
    if (animate) {
      _scrollController.animateTo(
        0.0, // Bottom for reverse list
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(0.0);
    }
  }

  /// **Optimize cache - MEMORY MANAGEMENT**
  void _optimizeCache() {
    if (_cachedWidgets.length <= _maxCachedMessages) return;
    
    _logger.d('Optimizing widget cache: ${_cachedWidgets.length} cached widgets');
    
    // Remove widgets that are far from visible range
    final keysToRemove = <int>[];
    
    for (final key in _cachedWidgets.keys) {
      if (!_visibleIndices.contains(key)) {
        // Calculate distance from visible range
        final minVisible = _visibleIndices.isEmpty ? 0 : _visibleIndices.reduce((a, b) => a < b ? a : b);
        final maxVisible = _visibleIndices.isEmpty ? 0 : _visibleIndices.reduce((a, b) => a > b ? a : b);
        
        if (key < minVisible - _preloadBuffer || key > maxVisible + _preloadBuffer) {
          keysToRemove.add(key);
        }
      }
    }
    
    // Remove distant cached widgets
    for (final key in keysToRemove) {
      _cachedWidgets.remove(key);
    }
    
    _logger.d('Cache optimized: removed ${keysToRemove.length} widgets, ${_cachedWidgets.length} remaining');
  }

  /// **Find child index callback for SliverList**
  int? _findChildIndex(Key key) {
    if (key is ValueKey<String>) {
      final messageId = key.value;
      return widget.messages.indexWhere((message) => message.id == messageId);
    }
    return null;
  }

  /// **Build empty state**
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// **Build load more indicator**
  Widget _buildLoadMoreIndicator() {
    if (!widget.isLoading) {
      return const SizedBox.shrink();
    }
    
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// **Widget for measuring item heights - PERFORMANCE HELPER**
class MeasuredWidget extends StatefulWidget {
  final Widget child;
  final Function(double height) onHeightMeasured;

  const MeasuredWidget({
    Key? key,
    required this.child,
    required this.onHeightMeasured,
  }) : super(key: key);

  @override
  State<MeasuredWidget> createState() => _MeasuredWidgetState();
}

class _MeasuredWidgetState extends State<MeasuredWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeight);
  }

  void _measureHeight(_) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      widget.onHeightMeasured(renderBox.size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
