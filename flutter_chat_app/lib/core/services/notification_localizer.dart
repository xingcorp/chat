import 'package:flutter/widgets.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Resolves localized notification strings without [BuildContext].
///
/// Uses [WidgetsBinding.instance.platformDispatcher.locale] to look up
/// [AppLocalizations]. The result is cached and should be invalidated via
/// [invalidateCache] when the user switches language in-app.
class NotificationLocalizer {
  NotificationLocalizer._();

  static AppLocalizations? _cached;

  /// Get [AppLocalizations] resolved from the platform locale.
  static AppLocalizations get _l10n {
    if (_cached != null) return _cached!;

    final Locale platformLocale =
        WidgetsBinding.instance.platformDispatcher.locale;

    // Try exact match first, then language-only, then fallback to 'vi'.
    if (AppLocalizations.supportedLocales.contains(platformLocale)) {
      _cached = lookupAppLocalizations(platformLocale);
    } else {
      _cached = _resolveByLanguage(platformLocale.languageCode);
    }

    return _cached!;
  }

  static AppLocalizations _resolveByLanguage(String languageCode) {
    final Locale? match =
        AppLocalizations.supportedLocales.cast<Locale?>().firstWhere(
              (Locale? l) => l?.languageCode == languageCode,
              orElse: () => null,
            );
    return lookupAppLocalizations(match ?? const Locale('vi'));
  }

  /// Call when the user changes language in-app settings.
  static void invalidateCache() {
    _cached = null;
  }

  /// Returns the localized label for non-text [ContentType]s.
  ///
  /// Returns `null` for [ContentType.text] and [ContentType.event] because
  /// those should use the actual message content.
  static String? getContentTypeLabel(
    ContentType contentType, {
    String? fileName,
  }) {
    switch (contentType) {
      case ContentType.text:
        return null;
      case ContentType.image:
        return _l10n.notificationContentImage;
      case ContentType.video:
        return _l10n.notificationContentVideo;
      case ContentType.audio:
        return _l10n.notificationContentAudio;
      case ContentType.file:
        return _l10n.notificationContentFile(fileName ?? '');
      case ContentType.sticker:
        return _l10n.notificationContentSticker;
      case ContentType.location:
        return _l10n.notificationContentLocation;
      case ContentType.link:
        return _l10n.notificationContentLink;
      case ContentType.event:
        return null;
    }
  }

  /// Formats the notification body for group chats.
  ///
  /// Example: "Nguyễn Văn A: Xong phần BE rồi"
  static String formatGroupBody({
    required String senderName,
    required String content,
  }) {
    return _l10n.notificationGroupBody(senderName, content);
  }

  /// Formats the body when current user is mentioned in a direct chat.
  ///
  /// Example: "@Bạn hãy kiểm tra lại nhé"
  static String formatMentionBody({required String content}) {
    return _l10n.notificationMentionPrefix(content);
  }

  /// Formats the body when current user is mentioned in a group chat.
  ///
  /// Example: "Nguyễn Văn A: @Bạn hãy kiểm tra lại nhé"
  static String formatGroupMentionBody({
    required String senderName,
    required String content,
  }) {
    return _l10n.notificationGroupMentionBody(senderName, content);
  }
}
