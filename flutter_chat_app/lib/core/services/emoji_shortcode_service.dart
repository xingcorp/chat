/// Service tìm kiếm emoji theo shortcode (`:smile:`, `:heart:`, `:thumbsup:`)
///
/// Pattern: Discord / Telegram / Slack
/// - User gõ `:` + 2 ký tự → search trong database
/// - Trả về danh sách emoji + shortcode name matching
/// - Fuzzy search: `:sm` → [😊:smile, 😏:smirk, 😄:smiley, ...]
///
/// Database tự chứa ~200 shortcodes phổ biến nhất (không cần package ngoài).
/// Nếu cần mở rộng, có thể thêm `emojis` package sau.
class EmojiShortcodeService {
  EmojiShortcodeService._();

  // ══════════════════════════════════════════
  // Public API
  // ══════════════════════════════════════════

  /// Tìm emoji matching shortcode query
  ///
  /// [query] Phần text sau dấu `:` (không bao gồm `:`)
  /// [limit] Số kết quả tối đa trả về
  ///
  /// Returns danh sách [EmojiShortcodeMatch] sorted by relevance
  ///
  /// Example:
  /// ```dart
  /// EmojiShortcodeService.search('sm') →
  ///   [😊:smile, 😏:smirk, 😄:smiley, 🙂:slightly_smiling_face]
  ///
  /// EmojiShortcodeService.search('heart') →
  ///   [❤️:heart, 💜:purple_heart, 💚:green_heart, ...]
  /// ```
  static List<EmojiShortcodeMatch> search(String query, {int limit = 6}) {
    if (query.isEmpty) return const [];

    final lowerQuery = query.toLowerCase();
    final results = <EmojiShortcodeMatch>[];

    for (final entry in _shortcodeDatabase.entries) {
      final shortcode = entry.key;
      final emoji = entry.value;

      // Exact prefix match (highest priority)
      if (shortcode.startsWith(lowerQuery)) {
        results.add(EmojiShortcodeMatch(
          emoji: emoji,
          shortcode: shortcode,
          relevance: shortcode == lowerQuery ? 100 : 90,
        ));
      }
      // Contains match (lower priority)
      else if (shortcode.contains(lowerQuery)) {
        results.add(EmojiShortcodeMatch(
          emoji: emoji,
          shortcode: shortcode,
          relevance: 50,
        ));
      }
    }

    // Sort by relevance DESC, then shortcode length ASC (shorter = more common)
    results.sort((a, b) {
      final relevanceDiff = b.relevance.compareTo(a.relevance);
      if (relevanceDiff != 0) return relevanceDiff;
      return a.shortcode.length.compareTo(b.shortcode.length);
    });

    return results.take(limit).toList();
  }

  /// Convert tất cả shortcodes trong text thành emoji
  ///
  /// [text] Input text có thể chứa shortcodes dạng `:name:`
  /// Returns text với shortcodes đã được thay bằng emoji
  ///
  /// Example:
  /// ```dart
  /// EmojiShortcodeService.convert('hello :smile: :heart:')
  /// // → 'hello 😊 ❤️'
  /// ```
  static String convert(String text) {
    if (text.isEmpty) return text;
    if (!text.contains(':')) return text;

    return text.replaceAllMapped(_shortcodePattern, (match) {
      final shortcode = match.group(1)?.toLowerCase();
      if (shortcode == null) return match.group(0) ?? '';

      final emoji = _shortcodeDatabase[shortcode];
      return emoji ?? match.group(0) ?? '';
    });
  }

  /// Kiểm tra shortcode có tồn tại không
  static bool exists(String shortcode) {
    return _shortcodeDatabase.containsKey(shortcode.toLowerCase());
  }

  /// Lấy emoji từ shortcode (không bao gồm dấu `:`)
  static String? getEmoji(String shortcode) {
    return _shortcodeDatabase[shortcode.toLowerCase()];
  }

  // ══════════════════════════════════════════
  // Private
  // ══════════════════════════════════════════

  /// Regex pattern match `:shortcode:` trong text
  static final RegExp _shortcodePattern = RegExp(
    r':([a-zA-Z0-9_+-]+):',
  );

  /// Database ~200 shortcodes phổ biến nhất
  ///
  /// Sources: Discord, Slack, GitHub, Telegram
  /// Grouped by category cho dễ maintain
  static const Map<String, String> _shortcodeDatabase = {
    // ── Smileys & People ──
    'smile': '😊',
    'smiley': '😃',
    'grinning': '😀',
    'grin': '😁',
    'laughing': '😆',
    'joy': '😂',
    'rofl': '🤣',
    'relaxed': '☺️',
    'blush': '😊',
    'innocent': '😇',
    'slightly_smiling_face': '🙂',
    'upside_down_face': '🙃',
    'wink': '😉',
    'relieved': '😌',
    'heart_eyes': '😍',
    'smiling_face_with_3_hearts': '🥰',
    'kissing_heart': '😘',
    'kissing': '😗',
    'kissing_smiling_eyes': '😙',
    'kissing_closed_eyes': '😚',
    'yum': '😋',
    'stuck_out_tongue': '😛',
    'stuck_out_tongue_winking_eye': '😜',
    'zany_face': '🤪',
    'stuck_out_tongue_closed_eyes': '😝',
    'money_mouth_face': '🤑',
    'hugs': '🤗',
    'thinking': '🤔',
    'zipper_mouth_face': '🤐',
    'raised_eyebrow': '🤨',
    'neutral_face': '😐',
    'expressionless': '😑',
    'no_mouth': '😶',
    'smirk': '😏',
    'unamused': '😒',
    'roll_eyes': '🙄',
    'grimacing': '😬',
    'lying_face': '🤥',
    'shushing_face': '🤫',
    'sunglasses': '😎',
    'nerd_face': '🤓',
    'confused': '😕',
    'worried': '😟',
    'slightly_frowning_face': '🙁',
    'frowning_face': '☹️',
    'open_mouth': '😮',
    'hushed': '😯',
    'astonished': '😲',
    'flushed': '😳',
    'pleading_face': '🥺',
    'cry': '😢',
    'sob': '😭',
    'scream': '😱',
    'confounded': '😖',
    'persevere': '😣',
    'disappointed': '😞',
    'sweat': '😓',
    'weary': '😩',
    'tired_face': '😫',
    'yawning_face': '🥱',
    'angry': '😠',
    'rage': '🤬',
    'triumph': '😤',
    'skull': '💀',
    'poop': '💩',
    'clown_face': '🤡',
    'ghost': '👻',
    'alien': '👽',
    'robot': '🤖',
    'jack_o_lantern': '🎃',
    'see_no_evil': '🙈',
    'hear_no_evil': '🙉',
    'speak_no_evil': '🙊',

    // ── Gestures ──
    'wave': '👋',
    'raised_hand': '✋',
    'ok_hand': '👌',
    'pinching_hand': '🤏',
    'v': '✌️',
    'crossed_fingers': '🤞',
    'love_you_gesture': '🤟',
    'metal': '🤘',
    'call_me_hand': '🤙',
    'point_left': '👈',
    'point_right': '👉',
    'point_up': '☝️',
    'point_down': '👇',
    'thumbsup': '👍',
    'thumbup': '👍',
    '+1': '👍',
    'thumbsdown': '👎',
    'thumbdown': '👎',
    '-1': '👎',
    'fist': '✊',
    'punch': '👊',
    'handshake': '🤝',
    'pray': '🙏',
    'clap': '👏',
    'muscle': '💪',
    'writing_hand': '✍️',
    'palms_up': '🤲',

    // ── Hearts & Emotions ──
    'heart': '❤️',
    'red_heart': '❤️',
    'orange_heart': '🧡',
    'yellow_heart': '💛',
    'green_heart': '💚',
    'blue_heart': '💙',
    'purple_heart': '💜',
    'black_heart': '🖤',
    'white_heart': '🤍',
    'broken_heart': '💔',
    'heartbeat': '💓',
    'heartpulse': '💗',
    'two_hearts': '💕',
    'sparkling_heart': '💖',
    'revolving_hearts': '💞',
    'cupid': '💘',
    'gift_heart': '💝',
    'heart_on_fire': '❤️‍🔥',
    'fire': '🔥',
    'star': '⭐',
    'sparkles': '✨',
    'star2': '🌟',
    'dizzy': '💫',
    'boom': '💥',
    'collision': '💥',
    'sweat_drops': '💦',
    'dash': '💨',
    'hole': '🕳️',
    'bomb': '💣',
    'speech_balloon': '💬',
    'thought_balloon': '💭',
    'zzz': '💤',
    'hundred': '💯',
    '100': '💯',

    // ── Animals & Nature ──
    'dog': '🐶',
    'cat': '🐱',
    'mouse': '🐭',
    'hamster': '🐹',
    'rabbit': '🐰',
    'fox': '🦊',
    'bear': '🐻',
    'panda': '🐼',
    'koala': '🐨',
    'tiger': '🐯',
    'lion': '🦁',
    'cow': '🐮',
    'pig': '🐷',
    'frog': '🐸',
    'monkey': '🐵',
    'chicken': '🐔',
    'penguin': '🐧',
    'bird': '🐦',
    'eagle': '🦅',
    'butterfly': '🦋',
    'bug': '🐛',
    'bee': '🐝',
    'snail': '🐌',
    'turtle': '🐢',
    'snake': '🐍',
    'dragon': '🐲',
    'unicorn': '🦄',
    'whale': '🐋',
    'dolphin': '🐬',
    'fish': '🐟',
    'octopus': '🐙',
    'crab': '🦀',
    'shrimp': '🦐',

    // ── Food & Drink ──
    'apple': '🍎',
    'banana': '🍌',
    'watermelon': '🍉',
    'grapes': '🍇',
    'strawberry': '🍓',
    'peach': '🍑',
    'cherry': '🍒',
    'pizza': '🍕',
    'hamburger': '🍔',
    'fries': '🍟',
    'hotdog': '🌭',
    'taco': '🌮',
    'burrito': '🌯',
    'egg': '🥚',
    'coffee': '☕',
    'tea': '🍵',
    'beer': '🍺',
    'wine': '🍷',
    'cocktail': '🍸',
    'cake': '🎂',
    'cookie': '🍪',
    'chocolate': '🍫',
    'candy': '🍬',
    'ice_cream': '🍦',
    'doughnut': '🍩',
    'rice': '🍚',
    'ramen': '🍜',
    'sushi': '🍣',

    // ── Activities & Celebration ──
    'soccer': '⚽',
    'basketball': '🏀',
    'football': '🏈',
    'baseball': '⚾',
    'tennis': '🎾',
    'trophy': '🏆',
    'medal': '🏅',
    'tada': '🎉',
    'confetti_ball': '🎊',
    'balloon': '🎈',
    'gift': '🎁',
    'ribbon': '🎀',
    'party_popper': '🎉',
    'sparkler': '🎇',
    'fireworks': '🎆',
    'art': '🎨',
    'music': '🎵',
    'musical_note': '🎵',
    'notes': '🎶',
    'microphone': '🎤',
    'headphones': '🎧',
    'guitar': '🎸',
    'drum': '🥁',
    'video_game': '🎮',
    'dice': '🎲',

    // ── Travel & Places ──
    'car': '🚗',
    'bus': '🚌',
    'airplane': '✈️',
    'rocket': '🚀',
    'ship': '🚢',
    'bike': '🚲',
    'house': '🏠',
    'office': '🏢',
    'hospital': '🏥',
    'school': '🏫',
    'church': '⛪',
    'earth': '🌍',
    'earth_americas': '🌎',
    'earth_asia': '🌏',
    'sun': '☀️',
    'moon': '🌙',
    'rainbow': '🌈',
    'cloud': '☁️',
    'rain': '🌧️',
    'snow': '❄️',
    'lightning': '⚡',
    'umbrella': '☂️',
    'palm_tree': '🌴',
    'cactus': '🌵',
    'christmas_tree': '🎄',
    'maple_leaf': '🍁',
    'four_leaf_clover': '🍀',
    'rose': '🌹',
    'sunflower': '🌻',
    'tulip': '🌷',
    'cherry_blossom': '🌸',

    // ── Objects & Symbols ──
    'phone': '📱',
    'computer': '💻',
    'keyboard': '⌨️',
    'camera': '📷',
    'tv': '📺',
    'radio': '📻',
    'bulb': '💡',
    'flashlight': '🔦',
    'wrench': '🔧',
    'hammer': '🔨',
    'lock': '🔒',
    'unlock': '🔓',
    'key': '🔑',
    'magnifying_glass': '🔍',
    'search': '🔍',
    'bell': '🔔',
    'loudspeaker': '📢',
    'megaphone': '📣',
    'mute': '🔇',
    'book': '📚',
    'memo': '📝',
    'pencil': '✏️',
    'paperclip': '📎',
    'scissors': '✂️',
    'email': '📧',
    'mailbox': '📬',
    'money': '💰',
    'dollar': '💵',
    'credit_card': '💳',
    'calendar': '📅',
    'clock': '🕐',
    'hourglass': '⏳',
    'alarm_clock': '⏰',
    'check': '✅',
    'white_check_mark': '✅',
    'x': '❌',
    'cross_mark': '❌',
    'warning': '⚠️',
    'no_entry': '⛔',
    'recycle': '♻️',
    'question': '❓',
    'exclamation': '❗',
    'interrobang': '⁉️',

    // ── Flags (popular) ──
    'flag_vn': '🇻🇳',
    'flag_us': '🇺🇸',
    'flag_gb': '🇬🇧',
    'flag_jp': '🇯🇵',
    'flag_kr': '🇰🇷',
    'flag_cn': '🇨🇳',
    'flag_fr': '🇫🇷',
    'flag_de': '🇩🇪',
    'white_flag': '🏳️',
    'rainbow_flag': '🏳️‍🌈',
    'pirate_flag': '🏴‍☠️',
  };
}

/// Kết quả tìm kiếm emoji shortcode
class EmojiShortcodeMatch {
  /// Unicode emoji character
  final String emoji;

  /// Shortcode name (không bao gồm dấu `:`)
  final String shortcode;

  /// Điểm relevance (0-100, cao hơn = match tốt hơn)
  final int relevance;

  const EmojiShortcodeMatch({
    required this.emoji,
    required this.shortcode,
    required this.relevance,
  });

  /// Display format: `😊 :smile:`
  String get displayText => '$emoji :$shortcode:';

  @override
  String toString() => 'EmojiShortcodeMatch($emoji, :$shortcode:, r=$relevance)';
}
