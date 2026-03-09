import 'package:get_it/get_it.dart';

import 'package:flutter_chat_app/core/services/chat_active_conversation_tracker.dart';
import 'package:flutter_chat_app/core/services/chat_notification_orchestrator.dart';
import 'package:flutter_chat_app/core/services/chat_notification_policy_service.dart';
import 'package:flutter_chat_app/core/services/chat_conversation_selection_service.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/services/local_notification_service.dart';
import 'package:flutter_chat_app/core/services/notification_handler_service.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';

/// Registers notification infrastructure after auto-generated DI is ready.
void registerNotificationModule(GetIt getIt) {
  if (!getIt.isRegistered<ChatConversationSelectionService>()) {
    getIt.registerSingleton<ChatConversationSelectionService>(
      ChatConversationSelectionService(),
    );
  }

  if (!getIt.isRegistered<ChatActiveConversationTracker>()) {
    getIt.registerSingleton<ChatActiveConversationTracker>(
      ChatActiveConversationTracker(),
    );
  }

  if (!getIt.isRegistered<LocalNotificationService>()) {
    getIt.registerLazySingleton<LocalNotificationService>(
      () => LocalNotificationService(
        logger: getIt<AppLogger>(),
      ),
    );
  }

  if (!getIt.isRegistered<ChatNotificationPolicyService>()) {
    getIt.registerLazySingleton<ChatNotificationPolicyService>(
      () => ChatNotificationPolicyService(
        currentUserProvider: getIt<CurrentUserProvider>(),
        activeConversationTracker: getIt<ChatActiveConversationTracker>(),
        logger: getIt<AppLogger>(),
      ),
    );
  }

  if (!getIt.isRegistered<ChatNotificationOrchestrator>()) {
    getIt.registerLazySingleton<ChatNotificationOrchestrator>(
      () => ChatNotificationOrchestrator(
        realtimeService: getIt<RealtimeService>(),
        notificationPolicy: getIt<ChatNotificationPolicyService>(),
        localNotificationService: getIt<LocalNotificationService>(),
        notificationHandlerService: getIt<NotificationHandlerService>(),
        logger: getIt<AppLogger>(),
      ),
    );
  }
}
