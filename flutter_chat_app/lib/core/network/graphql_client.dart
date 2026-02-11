import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/error/exceptions.dart' as app_exceptions;
import 'package:flutter_chat_app/core/network/auth/auth_delegate.dart';
import 'package:flutter_chat_app/core/network/auth/token_provider.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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
class GraphQLClientWrapperImpl implements GraphQLClientWrapper {
  final GraphQLClient _client;
  final NetworkInfo _networkInfo;
  final TokenProvider? _tokenProvider;
  final AuthDelegate? _authDelegate;
  final String _endpointUrl;
  final AppLogger _logger;

  /// Constructor
  GraphQLClientWrapperImpl(
    this._client,
    this._networkInfo, [
    this._tokenProvider,
    this._authDelegate,
    String? endpointUrl,
    AppLogger? logger,
  ])  : _endpointUrl = endpointUrl ?? 'graphql',
        _logger = logger ?? AppLogger();

  /// Get the underlying GraphQLClient instance
  @override
  GraphQLClient get client => _client;

  /// Factory method to create a GraphQL client
  static Future<GraphQLClient> createClient({
    String? token,
    Future<String?> Function()? accessTokenProvider,
    String? graphqlUrl,
    String? graphqlWsUrl,
    ValueNotifier<GraphQLClient>? clientNotifier,
  }) async {
    final resolvedToken = accessTokenProvider != null
        ? await accessTokenProvider()
        : token;

    final graphQlApiUrl = graphqlUrl ?? _tryGetEnv('GRAPHQL_API_URL');
    if (graphQlApiUrl.isEmpty) {
      throw StateError('Missing required: graphqlUrl parameter or GRAPHQL_API_URL env key');
    }

    final httpLink = HttpLink(graphQlApiUrl);

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
    final graphQlWsUrlResolved = graphqlWsUrl ?? _tryGetEnv('GRAPHQL_WS_URL');
    if (graphQlWsUrlResolved.isEmpty) {
      throw StateError('Missing required: graphqlWsUrl parameter or GRAPHQL_WS_URL env key');
    }

    final websocketLink = WebSocketLink(
      graphQlWsUrlResolved,
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
    final endpoint = _endpointUrl;
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
      _logOperationException(
        exception: result.exception!,
        operationName: options.operationName ?? 'UnnamedQuery',
        endpoint: _endpointUrl,
        variables: options.variables,
      );
      try {
        _handleGraphQLException(result.exception!);
      } on app_exceptions.AuthException {
        if (didRetry) {
          _authDelegate?.onAuthExpired();
          rethrow;
        }

        final refreshedToken = await _tokenProvider?.refreshAccessToken();
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          _authDelegate?.onTokenRefreshed(refreshedToken);
          return _queryWithRetry(options, didRetry: true);
        }

        _authDelegate?.onAuthExpired();
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
    final endpoint = _endpointUrl;
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
      _logOperationException(
        exception: result.exception!,
        operationName: options.operationName ?? 'UnnamedMutation',
        endpoint: _endpointUrl,
        variables: options.variables,
      );
      try {
        _handleGraphQLException(result.exception!);
      } on app_exceptions.AuthException {
        if (didRetry) {
          _authDelegate?.onAuthExpired();
          rethrow;
        }

        final refreshedToken = await _tokenProvider?.refreshAccessToken();
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          _authDelegate?.onTokenRefreshed(refreshedToken);
          return _mutateWithRetry(options, didRetry: true);
        }

        _authDelegate?.onAuthExpired();
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

  Map<String, dynamic> _redactVariables(Map<String, dynamic> input) {
    dynamic redact(dynamic value) {
      if (value is Map) {
        final out = <String, dynamic>{};
        for (final entry in value.entries) {
          final key = entry.key.toString();
          final v = entry.value;
          if (key == 'message' || key == 'content') {
            out[key] = '<redacted>';
            continue;
          }
          if (key == 'urls' && v is List) {
            out[key] = {'count': v.length};
            continue;
          }
          out[key] = redact(v);
        }
        return out;
      }
      if (value is List) {
        return value.map(redact).toList();
      }
      return value;
    }

    return redact(input) as Map<String, dynamic>;
  }

  void _logOperationException({
    required OperationException exception,
    required String operationName,
    required String endpoint,
    required Map<String, dynamic> variables,
  }) {
    final errors = exception.graphqlErrors
        .map(
          (e) => {
            'message': e.message,
            'code': e.extensions?['code'],
            'path': e.path,
            'extensions': e.extensions,
          },
        )
        .toList();

    _logger.error(
      'GraphQL operation exception',
      {
        'operation': operationName,
        'endpoint': endpoint,
        'linkException': exception.linkException?.toString(),
        'graphqlErrors': errors,
        'variables': _redactVariables(variables),
      },
    );
  }

  /// Safely read env value — returns empty string if not available.
  /// Used only in [createClient] as fallback when explicit URLs aren't provided.
  static String _tryGetEnv(String key) {
    return _dotenvCache?[key]?.trim() ?? '';
  }

  static Map<String, String>? _dotenvCache;

  /// Pre-populate env cache for standalone mode.
  /// Called by injection.dart during standalone app initialization.
  static void setEnvCache(Map<String, String> env) {
    _dotenvCache = env;
  }
}