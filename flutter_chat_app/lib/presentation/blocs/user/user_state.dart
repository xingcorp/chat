part of 'user_bloc.dart';

/// **Abstract class for User BLoC states**
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

/// **Initial state**
class UserInitial extends UserState {
  const UserInitial();
}

/// **Loading state**
class UserLoading extends UserState {
  const UserLoading();
}

/// **User profile loaded state**
class UserProfileLoaded extends UserState {
  final User user;
  final bool isUpdating;

  const UserProfileLoaded({
    required this.user,
    this.isUpdating = false,
  });

  /// Create a copy with updated properties
  UserProfileLoaded copyWith({
    User? user,
    bool? isUpdating,
  }) {
    return UserProfileLoaded(
      user: user ?? this.user,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object> get props => [user, isUpdating];
}

/// **Searching users state**
class UserSearching extends UserState {
  const UserSearching();
}

/// **User search results state**
class UserSearchResults extends UserState {
  final List<User> users;

  const UserSearchResults({required this.users});

  @override
  List<Object> get props => [users];
}

/// **Error state**
class UserError extends UserState {
  final String message;

  const UserError({required this.message});

  @override
  List<Object> get props => [message];
}

/// **Extension for convenient state creation**
extension UserStateX on UserState {
  static const UserInitial initial = UserInitial();
  static const UserLoading loading = UserLoading();
  static const UserSearching searching = UserSearching();

  static UserProfileLoaded profileLoaded({required User user}) =>
      UserProfileLoaded(user: user);

  static UserSearchResults searchResults({required List<User> users}) =>
      UserSearchResults(users: users);

  static UserError error({required String message}) =>
      UserError(message: message);
}
