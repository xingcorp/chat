import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_chat_app/core/services/enhanced_message_queue_service.dart';
import 'package:flutter_chat_app/core/services/attachment_queue_service.dart';
import 'package:flutter_chat_app/core/services/media_cache.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/local_storage_service.dart';
import 'package:flutter_chat_app/core/network/realtime/realtime_connection_service.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:flutter_chat_app/domain/repositories/i_attachment_repository.dart';

/// Upgrades the application to use the EnhancedMessageQueueService
/// 
/// This function registers all necessary services to enable the 
/// enhanced message queue functionality.
/// 
/// Returns true if the upgrade was successful, false otherwise.
Future<bool> upgradeToEnhancedMessageQueue() async {
  final getIt = GetIt.instance;
  
  try {
    // Check if the service is already registered
    if (getIt.isRegistered<EnhancedMessageQueueService>()) {
      debugPrint('EnhancedMessageQueueService is already registered');
      return true;
    }
    
    // Ensure all required dependencies are available
    if (!getIt.isRegistered<IMessageRepository>() ||
        !getIt.isRegistered<LocalStorageService>() ||
        !getIt.isRegistered<ConnectivityService>() ||
        !getIt.isRegistered<IRealtimeConnectionService>()) {
      debugPrint('Missing required dependencies for EnhancedMessageQueueService');
      return false;
    }
    
    // Register MediaCache if not already registered
    if (!getIt.isRegistered<MediaCache>()) {
      final mediaCache = await MediaCache.create();
      getIt.registerSingleton<MediaCache>(mediaCache);
      debugPrint('Registered MediaCache service');
    }
    
    // Register or retrieve IAttachmentRepository
    if (!getIt.isRegistered<IAttachmentRepository>()) {
      debugPrint('Warning: No IAttachmentRepository found. Some attachment features may not work.');
      // Create a stub implementation to avoid crashes
      getIt.registerSingleton<IAttachmentRepository>(StubAttachmentRepository());
    }
    
    // Register AttachmentQueueService if not already registered
    if (!getIt.isRegistered<AttachmentQueueService>()) {
      final attachmentQueueService = AttachmentQueueService(
        getIt<IAttachmentRepository>(),
        getIt<ConnectivityService>(),
        getIt<LocalStorageService>(),
        getIt<MediaCache>(),
      );
      
      // Initialize the service
      await attachmentQueueService.initialize();
      
      getIt.registerSingleton<AttachmentQueueService>(attachmentQueueService);
      debugPrint('Registered and initialized AttachmentQueueService');
    }
    
    // Now register EnhancedMessageQueueService
    final enhancedMessageQueueService = EnhancedMessageQueueService(
      getIt<IMessageRepository>(),
      getIt<LocalStorageService>(),
      getIt<ConnectivityService>(),
      getIt<IRealtimeConnectionService>(),
      getIt<AttachmentQueueService>(),
    );
    
    // Initialize service
    await enhancedMessageQueueService.initialize();
    
    // Register service
    getIt.registerSingleton<EnhancedMessageQueueService>(enhancedMessageQueueService);
    debugPrint('Successfully registered and initialized EnhancedMessageQueueService');
    
    return true;
  } catch (e, stackTrace) {
    debugPrint('Error upgrading to EnhancedMessageQueueService: $e');
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