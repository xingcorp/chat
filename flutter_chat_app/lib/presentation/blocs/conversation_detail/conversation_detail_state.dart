import 'package:flutter_chat_app/presentation/blocs/base/base_state.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';

/// Base state for ConversationDetail BLoC
abstract class ConversationDetailState extends BaseState {
  const ConversationDetailState();
}

/// Initial state
class ConversationDetailInitial extends ConversationDetailState {
  const ConversationDetailInitial();

  @override
  List<Object?> get props => [];
}

/// Loading state
class ConversationDetailLoading extends ConversationDetailState {
  final String? message;

  const ConversationDetailLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Conversation detail loaded successfully
class ConversationDetailLoaded extends ConversationDetailState {
  final Chat chat;

  const ConversationDetailLoaded({required this.chat});

  @override
  List<Object?> get props => [chat];
}

/// Members added successfully (transient state for listener feedback)
class ConversationDetailMembersAdded extends ConversationDetailState {
  final Chat chat;

  const ConversationDetailMembersAdded({required this.chat});

  @override
  List<Object?> get props => [chat];
}

/// Error state
class ConversationDetailError extends ConversationDetailState {
  final String message;
  final Object? error;

  const ConversationDetailError({
    required this.message,
    this.error,
  });

  @override
  List<Object?> get props => [message, error];
}
