import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ lưu trữ trạng thái ứng dụng
@singleton
class StatePersistenceService {
  /// Logger
  final _logger = Logger();
  
  /// SharedPreferences instance
  final SharedPreferences _preferences;
  
  /// Tiền tố cho các khóa
  static const String _keyPrefix = 'persisted_state_';
  
  /// Thời gian hết hạn mặc định (24 giờ)
  static const Duration _defaultExpiration = Duration(hours: 24);
  
  /// Constructor
  StatePersistenceService(this._preferences);
  
  /// Lưu trạng thái với ID
  Future<bool> saveState(
    String id, 
    Map<String, dynamic> state, {
    Duration expiration = _defaultExpiration,
  }) async {
    try {
      final key = _keyPrefix + id;
      
      // Thêm thông tin thời gian vào state
      final stateWithMeta = {
        'data': state,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiration': expiration.inMilliseconds,
      };
      
      // Chuyển đổi sang JSON
      final jsonString = jsonEncode(stateWithMeta);
      
      // Lưu trạng thái
      final result = await _preferences.setString(key, jsonString);
      
      if (result) {
        _logger.d('State saved: $id');
      } else {
        _logger.w('Failed to save state: $id');
      }
      
      return result;
    } catch (e) {
      _logger.e('Error saving state: $e');
      return false;
    }
  }
  
  /// Tải trạng thái với ID
  Future<Map<String, dynamic>?> loadState(String id) async {
    try {
      final key = _keyPrefix + id;
      
      // Lấy chuỗi JSON
      final jsonString = _preferences.getString(key);
      
      if (jsonString == null) {
        _logger.d('No state found for ID: $id');
        return null;
      }
      
      // Chuyển đổi từ JSON
      final stateWithMeta = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Kiểm tra thời gian hết hạn
      final timestamp = stateWithMeta['timestamp'] as int;
      final expiration = stateWithMeta['expiration'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Kiểm tra nếu hết hạn
      if (now - timestamp > expiration) {
        _logger.d('State expired for ID: $id');
        await removeState(id);
        return null;
      }
      
      _logger.d('State loaded: $id');
      return stateWithMeta['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Error loading state: $e');
      return null;
    }
  }
  
  /// Xóa trạng thái với ID
  Future<bool> removeState(String id) async {
    try {
      final key = _keyPrefix + id;
      final result = await _preferences.remove(key);
      
      if (result) {
        _logger.d('State removed: $id');
      } else {
        _logger.w('Failed to remove state: $id');
      }
      
      return result;
    } catch (e) {
      _logger.e('Error removing state: $e');
      return false;
    }
  }
  
  /// Xóa tất cả trạng thái đã lưu
  Future<bool> clearAllStates() async {
    try {
      final keys = _preferences.getKeys()
          .where((key) => key.startsWith(_keyPrefix))
          .toList();
      
      for (final key in keys) {
        await _preferences.remove(key);
      }
      
      _logger.d('Cleared all states. Count: ${keys.length}');
      return true;
    } catch (e) {
      _logger.e('Error clearing all states: $e');
      return false;
    }
  }
  
  /// Xóa tất cả trạng thái hết hạn
  Future<int> clearExpiredStates() async {
    try {
      final keys = _preferences.getKeys()
          .where((key) => key.startsWith(_keyPrefix))
          .toList();
          
      int clearedCount = 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      for (final key in keys) {
        final jsonString = _preferences.getString(key);
        if (jsonString != null) {
          try {
            final stateWithMeta = jsonDecode(jsonString) as Map<String, dynamic>;
            final timestamp = stateWithMeta['timestamp'] as int;
            final expiration = stateWithMeta['expiration'] as int;
            
            if (now - timestamp > expiration) {
              await _preferences.remove(key);
              clearedCount++;
            }
          } catch (_) {
            // Nếu không thể phân tích trạng thái, xóa nó
            await _preferences.remove(key);
            clearedCount++;
          }
        }
      }
      
      _logger.d('Cleared expired states. Count: $clearedCount');
      return clearedCount;
    } catch (e) {
      _logger.e('Error clearing expired states: $e');
      return 0;
    }
  }
} 