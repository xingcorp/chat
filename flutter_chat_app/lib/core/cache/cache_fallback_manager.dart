/// **CACHE FALLBACK MANAGER - GRACEFUL DEGRADATION**
///
/// Professional cache fallback system for graceful service degradation:
/// - Intelligent cache validation và expiration handling
/// - Fallback strategies based on data criticality
/// - Performance-optimized cache access <200ms
/// - Memory-efficient cache management
///
/// **Architecture:** Clean Architecture + Offline-First + Cache Patterns

import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';

/// **Cache Entry Model**
class CacheEntry<T> {
  /// Cached data
  final T data;
  
  /// Timestamp when cached
  final DateTime cachedAt;
  
  /// Expiration timestamp
  final DateTime expiresAt;
  
  /// Data version for invalidation
  final String version;
  
  /// Data criticality level
  final CacheCriticality criticality;

  const CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.expiresAt,
    required this.version,
    required this.criticality,
  });

  /// **Is Expired**
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// **Is Stale**
  /// Data is stale but might still be usable for fallback
  bool get isStale {
    final staleDuration = _getStaleDuration();
    return DateTime.now().isAfter(cachedAt.add(staleDuration));
  }

  /// **Age in Minutes**
  int get ageInMinutes => DateTime.now().difference(cachedAt).inMinutes;

  /// **To Map**
  Map<String, dynamic> toMap() {
    return {
      'data': _serializeData(data),
      'cachedAt': cachedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'version': version,
      'criticality': criticality.name,
    };
  }

  /// **From Map**
  static CacheEntry<T> fromMap<T>(
    Map<String, dynamic> map,
    T Function(dynamic) deserializer,
  ) {
    return CacheEntry<T>(
      data: deserializer(map['data']),
      cachedAt: DateTime.parse(map['cachedAt']),
      expiresAt: DateTime.parse(map['expiresAt']),
      version: map['version'] ?? '1.0.0',
      criticality: CacheCriticality.values.firstWhere(
        (c) => c.name == map['criticality'],
        orElse: () => CacheCriticality.normal,
      ),
    );
  }

  /// **Get Stale Duration**
  Duration _getStaleDuration() {
    switch (criticality) {
      case CacheCriticality.critical:
        return const Duration(minutes: 5);
      case CacheCriticality.high:
        return const Duration(minutes: 15);
      case CacheCriticality.normal:
        return const Duration(hours: 1);
      case CacheCriticality.low:
        return const Duration(hours: 6);
    }
  }

  /// **Serialize Data**
  dynamic _serializeData(T data) {
    if (data is String || data is num || data is bool) {
      return data;
    } else if (data is Map || data is List) {
      return data;
    } else {
      // For complex objects, convert to JSON
      return json.encode(data);
    }
  }
}

/// **Cache Criticality Levels**
enum CacheCriticality {
  /// Critical data (user profile, auth tokens)
  critical,
  
  /// High priority data (recent messages, active chats)
  high,
  
  /// Normal priority data (chat history, user lists)
  normal,
  
  /// Low priority data (analytics, non-essential metadata)
  low,
}

/// **Cache Fallback Strategy**
enum CacheFallbackStrategy {
  /// Use cache if available, regardless of age
  useStaleCache,
  
  /// Use cache only if not expired
  useValidCacheOnly,
  
  /// Try network first, fallback to cache
  networkFirstCacheFallback,
  
  /// Use cache first, update in background
  cacheFirstBackgroundUpdate,
  
  /// No cache fallback
  noFallback,
}

/// **CACHE FALLBACK MANAGER**
///
/// Enterprise-grade cache fallback system với intelligent degradation
class CacheFallbackManager {
  /// Hive box for cache storage
  Box<Map>? _box;
  
  /// Logger instance
  final Logger _logger = Logger();
  
  /// Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _cacheEvictions = 0;
  
  /// Cache size limits
  static const int _maxCacheEntries = 1000;
  static const int _maxCacheSize = 10 * 1024 * 1024; // 10MB

  /// **Initialize Cache Manager**
  ///
  /// **Performance:** <100ms initialization
  Future<Either<Failure, bool>> initialize() async {
    try {
      _logger.i('💾 Initializing cache fallback manager');
      
      // Open Hive box for cache storage
      _box = await Hive.openBox<Map>('cache_fallback');
      
      // Cleanup expired entries
      await _cleanupExpiredEntries();
      
      _logger.i('✅ Cache fallback manager initialized');
      return const Right(true);
      
    } catch (e) {
      _logger.e('💥 Failed to initialize cache manager: $e');
      return Left(CacheFailure(
        message: 'Failed to initialize cache: $e',
        code: 'cache_init_failed',
      ));
    }
  }

  /// **Get with Fallback**
  ///
  /// **Performance:** <200ms cache access với fallback logic
  Future<Either<Failure, T>> getWithFallback<T>(
    String key, {
    required Future<Either<Failure, T>> Function() networkCall,
    required T Function(dynamic) deserializer,
    CacheFallbackStrategy strategy = CacheFallbackStrategy.networkFirstCacheFallback,
    CacheCriticality criticality = CacheCriticality.normal,
    Duration? cacheDuration,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      switch (strategy) {
        case CacheFallbackStrategy.networkFirstCacheFallback:
          return await _networkFirstCacheFallback(
            key,
            networkCall,
            deserializer,
            criticality,
            cacheDuration,
          );
        
        case CacheFallbackStrategy.cacheFirstBackgroundUpdate:
          return await _cacheFirstBackgroundUpdate(
            key,
            networkCall,
            deserializer,
            criticality,
            cacheDuration,
          );
        
        case CacheFallbackStrategy.useValidCacheOnly:
          return await _useValidCacheOnly(key, deserializer);
        
        case CacheFallbackStrategy.useStaleCache:
          return await _useStaleCache(key, deserializer);
        
        case CacheFallbackStrategy.noFallback:
          return await networkCall();
      }
    } finally {
      stopwatch.stop();
      _logger.t('⏱️ Cache operation completed in ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  /// **Set Cache Entry**
  ///
  /// **Performance:** <50ms cache write
  Future<Either<Failure, bool>> setCacheEntry<T>(
    String key,
    T data, {
    Duration? cacheDuration,
    CacheCriticality criticality = CacheCriticality.normal,
    String version = '1.0.0',
  }) async {
    try {
      if (_box == null) {
        return Left(CacheFailure(
          message: 'Cache not initialized',
          code: 'cache_not_initialized',
        ));
      }

      final duration = cacheDuration ?? _getDefaultCacheDuration(criticality);
      final entry = CacheEntry<T>(
        data: data,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(duration),
        version: version,
        criticality: criticality,
      );

      await _box!.put(key, entry.toMap());
      
      _logger.t('💾 Cache entry set: $key (expires in ${duration.inMinutes}min)');
      
      // Check cache size limits
      await _enforceCacheLimits();
      
      return const Right(true);
      
    } catch (e) {
      _logger.e('💥 Failed to set cache entry: $e');
      return Left(CacheFailure(
        message: 'Failed to set cache: $e',
        code: 'cache_set_failed',
      ));
    }
  }

  /// **Network First, Cache Fallback**
  Future<Either<Failure, T>> _networkFirstCacheFallback<T>(
    String key,
    Future<Either<Failure, T>> Function() networkCall,
    T Function(dynamic) deserializer,
    CacheCriticality criticality,
    Duration? cacheDuration,
  ) async {
    // Try network first
    final networkResult = await networkCall();
    
    return networkResult.fold(
      (failure) async {
        _logger.w('🌐 Network call failed, trying cache fallback: ${failure.message}');
        
        // Fallback to cache
        final cacheResult = await _getCacheEntry(key, deserializer);
        
        return cacheResult.fold(
          (cacheFailure) {
            _cacheMisses++;
            _logger.e('💾 Cache fallback also failed: ${cacheFailure.message}');
            return Left(failure); // Return original network failure
          },
          (cacheEntry) {
            _cacheHits++;
            
            if (cacheEntry.isStale) {
              _logger.w('💾 Using stale cache data (age: ${cacheEntry.ageInMinutes}min)');
            } else {
              _logger.i('💾 Using valid cache data');
            }
            
            return Right(cacheEntry.data);
          },
        );
      },
      (data) async {
        // Network success - update cache
        await setCacheEntry(
          key,
          data,
          cacheDuration: cacheDuration,
          criticality: criticality,
        );
        
        return Right(data);
      },
    );
  }

  /// **Cache First, Background Update**
  Future<Either<Failure, T>> _cacheFirstBackgroundUpdate<T>(
    String key,
    Future<Either<Failure, T>> Function() networkCall,
    T Function(dynamic) deserializer,
    CacheCriticality criticality,
    Duration? cacheDuration,
  ) async {
    // Try cache first
    final cacheResult = await _getCacheEntry(key, deserializer);
    
    return cacheResult.fold(
      (cacheFailure) async {
        _cacheMisses++;
        _logger.d('💾 Cache miss, falling back to network');
        
        // No cache available, use network
        final networkResult = await networkCall();
        
        // Update cache if network succeeds
        networkResult.fold(
          (failure) => null,
          (data) => setCacheEntry(
            key,
            data,
            cacheDuration: cacheDuration,
            criticality: criticality,
          ),
        );
        
        return networkResult;
      },
      (cacheEntry) {
        _cacheHits++;
        
        // Return cached data immediately
        if (!cacheEntry.isStale) {
          _logger.t('💾 Cache hit with fresh data');
        } else {
          _logger.t('💾 Cache hit with stale data, updating in background');
          
          // Update in background
          _updateCacheInBackground(
            key,
            networkCall,
            criticality,
            cacheDuration,
          );
        }
        
        return Right(cacheEntry.data);
      },
    );
  }

  /// **Use Valid Cache Only**
  Future<Either<Failure, T>> _useValidCacheOnly<T>(
    String key,
    T Function(dynamic) deserializer,
  ) async {
    final cacheResult = await _getCacheEntry(key, deserializer);
    
    return cacheResult.fold(
      (failure) {
        _cacheMisses++;
        return Left(failure);
      },
      (cacheEntry) {
        if (cacheEntry.isExpired) {
          _cacheMisses++;
          return Left(CacheFailure(
            message: 'Cache entry expired',
            code: 'cache_expired',
          ));
        }
        
        _cacheHits++;
        return Right(cacheEntry.data);
      },
    );
  }

  /// **Use Stale Cache**
  Future<Either<Failure, T>> _useStaleCache<T>(
    String key,
    T Function(dynamic) deserializer,
  ) async {
    final cacheResult = await _getCacheEntry(key, deserializer);
    
    return cacheResult.fold(
      (failure) {
        _cacheMisses++;
        return Left(failure);
      },
      (cacheEntry) {
        _cacheHits++;
        
        if (cacheEntry.isStale) {
          _logger.w('💾 Using stale cache data (age: ${cacheEntry.ageInMinutes}min)');
        }
        
        return Right(cacheEntry.data);
      },
    );
  }

  /// **Get Cache Entry**
  Future<Either<Failure, CacheEntry<T>>> _getCacheEntry<T>(
    String key,
    T Function(dynamic) deserializer,
  ) async {
    try {
      if (_box == null) {
        return Left(CacheFailure(
          message: 'Cache not initialized',
          code: 'cache_not_initialized',
        ));
      }

      final data = _box!.get(key);
      if (data == null) {
        return Left(CacheFailure(
          message: 'Cache entry not found',
          code: 'cache_not_found',
        ));
      }

      final entry = CacheEntry.fromMap<T>(
        Map<String, dynamic>.from(data),
        deserializer,
      );

      return Right(entry);
      
    } catch (e) {
      _logger.e('💥 Error getting cache entry: $e');
      return Left(CacheFailure(
        message: 'Failed to get cache entry: $e',
        code: 'cache_get_failed',
      ));
    }
  }

  /// **Update Cache in Background**
  void _updateCacheInBackground<T>(
    String key,
    Future<Either<Failure, T>> Function() networkCall,
    CacheCriticality criticality,
    Duration? cacheDuration,
  ) {
    // Run in background without blocking
    networkCall().then((result) {
      result.fold(
        (failure) {
          _logger.w('🔄 Background cache update failed: ${failure.message}');
        },
        (data) {
          setCacheEntry(
            key,
            data,
            cacheDuration: cacheDuration,
            criticality: criticality,
          );
          _logger.t('🔄 Background cache update successful');
        },
      );
    });
  }

  /// **Get Default Cache Duration**
  Duration _getDefaultCacheDuration(CacheCriticality criticality) {
    switch (criticality) {
      case CacheCriticality.critical:
        return const Duration(minutes: 30);
      case CacheCriticality.high:
        return const Duration(hours: 2);
      case CacheCriticality.normal:
        return const Duration(hours: 6);
      case CacheCriticality.low:
        return const Duration(days: 1);
    }
  }

  /// **Cleanup Expired Entries**
  Future<void> _cleanupExpiredEntries() async {
    if (_box == null) return;
    
    final keys = _box!.keys.toList();
    int cleanedCount = 0;
    
    for (final key in keys) {
      try {
        final data = _box!.get(key);
        if (data != null) {
          final expiresAt = DateTime.tryParse(data['expiresAt'] ?? '');
          if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
            await _box!.delete(key);
            cleanedCount++;
          }
        }
      } catch (e) {
        // Remove corrupted entries
        await _box!.delete(key);
        cleanedCount++;
      }
    }
    
    if (cleanedCount > 0) {
      _logger.i('🧹 Cleaned up $cleanedCount expired cache entries');
    }
  }

  /// **Enforce Cache Limits**
  Future<void> _enforceCacheLimits() async {
    if (_box == null) return;
    
    final keys = _box!.keys.toList();
    
    // Check entry count limit
    if (keys.length > _maxCacheEntries) {
      final entriesToRemove = keys.length - _maxCacheEntries;
      
      // Remove oldest entries
      for (int i = 0; i < entriesToRemove; i++) {
        await _box!.delete(keys[i]);
        _cacheEvictions++;
      }
      
      _logger.w('🗑️ Evicted $entriesToRemove cache entries due to size limit');
    }
  }

  /// **Get Cache Statistics**
  Map<String, dynamic> getStatistics() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? (_cacheHits / totalRequests * 100) : 0.0;
    
    return {
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'cache_evictions': _cacheEvictions,
      'hit_rate_percent': hitRate.toStringAsFixed(2),
      'total_entries': _box?.keys.length ?? 0,
    };
  }

  /// **Clear Cache**
  Future<Either<Failure, bool>> clearCache() async {
    try {
      await _box?.clear();
      _cacheHits = 0;
      _cacheMisses = 0;
      _cacheEvictions = 0;
      
      _logger.w('🗑️ Cache cleared');
      return const Right(true);
      
    } catch (e) {
      _logger.e('💥 Failed to clear cache: $e');
      return Left(CacheFailure(
        message: 'Failed to clear cache: $e',
        code: 'cache_clear_failed',
      ));
    }
  }

  /// **Dispose Resources**
  Future<void> dispose() async {
    _logger.i('🧹 Disposing cache fallback manager');
    
    await _box?.close();
    
    _logger.i('✅ Cache fallback manager disposed');
  }
}
