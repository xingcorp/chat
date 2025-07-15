import 'package:flutter_chat_app/domain/entities/user.dart';
import 'package:isar/isar.dart';

part 'user_model.g.dart';

/// Model class representing a user in the system
@collection
class UserModel {
  /// User's unique identifier in the database
  @Id()
  final int id;

  /// Server ID of the user
  @Index(unique: true)
  final String serverId;

  /// User's username
  @Index()
  final String username;

  /// User's display name
  final String displayName;

  /// URL to the user's avatar image
  final String? avatarUrl;

  /// User's email address
  final String? email;

  /// Indicates if the user is currently online
  final bool isOnline;

  /// Timestamp of the user's last activity
  final DateTime lastSeen;

  /// User's current status message
  final String? statusMessage;

  /// List of roles assigned to the user
  final List<String> roles;

  /// Default constructor
  UserModel({
    this.id = 0,
    required this.serverId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.email,
    this.isOnline = false,
    required this.lastSeen,
    this.statusMessage,
    this.roles = const [],
  });

  /// Create a user from a map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      serverId: map['id'] as String,
      username: map['username'] as String,
      displayName: map['displayName'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      email: map['email'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: DateTime.parse(map['lastSeen'] as String),
      statusMessage: map['statusMessage'] as String?,
      roles: List<String>.from(map['roles'] ?? []),
    );
  }

  /// Create a user from JSON (alias for fromMap for API compatibility)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json);
  }

  /// Convert user to a map
  Map<String, dynamic> toMap() {
    return {
      'id': serverId,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'email': email,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'statusMessage': statusMessage,
      'roles': roles,
    };
  }

  /// Create a copy of this user with changed fields
  UserModel copyWith({
    int? id,
    String? serverId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? email,
    bool? isOnline,
    DateTime? lastSeen,
    String? statusMessage,
    List<String>? roles,
  }) {
    return UserModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      statusMessage: statusMessage ?? this.statusMessage,
      roles: roles ?? this.roles,
    );
  }

  /// Update user's online status
  UserModel updateOnlineStatus(bool status, [DateTime? seen]) {
    return copyWith(
      isOnline: status,
      lastSeen: seen ?? (status ? null : DateTime.now()),
    );
  }

  /// Update user's status message
  UserModel updateStatusMessage(String? message) {
    return copyWith(
      statusMessage: message,
    );
  }

  /// Create a new user
  static UserModel createUser({
    required int id,
    required String serverId,
    required String username,
    required String displayName,
    String? avatarUrl,
    String? email,
    String? statusMessage,
    List<String> roles = const ['user'],
  }) {
    return UserModel(
      id: id,
      serverId: serverId,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      email: email,
      isOnline: true,
      lastSeen: DateTime.now(),
      statusMessage: statusMessage,
      roles: roles,
    );
  }

  /// Update user profile
  UserModel updateProfile({
    String? displayName,
    String? avatarUrl,
    String? email,
    String? statusMessage,
  }) {
    return copyWith(
      displayName: displayName,
      avatarUrl: avatarUrl,
      email: email,
      statusMessage: statusMessage,
    );
  }

  /// Add a role to the user
  UserModel addRole(String role) {
    if (roles.contains(role)) return this;
    
    final newRoles = List<String>.from(roles);
    newRoles.add(role);
    
    return copyWith(
      roles: newRoles,
    );
  }

  /// Remove a role from the user
  UserModel removeRole(String role) {
    if (!roles.contains(role)) return this;
    
    final newRoles = List<String>.from(roles);
    newRoles.remove(role);
    
    return copyWith(
      roles: newRoles,
    );
  }

  /// Check if user has a specific role
  bool hasRole(String role) {
    return roles.contains(role);
  }

  /// Check if user is an admin
  bool get isAdmin => hasRole('admin');

  /// Check if user is a moderator
  bool get isModerator => hasRole('moderator') || isAdmin;

  /// Get the full name or username if display name is empty
  String get fullName => displayName.isNotEmpty ? displayName : username;

  /// Get user initials for avatar placeholder
  String get initials {
    if (displayName.isEmpty) {
      return username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '?';
    }

    final nameParts = displayName.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }

    return '?';
  }

  /// Convert UserModel to domain User entity
  User toDomain() {
    return User(
      id: serverId,
      username: username,
      email: email ?? '',
      fullName: displayName.isNotEmpty ? displayName : null,
      avatar: avatarUrl,
      isOnline: isOnline,
      lastSeen: lastSeen,
      metadata: {
        'statusMessage': statusMessage,
        'roles': roles,
        'localId': id.toString(),
      },
    );
  }

  /// Get timestamp for "last seen" display
  String getLastSeenDisplay() {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (isOnline) {
      return 'Online';
    } else if (difference.inSeconds < 60) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return 'Last seen on ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  /// Check if the user is active recently
  bool get isRecentlyActive {
    if (isOnline) return true;
    final now = DateTime.now();
    return now.difference(lastSeen).inHours < 24; // Active in last 24 hours
  }

  /// Check if user has provided an email
  bool get hasEmail => email != null && email!.isNotEmpty;

  /// Check if user has a custom avatar
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  /// Check if user has a status message
  bool get hasStatusMessage => statusMessage != null && statusMessage!.isNotEmpty;

  /// Generate a username suggestion based on display name
  static String generateUsernameSuggestion(String displayName) {
    if (displayName.isEmpty) return '';
    
    // Remove special characters and convert to lowercase
    final sanitized = displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(' ', '_');
    
    // Add a random number suffix
    final randomSuffix = DateTime.now().millisecondsSinceEpoch % 1000;
    return '${sanitized}_$randomSuffix';
  }
} 