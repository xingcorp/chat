import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/entities/user.dart';

/// Entity đại diện cho một cuộc trò chuyện
class Chat {
  /// ID của chat
  final String id;
  
  /// Tên của chat
  final String? name;
  
  /// URL hình đại diện
  final String? avatarUrl;
  
  /// Thời gian tin nhắn cuối
  final DateTime? lastMessageTime;
  
  /// Nội dung tin nhắn cuối
  final String? lastMessagePreview;
  
  /// Số tin nhắn chưa đọc
  final int unreadCount;
  
  /// Loại chat
  final ChatType type;
  
  /// Danh sách ID thành viên
  final List<String> participantIds;
  
  /// Constructor
  const Chat({
    required this.id,
    this.name,
    this.avatarUrl,
    this.lastMessageTime,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.type = ChatType.direct,
    this.participantIds = const [],
  });
  
  /// Tạo bản sao với một số thuộc tính mới
  Chat copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    DateTime? lastMessageTime,
    String? lastMessagePreview,
    int? unreadCount,
    ChatType? type,
    List<String>? participantIds,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
    );
  }

  /// Create entity from JSON
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      lastMessageTime: json['lastMessageTime'] != null 
        ? DateTime.parse(json['lastMessageTime'] as String)
        : null,
      lastMessagePreview: json['lastMessagePreview'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      type: _parseType(json['type'] as String),
      participantIds: (json['participantIds'] as List<dynamic>)
        .map((id) => id as String)
        .toList(),
    );
  }

  /// Convert entity to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessagePreview': lastMessagePreview,
      'unreadCount': unreadCount,
      'type': type.toString().split('.').last,
      'participantIds': participantIds,
    };
  }

  /// Parse chat type from string
  static ChatType _parseType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'direct':
        return ChatType.direct;
      case 'group':
        return ChatType.group;
      case 'channel':
        return ChatType.channel;
      default:
        return ChatType.direct;
    }
  }
}

/// Loại chat
enum ChatType {
  /// Chat trực tiếp (1-1)
  direct,
  
  /// Nhóm chat
  group,
  
  /// Kênh chat
  channel,
}