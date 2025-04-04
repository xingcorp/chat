import 'package:flutter_chat_app/core/exceptions/exceptions.dart';
import 'package:graphql_flutter/graphql_flutter.dart' hide ServerException;
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper for GraphQL client to handle common operations
class GraphQLClientWrapper {
  final GraphQLClient _client;
  final SharedPreferences _preferences;
  static const String _tokenKey = 'auth_token';

  /// Constructor
  GraphQLClientWrapper(this._client, this._preferences);

  /// Factory constructor to create a GraphQL client with default settings
  static Future<GraphQLClientWrapper> create({
    required String endpoint,
    required SharedPreferences preferences,
  }) async {
    final HttpLink httpLink = HttpLink(endpoint);
    
    // Create an auth link that adds the token to requests
    final AuthLink authLink = AuthLink(
      getToken: () async {
        final token = preferences.getString(_tokenKey);
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
    
    return GraphQLClientWrapper(client, preferences);
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
    await _preferences.setString(_tokenKey, token);
  }

  /// Get the stored authentication token
  Future<String?> getToken() async {
    return _preferences.getString(_tokenKey);
  }

  /// Clear the stored authentication token
  Future<void> clearToken() async {
    await _preferences.remove(_tokenKey);
  }
} 