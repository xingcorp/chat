// 🏗️ **UNIFIED REPOSITORY TEMPLATE**
// This template provides the standard implementation pattern for all repositories
// following the consolidated BaseRepository approach with enterprise features.

import 'dart:async';
import 'package:flutter_chat_app/core/base/base_repository.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';

// Domain imports
import 'package:flutter_chat_app/domain/entities/[entity_name].dart';
import 'package:flutter_chat_app/domain/repositories/i_[entity_name]_repository.dart';

// Data imports
import 'package:flutter_chat_app/data/datasources/[entity_name]/[entity_name]_remote_datasource.dart';
import 'package:flutter_chat_app/data/datasources/[entity_name]/[entity_name]_local_datasource.dart';
import 'package:flutter_chat_app/data/models/[entity_name]_model.dart';

/// **TEMPLATE USAGE INSTRUCTIONS:**
/// 
/// 1. Replace [EntityName] with your actual entity name (e.g., User, Chat, Message)
/// 2. Replace [entity_name] with snake_case version (e.g., user, chat, message)
/// 3. Implement all abstract methods from I[EntityName]Repository
/// 4. Choose appropriate BaseRepository strategy for each method:
///    - executeOnlineFirst: For real-time data (new messages, status updates)
///    - executeOfflineFirst: For cached data (chat history, user profiles)
///    - executeRemoteOnly: For authentication, fresh server data
///    - executeLocalOnly: For preferences, drafts
/// 5. Add comprehensive error handling and performance monitoring
/// 6. Include proper documentation for all public methods

class [EntityName]RepositoryImpl extends BaseRepository implements I[EntityName]Repository {
  final [EntityName]RemoteDataSource _remoteDataSource;
  final [EntityName]LocalDataSource _localDataSource;

  [EntityName]RepositoryImpl({
    required [EntityName]RemoteDataSource remoteDataSource,
    required [EntityName]LocalDataSource localDataSource,
    required super.networkInfo,
    required super.logger,
    required super.performanceMonitor,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  /// **EXAMPLE: Get entities with offline-first strategy**
  /// Use this pattern for data that should be available immediately from cache
  /// with background synchronization for updates.
  @override
  Future<Either<Failure, List<[EntityName]>>> get[EntityName]s() async {
    return executeOfflineFirst<List<[EntityName]>>(
      localDataSource: () async {
        final models = await _localDataSource.getAll[EntityName]s();
        return models.map((model) => model.toDomain()).toList();
      },
      remoteDataSource: () async {
        final models = await _remoteDataSource.get[EntityName]s();
        return models.map((model) => model.toDomain()).toList();
      },
      cacheData: (entities) async {
        final models = entities.map((entity) => [EntityName]Model.fromDomain(entity)).toList();
        await _localDataSource.cache[EntityName]s(models);
      },
      operationName: 'get[EntityName]s',
    );
  }

  /// **EXAMPLE: Get single entity by ID with online-first strategy**
  /// Use this pattern for data that should be fresh from server when possible
  /// with local fallback for offline scenarios.
  @override
  Future<Either<Failure, [EntityName]?>> get[EntityName]ById(String id) async {
    return executeOnlineFirst<[EntityName]?>(
      remoteDataSource: () async {
        final model = await _remoteDataSource.get[EntityName]ById(id);
        return model?.toDomain();
      },
      localDataSource: () async {
        final model = await _localDataSource.get[EntityName]ById(id);
        return model?.toDomain();
      },
      cacheData: (entity) async {
        if (entity != null) {
          final model = [EntityName]Model.fromDomain(entity);
          await _localDataSource.save[EntityName](model);
        }
      },
      operationName: 'get[EntityName]ById',
    );
  }

  /// **EXAMPLE: Create entity with online-first strategy**
  /// Use this pattern for operations that require server confirmation
  /// but should provide immediate feedback to the user.
  @override
  Future<Either<Failure, [EntityName]>> create[EntityName](Create[EntityName]Params params) async {
    return executeOnlineFirst<[EntityName]>(
      remoteDataSource: () async {
        final model = await _remoteDataSource.create[EntityName](params);
        return model.toDomain();
      },
      localDataSource: () async {
        // Create pending local entity for immediate UI feedback
        final pendingModel = [EntityName]Model.createPending(params);
        await _localDataSource.save[EntityName](pendingModel);
        return pendingModel.toDomain();
      },
      cacheData: (entity) async {
        final model = [EntityName]Model.fromDomain(entity);
        await _localDataSource.save[EntityName](model);
      },
      operationName: 'create[EntityName]',
    );
  }

  /// **EXAMPLE: Update entity with online-first strategy**
  @override
  Future<Either<Failure, [EntityName]>> update[EntityName](Update[EntityName]Params params) async {
    return executeOnlineFirst<[EntityName]>(
      remoteDataSource: () async {
        final model = await _remoteDataSource.update[EntityName](params);
        return model.toDomain();
      },
      localDataSource: () async {
        // Update local entity immediately for optimistic updates
        final existingModel = await _localDataSource.get[EntityName]ById(params.id);
        if (existingModel != null) {
          final updatedModel = existingModel.copyWith(
            // Apply updates from params
            updatedAt: DateTime.now(),
          );
          await _localDataSource.save[EntityName](updatedModel);
          return updatedModel.toDomain();
        }
        throw CacheFailure(message: '[EntityName] not found locally');
      },
      cacheData: (entity) async {
        final model = [EntityName]Model.fromDomain(entity);
        await _localDataSource.save[EntityName](model);
      },
      operationName: 'update[EntityName]',
    );
  }

  /// **EXAMPLE: Delete entity with online-first strategy**
  @override
  Future<Either<Failure, void>> delete[EntityName](String id) async {
    return executeOnlineFirst<void>(
      remoteDataSource: () async {
        await _remoteDataSource.delete[EntityName](id);
      },
      localDataSource: () async {
        // Mark as deleted locally for immediate UI feedback
        await _localDataSource.markAsDeleted(id);
      },
      cacheData: (_) async {
        // Remove from local cache after successful server deletion
        await _localDataSource.delete[EntityName](id);
      },
      operationName: 'delete[EntityName]',
    );
  }

  /// **EXAMPLE: Sync entities with remote server**
  /// Use this pattern for background synchronization operations.
  @override
  Future<Either<Failure, void>> sync[EntityName]s() async {
    return executeSyncStrategy(
      syncOperation: () async {
        // Get latest entities from server
        final remoteModels = await _remoteDataSource.get[EntityName]s();
        
        // Update local cache
        await _localDataSource.cache[EntityName]s(remoteModels);
        
        // Sync pending local changes to server
        final pendingModels = await _localDataSource.getPending[EntityName]s();
        for (final model in pendingModels) {
          try {
            await _remoteDataSource.create[EntityName](model.toCreateParams());
            await _localDataSource.markAsSynced(model.id);
          } catch (e) {
            logger.w('Failed to sync [entity_name] ${model.id}: $e');
          }
        }
      },
      operationName: 'sync[EntityName]s',
    );
  }

  /// **EXAMPLE: Search entities with online-first strategy**
  @override
  Future<Either<Failure, List<[EntityName]>>> search[EntityName]s(String query) async {
    return executeOnlineFirst<List<[EntityName]>>(
      remoteDataSource: () async {
        final models = await _remoteDataSource.search[EntityName]s(query);
        return models.map((model) => model.toDomain()).toList();
      },
      localDataSource: () async {
        final models = await _localDataSource.search[EntityName]s(query);
        return models.map((model) => model.toDomain()).toList();
      },
      cacheData: (entities) async {
        // Cache search results for offline access
        final models = entities.map((entity) => [EntityName]Model.fromDomain(entity)).toList();
        await _localDataSource.cacheSearchResults(query, models);
      },
      operationName: 'search[EntityName]s',
    );
  }

  /// **EXAMPLE: Get user preferences (local-only strategy)**
  /// Use this pattern for data that should only be stored locally.
  @override
  Future<Either<Failure, [EntityName]Preferences>> get[EntityName]Preferences() async {
    return executeLocalOnly<[EntityName]Preferences>(
      localDataSource: () async {
        final model = await _localDataSource.get[EntityName]Preferences();
        return model.toDomain();
      },
      operationName: 'get[EntityName]Preferences',
    );
  }

  /// **EXAMPLE: Save user preferences (local-only strategy)**
  @override
  Future<Either<Failure, void>> save[EntityName]Preferences([EntityName]Preferences preferences) async {
    return executeLocalOnly<void>(
      localDataSource: () async {
        final model = [EntityName]PreferencesModel.fromDomain(preferences);
        await _localDataSource.save[EntityName]Preferences(model);
      },
      operationName: 'save[EntityName]Preferences',
    );
  }

  /// **EXAMPLE: Get server configuration (remote-only strategy)**
  /// Use this pattern for data that must always be fresh from server.
  @override
  Future<Either<Failure, [EntityName]Config>> get[EntityName]Config() async {
    return executeRemoteOnly<[EntityName]Config>(
      remoteDataSource: () async {
        final model = await _remoteDataSource.get[EntityName]Config();
        return model.toDomain();
      },
      cacheData: (config) async {
        // Cache for offline fallback if needed
        final model = [EntityName]ConfigModel.fromDomain(config);
        await _localDataSource.save[EntityName]Config(model);
      },
      operationName: 'get[EntityName]Config',
    );
  }
}

/// **STRATEGY SELECTION GUIDELINES:**
/// 
/// **executeOnlineFirst**: Use for real-time data that should be fresh when possible
/// - New messages, user status updates, live data
/// - Operations that require server confirmation
/// - Data that changes frequently
/// 
/// **executeOfflineFirst**: Use for cached data that should be available immediately
/// - Chat history, user profiles, settings
/// - Data that doesn't change frequently
/// - Bulk data that's expensive to fetch
/// 
/// **executeRemoteOnly**: Use for data that must always be fresh
/// - Authentication tokens, server configuration
/// - Security-sensitive operations
/// - One-time operations
/// 
/// **executeLocalOnly**: Use for data that should only be stored locally
/// - User preferences, drafts, temporary data
/// - Privacy-sensitive information
/// - App-specific settings
/// 
/// **executeSyncStrategy**: Use for background synchronization
/// - Batch operations, data reconciliation
/// - Periodic sync operations
/// - Conflict resolution scenarios
