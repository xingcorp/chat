import 'dart:async';

import 'package:flutter_chat_app/core/constants/storage_keys.dart';
import 'package:flutter_chat_app/core/network/auth/token_provider.dart';
import 'package:flutter_chat_app/core/storage/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  bool get isEmpty => accessToken.isEmpty && refreshToken.isEmpty;
}

abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> writeAccessToken(String token);
  Future<void> writeRefreshToken(String token);
  Future<String?> readString(String key);
  Future<void> removeKey(String key);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  final SecureStorage _secureStorage;

  SecureTokenStorage(this._secureStorage);

  @override
  Future<String?> readAccessToken() {
    return _secureStorage.getString(StorageKeys.accessToken);
  }

  @override
  Future<String?> readRefreshToken() {
    return _secureStorage.getString(StorageKeys.refreshToken);
  }

  @override
  Future<void> writeAccessToken(String token) {
    return _secureStorage.setString(StorageKeys.accessToken, token);
  }

  @override
  Future<void> writeRefreshToken(String token) {
    return _secureStorage.setString(StorageKeys.refreshToken, token);
  }

  @override
  Future<String?> readString(String key) {
    return _secureStorage.getString(key);
  }

  @override
  Future<void> removeKey(String key) {
    return _secureStorage.remove(key);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _secureStorage.remove(StorageKeys.accessToken),
      _secureStorage.remove(StorageKeys.refreshToken),
    ]);
  }
}

class SharedPreferencesTokenStorage implements TokenStorage {
  final SharedPreferences _prefs;

  SharedPreferencesTokenStorage(this._prefs);

  @override
  Future<String?> readAccessToken() async {
    return _prefs.getString(StorageKeys.accessToken);
  }

  @override
  Future<String?> readRefreshToken() async {
    return _prefs.getString(StorageKeys.refreshToken);
  }

  @override
  Future<void> writeAccessToken(String token) async {
    await _prefs.setString(StorageKeys.accessToken, token);
  }

  @override
  Future<void> writeRefreshToken(String token) async {
    await _prefs.setString(StorageKeys.refreshToken, token);
  }

  @override
  Future<String?> readString(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<void> removeKey(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _prefs.remove(StorageKeys.accessToken),
      _prefs.remove(StorageKeys.refreshToken),
    ]);
  }
}

abstract class TokenRepository implements TokenProvider {
  @override
  Stream<AuthTokens?> get tokensStream;

  Future<void> initialize();

  @override
  Future<String?> getAccessToken();
  @override
  Future<String?> getRefreshToken();
  Future<AuthTokens?> getTokens();

  Future<void> saveAccessToken(String accessToken);
  Future<void> saveRefreshToken(String refreshToken);
  Future<void> saveTokens(AuthTokens tokens);

  @override
  Future<String?> refreshAccessToken();

  Future<void> clear();
}

class TokenRepositoryImpl implements TokenRepository {
  final TokenStorage _tokenStorage;
  final SharedPreferences _prefs;
  final Future<String?> Function()? _refreshAccessToken;

  final StreamController<AuthTokens?> _tokensController =
      StreamController<AuthTokens?>.broadcast();

  bool _initialized = false;
  Completer<String?>? _refreshCompleter;

  TokenRepositoryImpl({
    required TokenStorage tokenStorage,
    required SharedPreferences prefs,
    Future<String?> Function()? refreshAccessToken,
  })  : _tokenStorage = tokenStorage,
        _prefs = prefs,
        _refreshAccessToken = refreshAccessToken;

  @override
  Stream<AuthTokens?> get tokensStream => _tokensController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    await _migrateLegacyKeys();

    _initialized = true;
    await _emitCurrentTokens();
  }

  Future<void> _migrateLegacyKeys() async {
    // Read all sources in parallel to minimise native bridge round-trips
    final results = await Future.wait([
      _tokenStorage.readString('auth_token'),   // [0] legacySecureAccessToken
      _tokenStorage.readAccessToken(),           // [1] currentSecureAccess
      _tokenStorage.readRefreshToken(),          // [2] currentSecureRefresh
    ]);

    final legacySecureAccessToken = results[0];
    var currentSecureAccess = results[1];
    final currentSecureRefresh = results[2];

    // Migrate legacy secure 'auth_token' → standard access token key
    if ((currentSecureAccess == null || currentSecureAccess.isEmpty) &&
        legacySecureAccessToken != null &&
        legacySecureAccessToken.isNotEmpty) {
      await _tokenStorage.writeAccessToken(legacySecureAccessToken);
      await _tokenStorage.removeKey('auth_token');
      currentSecureAccess = legacySecureAccessToken;
    }

    // Migrate legacy SharedPreferences keys → secure storage
    final legacySpAccess = _prefs.getString('auth_access_token') ??
        _prefs.getString('auth_token') ??
        _prefs.getString(StorageKeys.accessToken);

    final legacySpRefresh = _prefs.getString('auth_refresh_token') ??
        _prefs.getString(StorageKeys.refreshToken);

    if ((currentSecureAccess == null || currentSecureAccess.isEmpty) &&
        legacySpAccess != null &&
        legacySpAccess.isNotEmpty) {
      await _tokenStorage.writeAccessToken(legacySpAccess);
      currentSecureAccess = legacySpAccess;
    }

    if ((currentSecureRefresh == null || currentSecureRefresh.isEmpty) &&
        legacySpRefresh != null &&
        legacySpRefresh.isNotEmpty) {
      await _tokenStorage.writeRefreshToken(legacySpRefresh);
    }

    // Sync effective tokens back to SharedPreferences + cleanup in parallel
    final effectiveAccess = currentSecureAccess;
    final effectiveRefresh = (currentSecureRefresh != null && currentSecureRefresh.isNotEmpty)
        ? currentSecureRefresh
        : legacySpRefresh;

    await Future.wait([
      if (effectiveAccess != null && effectiveAccess.isNotEmpty)
        _prefs.setString(StorageKeys.accessToken, effectiveAccess),
      if (effectiveRefresh != null && effectiveRefresh.isNotEmpty)
        _prefs.setString(StorageKeys.refreshToken, effectiveRefresh),
      _prefs.remove('auth_access_token'),
      _prefs.remove('auth_refresh_token'),
      _prefs.remove('auth_token'),
    ]);
  }

  Future<void> _emitCurrentTokens() async {
    final access = (await getAccessToken()) ?? '';
    final refresh = (await getRefreshToken()) ?? '';

    if (access.isEmpty && refresh.isEmpty) {
      _tokensController.add(null);
      return;
    }

    _tokensController.add(AuthTokens(accessToken: access, refreshToken: refresh));
  }

  @override
  Future<String?> getAccessToken() async {
    if (!_initialized) {
      await initialize();
    }

    final secure = await _tokenStorage.readAccessToken();
    if (secure != null && secure.isNotEmpty) {
      return secure;
    }

    final sp = _prefs.getString(StorageKeys.accessToken);
    if (sp != null && sp.isNotEmpty) {
      await _tokenStorage.writeAccessToken(sp);
      return sp;
    }

    return null;
  }

  @override
  Future<String?> getRefreshToken() async {
    if (!_initialized) {
      await initialize();
    }

    final secure = await _tokenStorage.readRefreshToken();
    if (secure != null && secure.isNotEmpty) {
      return secure;
    }

    final sp = _prefs.getString(StorageKeys.refreshToken);
    if (sp != null && sp.isNotEmpty) {
      await _tokenStorage.writeRefreshToken(sp);
      return sp;
    }

    return null;
  }

  @override
  Future<AuthTokens?> getTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();

    if (access == null || access.isEmpty) {
      return null;
    }

    return AuthTokens(
      accessToken: access,
      refreshToken: refresh ?? '',
    );
  }

  @override
  Future<void> saveAccessToken(String accessToken) async {
    if (!_initialized) {
      await initialize();
    }

    await _tokenStorage.writeAccessToken(accessToken);
    await _prefs.setString(StorageKeys.accessToken, accessToken);
    await _prefs.remove('auth_access_token');
    await _prefs.remove('auth_token');

    await _emitCurrentTokens();
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    if (!_initialized) {
      await initialize();
    }

    await _tokenStorage.writeRefreshToken(refreshToken);
    await _prefs.setString(StorageKeys.refreshToken, refreshToken);
    await _prefs.remove('auth_refresh_token');

    await _emitCurrentTokens();
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    if (!_initialized) {
      await initialize();
    }

    await Future.wait([
      _tokenStorage.writeAccessToken(tokens.accessToken),
      _tokenStorage.writeRefreshToken(tokens.refreshToken),
      _prefs.setString(StorageKeys.accessToken, tokens.accessToken),
      _prefs.setString(StorageKeys.refreshToken, tokens.refreshToken),
      _prefs.remove('auth_access_token'),
      _prefs.remove('auth_refresh_token'),
      _prefs.remove('auth_token'),
    ]);

    await _emitCurrentTokens();
  }

  @override
  Future<String?> refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    if (_refreshAccessToken == null) {
      return null;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final token = await _refreshAccessToken!();
      if (token != null && token.isNotEmpty) {
        await saveAccessToken(token);
      }
      completer.complete(token);
    } catch (_) {
      completer.complete(null);
    } finally {
      _refreshCompleter = null;
    }

    return completer.future;
  }

  @override
  Future<void> clear() async {
    if (!_initialized) {
      await initialize();
    }

    await Future.wait([
      _tokenStorage.clear(),
      _prefs.remove(StorageKeys.accessToken),
      _prefs.remove(StorageKeys.refreshToken),
      _prefs.remove('auth_access_token'),
      _prefs.remove('auth_refresh_token'),
      _prefs.remove('auth_token'),
    ]);

    _tokensController.add(null);
  }
}
