part of 'typing_bloc.dart';

/// **Abstract class for Typing BLoC events**
abstract class TypingEvent extends Equatable {
  const TypingEvent();

  @override
  List<Object?> get props => [];
}

/// **Start typing event**
class StartTyping extends TypingEvent {
  final String chatId;

  const StartTyping({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

/// **Stop typing event**
class StopTyping extends TypingEvent {
  final String chatId;

  const StopTyping({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

/// **Receive typing indicator from other users event**
class ReceiveTypingIndicator extends TypingEvent {
  final TypingIndicator indicator;

  const ReceiveTypingIndicator({required this.indicator});

  @override
  List<Object> get props => [indicator];
}

/// **Join chat for typing indicators event**
class JoinChatForTyping extends TypingEvent {
  final String chatId;

  const JoinChatForTyping({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

/// **Leave chat for typing indicators event**
class LeaveChatForTyping extends TypingEvent {
  final String chatId;

  const LeaveChatForTyping({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

/// **Clear typing indicators for chat event**
class ClearTypingIndicators extends TypingEvent {
  final String chatId;

  const ClearTypingIndicators({required this.chatId});

  @override
  List<Object> get props => [chatId];
}
