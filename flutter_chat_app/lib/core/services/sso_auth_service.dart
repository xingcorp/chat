import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';

/// SSO Authentication Result
class SsoAuthResult {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final DateTime? accessTokenExpirationDateTime;

  const SsoAuthResult({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.accessTokenExpirationDateTime,
  });
}

/// SSO Configuration
class SsoConfig {
  final String issuer;
  final String clientId;
  final String redirectUri;
  final List<String> scopes;
  final String? idpHint;

  const SsoConfig({
    required this.issuer,
    required this.clientId,
    required this.redirectUri,
    this.scopes = const ['openid', 'profile', 'email'],
    this.idpHint,
  });

  /// Default Keycloak configuration
  static SsoConfig keycloak({String? idpHint}) => SsoConfig(
    issuer: 'https://auth.smarthiz.com/realms/oxii',
    clientId: 'sso-client',
    redirectUri: 'com.oxii.office.mobile://auth/callback',
    scopes: const ['openid', 'profile', 'email'],
    idpHint: idpHint,
  );

  /// Google SSO via Keycloak
  /// Temporarily disabled idpHint for debugging
  static SsoConfig google() => keycloak(idpHint: null);
}

/// SSO Authentication Service using flutter_appauth
/// Handles OAuth 2.0 / OpenID Connect authentication with PKCE
/// Only available in standalone mode (mobile platforms only, not web)
@LazySingleton(env: [Environment.dev, Environment.prod, 'standalone'])
class SsoAuthService {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final Logger _logger = Logger();

  /// Authenticate with SSO provider
  ///
  /// [config] - SSO configuration (use SsoConfig.google() for Google SSO)
  /// Returns Either<Failure, SsoAuthResult> with tokens on success
  Future<Either<Failure, SsoAuthResult>> authenticate(SsoConfig config) async {
    try {
      _logger.i('=== SSO Authentication Debug ===');
      _logger.i('Issuer: ${config.issuer}');
      _logger.i('Client ID: ${config.clientId}');
      _logger.i('Redirect URI: ${config.redirectUri}');
      _logger.i('Scopes: ${config.scopes.join(', ')}');
      _logger.i('IDP Hint: ${config.idpHint ?? 'none'}');

      // Build the discovery URL
      final discoveryUrl = '${config.issuer}/.well-known/openid-configuration';
      _logger.i('Discovery URL: $discoveryUrl');

      // Build authorization request with PKCE
      final request = AuthorizationTokenRequest(
        config.clientId,
        config.redirectUri,
        discoveryUrl: discoveryUrl,
        scopes: config.scopes,
        additionalParameters: config.idpHint != null
          ? {'kc_idp_hint': config.idpHint!}
          : null,
        allowInsecureConnections: false,
      );

      _logger.i('Calling authorizeAndExchangeCode...');
      final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(request);

      if (result == null) {
        _logger.w('SSO authentication cancelled by user');
        return Left(AuthenticationFailure(
          message: 'SSO authentication cancelled by user',
          code: 'sso_cancelled',
        ));
      }

      _logger.i('=== SSO Response Debug ===');
      _logger.i('Access Token: ${result.accessToken != null ? '${result.accessToken!.substring(0, 20)}...' : 'null'}');
      _logger.i('Refresh Token: ${result.refreshToken != null ? 'present' : 'null'}');
      _logger.i('ID Token: ${result.idToken != null ? 'present' : 'null'}');
      _logger.i('Token Type: ${result.tokenType}');
      _logger.i('Expires: ${result.accessTokenExpirationDateTime}');

      if (result.accessToken == null || result.accessToken!.isEmpty) {
        _logger.e('SSO authentication failed: no access token received');
        return Left(AuthenticationFailure(
          message: 'No access token received from SSO',
          code: 'sso_no_token',
        ));
      }

      _logger.i('SSO authentication successful');

      return Right(SsoAuthResult(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
        accessTokenExpirationDateTime: result.accessTokenExpirationDateTime,
      ));
    } catch (e, stackTrace) {
      _logger.e('=== SSO Error Debug ===');
      _logger.e('Error Type: ${e.runtimeType}');
      _logger.e('Error Message: $e');
      _logger.e('Stack Trace:', error: e, stackTrace: stackTrace);

      final errorCode = _parseErrorCode(e);
      _logger.e('Parsed Error Code: $errorCode');

      return Left(AuthenticationFailure(
        message: 'SSO authentication error: ${e.toString()}',
        code: errorCode,
      ));
    }
  }

  /// Authenticate with Google via Keycloak SSO
  Future<Either<Failure, SsoAuthResult>> authenticateWithGoogle() {
    return authenticate(SsoConfig.google());
  }

  /// Authenticate with default Keycloak SSO (shows login page)
  Future<Either<Failure, SsoAuthResult>> authenticateWithKeycloak() {
    return authenticate(SsoConfig.keycloak());
  }

  /// Refresh access token using refresh token
  Future<Either<Failure, SsoAuthResult>> refreshToken({
    required String refreshToken,
    SsoConfig? config,
  }) async {
    try {
      final ssoConfig = config ?? SsoConfig.keycloak();

      _logger.i('Refreshing SSO token');

      final TokenResponse? result = await _appAuth.token(
        TokenRequest(
          ssoConfig.clientId,
          ssoConfig.redirectUri,
          issuer: ssoConfig.issuer,
          refreshToken: refreshToken,
          scopes: ssoConfig.scopes,
        ),
      );

      if (result == null || result.accessToken == null) {
        _logger.e('Token refresh failed: no token received');
        return Left(AuthenticationFailure(
          message: 'Token refresh failed: no token received',
          code: 'sso_refresh_failed',
        ));
      }

      _logger.i('Token refresh successful');

      return Right(SsoAuthResult(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
        accessTokenExpirationDateTime: result.accessTokenExpirationDateTime,
      ));
    } catch (e, stackTrace) {
      _logger.e('Token refresh error', error: e, stackTrace: stackTrace);

      return Left(AuthenticationFailure(
        message: 'Token refresh error: ${e.toString()}',
        code: 'sso_refresh_error',
      ));
    }
  }

  /// Parse error code from exception
  String _parseErrorCode(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('cancelled') || errorStr.contains('canceled')) {
      return 'sso_cancelled';
    }

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'sso_network_error';
    }

    if (errorStr.contains('timeout')) {
      return 'sso_timeout';
    }

    if (errorStr.contains('invalid_grant')) {
      return 'sso_invalid_grant';
    }

    return 'sso_error';
  }
}
