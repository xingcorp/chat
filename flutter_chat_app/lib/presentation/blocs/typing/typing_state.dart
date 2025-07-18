part of 'typing_bloc.dart';

/// **Abstract class for Typing BLoC states**
abstract class TypingState extends Equatable {
  const TypingState();

  @override
  List<Object?> get props => [];
}

/// **Initial state**
class TypingInitial extends TypingState {
  const TypingInitial();
}

/// **Currently typing state**
class TypingActive extends TypingState {
  final String chatId;

  const TypingActive({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

/// **Stopped typing state**
class TypingStopped extends TypingState {
  final String chatId;

  const TypingStopped({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

/// **Other users typing state**
class TypingUsersActive extends TypingState {
  final String chatId;
  final List<TypingUser> typingUsers;

  const TypingUsersActive({
    required this.chatId,
    required this.typingUsers,
  });

  @override
  List<Object> get props => [chatId, typingUsers];
}

/// **No one typing state**
class TypingNoOneActive extends TypingState {
  final String chatId;

  const TypingNoOneActive({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

/// **Joined chat for typing state**
class TypingJoined extends TypingState {
  final String chatId;

  const TypingJoined({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

/// **Left chat for typing state**
class TypingLeft extends TypingState {
  final String chatId;

  const TypingLeft({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

/// **Error state**
class TypingError extends TypingState {
  final String message;

  const TypingError({required this.message});

  @override
  List<Object> get props => [message];
}

/// **Extension for convenient state creation**
extension TypingStateX on TypingState {
  static const TypingInitial initial = TypingInitial();

  static TypingActive typing({required String chatId}) =>
      TypingActive(chatId: chatId);

  static TypingStopped stopped({required String chatId}) =>
      TypingStopped(chatId: chatId);

  static TypingUsersActive usersTyping({
    required String chatId,
    required List<TypingUser> typingUsers,
  }) =>
      TypingUsersActive(chatId: chatId, typingUsers: typingUsers);

  static TypingNoOneActive noOneTyping({required String chatId}) =>
      TypingNoOneActive(chatId: chatId);

  static TypingJoined joined({required String chatId}) =>
      TypingJoined(chatId: chatId);

  static TypingLeft left({required String chatId}) =>
      TypingLeft(chatId: chatId);

  static TypingError error({required String message}) =>
      TypingError(message: message);
}
