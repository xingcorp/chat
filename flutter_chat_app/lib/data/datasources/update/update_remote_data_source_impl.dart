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
      onReceiveProgress: (received, total) {
        onProgress(received, total);
      },
    );

    _downloadCancelToken = null;
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
