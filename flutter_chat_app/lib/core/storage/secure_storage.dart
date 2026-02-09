import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract interface for secure storage operations
abstract class SecureStorage {
  /// Sets a string value
  Future<void> setString(String key, String value);
  
  /// Gets a string value
  Future<String?> getString(String key);
  
  /// Sets an object value by encoding it to JSON
  Future<void> setObject(String key, Map<String, dynamic> value);
  
  /// Gets an object value by decoding it from JSON
  Future<Map<String, dynamic>?> getObject(String key);
  
  /// Checks if the key exists
  Future<bool> containsKey(String key);
  
  /// Removes a value
  Future<void> remove(String key);
  
  /// Clears all values
  Future<void> clear();
  
  /// Gets all keys
  Future<List<String>> getKeys();
  
  /// Gets all values
  Future<Map<String, String>> getAll();
}

class InMemorySecureStorage implements SecureStorage {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return _data[key];
  }

  @override
  Future<void> setObject(String key, Map<String, dynamic> value) async {
    _data[key] = json.encode(value);
  }

  @override
  Future<Map<String, dynamic>?> getObject(String key) async {
    final jsonString = _data[key];
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    return _data.containsKey(key);
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  @override
  Future<List<String>> getKeys() async {
    return _data.keys.toList();
  }

  @override
  Future<Map<String, String>> getAll() async {
    return Map<String, String>.from(_data);
  }
}

/// Implementation of the SecureStorage interface
class SecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage _storage;
  
  /// Constructor
  SecureStorageImpl({FlutterSecureStorage? storage})
      : _storage = storage ??
            (kIsWeb
                ? const FlutterSecureStorage()
                : const FlutterSecureStorage(
                    aOptions: AndroidOptions(
                      encryptedSharedPreferences: true,
                    ),
                  ));
  
  @override
  Future<void> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  @override
  Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }
  
  @override
  Future<void> setObject(String key, Map<String, dynamic> value) async {
    final String jsonString = json.encode(value);
    await _storage.write(key: key, value: jsonString);
  }
  
  @override
  Future<Map<String, dynamic>?> getObject(String key) async {
    final String? jsonString = await _storage.read(key: key);
    if (jsonString == null) return null;
    
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
  
  @override
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
  
  @override
  Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }
  
  @override
  Future<void> clear() async {
    await _storage.deleteAll();
  }
  
  @override
  Future<List<String>> getKeys() async {
    final Map<String, String> allValues = await _storage.readAll();
    return allValues.keys.toList();
  }
  
  @override
  Future<Map<String, String>> getAll() async {
    return await _storage.readAll();
  }
} 