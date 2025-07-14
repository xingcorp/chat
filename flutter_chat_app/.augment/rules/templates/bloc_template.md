# BLoC Template - Enterprise Messaging Pattern

**Type**: Manual  
**Description**: Comprehensive BLoC implementation template for messaging app features with performance optimization and error handling

## Complete BLoC Implementation Template

### Event Definition
```dart
// events/[feature_name]_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '[feature_name]_event.freezed.dart';

@freezed
class [FeatureName]Event with _$[FeatureName]Event {
  // Loading events
  const factory [FeatureName]Event.load({
    @Default(false) bool forceRefresh,
  }) = Load[FeatureName]Event;
  
  const factory [FeatureName]Event.loadMore() = LoadMore[FeatureName]Event;
  
  const factory [FeatureName]Event.refresh() = Refresh[FeatureName]Event;
  
  // Action events
  const factory [FeatureName]Event.create({
    required [EntityType] entity,
  }) = Create[FeatureName]Event;
  
  const factory [FeatureName]Event.update({
    required String id,
    required [EntityType] entity,
  }) = Update[FeatureName]Event;
  
  const factory [FeatureName]Event.delete({
    required String id,
  }) = Delete[FeatureName]Event;
  
  // Real-time events
  const factory [FeatureName]Event.receive({
    required [EntityType] entity,
  }) = Receive[FeatureName]Event;
  
  // Error recovery events
  const factory [FeatureName]Event.retry() = Retry[FeatureName]Event;
  
  const factory [FeatureName]Event.clearError() = ClearError[FeatureName]Event;
}
```

### State Definition
```dart
// states/[feature_name]_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_app/domain/entities/[entity_name].dart';

part '[feature_name]_state.freezed.dart';

@freezed
class [FeatureName]State with _$[FeatureName]State {
  const factory [FeatureName]State.initial() = [FeatureName]Initial;
  
  const factory [FeatureName]State.loading({
    @Default([]) List<[EntityType]> items,
    @Default(false) bool isLoadingMore,
  }) = [FeatureName]Loading;
  
  const factory [FeatureName]State.loaded({
    required List<[EntityType]> items,
    @Default(false) bool hasMore,
    @Default(false) bool isLoadingMore,
    @Default(false) bool isRefreshing,
  }) = [FeatureName]Loaded;
  
  const factory [FeatureName]State.error({
    required String message,
    required Failure failure,
    @Default([]) List<[EntityType]> items,
    @Default(false) bool canRetry,
  }) = [FeatureName]Error;
}

// State extensions for convenience
extension [FeatureName]StateX on [FeatureName]State {
  List<[EntityType]> get items => maybeMap(
    loading: (state) => state.items,
    loaded: (state) => state.items,
    error: (state) => state.items,
    orElse: () => [],
  );
  
  bool get isLoading => maybeMap(
    loading: (_) => true,
    orElse: () => false,
  );
  
  bool get hasError => maybeMap(
    error: (_) => true,
    orElse: () => false,
  );
  
  String? get errorMessage => maybeMap(
    error: (state) => state.message,
    orElse: () => null,
  );
  
  bool get canLoadMore => maybeMap(
    loaded: (state) => state.hasMore && !state.isLoadingMore,
    orElse: () => false,
  );
}
```

### BLoC Implementation
```dart
// blocs/[feature_name]_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';

import 'package:flutter_chat_app/domain/usecases/[feature_name]/get_[entity_name]s_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/[feature_name]/create_[entity_name]_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/[feature_name]/update_[entity_name]_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/[feature_name]/delete_[entity_name]_usecase.dart';
import 'package:flutter_chat_app/core/services/websocket_service.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';

@injectable
class [FeatureName]Bloc extends Bloc<[FeatureName]Event, [FeatureName]State> {
  final Get[EntityName]sUseCase _get[EntityName]s;
  final Create[EntityName]UseCase _create[EntityName];
  final Update[EntityName]UseCase _update[EntityName];
  final Delete[EntityName]UseCase _delete[EntityName];
  final WebSocketService _webSocketService;
  final Logger _logger;
  
  StreamSubscription<[EntityType]>? _realTimeSubscription;
  
  [FeatureName]Bloc({
    required Get[EntityName]sUseCase get[EntityName]s,
    required Create[EntityName]UseCase create[EntityName],
    required Update[EntityName]UseCase update[EntityName],
    required Delete[EntityName]UseCase delete[EntityName],
    required WebSocketService webSocketService,
    required Logger logger,
  }) : _get[EntityName]s = get[EntityName]s,
       _create[EntityName] = create[EntityName],
       _update[EntityName] = update[EntityName],
       _delete[EntityName] = delete[EntityName],
       _webSocketService = webSocketService,
       _logger = logger,
       super(const [FeatureName]State.initial()) {
    
    on<Load[FeatureName]Event>(_onLoad);
    on<LoadMore[FeatureName]Event>(_onLoadMore);
    on<Refresh[FeatureName]Event>(_onRefresh);
    on<Create[FeatureName]Event>(_onCreate);
    on<Update[FeatureName]Event>(_onUpdate);
    on<Delete[FeatureName]Event>(_onDelete);
    on<Receive[FeatureName]Event>(_onReceive);
    on<Retry[FeatureName]Event>(_onRetry);
    on<ClearError[FeatureName]Event>(_onClearError);
    
    _setupRealTimeSubscription();
  }
  
  void _setupRealTimeSubscription() {
    _realTimeSubscription = _webSocketService
        .[entityName]Stream
        .listen((entity) => add([FeatureName]Event.receive(entity: entity)));
  }
  
  Future<void> _onLoad(
    Load[FeatureName]Event event,
    Emitter<[FeatureName]State> emit,
  ) async {
    _logger.i('[FeatureName]Bloc: Loading [entity_name]s');
    
    emit([FeatureName]State.loading(items: state.items));
    
    final result = await _get[EntityName]s(Get[EntityName]sParams(
      forceRefresh: event.forceRefresh,
    ));
    
    result.fold(
      (failure) {
        _logger.e('[FeatureName]Bloc: Failed to load [entity_name]s: ${failure.message}');
        emit([FeatureName]State.error(
          message: failure.message,
          failure: failure,
          items: state.items,
          canRetry: true,
        ));
      },
      (items) {
        _logger.i('[FeatureName]Bloc: Loaded ${items.length} [entity_name]s');
        emit([FeatureName]State.loaded(
          items: items,
          hasMore: items.length >= 20, // Adjust based on pagination
        ));
      },
    );
  }
  
  Future<void> _onLoadMore(
    LoadMore[FeatureName]Event event,
    Emitter<[FeatureName]State> emit,
  ) async {
    final currentState = state;
    if (currentState is! [FeatureName]Loaded || 
        !currentState.hasMore || 
        currentState.isLoadingMore) {
      return;
    }
    
    _logger.i('[FeatureName]Bloc: Loading more [entity_name]s');
    
    emit(currentState.copyWith(isLoadingMore: true));
    
    final result = await _get[EntityName]s(Get[EntityName]sParams(
      offset: currentState.items.length,
    ));
    
    result.fold(
      (failure) {
        _logger.e('[FeatureName]Bloc: Failed to load more [entity_name]s: ${failure.message}');
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (newItems) {
        _logger.i('[FeatureName]Bloc: Loaded ${newItems.length} more [entity_name]s');
        emit(currentState.copyWith(
          items: [...currentState.items, ...newItems],
          hasMore: newItems.length >= 20,
          isLoadingMore: false,
        ));
      },
    );
  }
  
  Future<void> _onCreate(
    Create[FeatureName]Event event,
    Emitter<[FeatureName]State> emit,
  ) async {
    _logger.i('[FeatureName]Bloc: Creating [entity_name]');
    
    // Optimistic update
    final currentItems = state.items;
    final optimisticItem = event.entity.copyWith(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    
    emit(state.maybeMap(
      loaded: (state) => state.copyWith(
        items: [optimisticItem, ...state.items],
      ),
      orElse: () => [FeatureName]State.loaded(
        items: [optimisticItem, ...currentItems],
      ),
    ));
    
    final result = await _create[EntityName](Create[EntityName]Params(
      entity: event.entity,
    ));
    
    result.fold(
      (failure) {
        _logger.e('[FeatureName]Bloc: Failed to create [entity_name]: ${failure.message}');
        // Remove optimistic item and show error
        emit([FeatureName]State.error(
          message: failure.message,
          failure: failure,
          items: currentItems,
          canRetry: true,
        ));
      },
      (createdItem) {
        _logger.i('[FeatureName]Bloc: Created [entity_name] successfully');
        // Replace optimistic item with real item
        final updatedItems = state.items
            .map((item) => item.id == optimisticItem.id ? createdItem : item)
            .toList();
        
        emit(state.maybeMap(
          loaded: (state) => state.copyWith(items: updatedItems),
          orElse: () => [FeatureName]State.loaded(items: updatedItems),
        ));
      },
    );
  }
  
  Future<void> _onReceive(
    Receive[FeatureName]Event event,
    Emitter<[FeatureName]State> emit,
  ) async {
    _logger.d('[FeatureName]Bloc: Received real-time [entity_name] update');
    
    final currentItems = state.items;
    final existingIndex = currentItems.indexWhere(
      (item) => item.id == event.entity.id,
    );
    
    List<[EntityType]> updatedItems;
    if (existingIndex != -1) {
      // Update existing item
      updatedItems = List.from(currentItems);
      updatedItems[existingIndex] = event.entity;
    } else {
      // Add new item
      updatedItems = [event.entity, ...currentItems];
    }
    
    emit(state.maybeMap(
      loaded: (state) => state.copyWith(items: updatedItems),
      orElse: () => [FeatureName]State.loaded(items: updatedItems),
    ));
  }
  
  void _onRetry(
    Retry[FeatureName]Event event,
    Emitter<[FeatureName]State> emit,
  ) {
    _logger.i('[FeatureName]Bloc: Retrying last operation');
    add(const [FeatureName]Event.load(forceRefresh: true));
  }
  
  void _onClearError(
    ClearError[FeatureName]Event event,
    Emitter<[FeatureName]State> emit,
  ) {
    emit(state.maybeMap(
      error: (state) => [FeatureName]State.loaded(items: state.items),
      orElse: () => state,
    ));
  }
  
  @override
  Future<void> close() {
    _realTimeSubscription?.cancel();
    return super.close();
  }
}
```

### Widget Integration
```dart
// widgets/[feature_name]_list_widget.dart
class [FeatureName]ListView extends StatelessWidget {
  const [FeatureName]ListView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<[FeatureName]Bloc, [FeatureName]State>(
      listener: (context, state) {
        state.maybeMap(
          error: (errorState) {
            if (errorState.canRetry) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorState.message),
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: () => context.read<[FeatureName]Bloc>()
                        .add(const [FeatureName]Event.retry()),
                  ),
                ),
              );
            }
          },
          orElse: () {},
        );
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<[FeatureName]Bloc>()
                .add(const [FeatureName]Event.refresh());
          },
          child: state.maybeMap(
            initial: (_) => const Center(child: CircularProgressIndicator()),
            loading: (state) => _buildLoadingList(state.items),
            loaded: (state) => _buildLoadedList(state),
            error: (state) => _buildErrorList(state),
            orElse: () => const SizedBox.shrink(),
          ),
        );
      },
    );
  }
  
  Widget _buildLoadedList([FeatureName]Loaded state) {
    return ListView.builder(
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          // Load more indicator
          if (!state.isLoadingMore) {
            context.read<[FeatureName]Bloc>()
                .add(const [FeatureName]Event.loadMore());
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return [EntityName]Tile(
          [entityName]: state.items[index],
          key: ValueKey(state.items[index].id),
        );
      },
    );
  }
}
```

### Testing Template
```dart
// test/blocs/[feature_name]_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('[FeatureName]Bloc', () {
    late [FeatureName]Bloc bloc;
    late MockGet[EntityName]sUseCase mockGet[EntityName]s;
    late MockCreate[EntityName]UseCase mockCreate[EntityName];
    late MockWebSocketService mockWebSocketService;
    
    setUp(() {
      mockGet[EntityName]s = MockGet[EntityName]sUseCase();
      mockCreate[EntityName] = MockCreate[EntityName]UseCase();
      mockWebSocketService = MockWebSocketService();
      
      bloc = [FeatureName]Bloc(
        get[EntityName]s: mockGet[EntityName]s,
        create[EntityName]: mockCreate[EntityName],
        webSocketService: mockWebSocketService,
        logger: MockLogger(),
      );
    });
    
    blocTest<[FeatureName]Bloc, [FeatureName]State>(
      'emits [loading, loaded] when [entity_name]s are loaded successfully',
      build: () {
        when(mockGet[EntityName]s(any))
            .thenAnswer((_) async => Right([test[EntityName]]));
        return bloc;
      },
      act: (bloc) => bloc.add(const [FeatureName]Event.load()),
      expect: () => [
        [FeatureName]State.loading(),
        [FeatureName]State.loaded(items: [test[EntityName]]),
      ],
      verify: (_) {
        verify(mockGet[EntityName]s(any)).called(1);
      },
    );
    
    blocTest<[FeatureName]Bloc, [FeatureName]State>(
      'handles optimistic updates correctly',
      build: () => bloc,
      seed: () => [FeatureName]State.loaded(items: []),
      act: (bloc) {
        when(mockCreate[EntityName](any))
            .thenAnswer((_) async => Right(test[EntityName]));
        bloc.add([FeatureName]Event.create(entity: test[EntityName]));
      },
      expect: () => [
        // Optimistic update
        [FeatureName]State.loaded(items: [isA<[EntityType]>()]),
        // Real update
        [FeatureName]State.loaded(items: [test[EntityName]]),
      ],
    );
  });
}
```
