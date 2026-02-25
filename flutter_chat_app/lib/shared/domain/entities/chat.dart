/// Entity đại diện cho một cuộc trò chuyện
class Chat {
  /// ID của chat
  final String id;
  
  /// Tên của chat
  final String? name;
  
  /// URL hình đại diện
  final String? avatarUrl;
  
  /// Mô tả của chat (cho group)
  final String? description;
  
  /// Loại group (Public/Private) - chỉ áp dụng cho group chat
  final GroupType? groupType;
  
  /// Thông tin người tạo group
  final String? creatorId;

  /// Tên người tạo group (từ creator.fullname)
  final String? creatorName;

  /// Thời gian tạo group
  final DateTime? createdAt;

  /// Danh sách thành viên với thông tin chi tiết
  final List<ConversationMember> members;
  
  /// Thời gian tin nhắn cuối
  final DateTime? lastMessageTime;
  
  /// Nội dung tin nhắn cuối
  final String? lastMessagePreview;
  
  /// Số tin nhắn chưa đọc
  final int unreadCount;
  
  /// Loại chat
  final ChatType type;
  
  /// Danh sách ID thành viên (backward compatibility)
  final List<String> participantIds;

  /// Danh sách ID người dùng đang typing
  final List<String> typingUserIds;

  /// Trạng thái muted của chat
  final bool isMuted;

  /// Constructor
  const Chat({
    required this.id,
    this.name,
    this.avatarUrl,
    this.description,
    this.groupType,
    this.creatorId,
    this.creatorName,
    this.createdAt,
    this.members = const [],
    this.lastMessageTime,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.type = ChatType.direct,
    this.participantIds = const [],
    this.typingUserIds = const [],
    this.isMuted = false,
  });
  
  /// Tạo bản sao với một số thuộc tính mới
  Chat copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? description,
    GroupType? groupType,
    String? creatorId,
    String? creatorName,
    DateTime? createdAt,
    List<ConversationMember>? members,
    DateTime? lastMessageTime,
    String? lastMessagePreview,
    int? unreadCount,
    ChatType? type,
    List<String>? participantIds,
    List<String>? typingUserIds,
    bool? isMuted,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      description: description ?? this.description,
      groupType: groupType ?? this.groupType,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      typingUserIds: typingUserIds ?? this.typingUserIds,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  /// Create entity from JSON
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['imgUrl'] as String?,
      description: json['description'] as String?,
      groupType: json['groupType'] != null
        ? _parseGroupType(json['groupType'] as String)
        : null,
      creatorId: json['creatorId'] as String? ?? json['creator']?['id'] as String?,
      creatorName: json['creatorName'] as String? ?? json['creator']?['fullname'] as String?,
      createdAt: json['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch((json['createdAt'] as num).toInt())
        : null,
      members: (json['members'] as List<dynamic>?)
        ?.map((m) => ConversationMember.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
      lastMessageTime: json['lastMessageTime'] != null
        ? DateTime.parse(json['lastMessageTime'] as String)
        : json['lastMessageAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['lastMessageAt'] as num).toInt())
          : null,
      lastMessagePreview: json['lastMessagePreview'] as String? ?? json['lastMessage'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      type: _parseType(json['type'] as String),
      participantIds: (json['participantIds'] as List<dynamic>?)
        ?.map((id) => id as String)
        .toList() ?? [],
      typingUserIds: (json['typingUserIds'] as List<dynamic>?)
        ?.map((id) => id as String)
        .toList() ?? [],
      isMuted: json['isMuted'] as bool? ?? false,
    );
  }

  /// Convert entity to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'imgUrl': avatarUrl,
      'description': description,
      'groupType': groupType?.toString().split('.').last,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'members': members.map((m) => m.toJson()).toList(),
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageAt': lastMessageTime?.millisecondsSinceEpoch,
      'lastMessagePreview': lastMessagePreview,
      'lastMessage': lastMessagePreview,
      'unreadCount': unreadCount,
      'type': type.toString().split('.').last,
      'participantIds': participantIds,
      'typingUserIds': typingUserIds,
      'isMuted': isMuted,
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
  
  /// Parse group type from string
  static GroupType _parseGroupType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'public':
        return GroupType.public;
      case 'private':
        return GroupType.private;
      default:
        return GroupType.private;
    }
  }
  
  // ============================================================================
  // BACKWARD COMPATIBILITY GETTERS
  // ============================================================================
  
  /// Alias for avatarUrl (backward compatibility with UI)
  String? get imgUrl => avatarUrl;
  
  /// Alias for lastMessagePreview (backward compatibility with UI)
  String? get lastMessage => lastMessagePreview;
  
  /// Alias for lastMessageTime (backward compatibility with UI)
  DateTime? get lastMessageAt => lastMessageTime;

  /// Kiểm tra có ai đó đang typing không
  bool get isTyping => typingUserIds.isNotEmpty;
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

/// Loại group chat
enum GroupType {
  /// Group công khai
  public,
  
  /// Group riêng tư
  private,
}

/// Thông tin thành viên trong conversation
class ConversationMember {
  /// ID của member record
  final String id;
  
  /// ID của user
  final String userId;
  
  /// Tên đầy đủ của user (displayName)
  final String? fullName;
  
  /// Avatar URL của user
  final String? avatarUrl;
  
  /// Tên phòng ban
  final String? departmentName;
  
  /// Chức vụ
  final String? titleName;
  
  /// Mã nhân viên
  final String? code;
  
  /// Có phải admin không
  final bool isAdmin;
  
  /// Đã kết nối chưa
  final bool isConnected;
  
  /// Đã ẩn conversation chưa
  final bool isHidden;
  
  /// Số tin nhắn chưa đọc
  final int unreadCount;
  
  /// ID tin nhắn cuối cùng đã đọc
  final String? lastMessageReadId;
  
  /// Thời gian bắt đầu xem tin nhắn
  final DateTime? viewMessagesFrom;
  
  /// Constructor
  const ConversationMember({
    required this.id,
    required this.userId,
    this.fullName,
    this.avatarUrl,
    this.departmentName,
    this.titleName,
    this.code,
    this.isAdmin = false,
    this.isConnected = false,
    this.isHidden = false,
    this.unreadCount = 0,
    this.lastMessageReadId,
    this.viewMessagesFrom,
  });
  
  /// Getter for displayName (alias for fullName)
  String? get displayName => fullName;
  
  /// Getter for imageUrls (alias for avatarUrl as list)
  List<String>? get imageUrls => avatarUrl != null ? [avatarUrl!] : null;
  
  /// Create from JSON
  factory ConversationMember.fromJson(Map<String, dynamic> json) {
    // Extract user info from nested user object or flat structure
    final user = json['user'] as Map<String, dynamic>?;
    
    return ConversationMember(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? user?['id'] as String? ?? '',
      fullName: json['fullName'] as String? 
          ?? json['displayName'] as String? 
          ?? user?['fullname'] as String?,
      avatarUrl: json['avatarUrl'] as String? 
          ?? (user?['imageUrls'] as List<dynamic>?)?.firstOrNull as String?,
      departmentName: json['departmentName'] as String? ?? user?['departmentName'] as String?,
      titleName: json['titleName'] as String? ?? user?['titleName'] as String?,
      code: json['code'] as String? ?? user?['code'] as String?,
      isAdmin: json['admin'] as bool? ?? json['isAdmin'] as bool? ?? false,
      isConnected: json['connected'] as bool? ?? json['isConnected'] as bool? ?? false,
      isHidden: json['hide'] as bool? ?? json['isHidden'] as bool? ?? false,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessageReadId: json['lastMessageReadId'] as String?,
      viewMessagesFrom: json['viewMessagesFrom'] != null
        ? DateTime.parse(json['viewMessagesFrom'] as String)
        : json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : null,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'displayName': fullName,
      'avatarUrl': avatarUrl,
      'departmentName': departmentName,
      'titleName': titleName,
      'code': code,
      'admin': isAdmin,
      'isAdmin': isAdmin,
      'connected': isConnected,
      'isConnected': isConnected,
      'hide': isHidden,
      'isHidden': isHidden,
      'unreadCount': unreadCount,
      'lastMessageReadId': lastMessageReadId,
      'viewMessagesFrom': viewMessagesFrom?.toIso8601String(),
      'joinedAt': viewMessagesFrom?.toIso8601String(),
    };
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ConversationMember &&
      other.id == id &&
      other.userId == userId &&
      other.fullName == fullName &&
      other.avatarUrl == avatarUrl &&
      other.departmentName == departmentName &&
      other.titleName == titleName &&
      other.code == code &&
      other.isAdmin == isAdmin &&
      other.isConnected == isConnected &&
      other.isHidden == isHidden &&
      other.unreadCount == unreadCount &&
      other.lastMessageReadId == lastMessageReadId &&
      other.viewMessagesFrom == viewMessagesFrom;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
      userId.hashCode ^
      (fullName?.hashCode ?? 0) ^
      (avatarUrl?.hashCode ?? 0) ^
      (departmentName?.hashCode ?? 0) ^
      (titleName?.hashCode ?? 0) ^
      (code?.hashCode ?? 0) ^
      isAdmin.hashCode ^
      isConnected.hashCode ^
      isHidden.hashCode ^
      unreadCount.hashCode ^
      (lastMessageReadId?.hashCode ?? 0) ^
      (viewMessagesFrom?.hashCode ?? 0);
  }
}