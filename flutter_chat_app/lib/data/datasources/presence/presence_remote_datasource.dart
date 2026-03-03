import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/data/graphql/presence_operations.dart';
import 'package:flutter_chat_app/data/models/user_presence_model.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PresenceRemoteDataSource {
  PresenceRemoteDataSource(this._graphqlClient);

  final GraphQLClientWrapper _graphqlClient;

  Future<List<UserPresenceModel>> getUsersPresence(List<String> userIds) async {
    final normalizedIds = userIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedIds.isEmpty) {
      return const <UserPresenceModel>[];
    }

    final result = await _graphqlClient.query(
      PresenceQueries.getUserPresence,
      variables: <String, dynamic>{'userIds': normalizedIds},
      operationName: 'GetUserPresence',
    );

    final rawList = _extractPresenceList(result);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(UserPresenceModel.fromJson)
        .toList(growable: false);
  }

  List<dynamic> _extractPresenceList(Map<String, dynamic> result) {
    final payload = result['chatUserPresence'];
    if (payload is List<dynamic>) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      final items = payload['items'];
      if (items is List<dynamic>) {
        return items;
      }

      final data = payload['data'];
      if (data is List<dynamic>) {
        return data;
      }
    }

    throw Exception('chatUserPresence query returned invalid payload');
  }
}
