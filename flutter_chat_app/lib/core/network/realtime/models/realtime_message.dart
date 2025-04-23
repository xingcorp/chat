import 'package:meta/meta.dart';

/// Class đại diện cho một tin nhắn realtime
@immutable
class RealtimeMessage {
  /// ID tin nhắn
  final String id;
  
  /// Loại tin nhắn
  final String type;
  
  /// Dữ liệu tin nhắn
  final dynamic data;
  
  /// Metadata bổ sung
  final Map<String, dynamic> metadata;
  
  /// Thời gian gửi
  final DateTime timestamp;
  
  /// Constructor
  RealtimeMessage({
    required this.id,
    required this.type,
    required this.data,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Tạo RealtimeMessage từ Map
  factory RealtimeMessage.fromJson(Map<String, dynamic> json) {
    return RealtimeMessage(
      id: json['id'] as String,
      type: json['type'] as String,
      data: json['data'],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : json['timestamp'] is String
              ? DateTime.parse(json['timestamp'] as String)
              : DateTime.now(),
    );
  }
  
  /// Chuyển đổi thành Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'metadata': metadata,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
  
  @override
  String toString() {
    return 'RealtimeMessage{id: $id, type: $type, timestamp: $timestamp}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RealtimeMessage) return false;
    return id == other.id && 
           type == other.type &&
           timestamp == other.timestamp;
  }
  
  @override
  int get hashCode => Object.hash(id, type, timestamp);
} 