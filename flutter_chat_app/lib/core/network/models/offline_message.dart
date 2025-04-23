import 'dart:convert';

/// Represents a message that was sent while offline and needs to be delivered
/// when the connection is restored
class OfflineMessage {
  /// Unique identifier for this offline message
  final String id;
  
  /// The event name/type of the message
  final String event;
  
  /// The payload data for the message
  final Map<String, dynamic> data;
  
  /// The timestamp when this message was created
  final DateTime timestamp;
  
  /// Whether this message requires an acknowledgment
  final bool requiresAck;
  
  /// The number of times we've attempted to send this message
  int retryCount;
  
  /// Creates a new offline message
  OfflineMessage({
    required this.id,
    required this.event,
    required this.data,
    required this.timestamp,
    this.requiresAck = true,
    this.retryCount = 0,
  });
  
  /// Creates an offline message from JSON
  factory OfflineMessage.fromJson(Map<String, dynamic> json) {
    return OfflineMessage(
      id: json['id'] as String,
      event: json['event'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      requiresAck: json['requiresAck'] as bool? ?? true,
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
  
  /// Converts this offline message to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': event,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'requiresAck': requiresAck,
      'retryCount': retryCount,
    };
  }
  
  /// Serializes this offline message to a string
  String serialize() {
    return jsonEncode(toJson());
  }
  
  /// Deserializes an offline message from a string
  static OfflineMessage deserialize(String data) {
    return OfflineMessage.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }
  
  /// Increments the retry count
  void incrementRetry() {
    retryCount++;
  }
  
  @override
  String toString() {
    return 'OfflineMessage(id: $id, event: $event, retryCount: $retryCount)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineMessage && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
} 