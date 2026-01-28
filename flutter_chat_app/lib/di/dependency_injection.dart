import 'package:flutter_chat_app/core/database/database_service.dart';
import 'package:flutter_chat_app/core/utils/system_resources.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AppModule {
  // Register SystemResourceMonitor as a singleton
  @singleton
  SystemResourceMonitor provideSystemResourceMonitor() {
    return SystemResourceMonitor();
  }
  
  // Register the legacy DatabaseService (manual singleton from core/database/)
  // Note: This is different from the DI-managed DatabaseService in core/services/
  @singleton
  DatabaseService provideLegacyDatabaseService() {
    return DatabaseService.instance;
  }
}