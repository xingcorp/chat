import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Abstract interface for local storage operations
abstract class LocalStorage {
  /// Sets a boolean value
  Future<bool> setBool(String key, bool value);
  
  /// Gets a boolean value
  Future<bool?> getBool(String key);
  
  /// Sets an integer value
  Future<bool> setInt(String key, int value);
  
  /// Gets an integer value
  Future<int?> getInt(String key);
  
  /// Sets a double value
  Future<bool> setDouble(String key, double value);
  
  /// Gets a double value
  Future<double?> getDouble(String key);
  
  /// Sets a string value
  Future<bool> setString(String key, String value);
  
  /// Gets a string value
  Future<String?> getString(String key);
  
  /// Sets a string list value
  Future<bool> setStringList(String key, List<String> value);
  
  /// Gets a string list value
  Future<List<String>?> getStringList(String key);
  
  /// Sets an object value by encoding it to JSON
  Future<bool> setObject(String key, Map<String, dynamic> value);
  
  /// Gets an object value by decoding it from JSON
  Future<Map<String, dynamic>?> getObject(String key);
  
  /// Checks if the key exists
  Future<bool> containsKey(String key);
  
  /// Removes a value
  Future<bool> remove(String key);
  
  /// Clears all values
  Future<bool> clear();
}

/// Implementation of the LocalStorage interface using SharedPreferences
class LocalStorageImpl implements LocalStorage {
  final SharedPreferences _prefs;
  
  /// Constructor
  LocalStorageImpl(this._prefs);
  
  @override
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }
  
  @override
  Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }
  
  @override
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }
  
  @override
  Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }
  
  @override
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }
  
  @override
  Future<double?> getDouble(String key) async {
    return _prefs.getDouble(key);
  }
  
  @override
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }
  
  @override
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }
  
  @override
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }
  
  @override
  Future<List<String>?> getStringList(String key) async {
    return _prefs.getStringList(key);
  }
  
  @override
  Future<bool> setObject(String key, Map<String, dynamic> value) async {
    final String jsonString = json.encode(value);
    return await _prefs.setString(key, jsonString);
  }
  
  @override
  Future<Map<String, dynamic>?> getObject(String key) async {
    final String? jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
  
  @override
  Future<bool> containsKey(String key) async {
    return _prefs.containsKey(key);
  }
  
  @override
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
  
  @override
  Future<bool> clear() async {
    return await _prefs.clear();
  }
} 