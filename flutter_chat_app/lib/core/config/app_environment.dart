/// Runtime deployment mode of the chat module.
///
/// The same `flutter_chat_app` package runs in two modes, which changes how
/// bundled assets resolve:
/// - [standalone]: this package IS the root app. Assets live at the bare path
///   (`assets/icons/...`), so asset loaders must NOT be given a package.
/// - [package]: embedded in a host app as a dependency. Assets live under
///   `packages/flutter_chat_app/assets/...`, so asset loaders MUST be qualified
///   with the package name or they resolve to nothing (transparent icons).
enum AppRuntimeMode {
  /// Running as the root app (own `main.dart`).
  standalone,

  /// Embedded in a host app via `ChatModule.initialize`.
  package,
}

/// Explicit, single source of truth for the current [AppRuntimeMode].
///
/// Set once at startup:
/// - standalone entry points keep the default ([AppRuntimeMode.standalone]);
/// - `ChatModuleInjection.initialize` sets [AppRuntimeMode.package] and
///   `ChatModuleInjection.dispose` resets it to standalone.
///
/// Prefer this over inferring the mode from side effects (e.g. config
/// overrides), which is implicit and breaks silently.
class AppEnvironment {
  AppEnvironment._();

  /// The pub package name — must match `name:` in pubspec.yaml.
  static const String packageName = 'flutter_chat_app';

  /// Current runtime mode. Defaults to standalone so the root app needs no
  /// wiring; only package mode sets it explicitly.
  static AppRuntimeMode mode = AppRuntimeMode.standalone;

  /// True when embedded in a host app.
  static bool get isPackageMode => mode == AppRuntimeMode.package;

  /// Package name to pass to bundled asset loaders (`AssetImage`,
  /// `Image.asset`, `SvgPicture.asset`).
  ///
  /// Returns [packageName] in package mode, `null` in standalone (passing a
  /// package there would break resolution).
  static String? get assetPackage => isPackageMode ? packageName : null;
}
