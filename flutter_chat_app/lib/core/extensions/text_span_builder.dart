import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Builder để parse text thành các TextSpan với support cho mentions, URLs, phones, emails, HTML
///
/// Pattern:
/// - Mention: [@id] hoặc @uuid format
/// - URL: https/http links
/// - Phone: Việt Nam phone numbers
/// - Email: email addresses
/// - HTML: <br>, <a href>, <b>, <i>, <u>
///
/// Mỗi entity có:
/// - Style riêng (primary color, underline)
/// - TapGestureRecognizer để mở action sheet
///
/// Long message handling:
/// - Truncate after maxLines with "Read more" button
/// - Expandable/collapsible like WhatsApp, Telegram
class TextSpanBuilder {
  // ══════════════════════════════════════════
  // Constants
  // ══════════════════════════════════════════

  /// Maximum lines before truncation (like WhatsApp/Telegram)
  static const int defaultMaxLines = 5;

  /// Maximum characters before truncation
  static const int defaultMaxChars = 500;

  // ══════════════════════════════════════════
  // Regex Patterns
  // ══════════════════════════════════════════

  /// Regex cho URL (http/https)
  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  /// Regex cho phone number (Việt Nam + international)
  /// Support: 09xxxxxxxx, 03xxxxxxxx, +84xxxxxxxxx, etc.
  static final RegExp _phoneRegex = RegExp(
    r'(\+84|84|0)[3|5|7|8|9][0-9]{8}',
    caseSensitive: false,
  );

  /// Regex cho email
  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    caseSensitive: false,
  );

  /// Regex cho mention ([@id] hoặc @uuid)
  static final RegExp _mentionRegex = RegExp(
    r'\[@([^\]]+)\]|@([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})',
  );

  /// Regex cho HTML line break
  static final RegExp _brRegex = RegExp(r'<br\s*/?>', caseSensitive: false);

  /// Regex cho HTML anchor tag
  static final RegExp _anchorRegex = RegExp(
    r'<a\s+[^>]*href=["\x27]([^"\x27]+)["\x27][^>]*>([^<]*)</a>',
    caseSensitive: false,
  );

  /// Regex cho HTML bold tag
  static final RegExp _boldRegex =
      RegExp(r'<b>([^<]*)</b>', caseSensitive: false);

  /// Regex cho HTML italic tag
  static final RegExp _italicRegex =
      RegExp(r'<i>([^<]*)</i>', caseSensitive: false);

  /// Regex cho HTML underline tag
  static final RegExp _underlineRegex =
      RegExp(r'<u>([^<]*)</u>', caseSensitive: false);

  /// Regex cho HTML strong tag (alias of bold)
  static final RegExp _strongRegex =
      RegExp(r'<strong>([^<]*)</strong>', caseSensitive: false);

  /// Regex cho HTML em tag (emphasis / italic)
  static final RegExp _emRegex =
      RegExp(r'<em>([^<]*)</em>', caseSensitive: false);

  /// Regex cho HTML strikethrough tags (<s> and <del>)
  static final RegExp _strikethroughRegex =
      RegExp(r'<(?:s|del)>([^<]*)</(?:s|del)>', caseSensitive: false);

  // ══════════════════════════════════════════
  // Main Build Method
  // ══════════════════════════════════════════

  /// Parse text thành danh sách InlineSpan
  ///
  /// [rawContent] Content gốc từ message
  /// [normalizedContent] Content đã format mentions (từ formatChatMessage)
  /// [textStyle] Style cho text thường
  /// [linkStyle] Style cho links (primary color, underline)
  /// [mentionStyle] Style cho mentions
  /// [highlightedMentionStyle] Style cho mention cần nhấn mạnh (ví dụ mention current user)
  /// [mentionNameById] Map id -> display name cho mentions
  /// [highlightMentionIds] Danh sách mention id cần tô nổi bật
  /// [onTapMention] Callback khi tap mention
  /// [context] BuildContext để show action sheets
  /// [selectable] Khi true, mention dùng TextSpan + TapGestureRecognizer thay vì
  ///   WidgetSpan + GestureDetector. Điều này đảm bảo SelectableText.rich() copy
  ///   mention text chính xác (WidgetSpan tạo ra U+FFFC khi copy).
  static List<InlineSpan> buildSpans({
    required String rawContent,
    required String normalizedContent,
    required TextStyle textStyle,
    required TextStyle linkStyle,
    required TextStyle mentionStyle,
    TextStyle? highlightedMentionStyle,
    required Map<String, String> mentionNameById,
    Set<String> highlightMentionIds = const <String>{},
    required void Function(String userId) onTapMention,
    required BuildContext context,
    bool selectable = false,
  }) {
    // Nếu không có entity nào, return text thường
    if (!_hasAnyEntities(rawContent)) {
      return [TextSpan(text: normalizedContent, style: textStyle)];
    }

    // Parse tất cả entities
    final entities = _parseAllEntities(rawContent);

    // Sort theo vị trí xuất hiện
    entities.sort((a, b) => a.start.compareTo(b.start));

    final spans = <InlineSpan>[];
    var lastIndex = 0;

    for (final entity in entities) {
      // Thêm text thường trước entity
      if (entity.start > lastIndex) {
        final normalText = rawContent.substring(lastIndex, entity.start);
        spans.add(TextSpan(text: normalText, style: textStyle));
      }

      // Thêm span cho entity
      spans.add(_buildEntitySpan(
          entity,
          textStyle,
          linkStyle,
          mentionStyle,
          highlightedMentionStyle,
          mentionNameById,
          highlightMentionIds,
          onTapMention,
          context,
          selectable));

      lastIndex = entity.end;
    }

    // Thêm text còn lại
    if (lastIndex < rawContent.length) {
      final remainingText = rawContent.substring(lastIndex);
      spans.add(TextSpan(text: remainingText, style: textStyle));
    }

    return spans;
  }

  // ══════════════════════════════════════════
  // Entity Parsing
  // ══════════════════════════════════════════

  /// Kiểm tra có entity nào trong text không
  static bool _hasAnyEntities(String text) {
    return _mentionRegex.hasMatch(text) ||
        _urlRegex.hasMatch(text) ||
        _phoneRegex.hasMatch(text) ||
        _emailRegex.hasMatch(text) ||
        _brRegex.hasMatch(text) ||
        _anchorRegex.hasMatch(text) ||
        _boldRegex.hasMatch(text) ||
        _italicRegex.hasMatch(text) ||
        _underlineRegex.hasMatch(text) ||
        _strongRegex.hasMatch(text) ||
        _emRegex.hasMatch(text) ||
        _strikethroughRegex.hasMatch(text);
  }

  /// Parse tất cả entities từ text
  static List<TextEntity> _parseAllEntities(String text) {
    final entities = <TextEntity>[];

    // Parse mentions
    for (final match in _mentionRegex.allMatches(text)) {
      final id = (match.group(1) ?? match.group(2) ?? '').trim();
      if (id.isNotEmpty) {
        entities.add(TextEntity(
          type: EntityType.mention,
          text: match.group(0)!,
          start: match.start,
          end: match.end,
          value: id,
        ));
      }
    }

    // Parse URLs
    for (final match in _urlRegex.allMatches(text)) {
      entities.add(TextEntity(
        type: EntityType.url,
        text: match.group(0)!,
        start: match.start,
        end: match.end,
        value: match.group(0)!,
      ));
    }

    // Parse phones
    for (final match in _phoneRegex.allMatches(text)) {
      entities.add(TextEntity(
        type: EntityType.phone,
        text: match.group(0)!,
        start: match.start,
        end: match.end,
        value: match.group(0)!,
      ));
    }

    // Parse emails
    for (final match in _emailRegex.allMatches(text)) {
      entities.add(TextEntity(
        type: EntityType.email,
        text: match.group(0)!,
        start: match.start,
        end: match.end,
        value: match.group(0)!,
      ));
    }

    // Parse HTML <br> tags
    for (final match in _brRegex.allMatches(text)) {
      entities.add(TextEntity(
        type: EntityType.htmlBr,
        text: match.group(0)!,
        start: match.start,
        end: match.end,
        value: '\n', // Convert to newline
      ));
    }

    // Parse HTML <a> tags
    for (final match in _anchorRegex.allMatches(text)) {
      entities.add(TextEntity(
        type: EntityType.htmlAnchor,
        text: match.group(0)!,
        start: match.start,
        end: match.end,
        value: match.group(1)!, // URL
        displayText: match.group(2)!, // Link text
      ));
    }

    // Parse HTML <b> tags
    for (final match in _boldRegex.allMatches(text)) {
      entities.add(TextEntity(
        type: EntityType.htmlBold,
        text: match.group(0)!,
        start: match.start,
        end: match.end,
        value: match.group(1)!, // Bold text
      ));
    }

    // Parse HTML <i> tags
    for (final match in _italicRegex.allMatches(text)) {
      entities.add(TextEntity(
        type: EntityType.htmlItalic,
        text: match.group(0)!,
        start: match.start,
        end: match.end,
        value: match.group(1)!, // Italic text
      ));
    }

    // Parse HTML <u> tags
    for (final match in _underlineRegex.allMatches(text)) {
      entities.add(TextEntity(
        type: EntityType.htmlUnderline,
        text: match.group(0)!,
        start: match.start,
        end: match.end,
        value: match.group(1)!, // Underline text
      ));
    }

    // Parse HTML <strong> tags
    for (final match in _strongRegex.allMatches(text)) {
      entities.add(TextEntity(
        type: EntityType.htmlStrong,
        text: match.group(0)!,
        start: match.start,
        end: match.end,
        value: match.group(1)!,
      ));
    }

    // Parse HTML <em> tags
    for (final match in _emRegex.allMatches(text)) {
      entities.add(TextEntity(
        type: EntityType.htmlEm,
        text: match.group(0)!,
        start: match.start,
        end: match.end,
        value: match.group(1)!,
      ));
    }

    // Parse HTML <s> / <del> tags
    for (final match in _strikethroughRegex.allMatches(text)) {
      entities.add(TextEntity(
        type: EntityType.htmlStrikethrough,
        text: match.group(0)!,
        start: match.start,
        end: match.end,
        value: match.group(1)!,
      ));
    }

    return entities;
  }

  // ══════════════════════════════════════════
  // Span Building
  // ══════════════════════════════════════════

  /// Build span cho entity
  static InlineSpan _buildEntitySpan(
    TextEntity entity,
    TextStyle textStyle,
    TextStyle linkStyle,
    TextStyle mentionStyle,
    TextStyle? highlightedMentionStyle,
    Map<String, String> mentionNameById,
    Set<String> highlightMentionIds,
    void Function(String userId) onTapMention,
    BuildContext context,
    bool selectable,
  ) {
    switch (entity.type) {
      case EntityType.mention:
        return _buildMentionSpan(
          entity,
          mentionStyle,
          highlightedMentionStyle,
          mentionNameById,
          highlightMentionIds,
          onTapMention,
          selectable: selectable,
        );

      case EntityType.url:
        return _buildUrlSpan(entity, linkStyle, context);

      case EntityType.phone:
        return _buildPhoneSpan(entity, linkStyle, context);

      case EntityType.email:
        return _buildEmailSpan(entity, linkStyle, context);

      case EntityType.htmlBr:
        return TextSpan(text: '\n', style: textStyle);

      case EntityType.htmlAnchor:
        return _buildHtmlAnchorSpan(entity, linkStyle, context);

      case EntityType.htmlBold:
        return TextSpan(
          text: entity.value,
          style: textStyle.copyWith(fontWeight: FontWeight.bold),
        );

      case EntityType.htmlItalic:
        return TextSpan(
          text: entity.value,
          style: textStyle.copyWith(fontStyle: FontStyle.italic),
        );

      case EntityType.htmlUnderline:
        return TextSpan(
          text: entity.value,
          style: textStyle.copyWith(decoration: TextDecoration.underline),
        );

      case EntityType.htmlStrong:
        return TextSpan(
          text: entity.value,
          style: textStyle.copyWith(fontWeight: FontWeight.bold),
        );

      case EntityType.htmlEm:
        return TextSpan(
          text: entity.value,
          style: textStyle.copyWith(fontStyle: FontStyle.italic),
        );

      case EntityType.htmlStrikethrough:
        return TextSpan(
          text: entity.value,
          style: textStyle.copyWith(decoration: TextDecoration.lineThrough),
        );
    }
  }

  /// Build span cho mention
  ///
  /// Khi [selectable] = true (desktop/web): dùng [TextSpan] + [TapGestureRecognizer]
  /// để text mention được bao gồm khi copy (Ctrl+C). WidgetSpan tạo ra U+FFFC
  /// (Object Replacement Character) khi SelectableText.rich() copy → gây lỗi.
  ///
  /// Khi [selectable] = false (mobile, default): dùng [WidgetSpan] + [GestureDetector]
  /// như cũ → behavior 100% backward compatible.
  static InlineSpan _buildMentionSpan(
    TextEntity entity,
    TextStyle mentionStyle,
    TextStyle? highlightedMentionStyle,
    Map<String, String> mentionNameById,
    Set<String> highlightMentionIds,
    void Function(String userId) onTapMention, {
    bool selectable = false,
  }) {
    final id = entity.value;
    final displayName = mentionNameById[id];
    final shouldHighlight = highlightMentionIds.contains(id);
    final effectiveStyle = shouldHighlight
        ? (highlightedMentionStyle ?? mentionStyle)
        : mentionStyle;

    if (displayName == null || displayName.trim().isEmpty) {
      // Mention không tìm thấy user, hiển thị text thường
      return TextSpan(text: entity.text, style: effectiveStyle);
    }

    final text = '@${displayName.trim()}';

    // Desktop/Web (selectable): dùng TextSpan + TapGestureRecognizer
    // → text được bao gồm khi user select + copy (Ctrl+C)
    if (selectable) {
      return TextSpan(
        text: text,
        style: effectiveStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () => onTapMention(id),
      );
    }

    // Mobile (default): dùng WidgetSpan + GestureDetector
    // → giữ nguyên behavior cũ, tránh conflict gesture với scroll
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GestureDetector(
        onTap: () => onTapMention(id),
        child: Text(
          text,
          style: effectiveStyle,
        ),
      ),
    );
  }

  /// Build span cho URL
  static InlineSpan _buildUrlSpan(
    TextEntity entity,
    TextStyle linkStyle,
    BuildContext context,
  ) {
    return TextSpan(
      text: entity.text,
      style: linkStyle,
      recognizer: TapGestureRecognizer()
        ..onTap = () => _showUrlActionSheet(context, entity.value),
    );
  }

  /// Build span cho phone
  static InlineSpan _buildPhoneSpan(
    TextEntity entity,
    TextStyle linkStyle,
    BuildContext context,
  ) {
    return TextSpan(
      text: entity.text,
      style: linkStyle,
      recognizer: TapGestureRecognizer()
        ..onTap = () => _showPhoneActionSheet(context, entity.value),
    );
  }

  /// Build span cho email
  static InlineSpan _buildEmailSpan(
    TextEntity entity,
    TextStyle linkStyle,
    BuildContext context,
  ) {
    return TextSpan(
      text: entity.text,
      style: linkStyle,
      recognizer: TapGestureRecognizer()
        ..onTap = () => _showEmailActionSheet(context, entity.value),
    );
  }

  /// Build span cho HTML anchor tag
  static InlineSpan _buildHtmlAnchorSpan(
    TextEntity entity,
    TextStyle linkStyle,
    BuildContext context,
  ) {
    final displayText = entity.displayText ?? entity.value;
    return TextSpan(
      text: displayText,
      style: linkStyle,
      recognizer: TapGestureRecognizer()
        ..onTap = () => _showUrlActionSheet(context, entity.value),
    );
  }

  // ══════════════════════════════════════════
  // Action Sheets
  // ══════════════════════════════════════════

  /// Show action sheet cho URL
  static Future<void> _showUrlActionSheet(
      BuildContext context, String url) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => UrlActionSheet(url: url),
      showDragHandle: true,
    );
  }

  /// Show action sheet cho phone
  static Future<void> _showPhoneActionSheet(
      BuildContext context, String phone) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => PhoneActionSheet(phone: phone),
      showDragHandle: true,
    );
  }

  /// Show action sheet cho email
  static Future<void> _showEmailActionSheet(
      BuildContext context, String email) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => EmailActionSheet(email: email),
      showDragHandle: true,
    );
  }
}

/// Entity trong text (mention, url, phone, email, html)
class TextEntity {
  final EntityType type;
  final String text;
  final int start;
  final int end;
  final String value;
  final String? displayText; // For HTML anchor tags

  TextEntity({
    required this.type,
    required this.text,
    required this.start,
    required this.end,
    required this.value,
    this.displayText,
  });
}

/// Loại entity
enum EntityType {
  mention,
  url,
  phone,
  email,
  htmlBr,
  htmlAnchor,
  htmlBold,
  htmlItalic,
  htmlUnderline,
  htmlStrong,
  htmlEm,
  htmlStrikethrough,
}

/// Action Sheet cho URL
class UrlActionSheet extends StatelessWidget {
  final String url;

  const UrlActionSheet({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            l10n.linkPreview,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const AppIcon(icon: Icons.open_in_browser),
            title: AppText(l10n.openLink),
            onTap: () async {
              Navigator.pop(context);
              await url_launcher.launchUrl(Uri.parse(url));
            },
          ),
          ListTile(
            leading: const AppIcon(icon: Icons.copy),
            title: AppText(l10n.copyLink),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: AppText(l10n.messageCopied)),
              );
            },
          ),
          ListTile(
            leading: const AppIcon(icon: Icons.share),
            title: AppText(l10n.share),
            onTap: () async {
              await SharePlus.instance.share(
                  ShareParams(uri: Uri.parse(url), subject: 'Link preview'));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

/// Action Sheet cho Phone
class PhoneActionSheet extends StatelessWidget {
  final String phone;

  const PhoneActionSheet({Key? key, required this.phone}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            l10n.contacts,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const AppIcon(icon: Icons.call),
            title: AppText(l10n.call),
            onTap: () async {
              Navigator.pop(context);
              await url_launcher.launchUrl(Uri(scheme: 'tel', path: phone));
            },
          ),
          ListTile(
            leading: const AppIcon(icon: Icons.message),
            title: AppText(l10n.send),
            onTap: () async {
              Navigator.pop(context);
              await url_launcher.launchUrl(Uri(scheme: 'sms', path: phone));
            },
          ),
          ListTile(
            leading: const AppIcon(icon: Icons.copy),
            title: AppText(l10n.copyMessage),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: phone));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: AppText(l10n.messageCopied)),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Action Sheet cho Email
class EmailActionSheet extends StatelessWidget {
  final String email;

  const EmailActionSheet({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            l10n.email,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const AppIcon(icon: Icons.email),
            title: AppText(l10n.send),
            onTap: () async {
              Navigator.pop(context);
              await url_launcher.launchUrl(Uri(scheme: 'mailto', path: email));
            },
          ),
          ListTile(
            leading: const AppIcon(icon: Icons.copy),
            title: AppText(l10n.copyMessage),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: email));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: AppText(l10n.messageCopied)),
              );
            },
          ),
        ],
      ),
    );
  }
}
