import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// SharedPreferences-backed storage for platforms where keychain access can
/// block startup or require additional entitlements during standalone boot.
class SharedPreferencesSecureStorage implements SecureStorage {
  final Future<SharedPreferences> Function() _prefsFactory;
  final Map<String, String?> _cache = {};
  bool _allLoaded = false;

  SharedPreferencesSecureStorage({
    Future<SharedPreferences> Function()? prefsFactory,
  }) : _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  Future<SharedPreferences> get _prefs async => _prefsFactory();

  @override
  Future<void> setString(String key, String value) async {
    _cache[key] = value;
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    if (_cache.containsKey(key)) {
      return _cache[key];
    }
    final prefs = await _prefs;
    final value = prefs.getString(key);
    _cache[key] = value;
    return value;
  }

  @override
  Future<void> setObject(String key, Map<String, dynamic> value) async {
    await setString(key, json.encode(value));
  }

  @override
  Future<Map<String, dynamic>?> getObject(String key) async {
    final jsonString = await getString(key);
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    if (_cache.containsKey(key)) {
      return _cache[key] != null;
    }
    final prefs = await _prefs;
    return prefs.containsKey(key);
  }

  @override
  Future<void> remove(String key) async {
    _cache[key] = null;
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    final keys = await getKeys();
    final prefs = await _prefs;
    for (final key in keys) {
      await prefs.remove(key);
    }
    _cache.clear();
    _allLoaded = false;
  }

  @override
  Future<List<String>> getKeys() async {
    if (_allLoaded) {
      return _cache.entries
          .where((entry) => entry.value != null)
          .map((entry) => entry.key)
          .toList();
    }
    final allValues = await getAll();
    return allValues.keys.toList();
  }

  @override
  Future<Map<String, String>> getAll() async {
    if (_allLoaded) {
      return Map<String, String>.fromEntries(
        _cache.entries
            .where((entry) => entry.value != null)
            .map((entry) => MapEntry(entry.key, entry.value!)),
      );
    }

    final prefs = await _prefs;
    final values = <String, String>{};
    for (final key in prefs.getKeys()) {
      final value = prefs.getString(key);
      if (value != null) {
        values[key] = value;
      }
    }
    _cache.addAll(values);
    _allLoaded = true;
    return values;
  }
}

/// Implementation of the SecureStorage interface with write-through in-memory cache.
///
/// Every read checks the in-memory map first, avoiding expensive native bridge
/// calls (EncryptedSharedPreferences / Keychain) on repeated access.
class SecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage _storage;
  final Map<String, String?> _cache = {};
  bool _allLoaded = false;

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
    _cache[key] = value;
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> getString(String key) async {
    if (_cache.containsKey(key)) {
      return _cache[key];
    }
    final value = await _storage.read(key: key);
    _cache[key] = value;
    return value;
  }

  @override
  Future<void> setObject(String key, Map<String, dynamic> value) async {
    final String jsonString = json.encode(value);
    _cache[key] = jsonString;
    await _storage.write(key: key, value: jsonString);
  }

  @override
  Future<Map<String, dynamic>?> getObject(String key) async {
    final String? jsonString = await getString(key);
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    if (_cache.containsKey(key)) {
      return _cache[key] != null;
    }
    return await _storage.containsKey(key: key);
  }

  @override
  Future<void> remove(String key) async {
    _cache[key] = null;
    await _storage.delete(key: key);
  }

  @override
  Future<void> clear() async {
    _cache.clear();
    _allLoaded = false;
    await _storage.deleteAll();
  }

  @override
  Future<List<String>> getKeys() async {
    if (_allLoaded) {
      return _cache.entries
          .where((e) => e.value != null)
          .map((e) => e.key)
          .toList();
    }
    final Map<String, String> allValues = await _storage.readAll();
    _cache.addAll(allValues);
    _allLoaded = true;
    return allValues.keys.toList();
  }

  @override
  Future<Map<String, String>> getAll() async {
    if (_allLoaded) {
      return Map<String, String>.fromEntries(
        _cache.entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
    }
    final allValues = await _storage.readAll();
    _cache.addAll(allValues);
    _allLoaded = true;
    return allValues;
  }
}
