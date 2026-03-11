import 'package:equatable/equatable.dart';

/// Domain entity representing an available app update.
///
/// Pure Dart — no Flutter imports.
class AppUpdateInfo extends Equatable {
  const AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.releaseDate,
    required this.fileSizeBytes,
    required this.sha256Checksum,
    required this.isForceUpdate,
    required this.minSupportedVersion,
    this.htmlUrl,
  });

  /// Semantic version string, e.g. '2.1.0'
  final String version;

  /// Build number, e.g. 92
  final int buildNumber;

  /// Direct download URL for the platform-specific installer
  final String downloadUrl;

  /// Markdown-formatted release notes
  final String releaseNotes;

  /// When this release was published
  final DateTime releaseDate;

  /// Size of the download in bytes (for progress UI)
  final int fileSizeBytes;

  /// SHA-256 hex digest for integrity verification
  final String sha256Checksum;

  /// If true, user CANNOT skip or dismiss — must update
  final bool isForceUpdate;

  /// Versions below this are forced to update (e.g. '1.8.0')
  final String minSupportedVersion;

  /// URL to the release page (for 'View on GitHub' link)
  final String? htmlUrl;

  /// Human-readable file size (e.g. '28.5 MB')
  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
        version,
        buildNumber,
        downloadUrl,
        releaseNotes,
        releaseDate,
        fileSizeBytes,
        sha256Checksum,
        isForceUpdate,
        minSupportedVersion,
        htmlUrl,
      ];
}
