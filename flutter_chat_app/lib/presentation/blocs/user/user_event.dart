part of 'user_bloc.dart';

/// **Abstract class for User BLoC events**
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

/// **Load user profile event**
class LoadUserProfile extends UserEvent {
  final String userId;

  const LoadUserProfile({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// **Update user profile event**
class UpdateUserProfile extends UserEvent {
  final String userId;
  final String? username;
  final String? displayName;
  final String? bio;

  const UpdateUserProfile({
    required this.userId,
    this.username,
    this.displayName,
    this.bio,
  });

  @override
  List<Object?> get props => [userId, username, displayName, bio];
}

/// **Update user avatar event**
class UpdateUserAvatar extends UserEvent {
  final String userId;
  final String avatarFile;

  const UpdateUserAvatar({
    required this.userId,
    required this.avatarFile,
  });

  @override
  List<Object> get props => [userId, avatarFile];
}

/// **Refresh user profile from server event**
class RefreshUserProfile extends UserEvent {
  final String userId;

  const RefreshUserProfile({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// **Search users event**
class SearchUsers extends UserEvent {
  final String query;
  final int limit;

  const SearchUsers({
    required this.query,
    this.limit = 20,
  });

  @override
  List<Object> get props => [query, limit];
}

/// **Clear user search results event**
class ClearUserSearch extends UserEvent {
  const ClearUserSearch();
}
