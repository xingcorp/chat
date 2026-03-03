import 'dart:async';

import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/domain/entities/user_presence.dart';
import 'package:flutter_chat_app/domain/repositories/i_presence_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

typedef NowProvider = DateTime Function();

@lazySingleton
class PresenceService {
  PresenceService({
    required IPresenceRepository repository,
    required RealtimeService realtimeService,
    required AppLogger logger,
  })  : _repository = repository,
        _realtimeService = realtimeService,
        _logger = logger,
        _cacheTtl = const Duration(seconds: 30),
        _now = DateTime.now {
    _subscribeSocketEvents();
  }

  PresenceService.test({
    required IPresenceRepository repository,
    required RealtimeService realtimeService,
    required AppLogger logger,
    Duration cacheTtl = const Duration(seconds: 30),
    NowProvider? now,
  })  : _repository = repository,
        _realtimeService = realtimeService,
        _logger = logger,
        _cacheTtl = cacheTtl,
        _now = now ?? DateTime.now {
    _subscribeSocketEvents();
  }

  final IPresenceRepository _repository;
  final RealtimeService _realtimeService;
  final AppLogger _logger;
  final Duration _cacheTtl;
  final NowProvider _now;

  final Map<String, _CachedPresence> _cache = <String, _CachedPresence>{};
  final Map<String, BehaviorSubject<UserPresence>> _subjects =
      <String, BehaviorSubject<UserPresence>>{};
  final Set<String> _trackedUserIds = <String>{};
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  Stream<UserPresence> getUserPresenceStream(String userId) {
    final normalizedId = _normalizeUserId(userId);
    if (normalizedId.isEmpty) {
      return Stream<UserPresence>.value(UserPresence.offlineFor(userId));
    }

    _trackedUserIds.add(normalizedId);
    final subject = _ensureSubject(normalizedId);
    _emitCachedIfAvailable(normalizedId, subject);
    unawaited(_fetchIfNeeded(normalizedId));
    return subject.stream;
  }

  Future<void> fetchPresenceForUsers(List<String> userIds) async {
    final normalizedIds = userIds
        .map(_normalizeUserId)
        .where((String id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedIds.isEmpty) {
      return;
    }

    _trackedUserIds.addAll(normalizedIds);

    final staleIds = normalizedIds
        .where((String userId) => _isCacheStale(userId))
        .toList(growable: false);
    if (staleIds.isEmpty) {
      return;
    }

    final requestedAt = _now();
    final result = await _repository.getUsersPresence(staleIds);
    result.fold(
      (failure) {
        _logger.w(
          'Presence batch fetch failed',
          context: <String, dynamic>{
            'userIds': staleIds,
            'error': failure.message,
            'code': failure.code,
          },
        );
        for (final userId in staleIds) {
          _updateCache(
            UserPresence.offlineFor(userId),
            sourceFetchedAt: requestedAt,
            allowOlderUpdate: false,
          );
        }
      },
      (presences) {
        final receivedUserIds = <String>{};
        for (final presence in presences) {
          final normalizedPresenceId = _normalizeUserId(presence.userId);
          if (normalizedPresenceId.isEmpty) {
            continue;
          }
          receivedUserIds.add(normalizedPresenceId);
          _updateCache(
            UserPresence(
              userId: normalizedPresenceId,
              isOnline: presence.isOnline,
              lastSeen: presence.lastSeen,
            ),
            sourceFetchedAt: requestedAt,
            allowOlderUpdate: false,
          );
        }

        for (final userId in staleIds) {
          if (!receivedUserIds.contains(userId)) {
            _updateCache(
              UserPresence.offlineFor(userId),
              sourceFetchedAt: requestedAt,
              allowOlderUpdate: false,
            );
          }
        }
      },
    );
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    for (final subject in _subjects.values) {
      subject.close();
    }
    _subjects.clear();
    _cache.clear();
    _trackedUserIds.clear();
  }

  Future<void> _fetchIfNeeded(String userId) async {
    if (!_isCacheStale(userId)) {
      return;
    }
    await fetchPresenceForUsers(<String>[userId]);
  }

  bool _isCacheStale(String userId) {
    final cached = _cache[userId];
    if (cached == null) {
      return true;
    }
    return _now().difference(cached.cachedAt) >= _cacheTtl;
  }

  void _subscribeSocketEvents() {
    _subscriptions.add(
      _realtimeService.presenceStream.listen(_handleRealtimePresence),
    );
  }

  void _handleRealtimePresence(UserPresence presence) {
    final normalizedId = _normalizeUserId(presence.userId);
    if (normalizedId.isEmpty) {
      return;
    }

    if (_trackedUserIds.isNotEmpty && !_trackedUserIds.contains(normalizedId)) {
      return;
    }

    _updateCache(
      UserPresence(
        userId: normalizedId,
        isOnline: presence.isOnline,
        lastSeen: presence.lastSeen,
      ),
      sourceFetchedAt: _now(),
      allowOlderUpdate: true,
    );
  }

  void _emitCachedIfAvailable(
    String userId,
    BehaviorSubject<UserPresence> subject,
  ) {
    final cached = _cache[userId];
    if (cached == null) {
      return;
    }

    final currentValue = subject.valueOrNull;
    if (currentValue != cached.presence) {
      subject.add(cached.presence);
    }
  }

  BehaviorSubject<UserPresence> _ensureSubject(String userId) {
    return _subjects.putIfAbsent(userId, () => BehaviorSubject<UserPresence>());
  }

  // Guard against race condition: a socket update may arrive after API request starts.
  // When API response returns, do not override cache if a newer update already exists.
  void _updateCache(
    UserPresence presence, {
    required DateTime sourceFetchedAt,
    required bool allowOlderUpdate,
  }) {
    final normalizedId = _normalizeUserId(presence.userId);
    if (normalizedId.isEmpty) {
      return;
    }

    final existing = _cache[normalizedId];
    if (!allowOlderUpdate &&
        existing != null &&
        existing.cachedAt.isAfter(sourceFetchedAt)) {
      return;
    }

    final normalizedPresence = UserPresence(
      userId: normalizedId,
      isOnline: presence.isOnline,
      lastSeen: presence.lastSeen,
    );

    final cachedEntry = _CachedPresence(
      presence: normalizedPresence,
      cachedAt: _now(),
    );
    _cache[normalizedId] = cachedEntry;
    _ensureSubject(normalizedId).add(normalizedPresence);
  }

  String _normalizeUserId(String rawUserId) {
    return rawUserId.trim();
  }
}

class _CachedPresence {
  const _CachedPresence({
    required this.presence,
    required this.cachedAt,
  });

  final UserPresence presence;
  final DateTime cachedAt;
}
