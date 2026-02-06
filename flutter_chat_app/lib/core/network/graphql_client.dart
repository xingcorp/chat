import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/error/exceptions.dart' as app_exceptions;
import 'package:flutter_chat_app/core/network/auth/token_repository.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
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
  final TokenRepository? _tokenRepository;
  final AppLogger _logger;

  /// Constructor
  GraphQLClientWrapperImpl(
    this._client,
    this._networkInfo, [
    this._tokenRepository,
    AppLogger? logger,
  ]) : _logger = logger ?? AppLogger();

  /// Get the underlying GraphQLClient instance
  @override
  GraphQLClient get client => _client;

  /// Factory method to create a GraphQL client
  static Future<GraphQLClient> createClient({
    String? token,
    Future<String?> Function()? accessTokenProvider,
    ValueNotifier<GraphQLClient>? clientNotifier,
  }) async {
    final resolvedToken = accessTokenProvider != null
        ? await accessTokenProvider()
        : token;

    final httpLink = HttpLink(
      dotenv.env['GRAPHQL_API_URL'] ?? '${AppConstants.apiBaseUrl}/graphql',
    );

    final authLink = AuthLink(
      getToken: () async {
        final currentToken = accessTokenProvider != null
            ? await accessTokenProvider()
            : resolvedToken;
        if (currentToken == null || currentToken.isEmpty) {
          return null;
        }
        return 'Bearer $currentToken';
      },
    );

    // Create a WebSocket link for subscriptions
    final websocketLink = WebSocketLink(
      dotenv.env['GRAPHQL_WS_URL'] ?? 'ws://localhost:3000/graphql',
      config: SocketClientConfig(
        initialPayload: () async {
          final currentToken = accessTokenProvider != null
              ? await accessTokenProvider()
              : resolvedToken;
          if (currentToken == null || currentToken.isEmpty) {
            return null;
          }
          return <String, dynamic>{
            'Authorization': 'Bearer $currentToken',
          };
        },
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
    final op = operationName ?? 'UnnamedQuery';
    final endpoint = dotenv.env['GRAPHQL_API_URL'] ?? '${AppConstants.apiBaseUrl}/graphql';
    final stopwatch = Stopwatch()..start();

    if (!await _networkInfo.isConnected) {
      _logger.warning(
        'GraphQL query blocked: no internet',
        {
          'operation': op,
          'endpoint': endpoint,
        },
      );
      throw app_exceptions.NoInternetException();
    }

    final options = QueryOptions(
      document: gql(queryString),
      variables: variables ?? {},
      fetchPolicy: fetchPolicy,
      operationName: operationName,
    );

    try {
      _logger.debug(
        'GraphQL query start',
        {
          'operation': op,
          'endpoint': endpoint,
          'hasVariables': (variables ?? {}).isNotEmpty,
        },
      );

      final data = await _queryWithRetry(options);
      stopwatch.stop();
      _logger.debug(
        'GraphQL query success',
        {
          'operation': op,
          'endpoint': endpoint,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      );
      return data;
    } on app_exceptions.NoInternetException {
      stopwatch.stop();
      rethrow;
    } on app_exceptions.AuthException {
      stopwatch.stop();
      rethrow;
    } catch (e) {
      stopwatch.stop();
      _logger.error(
        'GraphQL query failed',
        {
          'operation': op,
          'endpoint': endpoint,
          'durationMs': stopwatch.elapsedMilliseconds,
          'error': e.toString(),
        },
      );
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> _queryWithRetry(
    QueryOptions options, {
    bool didRetry = false,
  }) async {
    final result = await _client.query(options);

    if (result.hasException) {
      try {
        _handleGraphQLException(result.exception!);
      } on app_exceptions.AuthException {
        if (didRetry) {
          rethrow;
        }

        final refreshedToken = await _tokenRepository?.refreshAccessToken();
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          return _queryWithRetry(options, didRetry: true);
        }

        rethrow;
      }
    }

    return result.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> mutate(
    String mutationString, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    String? operationName,
  }) async {
    final op = operationName ?? 'UnnamedMutation';
    final endpoint = dotenv.env['GRAPHQL_API_URL'] ?? '${AppConstants.apiBaseUrl}/graphql';
    final stopwatch = Stopwatch()..start();

    if (!await _networkInfo.isConnected) {
      _logger.warning(
        'GraphQL mutation blocked: no internet',
        {
          'operation': op,
          'endpoint': endpoint,
        },
      );
      throw app_exceptions.NoInternetException();
    }

    final options = MutationOptions(
      document: gql(mutationString),
      variables: variables ?? {},
      fetchPolicy: fetchPolicy,
      operationName: operationName,
    );

    try {
      _logger.debug(
        'GraphQL mutation start',
        {
          'operation': op,
          'endpoint': endpoint,
          'hasVariables': (variables ?? {}).isNotEmpty,
        },
      );

      final data = await _mutateWithRetry(options);
      stopwatch.stop();
      _logger.debug(
        'GraphQL mutation success',
        {
          'operation': op,
          'endpoint': endpoint,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      );
      return data;
    } on app_exceptions.NoInternetException {
      stopwatch.stop();
      rethrow;
    } on app_exceptions.AuthException {
      stopwatch.stop();
      rethrow;
    } catch (e) {
      stopwatch.stop();
      _logger.error(
        'GraphQL mutation failed',
        {
          'operation': op,
          'endpoint': endpoint,
          'durationMs': stopwatch.elapsedMilliseconds,
          'error': e.toString(),
        },
      );
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> _mutateWithRetry(
    MutationOptions options, {
    bool didRetry = false,
  }) async {
    final result = await _client.mutate(options);

    if (result.hasException) {
      try {
        _handleGraphQLException(result.exception!);
      } on app_exceptions.AuthException {
        if (didRetry) {
          rethrow;
        }

        final refreshedToken = await _tokenRepository?.refreshAccessToken();
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          return _mutateWithRetry(options, didRetry: true);
        }

        rethrow;
      }
    }

    return result.data ?? {};
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
        message: 'Network error: ${exception.linkException}',
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