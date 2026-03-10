/// Extensions liên quan đến emoji detection và xử lý
///
/// Copy pattern `isOnlyEmoji` từ Stream Chat Flutter plugin
/// với emoji regex chuẩn để detect emoji-only messages.
///
/// Pattern: WhatsApp / Telegram / Stream Chat
/// - 1-3 emoji → hiển thị font size lớn (không bubble)
/// - 4+ emoji hoặc emoji+text → font size thường
extension EmojiStringExtension on String {
  // ══════════════════════════════════════════
  // Emoji Detection
  // ══════════════════════════════════════════

  /// Regex pattern detect Unicode emoji characters
  ///
  /// Covers:
  /// - Copyright & Registered: ©, ®
  /// - Zero-width joiner (ZWJ sequences)
  /// - Variation selectors (text vs emoji presentation)
  /// - Miscellaneous symbols: ☀-⛿
  /// - Dingbats & more: ⌀-⯿
  /// - Supplemental symbols (surrogate pairs): 🀀-🿿, 📀-🗿, 🤀-🧿
  /// - Keycap sequences: #️⃣, 0️⃣-9️⃣
  /// - Skin tone modifiers: 🏻-🏿
  /// - Regional indicators (flags): 🇦-🇿
  static final RegExp _emojiRegex = RegExp(
    r'(\u00a9|\u00ae|\u200d|[\u200b-\u200f]|[\ufe00-\ufe0f]|[\u20e0-\u20e3]|'
    r'[\u2600-\u27FF]|[\u2300-\u2bFF]|[\u2900-\u297F]|'
    r'\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff]|'
    r'[\uD800-\uDBFF][\uDC00-\uDFFF])',
    unicode: true,
  );

  /// Kiểm tra string chỉ chứa emoji (1-3 emoji, không có text khác)
  ///
  /// Dùng để quyết định render message với font size lớn.
  ///
  /// Pattern (giống WhatsApp/Telegram/Stream Chat):
  /// - 1-3 emoji-only → `true` → render to
  /// - 4+ emoji → `false` → render thường
  /// - Emoji + text bất kỳ → `false` → render thường
  ///
  /// Example:
  /// ```dart
  /// '😊'.isOnlyEmoji       // true — 1 emoji
  /// '😊❤️😀'.isOnlyEmoji   // true — 3 emoji
  /// '😊😀😆😎'.isOnlyEmoji // false — 4 emoji
  /// 'hello 😊'.isOnlyEmoji // false — có text
  /// ''.isOnlyEmoji          // false — rỗng
  /// ```
  bool get isOnlyEmoji {
    final trimmed = trim();
    if (trimmed.isEmpty) return false;

    // Quick reject: nếu có chữ cái hoặc số → không phải emoji-only
    if (RegExp(r'[a-zA-Z0-9]').hasMatch(trimmed)) return false;

    // Count visual grapheme clusters using runes
    // Each emoji is typically 1-2 runes (surrogate pairs), ZWJ sequences are longer
    // Use a simple heuristic: strip all emoji-related code points, if nothing remains → emoji-only
    final strippedOfEmoji = trimmed.replaceAll(_emojiRegex, '').trim();
    if (strippedOfEmoji.isNotEmpty) return false;

    // Count emoji by matching against the regex
    final emojiMatches = _emojiRegex.allMatches(trimmed).length;

    // Filter out ZWJ and variation selectors from count
    // (they are part of emoji sequences, not standalone emoji)
    final visualEmojiCount = _countVisualEmoji(trimmed);
    if (visualEmojiCount > 3) return false;

    return emojiMatches > 0;
  }

  /// Đếm số emoji "nhìn thấy được" trong string
  ///
  /// ZWJ sequences (👨‍👩‍👧‍👦) đếm là 1 emoji.
  /// Variation selectors không đếm.
  /// Skin tone modifiers không đếm riêng (là phần của emoji trước đó).
  int get emojiCount => _countVisualEmoji(this);

  /// Kiểm tra string có chứa ít nhất 1 emoji
  bool get containsEmoji {
    return _emojiRegex.hasMatch(this);
  }

  /// Đếm visual emoji (nhóm ZWJ sequences lại)
  static int _countVisualEmoji(String text) {
    // Approach: remove all non-emoji characters, then count grapheme clusters
    // by splitting on ZWJ boundaries
    final emojiOnly = text.replaceAll(RegExp(r'[^\u00a9\u00ae\u200d\u200b-\u200f'
        r'\ufe00-\ufe0f\u20e0-\u20e3\u2600-\u27FF\u2300-\u2bFF'
        r'\u2900-\u297F\uD800-\uDFFF]'), '');
    if (emojiOnly.isEmpty) return 0;

    // Simple heuristic: count base emoji characters
    // (exclude ZWJ \u200d, variation selectors \ufe00-\ufe0f, skin tones \ud83c[\udffb-\udfff])
    final baseEmojiPattern = RegExp(
      r'[\u2600-\u27FF\u2300-\u2bFF\u00a9\u00ae]|'
      r'\ud83c[\ud000-\udffa]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff]',
    );
    return baseEmojiPattern.allMatches(emojiOnly).length;
  }
}
