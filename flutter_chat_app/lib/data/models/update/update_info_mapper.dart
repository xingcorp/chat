import 'dart:io' show Platform;

import 'package:flutter_chat_app/core/constants/update_constants.dart';
import 'package:flutter_chat_app/data/models/update/github_release_dto.dart';
import 'package:flutter_chat_app/data/models/update/update_info_dto.dart';
import 'package:flutter_chat_app/data/utils/semantic_version.dart';
import 'package:flutter_chat_app/domain/entities/app_update_info.dart';

/// Maps update DTOs (GitHub Release or fallback JSON) to domain [AppUpdateInfo].
class UpdateInfoMapper {
  /// Convert GitHub Release DTO to Domain Entity.
  ///
  /// Determines the correct platform asset and checksum file from the release assets.
  /// The release body is parsed for optional metadata (force_update, min_supported_version)
  /// encoded as HTML comments:
  ///   `<!-- force_update: true -->`
  ///   `<!-- min_supported_version: 1.8.0 -->`
  static AppUpdateInfo? fromGitHubRelease(
    GitHubReleaseDto release, {
    String? checksumContent,
  }) {
    final assetPattern = Platform.isWindows
        ? UpdateConstants.windowsAssetPattern
        : UpdateConstants.macosAssetPattern;

    // Find the platform-specific installer asset (exclude checksum files)
    GitHubAssetDto? installerAsset;
    for (final asset in release.assets) {
      if (asset.name.endsWith(assetPattern) &&
          !asset.name.endsWith(UpdateConstants.checksumSuffix)) {
        installerAsset = asset;
        break;
      }
    }

    if (installerAsset == null) return null;

    // Parse version from tag
    final version = SemanticVersion.tryParse(release.tagName);
    if (version == null) return null;

    // Parse optional metadata from release body (HTML comments)
    final isForceUpdate =
        _parseMetadata(release.body, 'force_update') == 'true';
    final minSupported =
        _parseMetadata(release.body, 'min_supported_version') ?? '0.0.0';

    // Parse build number from tag (e.g., 'v2.1.0+92' -> 92)
    final buildNumber = _parseBuildNumber(release.tagName);

    return AppUpdateInfo(
      version: version.toString(),
      buildNumber: buildNumber,
      downloadUrl: installerAsset.browserDownloadUrl,
      releaseNotes: _cleanReleaseNotes(release.body),
      releaseDate: DateTime.tryParse(release.publishedAt) ?? DateTime.now(),
      fileSizeBytes: installerAsset.size,
      sha256Checksum: checksumContent?.trim() ?? '',
      isForceUpdate: isForceUpdate,
      minSupportedVersion: minSupported,
      htmlUrl: release.htmlUrl,
    );
  }

  /// Convert fallback JSON DTO to Domain Entity.
  static AppUpdateInfo? fromUpdateInfoDto(UpdateInfoDto dto) {
    final platformKey = Platform.isWindows ? 'windows' : 'macos';
    final platformInfo = dto.platforms[platformKey];

    if (platformInfo == null) return null;

    return AppUpdateInfo(
      version: dto.version,
      buildNumber: dto.buildNumber,
      downloadUrl: platformInfo.url,
      releaseNotes: dto.releaseNotes,
      releaseDate: DateTime.tryParse(dto.releaseDate) ?? DateTime.now(),
      fileSizeBytes: platformInfo.size,
      sha256Checksum: platformInfo.sha256,
      isForceUpdate: dto.forceUpdate,
      minSupportedVersion: dto.minSupportedVersion,
      htmlUrl: dto.htmlUrl,
    );
  }

  /// Find the checksum asset URL for a given installer asset.
  static String? findChecksumUrl(GitHubReleaseDto release, String installerName) {
    final checksumName = '$installerName${UpdateConstants.checksumSuffix}';
    for (final asset in release.assets) {
      if (asset.name == checksumName) {
        return asset.browserDownloadUrl;
      }
    }
    return null;
  }

  static String? _parseMetadata(String body, String key) {
    final regex = RegExp('<!--\\s*$key:\\s*(.+?)\\s*-->');
    return regex.firstMatch(body)?.group(1);
  }

  static int _parseBuildNumber(String tagName) {
    final plusIndex = tagName.indexOf('+');
    if (plusIndex == -1) return 0;
    return int.tryParse(tagName.substring(plusIndex + 1)) ?? 0;
  }

  static String _cleanReleaseNotes(String body) {
    // Remove metadata HTML comments from display text
    return body
        .replaceAll(RegExp(r'<!--\s*force_update:.*?-->'), '')
        .replaceAll(RegExp(r'<!--\s*min_supported_version:.*?-->'), '')
        .trim();
  }
}
