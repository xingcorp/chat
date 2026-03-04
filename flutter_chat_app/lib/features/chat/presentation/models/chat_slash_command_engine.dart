import 'package:flutter/foundation.dart';

enum ChatSlashCommand {
  shrug,
  tableflip,
  me,
  mute,
}

enum ChatSlashCommandOutcome {
  none,
  sendMessage,
  muteAction,
  invalid,
}

enum ChatSlashCommandValidationError {
  unknownCommand,
  missingArgument,
}

@immutable
class ChatSlashCommandResult {
  const ChatSlashCommandResult._({
    required this.outcome,
    this.command,
    this.messageText,
    this.validationError,
  });

  const ChatSlashCommandResult.none()
      : this._(outcome: ChatSlashCommandOutcome.none);

  const ChatSlashCommandResult.sendMessage({
    required ChatSlashCommand command,
    required String messageText,
  }) : this._(
          outcome: ChatSlashCommandOutcome.sendMessage,
          command: command,
          messageText: messageText,
        );

  const ChatSlashCommandResult.muteAction()
      : this._(
          outcome: ChatSlashCommandOutcome.muteAction,
          command: ChatSlashCommand.mute,
        );

  const ChatSlashCommandResult.invalid({
    required ChatSlashCommandValidationError validationError,
  }) : this._(
          outcome: ChatSlashCommandOutcome.invalid,
          validationError: validationError,
        );

  final ChatSlashCommandOutcome outcome;
  final ChatSlashCommand? command;
  final String? messageText;
  final ChatSlashCommandValidationError? validationError;
}

@immutable
class SlashCommandOption {
  const SlashCommandOption({
    required this.name,
    required this.description,
    required this.usage,
  });

  final String name;
  final String description;
  final String usage;
}

class ChatSlashCommandEngine {
  const ChatSlashCommandEngine();

  static const String shrugCommand = 'shrug';
  static const String tableflipCommand = 'tableflip';
  static const String meCommand = 'me';
  static const String muteCommand = 'mute';

  static const List<String> supportedCommandNames = <String>[
    shrugCommand,
    tableflipCommand,
    meCommand,
    muteCommand,
  ];

  static const String _shrugSuffix = r'¯\_(ツ)_/¯';
  static const String _tableFlip = '(╯°□°)╯︵ ┻━┻';

  ChatSlashCommandResult parse({
    required String input,
    required String actorDisplayName,
  }) {
    final normalizedInput = input.trim();
    if (!normalizedInput.startsWith('/')) {
      return const ChatSlashCommandResult.none();
    }

    final withoutTrigger = normalizedInput.substring(1).trimLeft();
    if (withoutTrigger.isEmpty) {
      return const ChatSlashCommandResult.invalid(
        validationError: ChatSlashCommandValidationError.unknownCommand,
      );
    }

    final firstSpace = withoutTrigger.indexOf(' ');
    final commandText = (firstSpace == -1
            ? withoutTrigger
            : withoutTrigger.substring(0, firstSpace))
        .trim()
        .toLowerCase();
    final argumentText =
        firstSpace == -1 ? '' : withoutTrigger.substring(firstSpace + 1).trim();

    switch (commandText) {
      case shrugCommand:
        final content =
            argumentText.isEmpty ? _shrugSuffix : '$argumentText $_shrugSuffix';
        return ChatSlashCommandResult.sendMessage(
          command: ChatSlashCommand.shrug,
          messageText: content,
        );

      case tableflipCommand:
        final content =
            argumentText.isEmpty ? _tableFlip : '$argumentText $_tableFlip';
        return ChatSlashCommandResult.sendMessage(
          command: ChatSlashCommand.tableflip,
          messageText: content,
        );

      case meCommand:
        if (argumentText.isEmpty) {
          return const ChatSlashCommandResult.invalid(
            validationError: ChatSlashCommandValidationError.missingArgument,
          );
        }

        final actor = actorDisplayName.trim();
        final effectiveActor =
            actor.isEmpty ? argumentText : '$actor $argumentText';
        return ChatSlashCommandResult.sendMessage(
          command: ChatSlashCommand.me,
          messageText: '* $effectiveActor',
        );

      case muteCommand:
        return const ChatSlashCommandResult.muteAction();

      default:
        return const ChatSlashCommandResult.invalid(
          validationError: ChatSlashCommandValidationError.unknownCommand,
        );
    }
  }

  List<String> searchCommands(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return List<String>.from(supportedCommandNames);
    }

    return supportedCommandNames
        .where((command) => command.contains(normalizedQuery))
        .toList(growable: false);
  }
}
