import 'package:equatable/equatable.dart';

/// Domain entity describing online/offline presence of a user.
class UserPresence extends Equatable {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserPresence({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
  });

  static const UserPresence offline = UserPresence(
    userId: '',
    isOnline: false,
  );

  static UserPresence offlineFor(
    String userId, {
    DateTime? lastSeen,
  }) {
    return UserPresence(
      userId: userId,
      isOnline: false,
      lastSeen: lastSeen,
    );
  }

  @override
  List<Object?> get props => <Object?>[userId, isOnline, lastSeen];
}
