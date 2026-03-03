import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/entities/user_presence.dart';

/// Repository contract for querying user presence.
abstract class IPresenceRepository {
  /// Query presence for a batch of user ids.
  Future<Either<Failure, List<UserPresence>>> getUsersPresence(
    List<String> userIds,
  );
}
