library;

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// **MEDIA ENUMS**
///
/// Enums for media components in the design system.
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Enum definitions with extension methods
///
/// **Usage**:
/// ```dart
/// FileUploadStatus.uploading
/// FileType.image
/// VideoQuality.hd720
/// 
/// // Get localized display name
/// fileStatus.getDisplayName(context)
/// fileType.getDisplayName(context)
/// ```

/// File upload status
enum FileUploadStatus {
  /// File is waiting to be uploaded
  pending,

  /// File is currently uploading
  uploading,

  /// File upload completed successfully
  completed,

  /// File upload failed
  failed,

  /// File upload was cancelled
  cancelled,
}

extension FileUploadStatusExtension on FileUploadStatus {
  /// Get localized display name
  String getDisplayName(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case FileUploadStatus.pending:
        return l10n.fileUploadStatusPending;
      case FileUploadStatus.uploading:
        return l10n.fileUploadStatusUploading;
      case FileUploadStatus.completed:
        return l10n.fileUploadStatusCompleted;
      case FileUploadStatus.failed:
        return l10n.fileUploadStatusFailed;
      case FileUploadStatus.cancelled:
        return l10n.fileUploadStatusCancelled;
    }
  }

  /// Whether upload is in progress
  bool get isInProgress => this == FileUploadStatus.uploading;

  /// Whether upload is complete
  bool get isComplete => this == FileUploadStatus.completed;

  /// Whether upload failed
  bool get isFailed => this == FileUploadStatus.failed;
}

/// File type categories
enum FileType {
  /// Image files (jpg, png, gif, etc.)
  image,

  /// Video files (mp4, mov, avi, etc.)
  video,

  /// Audio files (mp3, wav, etc.)
  audio,

  /// Document files (pdf, doc, etc.)
  document,

  /// Archive files (zip, rar, etc.)
  archive,

  /// Other file types
  other,
}

extension FileTypeExtension on FileType {
  /// Get localized display name
  String getDisplayName(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case FileType.image:
        return l10n.fileTypeImage;
      case FileType.video:
        return l10n.fileTypeVideo;
      case FileType.audio:
        return l10n.fileTypeAudio;
      case FileType.document:
        return l10n.fileTypeDocument;
      case FileType.archive:
        return l10n.fileTypeArchive;
      case FileType.other:
        return l10n.fileTypeOther;
    }
  }

  /// Get file extensions for this type
  List<String> get extensions {
    switch (this) {
      case FileType.image:
        return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
      case FileType.video:
        return ['mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv', 'webm'];
      case FileType.audio:
        return ['mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac'];
      case FileType.document:
        return ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'];
      case FileType.archive:
        return ['zip', 'rar', '7z', 'tar', 'gz'];
      case FileType.other:
        return [];
    }
  }

  /// Get MIME types for this type
  List<String> get mimeTypes {
    switch (this) {
      case FileType.image:
        return ['image/*'];
      case FileType.video:
        return ['video/*'];
      case FileType.audio:
        return ['audio/*'];
      case FileType.document:
        return [
          'application/pdf',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'application/vnd.ms-excel',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ];
      case FileType.archive:
        return [
          'application/zip',
          'application/x-rar-compressed',
          'application/x-7z-compressed',
        ];
      case FileType.other:
        return ['*/*'];
    }
  }
}

/// Video quality options
enum VideoQuality {
  /// Auto quality (adaptive)
  auto,

  /// 360p resolution
  p360,

  /// 480p resolution
  p480,

  /// 720p HD resolution
  p720,

  /// 1080p Full HD resolution
  p1080,
}

extension VideoQualityExtension on VideoQuality {
  /// Get display name
  String get displayName {
    switch (this) {
      case VideoQuality.auto:
        return 'Auto';
      case VideoQuality.p360:
        return '360p';
      case VideoQuality.p480:
        return '480p';
      case VideoQuality.p720:
        return '720p';
      case VideoQuality.p1080:
        return '1080p';
    }
  }

  /// Get resolution height
  int get height {
    switch (this) {
      case VideoQuality.auto:
        return 0;
      case VideoQuality.p360:
        return 360;
      case VideoQuality.p480:
        return 480;
      case VideoQuality.p720:
        return 720;
      case VideoQuality.p1080:
        return 1080;
    }
  }
}

/// Playback speed options
enum PlaybackSpeed {
  /// 0.5x speed
  half,

  /// 1x normal speed
  normal,

  /// 1.5x speed
  oneAndHalf,

  /// 2x speed
  double,
}

extension PlaybackSpeedExtension on PlaybackSpeed {
  /// Get display name
  String get displayName {
    switch (this) {
      case PlaybackSpeed.half:
        return '0.5x';
      case PlaybackSpeed.normal:
        return '1x';
      case PlaybackSpeed.oneAndHalf:
        return '1.5x';
      case PlaybackSpeed.double:
        return '2x';
    }
  }

  /// Get speed value
  double get value {
    switch (this) {
      case PlaybackSpeed.half:
        return 0.5;
      case PlaybackSpeed.normal:
        return 1.0;
      case PlaybackSpeed.oneAndHalf:
        return 1.5;
      case PlaybackSpeed.double:
        return 2.0;
    }
  }
}

/// Gallery layout mode
enum GalleryLayoutMode {
  /// Grid layout
  grid,

  /// List layout
  list,

  /// Masonry layout
  masonry,
}

extension GalleryLayoutModeExtension on GalleryLayoutMode {
  /// Get localized display name
  String getDisplayName(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case GalleryLayoutMode.grid:
        return l10n.galleryLayoutGrid;
      case GalleryLayoutMode.list:
        return l10n.galleryLayoutList;
      case GalleryLayoutMode.masonry:
        return l10n.galleryLayoutMasonry;
    }
  }
}

/// Emoji category
enum EmojiCategory {
  /// Recently used emojis
  recent,

  /// Smileys and people
  smileys,

  /// Animals and nature
  animals,

  /// Food and drink
  food,

  /// Travel and places
  travel,

  /// Activities
  activities,

  /// Objects
  objects,

  /// Symbols
  symbols,

  /// Flags
  flags,
}

extension EmojiCategoryExtension on EmojiCategory {
  /// Get localized display name
  String getDisplayName(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case EmojiCategory.recent:
        return l10n.emojiCategoryRecent;
      case EmojiCategory.smileys:
        return l10n.emojiCategorySmileys;
      case EmojiCategory.animals:
        return l10n.emojiCategoryAnimals;
      case EmojiCategory.food:
        return l10n.emojiCategoryFood;
      case EmojiCategory.travel:
        return l10n.emojiCategoryTravel;
      case EmojiCategory.activities:
        return l10n.emojiCategoryActivities;
      case EmojiCategory.objects:
        return l10n.emojiCategoryObjects;
      case EmojiCategory.symbols:
        return l10n.emojiCategorySymbols;
      case EmojiCategory.flags:
        return l10n.emojiCategoryFlags;
    }
  }

  /// Get icon for category
  String get icon {
    switch (this) {
      case EmojiCategory.recent:
        return '🕐';
      case EmojiCategory.smileys:
        return '😀';
      case EmojiCategory.animals:
        return '🐶';
      case EmojiCategory.food:
        return '🍔';
      case EmojiCategory.travel:
        return '✈️';
      case EmojiCategory.activities:
        return '⚽';
      case EmojiCategory.objects:
        return '💡';
      case EmojiCategory.symbols:
        return '❤️';
      case EmojiCategory.flags:
        return '🏁';
    }
  }
}

/// Skin tone options for emojis
enum SkinTone {
  /// Default (no skin tone modifier)
  none,

  /// Light skin tone
  light,

  /// Medium-light skin tone
  mediumLight,

  /// Medium skin tone
  medium,

  /// Medium-dark skin tone
  mediumDark,

  /// Dark skin tone
  dark,
}

extension SkinToneExtension on SkinTone {
  /// Get localized display name
  String getDisplayName(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case SkinTone.none:
        return l10n.skinToneDefault;
      case SkinTone.light:
        return l10n.skinToneLight;
      case SkinTone.mediumLight:
        return l10n.skinToneMediumLight;
      case SkinTone.medium:
        return l10n.skinToneMedium;
      case SkinTone.mediumDark:
        return l10n.skinToneMediumDark;
      case SkinTone.dark:
        return l10n.skinToneDark;
    }
  }

  /// Get Unicode modifier
  String get modifier {
    switch (this) {
      case SkinTone.none:
        return '';
      case SkinTone.light:
        return '\u{1F3FB}';
      case SkinTone.mediumLight:
        return '\u{1F3FC}';
      case SkinTone.medium:
        return '\u{1F3FD}';
      case SkinTone.mediumDark:
        return '\u{1F3FE}';
      case SkinTone.dark:
        return '\u{1F3FF}';
    }
  }

  /// Get emoji representation
  String get emoji {
    switch (this) {
      case SkinTone.none:
        return '👋';
      case SkinTone.light:
        return '👋🏻';
      case SkinTone.mediumLight:
        return '👋🏼';
      case SkinTone.medium:
        return '👋🏽';
      case SkinTone.mediumDark:
        return '👋🏾';
      case SkinTone.dark:
        return '👋🏿';
    }
  }
}
