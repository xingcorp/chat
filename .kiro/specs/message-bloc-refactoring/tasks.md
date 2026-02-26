# Implementation Plan: MessageBloc Refactoring

## Tổng quan

Refactoring nội bộ MessageBloc và các thành phần liên quan để tuân thủ mandatory patterns của dự án. Thứ tự thực hiện: State (@freezed) → BLoC (BaseBloc) → Event (thêm LoadConversationDetail) → ChatDetailsPage (cleanup) → DI → Code generation. Không thay đổi business logic hay UX.

## Tasks

- [x] 1. Migrate MessageState sang @freezed + BaseState
  - [x] 1.1 Chuyển đổi MessageState từ Equatable sang @freezed extends BaseState
    - Thay thế file `flutter_chat_app/lib/presentation/blocs/message/message_state.dart`
    - Chuyển từ `part of` sang file độc lập hoặc giữ `part of` pattern (consistent với codebase)
    - Định nghĩa `@freezed class MessageState extends BaseState with _$MessageState`
    - Thêm `const MessageState._()` private constructor cho custom methods
    - Factory constructors: `MessageState.initial()`, `MessageState.loading({required String chatId})`, `MessageState.loaded({...})`, `MessageState.error({...})`
    - `MessageState.loaded()` giữ nguyên tất cả fields hiện tại + thêm `Chat? conversationDetail`
    - `MessageState.error()` giữ nguyên fields: chatId, error, previousMessages
    - Giữ nguyên `MessageDataSource` enum không thay đổi
    - Import `BaseState` từ `presentation/blocs/base/base_state.dart`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [ ]* 1.2 Write property test — Property 3: Freezed state field preservation round-trip
    - **Property 3: Freezed state field preservation round-trip**
    - Generate random field values cho MessageState.loaded() và MessageState.error(), construct state rồi đọc lại từng field, verify tất cả giá trị bằng đầu vào
    - **Validates: Requirements 3.3, 3.4, 3.5**

- [x] 2. Migrate MessageBloc sang BaseBloc
  - [x] 2.1 Chuyển MessageBloc từ `Bloc + BlocErrorMixin` sang `BaseBloc`
    - Sửa file `flutter_chat_app/lib/presentation/blocs/message/message_bloc.dart`
    - Thay `extends Bloc<MessageEvent, MessageState> with BlocErrorMixin` → `extends BaseBloc<MessageEvent, MessageState>`
    - Loại bỏ `import 'package:bloc/bloc.dart'` và `import bloc_error_mixin.dart`
    - Thêm `import 'package:flutter_chat_app/presentation/blocs/base/base_bloc.dart'`
    - Thay initial state: `super(const MessageInitial())` → `super(const MessageState.initial())`
    - Giữ `@override final AppLogger logger` để override BaseBloc's logger
    - Giữ nguyên tất cả event handler registrations trong constructor
    - Giữ nguyên `_messageSubscriptions` map và cleanup logic riêng
    - Override `close()`: cancel `_backgroundFetchOperation`, `_messageSubscriptions`, rồi gọi `super.close()`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [x] 2.2 Cập nhật type checks trong MessageBloc cho tương thích freezed
    - Cập nhật tất cả `state is MessagesLoaded` → giữ nguyên (freezed generate concrete classes, `is` check vẫn hoạt động)
    - Cập nhật tất cả `MessagesLoaded(...)` constructor calls → `MessageState.loaded(...)`
    - Cập nhật tất cả `MessagesLoading(...)` → `MessageState.loading(...)`
    - Cập nhật tất cả `MessagesError(...)` → `MessageState.error(...)`
    - Cập nhật tất cả `MessageInitial()` → `MessageState.initial()`
    - Cập nhật `copyWith` calls (freezed auto-generates copyWith, syntax giữ nguyên)
    - _Requirements: 2.8, 3.7_

  - [ ]* 2.3 Write property test — Property 7: Tất cả event handlers được bảo toàn sau migration
    - **Property 7: Tất cả event handlers được bảo toàn sau migration**
    - Iterate tất cả event types (LoadMessages, LoadMoreMessages, SendMessage, EditMessage, DeleteMessage, MarkChatAsRead, ReceiveRealTimeMessage, RefreshMessages, ClearMessages, ToggleReaction, SendMessageWithAttachments, SendLocationMessage, AppResumed, ReceiveMessageEdited, ReceiveMessageDeleted, ReceiveMessageReaction), verify handler registered và không throw unhandled event error
    - **Validates: Requirements 2.4**

- [x] 3. Checkpoint — Verify MessageBloc compiles và state migration đúng
  - Chạy `dart run build_runner build --delete-conflicting-outputs` để generate freezed code
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Thêm LoadConversationDetail event và handler vào MessageBloc
  - [x] 4.1 Thêm event LoadConversationDetail vào message_event.dart
    - Thêm class `LoadConversationDetail extends MessageEvent` với field `chatId: String`
    - Override `props` trả về `[chatId]`
    - _Requirements: 1.1_

  - [x] 4.2 Thêm GetConversationDetailUseCase dependency và handler vào MessageBloc
    - Thêm field `final GetConversationDetailUseCase _getConversationDetail` vào MessageBloc
    - Thêm `required GetConversationDetailUseCase getConversationDetail` vào constructor
    - Đăng ký handler `on<LoadConversationDetail>(_onLoadConversationDetail)` trong constructor
    - Implement `_onLoadConversationDetail`: gọi UseCase, nếu thành công và state là MessagesLoaded thì `emit(currentState.copyWith(conversationDetail: chat))`, nếu lỗi thì chỉ log không emit error state
    - _Requirements: 1.1, 1.3, 1.4_

  - [ ]* 4.3 Write property test — Property 1: LoadConversationDetail trả về Chat entity trong state
    - **Property 1: LoadConversationDetail trả về Chat entity trong state**
    - Generate random chatIds, mock UseCase success, verify state là MessagesLoaded với conversationDetail chứa Chat entity tương ứng
    - **Validates: Requirements 1.1, 1.3**

  - [ ]* 4.4 Write property test — Property 2: Conversation detail error không phá vỡ message state
    - **Property 2: Conversation detail error không phá vỡ message state**
    - Generate random failures từ GetConversationDetailUseCase, verify MessagesLoaded state preserved với messages giữ nguyên
    - **Validates: Requirements 1.4**

- [x] 5. Cleanup ChatDetailsPage — loại bỏ direct UseCase calls
  - [x] 5.1 Loại bỏ GetConversationDetailUseCase và IChatRemoteDataSource khỏi ChatDetailsPage
    - Sửa file `flutter_chat_app/lib/features/chat/presentation/pages/chat/chat_details_page.dart`
    - Xóa `late final GetConversationDetailUseCase _getConversationDetail`
    - Xóa `_getConversationDetail = getIt<GetConversationDetailUseCase>()` trong initState
    - Xóa import `get_conversation_detail_usecase.dart`
    - Xóa method `_loadChatHeader()` gọi UseCase trực tiếp
    - _Requirements: 1.2, 1.6_

  - [x] 5.2 Dispatch LoadConversationDetail event từ ChatDetailsPage và đọc state
    - Thay `unawaited(_loadChatHeader())` bằng `_messageBloc.add(LoadConversationDetail(chatId: widget.chatId))`
    - Trong BlocConsumer listener: khi `state is MessagesLoaded && state.conversationDetail != null`, cập nhật `_chat`, mention context, và transform context (tương tự logic cũ trong `_loadChatHeader`)
    - Cập nhật `_refreshChatInfo()` để dispatch `LoadConversationDetail` thay vì gọi `_loadChatHeader()`
    - _Requirements: 1.1, 1.5_

  - [x] 5.3 Cập nhật tất cả state type checks trong ChatDetailsPage cho freezed
    - Cập nhật `state is MessagesLoaded` checks (giữ nguyên, vẫn hoạt động với freezed)
    - Cập nhật cách truy cập state fields nếu cần (freezed giữ nguyên field access syntax)
    - Verify tất cả BlocConsumer/BlocBuilder/BlocListener trong page hoạt động đúng
    - _Requirements: 3.8_

- [x] 6. Cập nhật DI registration và code generation
  - [x] 6.1 Cập nhật DI registration cho MessageBloc
    - Thêm `GetConversationDetailUseCase` vào constructor injection của MessageBloc trong DI config
    - Verify `@injectable` annotation trên MessageBloc vẫn đúng
    - Chạy `dart run build_runner build --delete-conflicting-outputs` để regenerate DI + freezed code
    - _Requirements: 1.3, 2.1_

- [x] 7. Checkpoint — Verify Two-Phase Render vẫn hoạt động sau refactoring
  - [ ]* 7.1 Write property test — Property 4: Two-Phase Render local data kèm background fetching flag
    - **Property 4: Two-Phase Render — local data kèm background fetching flag**
    - Generate random chatIds với local data, verify state emitted đầu tiên là MessagesLoaded với `dataSource == MessageDataSource.local` và `isBackgroundFetching == true`
    - **Validates: Requirements 4.1, 4.4**

  - [ ]* 7.2 Write property test — Property 5: Background fetch thành công → merged state
    - **Property 5: Background fetch thành công → merged state**
    - Generate random local + server message lists, verify state mới có `dataSource == MessageDataSource.merged` và `isBackgroundFetching == false`
    - **Validates: Requirements 4.5**

  - [ ]* 7.3 Write property test — Property 6: Background fetch thất bại → giữ nguyên local data
    - **Property 6: Background fetch thất bại → giữ nguyên local data**
    - Generate random failures during background fetch, verify local data preserved và `isBackgroundFetching == false`
    - **Validates: Requirements 4.6**

- [-] 8. Final checkpoint — Ensure all tests pass
  - Chạy `dart run build_runner build --delete-conflicting-outputs` lần cuối
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Thứ tự thực hiện quan trọng: State trước → BLoC → Event/Handler → Page cleanup → DI
- Freezed type checks (`state is MessagesLoaded`) vẫn hoạt động, không cần migrate sang `state.when()` trong BLoC
- `MessageDataSource` enum giữ nguyên, không thay đổi
- Tất cả business logic (Two-Phase Render, delta sync, socket buffering) phải giữ nguyên sau refactoring
- Property tests sử dụng `dart_check` library với minimum 100 iterations
