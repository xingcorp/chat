/// Tracks mention name↔userId mappings and converts display format
/// to backend format.
///
/// Platform/controller agnostic — can be used with both
/// `MentionTextEditingController` (plain TextField) and
/// `QuillComposerController` (Quill rich text).
///
/// **Display format:** `Hello @John, check @Alice`
/// **Backend format:** `Hello [@user-123], check [@user-456]`
class MentionTracker {
  MentionTracker({
    Map<String, String> mentionNameById = const <String, String>{},
  }) : _mentionNameById = Map<String, String>.from(mentionNameById);

  Map<String, String> _mentionNameById;

  /// Unmodifiable view of the current mention map (userId → fullName).
  Map<String, String> get mentionNameById =>
      Map<String, String>.unmodifiable(_mentionNameById);

  /// Replace all tracked mentions at once (e.g. when restoring a draft).
  void updateMentions(Map<String, String> mentionNameById) {
    _mentionNameById = Map<String, String>.from(mentionNameById);
  }

  /// Add or update a single mention.
  void upsertMention(String userId, String fullName) {
    final id = userId.trim();
    final name = fullName.trim();
    if (id.isEmpty || name.isEmpty) return;
    _mentionNameById[id] = name;
  }

  /// Remove all tracked mentions.
  void clear() => _mentionNameById.clear();

  /// Whether any mentions are currently tracked.
  bool get hasMentions => _mentionNameById.isNotEmpty;

  /// Convert display mentions (`@FullName`) to backend format (`[@userId]`).
  ///
  /// Sorts by name length descending to prevent partial matches
  /// (e.g. `@John Smith` is replaced before `@John`).
  String toBackendMentionFormat(String input) {
    var result = input;

    final entries = _mentionNameById.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    for (final e in entries) {
      final name = e.value.trim();
      if (name.isEmpty) continue;

      final escaped = RegExp.escape('@$name');
      result = result.replaceAllMapped(
        RegExp('(^|\\s)($escaped)(?=\\s|\$)'),
        (m) => '${m.group(1)}[@${e.key}]',
      );
    }

    return result;
  }
}
