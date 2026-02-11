import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/core/initialization/app_bootstrap.dart';

export 'package:flutter_chat_app/core/initialization/app_bootstrap.dart'
    show runMainApp;
export 'package:flutter_chat_app/app.dart' show MyApp;

Future<void> main() async {
  if (!FlavorConfig.isInitialized) {
    FlavorConfig.initializeFromEnvironment();
  }
  await runMainApp();
}
