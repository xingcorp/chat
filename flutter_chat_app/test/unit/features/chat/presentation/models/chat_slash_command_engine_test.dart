import 'package:flutter_chat_app/features/chat/presentation/models/chat_slash_command_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = ChatSlashCommandEngine();

  group('ChatSlashCommandEngine.parse', () {
    test('returns none outcome for plain text', () {
      final result = engine.parse(
        input: 'Hello world',
        actorDisplayName: 'Alice',
      );

      expect(result.outcome, ChatSlashCommandOutcome.none);
      expect(result.command, isNull);
      expect(result.messageText, isNull);
    });

    test('returns missing argument for /me without payload', () {
      final result = engine.parse(
        input: '/me',
        actorDisplayName: 'Alice',
      );

      expect(result.outcome, ChatSlashCommandOutcome.invalid);
      expect(
        result.validationError,
        ChatSlashCommandValidationError.missingArgument,
      );
    });

    test('transforms /tableflip to formatted message', () {
      final result = engine.parse(
        input: '/tableflip wow',
        actorDisplayName: 'Alice',
      );

      expect(result.outcome, ChatSlashCommandOutcome.sendMessage);
      expect(result.command, ChatSlashCommand.tableflip);
      expect(result.messageText, 'wow (╯°□°)╯︵ ┻━┻');
    });

    test('returns mute action for /mute', () {
      final result = engine.parse(
        input: '/mute',
        actorDisplayName: 'Alice',
      );

      expect(result.outcome, ChatSlashCommandOutcome.muteAction);
      expect(result.command, ChatSlashCommand.mute);
    });

    test('returns unknown command for unsupported command', () {
      final result = engine.parse(
        input: '/unsupported',
        actorDisplayName: 'Alice',
      );

      expect(result.outcome, ChatSlashCommandOutcome.invalid);
      expect(
        result.validationError,
        ChatSlashCommandValidationError.unknownCommand,
      );
    });
  });

  group('ChatSlashCommandEngine.searchCommands', () {
    test('returns all commands for empty query', () {
      final commands = engine.searchCommands('');

      expect(commands, ChatSlashCommandEngine.supportedCommandNames);
    });

    test('filters commands by query', () {
      final commands = engine.searchCommands('ta');

      expect(commands, <String>[ChatSlashCommandEngine.tableflipCommand]);
    });
  });
}
