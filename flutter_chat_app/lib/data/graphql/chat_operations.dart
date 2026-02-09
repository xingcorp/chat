/// **ENTERPRISE CHAT GRAPHQL OPERATIONS**
///
/// GraphQL operations matching backend API schema exactly.
/// Backend API: https://oxii-workoffice.smarthiz.com/graphql
///
/// **Architecture:** Clean Architecture + Backend API Integration
/// **Pattern:** Const string operations for type safety and performance
/// **Maintainability:** Grouped by operation type (Queries, Mutations)
///
/// **CRITICAL:** Field names must match backend API exactly:
/// - Use `fullname` not `fullName`
/// - Use `imgUrl` not `avatarUrl` for conversations
/// - Use `message` not `content` for message text
/// - Use `urls` array not single `url`
/// - Use `readerIds` not `readBy`

/// **CHAT QUERIES**
///
/// Read operations for conversations and messages
class ChatQueries {
  /// **Get Conversation List**
  ///
  /// Fetches paginated list of user's conversations with filters.
  ///
  /// **Variables:**
  /// - filters: ChatConversationListFilter
  ///   - size: Int (default: 25)
  ///   - page: Int (default: 0)
  ///   - keyword: String (optional, search term)
  ///   - type: String (optional, "Direct" | "Group")
  ///
  /// **Returns:** List of conversations with members and last message
  static const String getConversationList = r'''
    query GetConversationList($filters: ChatConversationListFilter!) {
      chatConversationList(filters: $filters) {
        total
        conversations {
          id
          name
          type
          description
          imgUrl
          groupType
          createdAt
          lastMessageAt
          lastMessageId
          creator {
            id
            fullname
          }
          members {
            id
            userId
            admin
            connected
            hide
            unreadCount
            lastMessageReadId
            user {
              id
              fullname
              email
            }
          }
        }
      }
    }
  ''';

  /// **Get Conversation Detail**
  ///
  /// Fetches detailed information about a specific conversation.
  /// Use either conversationId (for existing conversation) or receiverId (for direct chat).
  ///
  /// **Variables:**
  /// - conversationId: String (optional, for existing conversation)
  /// - receiverId: String (optional, for direct chat with user)
  ///
  /// **Returns:** Conversation details with full member list
  static const String getConversationDetail = r'''
    query GetConversationDetail(
      $conversationId: String
      $receiverId: String
    ) {
      chatConversationDetail(
        conversationId: $conversationId
        receiverId: $receiverId
      ) {
        id
        name
        type
        description
        imgUrl
        groupType
        createdAt
        lastMessageAt
        lastMessageId
        creator {
          id
          fullname
        }
        members {
          id
          userId
          admin
          connected
          hide
          unreadCount
          lastMessageReadId
          user {
            id
            fullname
            email
          }
        }
      }
    }
  ''';

  /// **Get Message List**
  ///
  /// Fetches paginated messages for a conversation with cursor-based pagination.
  ///
  /// **Variables:**
  /// - filters: ChatMessageGetListFilter
  ///   - conversationId: String (required)
  ///   - size: Int (default: 100)
  ///   - lastKey: LastKeyInput (optional, for pagination)
  ///     - conversationId: String
  ///     - createdAt: Float (timestamp)
  ///   - type: String (optional, filter by message type)
  ///   - order: String (optional, "DESC" | "ASC", default: "DESC")
  ///   - from: Float (optional, timestamp filter)
  ///
  /// **Returns:** Messages with pagination cursor
  static const String getMessageList = r'''
    query GetMessageList($filters: ChatMessageGetListFilter!) {
      chatMessageList(filters: $filters) {
        lastKey {
          conversationId
          createdAt
        }
        messages {
          id
          message
          urls
          type
          createdAt
          editAt
          deletedAt
          replyMessageId
          replyMessage {
            id
            message
            sender {
              id
              fullname
              avatar { location }
            }
          }
          forwardedFromMessageId
          fileName
          senderId
          sender {
            id
            fullname
            avatar { location }
          }
          conversationId
          readerIds
          reactions {
            code
            userId
            user {
              id
              fullname
            }
          }
          mentionTo {
            id
            fullname
          }
        }
      }
    }
  ''';

  /// **Search Messages**
  ///
  /// Searches messages across conversations with advanced filters.
  ///
  /// **Variables:**
  /// - filters: ChatSearchArgs
  ///   - keyword: String (required, search term)
  ///   - conversationIds: [String] (optional, filter by conversations)
  ///   - senderIds: [String] (optional, filter by senders)
  ///   - messageTypes: [String] (optional, filter by types)
  ///   - from: Float (optional, start timestamp)
  ///   - to: Float (optional, end timestamp)
  ///   - page: Int (default: 0)
  ///   - size: Int (default: 100)
  ///
  /// **Returns:** List of matching messages
  static const String searchMessages = r'''
    query SearchMessages($filters: ChatSearchArgs!) {
      chatSearch(filters: $filters) {
        id
        message
        fileName
        type
        createdAt
        senderId
        sender {
          id
          fullname
          avatar { location }
        }
        conversationId
      }
    }
  ''';
}

/// **CHAT MUTATIONS**
///
/// Write operations for conversations and messages
class ChatMutations {
  /// **Create Group**
  ///
  /// Creates a new group conversation.
  ///
  /// **Variables:**
  /// - arguments: ChatGroupAddInput
  ///   - name: String (required, group name)
  ///   - imgUrl: String (optional, group avatar)
  ///   - description: String (optional, group description)
  ///   - groupType: String (required, "Public" | "Private")
  ///   - memberIds: [String] (required, initial member IDs)
  ///
  /// **Returns:** Created group conversation
  static const String createGroup = r'''
    mutation CreateGroup($arguments: ChatGroupAddInput!) {
      chatGroupAdd(arguments: $arguments) {
        id
        name
        type
        description
        imgUrl
        groupType
        createdAt
        creator {
          id
          fullname
          avatar { location }
        }
        members {
          id
          userId
          admin
          user {
            id
            fullname
            avatar { location }
          }
        }
      }
    }
  ''';

  /// **Edit Group**
  ///
  /// Updates group information and members.
  ///
  /// **Variables:**
  /// - arguments: ChatGroupEditInput
  ///   - conversationId: String (required)
  ///   - name: String (optional, new group name)
  ///   - imgUrl: String (optional, new group avatar)
  ///   - description: String (optional, new description)
  ///   - groupType: String (optional, "Public" | "Private")
  ///   - memberIds: [String] (optional, updated member list)
  ///   - adminIds: [String] (optional, updated admin list)
  ///
  /// **Returns:** Updated group conversation
  static const String editGroup = r'''
    mutation EditGroup($arguments: ChatGroupEditInput!) {
      chatGroupEdit(arguments: $arguments) {
        id
        name
        type
        description
        imgUrl
        groupType
        createdAt
        members {
          id
          userId
          admin
          user {
            id
            fullname
            avatar { location }
          }
        }
      }
    }
  ''';

  /// **Leave Conversation**
  ///
  /// Removes current user from a conversation.
  ///
  /// **Variables:**
  /// - arguments: ChatGroupLeaveArgs
  ///   - conversationId: String (required)
  ///
  /// **Returns:** Conversation ID
  static const String leaveConversation = r'''
    mutation LeaveConversation($arguments: ChatGroupLeaveArgs!) {
      chatConversationLeave(arguments: $arguments) {
        id
      }
    }
  ''';

  /// **Delete Conversation**
  ///
  /// Deletes a conversation for current user (hides from list).
  ///
  /// **Variables:**
  /// - arguments: ChatGroupLeaveArgs
  ///   - conversationId: String (required)
  ///
  /// **Returns:** Deletion confirmation
  static const String deleteConversation = r'''
    mutation DeleteConversation($arguments: ChatGroupLeaveArgs!) {
      chatConversationDelete(arguments: $arguments) {
        id
        userId
        conversationId
      }
    }
  ''';

  /// **Send Message**
  ///
  /// Sends a new message to a conversation or creates direct chat.
  ///
  /// **Variables:**
  /// - arguments: ChatAddMessageInput
  ///   - conversationId: String (optional, for existing conversation)
  ///   - receiverId: String (optional, for new direct chat)
  ///   - type: String (required, "TEXT" | "IMAGE" | "VIDEO" | "AUDIO" | "FILE" | "LOCATION")
  ///   - message: String (required, message content)
  ///   - urls: [String] (optional, attachment URLs)
  ///   - fileName: String (optional, file name for attachments)
  ///   - replyMessageId: String (optional, ID of message being replied to)
  ///   - forwardedFromMessageId: String (optional, ID of forwarded message)
  ///   - createdAt: Float (required, timestamp in milliseconds)
  ///
  /// **Returns:** Sent message with server ID
  static const String sendMessage = r'''
    mutation SendMessage($arguments: ChatAddMessageInput!) {
      chatMessageAdd(arguments: $arguments) {
        id
        message
        urls
        type
        createdAt
        senderId
        sender {
          id
          fullname
          avatar { location }
        }
        conversationId
        replyMessageId
        forwardedFromMessageId
        fileName
      }
    }
  ''';

  /// **Edit Message**
  ///
  /// Edits or deletes an existing message.
  ///
  /// **Variables:**
  /// - arguments: ChatMessageUpdateArgs
  ///   - messageId: String (required)
  ///   - act: String (required, "EDIT" | "DELETE")
  ///   - message: String (optional, new message content for EDIT)
  ///
  /// **Returns:** Updated message
  static const String editMessage = r'''
    mutation EditMessage($arguments: ChatMessageUpdateArgs!) {
      chatMessageEdit(arguments: $arguments) {
        id
        message
        editAt
        deletedAt
      }
    }
  ''';

  /// **Mark Messages as Read**
  ///
  /// Marks messages in a conversation as read by current user.
  ///
  /// **Variables:**
  /// - arguments: ChatMessageUpdateReadArgs
  ///   - conversationId: String (required)
  ///   - readCount: Int (required, number of messages read)
  ///
  /// **Returns:** Conversation ID
  static const String markAsRead = r'''
    mutation MarkAsRead($arguments: ChatMessageUpdateReadArgs!) {
      chatMessageUpdateRead(arguments: $arguments) {
        conversationId
      }
    }
  ''';

  /// **Update Message Reaction**
  ///
  /// Adds or removes a reaction emoji to/from a message.
  ///
  /// **Variables:**
  /// - arguments: ChatMessageUpdateReactionArgs
  ///   - messageId: String (required)
  ///   - code: String (required, emoji code)
  ///   - act: String (required, "ADD" | "REMOVE")
  ///
  /// **Returns:** Updated message with reactions
  static const String updateReaction = r'''
    mutation UpdateReaction($arguments: ChatMessageUpdateReactionArgs!) {
      chatMessageUpdateReaction(arguments: $arguments) {
        id
        reactions {
          code
          userId
          user {
            id
            fullname
          }
        }
      }
    }
  ''';

  /// **Delete Message History**
  ///
  /// Deletes all message history in a conversation for current user.
  ///
  /// **Variables:**
  /// - arguments: DeleteHistoryArgs
  ///   - conversationId: String (required)
  ///
  /// **Returns:** Deletion confirmation
  static const String deleteHistory = r'''
    mutation DeleteHistory($arguments: DeleteHistoryArgs!) {
      chatMessageDeleteHistory(arguments: $arguments) {
        id
        conversationId
        viewMessagesFrom
      }
    }
  ''';
}

/// **CHAT SUBSCRIPTIONS**
///
/// Real-time subscriptions for chat events.
///
/// **NOTE:** Backend uses Socket.IO for real-time events, not GraphQL subscriptions.
/// These subscriptions are kept for potential future use or alternative implementations.
/// For real-time messaging, use Socket.IO events instead (see socket_manager.dart).
class ChatSubscriptions {
  /// **Subscribe to New Messages**
  ///
  /// Receives real-time updates when new messages are sent to a conversation.
  ///
  /// **Variables:**
  /// - chatId: ID (required, conversation ID)
  ///
  /// **Returns:** New message data
  ///
  /// **NOTE:** Use Socket.IO event 'message:sent' instead for production
  static const String newMessage = r'''
    subscription OnNewMessage($chatId: ID!) {
      newMessage(chatId: $chatId) {
        id
        message
        urls
        type
        createdAt
        senderId
        sender {
          id
          fullname
          avatar { location }
        }
        conversationId
      }
    }
  ''';

  /// **Subscribe to Typing Status**
  ///
  /// Receives real-time updates when users start/stop typing.
  ///
  /// **Variables:**
  /// - chatId: ID (required, conversation ID)
  ///
  /// **Returns:** Typing status data
  ///
  /// **NOTE:** Use Socket.IO event 'message:typing' instead for production
  static const String typingStatus = r'''
    subscription OnTypingStatus($chatId: ID!) {
      typingStatus(chatId: $chatId) {
        userId
        userName
        chatId
        isTyping
      }
    }
  ''';

  /// **Subscribe to User Presence**
  ///
  /// Receives real-time updates when users go online/offline.
  ///
  /// **Returns:** User presence data
  ///
  /// **NOTE:** Use Socket.IO for real-time presence tracking
  static const String userPresence = r'''
    subscription OnUserPresence {
      userPresence {
        userId
        isOnline
        lastSeen
      }
    }
  ''';
}
