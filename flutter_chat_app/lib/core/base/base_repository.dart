import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';

/// Interface cho tất cả các repository trong ứng dụng
abstract class BaseRepository {
  final NetworkInfo networkInfo;
  
  BaseRepository({required this.networkInfo});
  
  /// Phương thức thực thi với strategy online-first
  /// Luôn kiểm tra kết nối internet trước, nếu có thì thực hiện remote, nếu không thì thực hiện local
  /// [remoteDataSource] Nguồn dữ liệu từ xa
  /// [localDataSource] Nguồn dữ liệu cục bộ
  /// [cacheData] Phương thức lưu dữ liệu vào bộ nhớ cache
  Future<Either<Failure, T>> executeOnlineFirst<T>({
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
        } catch (e) {
          LogUtils.e('Repository', 'Local data source error: $e');
          return Left(CacheFailure(message: e.toString()));
        }
      }
    } else {
      try {
        final localData = await localDataSource();
        return Right(localData);
      } catch (e) {
        LogUtils.e('Repository', 'Local data source error: $e');
        return Left(ConnectionFailure(message: 'No internet connection and no cached data'));
      }
    }
  }
  
  /// Phương thức thực thi với strategy offline-first
  /// Luôn lấy dữ liệu từ local trước, sau đó cập nhật từ remote nếu có kết nối
  /// [remoteDataSource] Nguồn dữ liệu từ xa
  /// [localDataSource] Nguồn dữ liệu cục bộ
  /// [cacheData] Phương thức lưu dữ liệu vào bộ nhớ cache
  Future<Either<Failure, T>> executeOfflineFirst<T>({
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
          return Left(ServerFailure(message: e.toString()));
        }
      } else {
        return Left(ConnectionFailure(message: 'No internet connection and no cached data'));
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
  
  /// Phương thức thực thi với strategy remote-only
  /// Chỉ lấy dữ liệu từ remote, không sử dụng cache
  Future<Either<Failure, T>> executeRemoteOnly<T>({
    required Future<T> Function() remoteDataSource,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteData = await remoteDataSource();
        return Right(remoteData);
      } catch (e) {
        LogUtils.e('Repository', 'Remote data source error: $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }
  
  /// Phương thức thực thi với strategy local-only
  /// Chỉ lấy dữ liệu từ local, không sử dụng remote
  Future<Either<Failure, T>> executeLocalOnly<T>({
    required Future<T> Function() localDataSource,
  }) async {
    try {
      final localData = await localDataSource();
      return Right(localData);
    } catch (e) {
      LogUtils.e('Repository', 'Local data source error: $e');
      return Left(CacheFailure(message: e.toString()));
    }
  }
} 