library;

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
  /// Get display name
  String get displayName {
    switch (this) {
      case FileUploadStatus.pending:
        return 'Pending';
      case FileUploadStatus.uploading:
        return 'Uploading';
      case FileUploadStatus.completed:
        return 'Completed';
      case FileUploadStatus.failed:
        return 'Failed';
      case FileUploadStatus.cancelled:
        return 'Cancelled';
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
  /// Get display name
  String get displayName {
    switch (this) {
      case FileType.image:
        return 'Image';
      case FileType.video:
        return 'Video';
      case FileType.audio:
        return 'Audio';
      case FileType.document:
        return 'Document';
      case FileType.archive:
        return 'Archive';
      case FileType.other:
        return 'Other';
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
  /// 360p resolution
  sd360,

  /// 480p resolution
  sd480,

  /// 720p HD resolution
  hd720,

  /// 1080p Full HD resolution
  hd1080,

  /// 1440p 2K resolution
  hd1440,

  /// 2160p 4K resolution
  uhd4k,

  /// Auto quality (adaptive)
  auto,
}

extension VideoQualityExtension on VideoQuality {
  /// Get display name
  String get displayName {
    switch (this) {
      case VideoQuality.sd360:
        return '360p';
      case VideoQuality.sd480:
        return '480p';
      case VideoQuality.hd720:
        return '720p HD';
      case VideoQuality.hd1080:
        return '1080p Full HD';
      case VideoQuality.hd1440:
        return '1440p 2K';
      case VideoQuality.uhd4k:
        return '4K Ultra HD';
      case VideoQuality.auto:
        return 'Auto';
    }
  }

  /// Get resolution height
  int get height {
    switch (this) {
      case VideoQuality.sd360:
        return 360;
      case VideoQuality.sd480:
        return 480;
      case VideoQuality.hd720:
        return 720;
      case VideoQuality.hd1080:
        return 1080;
      case VideoQuality.hd1440:
        return 1440;
      case VideoQuality.uhd4k:
        return 2160;
      case VideoQuality.auto:
        return 0;
    }
  }
}

/// Playback speed options
enum PlaybackSpeed {
  /// 0.25x speed
  x025,

  /// 0.5x speed
  x050,

  /// 0.75x speed
  x075,

  /// 1x normal speed
  x100,

  /// 1.25x speed
  x125,

  /// 1.5x speed
  x150,

  /// 1.75x speed
  x175,

  /// 2x speed
  x200,
}

extension PlaybackSpeedExtension on PlaybackSpeed {
  /// Get display name
  String get displayName {
    switch (this) {
      case PlaybackSpeed.x025:
        return '0.25x';
      case PlaybackSpeed.x050:
        return '0.5x';
      case PlaybackSpeed.x075:
        return '0.75x';
      case PlaybackSpeed.x100:
        return '1x';
      case PlaybackSpeed.x125:
        return '1.25x';
      case PlaybackSpeed.x150:
        return '1.5x';
      case PlaybackSpeed.x175:
        return '1.75x';
      case PlaybackSpeed.x200:
        return '2x';
    }
  }

  /// Get speed value
  double get value {
    switch (this) {
      case PlaybackSpeed.x025:
        return 0.25;
      case PlaybackSpeed.x050:
        return 0.5;
      case PlaybackSpeed.x075:
        return 0.75;
      case PlaybackSpeed.x100:
        return 1.0;
      case PlaybackSpeed.x125:
        return 1.25;
      case PlaybackSpeed.x150:
        return 1.5;
      case PlaybackSpeed.x175:
        return 1.75;
      case PlaybackSpeed.x200:
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
  /// Get display name
  String get displayName {
    switch (this) {
      case GalleryLayoutMode.grid:
        return 'Grid';
      case GalleryLayoutMode.list:
        return 'List';
      case GalleryLayoutMode.masonry:
        return 'Masonry';
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
  /// Get display name
  String get displayName {
    switch (this) {
      case EmojiCategory.recent:
        return 'Recent';
      case EmojiCategory.smileys:
        return 'Smileys & People';
      case EmojiCategory.animals:
        return 'Animals & Nature';
      case EmojiCategory.food:
        return 'Food & Drink';
      case EmojiCategory.travel:
        return 'Travel & Places';
      case EmojiCategory.activities:
        return 'Activities';
      case EmojiCategory.objects:
        return 'Objects';
      case EmojiCategory.symbols:
        return 'Symbols';
      case EmojiCategory.flags:
        return 'Flags';
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
  /// Get display name
  String get displayName {
    switch (this) {
      case SkinTone.none:
        return 'Default';
      case SkinTone.light:
        return 'Light';
      case SkinTone.mediumLight:
        return 'Medium Light';
      case SkinTone.medium:
        return 'Medium';
      case SkinTone.mediumDark:
        return 'Medium Dark';
      case SkinTone.dark:
        return 'Dark';
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
