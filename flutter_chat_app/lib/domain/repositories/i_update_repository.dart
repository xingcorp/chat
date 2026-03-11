import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/entities/app_update_info.dart';

/// Repository contract for app update operations.
///
/// Returns `Right(null)` from [checkForUpdate] when no update is available.
/// [onProgress] callbacks provide (receivedBytes, totalBytes).
abstract class IUpdateRepository {
  /// Check if a newer version is available.
  /// Returns Right(AppUpdateInfo) if update available, Right(null) if up-to-date.
  Future<Either<Failure, AppUpdateInfo?>> checkForUpdate();

  /// Download the update installer to a temp directory.
  /// [onProgress] is called with (received, total) bytes.
  /// Returns the local file path of the downloaded installer.
  Future<Either<Failure, String>> downloadUpdate({
    required AppUpdateInfo updateInfo,
    required void Function(int received, int total) onProgress,
  });

  /// Verify the downloaded file against the expected SHA-256 checksum.
  Future<Either<Failure, bool>> verifyDownload({
    required String filePath,
    required String expectedChecksum,
  });

  /// Launch the installer and exit the app.
  Future<Either<Failure, void>> installUpdate({
    required String installerPath,
  });

  /// Cancel an in-progress download.
  Future<Either<Failure, void>> cancelDownload();

  /// Mark a version as 'skipped' so it will not be shown again.
  Future<Either<Failure, void>> skipVersion(String version);

  /// Get the version the user chose to skip, if any.
  Future<Either<Failure, String?>> getSkippedVersion();

  /// Store 'remind me later' timestamp.
  Future<Either<Failure, void>> setRemindLaterTimestamp(DateTime timestamp);

  /// Get 'remind me later' timestamp.
  Future<Either<Failure, DateTime?>> getRemindLaterTimestamp();

  /// Get the last time we checked for updates.
  Future<Either<Failure, DateTime?>> getLastCheckTimestamp();

  /// Store the last check timestamp.
  Future<Either<Failure, void>> setLastCheckTimestamp(DateTime timestamp);
}
