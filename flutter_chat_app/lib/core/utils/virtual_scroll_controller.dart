import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
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
    for (final id in _allMessageIds) {
      if (_bufferZoneMessageIds.contains(id)) {
        return id;
      }
    }
    return null;
  }
  
  /// ID of the newest message in the buffer
  String? get newestBufferedMessageId {
    if (_bufferZoneMessageIds.isEmpty) return null;
    for (int i = _allMessageIds.length - 1; i >= 0; i--) {
      if (_bufferZoneMessageIds.contains(_allMessageIds[i])) {
        return _allMessageIds[i];
      }
    }
    return null;
  }
  
  /// Total number of messages (including those not in memory)
  int get totalMessageCount => _allMessageIds.length;
  
  /// Number of messages currently in memory
  int get bufferedMessageCount => _bufferZoneMessageIds.length;
  
  /// Whether we have more messages to load
  bool get hasMoreToLoad => !_hasReachedEnd;
  
  /// Currently visible messages (sorted newest to oldest)
  List<ChatMessage> get visibleMessages {
    final result = <ChatMessage>[];
    for (final id in _visibleMessageIds) {
      final message = _messageCache[id];
      if (message != null) {
        result.add(message);
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }
  
  /// All currently buffered messages (sorted newest to oldest)
  List<ChatMessage> get bufferedMessages {
    final result = <ChatMessage>[];
    for (final id in _bufferZoneMessageIds) {
      final message = _messageCache[id];
      if (message != null) {
        result.add(message);
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
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
    _performance.startTrace(TraceType.custom, customTraceName: 'virtual_scroll_init');
    
    // Clear existing data
    _messageCache.clear();
    _allMessageIds.clear();
    _bufferZoneMessageIds.clear();
    _visibleMessageIds.clear();
    
    // Sort newest to oldest for initialization
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
    
    _performance.stopTrace(TraceType.custom, customTraceName: 'virtual_scroll_init');
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
    _performance.startTrace(TraceType.loadMessages);
    
    try {
      final beforeId = _allMessageIds.isNotEmpty ? _allMessageIds.first : null;
      final messages = await onLoadMessages!(beforeId, bufferZoneSize);
      
      if (messages.isEmpty) {
        _hasReachedEnd = true;
      } else {
        // Add to cache
        for (final message in messages) {
          _messageCache[message.id] = message;
          
          // Add to IDs if new
          if (!_allMessageIds.contains(message.id)) {
            _allMessageIds.insert(0, message.id);
          }
        }
        
        // Update buffer zone
        _updateBufferZone();
      }
    } catch (e) {
      debugPrint('Error loading earlier messages: $e');
    } finally {
      _isLoadingEarlier = false;
      _performance.stopTrace(TraceType.loadMessages);
    }
  }
  
  /// Load newer messages
  Future<void> loadNewerMessages() async {
    if (_isLoadingEarlier || onLoadMessages == null) {
      return;
    }
    
    _isLoadingEarlier = true;
    _performance.startTrace(TraceType.loadMessages);
    
    try {
      final afterId = _allMessageIds.isNotEmpty ? _allMessageIds.last : null;
      // Implementation would need to be adjusted to support fetching newer messages
      // This is just a placeholder that would need server support
      final messages = await onLoadMessages!(null, bufferZoneSize);
      
      // Add to cache
      for (final message in messages) {
        _messageCache[message.id] = message;
        
        // Add to IDs if new
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
    } catch (e) {
      debugPrint('Error loading newer messages: $e');
    } finally {
      _isLoadingEarlier = false;
      _performance.stopTrace(TraceType.loadMessages);
    }
  }
  
  /// Handle scroll events to load more messages
  void _handleScroll() {
    if (!scrollController.hasClients) return;
    
    // If we're near the top and have more to load, load earlier messages
    if (scrollController.position.pixels < 500 && hasMoreToLoad && !_isLoadingEarlier) {
      // Use debounce to avoid multiple calls
      SchedulerBinding.instance.addPostFrameCallback((_) {
        loadEarlierMessages();
      });
    }
  }
  
  /// Update the buffer zone with messages around visible messages
  void _updateBufferZone() {
    if (_visibleMessageIds.isEmpty && _allMessageIds.isEmpty) return;
    
    // Get indices of visible messages
    final visibleIndices = <int>[];
    for (final id in _visibleMessageIds) {
      final index = _allMessageIds.indexOf(id);
      if (index >= 0) {
        visibleIndices.add(index);
      }
    }
    
    // If no visible messages, use the most recent ones
    if (visibleIndices.isEmpty) {
      final startIndex = math.max(0, _allMessageIds.length - 1 - bufferZoneSize);
      visibleIndices.add(startIndex);
    }
    
    // Calculate buffer zone boundaries
    final minVisibleIndex = visibleIndices.reduce(math.min);
    final maxVisibleIndex = visibleIndices.reduce(math.max);
    
    final startBufferIndex = math.max(0, minVisibleIndex - bufferZoneSize);
    final endBufferIndex = math.min(_allMessageIds.length - 1, maxVisibleIndex + bufferZoneSize);
    
    // Create a new buffer zone
    final newBufferZone = <String>{};
    for (int i = startBufferIndex; i <= endBufferIndex; i++) {
      newBufferZone.add(_allMessageIds[i]);
    }
    
    // Update buffer zone
    _bufferZoneMessageIds.clear();
    _bufferZoneMessageIds.addAll(newBufferZone);
    
    // Cleanup cache if we're over the limit
    _cleanupCache();
    
    // Notify listeners
    _notifyBufferUpdated();
  }
  
  /// Clean up memory by removing messages outside the buffer zone
  void _cleanupCache() {
    if (_messageCache.length <= maxMessageBuffer) return;
    
    // Only keep messages that are in the buffer zone
    final idsToRemove = <String>[];
    
    for (final id in _messageCache.keys) {
      if (!_bufferZoneMessageIds.contains(id)) {
        idsToRemove.add(id);
      }
      
      // Break if we've removed enough
      if (_messageCache.length - idsToRemove.length <= maxMessageBuffer) {
        break;
      }
    }
    
    // Remove from cache
    for (final id in idsToRemove) {
      _messageCache.remove(id);
    }
  }
  
  /// Notify listeners of buffer zone update
  void _notifyBufferUpdated() {
    if (!_bufferUpdateController.isClosed) {
      _bufferUpdateController.add(bufferedMessages);
    }
  }
  
  /// Dispose resources
  void dispose() {
    scrollController.removeListener(_handleScroll);
    _bufferUpdateController.close();
    
    // Consider not disposing the ScrollController here if it was passed in
    // by the user, but let them handle disposal
    if (!scrollController.hasClients) {
      scrollController.dispose();
    }
  }
} 