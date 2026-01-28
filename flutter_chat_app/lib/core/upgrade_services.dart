import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/core/services/attachment_queue_service.dart';
import 'package:flutter_chat_app/core/services/media_cache.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/local_storage_service.dart';
import 'package:flutter_chat_app/core/network/realtime/realtime_connection_service.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/core/utils/isolate_manager.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:flutter_chat_app/domain/repositories/i_attachment_repository.dart';

/// DEPRECATED: This file is no longer needed as MessageQueueService is now the standard.
/// The upgrade logic has been removed as part of Clean Architecture refactoring.
/// 
/// MessageQueueService is now registered directly in the DI container.
/// 
/// This file is kept temporarily for backward compatibility and will be removed in a future release.

/// Upgrades the application to use the MessageQueueService
/// 
/// DEPRECATED: This function is no longer needed. MessageQueueService is now
/// registered directly in the DI container during initialization.
/// 
/// Returns true if the service is already registered, false otherwise.
@Deprecated('MessageQueueService is now registered directly in DI. This function will be removed.')
Future<bool> upgradeToEnhancedMessageQueue() async {
  final getIt = GetIt.instance;
  
  try {
    // Check if the service is already registered
    if (getIt.isRegistered<MessageQueueService>()) {
      debugPrint('MessageQueueService is already registered');
      return true;
    }
    
    debugPrint('MessageQueueService should be registered in DI container during initialization');
    return false;
  } catch (e, stackTrace) {
    debugPrint('Error checking MessageQueueService registration: $e');
    debugPrint(stackTrace.toString());
    return false;
  }
}

/// Stub implementation of IAttachmentRepository for fallback purposes
class StubAttachmentRepository implements IAttachmentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    debugPrint('Warning: Stub attachment repository method called: ${invocation.memberName}');
    return null;
  }
} 