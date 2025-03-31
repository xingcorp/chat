/// User entity that matches the GraphQL API structure
class User {
  /// Unique identifier
  final String id;
  
  /// User's username
  final String username;
  
  /// User's email
  final String email;
  
  /// User's full name
  final String? fullName;
  
  /// User's avatar URL
  final String? avatar;
  
  /// Online status
  final bool isOnline;
  
  /// Last seen timestamp
  final DateTime? lastSeen;

  /// User constructor
  const User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is User &&
      other.id == id &&
      other.username == username &&
      other.email == email &&
      other.fullName == fullName &&
      other.avatar == avatar &&
      other.isOnline == isOnline &&
      other.lastSeen == lastSeen;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      username.hashCode ^
      email.hashCode ^
      fullName.hashCode ^
      avatar.hashCode ^
      isOnline.hashCode ^
      lastSeen.hashCode;
  }

  /// Create a copy with modified values
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? avatar,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  /// Create entity from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      avatar: json['avatar'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
    );
  }

  /// Convert entity to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'avatar': avatar,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
} 