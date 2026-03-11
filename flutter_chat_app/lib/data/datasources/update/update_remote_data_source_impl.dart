import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_chat_app/core/constants/update_constants.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/datasources/update/update_remote_data_source.dart';
import 'package:flutter_chat_app/data/models/update/github_release_dto.dart';
import 'package:flutter_chat_app/data/models/update/update_info_dto.dart';

/// Implementation of [UpdateRemoteDataSource] using Dio for HTTP calls.
///
/// Uses a dedicated [Dio] instance (not the app's [IHttpClient]) because:
/// - Update checks go to GitHub API (different base URL)
/// - No auth token needed (public repo)
/// - Download needs progress callback and cancel token
class UpdateRemoteDataSourceImpl implements UpdateRemoteDataSource {
  UpdateRemoteDataSourceImpl() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'OxiiChat-Updater',
    },
  ));

  final Dio _dio;
  CancelToken? _downloadCancelToken;
  DateTime? _downloadStartTime;
  int _lastLoggedPercent = -1;

  @override
  Future<GitHubReleaseDto> getLatestGitHubRelease() async {
    final url =
        '${UpdateConstants.githubApiBaseUrl}/repos/'
        '${UpdateConstants.githubOwner}/${UpdateConstants.githubRepo}'
        '/releases/latest';

    LogUtils.d('UpdateRemoteDataSource', 'Checking for updates at: $url');

    final response = await _dio.get<Map<String, dynamic>>(url);

    if (response.data == null) {
      throw Exception('Empty response from GitHub API');
    }

    return GitHubReleaseDto.fromJson(response.data!);
  }

  @override
  Future<String> getChecksumForAsset(String checksumUrl) async {
    final response = await _dio.get<String>(checksumUrl);
    final content = response.data ?? '';
    // Checksum files typically contain: 'sha256hash  filename'
    return content.split(RegExp(r'\s+')).first;
  }

  @override
  Future<UpdateInfoDto> getLatestFromFallback() async {
    final response = await _dio.get<Map<String, dynamic>>(
      UpdateConstants.fallbackUpdateUrl,
    );

    if (response.data == null) {
      throw Exception('Empty response from fallback endpoint');
    }

    return UpdateInfoDto.fromJson(response.data!);
  }

  @override
  Future<String> downloadFile({
    required String url,
    required String savePath,
    required void Function(int received, int total) onProgress,
  }) async {
    _downloadCancelToken = CancelToken();
    _downloadStartTime = DateTime.now();
    _lastLoggedPercent = -1;

    // Ensure download directory exists
    final dir = Directory(savePath).parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    LogUtils.i('UpdateRemoteDataSource', 'Downloading update: $url -> $savePath');

    await _dio.download(
      url,
      savePath,
      cancelToken: _downloadCancelToken,
      // Override receiveTimeout for large file downloads — the default 30s
      // timeout applies to gaps between data packets, which is too short
      // for slow connections downloading large installers.
      options: Options(
        receiveTimeout: const Duration(minutes: 10),
      ),
      onReceiveProgress: (received, total) {
        // Log progress every 10% or when total is unknown
        if (total > 0) {
          final percent = (received * 100 ~/ total);
          if (percent ~/ 10 > _lastLoggedPercent ~/ 10) {
            _lastLoggedPercent = percent;
            final elapsed = DateTime.now().difference(_downloadStartTime!);
            final speedMBps = elapsed.inMilliseconds > 0
                ? (received / 1024 / 1024) / (elapsed.inMilliseconds / 1000)
                : 0.0;
            final receivedMB = (received / (1024 * 1024)).toStringAsFixed(1);
            final totalMB = (total / (1024 * 1024)).toStringAsFixed(1);
            LogUtils.d('UpdateRemoteDataSource',
                'Download progress: $percent% ($receivedMB/$totalMB MB) '
                'speed: ${speedMBps.toStringAsFixed(2)} MB/s '
                'elapsed: ${elapsed.inSeconds}s');
          }
        } else {
          // Total unknown — log every 5MB
          final receivedMB = received ~/ (1024 * 1024);
          if (receivedMB > 0 && receivedMB % 5 == 0) {
            LogUtils.d('UpdateRemoteDataSource',
                'Download progress: ${receivedMB}MB received (total unknown)');
          }
        }
        onProgress(received, total);
      },
    );

    final fileSize = File(savePath).lengthSync();
    final totalElapsed = DateTime.now().difference(_downloadStartTime!);
    LogUtils.i('UpdateRemoteDataSource',
        'Download complete: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB '
        'in ${totalElapsed.inSeconds}s');

    _downloadCancelToken = null;
    _downloadStartTime = null;
    _lastLoggedPercent = -1;
    return savePath;
  }

  @override
  void cancelDownload() {
    if (_downloadCancelToken != null && !_downloadCancelToken!.isCancelled) {
      _downloadCancelToken!.cancel('User cancelled download');
    }
    _downloadCancelToken = null;
  }
}
