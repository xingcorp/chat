/// GraphQL operations for chat functionality

/// Query to fetch chat list for a user
class ChatQueries {
  /// Get all chats for the current user
  static const String getUserChats = r'''
    query GetUserChats($limit: Int, $offset: Int) {
      getUserChats(limit: $limit, offset: $offset) {
        id
        type
        name
        lastMessage {
          id
          content
          createdAt
          sender {
            id
            username
            avatar
          }
        }
        participants {
          id
          username
          avatar
          isOnline
          lastSeen
        }
        unreadCount
        createdAt
        updatedAt
      }
    }
  ''';

  /// Get chat details by ID
  static const String getChatDetails = r'''
    query GetChatDetails($chatId: ID!) {
      getChatById(id: $chatId) {
        id
        type
        name
        participants {
          id
          username
          avatar
          isOnline
          lastSeen
        }
        createdAt
        updatedAt
      }
    }
  ''';

  /// Get messages for a chat
  static const String getChatMessages = r'''
    query GetChatMessages($chatId: ID!, $limit: Int, $before: String) {
      getChatMessages(chatId: $chatId, limit: $limit, before: $before) {
        id
        content
        contentType
        attachments {
          id
          url
          type
          name
          size
        }
        sender {
          id
          username
          avatar
        }
        readBy {
          id
          username
          readAt
        }
        createdAt
        updatedAt
      }
    }
  ''';
}

/// Mutations for chat operations
class ChatMutations {
  /// Create a new direct chat
  static const String createDirectChat = r'''
    mutation CreateDirectChat($participantId: ID!) {
      createDirectChat(participantId: $participantId) {
        id
        type
        participants {
          id
          username
          avatar
        }
        createdAt
      }
    }
  ''';

  /// Create a new group chat
  static const String createGroupChat = r'''
    mutation CreateGroupChat($name: String!, $participantIds: [ID!]!) {
      createGroupChat(name: $name, participantIds: $participantIds) {
        id
        type
        name
        participants {
          id
          username
          avatar
        }
        createdAt
      }
    }
  ''';

  /// Send a message
  static const String sendMessage = r'''
    mutation SendMessage($chatId: ID!, $content: String!, $contentType: MessageContentType = TEXT, $attachments: [AttachmentInput]) {
      sendMessage(chatId: $chatId, content: $content, contentType: $contentType, attachments: $attachments) {
        id
        content
        contentType
        attachments {
          id
          url
          type
          name
          size
        }
        sender {
          id
          username
          avatar
        }
        createdAt
      }
    }
  ''';

  /// Mark messages as read
  static const String markMessagesAsRead = r'''
    mutation MarkMessagesAsRead($chatId: ID!) {
      markMessagesAsRead(chatId: $chatId) {
        success
        unreadCount
      }
    }
  ''';

  /// Delete a message
  static const String deleteMessage = r'''
    mutation DeleteMessage($messageId: ID!) {
      deleteMessage(id: $messageId) {
        success
        message
      }
    }
  ''';

  /// Add participants to a group chat
  static const String addParticipantsToChat = r'''
    mutation AddParticipantsToChat($chatId: ID!, $participantIds: [ID!]!) {
      addParticipantsToChat(chatId: $chatId, participantIds: $participantIds) {
        id
        participants {
          id
          username
          avatar
        }
      }
    }
  ''';

  /// Remove participant from a group chat
  static const String removeParticipantFromChat = r'''
    mutation RemoveParticipantFromChat($chatId: ID!, $participantId: ID!) {
      removeParticipantFromChat(chatId: $chatId, participantId: $participantId) {
        id
        participants {
          id
          username
          avatar
        }
      }
    }
  ''';

  /// Leave a group chat
  static const String leaveChat = r'''
    mutation LeaveChat($chatId: ID!) {
      leaveChat(chatId: $chatId) {
        success
        message
      }
    }
  ''';
}

/// Subscriptions for real-time chat updates
class ChatSubscriptions {
  /// Subscribe to new messages in a chat
  static const String newMessage = r'''
    subscription OnNewMessage($chatId: ID) {
      newMessage(chatId: $chatId) {
        id
        content
        contentType
        attachments {
          id
          url
          type
          name
          size
        }
        chat {
          id
          name
          type
        }
        sender {
          id
          username
          avatar
        }
        createdAt
      }
    }
  ''';

  /// Subscribe to typing status events
  static const String typingStatus = r'''
    subscription OnTypingStatus($chatId: ID!) {
      typingStatus(chatId: $chatId) {
        chatId
        userId
        username
        isTyping
      }
    }
  ''';

  /// Subscribe to user presence status changes
  static const String userPresence = r'''
    subscription OnUserPresence {
      userPresence {
        userId
        isOnline
        lastSeen
      }
    }
  ''';

  /// Subscribe to message read status updates
  static const String messageReadStatus = r'''
    subscription OnMessageReadStatus($chatId: ID!) {
      messageReadStatus(chatId: $chatId) {
        chatId
        messageId
        userId
        username
        readAt
      }
    }
  ''';
}

/// Input types for GraphQL mutations
class ChatInputTypes {
  /// Input for attachment
  static const String attachmentInput = r'''
    input AttachmentInput {
      url: String!
      type: String!
      name: String!
      size: Int!
    }
  ''';
} 