import 'package:injectable/injectable.dart';

import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/data/graphql/chat_operations.dart';

/// **Push Notification Remote Data Source**
///
/// Handles push notification operations via GraphQL API.
/// Triggers backend to send Firebase Cloud Messaging notifications to users.
///
/// **Architecture:** Clean Architecture - Data Layer
/// **Pattern:** Remote data source for push notification operations
@lazySingleton
class PushNotificationRemoteDataSource {
  final GraphQLClientWrapper _graphqlClient;

  PushNotificationRemoteDataSource(this._graphqlClient);

  /// **Notify Users**
  ///
  /// Triggers push notification to specified users via backend.
  /// Backend sends Firebase Cloud Messaging notifications to user devices.
  ///
  /// **Parameters:**
  /// - receiverIds: List of user IDs to notify (required)
  /// - title: Notification title (required)
  /// - content: Notification body text (required)
  /// - metadata: Additional data for deep linking (optional)
  ///
  /// **Returns:** Boolean indicating success/failure
  ///
  /// **Use Cases:**
  /// - Mention notifications: notify users when mentioned in messages
  /// - Important messages: trigger push for high-priority content
  /// - Custom alerts: send targeted notifications to specific users
  ///
  /// **Requirements:** 2.2
  Future<bool> notifyUsers({
    required List<String> receiverIds,
    required String title,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final variables = <String, dynamic>{
      'arguments': {
        'receiverIds': receiverIds,
        'title': title,
        'content': content,
        if (metadata != null) 'metadata': metadata,
      },
    };

    final result = await _graphqlClient.mutate(
      ChatMutations.notifyUser,
      variables: variables,
      operationName: 'NotifyUser',
    );

    return result['chatNotifyUser'] as bool? ?? false;
  }
}
