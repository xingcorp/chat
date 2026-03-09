/// Stub — no-op for web and other non-IO platforms.
library;

Future<void> ensureMediaKitInitializedImpl() async {
  // Nothing to do on web / unsupported platforms.
}
