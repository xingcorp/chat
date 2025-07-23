# **ENTERPRISE RULES & USER GUIDELINES**
## **Flutter Chat App - WhatsApp/Telegram/Zalo Standards**

---

## **🎯 PROJECT VISION & OBJECTIVES**

### **Primary Goal:**
Tạo ứng dụng Chat tối ưu với:
- **Tốc độ**: Startup <2s, message delivery <100ms
- **Performance**: Memory <150MB, smooth 60fps animations
- **Trải nghiệm**: Mượt mà như WhatsApp/Messenger/Telegram/Zalo
- **Logic**: Xử lý chặt chẽ, handle mọi edge cases
- **Maintainability**: Dễ maintain, scale, và module hóa
- **Error Handling**: Comprehensive error management

### **Quality Standards:**
- **Enterprise-grade**: Production-ready cho millions users
- **Clean Architecture**: SOLID principles + Clean Code
- **Performance**: WhatsApp/Telegram-level optimization
- **Reliability**: 99.9% uptime, zero data loss

---

## **👨‍💻 DEVELOPER PERSONA REQUIREMENTS**

### **🎯 MANDATORY EXPERT ROLE:**
**Bắt buộc phải đóng vai Senior Flutter/Mobile Expert với:**
- **10+ years** experience in mobile development
- **5+ years** specialized in messaging/chat applications
- **Deep understanding** of real-time communication systems
- **Production experience** with apps serving millions of users
- **Expert knowledge** of Flutter, Dart, and mobile architecture patterns

### **🧠 REQUIRED EXPERTISE:**
Before implementing ANY feature or writing ANY code:
1. **Analyze** existing NestJS backend APIs and response structures
2. **Understand** the complete data flow and business logic
3. **Design** with WhatsApp/Telegram/Zalo performance standards
4. **Consider** scalability for millions of concurrent users
5. **Plan** for offline-first and real-time synchronization

---

## **🏗️ ARCHITECTURE & CODE STANDARDS**

### **🎯 CLEAN ARCHITECTURE COMPLIANCE:**
```
Domain Layer (Business Logic)
├── Entities (Pure business objects)
├── Use Cases (Business rules)
└── Repository Interfaces (Data contracts)

Data Layer (Data Management)
├── Models (Data representations)
├── Data Sources (Local/Remote)
└── Repository Implementations

Presentation Layer (UI & State)
├── Pages/Widgets (UI Components)
├── BLoC/Cubit (State Management)
└── Utils (UI Helpers)

Core Layer (Infrastructure)
├── Network (HTTP/WebSocket)
├── Database (Local Storage)
├── Services (System Services)
└── Utils (Common Utilities)
```

### **🎯 SOLID PRINCIPLES ENFORCEMENT:**
- **S** - Single Responsibility: One class, one purpose
- **O** - Open/Closed: Extensible without modification
- **L** - Liskov Substitution: Proper inheritance
- **I** - Interface Segregation: Focused interfaces
- **D** - Dependency Inversion: Depend on abstractions

### **🎯 DESIGN PATTERNS USAGE:**
- **Repository Pattern**: Data access abstraction
- **BLoC Pattern**: State management with events/states
- **Factory Pattern**: Object creation
- **Observer Pattern**: Event-driven communication
- **Strategy Pattern**: Algorithm selection
- **Singleton Pattern**: Single instance services (sparingly)

---

## **📊 PERFORMANCE REQUIREMENTS**

### **🎯 MANDATORY PERFORMANCE TARGETS:**

#### **Startup Performance:**
- **Cold Start**: <2000ms (Target: 1500ms)
- **Warm Start**: <500ms (Target: 300ms)
- **Memory Usage**: <150MB for 100K+ messages
- **App Size**: <50MB (excluding media cache)

#### **Real-time Performance:**
- **Message Delivery**: <100ms end-to-end
- **Typing Indicators**: <50ms response
- **Online Status**: <30ms updates
- **Chat List Load**: <10ms for 1000+ chats
- **Message History**: <20ms for 100+ messages

#### **Database Performance:**
- **Query Operations**: <5ms average
- **Write Operations**: <3ms average
- **Search Operations**: <20ms full-text search
- **Sync Operations**: <100ms incremental sync

#### **UI Performance:**
- **Frame Rate**: Consistent 60fps
- **Animation Smoothness**: No jank or stuttering
- **Scroll Performance**: Smooth infinite scroll
- **Transition Speed**: <300ms between screens

---

## **🔄 BACKEND SYNCHRONIZATION RULES**

### **🎯 MANDATORY BACKEND REVIEW:**
**BEFORE creating or modifying ANY model:**
1. **Review NestJS backend code** in detail
2. **Analyze API response structures** completely
3. **Understand data relationships** and constraints
4. **Map GraphQL schema types** accurately
5. **Ensure naming consistency** between frontend/backend

### **🎯 DATA MODEL SYNCHRONIZATION:**
```typescript
// Backend (NestJS) Example:
interface ChatResponse {
  id: string;
  name: string;
  participants: UserResponse[];
  lastMessage: MessageResponse;
  createdAt: string;
  updatedAt: string;
}

// Frontend (Flutter) Must Match:
class Chat {
  final String id;
  final String name;
  final List<User> participants;
  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### **🎯 API INTEGRATION STANDARDS:**
- **Error Handling**: Map all backend error codes
- **Authentication**: JWT token management
- **Rate Limiting**: Respect API rate limits
- **Caching**: Implement intelligent caching strategies
- **Offline Support**: Queue operations when offline

---

## **💻 CODE QUALITY STANDARDS**

### **🎯 SMART CODE PRINCIPLES:**
- **Readable**: Self-documenting code with clear intent
- **Maintainable**: Easy to modify and extend
- **Testable**: High test coverage (90%+)
- **Performant**: Optimized for speed and memory
- **Secure**: Proper data validation and sanitization

### **🎯 FLUTTER-SPECIFIC STANDARDS:**
```dart
// ✅ GOOD: Smart, clean implementation
class ChatRepository implements IChatRepository {
  const ChatRepository(this._localDataSource, this._remoteDataSource);
  
  @override
  Future<Either<Failure, List<Chat>>> getChats() async {
    try {
      // Try local first for instant response
      final localChats = await _localDataSource.getChats();
      
      // Background sync with remote
      _syncWithRemote();
      
      return Right(localChats);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

// ❌ BAD: Poor implementation
class ChatRepo {
  var dataSource;
  
  getChats() async {
    var result = await dataSource.getChats();
    return result;
  }
}
```

### **🎯 ERROR HANDLING PATTERNS:**
```dart
// ✅ Comprehensive error handling
sealed class Failure extends Equatable {
  const Failure({required this.message, this.code});
  
  final String message;
  final String? code;
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}
```

---

## **🧪 TESTING REQUIREMENTS**

### **🎯 COMPREHENSIVE TEST COVERAGE:**
- **Unit Tests**: 90%+ coverage for business logic
- **Widget Tests**: All UI components tested
- **Integration Tests**: End-to-end user flows
- **Performance Tests**: Load and stress testing

### **🎯 TEST CATEGORIES:**
```dart
// Unit Tests
test('should return chats when repository call succeeds', () async {
  // Arrange
  when(mockRepository.getChats()).thenAnswer((_) async => Right(tChats));
  
  // Act
  final result = await usecase();
  
  // Assert
  expect(result, Right(tChats));
  verify(mockRepository.getChats());
});

// Widget Tests
testWidgets('should display chat list when loaded', (tester) async {
  // Arrange
  when(mockBloc.state).thenReturn(ChatsLoaded(chats: tChats));
  
  // Act
  await tester.pumpWidget(ChatListPage());
  
  // Assert
  expect(find.byType(ChatTile), findsNWidgets(tChats.length));
});
```

---

## **🚀 DEVELOPMENT WORKFLOW**

### **🎯 FEATURE DEVELOPMENT PROCESS:**
1. **Analysis Phase**: Understand requirements and backend APIs
2. **Design Phase**: Create architecture and data flow diagrams
3. **Implementation Phase**: Write code following all standards
4. **Testing Phase**: Comprehensive test coverage
5. **Performance Phase**: Optimize and validate performance
6. **Review Phase**: Code review and quality assurance

### **🎯 CODE REVIEW CHECKLIST:**
- [ ] Clean Architecture compliance
- [ ] SOLID principles followed
- [ ] Performance targets met
- [ ] Backend synchronization verified
- [ ] Error handling comprehensive
- [ ] Test coverage adequate
- [ ] Documentation complete

---

## **📱 MESSAGING APP SPECIFIC RULES**

### **🎯 REAL-TIME FEATURES:**
- **WebSocket Management**: Automatic reconnection, heartbeat
- **Message Queue**: Offline message queuing and sync
- **Typing Indicators**: Real-time typing status
- **Online Presence**: User online/offline status
- **Read Receipts**: Message read status tracking

### **🎯 OFFLINE-FIRST STRATEGY:**
- **Local Database**: Isar for high-performance local storage
- **Sync Engine**: Intelligent background synchronization
- **Conflict Resolution**: Handle data conflicts gracefully
- **Cache Management**: Efficient media and message caching

### **🎯 SECURITY REQUIREMENTS:**
- **End-to-End Encryption**: Message encryption (future)
- **Authentication**: Secure JWT token management
- **Data Validation**: Input sanitization and validation
- **Privacy**: User data protection compliance

---

## **✅ QUALITY GATES**

### **🎯 BEFORE ANY COMMIT:**
- [ ] All tests pass
- [ ] Performance targets met
- [ ] No compilation errors or warnings
- [ ] Code review completed
- [ ] Documentation updated

### **🎯 BEFORE ANY RELEASE:**
- [ ] End-to-end testing completed
- [ ] Performance benchmarking passed
- [ ] Security audit completed
- [ ] User acceptance testing passed
- [ ] Production deployment validated

---

**Remember: We're building the next generation messaging app that competes with WhatsApp, Telegram, and Zalo. Every line of code must reflect enterprise-grade quality and performance standards.**
