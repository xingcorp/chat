import 'package:isar/isar.dart';

part 'user_model.g.dart';

/// Model class representing a user in the system
@collection
class UserModel {
  /// User's unique identifier in the database
  Id id = Isar.autoIncrement;

  /// Server ID of the user
  @Index(unique: true, replace: true)
  final String serverId;

  /// User's username
  @Index(caseSensitive: false)
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
} 