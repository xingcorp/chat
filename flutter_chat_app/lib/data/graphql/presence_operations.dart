/// GraphQL operations for user presence.
class PresenceQueries {
  static const String getUserPresence = r'''
    query GetUserPresence($userIds: [String!]!) {
      chatUserPresence(userIds: $userIds) {
        userId
        isOnline
        lastSeen
      }
    }
  ''';
}
