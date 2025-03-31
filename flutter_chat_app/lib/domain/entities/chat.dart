import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/entities/user.dart';

/// Chat type enum
enum ChatType {
  /// Direct chat between two users
  direct,
  
  /// Group chat with multiple users
  group
}

/// Chat entity that matches the GraphQL API structure
class Chat {
  /// Unique identifier
  final String id;
  
  /// Chat type (direct or group)
  final ChatType type;
  
  /// Chat name (null for direct chats)
  final String? name;
  
  /// Chat description (for group chats)
  final String? description;
  
  /// Group avatar (for group chats)
  final String? avatar;
  
  /// Last message in the chat
  final ChatMessage? lastMessage;
  
  /// Chat participants
  final List<User> participants;
  
  /// Owner of the chat (for group chats)
  final User? owner;
  
  /// Admin users (for group chats)
  final List<User> admins;
  
  /// Number of unread messages for current user
  final int unreadCount;
  
  /// Creation timestamp
  final DateTime createdAt;
  
  /// Last update timestamp
  final DateTime updatedAt;

  /// Constructor
  const Chat({
    required this.id,
    required this.type,
    this.name,
    this.description,
    this.avatar,
    this.lastMessage,
    required this.participants,
    this.owner,
    this.admins = const [],
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Chat &&
      other.id == id &&
      other.type == type &&
      other.name == name &&
      other.description == description &&
      other.avatar == avatar &&
      other.lastMessage == lastMessage &&
      _listEquals(other.participants, participants) &&
      other.owner == owner &&
      _listEquals(other.admins, admins) &&
      other.unreadCount == unreadCount &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  /// Helper to compare equality of two lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    
    return true;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      type.hashCode ^
      name.hashCode ^
      description.hashCode ^
      avatar.hashCode ^
      lastMessage.hashCode ^
      participants.hashCode ^
      owner.hashCode ^
      admins.hashCode ^
      unreadCount.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }

  /// Create a copy with modified values
  Chat copyWith({
    String? id,
    ChatType? type,
    String? name,
    String? description,
    String? avatar,
    ChatMessage? lastMessage,
    List<User>? participants,
    User? owner,
    List<User>? admins,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      participants: participants ?? this.participants,
      owner: owner ?? this.owner,
      admins: admins ?? this.admins,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create entity from JSON
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      type: _parseType(json['type'] as String),
      name: json['name'] as String?,
      description: json['description'] as String?,
      avatar: json['avatar'] as String?,
      lastMessage: json['lastMessage'] != null 
        ? ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
        : null,
      participants: (json['participants'] as List<dynamic>)
        .map((participant) => User.fromJson(participant as Map<String, dynamic>))
        .toList(),
      owner: json['owner'] != null 
        ? User.fromJson(json['owner'] as Map<String, dynamic>)
        : null,
      admins: json['admins'] != null
        ? (json['admins'] as List<dynamic>)
            .map((admin) => User.fromJson(admin as Map<String, dynamic>))
            .toList()
        : [],
      unreadCount: json['unreadCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert entity to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'name': name,
      'description': description,
      'avatar': avatar,
      'lastMessage': lastMessage?.toJson(),
      'participants': participants.map((participant) => participant.toJson()).toList(),
      'owner': owner?.toJson(),
      'admins': admins.map((admin) => admin.toJson()).toList(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Parse chat type from string
  static ChatType _parseType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'direct':
        return ChatType.direct;
      case 'group':
        return ChatType.group;
      default:
        return ChatType.direct;
    }
  }
}