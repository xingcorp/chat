import 'package:flutter/foundation.dart';
import 'package:graphql/client.dart';
import 'package:isar/isar.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_chat_app/data/graphql/chat_operations.dart'
    show ChatQueries;
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/chat_draft_model.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:flutter_chat_app/data/models/offline_operation_model.dart';
import 'package:flutter_chat_app/data/models/sync_metadata_model.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart'
    show ChatType;

/// Lightweight helper for background sync operations.
///
/// Designed to be initialized in a background isolate where GetIt
/// and the main app's DI graph are NOT available. Opens its own Isar
/// instance and GraphQL client, reading config from SharedPreferences
/// (saved there during foreground initialization).
///
/// ## Usage
/// ```dart
/// final helper = await BackgroundSyncHelper.initialize();
/// await helper.syncChatList();
/// await helper.dispose();
/// ```
class BackgroundSyncHelper {
  final Isar _isar;
  final GraphQLClient _graphqlClient;
  final SharedPreferences _prefs;
  final Logger _logger;

  /// SharedPreferences keys used by foreground to persist config
  static const String keyBaseUrl = 'chat_module_base_url';
  static const String keyGraphqlUrl = 'chat_module_graphql_url';
  static const String keyAccessToken = 'chat_module_access_token';
  static const String keyLastBgSyncTime = 'last_bg_sync_time';

  BackgroundSyncHelper._({
    required Isar isar,
    required GraphQLClient graphqlClient,
    required SharedPreferences prefs,
    required Logger logger,
  })  : _isar = isar,
        _graphqlClient = graphqlClient,
        _prefs = prefs,
        _logger = logger;

  /// Initialize minimal dependencies for background isolate.
  ///
  /// Reads API URLs and auth token from SharedPreferences
  /// (saved by [ChatModuleInjection] during foreground initialization).
  /// Opens Isar with the same DB name & directory as the foreground.
  static Future<BackgroundSyncHelper> initialize() async {
    final logger = Logger();
    final prefs = await SharedPreferences.getInstance();

    final graphqlUrl = prefs.getString(keyGraphqlUrl) ?? '';
    final accessToken = prefs.getString(keyAccessToken) ?? '';

    if (graphqlUrl.isEmpty) {
      throw StateError(
          'BackgroundSyncHelper: No graphqlUrl in SharedPreferences. '
          'Ensure ChatModule was initialized at least once in the foreground.');
    }

    // Open Isar — same schemas, same name, same directory as foreground.
    // Isar v4 supports multi-isolate access to the same DB file.
    Isar isar;
    if (kIsWeb) {
      await Isar.initialize();
      isar = Isar.open(
        schemas: _schemas,
        directory: Isar.sqliteInMemory,
        engine: IsarEngine.sqlite,
        name: 'chat_app_db',
      );
    } else {
      final dir = await getApplicationDocumentsDirectory();
      isar = Isar.open(
        schemas: _schemas,
        directory: dir.path,
        name: 'chat_app_db',
      );
    }

    // Create lightweight GraphQL client
    final httpLink = HttpLink(
      graphqlUrl,
      defaultHeaders: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    final graphqlClient = GraphQLClient(link: httpLink, cache: GraphQLCache());

    return BackgroundSyncHelper._(
      isar: isar,
      graphqlClient: graphqlClient,
      prefs: prefs,
      logger: logger,
    );
  }

  static final List<IsarGeneratedSchema> _schemas = [
    ChatModelSchema,
    ChatDraftModelSchema,
    MessageModelSchema,
    UserModelSchema,
    OfflineOperationModelSchema,
    SyncMetadataModelSchema,
  ];

  /// Fetch latest chat list from server and save to Isar.
  ///
  /// Uses server-wins strategy: remote data overwrites local.
  Future<void> syncChatList() async {
    _logger.i('BackgroundSyncHelper: Syncing chat list');

    try {
      final result = await _graphqlClient.query(
        QueryOptions(
          document: gql(ChatQueries.getConversationList),
          variables: const {
            'filters': {
              'page': 0,
              'size': 50,
            },
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw result.exception!;
      }

      final data = result.data?['chatConversationList'];
      if (data == null) {
        _logger.w('BackgroundSyncHelper: No data in response');
        return;
      }

      final conversations = data['conversations'] as List?;
      if (conversations == null || conversations.isEmpty) {
        _logger.i('BackgroundSyncHelper: No conversations to sync');
        return;
      }

      // Parse and save to Isar
      _isar.write((isar) {
        for (final conv in conversations) {
          final map = conv as Map<String, dynamic>;
          final chatModel = _parseConversationToModel(map);
          if (chatModel != null) {
            isar.chatModels.put(chatModel);
          }
        }
      });

      await _prefs.setString(
          keyLastBgSyncTime, DateTime.now().toIso8601String());
      _logger.i(
          'BackgroundSyncHelper: Synced ${conversations.length} conversations');
    } catch (e) {
      _logger.e('BackgroundSyncHelper: Sync failed: $e');
      rethrow;
    }
  }

  /// Parse a conversation JSON map to a [ChatModel].
  ///
  /// Extracts relevant fields using the same shape as
  /// [ChatRemoteDataSourceImpl.getConversationList].
  ChatModel? _parseConversationToModel(Map<String, dynamic> map) {
    try {
      final id = map['id'] as String?;
      if (id == null) return null;

      final personalConv = map['personalConversation'] as Map<String, dynamic>?;
      final lastMessage = map['lastMessage'] as Map<String, dynamic>?;
      final members = map['members'] as List? ?? [];

      // Build last message preview
      String? lastMessagePreview;
      if (lastMessage != null) {
        final sender = lastMessage['sender'] as Map<String, dynamic>?;
        final senderName = sender?['fullname'] as String? ?? '';
        final messageText = lastMessage['message'] as String? ?? '';
        lastMessagePreview =
            senderName.isNotEmpty ? '$senderName: $messageText' : messageText;
      }

      // Build member IDs list
      final participantIds = <String>[];
      String? membersJsonStr;
      if (members.isNotEmpty) {
        for (final member in members) {
          final m = member as Map<String, dynamic>;
          final userId =
              m['userId'] as String? ?? m['user']?['id'] as String? ?? '';
          if (userId.isNotEmpty) participantIds.add(userId);
        }
        membersJsonStr = members
            .map((m) {
              final mm = m as Map<String, dynamic>;
              final user = mm['user'] as Map<String, dynamic>?;
              return {
                'id': mm['id'],
                'userId': mm['userId'] ?? user?['id'],
                'fullName': user?['fullname'],
                'avatarUrl': (user?['imageUrls'] as List?)?.firstOrNull,
                'admin': mm['admin'] ?? false,
                'connected': mm['connected'] ?? false,
                'hide': mm['hide'] ?? false,
                'unreadCount': mm['unreadCount'] ?? 0,
                'lastMessageReadId': mm['lastMessageReadId'],
              };
            })
            .toList()
            .toString();
      }

      // Parse ChatType enum
      final typeStr = (map['type'] as String? ?? 'Direct').toLowerCase();
      final chatType = typeStr == 'group'
          ? ChatType.group
          : typeStr == 'channel'
              ? ChatType.channel
              : ChatType.direct;

      final creator = map['creator'] as Map<String, dynamic>?;

      return ChatModel(
        serverId: id,
        name: map['name'] as String?,
        type: chatType,
        groupType: map['groupType'] as String?,
        description: map['description'] as String?,
        creatorId: creator?['id'] as String?,
        membersJson: membersJsonStr,
        lastMessagePreview: lastMessagePreview,
        lastMessageTime:
            DateTime.tryParse(map['lastMessageAt'] as String? ?? ''),
        unreadCount: personalConv?['unreadCount'] as int? ?? 0,
        participantIds: participantIds,
        avatarUrl: map['imgUrl'] as String?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (e) {
      _logger.w('BackgroundSyncHelper: Failed to parse conversation: $e');
      return null;
    }
  }

  /// Dispose resources. Does NOT close Isar (may be shared with foreground).
  Future<void> dispose() async {
    // GraphQLClient has no explicit close method — link resources are GC'd.
    // Do NOT close Isar — foreground may still be using it.
  }
}
