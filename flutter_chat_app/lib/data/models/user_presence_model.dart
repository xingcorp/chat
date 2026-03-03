import 'package:flutter_chat_app/domain/entities/user_presence.dart';

class UserPresenceModel {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserPresenceModel({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
  });

  factory UserPresenceModel.fromJson(Map<String, dynamic> json) {
    return UserPresenceModel(
      userId: (json['userId'] ?? '').toString(),
      isOnline: _parseIsOnline(json['isOnline'] ?? json['status']),
      lastSeen: _parseLastSeen(json['lastSeen'] ?? json['offlineAt']),
    );
  }

  UserPresence toEntity() {
    return UserPresence(
      userId: userId,
      isOnline: isOnline,
      lastSeen: lastSeen,
    );
  }

  static bool _parseIsOnline(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'online' ||
          normalized == 'true' ||
          normalized == '1';
    }
    return false;
  }

  static DateTime? _parseLastSeen(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is num) {
      final raw = value.toInt();
      final milliseconds = raw < 1000000000000 ? raw * 1000 : raw;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }

      final asInt = int.tryParse(trimmed);
      if (asInt != null) {
        final milliseconds = asInt < 1000000000000 ? asInt * 1000 : asInt;
        return DateTime.fromMillisecondsSinceEpoch(milliseconds);
      }

      return DateTime.tryParse(trimmed);
    }

    return null;
  }
}
