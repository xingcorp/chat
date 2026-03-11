import 'package:flutter_chat_app/data/models/update/github_release_dto.dart';
import 'package:flutter_chat_app/data/models/update/update_info_dto.dart';

/// Interface for fetching update information from remote sources.
abstract class UpdateRemoteDataSource {
  /// Fetch the latest release from GitHub Releases API.
  Future<GitHubReleaseDto> getLatestGitHubRelease();

  /// Fetch the SHA-256 checksum file content for a specific asset.
  Future<String> getChecksumForAsset(String checksumUrl);

  /// Fetch update info from the fallback JSON endpoint.
  Future<UpdateInfoDto> getLatestFromFallback();

  /// Download the installer file to [savePath].
  /// [onProgress] receives (receivedBytes, totalBytes).
  /// Returns the final path of the downloaded file.
  Future<String> downloadFile({
    required String url,
    required String savePath,
    required void Function(int received, int total) onProgress,
  });

  /// Cancel the current in-progress download.
  void cancelDownload();
}
