import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/presentation/widgets/date_separator.dart';
import 'package:flutter_chat_app/presentation/widgets/message_item.dart';
import 'package:flutter_chat_app/core/services/date_formatter_service.dart';
import 'package:flutter_chat_app/core/utils/debouncer.dart';

/// Widget cuộn tin nhắn với tính năng phân trang, giữ vị trí cuộn và virtual rendering
class PaginatedMessageList extends StatefulWidget {
  /// Danh sách tin nhắn hiển thị
  final List<ChatMessage> messages;
  
  /// Callback khi cần tải thêm tin nhắn cũ hơn
  final Future<void> Function() onLoadMore;
  
  /// Callback khi cần tải tin nhắn mới hơn (pull-to-refresh)
  final Future<void> Function() onRefresh;
  
  /// Callback khi nhấn vào một tin nhắn
  final Function(ChatMessage)? onMessageTap;
  
  /// Callback khi nhấn giữ một tin nhắn
  final Function(ChatMessage)? onMessageLongPress;
  
  /// Flag đánh dấu đang tải thêm tin nhắn
  final bool isLoadingMore;
  
  /// Flag đánh dấu đã tải hết tin nhắn cũ
  final bool hasReachedEnd;
  
  /// ID tin nhắn cần focus (cuộn đến)
  final String? initialScrollMessageId;
  
  /// ID người dùng hiện tại
  final String currentUserId;
  
  /// Callback để render item tin nhắn tùy chỉnh
  final Widget Function(BuildContext, ChatMessage, bool)? messageItemBuilder;
  
  /// Constructor
  const PaginatedMessageList({
    Key? key,
    required this.messages,
    required this.onLoadMore,
    required this.onRefresh,
    required this.currentUserId,
    this.onMessageTap,
    this.onMessageLongPress,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.initialScrollMessageId,
    this.messageItemBuilder,
  }) : super(key: key);

  @override
  State<PaginatedMessageList> createState() => _PaginatedMessageListState();
}

class _PaginatedMessageListState extends State<PaginatedMessageList> {
  /// Controller cho danh sách có thể định vị
  final ItemScrollController _itemScrollController = ItemScrollController();
  
  /// Controller theo dõi vị trí cuộn
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  
  /// Controller làm mới danh sách
  final RefreshController _refreshController = RefreshController();
  
  /// Controller tìm kiếm nhanh 
  final ScrollController _jumpScrollController = ScrollController();
  
  /// Danh sách tin nhắn với ngày tách biệt
  List<Object> _itemsWithSeparators = [];
  
  /// Flag kiểm tra đang kéo xuống để tải thêm
  bool _isLoadingMore = false;
  
  /// Flag hiển thị button cuộn xuống
  bool _showScrollToBottom = false;
  
  /// Vị trí cuộn hiện tại
  int _currentFirstIndex = 0;
  
  /// Tin nhắn đang hiển thị theo ngày
  final Map<String, List<int>> _messagesByDate = {};
  
  /// Debouncer cho sự kiện cuộn
  final _scrollDebouncer = Debouncer(milliseconds: 100);
  
  /// Vị trí hiển thị ban đầu
  int _initialScrollIndex = 0;
  
  /// Ngày đang hiển thị cuối cùng trên thanh cuộn
  DateTime? _currentJumpDate;
  
  /// Hiển thị thanh cuộn nhanh
  final bool _showJumpBar = false;

  /// Đang kéo thanh cuộn nhanh
  final bool _isDraggingJumpBar = false;
  
  @override
  void initState() {
    super.initState();
    
    // Xử lý tin nhắn và phân tách ngày
    _processMessages();
    
    // Lắng nghe thay đổi vị trí cuộn
    _itemPositionsListener.itemPositions.addListener(_onScrollPositionChanged);
    
    // Xác định vị trí cuộn ban đầu
    if (widget.initialScrollMessageId != null) {
      _findInitialScrollPosition();
    }
    
    // Lắng nghe sự kiện cuộn thanh jumpbar
    _jumpScrollController.addListener(_onJumpScrollChanged);
  }
  
  @override
  void didUpdateWidget(PaginatedMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Kiểm tra thay đổi tin nhắn
    if (widget.messages != oldWidget.messages) {
      // Lưu lại tin nhắn đầu tiên đang hiển thị hiện tại
      ChatMessage? firstVisibleMsg = _getCurrentFirstVisibleMessage();
      
      // Xử lý lại tin nhắn
      _processMessages();
      
      // Duy trì vị trí cuộn nếu đang tải tin nhắn cũ
      if (oldWidget.isLoadingMore && !widget.isLoadingMore && firstVisibleMsg != null) {
        _maintainScrollPosition(firstVisibleMsg);
      }
    }
  }
  
  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScrollPositionChanged);
    _jumpScrollController.removeListener(_onJumpScrollChanged);
    _jumpScrollController.dispose();
    _scrollDebouncer.dispose();
    super.dispose();
  }
  
  /// Lấy tin nhắn đầu tiên đang hiển thị
  ChatMessage? _getCurrentFirstVisibleMessage() {
    if (_itemPositionsListener.itemPositions.value.isEmpty) {
      return null;
    }
    
    final visibleItems = _itemPositionsListener.itemPositions.value.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    
    if (visibleItems.isEmpty) return null;
    
    final firstVisibleIndex = visibleItems.first.index;
    int messageIndex = firstVisibleIndex;
    
    // Tìm tin nhắn thực tế (bỏ qua date separator)
    while (messageIndex < _itemsWithSeparators.length) {
      final item = _itemsWithSeparators[messageIndex];
      if (item is ChatMessage) {
        return item;
      }
      messageIndex++;
    }
    
    return null;
  }
  
  /// Duy trì vị trí cuộn khi tải thêm tin nhắn cũ
  void _maintainScrollPosition(ChatMessage firstVisibleMsg) {
    // Tìm lại vị trí của tin nhắn trong danh sách mới
    for (int i = 0; i < _itemsWithSeparators.length; i++) {
      final item = _itemsWithSeparators[i];
      if (item is ChatMessage && item.id == firstVisibleMsg.id) {
        // Cuộn đến tin nhắn này
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_itemScrollController.isAttached) {
            _itemScrollController.jumpTo(index: i);
          }
        });
        break;
      }
    }
  }
  
  /// Tìm vị trí ban đầu để cuộn đến
  void _findInitialScrollPosition() {
    for (int i = 0; i < _itemsWithSeparators.length; i++) {
      final item = _itemsWithSeparators[i];
      if (item is ChatMessage && item.id == widget.initialScrollMessageId) {
        _initialScrollIndex = i;
        
        // Cuộn đến vị trí ban đầu sau khi render
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_itemScrollController.isAttached) {
            _itemScrollController.scrollTo(
              index: _initialScrollIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
        break;
      }
    }
  }
  
  /// Xử lý tin nhắn và thêm phân tách ngày
  void _processMessages() {
    final combinedItems = <Object>[];
    _messagesByDate.clear();
    
    String? currentDate;
    
    // Đảo ngược tin nhắn để hiển thị từ dưới lên
    for (int i = widget.messages.length - 1; i >= 0; i--) {
      final message = widget.messages[i];
      
      // Format ngày từ tin nhắn
      final messageDate = DateFormatterService.formatDateForGrouping(message.createdAt);
      
      // Nếu ngày thay đổi, thêm separator
      if (messageDate != currentDate) {
        currentDate = messageDate;
        combinedItems.add(DateSeparator(date: message.createdAt));
        
        // Lưu vị trí bắt đầu cho ngày này
        _messagesByDate[messageDate] = [combinedItems.length - 1];
      }
      
      // Thêm tin nhắn vào danh sách
      combinedItems.add(message);
      
      // Cập nhật index cho nhóm ngày
      _messagesByDate[messageDate]?.add(combinedItems.length - 1);
    }
    
    setState(() {
      _itemsWithSeparators = combinedItems;
    });
  }
  
  /// Xử lý sự kiện khi vị trí cuộn thay đổi
  void _onScrollPositionChanged() {
    _scrollDebouncer.run(() {
      if (!mounted) return;
      
      if (_itemPositionsListener.itemPositions.value.isEmpty) return;
      
      // Sắp xếp các vị trí theo thứ tự
      final positions = _itemPositionsListener.itemPositions.value.toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      
      if (positions.isEmpty) return;
      
      // Lưu vị trí đầu tiên đang hiển thị
      final firstIndex = positions.first.index;
      _currentFirstIndex = firstIndex;
      
      // Kiểm tra nếu đã cuộn gần đến đầu danh sách và cần tải thêm
      if (firstIndex < 5 && !widget.isLoadingMore && !widget.hasReachedEnd && !_isLoadingMore) {
        _loadMoreMessages();
      }
      
      // Kiểm tra nếu cần hiển thị nút cuộn xuống
      final lastIndex = positions.last.index;
      final shouldShowScrollToBottom = lastIndex < _itemsWithSeparators.length - 15;
      
      if (_showScrollToBottom != shouldShowScrollToBottom) {
        setState(() {
          _showScrollToBottom = shouldShowScrollToBottom;
        });
      }
      
      // Cập nhật ngày hiển thị trên thanh cuộn
      _updateCurrentJumpDate(positions);
    });
  }
  
  /// Cập nhật ngày đang hiển thị trên thanh cuộn
  void _updateCurrentJumpDate(Iterable<ItemPosition> positions) {
    if (positions.isEmpty) return;

    // Lấy vị trí hiển thị đầu tiên
    final visibleIndex = positions.first.index;
    if (visibleIndex >= _itemsWithSeparators.length) return;

    // Tìm ngày gần nhất
    DateTime? date;
    for (int i = visibleIndex; i >= 0; i--) {
      final item = _itemsWithSeparators[i];
      if (item is DateTime) {
        date = item;
        break;
      }
    }

    if (date != null && (_currentJumpDate == null || !_currentJumpDate!.isAtSameMomentAs(date))) {
      setState(() {
        _currentJumpDate = date;
      });
    }
  }
  
  /// Xử lý sự kiện khi cuộn thanh jumpbar
  void _onJumpScrollChanged() {
    if (!_jumpScrollController.hasClients) return;
    
    // Tính toán vị trí cuộn dựa trên tỷ lệ của thanh jumpbar
    final scrollRatio = _jumpScrollController.position.pixels / _jumpScrollController.position.maxScrollExtent;
    
    // Lấy tất cả các ngày theo thứ tự
    final sortedDates = _messagesByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sắp xếp giảm dần
    
    if (sortedDates.isEmpty) return;
    
    // Chọn ngày dựa trên vị trí cuộn
    final selectedDateIndex = (scrollRatio * (sortedDates.length - 1)).round();
    final selectedDate = sortedDates[selectedDateIndex];
    
    // Lấy vị trí của tin nhắn đầu tiên trong ngày
    final messageIndices = _messagesByDate[selectedDate];
    if (messageIndices == null || messageIndices.isEmpty) return;
    
    // Cuộn đến tin nhắn đầu tiên của ngày
    if (_itemScrollController.isAttached) {
      _itemScrollController.jumpTo(index: messageIndices.first);
    }
  }
  
  /// Tải thêm tin nhắn cũ
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      await widget.onLoadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }
  
  /// Hàm làm mới danh sách và tải tin nhắn mới
  Future<void> _onRefresh() async {
    try {
      await widget.onRefresh();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }
  
  /// Cuộn xuống tin nhắn cuối cùng
  void _scrollToBottom() {
    if (_itemScrollController.isAttached && _itemsWithSeparators.isNotEmpty) {
      _itemScrollController.scrollTo(
        index: _itemsWithSeparators.length - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Thanh jumpbar để nhảy nhanh đến ngày
            if (_messagesByDate.length > 3)
              _buildJumpScrollBar(),
            
            // Danh sách tin nhắn chính
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                child: ScrollablePositionedList.builder(
                  itemCount: _itemsWithSeparators.length,
                  itemBuilder: _buildListItem,
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  addAutomaticKeepAlives: true,
                  minCacheExtent: 30,
                  addRepaintBoundaries: true,
                ),
              ),
            ),
          ],
        ),
        
        // Loading indicator khi tải thêm tin nhắn
        if (widget.isLoadingMore)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black12,
              padding: const EdgeInsets.all(8.0),
              child: const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
              ),
            ),
          ),
        
        // Nút cuộn xuống
        if (_showScrollToBottom)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _scrollToBottom,
              child: const Icon(Icons.arrow_downward),
            ),
          ),
      ],
    );
  }
  
  /// Xây dựng thanh cuộn nhanh theo ngày
  Widget _buildJumpScrollBar() {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.calendar_today,
              size: 16,
              color: Theme.of(context).hintColor,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                // Tính toán vị trí tương đối
                final box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final scrollRatio = localPosition.dx / box.size.width;
                
                // Đặt vị trí cuộn theo tỷ lệ
                _jumpScrollController.jumpTo(
                  scrollRatio * _jumpScrollController.position.maxScrollExtent,
                );
              },
              child: SingleChildScrollView(
                controller: _jumpScrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: _messagesByDate.keys.map((dateStr) {
                    return Container(
                      width: 80,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Xây dựng item trong danh sách (tin nhắn hoặc separator)
  Widget _buildListItem(BuildContext context, int index) {
    final item = _itemsWithSeparators[index];
    
    // Hiển thị loading indicator ở đầu danh sách
    if (index == 0 && !widget.hasReachedEnd) {
      return Column(
        children: [
          // Chỉ hiển thị nếu không phải đang tải (vì đã có indicator riêng)
          if (!widget.isLoadingMore && !_isLoadingMore)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: TextButton(
                  onPressed: _loadMoreMessages,
                  child: const Text('Tải thêm tin nhắn cũ'),
                ),
              ),
            ),
          // Hiển thị item bình thường
          _buildActualItem(item),
        ],
      );
    }
    
    // Hiển thị indicator đã tải hết ở đầu danh sách
    if (index == 0 && widget.hasReachedEnd) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Không còn tin nhắn cũ hơn',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
          _buildActualItem(item),
        ],
      );
    }
    
    return _buildActualItem(item);
  }
  
  /// Xây dựng item thực tế (tin nhắn hoặc separator)
  Widget _buildActualItem(Object item) {
    // Hiển thị separator ngày
    if (item is DateSeparator) {
      return item;
    }
    
    // Hiển thị tin nhắn
    if (item is ChatMessage) {
      // Kiểm tra nếu cần highlight tin nhắn
      final bool isHighlighted = widget.initialScrollMessageId == item.id;
      
      return MessageItem(
        message: item,
        sender: item.sender,
        isCurrentUser: item.sender.id == widget.currentUserId,
        onTap: widget.onMessageTap != null ? () => widget.onMessageTap!(item) : null,
        onLongPress: widget.onMessageLongPress != null ? () => widget.onMessageLongPress!(item) : null,
        isHighlighted: isHighlighted,
      );
    }
    
    return const SizedBox.shrink();
  }
}

/// Controller làm mới danh sách
class RefreshController {
  final _refreshCompleter = Completer<void>();
  
  /// Hoàn thành làm mới
  void refreshCompleted() {
    if (!_refreshCompleter.isCompleted) {
      _refreshCompleter.complete();
    }
  }
  
  /// Đánh dấu làm mới thất bại
  void refreshFailed() {
    if (!_refreshCompleter.isCompleted) {
      _refreshCompleter.completeError('Refresh failed');
    }
  }
  
  /// Lấy future của quá trình làm mới
  Future<void> get future => _refreshCompleter.future;
}

/// Widget làm mới khi kéo xuống
class SmartRefresher extends StatefulWidget {
  /// Controller làm mới
  final RefreshController controller;
  
  /// Callback khi làm mới
  final Future<void> Function() onRefresh;
  
  /// Widget con
  final Widget child;
  
  /// Constructor
  const SmartRefresher({
    Key? key,
    required this.controller,
    required this.onRefresh,
    required this.child,
  }) : super(key: key);

  @override
  State<SmartRefresher> createState() => _SmartRefresherState();
}

class _SmartRefresherState extends State<SmartRefresher> {
  /// Đang làm mới
  bool _isRefreshing = false;
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: widget.child,
    );
  }
  
  /// Xử lý sự kiện làm mới
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      await widget.onRefresh();
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
} 