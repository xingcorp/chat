import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chiến lược cache cho network responses
enum CacheStrategy {
  /// Ưu tiên cache, nếu không có cache thì gọi network (cache-first)
  cacheFirst,
  
  /// Ưu tiên network, nếu network lỗi thì dùng cache (network-first)
  networkFirst,
  
  /// Dùng cache trong khi đang gọi network (stale-while-revalidate)
  staleWhileRevalidate,
  
  /// Chỉ dùng cache, không gọi network (cache-only)
  cacheOnly,
  
  /// Chỉ gọi network, không dùng cache (network-only)
  networkOnly,
}

/// Class quản lý cache cho network responses
@lazySingleton
class NetworkResponseCache {
  /// Box chứa dữ liệu cache
  Box<String>? _cacheBox;
  
  /// SharedPreferences để lưu metadata
  final SharedPreferences _prefs;

  /// Logger instance
  final Logger _logger = Logger();

  /// Key prefix cho metadata trong SharedPreferences
  static const String _prefixExpiry = 'cache_expiry_';

  /// Key prefix cho group cache
  static const String _prefixGroup = 'cache_group_';
  
  /// Constructor
  @factoryMethod
  NetworkResponseCache(this._prefs) {
    _initialize();
  }
  
  /// Khởi tạo cache
  Future<void> _initialize() async {
    try {
      if (kIsWeb) {
        await Hive.initFlutter();
        _cacheBox = await Hive.openBox<String>('network_cache');
        _cleanExpiredCache();
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/network_cache');
      
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      Hive.init(cacheDir.path);
      _cacheBox = await Hive.openBox<String>('network_cache');
      
      // Xóa các cache đã hết hạn
      _cleanExpiredCache();
    } catch (e) {
      _logger.e('Error initializing cache: $e');
    }
  }
  
  /// Lấy dữ liệu cache
  Future<T?> getCache<T>(String key) async {
    await _ensureInitialized();
    
    // Kiểm tra cache có tồn tại không
    if (!_cacheBox!.containsKey(key)) {
      return null;
    }
    
    // Kiểm tra cache có hết hạn không
    final expiryTime = _prefs.getInt('$_prefixExpiry$key');
    if (expiryTime != null && expiryTime < DateTime.now().millisecondsSinceEpoch) {
      // Cache đã hết hạn, xóa và trả về null
      await _cacheBox!.delete(key);
      await _prefs.remove('$_prefixExpiry$key');
      return null;
    }
    
    try {
      // Lấy dữ liệu từ cache
      final jsonString = _cacheBox!.get(key);
      if (jsonString == null) {
        return null;
      }
      
      final jsonData = json.decode(jsonString);
      return jsonData as T;
    } catch (e) {
      _logger.e('Error reading cache: $e');
      return null;
    }
  }
  
  /// Kiểm tra cache có tồn tại không
  Future<bool> hasCache(String key) async {
    await _ensureInitialized();
    
    if (!_cacheBox!.containsKey(key)) {
      return false;
    }
    
    // Kiểm tra cache có hết hạn không
    final expiryTime = _prefs.getInt('$_prefixExpiry$key');
    if (expiryTime != null && expiryTime < DateTime.now().millisecondsSinceEpoch) {
      // Cache đã hết hạn, xóa và trả về false
      await _cacheBox!.delete(key);
      await _prefs.remove('$_prefixExpiry$key');
      return false;
    }
    
    return true;
  }
  
  /// Thêm dữ liệu vào cache
  Future<void> cacheResponse<T>(
    String key, 
    T data, {
    Duration expiryDuration = const Duration(hours: 1),
    String? group,
  }) async {
    await _ensureInitialized();
    
    try {
      // Chuyển đổi dữ liệu thành JSON string
      final jsonString = json.encode(data);
      
      // Lưu dữ liệu vào cache
      await _cacheBox!.put(key, jsonString);
      
      // Lưu thời gian hết hạn
      final expiryTime = DateTime.now().add(expiryDuration).millisecondsSinceEpoch;
      await _prefs.setInt('$_prefixExpiry$key', expiryTime);
      
      // Thêm vào group nếu cần
      if (group != null) {
        final groupKeys = _prefs.getStringList('$_prefixGroup$group') ?? [];
        if (!groupKeys.contains(key)) {
          groupKeys.add(key);
          await _prefs.setStringList('$_prefixGroup$group', groupKeys);
        }
      }
    } catch (e) {
      _logger.e('Error caching response: $e');
    }
  }
  
  /// Xóa một cache cụ thể
  Future<void> invalidateCache(String key) async {
    await _ensureInitialized();
    
    await _cacheBox!.delete(key);
    await _prefs.remove('$_prefixExpiry$key');
    
    // Xóa khỏi tất cả các group
    final groupKeys = _prefs.getKeys().where((k) => k.startsWith(_prefixGroup)).toList();
    for (final groupKey in groupKeys) {
      final keys = _prefs.getStringList(groupKey) ?? [];
      if (keys.contains(key)) {
        keys.remove(key);
        await _prefs.setStringList(groupKey, keys);
      }
    }
  }
  
  /// Xóa tất cả cache của một group
  Future<void> invalidateGroup(String group) async {
    await _ensureInitialized();
    
    final groupKey = '$_prefixGroup$group';
    final keys = _prefs.getStringList(groupKey) ?? [];
    
    // Xóa từng cache trong group
    for (final key in keys) {
      await _cacheBox!.delete(key);
      await _prefs.remove('$_prefixExpiry$key');
    }
    
    // Xóa group
    await _prefs.remove(groupKey);
  }
  
  /// Xóa tất cả cache
  Future<void> clearAll() async {
    await _ensureInitialized();
    
    // Xóa tất cả cache trong box
    await _cacheBox!.clear();
    
    // Xóa tất cả metadata
    final keysToRemove = _prefs.getKeys().where(
      (key) => key.startsWith(_prefixExpiry) || key.startsWith(_prefixGroup)
    ).toList();
    
    for (final key in keysToRemove) {
      await _prefs.remove(key);
    }
  }
  
  /// Đảm bảo cache đã được khởi tạo
  Future<void> _ensureInitialized() async {
    if (_cacheBox == null) {
      await _initialize();
    }
    
    if (_cacheBox == null) {
      throw Exception('Failed to initialize network cache');
    }
  }
  
  /// Xóa các cache đã hết hạn
  Future<void> _cleanExpiredCache() async {
    if (_cacheBox == null) return;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiryKeys = _prefs.getKeys().where((key) => key.startsWith(_prefixExpiry)).toList();
    
    for (final expiryKey in expiryKeys) {
      final expiryTime = _prefs.getInt(expiryKey);
      if (expiryTime != null && expiryTime < now) {
        final cacheKey = expiryKey.substring(_prefixExpiry.length);
        
        // Xóa cache
        await _cacheBox!.delete(cacheKey);
        await _prefs.remove(expiryKey);
        
        // Xóa khỏi tất cả các group
        final groupKeys = _prefs.getKeys().where((k) => k.startsWith(_prefixGroup)).toList();
        for (final groupKey in groupKeys) {
          final keys = _prefs.getStringList(groupKey) ?? [];
          if (keys.contains(cacheKey)) {
            keys.remove(cacheKey);
            await _prefs.setStringList(groupKey, keys);
          }
        }
      }
    }
  }
  
  /// Đóng cache
  Future<void> dispose() async {
    await _cacheBox?.close();
  }
} 