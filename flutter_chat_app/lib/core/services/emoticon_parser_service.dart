/// Service chuyển đổi emoticon text thành emoji Unicode
///
/// Hỗ trợ 2 loại chuyển đổi:
/// 1. Classic emoticons: `:)` → 😊, `:v` → ✌️, `<3` → ❤️
/// 2. Shortcode syntax: `:smile:` → 😊, `:heart:` → ❤️
///
/// Pattern tham khảo từ Zalo, Messenger, WhatsApp:
/// - Convert khi send (không real-time khi đang gõ)
/// - Word-boundary aware (tránh false match trong URLs, time format)
/// - Longest-match-first (tránh partial match)
///
/// Về `:v` custom icon như Zalo:
/// Hiện tại map sang Unicode emoji. Phase sau có thể render custom image
/// thông qua WidgetSpan trong TextSpanBuilder.
class EmoticonParserService {
  EmoticonParserService._();

  // ══════════════════════════════════════════
  // Emoticon → Emoji Map
  // ══════════════════════════════════════════

  /// Map emoticon text → Unicode emoji
  ///
  /// Sorted by key length DESC tại build time để longest-match-first.
  /// Bao gồm Vietnamese internet culture favorites: `:v`, `:3`, `^_^`, `T_T`
  static const Map<String, String> _emoticonMap = {
    // ── Vietnamese Internet Culture (CRITICAL cho user VN) ──
    ':v': '✌️', // Pac-Man / peace — icon văn hóa VN
    ':3': '😺', // Cat face — rất phổ biến VN

    // ── With-nose variants (longer → match first) ──
    ':-)': '😊',
    ':-(': '😞',
    ':-D': '😀',
    ';-)': '😉',
    ':-P': '😛',
    ':-p': '😛',
    ':-O': '😮',
    ':-o': '😮',
    ':-/': '😕',
    ':-|': '😐',
    ':-*': '😘',

    // ── Cry with nose ──
    ":'-(": '😢',

    // ── Compound emoticons ──
    ":'(": '😢',
    '>:(': '😠',
    '>:-(': '😠',
    'O:)': '😇',
    '3:)': '😈',

    // ── Standard emoticons ──
    ':)': '😊',
    ':(': '😞',
    ':D': '😀',
    ';)': '😉',
    ':P': '😛',
    ':p': '😛',
    ':O': '😮',
    ':o': '😮',
    ':/': '😕',
    ':|': '😐',
    ':*': '😘',

    // ── Special ──
    '<3': '❤️',
    'xD': '😆',
    'XD': '😆',
    'B)': '😎',
    'B-)': '😎',

    // ── East Asian (phổ biến ở VN) ──
    r':\$': '😳', // Embarrassed — escaped $ for regex safety
    'T_T': '😭',
    'T.T': '😭',
    '-_-': '😑',
    '^_^': '😊',
    '>.<': '😣',
    '>_<': '😣',
  };

  /// Map đã sort theo key length DESC (longest-match-first)
  static late final List<MapEntry<String, String>> _sortedEntries = () {
    final entries = _emoticonMap.entries.toList();
    entries.sort((a, b) => b.key.length.compareTo(a.key.length));
    return entries;
  }();

  /// Compiled regex pattern cho emoticon detection
  /// Mỗi emoticon được escape cho regex và wrapped trong word-boundary checks
  static late final RegExp _emoticonRegex = _buildEmoticonRegex();

  // ══════════════════════════════════════════
  // Public API
  // ══════════════════════════════════════════

  /// Convert tất cả emoticons trong text thành emoji Unicode
  ///
  /// [text] Input text có thể chứa emoticons
  /// Returns text với emoticons đã được thay bằng emoji
  ///
  /// Example:
  /// ```dart
  /// EmoticonParserService.convert('hello :) how r u :v')
  /// // → 'hello 😊 how r u ✌️'
  /// ```
  static String convert(String text) {
    if (text.isEmpty) return text;

    // Quick check: có chứa ký tự đặc biệt của emoticon không?
    if (!_mightContainEmoticon(text)) return text;

    var result = text;

    // Iterate qua sorted entries (longest first) để tránh partial match
    for (final entry in _sortedEntries) {
      final emoticon = entry.key;
      final emoji = entry.value;

      // Build pattern cho emoticon cụ thể với word boundary
      final pattern = _buildSingleEmoticonPattern(emoticon);
      if (pattern == null) continue;

      result = result.replaceAllMapped(pattern, (match) {
        final prefix = match.group(1) ?? '';
        final suffix = match.group(3) ?? '';
        return '$prefix$emoji$suffix';
      });
    }

    return result;
  }

  /// Kiểm tra text có chứa emoticon không (quick check, không convert)
  static bool containsEmoticon(String text) {
    if (text.isEmpty) return false;
    if (!_mightContainEmoticon(text)) return false;
    return _emoticonRegex.hasMatch(text);
  }

  /// Lấy danh sách tất cả emoticons được hỗ trợ
  static Map<String, String> get supportedEmoticons =>
      Map.unmodifiable(_emoticonMap);

  // ══════════════════════════════════════════
  // Private Methods
  // ══════════════════════════════════════════

  /// Quick heuristic check — tránh chạy regex nặng cho text không có emoticon
  static bool _mightContainEmoticon(String text) {
    return text.contains(':') ||
        text.contains(';') ||
        text.contains('<') ||
        text.contains('>') ||
        text.contains('B') ||
        text.contains('x') ||
        text.contains('X') ||
        text.contains('T') ||
        text.contains('^') ||
        text.contains('-');
  }

  /// Build regex pattern cho một emoticon cụ thể
  ///
  /// Pattern rules:
  /// - Group 1: Prefix boundary (start-of-string hoặc whitespace)
  /// - Group 2: Emoticon text (escaped)
  /// - Group 3: Suffix boundary (end-of-string hoặc whitespace)
  /// - KHÔNG match trong URLs (preceded by `://` hoặc `//`)
  /// - KHÔNG match trong time format (e.g., `10:30`)
  static RegExp? _buildSingleEmoticonPattern(String emoticon) {
    final escaped = RegExp.escape(emoticon);

    // Prefix: start-of-string HOẶC whitespace/newline
    // Suffix: end-of-string HOẶC whitespace/newline/punctuation
    //
    // Đặc biệt cho emoticons bắt đầu bằng `:` — phải loại trừ:
    // - Digits trước `:` (time format: 10:30, 2:00)
    // - `://` trước `:` (URLs)
    // - Letter trước `:` (compound words like re:start)

    String prefixBoundary;
    if (emoticon.startsWith(':')) {
      // Cho emoticons bắt đầu bằng `:`:
      // Must be preceded by start-of-string or whitespace (không phải digit/letter)
      prefixBoundary = r'(^|(?<=\s))';
    } else if (emoticon.startsWith('>') ||
        emoticon.startsWith('O') ||
        emoticon.startsWith('3')) {
      // Compound emoticons: >:( O:) 3:)
      prefixBoundary = r'(^|(?<=\s))';
    } else if (emoticon.startsWith('<')) {
      // <3
      prefixBoundary = r'(^|(?<=\s))';
    } else {
      // Other emoticons (B), xD, XD, T_T, ^_^, -_-)
      prefixBoundary = r'(^|(?<=\s))';
    }

    // Suffix: end-of-string or whitespace or common punctuation
    const suffixBoundary = r'($|(?=\s|[.,!?\-;:]))';

    try {
      return RegExp(
        '$prefixBoundary($escaped)$suffixBoundary',
        multiLine: true,
      );
    } catch (_) {
      // Regex build failed — skip this emoticon
      return null;
    }
  }

  /// Build combined regex cho quick detection (containsEmoticon)
  static RegExp _buildEmoticonRegex() {
    // Use a simplified pattern for quick detection
    final patterns = _sortedEntries
        .map((e) => RegExp.escape(e.key))
        .join('|');
    return RegExp(
      '(?:^|\\s)($patterns)(?:\\s|\$)',
      multiLine: true,
    );
  }
}
