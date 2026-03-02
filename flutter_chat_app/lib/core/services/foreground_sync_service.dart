import 'dart:async';

import 'package:flutter_chat_app/core/services/chat_module_event_bus.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Foreground sync service that runs in the main isolate.
///
/// Listens to [ChatModuleEventBus.syncTriggerStream] and performs
/// a full sync of chat data using the DI-provided repository.
/// Unlike [BackgroundSyncHelper], this has access to GetIt dependencies.
@lazySingleton
class ForegroundSyncService {
  final IChatRepository _repository;
  final ChatModuleEventBus _eventBus;
  final AppLogger _logger;

  StreamSubscription<void>? _syncSubscription;
  bool _isSyncing = false;

  ForegroundSyncService({
    required IChatRepository repository,
    required ChatModuleEventBus eventBus,
    required AppLogger logger,
  })  : _repository = repository,
        _eventBus = eventBus,
        _logger = logger;

  /// Start listening for sync triggers.
  void initialize() {
    _syncSubscription?.cancel();
    _syncSubscription = _eventBus.syncTriggerStream.listen((_) => sync());
    _logger.d('ForegroundSyncService: Initialized');
  }

  /// Perform a foreground sync: fetch chats from server, save locally,
  /// and update the unread count on the event bus.
  Future<void> sync() async {
    if (_isSyncing) {
      _logger.d('ForegroundSyncService: Sync already in progress, skipping');
      return;
    }

    _isSyncing = true;
    _logger.i('ForegroundSyncService: Starting sync');

    try {
      final result = await _repository.getChats();

      result.fold(
        (failure) {
          _logger.error('ForegroundSyncService: Sync failed', failure);
        },
        (chats) {
          // Compute total unread count and update event bus
          int totalUnread = 0;
          for (final chat in chats) {
            totalUnread += chat.unreadCount;
          }
          _eventBus.updateTotalUnreadCount(totalUnread);
          _logger.i('ForegroundSyncService: Synced ${chats.length} chats, '
              'totalUnread=$totalUnread');
        },
      );
    } catch (e, stackTrace) {
      _logger.error('ForegroundSyncService: Unexpected error', e, stackTrace);
    } finally {
      _isSyncing = false;
    }
  }

  /// Stop listening and clean up.
  void dispose() {
    _syncSubscription?.cancel();
    _syncSubscription = null;
  }
}
