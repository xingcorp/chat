import 'package:flutter_chat_app/core/services/emoji_shortcode_service.dart';

/// The type of autocomplete suggestion to show.
enum SuggestionMode {
  /// `@mention` — shows member list.
  mention,

  /// `/slash` — shows slash command list.
  slashCommand,

  /// `:shortcode` — shows emoji shortcode list.
  shortcode,
}

/// Result of trigger detection — describes what kind of suggestion
/// to show and the character range to replace on selection.
class SuggestionTriggerResult {
  const SuggestionTriggerResult({
    required this.mode,
    required this.triggerStartIndex,
    required this.triggerEndIndex,
    required this.query,
  });

  /// The type of suggestion to show.
  final SuggestionMode mode;

  /// Start index of the trigger text (inclusive).
  /// For `@mention`: index of `@`.
  /// For `/slash`: index of `/`.
  /// For `:shortcode`: index of `:`.
  final int triggerStartIndex;

  /// End index of the trigger text (exclusive, usually cursor position).
  final int triggerEndIndex;

  /// The search query (text after the trigger character, before cursor).
  final String query;
}

/// Detects autocomplete trigger patterns (@mention, /slash, :shortcode)
/// in text given the cursor position.
///
/// This is a stateless utility — call [detect] on every text change.
/// It returns `null` when no trigger pattern is found.
class SuggestionTriggerDetector {
  const SuggestionTriggerDetector();

  /// Given [text] and [cursorPos], detect if the user is typing a
  /// trigger pattern. Returns `null` if no trigger found.
  ///
  /// Priority: @mention > /slash > :shortcode.
  SuggestionTriggerResult? detect(String text, int cursorPos) {
    if (cursorPos < 0 || cursorPos > text.length) return null;

    return _checkMention(text, cursorPos) ??
        _checkSlashCommand(text, cursorPos) ??
        _checkShortcode(text, cursorPos);
  }

  /// Detect `@query` pattern for mention suggestions.
  SuggestionTriggerResult? _checkMention(String text, int cursorPos) {
    int atIndex = -1;
    for (int i = cursorPos - 1; i >= 0; i--) {
      if (text[i] == '@') {
        // Completed mentions look like [@userId] — skip those.
        if (i == 0 || text[i - 1] != '[') {
          atIndex = i;
          break;
        }
      }
      // Stop at whitespace boundaries.
      if (text[i] == ' ' || text[i] == '\n') {
        break;
      }
    }

    if (atIndex < 0 || cursorPos <= atIndex) {
      return null;
    }

    final query = text.substring(atIndex + 1, cursorPos).toLowerCase();
    return SuggestionTriggerResult(
      mode: SuggestionMode.mention,
      triggerStartIndex: atIndex,
      triggerEndIndex: cursorPos,
      query: query,
    );
  }

  /// Detect `/command` pattern at the start of a line.
  SuggestionTriggerResult? _checkSlashCommand(String text, int cursorPos) {
    if (cursorPos <= 0 || text.isEmpty) return null;

    final lineStart = text.lastIndexOf('\n', cursorPos - 1);
    final segmentStart = lineStart == -1 ? 0 : lineStart + 1;
    if (segmentStart >= cursorPos) return null;

    final segment = text.substring(segmentStart, cursorPos);
    final match = RegExp(r'^\s*/([a-zA-Z]*)$').firstMatch(segment);
    if (match == null) return null;

    final slashOffset = segment.indexOf('/');
    if (slashOffset < 0) return null;

    final query = (match.group(1) ?? '').toLowerCase();
    return SuggestionTriggerResult(
      mode: SuggestionMode.slashCommand,
      triggerStartIndex: segmentStart + slashOffset,
      triggerEndIndex: cursorPos,
      query: query,
    );
  }

  /// Detect `:shortcode` pattern (needs 2+ chars after `:`).
  SuggestionTriggerResult? _checkShortcode(String text, int cursorPos) {
    if (cursorPos <= 0) return null;

    final textBeforeCursor = text.substring(0, cursorPos);
    final lastColonIndex = textBeforeCursor.lastIndexOf(':');

    if (lastColonIndex < 0) return null;

    // `:` must be at start of text or after whitespace
    // (avoids matching inside URLs, timestamps, etc.)
    if (lastColonIndex > 0 &&
        textBeforeCursor[lastColonIndex - 1] != ' ' &&
        textBeforeCursor[lastColonIndex - 1] != '\n') {
      return null;
    }

    final query = textBeforeCursor.substring(lastColonIndex + 1);

    // No spaces/newlines allowed in shortcode query.
    if (query.contains(' ') || query.contains('\n')) return null;

    // Need at least 2 chars to search (Discord/Slack standard).
    if (query.length < 2) return null;

    // Check if any matches exist before returning a result.
    final results = EmojiShortcodeService.search(query, limit: 1);
    if (results.isEmpty) return null;

    return SuggestionTriggerResult(
      mode: SuggestionMode.shortcode,
      triggerStartIndex: lastColonIndex,
      triggerEndIndex: cursorPos,
      query: query,
    );
  }
}
