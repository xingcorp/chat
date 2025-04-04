/// GraphQL operations for chat functionality

/// Query to fetch chat list for a user
class ChatQueries {
  /// Get a list of chats for the current user
  static const String getUserChats = '''
    query GetUserChats(\$limit: Int, \$offset: Int) {
      getUserChats(limit: \$limit, offset: \$offset) {
        id
        name
        type
        avatarUrl
        createdAt
        updatedAt
        lastMessage {
          id
          text
          sender {
            id
            fullName
            avatarUrl
          }
          createdAt
          readBy {
            id
          }
        }
        participants {
          id
          fullName
          avatarUrl
          isOnline
          lastSeen
        }
        unreadCount
      }
    }
  ''';

  /// Get details of a specific chat by ID
  static const String getChatDetails = '''
    query GetChatDetails(\$chatId: ID!) {
      getChatById(id: \$chatId) {
        id
        name
        type
        avatarUrl
        createdAt
        updatedAt
        participants {
          id
          fullName
          avatarUrl
          isOnline
          lastSeen
        }
        lastMessage {
          id
          text
          sender {
            id
            fullName
          }
          createdAt
          readBy {
            id
          }
        }
        unreadCount
      }
    }
  ''';

  /// Get messages for a specific chat
  static const String getChatMessages = '''
    query GetChatMessages(\$chatId: ID!, \$limit: Int, \$before: DateTime) {
      getChatMessages(chatId: \$chatId, limit: \$limit, before: \$before) {
        id
        text
        chatId
        attachments {
          id
          url
          type
          name
          size
        }
        sender {
          id
          fullName
          avatarUrl
        }
        createdAt
        updatedAt
        readBy {
          id
          fullName
        }
      }
    }
  ''';
}

/// Mutations for chat operations
class ChatMutations {
  /// Create a direct chat with a user
  static const String createDirectChat = '''
    mutation CreateDirectChat(\$participantId: ID!) {
      createDirectChat(participantId: \$participantId) {
        id
        name
        type
        avatarUrl
        createdAt
        participants {
          id
          fullName
          avatarUrl
          isOnline
        }
      }
    }
  ''';

  /// Create a group chat
  static const String createGroupChat = '''
    mutation CreateGroupChat(\$name: String!, \$participantIds: [ID!]!) {
      createGroupChat(name: \$name, participantIds: \$participantIds) {
        id
        name
        type
        avatarUrl
        createdAt
        participants {
          id
          fullName
          avatarUrl
          isOnline
        }
      }
    }
  ''';

  /// Update chat details
  static const String updateChat = '''
    mutation UpdateChat(\$chatId: ID!, \$name: String, \$avatarUrl: String) {
      updateChat(id: \$chatId, name: \$name, avatarUrl: \$avatarUrl) {
        id
        name
        type
        avatarUrl
        updatedAt
      }
    }
  ''';

  /// Add users to a chat
  static const String addUserToChat = '''
    mutation AddUserToChat(\$chatId: ID!, \$userIds: [ID!]!) {
      addUsersToChat(chatId: \$chatId, userIds: \$userIds) {
        success
        message
      }
    }
  ''';

  /// Remove users from a chat
  static const String removeUserFromChat = '''
    mutation RemoveUserFromChat(\$chatId: ID!, \$userIds: [ID!]!) {
      removeUsersFromChat(chatId: \$chatId, userIds: \$userIds) {
        success
        message
      }
    }
  ''';

  /// Delete a chat
  static const String deleteChat = '''
    mutation DeleteChat(\$chatId: ID!) {
      deleteChat(id: \$chatId) {
        success
        message
      }
    }
  ''';

  /// Send a message in a chat
  static const String sendMessage = '''
    mutation SendMessage(
      \$chatId: ID!, 
      \$text: String!, 
      \$attachments: [AttachmentInput]
    ) {
      sendMessage(
        chatId: \$chatId, 
        text: \$text, 
        attachments: \$attachments
      ) {
        id
        text
        chatId
        attachments {
          id
          url
          type
          name
          size
        }
        sender {
          id
          fullName
          avatarUrl
        }
        createdAt
        readBy {
          id
        }
      }
    }
  ''';

  /// Mark messages as read in a chat
  static const String markMessagesAsRead = '''
    mutation MarkMessagesAsRead(\$chatId: ID!) {
      markMessagesAsRead(chatId: \$chatId) {
        success
        message
      }
    }
  ''';

  /// Delete a message
  static const String deleteMessage = '''
    mutation DeleteMessage(\$messageId: ID!) {
      deleteMessage(id: \$messageId) {
        success
        message
      }
    }
  ''';

  /// Leave a chat
  static const String leaveChat = '''
    mutation LeaveChat(\$chatId: ID!) {
      leaveChat(chatId: \$chatId) {
        success
        message
      }
    }
  ''';
}

/// Subscriptions for real-time chat updates
class ChatSubscriptions {
  /// Subscribe to new messages in a chat
  static const String newMessage = '''
    subscription OnNewMessage(\$chatId: ID!) {
      newMessage(chatId: \$chatId) {
        id
        text
        chatId
        attachments {
          id
          url
          type
          name
          size
        }
        sender {
          id
          fullName
          avatarUrl
        }
        createdAt
        readBy {
          id
        }
      }
    }
  ''';

  /// Subscribe to typing status in a chat
  static const String typingStatus = '''
    subscription OnTypingStatus(\$chatId: ID!) {
      typingStatus(chatId: \$chatId) {
        userId
        userName
        chatId
        isTyping
      }
    }
  ''';

  /// Subscribe to user presence status changes
  static const String userPresence = '''
    subscription OnUserPresence {
      userPresence {
        userId
        isOnline
        lastSeen
      }
    }
  ''';
} 