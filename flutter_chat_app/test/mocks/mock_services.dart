/// **SIMPLE MOCK SERVICES FOR TESTING**
/// 
/// Simple mock implementations for testing purposes.
/// These provide basic functionality without external dependencies.

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';

/// **MOCK MEMORY OPTIMIZER**
class MockMemoryOptimizer {
  Future<Either<Failure, bool>> initialize() async {
    return const Right(true);
  }

  Future<void> handleMemoryPressure() async {
    // Mock implementation
  }

  Future<void> optimizeMemoryUsage() async {
    // Mock implementation
  }
}

/// **MOCK ENHANCED CACHE MANAGER**
class MockEnhancedCacheManager {
  final Map<String, dynamic> _cache = {};

  Future<Either<Failure, bool>> initialize() async {
    return const Right(true);
  }

  Future<Either<Failure, T?>> get<T>(String key) async {
    return Right(_cache[key] as T?);
  }

  Future<Either<Failure, bool>> set<T>(String key, T value, {Duration? ttl}) async {
    _cache[key] = value;
    return const Right(true);
  }

  Future<Either<Failure, bool>> remove(String key) async {
    _cache.remove(key);
    return const Right(true);
  }

  Future<Either<Failure, bool>> clear() async {
    _cache.clear();
    return const Right(true);
  }
}

/// **MOCK NETWORK OPTIMIZER**
class MockNetworkOptimizer {
  Future<Either<Failure, bool>> initialize() async {
    return const Right(true);
  }
}
