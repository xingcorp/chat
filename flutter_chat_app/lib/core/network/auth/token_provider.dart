import 'package:flutter_chat_app/core/network/auth/token_repository.dart';

/// Interface for providing authentication tokens to the chat module.
///
/// Host apps implement this to supply tokens from their own auth system.
/// The chat module never manages auth flows directly.
abstract class TokenProvider {
  /// Get the current access token. Returns null if not authenticated.
  Future<String?> getAccessToken();

  /// Get the current refresh token. Returns null if not available.
  Future<String?> getRefreshToken();

  /// Attempt to refresh the access token.
  /// Returns the new access token, or null if refresh failed.
  Future<String?> refreshAccessToken();

  /// Stream of token changes. Emits null when tokens are cleared (logout).
  Stream<AuthTokens?> get tokensStream;
}
