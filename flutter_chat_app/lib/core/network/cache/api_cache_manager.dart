import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../monitoring/logger.dart';

/// Lớp quản lý cache API với TTL (Time-to-Live) và LRU (Least Recently Used)
class ApiCacheManager {
  static ApiCacheManager? _instance;
  static ApiCacheManager get instance => _instance!;
  
  static const String _cachePrefix = 'api_cache_';
  static const String _cacheIndexKey = 'api_cache_index';
  static const String _cacheTimestampPrefix = 'api_cache_ts_';
  static const int _maxCacheEntries = 100; // Số lượng tối đa các mục trong cache
  
  final AppLogger _logger;
  late SharedPreferences _prefs;
  final List<String> _cacheIndex = []; // Danh sách các khóa cache theo thứ tự LRU
  
  /// Khởi tạo ApiCacheManager
  static Future<void> init({
    required AppLogger logger,
    SharedPreferences? prefs,
  }) async {
    if (_instance != null) return;
    
    final sharedPrefs = prefs ?? await SharedPreferences.getInstance();
    
    _instance = ApiCacheManager._(
      logger: logger,
      prefs: sharedPrefs,
    );
    
    await _instance!._initialize();
  }
  
  ApiCacheManager._({
    required AppLogger logger,
    required SharedPreferences prefs,
  }) : _logger = logger,
       _prefs = prefs;
  
  /// Khởi tạo và tải danh sách cache
  Future<void> _initialize() async {
    _logger.debug('ApiCacheManager: Đang khởi tạo');
    
    // Tải danh sách cache
    final indexJson = _prefs.getString(_cacheIndexKey);
    if (indexJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(indexJson);
        _cacheIndex.addAll(decoded.cast<String>());
        _logger.debug('ApiCacheManager: Đã tải ${_cacheIndex.length} mục cache');
      } catch (e) {
        _logger.error('ApiCacheManager: Lỗi khi tải index cache: $e');
        await _prefs.remove(_cacheIndexKey);
      }
    }
    
    // Xóa các mục hết hạn khi khởi động
    await _removeExpiredEntries();
  }
  
  /// Lưu giá trị vào cache
  Future<void> put<T>(
    String key, 
    T value, 
    Duration ttl,
  ) async {
    final cacheKey = _getCacheKey(key);
    final timestampKey = _getTimestampKey(key);
    final expiryTime = DateTime.now().add(ttl).millisecondsSinceEpoch;
    
    try {
      // Lưu giá trị
      String valueToStore;
      if (value is String) {
        valueToStore = value;
      } else {
        valueToStore = jsonEncode(value);
      }
      
      await _prefs.setString(cacheKey, valueToStore);
      await _prefs.setInt(timestampKey, expiryTime);
      
      // Cập nhật index LRU
      await _updateCacheIndex(key);
      
      _logger.debug('ApiCacheManager: Đã lưu cache cho "$key" (TTL: ${ttl.inMinutes} phút)');
    } catch (e) {
      _logger.error('ApiCacheManager: Lỗi khi lưu cache cho "$key": $e');
    }
  }
  
  /// Lấy giá trị từ cache
  Future<T?> get<T>(String key) async {
    final cacheKey = _getCacheKey(key);
    final timestampKey = _getTimestampKey(key);
    
    try {
      // Kiểm tra xem key có tồn tại không
      if (!_prefs.containsKey(cacheKey) || !_prefs.containsKey(timestampKey)) {
        return null;
      }
      
      // Kiểm tra hạn sử dụng
      final expiryTime = _prefs.getInt(timestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now > expiryTime) {
        // Cache đã hết hạn, xóa nó
        await _remove(key);
        return null;
      }
      
      // Lấy giá trị từ cache
      final cachedValue = _prefs.getString(cacheKey);
      if (cachedValue == null) return null;
      
      // Cập nhật vị trí trong LRU cache
      await _updateCacheIndex(key);
      
      // Chuyển đổi giá trị thành kiểu mong muốn
      if (T == String) {
        return cachedValue as T;
      } else {
        try {
          final decoded = jsonDecode(cachedValue);
          return decoded as T;
        } catch (e) {
          _logger.error('ApiCacheManager: Lỗi khi chuyển đổi giá trị cache cho "$key": $e');
          return null;
        }
      }
    } catch (e) {
      _logger.error('ApiCacheManager: Lỗi khi lấy cache cho "$key": $e');
      return null;
    }
  }
  
  /// Xóa một mục khỏi cache
  Future<void> remove(String key) async {
    await _remove(key);
  }
  
  /// Xóa tất cả cache
  Future<void> clear() async {
    _logger.debug('ApiCacheManager: Đang xóa tất cả cache');
    
    try {
      // Xóa tất cả các mục trong cache
      for (final key in List.from(_cacheIndex)) {
        await _remove(key);
      }
      
      // Xóa index
      _cacheIndex.clear();
      await _prefs.remove(_cacheIndexKey);
      
      _logger.debug('ApiCacheManager: Đã xóa tất cả cache');
    } catch (e) {
      _logger.error('ApiCacheManager: Lỗi khi xóa cache: $e');
    }
  }
  
  /// Xóa cache cho một nhóm các key có prefix chung
  Future<void> clearGroup(String keyPrefix) async {
    _logger.debug('ApiCacheManager: Đang xóa nhóm cache với prefix "$keyPrefix"');
    
    try {
      final keysToRemove = _cacheIndex
          .where((key) => key.startsWith(keyPrefix))
          .toList();
      
      for (final key in keysToRemove) {
        await _remove(key);
      }
      
      _logger.debug('ApiCacheManager: Đã xóa ${keysToRemove.length} mục cache với prefix "$keyPrefix"');
    } catch (e) {
      _logger.error('ApiCacheManager: Lỗi khi xóa nhóm cache: $e');
    }
  }
  
  /// Lấy tất cả các key trong cache
  List<String> getAllKeys() {
    return List.from(_cacheIndex);
  }
  
  /// Lấy kích thước cache
  Future<int> getCacheSize() async {
    int totalSize = 0;
    
    for (final key in _cacheIndex) {
      final cacheKey = _getCacheKey(key);
      final value = _prefs.getString(cacheKey);
      if (value != null) {
        totalSize += value.length;
      }
    }
    
    return totalSize;
  }
  
  /// Lấy số lượng mục trong cache
  int getCacheCount() {
    return _cacheIndex.length;
  }
  
  /// Kiểm tra xem cache có chứa key không
  bool containsKey(String key) {
    return _cacheIndex.contains(key);
  }
  
  /// Xóa nội bộ một mục khỏi cache
  Future<void> _remove(String key) async {
    final cacheKey = _getCacheKey(key);
    final timestampKey = _getTimestampKey(key);
    
    await _prefs.remove(cacheKey);
    await _prefs.remove(timestampKey);
    
    _cacheIndex.remove(key);
    await _saveIndex();
    
    _logger.debug('ApiCacheManager: Đã xóa cache cho "$key"');
  }
  
  /// Cập nhật vị trí của key trong danh sách LRU
  Future<void> _updateCacheIndex(String key) async {
    // Xóa key nếu đã tồn tại trong danh sách
    _cacheIndex.remove(key);
    
    // Thêm key vào đầu danh sách (MRU - Most Recently Used)
    _cacheIndex.insert(0, key);
    
    // Đảm bảo số lượng mục không vượt quá giới hạn
    if (_cacheIndex.length > _maxCacheEntries) {
      final keyToRemove = _cacheIndex.removeLast(); // Xóa mục cuối cùng (LRU)
      final cacheKey = _getCacheKey(keyToRemove);
      final timestampKey = _getTimestampKey(keyToRemove);
      
      await _prefs.remove(cacheKey);
      await _prefs.remove(timestampKey);
      
      _logger.debug('ApiCacheManager: Đã xóa mục LRU "$keyToRemove" do vượt quá giới hạn');
    }
    
    // Lưu index mới
    await _saveIndex();
  }
  
  /// Lưu danh sách index
  Future<void> _saveIndex() async {
    await _prefs.setString(_cacheIndexKey, jsonEncode(_cacheIndex));
  }
  
  /// Xóa các mục hết hạn
  Future<void> _removeExpiredEntries() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    int removedCount = 0;
    
    for (final key in List.from(_cacheIndex)) {
      final timestampKey = _getTimestampKey(key);
      final expiryTime = _prefs.getInt(timestampKey) ?? 0;
      
      if (now > expiryTime) {
        await _remove(key);
        removedCount++;
      }
    }
    
    if (removedCount > 0) {
      _logger.debug('ApiCacheManager: Đã xóa $removedCount mục cache hết hạn');
    }
  }
  
  /// Tạo khóa cache từ key
  String _getCacheKey(String key) {
    return '$_cachePrefix$key';
  }
  
  /// Tạo khóa timestamp từ key
  String _getTimestampKey(String key) {
    return '$_cacheTimestampPrefix$key';
  }
} 