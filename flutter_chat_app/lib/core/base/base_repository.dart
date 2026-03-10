import 'dart:async';

import 'package:flutter_chat_app/core/error/error_handler.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/core/monitoring/i_performance_monitor.dart';

/// **ENTERPRISE-GRADE BASE REPOSITORY**
///
/// Provides unified data access patterns with comprehensive error handling,
/// performance monitoring, and multiple data fetching strategies.
///
/// **Strategies Available:**
/// - executeOnlineFirst: Real-time data (messages, status updates)
/// - executeOfflineFirst: Cached data (chat history, profiles)
/// - executeRemoteOnly: Fresh server data (auth, config)
/// - executeLocalOnly: Local preferences, drafts
/// - executeSyncStrategy: Background synchronization
abstract class BaseRepository {
  final NetworkInfo networkInfo;
  final AppLogger logger;
  final IPerformanceMonitor performanceMonitor;

  BaseRepository({
    required this.networkInfo,
    required this.logger,
    required this.performanceMonitor,
  });
  
  /// **ONLINE-FIRST STRATEGY**
  ///
  /// Use for real-time data that should be fresh when possible:
  /// - New messages, user status updates
  /// - Operations requiring server confirmation
  /// - Data that changes frequently
  ///
  /// **Flow**: Remote → Local fallback → Error handling
  /// **Performance**: Monitored with operation timing
  Future<Either<Failure, T>> executeOnlineFirst<T>({
    required Future<T> Function() remoteDataSource,
    required Future<T> Function() localDataSource,
    Future<void> Function(T)? cacheData,
    String? operationName,
  }) async {
    return _executeWithMonitoring<T>(
      operation: () => _executeOnlineFirstInternal<T>(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
        cacheData: cacheData,
      ),
      operationName: operationName ?? 'executeOnlineFirst',
    );
  }

  /// Internal implementation of online-first strategy
  Future<Either<Failure, T>> _executeOnlineFirstInternal<T>({
    required Future<T> Function() remoteDataSource,
    required Future<T> Function() localDataSource,
    Future<void> Function(T)? cacheData,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteData = await remoteDataSource();
        
        // Cache dữ liệu nếu cần
        if (cacheData != null) {
          await cacheData(remoteData);
        }
        
        return Right(remoteData);
      } catch (e) {
        LogUtils.e('Repository', 'Remote data source error: $e');
        // Fallback to local data source if remote fails
        try {
          final localData = await localDataSource();
          return Right(localData);
        } catch (localError) {
          LogUtils.e('Repository', 'Local data source error: $localError');
          // Use ErrorHandler to properly map the original remote exception
          return Left(ErrorHandler.mapExceptionToFailure(e, context: 'executeOnlineFirst'));
        }
      }
    } else {
      try {
        final localData = await localDataSource();
        return Right(localData);
      } catch (e) {
        LogUtils.e('Repository', 'Local data source error: $e');
        return const Left(ConnectionFailure(message: 'No internet connection and no cached data'));
      }
    }
  }
  
  /// **OFFLINE-FIRST STRATEGY**
  ///
  /// Use for cached data that should be available immediately:
  /// - Chat history, user profiles, settings
  /// - Data that doesn't change frequently
  /// - Bulk data that's expensive to fetch
  ///
  /// **Flow**: Local immediate → Background remote sync
  /// **Performance**: Monitored with operation timing
  Future<Either<Failure, T>> executeOfflineFirst<T>({
    required Future<T> Function() remoteDataSource,
    required Future<T> Function() localDataSource,
    Future<void> Function(T)? cacheData,
    String? operationName,
  }) async {
    return _executeWithMonitoring<T>(
      operation: () => _executeOfflineFirstInternal<T>(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
        cacheData: cacheData,
      ),
      operationName: operationName ?? 'executeOfflineFirst',
    );
  }

  /// Internal implementation of offline-first strategy
  Future<Either<Failure, T>> _executeOfflineFirstInternal<T>({
    required Future<T> Function() remoteDataSource,
    required Future<T> Function() localDataSource,
    Future<void> Function(T)? cacheData,
  }) async {
    try {
      // Luôn lấy dữ liệu từ local trước
      final localData = await localDataSource();
      
      // Nếu có kết nối internet, cập nhật dữ liệu từ remote và lưu vào cache
      if (await networkInfo.isConnected) {
        unawaited(_updateCacheFromRemote<T>(
          remoteDataSource: remoteDataSource, 
          cacheData: cacheData
        ));
      }
      
      return Right(localData);
    } catch (e) {
      LogUtils.e('Repository', 'Local data source error: $e');
      
      // Nếu local thất bại và có kết nối, thử lấy từ remote
      if (await networkInfo.isConnected) {
        try {
          final remoteData = await remoteDataSource();
          
          // Cache dữ liệu nếu cần
          if (cacheData != null) {
            await cacheData(remoteData);
          }
          
          return Right(remoteData);
        } catch (e) {
          LogUtils.e('Repository', 'Remote data source error: $e');
          return Left(ErrorHandler.mapExceptionToFailure(e, context: 'executeOfflineFirst'));
        }
      } else {
        return const Left(ConnectionFailure(message: 'No internet connection and no cached data'));
      }
    }
  }
  
  /// Phương thức cập nhật cache từ nguồn dữ liệu từ xa
  Future<void> _updateCacheFromRemote<T>({
    required Future<T> Function() remoteDataSource,
    Future<void> Function(T)? cacheData,
  }) async {
    try {
      final remoteData = await remoteDataSource();
      
      // Cache dữ liệu nếu cần
      if (cacheData != null) {
        await cacheData(remoteData);
      }
    } catch (e) {
      LogUtils.e('Repository', 'Update cache from remote error: $e');
    }
  }
  
  /// **REMOTE-ONLY STRATEGY**
  ///
  /// Use for data that must always be fresh from server:
  /// - Authentication tokens, server configuration
  /// - Security-sensitive operations
  /// - One-time operations
  Future<Either<Failure, T>> executeRemoteOnly<T>({
    required Future<T> Function() remoteDataSource,
    Future<void> Function(T)? cacheData,
    String? operationName,
  }) async {
    return _executeWithMonitoring<T>(
      operation: () => _executeRemoteOnlyInternal<T>(
        remoteDataSource: remoteDataSource,
        cacheData: cacheData,
      ),
      operationName: operationName ?? 'executeRemoteOnly',
    );
  }

  /// Internal implementation of remote-only strategy
  Future<Either<Failure, T>> _executeRemoteOnlyInternal<T>({
    required Future<T> Function() remoteDataSource,
    Future<void> Function(T)? cacheData,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteData = await remoteDataSource();

        // Cache dữ liệu nếu cần
        if (cacheData != null) {
          await cacheData(remoteData);
        }

        return Right(remoteData);
      } catch (e) {
        logger.e('Remote data source error: $e');
        return Left(ErrorHandler.mapExceptionToFailure(e, context: 'executeRemoteOnly'));
      }
    } else {
      return const Left(ConnectionFailure(message: 'No internet connection'));
    }
  }
  
  /// **LOCAL-ONLY STRATEGY**
  ///
  /// Use for data that should only be stored locally:
  /// - User preferences, drafts, temporary data
  /// - Privacy-sensitive information
  /// - App-specific settings
  Future<Either<Failure, T>> executeLocalOnly<T>({
    required Future<T> Function() localDataSource,
    String? operationName,
  }) async {
    return _executeWithMonitoring<T>(
      operation: () => _executeLocalOnlyInternal<T>(
        localDataSource: localDataSource,
      ),
      operationName: operationName ?? 'executeLocalOnly',
    );
  }

  /// Internal implementation of local-only strategy
  Future<Either<Failure, T>> _executeLocalOnlyInternal<T>({
    required Future<T> Function() localDataSource,
  }) async {
    try {
      final localData = await localDataSource();
      return Right(localData);
    } catch (e) {
      logger.e('Local data source error: $e');
      return Left(ErrorHandler.mapExceptionToFailure(e, context: 'executeLocalOnly'));
    }
  }

  /// **SYNC STRATEGY**
  ///
  /// Use for background synchronization operations:
  /// - Batch operations, data reconciliation
  /// - Periodic sync operations
  /// - Conflict resolution scenarios
  Future<Either<Failure, void>> executeSyncStrategy({
    required Future<void> Function() syncOperation,
    String? operationName,
  }) async {
    return _executeWithMonitoring<void>(
      operation: () => _executeSyncStrategyInternal(
        syncOperation: syncOperation,
      ),
      operationName: operationName ?? 'executeSyncStrategy',
    );
  }

  /// Internal implementation of sync strategy
  Future<Either<Failure, void>> _executeSyncStrategyInternal({
    required Future<void> Function() syncOperation,
  }) async {
    try {
      await syncOperation();
      return const Right(null);
    } catch (e) {
      logger.e('Sync operation error: $e');
      return Left(ErrorHandler.mapExceptionToFailure(e, context: 'executeSyncStrategy'));
    }
  }

  /// **ENTERPRISE PERFORMANCE MONITORING**
  ///
  /// Wraps repository operations with comprehensive performance tracking
  /// and error handling for enterprise-grade monitoring.
  Future<Either<Failure, T>> _executeWithMonitoring<T>({
    required Future<Either<Failure, T>> Function() operation,
    required String operationName,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      logger.d('[$operationName] Starting repository operation');

      // Start performance trace
      await performanceMonitor.startTrace(
        TraceType.custom,
        customTraceName: operationName,
      );

      final result = await operation();

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      // Record operation metrics
      await performanceMonitor.addTraceAttribute(
        TraceType.custom,
        customTraceName: operationName,
        attributeName: 'duration_ms',
        value: duration.toString(),
      );

      await performanceMonitor.addTraceAttribute(
        TraceType.custom,
        customTraceName: operationName,
        attributeName: 'success',
        value: result.isRight.toString(),
      );

      // Log result
      result.fold(
        (failure) {
          logger.w('[$operationName] Failed in ${duration}ms: ${failure.message}');
        },
        (data) {
          logger.d('[$operationName] Completed successfully in ${duration}ms');
        },
      );

      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      logger.e('[$operationName] Unexpected error in ${duration}ms: $e',
               error: e, stackTrace: stackTrace);

      // Record error metrics
      await performanceMonitor.addTraceAttribute(
        TraceType.custom,
        customTraceName: operationName,
        attributeName: 'error',
        value: e.toString(),
      );

      return Left(ErrorHandler.mapExceptionToFailure(
        e,
        context: operationName,
      ));
    } finally {
      // Stop performance trace
      await performanceMonitor.stopTrace(
        TraceType.custom,
        customTraceName: operationName,
      );
    }
  }
}