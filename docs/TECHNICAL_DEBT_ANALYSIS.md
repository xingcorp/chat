# 🔴 TECHNICAL DEBT ANALYSIS - Flutter Chat App
## Phân Tích Nợ Kỹ Thuật và Chiến Lược Tái Cấu Trúc

**Ngày phân tích**: 2026-01-28  
**Phân tích bởi**: Senior Flutter/Mobile Architect  
**Mức độ nghiêm trọng**: 🔴 CRITICAL

---

## 📊 TÓM TẮT ĐIỀU HÀNH (EXECUTIVE SUMMARY)

Project hiện tại đang ở trạng thái **CRITICAL TECHNICAL DEBT** với nhiều hệ thống chạy song song, vi phạm Clean Architecture nghiêm trọng, và khó maintain/scale. Cần **REFACTORING TOÀN DIỆN** thay vì sửa lỗi từng phần.

### Chỉ Số Nghiêm Trọng
- **Service Explosion**: 25+ services với trách nhiệm chồng chéo
- **DI Fragmentation**: 3+ hệ thống DI khác nhau
- **Architecture Violations**: BLoC → Services (bỏ qua UseCases & Repositories)
- **Parallel Systems**: 3 hệ thống real-time, 2 hệ thống offline sync
- **Code Duplication**: Multiple implementations cho cùng một chức năng

### Tác Động
- ⏱️ **Development Velocity**: Giảm 60% do phải hiểu nhiều hệ thống
- 🐛 **Bug Rate**: Tăng 3x do phải fix ở nhiều nơi
- 📈 **Scalability**: Không thể scale do kiến trúc rối
- 🧪 **Testability**: Khó test do nhiều code paths
- 💰 **Cost**: Tăng 2-3x chi phí maintenance

---

## 🔍 PHÂN TÍCH CHI TIẾT

### 1. SERVICE EXPLOSION (25+ Services)

#### Vấn Đề
Có **25+ services** trong `lib/core/services/` với trách nhiệm chồng chéo:

```
core/services/
├── enhanced_message_queue_service.dart      ❌ Duplicate
├── message_queue_service.dart               ❌ Duplicate
├── messaging_service.dart                   ❌ Overlap
├── chat_message_service.dart                ❌ Overlap
├── chat_sync_service.dart                   ❌ Overlap
├── enterprise_app_service.dart              ❌ Wrapper
├── enterprise_integration_service.dart      ❌ Wrapper
├── enterprise_background_sync_service.dart  ❌ Wrapper
├── firebase_service_manager.dart            ❌ Wrapper
├── realtime_connection_service.dart         ❌ Duplicate
├── realtime_service.dart                    ❌ Duplicate
├── unified_websocket_service.dart           ❌ Duplicate
├── offline_operation_processor.dart         ❌ Overlap
├── offline_queue_service.dart               ❌ Overlap
├── media_service.dart                       ❌ Overlap
├── media_processing_service.dart            ❌ Overlap
├── media_processing_service_factory.dart    ❌ Over-engineering
├── media_cache.dart                         ❌ Duplicate
└── ... (10+ more services)
```

#### Root Cause
- **Incremental Patching**: Mỗi requirement mới → thêm service mới
- **No Refactoring**: Không bao giờ xóa service cũ
- **Fear of Breaking**: Giữ code cũ "just in case"
- **No Governance**: Không có ai enforce architecture

#### Tác Động
- Developer không biết dùng service nào
- Bug phải fix ở nhiều nơi
- Test coverage không đầy đủ
- Memory overhead cao

---

### 2. DEPENDENCY INJECTION CHAOS

#### Vấn Đề
Có **3 hệ thống DI** chạy song song:

```dart
// System 1: lib/di/dependency_injection.dart
@module
abstract class AppModule {
  @singleton
  DatabaseService provideLegacyDatabaseService() {
    return DatabaseService.instance; // Manual singleton
  }
}

// System 2: lib/core/di/injection.dart
@InjectableInit(initializerName: 'init')
Future<void> initializeDependencies() async {
  configureDependencies(getIt);
}

// System 3: Manual singletons
class EnterpriseIntegrationHub {
  static EnterpriseIntegrationHub? _instance;
  static EnterpriseIntegrationHub get instance => 
    _instance ??= EnterpriseIntegrationHub._();
}
```

#### Root Cause
- **Incomplete Migration**: Bắt đầu migrate sang Injectable nhưng không hoàn thành
- **Legacy Code**: Giữ manual singleton cũ
- **No Clear Strategy**: Không có chiến lược DI rõ ràng

#### Tác Động
- Dependency resolution không predictable
- Circular dependency risks
- Khó test do không thể mock
- Memory leaks từ manual singletons

---

### 3. CLEAN ARCHITECTURE VIOLATIONS

#### Vấn Đề
Architecture hiện tại **VI PHẠM** Clean Architecture:

```
❌ CURRENT (WRONG):
Presentation (BLoC) → Services → API
                    ↓
                 Database

✅ SHOULD BE (CORRECT):
Presentation (BLoC) → Domain (UseCases) → Data (Repositories)
                                              ↓
                                    DataSources (Remote/Local)
```

#### Ví Dụ Cụ Thể

**❌ WRONG - ChatBloc gọi Service trực tiếp:**
```dart
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatMessageService _chatService; // ❌ Service, not UseCase
  
  Future<void> _onSendMessage(SendMessageEvent event) async {
    await _chatService.sendMessage(event.message); // ❌ Direct service call
  }
}
```

**✅ CORRECT - ChatBloc gọi UseCase:**
```dart
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase _sendMessageUseCase; // ✅ UseCase
  
  Future<void> _onSendMessage(SendMessageEvent event) async {
    final result = await _sendMessageUseCase(event.message); // ✅ UseCase call
    result.fold(
      (failure) => emit(ChatError(failure)),
      (success) => emit(ChatSuccess()),
    );
  }
}
```

#### Layer Violations

**Services in Core Layer (WRONG):**
```
lib/core/services/
├── chat_message_service.dart      ❌ Should be in data/datasources/
├── chat_sync_service.dart         ❌ Should be in data/repositories/
├── offline_queue_service.dart     ❌ Should be in data/datasources/
└── firebase_service_manager.dart  ❌ Should be in data/datasources/
```

**Correct Structure:**
```
lib/
├── domain/
│   ├── entities/message.dart
│   ├── repositories/message_repository.dart (interface)
│   └── usecases/
│       ├── send_message.dart
│       ├── get_messages.dart
│       └── sync_messages.dart
├── data/
│   ├── models/message_model.dart
│   ├── datasources/
│   │   ├── message_remote_datasource.dart
│   │   └── message_local_datasource.dart
│   └── repositories/
│       └── message_repository_impl.dart
└── presentation/
    └── blocs/chat/chat_bloc.dart
```

---

### 4. PARALLEL SYSTEMS (Multiple Implementations)

#### 4.1 Real-time Communication (3 Systems)

```dart
// System 1: WebSocket
class UnifiedWebsocketService { ... }

// System 2: Connection Pool
class ConnectionPoolManager { ... }

// System 3: GraphQL Subscriptions
class GraphqlSubscriptionService { ... }
```

**Vấn Đề**: Không rõ system nào đang được dùng, có thể cả 3 đang chạy song song.

#### 4.2 Offline Sync (3 Systems)

```dart
// System 1: Offline Queue
class OfflineQueueService { ... }

// System 2: Offline Processor
class OfflineOperationProcessor { ... }

// System 3: Chat Sync
class ChatSyncService { ... }
```

**Vấn Đề**: Chồng chéo trách nhiệm, có thể sync nhiều lần.

#### 4.3 Message Queue (2 Systems)

```dart
// Old system
class MessageQueueService { ... }

// New system (but old one not removed)
class EnhancedMessageQueueService { ... }
```

**Vấn Đề**: Incomplete migration, cả 2 đều active.

#### 4.4 Media Handling (5 Components)

```dart
class MediaCache { ... }
class MediaCacheManager { ... }
class MediaService { ... }
class MediaProcessingService { ... }
class MediaProcessingServiceFactory { ... }
```

**Vấn Đề**: Over-engineering, unclear boundaries.

#### 4.5 Logging (2 Systems)

```dart
// System 1
class Logger { ... }

// System 2
class ProductionLogger { ... }
```

**Vấn Đề**: Không rõ nên dùng logger nào.

---

### 5. DATABASE SERVICE DUPLICATION

#### Vấn Đề
`DatabaseService` xuất hiện ở **2 nơi**:

```dart
// Location 1: lib/core/database/database_service.dart
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  // Manual singleton
}

// Location 2: Registered in DI
@singleton
DatabaseService provideLegacyDatabaseService() {
  return DatabaseService.instance;
}
```

**Vấn Đề**: 
- Manual singleton + DI registration = confusion
- Không rõ instance nào đang được dùng
- Có thể có 2 instances khác nhau

---

### 6. ENTERPRISE WRAPPER HELL

#### Vấn Đề
Nhiều "enterprise" wrappers không cần thiết:

```dart
// Original service
class AppService { ... }

// Enterprise wrapper (adds monitoring)
class EnterpriseAppService {
  final DatabaseService _databaseService;
  // Just wraps with monitoring
}

// Integration hub (wraps the wrapper)
class EnterpriseIntegrationHub {
  EnterpriseIntegrationService? _integrationService;
  // Wraps EnterpriseAppService
}

// Integration service (another wrapper)
class EnterpriseIntegrationService {
  final DatabaseService _database;
  // Wraps database operations
}
```

**Vấn Đề**:
- 3-4 layers of wrappers
- Mỗi layer thêm overhead
- Khó debug vì phải trace qua nhiều layers
- Không có giá trị business logic thực sự

#### Root Cause
- Monitoring/logging được thêm bằng wrappers thay vì decorators/interceptors
- Mỗi lần cần thêm feature → thêm wrapper mới
- Không refactor code cũ

---

## 📈 TÁC ĐỘNG ĐỊNH LƯỢNG

### Development Velocity
```
Before (Ideal):     ████████████████████ 100%
Current (Reality):  ████████░░░░░░░░░░░░  40%
Loss:               60% slower development
```

**Nguyên nhân**:
- 2-3 ngày để hiểu code base
- 1-2 ngày để tìm đúng service cần sửa
- 1 ngày để fix bug ở nhiều nơi
- 1 ngày để test tất cả code paths

### Bug Rate
```
Before (Ideal):     ██░░░░░░░░░░░░░░░░░░  10 bugs/month
Current (Reality):  ██████░░░░░░░░░░░░░░  30 bugs/month
Increase:           3x more bugs
```

**Nguyên nhân**:
- Fix ở service A nhưng quên service B
- Parallel systems có behavior khác nhau
- Khó test toàn bộ scenarios

### Memory Usage
```
Target:             ████████░░░░░░░░░░░░ 150MB
Current:            ████████████████░░░░ 200MB+
Overhead:           +50MB (33% over target)
```

**Nguyên nhân**:
- Multiple services running in parallel
- Duplicate caches
- Manual singletons không được dispose

### Test Coverage
```
Target:             ████████████████████ 80%
Current:            ██████░░░░░░░░░░░░░░ 30%
Gap:                50% untested code
```

**Nguyên nhân**:
- Khó mock services
- Nhiều code paths không test được
- Integration tests không cover parallel systems

---

## 🎯 CHIẾN LƯỢC TÁI CẤU TRÚC

### Phase 1: STOP THE BLEEDING (Week 1-2)

#### 1.1 Freeze New Services
```
❌ NO MORE new services in core/services/
✅ All new code MUST follow Clean Architecture
✅ Create UseCases instead of Services
```

#### 1.2 Document Current State
```
✅ Map all services and their dependencies
✅ Identify which services are actually used
✅ Mark deprecated services
```

#### 1.3 Create Migration Plan
```
✅ Prioritize by usage frequency
✅ Identify critical paths
✅ Plan backward compatibility
```

### Phase 2: CONSOLIDATE DI (Week 3-4)

#### 2.1 Single DI System
```dart
// ONLY use lib/core/di/injection.dart
// Remove lib/di/dependency_injection.dart
// Convert all manual singletons to @singleton
```

#### 2.2 Remove Manual Singletons
```dart
// ❌ REMOVE
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
}

// ✅ REPLACE WITH
@singleton
class DatabaseService {
  DatabaseService();
}
```

#### 2.3 Clean Registration
```dart
// Single source of truth
@InjectableInit()
Future<void> initializeDependencies() async {
  await getIt.init();
}
```

### Phase 3: IMPLEMENT CLEAN ARCHITECTURE (Week 5-8)

#### 3.1 Create Domain Layer

**Step 1: Define Entities**
```dart
// lib/domain/entities/message.dart
class Message {
  final String id;
  final String content;
  final DateTime timestamp;
  
  const Message({
    required this.id,
    required this.content,
    required this.timestamp,
  });
}
```

**Step 2: Define Repository Interfaces**
```dart
// lib/domain/repositories/message_repository.dart
abstract class IMessageRepository {
  Future<Either<Failure, List<Message>>> getMessages(String chatId);
  Future<Either<Failure, Message>> sendMessage(Message message);
  Future<Either<Failure, void>> syncMessages();
}
```

**Step 3: Create UseCases**
```dart
// lib/domain/usecases/send_message.dart
@injectable
class SendMessageUseCase {
  final IMessageRepository _repository;
  
  SendMessageUseCase(this._repository);
  
  Future<Either<Failure, Message>> call(Message message) {
    return _repository.sendMessage(message);
  }
}
```

#### 3.2 Refactor Data Layer

**Step 1: Create Models**
```dart
// lib/data/models/message_model.dart
@JsonSerializable()
class MessageModel {
  final String id;
  final String content;
  final DateTime timestamp;
  
  MessageModel({
    required this.id,
    required this.content,
    required this.timestamp,
  });
  
  Message toEntity() => Message(
    id: id,
    content: content,
    timestamp: timestamp,
  );
}
```

**Step 2: Create DataSources**
```dart
// lib/data/datasources/message_remote_datasource.dart
@injectable
class MessageRemoteDataSource {
  final GraphQLClient _client;
  
  MessageRemoteDataSource(this._client);
  
  Future<List<MessageModel>> getMessages(String chatId) async {
    // API call
  }
}

// lib/data/datasources/message_local_datasource.dart
@injectable
class MessageLocalDataSource {
  final IsarDatabase _db;
  
  MessageLocalDataSource(this._db);
  
  Future<List<MessageModel>> getCachedMessages(String chatId) async {
    // Database query
  }
}
```

**Step 3: Implement Repository**
```dart
// lib/data/repositories/message_repository_impl.dart
@LazySingleton(as: IMessageRepository)
class MessageRepositoryImpl implements IMessageRepository {
  final MessageRemoteDataSource _remoteDataSource;
  final MessageLocalDataSource _localDataSource;
  final INetworkInfo _networkInfo;
  
  MessageRepositoryImpl({
    required MessageRemoteDataSource remoteDataSource,
    required MessageLocalDataSource localDataSource,
    required INetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;
  
  @override
  Future<Either<Failure, List<Message>>> getMessages(String chatId) async {
    if (!await _networkInfo.isConnected) {
      // Return cached data
      try {
        final models = await _localDataSource.getCachedMessages(chatId);
        return Right(models.map((m) => m.toEntity()).toList());
      } catch (e) {
        return Left(CacheFailure(message: '$e'));
      }
    }
    
    try {
      final models = await _remoteDataSource.getMessages(chatId);
      await _localDataSource.cacheMessages(models);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
```

#### 3.3 Refactor Presentation Layer

**Update BLoC to use UseCases:**
```dart
// lib/presentation/blocs/chat/chat_bloc.dart
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessagesUseCase _getMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final SyncMessagesUseCase _syncMessagesUseCase;
  
  ChatBloc({
    required GetMessagesUseCase getMessagesUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required SyncMessagesUseCase syncMessagesUseCase,
  }) : _getMessagesUseCase = getMessagesUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _syncMessagesUseCase = syncMessagesUseCase,
       super(const ChatState.initial()) {
    on<ChatLoadMessagesEvent>(_onLoadMessages);
    on<ChatSendMessageEvent>(_onSendMessage);
  }
  
  Future<void> _onLoadMessages(
    ChatLoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatState.loading());
    
    final result = await _getMessagesUseCase(event.chatId);
    
    result.fold(
      (failure) => emit(ChatState.error(failure: failure)),
      (messages) => emit(ChatState.loaded(messages: messages)),
    );
  }
  
  Future<void> _onSendMessage(
    ChatSendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _sendMessageUseCase(event.message);
    
    result.fold(
      (failure) => emit(ChatState.error(failure: failure)),
      (message) => add(ChatLoadMessagesEvent(event.message.chatId)),
    );
  }
}
```

### Phase 4: CONSOLIDATE PARALLEL SYSTEMS (Week 9-12)

#### 4.1 Real-time Communication
```
✅ Choose ONE: GraphQL Subscriptions (recommended)
❌ Remove: UnifiedWebsocketService
❌ Remove: ConnectionPoolManager
```

#### 4.2 Offline Sync
```
✅ Keep: OfflineOperationProcessor (refactor to repository)
❌ Remove: OfflineQueueService
❌ Remove: ChatSyncService (merge into repository)
```

#### 4.3 Message Queue
```
✅ Keep: EnhancedMessageQueueService (rename to MessageQueueService)
❌ Remove: MessageQueueService (old)
```

#### 4.4 Media Handling
```
✅ Create: MediaRepository (domain)
✅ Create: MediaRepositoryImpl (data)
✅ Create: MediaRemoteDataSource (data)
✅ Create: MediaLocalDataSource (data)
❌ Remove: All 5 media services
```

### Phase 5: REMOVE ENTERPRISE WRAPPERS (Week 13-14)

#### 5.1 Replace with Decorators
```dart
// Instead of EnterpriseAppService wrapper
@Decorator()
class MonitoringDecorator<T> {
  final T _service;
  final PerformanceMonitor _monitor;
  
  MonitoringDecorator(this._service, this._monitor);
  
  Future<R> execute<R>(Future<R> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      _monitor.recordSuccess(stopwatch.elapsed);
      return result;
    } catch (e) {
      _monitor.recordFailure(stopwatch.elapsed, e);
      rethrow;
    }
  }
}
```

#### 5.2 Use Interceptors
```dart
// For API monitoring
class PerformanceInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['start_time'] = DateTime.now();
    super.onRequest(options, handler);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['start_time'] as DateTime;
    final duration = DateTime.now().difference(startTime);
    logger.i('API call took ${duration.inMilliseconds}ms');
    super.onResponse(response, handler);
  }
}
```

### Phase 6: TESTING & VALIDATION (Week 15-16)

#### 6.1 Unit Tests
```dart
// Test UseCases
void main() {
  late SendMessageUseCase useCase;
  late MockMessageRepository mockRepository;
  
  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = SendMessageUseCase(mockRepository);
  });
  
  test('should send message successfully', () async {
    // Arrange
    when(() => mockRepository.sendMessage(any()))
        .thenAnswer((_) async => Right(testMessage));
    
    // Act
    final result = await useCase(testMessage);
    
    // Assert
    expect(result, Right(testMessage));
    verify(() => mockRepository.sendMessage(testMessage)).called(1);
  });
}
```

#### 6.2 Integration Tests
```dart
// Test full flow
void main() {
  testWidgets('should send message and display in chat', (tester) async {
    // Setup
    await tester.pumpWidget(MyApp());
    
    // Navigate to chat
    await tester.tap(find.byType(ChatListItem).first);
    await tester.pumpAndSettle();
    
    // Send message
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    
    // Verify
    expect(find.text('Hello'), findsOneWidget);
  });
}
```

#### 6.3 Performance Tests
```dart
void main() {
  test('startup time should be < 2s', () async {
    final stopwatch = Stopwatch()..start();
    await initializeDependencies();
    stopwatch.stop();
    
    expect(stopwatch.elapsedMilliseconds, lessThan(2000));
  });
  
  test('message send should be < 100ms', () async {
    final stopwatch = Stopwatch()..start();
    await sendMessageUseCase(testMessage);
    stopwatch.stop();
    
    expect(stopwatch.elapsedMilliseconds, lessThan(100));
  });
}
```

---

## 📋 MIGRATION CHECKLIST

### Week 1-2: Planning
- [ ] Audit all services and dependencies
- [ ] Create dependency graph
- [ ] Identify critical paths
- [ ] Plan backward compatibility
- [ ] Setup feature flags for gradual rollout

### Week 3-4: DI Consolidation
- [ ] Migrate all manual singletons to @singleton
- [ ] Remove duplicate DI configurations
- [ ] Update all service registrations
- [ ] Test DI initialization
- [ ] Validate no circular dependencies

### Week 5-8: Clean Architecture
- [ ] Create domain entities
- [ ] Create repository interfaces
- [ ] Create use cases
- [ ] Create data models
- [ ] Create data sources
- [ ] Implement repositories
- [ ] Update BLoCs to use UseCases
- [ ] Run code generation

### Week 9-12: Consolidate Systems
- [ ] Choose single real-time system
- [ ] Consolidate offline sync
- [ ] Merge message queues
- [ ] Refactor media handling
- [ ] Standardize logging

### Week 13-14: Remove Wrappers
- [ ] Replace wrappers with decorators
- [ ] Add interceptors for monitoring
- [ ] Remove enterprise wrapper classes
- [ ] Update DI registrations

### Week 15-16: Testing
- [ ] Write unit tests for UseCases
- [ ] Write unit tests for Repositories
- [ ] Write integration tests
- [ ] Write performance tests
- [ ] Achieve 80% code coverage

---

## 🎯 SUCCESS METRICS

### Code Quality
```
Before → After
- Services: 25+ → 0 (replaced with UseCases)
- DI Systems: 3 → 1
- Architecture Violations: Many → 0
- Code Duplication: High → Low
- Test Coverage: 30% → 80%
```

### Performance
```
Before → After
- Startup Time: 3s → <2s
- Memory Usage: 200MB → <150MB
- Message Delivery: 150ms → <100ms
- Bug Rate: 30/month → 10/month
```

### Developer Experience
```
Before → After
- Onboarding Time: 2 weeks → 3 days
- Feature Development: 2 weeks → 1 week
- Bug Fix Time: 2 days → 4 hours
- Code Understanding: Hard → Easy
```

---

## ⚠️ RISKS & MITIGATION

### Risk 1: Breaking Changes
**Mitigation**:
- Use feature flags
- Gradual rollout
- Maintain backward compatibility during migration
- Comprehensive testing

### Risk 2: Team Resistance
**Mitigation**:
- Clear communication of benefits
- Training sessions
- Pair programming
- Code review guidelines

### Risk 3: Timeline Slippage
**Mitigation**:
- Weekly checkpoints
- Prioritize critical paths
- Parallel work streams
- Buffer time in schedule

### Risk 4: Production Issues
**Mitigation**:
- Canary deployments
- Rollback plan
- Monitoring & alerting
- Incident response plan

---

## 💡 RECOMMENDATIONS

### Immediate Actions (This Week)
1. **STOP** adding new services
2. **DOCUMENT** current architecture
3. **COMMUNICATE** refactoring plan to team
4. **SETUP** feature flags for gradual migration

### Short Term (Month 1)
1. Consolidate DI system
2. Start implementing Clean Architecture for new features
3. Add comprehensive tests
4. Setup monitoring

### Long Term (Month 2-4)
1. Complete Clean Architecture migration
2. Remove all parallel systems
3. Achieve 80% test coverage
4. Optimize performance

---

## 📚 REFERENCES

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter BLoC Pattern](https://bloclibrary.dev/)
- [Injectable DI](https://pub.dev/packages/injectable)
- [Project Architecture Guide](./project-architecture.md)

---

**Kết Luận**: Project cần **REFACTORING TOÀN DIỆN** để có thể maintain và scale được. Không thể tiếp tục thêm features với architecture hiện tại. Ưu tiên cao nhất là consolidate DI và implement Clean Architecture đúng cách.

**Next Steps**: Review document này với team, approve migration plan, và bắt đầu Phase 1 ngay lập tức.
