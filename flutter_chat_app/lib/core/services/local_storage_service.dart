import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle local storage operations
@lazySingleton
class LocalStorageService {
  late SharedPreferences _preferences;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// Initialize the service
  @factoryMethod
  static Future<LocalStorageService> init() async {
    final service = LocalStorageService._();
    await service._init();
    return service;
  }
  
  /// Private constructor
  LocalStorageService._();
  
  /// Initialize shared preferences
  Future<void> _init() async {
    _preferences = await SharedPreferences.getInstance();
  }
  
  /// Store a string value
  Future<bool> setString(String key, String value) async {
    return await _preferences.setString(key, value);
  }
  
  /// Retrieve a string value
  String? getString(String key) {
    return _preferences.getString(key);
  }
  
  /// Store an integer value
  Future<bool> setInt(String key, int value) async {
    return await _preferences.setInt(key, value);
  }
  
  /// Retrieve an integer value
  int? getInt(String key) {
    return _preferences.getInt(key);
  }
  
  /// Store a boolean value
  Future<bool> setBool(String key, bool value) async {
    return await _preferences.setBool(key, value);
  }
  
  /// Retrieve a boolean value
  bool? getBool(String key) {
    return _preferences.getBool(key);
  }
  
  /// Store a list of strings
  Future<bool> setStringList(String key, List<String> value) async {
    return await _preferences.setStringList(key, value);
  }
  
  /// Retrieve a list of strings
  List<String>? getStringList(String key) {
    return _preferences.getStringList(key);
  }
  
  /// Store an object as JSON
  Future<bool> setObject(String key, Object value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }
  
  /// Retrieve and parse a JSON object
  Map<String, dynamic>? getObject(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
  
  /// Check if a key exists
  bool containsKey(String key) {
    return _preferences.containsKey(key);
  }
  
  /// Remove a specific key
  Future<bool> remove(String key) async {
    return await _preferences.remove(key);
  }
  
  /// Clear all data
  Future<bool> clear() async {
    return await _preferences.clear();
  }
  
  /// Store a secure string (encrypted)
  Future<void> setSecureString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  /// Retrieve a secure string
  Future<String?> getSecureString(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  /// Remove a secure key
  Future<void> removeSecure(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  /// Clear all secure data
  Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }
} 