import 'dart:async';
import 'dart:isolate';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:flutter_chat_app/core/monitoring/i_crash_reporter.dart';

/// Firebase-backed crash reporting implementation.
///
/// Implements [ICrashReporter] using Firebase Crashlytics SDK.
/// For environments without Firebase, use [NoOpCrashReporter] instead.
@LazySingleton(as: ICrashReporter)
class CrashReporter implements ICrashReporter {
  /// Logger
  final _logger = Logger();
  
  /// Crashlytics instance (nullable for stub implementations)
  final FirebaseCrashlytics? _crashlytics;
  
  /// Package info
  late PackageInfo _packageInfo;
  
  /// Có đang dùng crashlytics không
  bool _isCrashlyticsEnabled = true;
  
  /// Constructor
  CrashReporter(this._crashlytics);
  
  /// Khởi tạo crash reporter
  @override
  Future<void> initialize() async {
    try {
      _logger.i('Khởi tạo Crash Reporter');
      
      // Lấy thông tin package
      _packageInfo = await PackageInfo.fromPlatform();
      
      // Không kích hoạt Crashlytics trong debug mode
      _isCrashlyticsEnabled = !kDebugMode;
      
      // Cấu hình Crashlytics (if available)
      if (_crashlytics != null) {
        await _crashlytics!.setCrashlyticsCollectionEnabled(_isCrashlyticsEnabled);

        // Thêm thông tin phiên bản
        await _crashlytics!.setCustomKey('app_version', _packageInfo.version);
        await _crashlytics!.setCustomKey('build_number', _packageInfo.buildNumber);
      }
      
      // Ghi lại unhandled errors từ Flutter framework
      FlutterError.onError = _handleFlutterError;
      
      // Ghi lại unhandled errors từ Dart runtime
      Isolate.current.addErrorListener(RawReceivePort(_handleIsolateError).sendPort);
      
      // Ghi lại unhandled errors từ Zone
      PlatformDispatcher.instance.onError = (error, stack) {
        _handleZoneError(error, stack);
        return true;
      };
      
      _logger.i('Crash Reporter đã được khởi tạo. Bật Crashlytics: $_isCrashlyticsEnabled');
    } catch (e, stackTrace) {
      _logger.e('Lỗi khi khởi tạo Crash Reporter: $e');
      _recordError(e, stackTrace, reason: 'initialize_crash_reporter_failed');
    }
  }
  
  /// Xử lý error từ Flutter framework
  void _handleFlutterError(FlutterErrorDetails details) {
    _logger.e('Flutter Error: ${details.exception}');
    
    if (_isCrashlyticsEnabled && _crashlytics != null) {
      _crashlytics!.recordFlutterError(details);
    } else {
      FlutterError.presentError(details);
    }
  }
  
  /// Xử lý error từ Isolate
  void _handleIsolateError(dynamic errorAndStacktracePair) {
    final errorAndStacktrace = errorAndStacktracePair as List<dynamic>;
    final error = errorAndStacktrace[0];
    final stackTrace = StackTrace.fromString(errorAndStacktrace[1].toString());
    
    _logger.e('Isolate Error: $error');
    _recordError(error, stackTrace, reason: 'isolate_error');
  }
  
  /// Xử lý error từ Zone
  void _handleZoneError(Object error, StackTrace stackTrace) {
    _logger.e('Zone Error: $error');
    _recordError(error, stackTrace, reason: 'zone_error');
  }
  
  /// Ghi lại error vào Crashlytics
  void _recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object>? information,
  }) {
    if (_isCrashlyticsEnabled && _crashlytics != null) {
      _crashlytics!.recordError(
        exception,
        stackTrace,
        reason: reason,
        information: information ?? [],
        printDetails: !kReleaseMode,
      );
    }
  }
  
  /// Ghi lại error tường minh (từ try-catch)
  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace stackTrace, {
    String? reason,
    Map<String, dynamic>? additionalData,
  }) async {
    _logger.e('Explicit Error: $exception, Reason: $reason');
    
    try {
      if (_isCrashlyticsEnabled) {
        // Thêm dữ liệu custom nếu có
        if (additionalData != null && _crashlytics != null) {
          for (final entry in additionalData.entries) {
            await _crashlytics!.setCustomKey(entry.key, entry.value.toString());
          }
        }
        
        // Ghi lại error
        _recordError(
          exception,
          stackTrace,
          reason: reason,
        );
      }
    } catch (e) {
      _logger.e('Error when recording error to Crashlytics: $e');
    }
  }
  
  /// Đặt thông tin user cho phiên hiện tại
  @override
  Future<void> setUserIdentifier(String userId) async {
    if (_isCrashlyticsEnabled && _crashlytics != null) {
      await _crashlytics!.setUserIdentifier(userId);
    }
  }
  
  /// Đặt custom key
  @override
  Future<void> setCustomKey(String key, dynamic value) async {
    if (_isCrashlyticsEnabled && _crashlytics != null) {
      await _crashlytics!.setCustomKey(key, value);
    }
  }
  
  /// Ghi log vào Crashlytics
  @override
  Future<void> log(String message) async {
    if (_isCrashlyticsEnabled && _crashlytics != null) {
      await _crashlytics!.log(message);
    }
  }
  
  /// Tạo crash test để kiểm tra
  Future<void> testCrash() async {
    if (_isCrashlyticsEnabled && _crashlytics != null) {
      _crashlytics!.crash();
    } else {
      _logger.w('Crashlytics disabled in debug mode. No test crash will occur.');
      throw Exception('Test Crash');
    }
  }
} 