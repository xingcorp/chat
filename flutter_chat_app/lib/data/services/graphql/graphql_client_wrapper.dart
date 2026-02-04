import 'package:flutter_chat_app/core/exceptions/exceptions.dart';
import 'package:flutter_chat_app/core/constants/storage_keys.dart';
import 'package:flutter_chat_app/core/storage/secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart' hide ServerException;
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper for GraphQL client to handle common operations
class GraphQLClientWrapper {
  final GraphQLClient _client;
  final SharedPreferences _preferences;
  final SecureStorage? _secureStorage;
  static const String _tokenKey = 'auth_token';

  /// Constructor
  GraphQLClientWrapper(
    this._client,
    this._preferences, {
    SecureStorage? secureStorage,
  }) : _secureStorage = secureStorage;

  /// Factory constructor to create a GraphQL client with default settings
  static Future<GraphQLClientWrapper> create({
    required String endpoint,
    required SharedPreferences preferences,
    SecureStorage? secureStorage,
  }) async {
    final HttpLink httpLink = HttpLink(endpoint);
    
    // Create an auth link that adds the token to requests
    final AuthLink authLink = AuthLink(
      getToken: () async {
        final token = preferences.getString(StorageKeys.accessToken) ??
            preferences.getString(_tokenKey);
        return token == null ? '' : 'Bearer $token';
      },
    );
    
    // Combine the auth link with the http link
    final Link link = authLink.concat(httpLink);
    
    // Create client
    final GraphQLClient client = GraphQLClient(
      link: link,
      cache: GraphQLCache(),
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.networkOnly,
        ),
        mutate: Policies(
          fetch: FetchPolicy.networkOnly,
        ),
        subscribe: Policies(
          fetch: FetchPolicy.networkOnly,
        ),
      ),
    );
    
    return GraphQLClientWrapper(
      client,
      preferences,
      secureStorage: secureStorage,
    );
  }

  /// Execute a GraphQL query
  Future<QueryResult> query(
    String query, {
    Map<String, dynamic> variables = const {},
  }) async {
    try {
      final options = QueryOptions(
        document: gql(query),
        variables: variables,
      );
      
      final result = await _client.query(options);
      
      // Check for connection errors
      if (result.hasException) {
        final errors = result.exception?.graphqlErrors ?? [];
        
        if (errors.isNotEmpty) {
          final firstError = errors.first;
          
          // Check if token expired
          if (firstError.message.contains('unauthorized') ||
              firstError.message.contains('token') ||
              firstError.extensions?['code'] == 'UNAUTHENTICATED') {
            throw AuthException(message: 'Authentication failed');
          }
          
          throw ServerException(message: firstError.message);
        } else if (result.exception?.linkException != null) {
          throw NoInternetException();
        }
      }
      
      return result;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'GraphQL query failed: $e');
    }
  }

  /// Execute a GraphQL mutation
  Future<QueryResult> mutate(
    String mutation, {
    Map<String, dynamic> variables = const {},
  }) async {
    try {
      final options = MutationOptions(
        document: gql(mutation),
        variables: variables,
      );
      
      final result = await _client.mutate(options);
      
      // Check for connection errors
      if (result.hasException) {
        final errors = result.exception?.graphqlErrors ?? [];
        
        if (errors.isNotEmpty) {
          final firstError = errors.first;
          
          // Check if token expired
          if (firstError.message.contains('unauthorized') ||
              firstError.message.contains('token') ||
              firstError.extensions?['code'] == 'UNAUTHENTICATED') {
            throw AuthException(message: 'Authentication failed');
          }
          
          throw ServerException(message: firstError.message);
        } else if (result.exception?.linkException != null) {
          throw NoInternetException();
        }
      }
      
      return result;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'GraphQL mutation failed: $e');
    }
  }

  /// Subscribe to a GraphQL subscription
  Stream<QueryResult> subscribe(
    String subscription, {
    Map<String, dynamic> variables = const {},
  }) {
    try {
      final options = SubscriptionOptions(
        document: gql(subscription),
        variables: variables,
      );
      
      return _client.subscribe(options);
    } catch (e) {
      throw ServerException(message: 'GraphQL subscription failed: $e');
    }
  }

  /// Store the authentication token
  Future<void> setToken(String token) async {
    final futures = <Future<void>>[
      _preferences.setString(StorageKeys.accessToken, token),
      _preferences.remove(_tokenKey),
    ];
    if (_secureStorage != null) {
      futures.add(_secureStorage!.setString(StorageKeys.accessToken, token));
    }
    await Future.wait(futures);
  }

  /// Get the stored authentication token
  Future<String?> getToken() async {
    final current = _preferences.getString(StorageKeys.accessToken);
    if (current != null && current.isNotEmpty) {
      return current;
    }

    final legacy = _preferences.getString(_tokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await Future.wait([
        _preferences.setString(StorageKeys.accessToken, legacy),
        _preferences.remove(_tokenKey),
      ]);
      return legacy;
    }

    return null;
  }

  /// Clear the stored authentication token
  Future<void> clearToken() async {
    final futures = <Future<void>>[
      _preferences.remove(_tokenKey),
      _preferences.remove(StorageKeys.accessToken),
    ];
    if (_secureStorage != null) {
      futures.add(_secureStorage!.remove(StorageKeys.accessToken));
    }
    await Future.wait(futures);
  }
}