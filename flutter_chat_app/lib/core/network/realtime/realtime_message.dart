import 'dart:math';

/// Class đại diện cho một tin nhắn realtime
class RealtimeMessage {
  /// Loại tin nhắn
  final String type;
  
  /// Dữ liệu tin nhắn
  final dynamic data;
  
  /// ID tin nhắn
  final String id;
  
  /// Thời gian tạo tin nhắn
  final DateTime timestamp;
  
  /// Thời gian nhận tin nhắn
  final DateTime receivedAt;
  
  /// Metadata bổ sung
  final Map<String, dynamic>? metadata;
  
  /// Constructor
  RealtimeMessage({
    required this.type,
    this.data,
    Map<String, dynamic>? metadata,
    String? id,
    DateTime? timestamp,
  })  : id = id ?? 'msg_${DateTime.now().millisecondsSinceEpoch}_${(10000 * Random().nextDouble()).floor()}',
        timestamp = timestamp ?? DateTime.now(),
        receivedAt = DateTime.now(),
        metadata = metadata;
  
  /// Tạo từ JSON
  factory RealtimeMessage.fromJson(Map<String, dynamic> json) {
    return RealtimeMessage(
      type: json['type'] as String,
      data: json['data'],
      id: json['id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : null,
    );
  }
  
  /// Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (metadata != null) 'metadata': metadata,
    };
  }
  
  /// Clone tin nhắn với các thay đổi
  RealtimeMessage copyWith({
    String? type,
    dynamic data,
    String? id,
    DateTime? timestamp,
    DateTime? receivedAt,
    Map<String, dynamic>? metadata,
  }) {
    return RealtimeMessage(
      type: type ?? this.type,
      data: data ?? this.data,
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
  
  @override
  String toString() {
    return 'RealtimeMessage{type: $type, id: $id, timestamp: $timestamp}';
  }
} 