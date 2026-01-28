// 🎛️ **UNIFIED BLOC TEMPLATE**
// This template provides the standard implementation pattern for all BLoCs
// following the consolidated BaseBloc approach with enterprise features.

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_bloc.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/di/injection.dart';

// Domain imports
import 'package:flutter_chat_app/domain/entities/[entity_name].dart';
import 'package:flutter_chat_app/domain/repositories/i_[entity_name]_repository.dart';

/// **TEMPLATE USAGE INSTRUCTIONS:**
/// 
/// 1. Replace [FeatureName] with your actual feature name (e.g., Chat, Message, User)
/// 2. Replace [feature_name] with snake_case version (e.g., chat, message, user)
/// 3. Define all events that this BLoC should handle
/// 4. Define all states that this BLoC can emit
/// 5. Implement event handlers using executeWithErrorHandling
/// 6. Add comprehensive analytics tracking
/// 7. Include proper documentation for all public methods

// ==================== EVENTS ====================

abstract class [FeatureName]Event extends Equatable {
  const [FeatureName]Event();

  @override
  List<Object?> get props => [];
}

/// Load [feature_name] data
class Load[FeatureName]Data extends [FeatureName]Event {
  final String? userId;
  final Map<String, dynamic>? filters;

  const Load[FeatureName]Data({
    this.userId,
    this.filters,
  });

  @override
  List<Object?> get props => [userId, filters];
}

/// Create new [feature_name] item
class Create[FeatureName]Item extends [FeatureName]Event {
  final String name;
  final String description;
  final Map<String, dynamic>? metadata;

  const Create[FeatureName]Item({
    required this.name,
    required this.description,
    this.metadata,
  });

  @override
  List<Object?> get props => [name, description, metadata];
}

/// Update existing [feature_name] item
class Update[FeatureName]Item extends [FeatureName]Event {
  final String id;
  final String? name;
  final String? description;
  final Map<String, dynamic>? metadata;

  const Update[FeatureName]Item({
    required this.id,
    this.name,
    this.description,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, name, description, metadata];
}

/// Delete [feature_name] item
class Delete[FeatureName]Item extends [FeatureName]Event {
  final String id;

  const Delete[FeatureName]Item({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Refresh [feature_name] data
class Refresh[FeatureName]Data extends [FeatureName]Event {
  const Refresh[FeatureName]Data();
}

/// Search [feature_name] items
class Search[FeatureName]Items extends [FeatureName]Event {
  final String query;

  const Search[FeatureName]Items({required this.query});

  @override
  List<Object?> get props => [query];
}

// ==================== STATES ====================

abstract class [FeatureName]State extends Equatable {
  const [FeatureName]State();

  @override
  List<Object?> get props => [];
}

/// Initial state
class [FeatureName]Initial extends [FeatureName]State {
  const [FeatureName]Initial();

  @override
  String toString() => '[FeatureName]Initial';
}

/// Loading state
class [FeatureName]Loading extends [FeatureName]State {
  final String? message;
  final double? progress;

  const [FeatureName]Loading({
    this.message,
    this.progress,
  });

  @override
  List<Object?> get props => [message, progress];

  @override
  String toString() => '[FeatureName]Loading{message: $message, progress: $progress}';
}

/// Loaded state with data
class [FeatureName]Loaded extends [FeatureName]State {
  final List<[FeatureName]Item> items;
  final bool hasReachedMax;
  final DateTime lastUpdated;

  const [FeatureName]Loaded({
    required this.items,
    this.hasReachedMax = false,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  [FeatureName]Loaded copyWith({
    List<[FeatureName]Item>? items,
    bool? hasReachedMax,
    DateTime? lastUpdated,
  }) {
    return [FeatureName]Loaded(
      items: items ?? this.items,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [items, hasReachedMax, lastUpdated];

  @override
  String toString() => '[FeatureName]Loaded{items: ${items.length}, hasReachedMax: $hasReachedMax}';
}

/// Error state
class [FeatureName]Error extends [FeatureName]State {
  final Failure failure;
  final List<[FeatureName]Item> items; // Preserve existing data

  const [FeatureName]Error({
    required this.failure,
    this.items = const [],
  });

  @override
  List<Object?> get props => [failure, items];

  @override
  String toString() => '[FeatureName]Error{failure: $failure}';
}

// ==================== BLOC ====================

class [FeatureName]Bloc extends BaseBloc<[FeatureName]Event, [FeatureName]State> {
  late final I[FeatureName]Repository _repository;

  [FeatureName]Bloc() : super(
    analyticsService: EnterpriseDI.get(),
    crashReporter: EnterpriseDI.get(),
    logger: EnterpriseDI.get(),
    performanceMonitor: EnterpriseDI.get(),
    errorRecoveryService: EnterpriseDI.get(),
    initialState: const [FeatureName]Initial(),
  ) {
    _repository = EnterpriseDI.get<I[FeatureName]Repository>();
    
    // Register event handlers
    on<Load[FeatureName]Data>(_onLoad[FeatureName]Data);
    on<Create[FeatureName]Item>(_onCreate[FeatureName]Item);
    on<Update[FeatureName]Item>(_onUpdate[FeatureName]Item);
    on<Delete[FeatureName]Item>(_onDelete[FeatureName]Item);
    on<Refresh[FeatureName]Data>(_onRefresh[FeatureName]Data);
    on<Search[FeatureName]Items>(_onSearch[FeatureName]Items);
  }

  /// Load [feature_name] data
  Future<void> _onLoad[FeatureName]Data(
    Load[FeatureName]Data event,
    Emitter<[FeatureName]State> emit,
  ) async {
    emitWithAnalytics(
      const [FeatureName]Loading(message: 'Loading [feature_name] data...'),
      eventName: '[feature_name]_load_started',
      properties: {
        'user_id': event.userId,
        'has_filters': event.filters != null,
        'filter_count': event.filters?.length ?? 0,
      },
    );

    await executeWithErrorHandling<List<[FeatureName]Item>>(
      operation: () => _repository.get[FeatureName]Items(
        userId: event.userId,
        filters: event.filters,
      ),
      onSuccess: (items) {
        emitWithAnalytics(
          [FeatureName]Loaded(items: items),
          eventName: '[feature_name]_load_success',
          properties: {
            'user_id': event.userId,
            'items_count': items.length,
            'load_duration_ms': DateTime.now().millisecondsSinceEpoch,
          },
        );
      },
      onError: (failure) {
        emitWithAnalytics(
          [FeatureName]Error(failure: failure),
          eventName: '[feature_name]_load_error',
          properties: {
            'user_id': event.userId,
            'error_type': failure.type.name,
            'error_code': failure.code,
          },
        );
      },
      operationName: 'load[FeatureName]Data',
      context: {
        'userId': event.userId,
        'filters': event.filters,
      },
      maxRetries: 3,
    );
  }

  /// Create new [feature_name] item
  Future<void> _onCreate[FeatureName]Item(
    Create[FeatureName]Item event,
    Emitter<[FeatureName]State> emit,
  ) async {
    final currentState = state;
    
    emitWithAnalytics(
      currentState is [FeatureName]Loaded
          ? [FeatureName]Loading(message: 'Creating [feature_name] item...')
          : const [FeatureName]Loading(message: 'Creating [feature_name] item...'),
      eventName: '[feature_name]_create_started',
      properties: {
        'item_name': event.name,
        'has_metadata': event.metadata != null,
      },
    );

    await executeWithErrorHandling<[FeatureName]Item>(
      operation: () => _repository.create[FeatureName]Item(
        name: event.name,
        description: event.description,
        metadata: event.metadata,
      ),
      onSuccess: (newItem) {
        if (currentState is [FeatureName]Loaded) {
          emitWithAnalytics(
            currentState.copyWith(
              items: [newItem, ...currentState.items],
              lastUpdated: DateTime.now(),
            ),
            eventName: '[feature_name]_create_success',
            properties: {
              'item_id': newItem.id,
              'item_name': newItem.name,
              'total_items': currentState.items.length + 1,
            },
          );
        } else {
          emitWithAnalytics(
            [FeatureName]Loaded(items: [newItem]),
            eventName: '[feature_name]_create_success',
            properties: {
              'item_id': newItem.id,
              'item_name': newItem.name,
              'total_items': 1,
            },
          );
        }
      },
      onError: (failure) {
        emitWithAnalytics(
          [FeatureName]Error(
            failure: failure,
            items: currentState is [FeatureName]Loaded ? currentState.items : [],
          ),
          eventName: '[feature_name]_create_error',
          properties: {
            'item_name': event.name,
            'error_type': failure.type.name,
            'error_code': failure.code,
          },
        );
      },
      operationName: 'create[FeatureName]Item',
      context: {
        'itemName': event.name,
        'hasMetadata': event.metadata != null,
      },
    );
  }

  /// Update existing [feature_name] item
  Future<void> _onUpdate[FeatureName]Item(
    Update[FeatureName]Item event,
    Emitter<[FeatureName]State> emit,
  ) async {
    final currentState = state;
    
    if (currentState is! [FeatureName]Loaded) {
      emitWithAnalytics(
        [FeatureName]Error(
          failure: const ValidationFailure(message: 'Cannot update item: no data loaded'),
        ),
        eventName: '[feature_name]_update_error',
        properties: {
          'item_id': event.id,
          'error_reason': 'no_data_loaded',
        },
      );
      return;
    }

    await executeWithErrorHandling<[FeatureName]Item>(
      operation: () => _repository.update[FeatureName]Item(
        id: event.id,
        name: event.name,
        description: event.description,
        metadata: event.metadata,
      ),
      onSuccess: (updatedItem) {
        final updatedItems = currentState.items.map((item) {
          return item.id == event.id ? updatedItem : item;
        }).toList();

        emitWithAnalytics(
          currentState.copyWith(
            items: updatedItems,
            lastUpdated: DateTime.now(),
          ),
          eventName: '[feature_name]_update_success',
          properties: {
            'item_id': updatedItem.id,
            'item_name': updatedItem.name,
          },
        );
      },
      onError: (failure) {
        emitWithAnalytics(
          [FeatureName]Error(
            failure: failure,
            items: currentState.items,
          ),
          eventName: '[feature_name]_update_error',
          properties: {
            'item_id': event.id,
            'error_type': failure.type.name,
            'error_code': failure.code,
          },
        );
      },
      operationName: 'update[FeatureName]Item',
      context: {'itemId': event.id},
    );
  }

  /// Delete [feature_name] item
  Future<void> _onDelete[FeatureName]Item(
    Delete[FeatureName]Item event,
    Emitter<[FeatureName]State> emit,
  ) async {
    final currentState = state;
    
    if (currentState is! [FeatureName]Loaded) return;

    await executeWithErrorHandling<void>(
      operation: () => _repository.delete[FeatureName]Item(event.id),
      onSuccess: (_) {
        final updatedItems = currentState.items
            .where((item) => item.id != event.id)
            .toList();

        emitWithAnalytics(
          currentState.copyWith(
            items: updatedItems,
            lastUpdated: DateTime.now(),
          ),
          eventName: '[feature_name]_delete_success',
          properties: {
            'item_id': event.id,
            'remaining_items': updatedItems.length,
          },
        );
      },
      onError: (failure) {
        emitWithAnalytics(
          [FeatureName]Error(
            failure: failure,
            items: currentState.items,
          ),
          eventName: '[feature_name]_delete_error',
          properties: {
            'item_id': event.id,
            'error_type': failure.type.name,
            'error_code': failure.code,
          },
        );
      },
      operationName: 'delete[FeatureName]Item',
      context: {'itemId': event.id},
    );
  }

  /// Refresh [feature_name] data
  Future<void> _onRefresh[FeatureName]Data(
    Refresh[FeatureName]Data event,
    Emitter<[FeatureName]State> emit,
  ) async {
    // Refresh without showing loading state to preserve UI
    await executeWithErrorHandling<List<[FeatureName]Item>>(
      operation: () => _repository.refresh[FeatureName]Items(),
      onSuccess: (items) {
        emitWithAnalytics(
          [FeatureName]Loaded(items: items),
          eventName: '[feature_name]_refresh_success',
          properties: {
            'items_count': items.length,
            'refresh_type': 'manual',
          },
        );
      },
      onError: (failure) {
        // Keep existing data on refresh error
        final currentState = state;
        emitWithAnalytics(
          [FeatureName]Error(
            failure: failure,
            items: currentState is [FeatureName]Loaded ? currentState.items : [],
          ),
          eventName: '[feature_name]_refresh_error',
          properties: {
            'error_type': failure.type.name,
            'error_code': failure.code,
          },
        );
      },
      operationName: 'refresh[FeatureName]Data',
    );
  }

  /// Search [feature_name] items
  Future<void> _onSearch[FeatureName]Items(
    Search[FeatureName]Items event,
    Emitter<[FeatureName]State> emit,
  ) async {
    if (event.query.isEmpty) {
      // Clear search, reload all items
      add(const Load[FeatureName]Data());
      return;
    }

    emitWithAnalytics(
      const [FeatureName]Loading(message: 'Searching [feature_name] items...'),
      eventName: '[feature_name]_search_started',
      properties: {
        'query': event.query,
        'query_length': event.query.length,
      },
    );

    await executeWithErrorHandling<List<[FeatureName]Item>>(
      operation: () => _repository.search[FeatureName]Items(event.query),
      onSuccess: (items) {
        emitWithAnalytics(
          [FeatureName]Loaded(items: items),
          eventName: '[feature_name]_search_success',
          properties: {
            'query': event.query,
            'results_count': items.length,
          },
        );
      },
      onError: (failure) {
        emitWithAnalytics(
          [FeatureName]Error(failure: failure),
          eventName: '[feature_name]_search_error',
          properties: {
            'query': event.query,
            'error_type': failure.type.name,
            'error_code': failure.code,
          },
        );
      },
      operationName: 'search[FeatureName]Items',
      context: {'query': event.query},
    );
  }
}

/// **USAGE GUIDELINES:**
/// 
/// **Event Naming**: Use descriptive verbs (Load, Create, Update, Delete, Refresh, Search)
/// **State Management**: Always preserve existing data in error states when possible
/// **Analytics**: Track all user actions and system events with relevant context
/// **Error Handling**: Use executeWithErrorHandling for all repository operations
/// **Performance**: Include operation names for performance monitoring
/// **Testing**: All events and states should be easily testable with clear props
