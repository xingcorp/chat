import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Interface for local storage operations
abstract class LocalStorage {
  /// Get a string value
  Future<String?> getString(String key);
  
  /// Save a string value
  Future<bool> saveString(String key, String value);
  
  /// Get a boolean value
  Future<bool?> getBool(String key);
  
  /// Save a boolean value
  Future<bool> saveBool(String key, bool value);
  
  /// Get an integer value
  Future<int?> getInt(String key);
  
  /// Save an integer value
  Future<bool> saveInt(String key, int value);
  
  /// Get a double value
  Future<double?> getDouble(String key);
  
  /// Save a double value
  Future<bool> saveDouble(String key, double value);
  
  /// Get a list of objects
  Future<List<dynamic>> getList(String key);
  
  /// Save a list of objects
  Future<bool> saveList(String key, List<dynamic> list);
  
  /// Remove a value
  Future<bool> remove(String key);
  
  /// Clear all values
  Future<bool> clear();
  
  /// Check if a key exists
  Future<bool> containsKey(String key);
  
  /// Get all keys (for cleanup operations)
  Set<String> getKeys();
}

/// Implementation of local storage using SharedPreferences
@LazySingleton(as: LocalStorage)
class LocalStorageImpl implements LocalStorage {
  final SharedPreferences _prefs;
  
  /// Constructor
  LocalStorageImpl(this._prefs);
  
  @override
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }
  
  @override
  Future<bool> saveString(String key, String value) async {
    return _prefs.setString(key, value);
  }
  
  @override
  Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }
  
  @override
  Future<bool> saveBool(String key, bool value) async {
    return _prefs.setBool(key, value);
  }
  
  @override
  Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }
  
  @override
  Future<bool> saveInt(String key, int value) async {
    return _prefs.setInt(key, value);
  }
  
  @override
  Future<double?> getDouble(String key) async {
    return _prefs.getDouble(key);
  }
  
  @override
  Future<bool> saveDouble(String key, double value) async {
    return _prefs.setDouble(key, value);
  }
  
  @override
  Future<List<dynamic>> getList(String key) async {
    try {
      final data = _prefs.getString(key);
      if (data == null) {
        return [];
      }
      return jsonDecode(data) as List<dynamic>;
    } catch (e) {
      debugPrint('Error getting list from local storage: $e');
      return [];
    }
  }
  
  @override
  Future<bool> saveList(String key, List<dynamic> list) async {
    try {
      final jsonString = jsonEncode(list);
      return _prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('Error saving list to local storage: $e');
      return false;
    }
  }
  
  @override
  Future<bool> remove(String key) async {
    return _prefs.remove(key);
  }
  
  @override
  Future<bool> clear() async {
    return _prefs.clear();
  }
  
  @override
  Future<bool> containsKey(String key) async {
    return _prefs.containsKey(key);
  }
  
  @override
  Set<String> getKeys() {
    return _prefs.getKeys();
  }
} 