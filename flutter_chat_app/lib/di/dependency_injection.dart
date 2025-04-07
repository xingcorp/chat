import 'package:flutter_chat_app/core/utils/system_resources.dart';

@module
abstract class AppModule {
  // ... existing declarations ...
  
  // Register SystemResourceMonitor as a singleton
  @singleton
  SystemResourceMonitor provideSystemResourceMonitor() {
    return SystemResourceMonitor();
  }
} 