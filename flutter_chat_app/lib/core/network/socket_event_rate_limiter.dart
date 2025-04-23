import 'dart:collection';

/// Manages rate limiting for socket events to prevent flooding
class SocketEventRateLimiter {
  /// Maximum number of events allowed in the time window
  final int _maxEvents;
  
  /// Time window in milliseconds for rate limiting
  final int _timeWindowMs;
  
  /// Map of event types to their timestamps
  final Map<String, Queue<DateTime>> _eventTimestamps = {};
  
  /// Events that are completely blocked (0 allowed in time window)
  final Set<String> _blockedEvents = {};
  
  /// Creates a rate limiter with specified max events and time window
  SocketEventRateLimiter({
    required int maxEvents,
    required int timeWindowMs,
  })  : _maxEvents = maxEvents,
        _timeWindowMs = timeWindowMs;
  
  /// Check if an event should be rate limited
  bool shouldLimit(String eventName) {
    // Check if event is completely blocked
    if (_blockedEvents.contains(eventName)) {
      return true;
    }
    
    // Clean old timestamps for this event
    _cleanOldTimestamps(eventName);
    
    // Get timestamps for this event, or create new queue if not exists
    final timestamps = _eventTimestamps[eventName] ?? Queue<DateTime>();
    
    // If we have reached max events in time window, limit it
    if (timestamps.length >= _maxEvents) {
      return true;
    }
    
    return false;
  }
  
  /// Record an event occurrence
  void recordEvent(String eventName) {
    // Initialize queue if not exists
    if (!_eventTimestamps.containsKey(eventName)) {
      _eventTimestamps[eventName] = Queue<DateTime>();
    }
    
    // Clean old timestamps
    _cleanOldTimestamps(eventName);
    
    // Add current timestamp
    _eventTimestamps[eventName]!.add(DateTime.now());
  }
  
  /// Try to record an event, but return false if it would be rate limited
  bool tryRecordEvent(String eventName) {
    if (shouldLimit(eventName)) {
      return false;
    }
    
    recordEvent(eventName);
    return true;
  }
  
  /// Completely block an event type (no occurrences allowed)
  void blockEvent(String eventName) {
    _blockedEvents.add(eventName);
  }
  
  /// Unblock a previously blocked event type
  void unblockEvent(String eventName) {
    _blockedEvents.remove(eventName);
  }
  
  /// Set a custom rate limit for a specific event
  void setCustomRateLimit(String eventName, int maxEvents, int timeWindowMs) {
    // Create custom rate limiter for this event
    final customLimiter = SocketEventRateLimiter(
      maxEvents: maxEvents,
      timeWindowMs: timeWindowMs,
    );
    
    // Clear existing timestamps for this event
    _eventTimestamps[eventName]?.clear();
  }
  
  /// Get current event count in the time window
  int getCurrentEventCount(String eventName) {
    _cleanOldTimestamps(eventName);
    return _eventTimestamps[eventName]?.length ?? 0;
  }
  
  /// Get remaining allowed events in the time window
  int getRemainingAllowedEvents(String eventName) {
    if (_blockedEvents.contains(eventName)) {
      return 0;
    }
    
    _cleanOldTimestamps(eventName);
    return _maxEvents - (_eventTimestamps[eventName]?.length ?? 0);
  }
  
  /// Get time until next event is allowed in milliseconds
  int getTimeUntilNext(String eventName) {
    if (!_eventTimestamps.containsKey(eventName) || 
        _eventTimestamps[eventName]!.isEmpty) {
      return 0;
    }
    
    _cleanOldTimestamps(eventName);
    
    // If not at limit, return 0
    if ((_eventTimestamps[eventName]?.length ?? 0) < _maxEvents) {
      return 0;
    }
    
    // Get oldest timestamp and calculate when it will exit the window
    final oldestTimestamp = _eventTimestamps[eventName]!.first;
    final windowEnd = oldestTimestamp.add(Duration(milliseconds: _timeWindowMs));
    final now = DateTime.now();
    
    // If window end is in the future, return remaining time
    if (windowEnd.isAfter(now)) {
      return windowEnd.difference(now).inMilliseconds;
    }
    
    return 0;
  }
  
  /// Reset all rate limiting data
  void reset() {
    _eventTimestamps.clear();
    _blockedEvents.clear();
  }
  
  /// Remove timestamps that are outside the time window
  void _cleanOldTimestamps(String eventName) {
    if (!_eventTimestamps.containsKey(eventName)) {
      return;
    }
    
    final timestamps = _eventTimestamps[eventName]!;
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(milliseconds: _timeWindowMs));
    
    // Remove timestamps older than cutoff
    while (timestamps.isNotEmpty && timestamps.first.isBefore(cutoff)) {
      timestamps.removeFirst();
    }
  }
  
  /// Get all rate-limited events in the last time window
  Set<String> getLimitedEvents() {
    final limitedEvents = <String>{};
    
    // Check each event
    for (final entry in _eventTimestamps.entries) {
      final eventName = entry.key;
      final timestamps = entry.value;
      
      _cleanOldTimestamps(eventName);
      
      // If event is at or over limit, add to limited events
      if (timestamps.length >= _maxEvents) {
        limitedEvents.add(eventName);
      }
    }
    
    // Add all blocked events
    limitedEvents.addAll(_blockedEvents);
    
    return limitedEvents;
  }
} 