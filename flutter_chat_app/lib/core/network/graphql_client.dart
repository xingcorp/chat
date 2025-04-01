import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/error/exceptions.dart' as app_exceptions;
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart' show ClientException;

/// Giao diện cho GraphQL client wrapper
abstract class GraphQLClientWrapper {
  /// GraphQL client instance
  GraphQLClient get client;

  /// Thực hiện truy vấn GraphQL
  Future<QueryResult> query(QueryOptions options);

  /// Thực hiện mutation GraphQL
  Future<QueryResult> mutate(MutationOptions options);

  /// Đăng ký subscription GraphQL
  Stream<QueryResult> subscribe(SubscriptionOptions options);

  /// Cập nhật token xác thực
  Future<void> updateAuthToken(String token);
}

/// Implementation của GraphQLClientWrapper
class GraphQLClientWrapperImpl implements GraphQLClientWrapper {
  GraphQLClient _client;
  final NetworkInfo _networkInfo;

  /// Constructor
  GraphQLClientWrapperImpl(this._client, this._networkInfo);

  /// Tạo GraphQL client với token
  static Future<GraphQLClient> createClient({
    required String? token,
    required ValueNotifier<GraphQLClient> clientNotifier,
  }) async {
    // HTTP link với token
    final httpLink = HttpLink(
      dotenv.env['GRAPHQL_API_URL'] ?? 'https://example.com/graphql',
      defaultHeaders: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // WebSocket link với token
    final wsLink = WebSocketLink(
      dotenv.env['GRAPHQL_WS_URL'] ?? 'wss://example.com/graphql',
      config: SocketClientConfig(
        initialPayload: {
          if (token != null && token.isNotEmpty) 'token': token,
        },
        autoReconnect: true,
        inactivityTimeout: const Duration(seconds: 30),
      ),
    );

    // Link theo loại operation
    final link = Link.split(
      (request) => request.isSubscription,
      wsLink,
      httpLink,
    );

    // Khởi tạo cache
    final cache = GraphQLCache(store: HiveStore());

    // Tạo client
    final client = GraphQLClient(
      link: link,
      cache: cache,
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
          cacheReread: CacheRereadPolicy.ignoreAll,
        ),
        mutate: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
          cacheReread: CacheRereadPolicy.ignoreAll,
        ),
        subscribe: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
          cacheReread: CacheRereadPolicy.ignoreAll,
        ),
      ),
    );

    // Cập nhật notifier
    clientNotifier.value = client;

    return client;
  }

  @override
  GraphQLClient get client => _client;

  @override
  Future<QueryResult> query(QueryOptions options) async {
    try {
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        throw app_exceptions.NoInternetException();
      }

      return await _client.query(options);
    } catch (e) {
      debugPrint('GraphQL query error: $e');
      rethrow;
    }
  }

  @override
  Future<QueryResult> mutate(MutationOptions options) async {
    try {
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        throw app_exceptions.NoInternetException();
      }

      return await _client.mutate(options);
    } catch (e) {
      debugPrint('GraphQL mutation error: $e');
      rethrow;
    }
  }

  @override
  Stream<QueryResult> subscribe(SubscriptionOptions options) {
    try {
      return _client.subscribe(options).handleError((error) {
        debugPrint('GraphQL subscription error: $error');
        return error;
      });
    } catch (e) {
      debugPrint('GraphQL subscribe error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateAuthToken(String token) async {
    // Tạo client mới với token mới
    final httpLink = HttpLink(
      dotenv.env['GRAPHQL_API_URL'] ?? 'https://example.com/graphql',
      defaultHeaders: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final wsLink = WebSocketLink(
      dotenv.env['GRAPHQL_WS_URL'] ?? 'wss://example.com/graphql',
      config: SocketClientConfig(
        initialPayload: {
          'token': token,
        },
        autoReconnect: true,
        inactivityTimeout: const Duration(seconds: 30),
      ),
    );

    final link = Link.split(
      (request) => request.isSubscription,
      wsLink,
      httpLink,
    );

    // Sử dụng lại cache hiện tại
    final cache = _client.cache;

    // Tạo client mới
    _client = GraphQLClient(
      link: link,
      cache: cache,
      defaultPolicies: _client.defaultPolicies,
    );
  }
} 