/// Delegate for handling authentication lifecycle events.
///
/// Host apps implement this to handle auth-related events from the chat module
/// (e.g., redirect to login when session expires).
abstract class AuthDelegate {
  /// Called when authentication has expired and cannot be refreshed.
  /// Host app should navigate to login screen.
  void onAuthExpired();

  /// Called when a token has been successfully refreshed.
  /// Host app can update its own token storage if needed.
  void onTokenRefreshed(String newAccessToken) {}
}

/// Default no-op implementation for standalone mode.
class NoOpAuthDelegate implements AuthDelegate {
  const NoOpAuthDelegate();

  @override
  void onAuthExpired() {
    // In standalone mode, auth expiry is handled by the app's own navigation
  }

  @override
  void onTokenRefreshed(String newAccessToken) {}
}

/// Callback-based implementation for package mode.
///
/// Delegates auth events to callbacks provided via [ChatConfig].
class CallbackAuthDelegate implements AuthDelegate {
  final void Function()? _onAuthExpired;
  final void Function(String newAccessToken)? _onTokenRefreshed;

  const CallbackAuthDelegate({
    void Function()? onAuthExpired,
    void Function(String newAccessToken)? onTokenRefreshed,
  })  : _onAuthExpired = onAuthExpired,
        _onTokenRefreshed = onTokenRefreshed;

  @override
  void onAuthExpired() {
    _onAuthExpired?.call();
  }

  @override
  void onTokenRefreshed(String newAccessToken) {
    _onTokenRefreshed?.call(newAccessToken);
  }
}
