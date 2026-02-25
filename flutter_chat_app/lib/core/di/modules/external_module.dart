/// External Module - Register third-party dependencies
///
/// This module registers external packages that cannot be auto-registered
/// by build_runner because they don't have @injectable annotations.
///
/// The @module annotation tells build_runner to include these registrations
/// in the generated injection.config.dart.

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@module
abstract class ExternalModule {
  /// Logger singleton for the entire app
  @singleton
  Logger get logger => Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
}
