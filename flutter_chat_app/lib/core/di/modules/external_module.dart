/// External Module - Register third-party dependencies
///
/// This module registers external packages that cannot be auto-registered
/// by build_runner because they don't have @injectable annotations.
///
/// The @module annotation tells build_runner to include these registrations
/// in the generated injection.config.dart.

import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';

@module
abstract class ExternalModule {
  /// AppLogger singleton for the entire app
  /// Used by all @injectable classes that depend on AppLogger
  @singleton
  AppLogger get appLogger => AppLogger();
}
