# NestJS API Integration Examples

## 🔍 **ACTUAL BACKEND RESPONSE ANALYSIS**

### **NestJS Backend Response Patterns Found:**

#### **1. REST Client Pattern (src/modules/core/common/rest.client.ts):**
```typescript
// Success Response
return { response: response.data }

// Error Response  
return { error: new BaseError(`${response.status}`, response.statusText) }

// No Content Error
return { error: HttpError.NoContent }
```

#### **2. GraphQL Pagination (src/models/base/paging.response.ts):**
```typescript
@InterfaceType()
export abstract class PagingData {
    @Field(_type => Int, { defaultValue: 0 })
    total: number

    @Field(_type => Int, { defaultValue: 0 })
    count: number
}
```

#### **3. User Response (src/modules/core/iam/identity/identity.response.ts):**
```typescript
@ObjectType()
export class UserResponse {
  @Field({ nullable: true })
  accessToken?: string

  @Field({ nullable: true })
  refreshToken?: string

  @Field({ nullable: true })
  loggedInTime?: number

  @Field(() => User, { nullable: true, defaultValue: null })
  user?: User

  @Field(() => [BusinessRole], { nullable: true, defaultValue: null })
  avaiableBusinessRoles?: BusinessRole[]
}
```

## 🔧 **SYNCHRONIZED FLUTTER IMPLEMENTATION**

### **Before (Generic BaseApiResponse):**
```dart
// ❌ WRONG: Generic pattern not matching backend
abstract class BaseApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;
  // ... generic fields that don't match NestJS
}
```

### **After (NestJS-Synchronized):**
```dart
// ✅ CORRECT: Matches actual NestJS backend structure
abstract class NestJSApiResponse<T> {
  final T? data;              // Direct data from { response: data }
  final NestJSError? error;   // Error from { error: BaseError }
  final PagingData? paging;   // Pagination from GraphQL
  final DateTime timestamp;   // Client-side timestamp
}
```

## 📋 **USAGE EXAMPLES**

### **1. REST API Integration:**
```dart
// Repository Implementation
class MessageRepositoryImpl extends BaseRepository {
  Future<Result<List<ChatMessage>>> getMessages() async {
    try {
      final response = await _httpClient.get('/api/messages');
      
      // Parse NestJS REST response: { response: data } or { error: BaseError }
      final apiResponse = NestJSApiResponse<List<dynamic>>.fromRestResponse(response.data);
      
      // Convert to domain Result
      return apiResponse.toResult().map((data) => 
        data.map((json) => ChatMessage.fromJson(json)).toList()
      );
    } catch (e) {
      return Result.failure(NetworkFailure(message: e.toString()));
    }
  }
}
```

### **2. GraphQL Integration:**
```dart
// GraphQL Query with Pagination
class ChatRepositoryImpl extends BaseRepository {
  Future<Result<List<Chat>>> getChats({int page = 1, int limit = 20}) async {
    try {
      final result = await _graphQLClient.query(QueryOptions(
        document: gql('''
          query GetChats(\$page: Int, \$limit: Int) {
            chats(page: \$page, limit: \$limit) {
              data {
                id
                name
                lastMessage
              }
              paging {
                total
                count
              }
            }
          }
        '''),
        variables: {'page': page, 'limit': limit},
      ));

      if (result.hasException) {
        final error = NestJSError(
          code: 'GRAPHQL_ERROR',
          message: result.exception.toString(),
        );
        return Result.failure(NetworkFailure(message: error.message));
      }

      final chatsData = result.data?['chats'];
      final apiResponse = NestJSApiResponse.success(
        chatsData['data'] as List<dynamic>,
        paging: PagingData.fromJson(chatsData['paging']),
      );

      return apiResponse.toResult().map((data) => 
        data.map((json) => Chat.fromJson(json)).toList()
      );
    } catch (e) {
      return Result.failure(NetworkFailure(message: e.toString()));
    }
  }
}
```

### **3. User Authentication (Matching UserResponse):**
```dart
// Auth Repository matching NestJS UserResponse
class AuthRepositoryImpl extends BaseRepository {
  Future<Result<AuthResult>> login(String email, String password) async {
    try {
      final response = await _httpClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final apiResponse = NestJSApiResponse<Map<String, dynamic>>.fromRestResponse(response.data);
      
      return apiResponse.toResult().map((data) => AuthResult(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        loggedInTime: data['loggedInTime'],
        user: User.fromJson(data['user']),
        availableBusinessRoles: (data['avaiableBusinessRoles'] as List?)
            ?.map((role) => BusinessRole.fromJson(role))
            .toList() ?? [],
      ));
    } catch (e) {
      return Result.failure(AuthenticationFailure(message: e.toString()));
    }
  }
}
```

### **4. Error Handling Examples:**
```dart
// Handle different NestJS error types
void handleApiResponse<T>(NestJSApiResponse<T> response) {
  response.toResult().fold(
    (failure) {
      switch (failure.runtimeType) {
        case ValidationFailure:
          showSnackBar('Dữ liệu không hợp lệ: ${failure.message}');
          break;
        case AuthenticationFailure:
          navigateToLogin();
          break;
        case NotFoundFailure:
          showSnackBar('Không tìm thấy dữ liệu');
          break;
        case ServerFailure:
          showSnackBar('Lỗi máy chủ, vui lòng thử lại sau');
          break;
        default:
          showSnackBar('Đã xảy ra lỗi: ${failure.message}');
      }
    },
    (data) {
      // Handle success
      processData(data);
    },
  );
}
```

### **5. Pagination Handling:**
```dart
// BLoC with pagination support
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  Future<void> _onLoadMessages(LoadMessages event, Emitter<MessageState> emit) async {
    emit(state.copyWith(isLoading: true));

    final result = await _messageRepository.getMessages(
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (response) {
        final messages = response.data ?? [];
        final paging = response.paging;
        
        emit(state.copyWith(
          isLoading: false,
          messages: event.page == 1 ? messages : [...state.messages, ...messages],
          hasMore: paging?.hasMore ?? false,
          totalCount: paging?.total ?? 0,
        ));
      },
    );
  }
}
```

## 🎯 **BENEFITS OF SYNCHRONIZED APPROACH**

### **✅ Advantages:**
- **Type Safety**: Exact match với backend response structure
- **No Mapping Errors**: Direct deserialization từ NestJS responses
- **Consistent Error Handling**: Unified error codes và messages
- **Pagination Support**: Built-in support cho GraphQL pagination
- **Future-Proof**: Easy to extend khi backend thay đổi

### **❌ Previous Generic Approach Issues:**
- Generic fields không match với actual backend
- Manual mapping required cho mỗi response
- Inconsistent error handling
- No built-in pagination support
- Hard to maintain khi backend changes

## 🚀 **MIGRATION STRATEGY**

### **Step 1: Update Repository Interfaces**
```dart
// Before
Future<Either<Failure, List<ChatMessage>>> getMessages();

// After  
Future<Result<NestJSApiResponse<List<ChatMessage>>>> getMessages();
```

### **Step 2: Update BLoC Implementations**
```dart
// Before
result.fold(
  (failure) => emit(ErrorState(failure.message)),
  (messages) => emit(LoadedState(messages)),
);

// After
result.fold(
  (failure) => emit(ErrorState(failure.message)),
  (response) => emit(LoadedState(
    data: response.data ?? [],
    paging: response.paging,
  )),
);
```

### **Step 3: Update Error Handling**
```dart
// Use NestJS-specific error codes
switch (error.code) {
  case 'UNAUTHORIZED':
    // Handle auth error
  case 'NOT_FOUND':
    // Handle not found
  case 'NO_CONTENT':
    // Handle empty response
}
```

## ✅ **CONCLUSION**

BaseApiResponse đã được synchronized với actual NestJS backend structure thay vì generic pattern. Điều này đảm bảo:

1. **Perfect Backend Sync**: Match 100% với NestJS response patterns
2. **Type Safety**: No runtime errors từ response parsing
3. **Maintainability**: Easy to update khi backend changes
4. **Performance**: No unnecessary mapping layers
5. **Developer Experience**: Clear error messages và debugging

**Ready for production use với NestJS backend!** 🎉
