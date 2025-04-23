import 'dart:convert';

/// Class lưu trữ tin nhắn để gửi khi offline
class OfflineMessage {
  /// ID duy nhất của tin nhắn
  final String id;
  
  /// Loại sự kiện
  final String event;
  
  /// Dữ liệu sự kiện
  final dynamic data;
  
  /// Thời gian tạo
  final DateTime timestamp;
  
  /// Số lần thử gửi lại
  int retryCount = 0;
  
  /// Constructor
  OfflineMessage({
    required this.event,
    required this.data,
    required this.timestamp,
    String? id,
  }) : id = id ?? '${DateTime.now().millisecondsSinceEpoch}_${event.hashCode}';
  
  /// Sao chép với dữ liệu mới
  OfflineMessage copyWith({
    String? event,
    dynamic data,
    DateTime? timestamp,
    int? retryCount,
  }) {
    final result = OfflineMessage(
      event: event ?? this.event,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      id: id,
    );
    
    result.retryCount = retryCount ?? this.retryCount;
    return result;
  }
  
  /// Chuyển đổi sang Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': event,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }
  
  /// Tạo từ Map
  factory OfflineMessage.fromJson(Map<String, dynamic> json) {
    final result = OfflineMessage(
      event: json['event'] as String,
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      id: json['id'] as String,
    );
    
    result.retryCount = json['retryCount'] as int? ?? 0;
    return result;
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
  String toString() => 'OfflineMessage(event: $event, retryCount: $retryCount)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineMessage && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
} 