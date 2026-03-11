import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_chat_app/core/constants/update_constants.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/services/update_installer_service.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/datasources/update/update_remote_data_source.dart';
import 'package:flutter_chat_app/data/models/update/update_info_mapper.dart';
import 'package:flutter_chat_app/data/utils/semantic_version.dart';
import 'package:flutter_chat_app/domain/entities/app_update_info.dart';
import 'package:flutter_chat_app/domain/repositories/i_update_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Concrete implementation of [IUpdateRepository].
///
/// - Checks GitHub Releases API for newer versions
/// - Falls back to static JSON endpoint if GitHub is unavailable
/// - Downloads installer with progress callback
/// - Verifies SHA-256 checksum
/// - Delegates platform-specific installation to [UpdateInstallerService]
/// - Persists skip/remind-later preferences via SharedPreferences
class UpdateRepositoryImpl implements IUpdateRepository {
  UpdateRepositoryImpl({
    required UpdateRemoteDataSource remoteDataSource,
    required UpdateInstallerService installerService,
    required SharedPreferences prefs,
  })  : _remoteDataSource = remoteDataSource,
        _installerService = installerService,
        _prefs = prefs;

  final UpdateRemoteDataSource _remoteDataSource;
  final UpdateInstallerService _installerService;
  final SharedPreferences _prefs;

  @override
  Future<Either<Failure, AppUpdateInfo?>> checkForUpdate() async {
    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = SemanticVersion.parse(packageInfo.version);

      LogUtils.i('UpdateRepository', 'Current version: $currentVersion');

      // 2. Try GitHub first, fallback to JSON endpoint
      AppUpdateInfo? updateInfo;
      try {
        updateInfo = await _checkGitHub();
      } catch (e) {
        LogUtils.w('UpdateRepository', 'GitHub check failed, trying fallback: $e');
        try {
          updateInfo = await _checkFallback();
        } catch (e2) {
          LogUtils.e('UpdateRepository', 'Fallback check also failed: $e2');
          return Left(UpdateFailure(
            message: 'Failed to check for updates: $e2',
            code: 'check_failed',
          ));
        }
      }

      if (updateInfo == null) {
        LogUtils.i('UpdateRepository', 'No update asset found for this platform');
        return const Right(null);
      }

      // 3. Compare versions
      final latestVersion = SemanticVersion.tryParse(updateInfo.version);
      if (latestVersion == null || !latestVersion.isNewerThan(currentVersion)) {
        LogUtils.i('UpdateRepository', 'Already up to date ($currentVersion >= ${updateInfo.version})');
        return const Right(null);
      }

      // 4. Check if version is skipped
      final skippedVersion = _prefs.getString(UpdateConstants.prefSkippedVersion);
      if (skippedVersion == updateInfo.version && !updateInfo.isForceUpdate) {
        LogUtils.i('UpdateRepository', 'Version ${updateInfo.version} is skipped by user');
        return const Right(null);
      }

      // 5. Check 'remind me later'
      final remindLaterTs = _prefs.getInt(UpdateConstants.prefRemindLaterTimestamp);
      if (remindLaterTs != null && !updateInfo.isForceUpdate) {
        final remindLaterTime = DateTime.fromMillisecondsSinceEpoch(remindLaterTs);
        if (DateTime.now().isBefore(remindLaterTime)) {
          LogUtils.i('UpdateRepository', 'Remind later active until $remindLaterTime');
          return const Right(null);
        }
      }

      // 6. Check force update via min_supported_version
      final minVersion = SemanticVersion.tryParse(updateInfo.minSupportedVersion);
      if (minVersion != null && currentVersion.isOlderThan(minVersion)) {
        // Current version is below minimum — force update
        updateInfo = AppUpdateInfo(
          version: updateInfo.version,
          buildNumber: updateInfo.buildNumber,
          downloadUrl: updateInfo.downloadUrl,
          releaseNotes: updateInfo.releaseNotes,
          releaseDate: updateInfo.releaseDate,
          fileSizeBytes: updateInfo.fileSizeBytes,
          sha256Checksum: updateInfo.sha256Checksum,
          isForceUpdate: true,
          minSupportedVersion: updateInfo.minSupportedVersion,
          htmlUrl: updateInfo.htmlUrl,
        );
      }

      LogUtils.i('UpdateRepository', 'Update available: ${updateInfo.version} (force=${updateInfo.isForceUpdate})');
      return Right(updateInfo);
    } catch (e) {
      return Left(UpdateFailure(
        message: 'Unexpected error checking for updates: $e',
        code: 'check_failed',
      ));
    }
  }

  @override
  Future<Either<Failure, String>> downloadUpdate({
    required AppUpdateInfo updateInfo,
    required void Function(int received, int total) onProgress,
  }) async {
    try {
      final tempDir = Directory.systemTemp;
      final downloadDir = Directory('${tempDir.path}/${UpdateConstants.downloadSubDir}');
      if (!downloadDir.existsSync()) {
        downloadDir.createSync(recursive: true);
      }

      // Extract filename from URL
      final uri = Uri.parse(updateInfo.downloadUrl);
      final fileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'OxiiChat_update${Platform.isWindows ? ".exe" : ".dmg"}';

      final savePath = '${downloadDir.path}/$fileName';

      LogUtils.i('UpdateRepository', 'Downloading to: $savePath');

      final resultPath = await _remoteDataSource.downloadFile(
        url: updateInfo.downloadUrl,
        savePath: savePath,
        onProgress: onProgress,
      );

      return Right(resultPath);
    } on Exception catch (e) {
      if (e.toString().contains('cancelled') || e.toString().contains('cancel')) {
        return Left(UpdateFailure(
          message: 'Download cancelled',
          code: 'cancelled',
        ));
      }
      return Left(UpdateFailure(
        message: 'Download failed: $e',
        code: 'download_failed',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyDownload({
    required String filePath,
    required String expectedChecksum,
  }) async {
    try {
      if (expectedChecksum.isEmpty) {
        // No checksum available — skip verification
        LogUtils.w('UpdateRepository', 'No checksum provided, skipping verification');
        return const Right(true);
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        return Left(UpdateFailure(
          message: 'Downloaded file not found: $filePath',
          code: 'verification_failed',
        ));
      }

      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      final actualChecksum = digest.toString();

      final isValid = actualChecksum.toLowerCase() == expectedChecksum.toLowerCase();

      if (!isValid) {
        LogUtils.e('UpdateRepository',
          'Checksum mismatch! Expected: $expectedChecksum, Got: $actualChecksum');
        // Delete corrupted file
        await file.delete();
      } else {
        LogUtils.i('UpdateRepository', 'Checksum verified successfully');
      }

      return Right(isValid);
    } catch (e) {
      return Left(UpdateFailure(
        message: 'Verification failed: $e',
        code: 'verification_failed',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> installUpdate({
    required String installerPath,
  }) async {
    try {
      await _installerService.launchInstallerAndExit(installerPath);
      return const Right(null);
    } catch (e) {
      return Left(UpdateFailure(
        message: 'Failed to launch installer: $e',
        code: 'install_failed',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> cancelDownload() async {
    try {
      _remoteDataSource.cancelDownload();
      return const Right(null);
    } catch (e) {
      return Left(UpdateFailure(
        message: 'Failed to cancel download: $e',
        code: 'cancelled',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> skipVersion(String version) async {
    try {
      await _prefs.setString(UpdateConstants.prefSkippedVersion, version);
      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to skip version: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getSkippedVersion() async {
    try {
      return Right(_prefs.getString(UpdateConstants.prefSkippedVersion));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to get skipped version: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setRemindLaterTimestamp(DateTime timestamp) async {
    try {
      await _prefs.setInt(
        UpdateConstants.prefRemindLaterTimestamp,
        timestamp.millisecondsSinceEpoch,
      );
      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to set remind later: $e'));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getRemindLaterTimestamp() async {
    try {
      final ts = _prefs.getInt(UpdateConstants.prefRemindLaterTimestamp);
      if (ts == null) return const Right(null);
      return Right(DateTime.fromMillisecondsSinceEpoch(ts));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to get remind later: $e'));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getLastCheckTimestamp() async {
    try {
      final ts = _prefs.getInt(UpdateConstants.prefLastCheckTimestamp);
      if (ts == null) return const Right(null);
      return Right(DateTime.fromMillisecondsSinceEpoch(ts));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to get last check: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setLastCheckTimestamp(DateTime timestamp) async {
    try {
      await _prefs.setInt(
        UpdateConstants.prefLastCheckTimestamp,
        timestamp.millisecondsSinceEpoch,
      );
      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to set last check: $e'));
    }
  }

  // ═══════════════════════════════════════════
  // Private helpers
  // ═══════════════════════════════════════════

  Future<AppUpdateInfo?> _checkGitHub() async {
    final release = await _remoteDataSource.getLatestGitHubRelease();

    // Skip draft and pre-release
    if (release.draft || release.prerelease) return null;

    // Try to get checksum
    String? checksum;
    final assetPattern = Platform.isWindows
        ? UpdateConstants.windowsAssetPattern
        : UpdateConstants.macosAssetPattern;

    // Find installer asset name
    String? installerName;
    for (final asset in release.assets) {
      if (asset.name.endsWith(assetPattern) &&
          !asset.name.endsWith(UpdateConstants.checksumSuffix)) {
        installerName = asset.name;
        break;
      }
    }

    if (installerName != null) {
      final checksumUrl = UpdateInfoMapper.findChecksumUrl(release, installerName);
      if (checksumUrl != null) {
        try {
          checksum = await _remoteDataSource.getChecksumForAsset(checksumUrl);
        } catch (e) {
          LogUtils.w('UpdateRepository', 'Could not fetch checksum: $e');
        }
      }
    }

    return UpdateInfoMapper.fromGitHubRelease(release, checksumContent: checksum);
  }

  Future<AppUpdateInfo?> _checkFallback() async {
    final dto = await _remoteDataSource.getLatestFromFallback();
    return UpdateInfoMapper.fromUpdateInfoDto(dto);
  }
}
