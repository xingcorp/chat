import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Loại dữ liệu của tin nhắn
enum MessageDataType {
  /// Dữ liệu chuỗi 
  string,
  
  /// Dữ liệu JSON
  json,
  
  /// Dữ liệu nhị phân
  binary,
  
  /// Dữ liệu không xác định
  unknown
}

/// Mức độ ưu tiên của tin nhắn
enum MessagePriority {
  /// Tin nhắn ưu tiên cao (gửi ngay lập tức)
  high,
  
  /// Tin nhắn ưu tiên bình thường
  normal,
  
  /// Tin nhắn ưu tiên thấp (có thể trì hoãn)
  low
}

/// Class đại diện cho một tin nhắn realtime với tối ưu hiệu suất
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
  
  /// Mức độ ưu tiên
  final MessagePriority priority;
  
  /// Loại dữ liệu
  final MessageDataType dataType;
  
  /// Kích thước dữ liệu (bytes)
  final int? dataSize;
  
  /// Constructor tối ưu hóa
  RealtimeMessage({
    required this.type,
    this.data,
    Map<String, dynamic>? metadata,
    String? id,
    DateTime? timestamp,
    this.priority = MessagePriority.normal,
    MessageDataType? dataType,
  })  : id = id ?? _generateId(),
        timestamp = timestamp ?? DateTime.now(),
        receivedAt = DateTime.now(),
        metadata = metadata,
        dataType = dataType ?? _detectDataType(data),
        dataSize = _calculateDataSize(data);
  
  /// Tạo ID ngẫu nhiên với entropy cao
  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure().nextInt(1000000);
    final randomHex = Random.secure().nextInt(65536).toRadixString(16).padLeft(4, '0');
    return 'msg_${timestamp}_${random}_$randomHex';
  }
  
  /// Phát hiện loại dữ liệu
  static MessageDataType _detectDataType(dynamic data) {
    if (data == null) {
      return MessageDataType.unknown;
    } else if (data is String) {
      // Kiểm tra xem có phải JSON không
      try {
        json.decode(data);
        return MessageDataType.json;
      } catch (_) {
        return MessageDataType.string;
      }
    } else if (data is Map || data is List) {
      return MessageDataType.json;
    } else if (data is Uint8List || data is ByteData || data is ByteBuffer) {
      return MessageDataType.binary;
    }
    return MessageDataType.unknown;
  }
  
  /// Tính toán kích thước dữ liệu
  static int? _calculateDataSize(dynamic data) {
    if (data == null) {
      return 0;
    } else if (data is String) {
      return utf8.encode(data).length;
    } else if (data is Map || data is List) {
      return utf8.encode(json.encode(data)).length;
    } else if (data is Uint8List) {
      return data.lengthInBytes;
    } else if (data is ByteData) {
      return data.lengthInBytes;
    } else if (data is ByteBuffer) {
      return data.lengthInBytes;
    }
    return null;
  }
  
  /// Tạo từ JSON với xử lý lỗi tốt hơn
  factory RealtimeMessage.fromJson(Map<String, dynamic> json) {
    // Xử lý dữ liệu đặc biệt (nhị phân)
    dynamic parsedData = json['data'];
    MessageDataType? detectedType;
    
    // Phân tích dữ liệu đặc biệt
    if (json['data_type'] != null) {
      final dataTypeStr = json['data_type'].toString();
      if (dataTypeStr == 'binary' && json['data'] is String) {
        // Chuyển đổi từ base64 sang binary
        try {
          parsedData = base64Decode(json['data'] as String);
          detectedType = MessageDataType.binary;
        } catch (e) {
          // Nếu không giải mã được, giữ nguyên
        }
      }
    }
    
    // Phân tích priority
    MessagePriority parsedPriority = MessagePriority.normal;
    if (json['priority'] != null) {
      final priorityStr = json['priority'].toString().toLowerCase();
      if (priorityStr == 'high') {
        parsedPriority = MessagePriority.high;
      } else if (priorityStr == 'low') {
        parsedPriority = MessagePriority.low;
      }
    }
    
    return RealtimeMessage(
      type: json['type'] as String,
      data: parsedData,
      id: json['id'] as String? ?? _generateId(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : null,
      priority: parsedPriority,
      dataType: detectedType,
    );
  }
  
  /// Chuyển đổi thành JSON với hỗ trợ nhiều loại dữ liệu
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'type': type,
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
    
    // Xử lý dữ liệu theo loại
    if (data != null) {
      switch (dataType) {
        case MessageDataType.binary:
          if (data is Uint8List) {
            result['data'] = base64Encode(data);
            result['data_type'] = 'binary';
          } else if (data is ByteData) {
            result['data'] = base64Encode(Uint8List.view(data.buffer));
            result['data_type'] = 'binary';
          } else if (data is ByteBuffer) {
            result['data'] = base64Encode(Uint8List.view(data));
            result['data_type'] = 'binary';
          } else {
            result['data'] = data;
          }
          break;
        case MessageDataType.json:
          // Đảm bảo JSON là hợp lệ
          if (data is String) {
            try {
              result['data'] = json.decode(data);
            } catch (_) {
              result['data'] = data;
            }
          } else {
            result['data'] = data;
          }
          break;
        default:
          result['data'] = data;
      }
    }
    
    // Thêm metadata
    if (metadata != null && metadata!.isNotEmpty) {
      result['metadata'] = metadata;
    }
    
    // Thêm priority nếu không phải normal
    if (priority != MessagePriority.normal) {
      result['priority'] = priority.toString().split('.').last;
    }
    
    // Thêm thông tin kích thước nếu có
    if (dataSize != null && dataSize! > 1024) {
      result['data_size'] = dataSize;
    }
    
    return result;
  }
  
  /// Clone tin nhắn với các thay đổi
  RealtimeMessage copyWith({
    String? type,
    dynamic data,
    String? id,
    DateTime? timestamp,
    DateTime? receivedAt,
    Map<String, dynamic>? metadata,
    MessagePriority? priority,
    MessageDataType? dataType,
  }) {
    final newData = data ?? this.data;
    return RealtimeMessage(
      type: type ?? this.type,
      data: newData,
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      priority: priority ?? this.priority,
      dataType: dataType ?? _detectDataType(newData),
    );
  }
  
  /// Chuyển đổi dữ liệu thành chuỗi để hiển thị
  String get displayData {
    if (data == null) return 'null';
    
    switch (dataType) {
      case MessageDataType.binary:
        final sizeText = dataSize != null ? '(${_formatSize(dataSize!)})' : '';
        return '[Binary Data $sizeText]';
      case MessageDataType.json:
        if (data is Map || data is List) {
          try {
            return json.encode(data);
          } catch (e) {
            return data.toString();
          }
        }
        return data.toString();
      default:
        return data.toString();
    }
  }
  
  /// Format kích thước theo đơn vị phù hợp
  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  /// Kiểm tra xem tin nhắn có phải là loại nào không
  bool isType(String messageType) => type == messageType;
  
  /// Kiểm tra xem metadata có chứa key và value không
  bool hasMetadata(String key, [dynamic value]) {
    if (metadata == null) return false;
    if (!metadata!.containsKey(key)) return false;
    if (value != null) return metadata![key] == value;
    return true;
  }
  
  /// Kiểm tra xem tin nhắn có phải là ưu tiên cao không
  bool get isHighPriority => priority == MessagePriority.high;
  
  /// Thời gian trễ xử lý tin nhắn (ms)
  int get processingLatency => receivedAt.difference(timestamp).inMilliseconds;
  
  @override
  String toString() {
    return 'RealtimeMessage{type: $type, id: $id, priority: $priority, timestamp: $timestamp, size: ${dataSize ?? "unknown"}}';
  }
} 