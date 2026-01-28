import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/error/exceptions.dart' as app_exceptions;
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';

/// Abstract interface for GraphQL client operations
abstract class GraphQLClientWrapper {
  /// Get the underlying GraphQLClient instance
  GraphQLClient get client;

  /// Execute a GraphQL query operation
  Future<Map<String, dynamic>> query(
    String queryString, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    String? operationName,
  });

  /// Execute a GraphQL mutation operation
  Future<Map<String, dynamic>> mutate(
    String mutationString, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    String? operationName,
  });

  /// Subscribe to a GraphQL subscription
  Stream<Map<String, dynamic>> subscribe(
    String subscriptionString, {
    Map<String, dynamic>? variables,
    String? operationName,
  });
}

/// Implementation of GraphQL client
@lazySingleton
class GraphQLClientWrapperImpl implements GraphQLClientWrapper {
  final GraphQLClient _client;
  final NetworkInfo _networkInfo;

  /// Constructor
  GraphQLClientWrapperImpl(this._client, this._networkInfo);

  /// Get the underlying GraphQLClient instance
  @override
  GraphQLClient get client => _client;

  /// Factory method to create a GraphQL client
  static Future<GraphQLClient> createClient({
    String? token,
    ValueNotifier<GraphQLClient>? clientNotifier,
  }) async {
    final httpLink = HttpLink(
      dotenv.env['GRAPHQL_API_URL'] ?? '${AppConstants.apiBaseUrl}/graphql',
    );

    final authLink = AuthLink(
      getToken: () => token != null ? 'Bearer $token' : null,
    );

    // Create a WebSocket link for subscriptions
    final websocketLink = WebSocketLink(
      dotenv.env['GRAPHQL_WS_URL'] ?? 'ws://localhost:3000/graphql',
      config: SocketClientConfig(
        initialPayload: token != null
            ? <String, dynamic>{
                'Authorization': 'Bearer $token',
              }
            : null,
        autoReconnect: true,
        inactivityTimeout: const Duration(seconds: 30),
      ),
    );

    // Split links based on operation type (query/mutation vs subscription)
    final link = Link.split(
      (request) => request.isSubscription,
      websocketLink,
      authLink.concat(httpLink),
    );

    // Initialize Hive for caching
    await initHiveForFlutter();

    // Create GraphQL client
    final client = GraphQLClient(
      link: link,
      cache: GraphQLCache(
        store: HiveStore(),
      ),
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.cacheAndNetwork,
          error: ErrorPolicy.all,
        ),
        mutate: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
        ),
        subscribe: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
        ),
      ),
    );

    if (clientNotifier != null) {
      clientNotifier.value = client;
    }

    return client;
  }

  @override
  Future<Map<String, dynamic>> query(
    String queryString, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    String? operationName,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw app_exceptions.NoInternetException();
    }

    try {
      final options = QueryOptions(
        document: gql(queryString),
        variables: variables ?? {},
        fetchPolicy: fetchPolicy,
        operationName: operationName,
      );

      final result = await _client.query(options);

      if (result.hasException) {
        _handleGraphQLException(result.exception!);
      }

      return result.data ?? {};
    } catch (e) {
      if (e is app_exceptions.NoInternetException) rethrow;
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> mutate(
    String mutationString, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    String? operationName,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw app_exceptions.NoInternetException();
    }

    try {
      final options = MutationOptions(
        document: gql(mutationString),
        variables: variables ?? {},
        fetchPolicy: fetchPolicy,
        operationName: operationName,
      );

      final result = await _client.mutate(options);

      if (result.hasException) {
        _handleGraphQLException(result.exception!);
      }

      return result.data ?? {};
    } catch (e) {
      if (e is app_exceptions.NoInternetException) rethrow;
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Stream<Map<String, dynamic>> subscribe(
    String subscriptionString, {
    Map<String, dynamic>? variables,
    String? operationName,
  }) {
    final options = SubscriptionOptions(
      document: gql(subscriptionString),
      variables: variables ?? {},
      operationName: operationName,
    );

    return _client.subscribe(options).map((result) {
      if (result.hasException) {
        _handleGraphQLException(result.exception!);
      }
      return result.data ?? {};
    });
  }

  void _handleGraphQLException(OperationException exception) {
    if (exception.linkException != null) {
      throw app_exceptions.ServerException(
        message: 'Network error: ${exception.linkException.toString()}',
      );
    }

    if (exception.graphqlErrors.isNotEmpty) {
      final messages = exception.graphqlErrors
          .map((error) => error.message)
          .join(', ');
          
      // Check for authentication errors
      final authErrors = exception.graphqlErrors
          .where((error) => error.extensions?['code'] == 'UNAUTHENTICATED' ||
                           error.extensions?['code'] == 'FORBIDDEN')
          .toList();
                           
      if (authErrors.isNotEmpty) {
        throw app_exceptions.AuthException(
          message: 'Authentication error: $messages',
          code: authErrors.first.extensions?['code'],
          details: exception.graphqlErrors,
        );
      }

      // Check for validation errors
      final validationErrors = exception.graphqlErrors
          .where((error) => error.extensions?['code'] == 'BAD_USER_INPUT')
          .toList();
                           
      if (validationErrors.isNotEmpty) {
        throw app_exceptions.ValidationException(
          message: 'Validation error: $messages',
          code: validationErrors.first.extensions?['code'],
          details: exception.graphqlErrors,
        );
      }

      // Generic GraphQL error
      throw app_exceptions.ServerException(
        message: 'GraphQL error: $messages',
        details: exception.graphqlErrors,
      );
    }

    throw app_exceptions.UnknownException(
      message: 'Unknown GraphQL error',
      details: exception,
    );
  }
} 