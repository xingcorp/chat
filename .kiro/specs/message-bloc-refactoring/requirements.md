# Requirements Document — MessageBloc Refactoring

## Giới thiệu

Tài liệu yêu cầu cho việc refactoring MessageBloc (1497 dòng) và các thành phần liên quan trong Flutter chat app. Hiện tại MessageBloc vi phạm nhiều mandatory pattern của dự án: extends `Bloc` thay vì `BaseBloc`, MessageState extends `Equatable` thay vì `BaseState`, ChatDetailsPage gọi UseCase trực tiếp thay vì thông qua BLoC, và MessageInitial không load dữ liệu local. Các vấn đề này liên kết chặt chẽ với nhau và cần được refactor đồng bộ.

## Glossary

- **MessageBloc**: BLoC quản lý trạng thái tin nhắn trong chat, file `message_bloc.dart` (~1497 dòng)
- **MessageState**: Tập hợp các trạng thái của MessageBloc, hiện gồm `MessageInitial`, `MessagesLoading`, `MessagesLoaded`, `MessagesError`
- **MessageEvent**: Tập hợp các sự kiện mà MessageBloc xử lý (LoadMessages, SendMessage, EditMessage, v.v.)
- **BaseBloc**: Lớp cơ sở bắt buộc cho tất cả BLoC, cung cấp error handling tự động, performance monitoring, analytics, crash reporting
- **BaseState**: Lớp cơ sở bắt buộc cho tất cả state, extends `Equatable`, hỗ trợ `@freezed`
- **BlocErrorMixin**: Mixin cung cấp standardized error handling cho BLoC (handleEitherResult, getUserErrorMessage, v.v.)
- **ChatDetailsPage**: Trang chi tiết chat, file `chat_details_page.dart` (~1393 dòng)
- **GetConversationDetailUseCase**: UseCase lấy thông tin chi tiết conversation từ repository
- **ChatBloc**: BLoC quản lý danh sách conversation, đã có handler `_onLoadChatDetails` cho GetConversationDetailUseCase
- **Two-Phase Render**: Pattern hiện tại của MessageBloc: Phase 1 emit local data ngay lập tức, Phase 2 background fetch từ server rồi merge
- **Freezed**: Code generation library tạo immutable data class với union types, copyWith, pattern matching

## Requirements

### Requirement 1: Di chuyển GetConversationDetailUseCase từ ChatDetailsPage vào BLoC

**User Story:** Là một developer, tôi muốn ChatDetailsPage không gọi UseCase trực tiếp, để tuân thủ Clean Architecture (Presentation layer chỉ tương tác với BLoC, không gọi Domain layer trực tiếp).

#### Acceptance Criteria

1. WHEN ChatDetailsPage cần load thông tin conversation, THE ChatDetailsPage SHALL dispatch một event tới BLoC thay vì gọi GetConversationDetailUseCase trực tiếp
2. THE ChatDetailsPage SHALL loại bỏ import và field `GetConversationDetailUseCase` khỏi page code
3. WHEN BLoC nhận event load conversation detail, THE BLoC SHALL gọi GetConversationDetailUseCase và emit state chứa thông tin Chat entity
4. WHEN GetConversationDetailUseCase trả về lỗi, THE BLoC SHALL log lỗi và giữ nguyên state hiện tại mà không phá vỡ luồng tin nhắn
5. WHEN conversation detail được load thành công, THE ChatDetailsPage SHALL cập nhật UI header và mention context từ state của BLoC
6. THE ChatDetailsPage SHALL loại bỏ việc gọi trực tiếp `getIt<GetConversationDetailUseCase>()` và `getIt<IChatRemoteDataSource>()` trong page

### Requirement 2: Migrate MessageBloc từ Bloc sang BaseBloc

**User Story:** Là một developer, tôi muốn MessageBloc extends BaseBloc thay vì Bloc, để có được error handling tự động, performance monitoring, analytics tracking, và crash reporting mà BaseBloc cung cấp.

#### Acceptance Criteria

1. THE MessageBloc SHALL extend `BaseBloc<MessageEvent, MessageState>` thay vì `Bloc<MessageEvent, MessageState>`
2. THE MessageBloc SHALL loại bỏ `with BlocErrorMixin` vì BaseBloc đã tích hợp sẵn error handling
3. THE MessageBloc SHALL truyền initial state `const MessageInitial()` cho super constructor của BaseBloc
4. WHEN MessageBloc được khởi tạo, THE MessageBloc SHALL giữ nguyên tất cả event handler registrations hiện tại (on<LoadMessages>, on<SendMessage>, v.v.)
5. THE MessageBloc SHALL giữ nguyên tất cả stream subscriptions và cleanup logic trong method `close()`
6. WHEN một lỗi không mong đợi xảy ra trong event handler, THE BaseBloc SHALL tự động log lỗi, báo cáo crash, và tracking analytics
7. THE MessageBloc SHALL giữ nguyên field `logger` kiểu `AppLogger` và sử dụng nó cho logging thay vì logger mặc định của BaseBloc
8. WHEN refactoring hoàn tất, THE MessageBloc SHALL biên dịch thành công mà không có lỗi và giữ nguyên toàn bộ chức năng hiện tại

### Requirement 3: Migrate MessageState từ Equatable sang BaseState với @freezed

**User Story:** Là một developer, tôi muốn MessageState extends BaseState và sử dụng @freezed, để có immutable state, pattern matching (when/maybeWhen), tự động copyWith, và tuân thủ mandatory pattern của dự án.

#### Acceptance Criteria

1. THE MessageState SHALL extend `BaseState` thay vì `Equatable` trực tiếp
2. THE MessageState SHALL sử dụng annotation `@freezed` với mixin `_$MessageState` để generate code
3. THE MessageState SHALL định nghĩa các factory constructors: `MessageState.initial()`, `MessageState.loading()`, `MessageState.loaded()`, `MessageState.error()`
4. THE MessageState.loaded() SHALL giữ nguyên tất cả fields hiện tại: chatId, messages, uiMessages, hasReachedMax, paginationError, dataSource, isBackgroundFetching
5. THE MessageState.error() SHALL giữ nguyên fields: chatId, error, previousMessages
6. THE MessageDataSource enum SHALL được giữ nguyên và không thay đổi
7. WHEN MessageState được migrate, THE MessageBloc SHALL cập nhật tất cả type checks (`state is MessagesLoaded`) sang pattern matching tương thích với freezed
8. WHEN MessageState được migrate, tất cả consumers (ChatDetailsPage, widgets) SHALL cập nhật cách truy cập state cho phù hợp với freezed API
9. WHEN code generation chạy (`dart run build_runner build`), THE generated code SHALL biên dịch thành công mà không có lỗi

### Requirement 4: Load dữ liệu local khi MessageBloc khởi tạo

**User Story:** Là một user, tôi muốn thấy tin nhắn đã cache ngay khi mở chat, thay vì thấy màn hình trống (MessageInitial), để có trải nghiệm mượt mà hơn và hỗ trợ offline-first.

#### Acceptance Criteria

1. WHEN MessageBloc nhận event LoadMessages và có dữ liệu local, THE MessageBloc SHALL emit state loaded với dữ liệu local trong vòng 50ms (đã hoạt động qua Two-Phase Render)
2. WHEN MessageBloc nhận event LoadMessages và không có dữ liệu local, THE MessageBloc SHALL emit state loading rồi fetch từ server (đã hoạt động)
3. WHEN ChatDetailsPage mở một conversation, THE ChatDetailsPage SHALL dispatch LoadMessages event ngay trong initState (đã hoạt động)
4. WHILE dữ liệu local đang hiển thị, THE MessageBloc SHALL hiển thị indicator rằng đang background fetch dữ liệu mới từ server thông qua field `isBackgroundFetching` trong state
5. WHEN background fetch hoàn tất, THE MessageBloc SHALL merge dữ liệu local và server rồi emit state merged (đã hoạt động qua Two-Phase Render)
6. IF background fetch thất bại, THEN THE MessageBloc SHALL giữ nguyên dữ liệu local đang hiển thị và tắt indicator background fetching (đã hoạt động)
