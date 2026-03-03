import 'dart:async';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/services/presence_service.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/entities/user_presence.dart';
import 'package:flutter_chat_app/domain/repositories/i_presence_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRealtimeService extends Mock implements RealtimeService {}

class _FakePresenceRepository implements IPresenceRepository {
  final List<List<String>> requestedBatches = <List<String>>[];
  Either<Failure, List<UserPresence>> Function(List<String> userIds)? onRequest;

  @override
  Future<Either<Failure, List<UserPresence>>> getUsersPresence(
    List<String> userIds,
  ) async {
    requestedBatches.add(List<String>.from(userIds));
    final requestHandler = onRequest;
    if (requestHandler != null) {
      return requestHandler(userIds);
    }
    return const Right<Failure, List<UserPresence>>(<UserPresence>[]);
  }
}

void main() {
  late _FakePresenceRepository repository;
  late _MockRealtimeService realtimeService;
  late StreamController<UserPresence> realtimeController;
  late PresenceService service;

  setUp(() {
    repository = _FakePresenceRepository();
    realtimeService = _MockRealtimeService();
    realtimeController = StreamController<UserPresence>.broadcast();
    when(
      () => realtimeService.presenceStream,
    ).thenAnswer((_) => realtimeController.stream);

    service = PresenceService(
      repository: repository,
      realtimeService: realtimeService,
      logger: AppLogger(),
    );
  });

  tearDown(() async {
    service.dispose();
    await realtimeController.close();
  });

  test('cache hit does not fetch again while cache is valid', () async {
    repository.onRequest = (userIds) {
      return Right<Failure, List<UserPresence>>(
        <UserPresence>[
          UserPresence(
            userId: userIds.first,
            isOnline: true,
          ),
        ],
      );
    };

    final firstPresence = await service.getUserPresenceStream('user_1').first;
    expect(firstPresence.isOnline, isTrue);
    expect(repository.requestedBatches, <List<String>>[
      <String>['user_1'],
    ]);

    await service.fetchPresenceForUsers(<String>['user_1']);
    expect(repository.requestedBatches.length, 1);
  });

  test('cache miss fetches repository and emits value', () async {
    repository.onRequest = (userIds) {
      return Right<Failure, List<UserPresence>>(
        <UserPresence>[
          UserPresence(
            userId: userIds.first,
            isOnline: false,
            lastSeen: DateTime(2026, 1, 1, 8, 30),
          ),
        ],
      );
    };

    final presence = await service.getUserPresenceStream('user_2').first;
    expect(presence.userId, 'user_2');
    expect(presence.isOnline, isFalse);
    expect(
      presence.lastSeen,
      DateTime(2026, 1, 1, 8, 30),
    );
    expect(repository.requestedBatches, <List<String>>[
      <String>['user_2'],
    ]);
  });

  test('socket update updates cache and stream listeners', () async {
    repository.onRequest = (userIds) {
      return Right<Failure, List<UserPresence>>(
        <UserPresence>[
          UserPresence(
            userId: userIds.first,
            isOnline: false,
          ),
        ],
      );
    };

    final stream = service.getUserPresenceStream('user_3');
    final initialPresence = await stream.first;
    expect(initialPresence.isOnline, isFalse);

    final updatedPresenceFuture = stream.skip(1).first;
    realtimeController.add(
      const UserPresence(
        userId: 'user_3',
        isOnline: true,
      ),
    );

    final updatedPresence = await updatedPresenceFuture;
    expect(updatedPresence.isOnline, isTrue);
  });

  test('batch fetch only requests stale user ids', () async {
    final now = DateTime(2026, 3, 1, 8, 0);
    var fakeNow = now;
    service.dispose();
    service = PresenceService.test(
      repository: repository,
      realtimeService: realtimeService,
      logger: AppLogger(),
      cacheTtl: const Duration(seconds: 30),
      now: () => fakeNow,
    );

    repository.onRequest = (userIds) {
      return Right<Failure, List<UserPresence>>(
        userIds
            .map(
              (id) => UserPresence(
                userId: id,
                isOnline: id == 'user_1',
              ),
            )
            .toList(growable: false),
      );
    };

    await service.fetchPresenceForUsers(<String>['user_1', 'user_2']);
    expect(repository.requestedBatches, <List<String>>[
      <String>['user_1', 'user_2'],
    ]);

    fakeNow = fakeNow.add(const Duration(seconds: 5));
    await service.fetchPresenceForUsers(<String>['user_1', 'user_2', 'user_3']);
    expect(repository.requestedBatches, <List<String>>[
      <String>['user_1', 'user_2'],
      <String>['user_3'],
    ]);
  });
}
