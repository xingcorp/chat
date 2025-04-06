import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:get_it/get_it.dart';

/// A controller for efficiently managing large lists of messages
/// using virtualization techniques to minimize memory usage and improve performance.
class VirtualScrollController {
  /// Maximum number of messages to keep in memory
  final int maxMessageBuffer;
  
  /// Number of messages to keep in memory above and below the viewport
  final int bufferZoneSize;
  
  /// Callback when messages need to be loaded
  final Future<List<ChatMessage>> Function(String? beforeId, int limit)? onLoadMessages;
  
  /// Underlying scroll controller
  final ScrollController scrollController;
  
  /// Performance monitoring
  final PerformanceMonitor _performance = GetIt.I<PerformanceMonitor>();
  
  /// All message IDs in the list, sorted from oldest to newest
  final List<String> _allMessageIds = [];
  
  /// Cache of loaded messages
  final Map<String, ChatMessage> _messageCache = {};
  
  /// Currently visible message IDs
  final Set<String> _visibleMessageIds = {};
  
  /// Message IDs currently in the buffer zone
  final Set<String> _bufferZoneMessageIds = {};
  
  /// Whether we're currently fetching earlier messages
  bool _isLoadingEarlier = false;
  
  /// Whether all earlier messages have been loaded
  bool _hasReachedEnd = false;
  
  /// Stream controller for buffer updates
  final _bufferUpdateController = StreamController<List<ChatMessage>>.broadcast();
  
  /// Stream of buffer updates
  Stream<List<ChatMessage>> get bufferUpdates => _bufferUpdateController.stream;
  
  /// ID of the oldest message in the buffer
  String? get oldestBufferedMessageId {
    if (_bufferZoneMessageIds.isEmpty) return null;
    return _allMessageIds.firstWhere(
      (id) => _bufferZoneMessageIds.contains(id), 
      orElse: () => '',
    );
  }
  
  /// ID of the newest message in the buffer
  String? get newestBufferedMessageId {
    if (_bufferZoneMessageIds.isEmpty) return null;
    return _allMessageIds.lastWhere(
      (id) => _bufferZoneMessageIds.contains(id), 
      orElse: () => '',
    );
  }
  
  /// Total number of messages (including those not in memory)
  int get totalMessageCount => _allMessageIds.length;
  
  /// Number of messages currently in memory
  int get bufferedMessageCount => _bufferZoneMessageIds.length;
  
  /// Whether we have more messages to load
  bool get hasMoreToLoad => !_hasReachedEnd;
  
  /// Currently visible messages (sorted newest to oldest)
  List<ChatMessage> get visibleMessages {
    return _visibleMessageIds
        .map((id) => _messageCache[id])
        .whereType<ChatMessage>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  /// All currently buffered messages (sorted newest to oldest)
  List<ChatMessage> get bufferedMessages {
    return _bufferZoneMessageIds
        .map((id) => _messageCache[id])
        .whereType<ChatMessage>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  VirtualScrollController({
    this.maxMessageBuffer = 100,
    this.bufferZoneSize = 30,
    this.onLoadMessages,
    ScrollController? scrollController,
  }) : scrollController = scrollController ?? ScrollController() {
    this.scrollController.addListener(_handleScroll);
  }
  
  /// Initialize with a list of messages
  void initialize(List<ChatMessage> initialMessages) {
    _performance.startTrace('virtual_scroll_init');
    
    // Sort newest to oldest
    initialMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Add to cache and IDs list
    for (final message in initialMessages) {
      _messageCache[message.id] = message;
      _allMessageIds.add(message.id);
    }
    
    // Sort IDs from oldest to newest (for easier navigation)
    _allMessageIds.sort((a, b) {
      final msgA = _messageCache[a];
      final msgB = _messageCache[b];
      if (msgA == null || msgB == null) return 0;
      return msgA.createdAt.compareTo(msgB.createdAt);
    });
    
    // Initialize buffer zone
    _updateBufferZone();
    
    _performance.stopTrace('virtual_scroll_init');
  }
  
  /// Update which messages are visible
  void updateVisibleMessages(List<String> visibleIds) {
    _visibleMessageIds.clear();
    _visibleMessageIds.addAll(visibleIds);
    
    // Ensure all visible messages are in the buffer zone
    bool allInBuffer = visibleIds.every((id) => _bufferZoneMessageIds.contains(id));
    if (!allInBuffer) {
      _updateBufferZone();
    }
  }
  
  /// Add a new message to the list
  void addMessage(ChatMessage message) {
    // Add to cache
    _messageCache[message.id] = message;
    
    // Add to ID list if not already there
    if (!_allMessageIds.contains(message.id)) {
      _allMessageIds.add(message.id);
      
      // Resort IDs
      _allMessageIds.sort((a, b) {
        final msgA = _messageCache[a];
        final msgB = _messageCache[b];
        if (msgA == null || msgB == null) return 0;
        return msgA.createdAt.compareTo(msgB.createdAt);
      });
    }
    
    // Update buffer zone
    _updateBufferZone();
  }
  
  /// Update an existing message
  void updateMessage(ChatMessage message) {
    if (_messageCache.containsKey(message.id)) {
      _messageCache[message.id] = message;
      
      // Notify listeners if the message is in the buffer zone
      if (_bufferZoneMessageIds.contains(message.id)) {
        _notifyBufferUpdated();
      }
    }
  }
  
  /// Delete a message
  void deleteMessage(String messageId) {
    _messageCache.remove(messageId);
    _allMessageIds.remove(messageId);
    _visibleMessageIds.remove(messageId);
    _bufferZoneMessageIds.remove(messageId);
    _notifyBufferUpdated();
  }
  
  /// Load earlier messages
  Future<void> loadEarlierMessages() async {
    if (_isLoadingEarlier || _hasReachedEnd || onLoadMessages == null) {
      return;
    }
    
    _isLoadingEarlier = true;
    _performance.startTrace('load_earlier_messages');
    
    try {
      final beforeId = _allMessageIds.isNotEmpty ? _allMessageIds.first : null;
      final messages = await onLoadMessages!(beforeId, bufferZoneSize);
      
      // If no messages returned, we've reached the end
      if (messages.isEmpty) {
        _hasReachedEnd = true;
        return;
      }
      
      // Add messages to cache and ID list
      for (final message in messages) {
        _messageCache[message.id] = message;
        if (!_allMessageIds.contains(message.id)) {
          _allMessageIds.add(message.id);
        }
      }
      
      // Resort IDs
      _allMessageIds.sort((a, b) {
        final msgA = _messageCache[a];
        final msgB = _messageCache[b];
        if (msgA == null || msgB == null) return 0;
        return msgA.createdAt.compareTo(msgB.createdAt);
      });
      
      // Update buffer zone
      _updateBufferZone();
    } finally {
      _isLoadingEarlier = false;
      _performance.stopTrace('load_earlier_messages');
    }
  }
  
  /// Scroll to a specific message by ID
  Future<bool> scrollToMessage(String messageId, {bool animated = true}) async {
    // Check if we have this message ID
    final index = _allMessageIds.indexOf(messageId);
    if (index == -1) return false;
    
    // Make sure the message is in the buffer zone
    if (!_bufferZoneMessageIds.contains(messageId)) {
      // TODO: Implement smarter scrolling for messages far outside buffer
      return false;
    }
    
    // Find the index in the visible list
    final visibleIndex = bufferedMessages.indexWhere((m) => m.id == messageId);
    if (visibleIndex == -1) return false;
    
    // Calculate position to scroll to
    final itemHeight = 60.0; // Estimated height, could be improved
    final position = visibleIndex * itemHeight;
    
    // Scroll to the position
    if (animated) {
      await scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      scrollController.jumpTo(position);
    }
    
    return true;
  }
  
  /// Handle scroll events
  void _handleScroll() {
    // Check if we need to load more messages
    if (scrollController.position.pixels <= scrollController.position.minScrollExtent + 200) {
      if (!_isLoadingEarlier && !_hasReachedEnd) {
        loadEarlierMessages();
      }
    }
    
    // Schedule a check of the buffer zone
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_isLoadingEarlier) {
        _updateBufferZone();
      }
    });
  }
  
  /// Update which messages are in the buffer zone
  void _updateBufferZone() {
    // Always keep the visible messages in the buffer
    final Set<String> newBufferZone = Set.from(_visibleMessageIds);
    
    // Get the first and last visible message indices
    int? firstVisibleIndex;
    int? lastVisibleIndex;
    
    if (_visibleMessageIds.isNotEmpty) {
      // Find the min and max indices of visible messages
      for (final id in _visibleMessageIds) {
        final index = _allMessageIds.indexOf(id);
        if (index != -1) {
          firstVisibleIndex = firstVisibleIndex == null ? index : math.min(firstVisibleIndex, index);
          lastVisibleIndex = lastVisibleIndex == null ? index : math.max(lastVisibleIndex, index);
        }
      }
    } else {
      // Default to the newest messages if nothing is visible
      lastVisibleIndex = _allMessageIds.length - 1;
      firstVisibleIndex = math.max(0, lastVisibleIndex - bufferZoneSize);
    }
    
    // If we have valid indices, add buffer around them
    if (firstVisibleIndex != null && lastVisibleIndex != null) {
      // Calculate buffer zone boundaries
      final startIndex = math.max(0, firstVisibleIndex - bufferZoneSize);
      final endIndex = math.min(_allMessageIds.length - 1, lastVisibleIndex + bufferZoneSize);
      
      // Add messages in buffer zone to the set
      for (int i = startIndex; i <= endIndex; i++) {
        final id = _allMessageIds[i];
        if (_messageCache.containsKey(id)) {
          newBufferZone.add(id);
        }
      }
    }
    
    // Cap to max buffer size if needed
    if (newBufferZone.length > maxMessageBuffer) {
      // Get sorted list of IDs by recency
      final List<String> sortedIds = newBufferZone.toList()
        ..sort((a, b) {
          final msgA = _messageCache[a];
          final msgB = _messageCache[b];
          if (msgA == null || msgB == null) return 0;
          
          // Sort newer messages first
          return msgB.createdAt.compareTo(msgA.createdAt);
        });
      
      // Keep visible messages and up to maxBuffer - visibleCount other messages
      final keptIds = <String>{};
      
      // Always keep visible messages
      keptIds.addAll(_visibleMessageIds);
      
      // Fill remaining buffer with most recent messages
      int remaining = maxMessageBuffer - keptIds.length;
      
      for (final id in sortedIds) {
        if (remaining <= 0) break;
        if (!keptIds.contains(id)) {
          keptIds.add(id);
          remaining--;
        }
      }
      
      newBufferZone = keptIds;
    }
    
    // Check if buffer zone has changed
    final hasChanged = !setEquals(_bufferZoneMessageIds, newBufferZone);
    
    if (hasChanged) {
      // Find messages to evict from cache
      final toEvict = <String>{};
      for (final id in _bufferZoneMessageIds) {
        if (!newBufferZone.contains(id)) {
          toEvict.add(id);
        }
      }
      
      // Update buffer zone
      _bufferZoneMessageIds.clear();
      _bufferZoneMessageIds.addAll(newBufferZone);
      
      // Notify listeners of buffer update
      _notifyBufferUpdated();
    }
  }
  
  /// Notify listeners that the buffer has been updated
  void _notifyBufferUpdated() {
    _bufferUpdateController.add(bufferedMessages);
  }
  
  /// Dispose the controller
  void dispose() {
    scrollController.removeListener(_handleScroll);
    _bufferUpdateController.close();
  }
}

/// Helper function to check if two Sets are equal
bool setEquals<T>(Set<T>? a, Set<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  return a.containsAll(b);
} 