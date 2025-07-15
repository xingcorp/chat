import 'package:flutter_chat_app/core/utils/system_resources.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AppModule {
  // Register SystemResourceMonitor as a singleton
  @singleton
  SystemResourceMonitor provideSystemResourceMonitor() {
    return SystemResourceMonitor();
  }
}