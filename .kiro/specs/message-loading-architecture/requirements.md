# Requirements Document — Message Loading Architecture (Phase 2 + Phase 3)

## Giới thiệu

Tài liệu này mô tả yêu cầu chi tiết cho việc nâng cấp kiến trúc tải tin nhắn của ứng dụng chat Flutter, bao gồm hai giai đoạn:

- **Phase 2 — Two-Phase Render (Slack-like)**: Hiển thị tin nhắn local/cached ngay lập tức khi mở chat, đồng thời fetch từ server. Khi server trả về, merge/replace dữ liệu mới. Người dùng thấy nội dung tức thì (không loading spinner cho chat đã truy cập trước đó).
- **Phase 3 — Delta Sync (Hybrid)**: Sử dụng tham số `from` timestamp để chỉ fetch tin nhắn MỚI kể từ timestamp cuối cùng đã biết. Kết hợp với socket events cho real-time edits/deletes/reactions. Giảm bandwidth và tải server. Xử lý edge cases: missed socket events, app backgrounded, reconnection.

**Phạm vi**: Chỉ thay đổi phía client (Flutter). Backend đã hỗ trợ đầy đủ (`ChatMessageGetListFilter.from`, Socket.IO events, DynamoDB query với `createdAt >= from`).

**Phase 1 (đã hoàn thành)**: Initial load remote-first, load-more offline-first, real-time socket subscription per chat room.

## Glossary

- **MessageBloc**: BLoC quản lý state tin nhắn cho một cuộc hội thoại, xử lý load, send, edit, delete, real-time events
- **MessageRepository**: Repository implementation (extends BaseRepository) cung cấp các strategy: executeOnlineFirst, executeOfflineFirst, executeRemoteOnly
- **RealtimeService**: Service singleton quản lý kết nối Socket.IO, cung cấp các stream: messageStream, messageEditedStream, messageDeletedStream, messageReactionStream
- **CacheSyncStrategy**: Singleton quản lý dirty flags và cache invalidation cho chat messages, chat list, user data
- **AppCacheManager**: Manager quản lý cache với TTL (messageTtl = 30 ngày), hỗ trợ getApiResponse và cacheApiResponse
- **LocalDataSource**: Isar database datasource lưu trữ MessageModel offline
- **RemoteDataSource**: GraphQL datasource gọi API backend (messageList query với ChatMessageGetListFilter)
- **Two-Phase_Render**: Pattern hiển thị dữ liệu local ngay lập tức (phase 1), sau đó merge dữ liệu server khi có (phase 2), tạo trải nghiệm instant load
- **Delta_Sync**: Pattern chỉ fetch tin nhắn mới kể từ timestamp cuối cùng đã biết, thay vì fetch toàn bộ, giảm bandwidth và thời gian tải
- **LastKnownTimestamp**: Timestamp (millisecondsSinceEpoch) của tin nhắn mới nhất đã biết trong local storage cho một conversation
- **SyncMetadata**: Dữ liệu metadata lưu trữ trạng thái sync cho mỗi conversation: lastKnownTimestamp, lastSyncTime, syncVersion
- **MergeStrategy**: Thuật toán merge tin nhắn local với tin nhắn server, ưu tiên server data, deduplicate bằng message ID
- **StaleData**: Dữ liệu local đã cũ, cần được refresh từ server (xác định qua dirty flag hoặc TTL hết hạn)
- **GapDetection**: Cơ chế phát hiện khoảng trống trong dữ liệu tin nhắn (missed messages) giữa local và server

## Requirements

### Requirement 1: Two-Phase Render — Hiển thị tin nhắn local ngay lập tức

**User Story:** Là người dùng, tôi muốn thấy tin nhắn ngay lập tức khi mở một cuộc hội thoại đã truy cập trước đó, để không phải chờ loading spinner.

#### Acceptance Criteria

1. WHEN người dùng mở một cuộc hội thoại có dữ liệu local, THE MessageBloc SHALL emit state MessagesLoaded với tin nhắn từ local storage trong vòng 50ms
2. WHILE state MessagesLoaded đã được emit với dữ liệu local, THE MessageBloc SHALL đồng thời thực hiện fetch tin nhắn từ server (background fetch)
3. WHEN server trả về dữ liệu mới, THE MessageBloc SHALL merge tin nhắn server vào state hiện tại mà không làm mất scroll position của người dùng
4. WHEN cuộc hội thoại không có dữ liệu local (lần đầu truy cập), THE MessageBloc SHALL emit state MessagesLoading và fetch trực tiếp từ server (giữ nguyên behavior Phase 1)
5. IF fetch từ server thất bại trong quá trình background fetch, THEN THE MessageBloc SHALL giữ nguyên dữ liệu local đã hiển thị và log warning, không emit error state

### Requirement 2: Two-Phase Render — Merge Strategy

**User Story:** Là người dùng, tôi muốn dữ liệu tin nhắn luôn chính xác sau khi merge giữa local và server, để không thấy tin nhắn trùng lặp hoặc thiếu.

#### Acceptance Criteria

1. THE MergeStrategy SHALL deduplicate tin nhắn bằng message ID, ưu tiên dữ liệu từ server khi có conflict
2. WHEN server trả về tin nhắn đã bị xóa (có deletedAt), THE MergeStrategy SHALL loại bỏ tin nhắn đó khỏi danh sách hiển thị
3. WHEN server trả về tin nhắn đã được chỉnh sửa (editedAt khác local), THE MergeStrategy SHALL cập nhật nội dung tin nhắn với phiên bản server
4. WHEN server trả về tin nhắn mới chưa có trong local, THE MergeStrategy SHALL thêm tin nhắn mới vào đúng vị trí theo thứ tự createdAt
5. THE MergeStrategy SHALL bảo toàn tin nhắn đang ở trạng thái sending hoặc pending (chưa được server xác nhận) trong quá trình merge
6. WHEN merge hoàn tất, THE MessageBloc SHALL emit state MessagesLoaded mới với flag isFromServer = true để UI có thể phân biệt

### Requirement 3: Two-Phase Render — State Management

**User Story:** Là developer, tôi muốn state management rõ ràng cho two-phase render, để dễ debug và maintain.

#### Acceptance Criteria

1. THE MessagesLoaded state SHALL bao gồm field dataSource (enum: local, server, merged) để chỉ ra nguồn dữ liệu hiện tại
2. THE MessagesLoaded state SHALL bao gồm field isBackgroundFetching (bool) để UI biết đang có background fetch
3. WHEN background fetch đang chạy, THE MessageBloc SHALL emit state với isBackgroundFetching = true
4. WHEN background fetch hoàn tất (thành công hoặc thất bại), THE MessageBloc SHALL emit state với isBackgroundFetching = false
5. IF người dùng thực hiện action (send, edit, delete) trong khi background fetch đang chạy, THEN THE MessageBloc SHALL xử lý action trên state hiện tại và merge kết quả background fetch sau đó

### Requirement 4: Delta Sync — Fetch tin nhắn mới bằng timestamp

**User Story:** Là người dùng, tôi muốn ứng dụng chỉ tải tin nhắn mới kể từ lần truy cập cuối, để tiết kiệm bandwidth và tải nhanh hơn.

#### Acceptance Criteria

1. THE SyncMetadata SHALL lưu trữ lastKnownTimestamp cho mỗi conversation trong local storage (Isar hoặc SharedPreferences)
2. WHEN MessageBloc thực hiện initial load cho conversation có lastKnownTimestamp, THE MessageRepository SHALL gửi request với tham số `from` = lastKnownTimestamp đến server
3. WHEN server trả về tin nhắn delta (từ timestamp), THE MessageRepository SHALL merge tin nhắn mới với tin nhắn local hiện có
4. WHEN delta sync thành công, THE SyncMetadata SHALL cập nhật lastKnownTimestamp bằng createdAt của tin nhắn mới nhất từ server
5. IF lastKnownTimestamp không tồn tại (conversation mới hoặc cache bị xóa), THEN THE MessageRepository SHALL thực hiện full load (không có tham số `from`)

### Requirement 5: Delta Sync — Kết hợp Socket Events

**User Story:** Là người dùng, tôi muốn tin nhắn được cập nhật real-time qua socket VÀ đồng bộ delta khi cần, để luôn thấy dữ liệu mới nhất.

#### Acceptance Criteria

1. WHILE người dùng đang trong một cuộc hội thoại, THE MessageBloc SHALL nhận real-time updates qua RealtimeService streams (messageStream, messageEditedStream, messageDeletedStream, messageReactionStream)
2. WHEN MessageBloc nhận socket event message:edit, THE MessageBloc SHALL cập nhật tin nhắn tương ứng trong state hiện tại bằng message ID
3. WHEN MessageBloc nhận socket event message:delete, THE MessageBloc SHALL loại bỏ tin nhắn tương ứng khỏi state hiện tại bằng message ID
4. WHEN MessageBloc nhận socket event message:reaction, THE MessageBloc SHALL cập nhật reactions của tin nhắn tương ứng trong state hiện tại
5. THE SyncMetadata SHALL được cập nhật lastKnownTimestamp khi nhận tin nhắn mới qua socket (nếu createdAt > lastKnownTimestamp hiện tại)

### Requirement 6: Delta Sync — Xử lý Missed Events và Reconnection

**User Story:** Là người dùng, tôi muốn ứng dụng tự động phát hiện và bù đắp tin nhắn bị miss khi mất kết nối, để không bỏ lỡ tin nhắn nào.

#### Acceptance Criteria

1. WHEN RealtimeService phát hiện reconnection (connectionState chuyển từ disconnected/error sang connected), THE MessageBloc SHALL thực hiện delta sync cho conversation đang active
2. WHEN app chuyển từ background sang foreground (onAppResumed), THE MessageBloc SHALL thực hiện delta sync cho conversation đang active nếu thời gian background > 30 giây
3. THE GapDetection SHALL so sánh số lượng tin nhắn delta từ server với số lượng socket events đã nhận trong khoảng thời gian tương ứng
4. IF GapDetection phát hiện có gap (tin nhắn bị miss), THEN THE MessageBloc SHALL thực hiện full refresh cho conversation đó
5. IF delta sync trả về số lượng tin nhắn bằng page size (ví dụ: 20), THEN THE MessageBloc SHALL thực hiện thêm một lần delta sync hoặc full refresh để đảm bảo không thiếu dữ liệu

### Requirement 7: Cache và Local Storage Management

**User Story:** Là developer, tôi muốn cache và local storage được quản lý hiệu quả cho two-phase render và delta sync, để đảm bảo performance và tính nhất quán dữ liệu.

#### Acceptance Criteria

1. WHEN merge hoàn tất sau two-phase render, THE MessageRepository SHALL cập nhật local storage (Isar) với dữ liệu merged
2. WHEN merge hoàn tất, THE MessageRepository SHALL invalidate cache keys liên quan và cập nhật cache mới
3. THE CacheSyncStrategy SHALL reset dirty flag cho conversation sau khi delta sync hoặc two-phase merge thành công
4. WHEN delta sync thành công, THE AppCacheManager SHALL cập nhật cache với tin nhắn mới, giữ TTL = 30 ngày (messageTtl)
5. IF local storage cho một conversation vượt quá 500 tin nhắn, THEN THE MessageRepository SHALL chỉ giữ 500 tin nhắn mới nhất trong cache, tin nhắn cũ hơn vẫn có trong Isar DB

### Requirement 8: Performance và Memory Management

**User Story:** Là người dùng, tôi muốn ứng dụng hoạt động mượt mà khi tải và hiển thị tin nhắn, không bị lag hoặc tốn quá nhiều bộ nhớ.

#### Acceptance Criteria

1. THE MessageBloc SHALL hoàn thành phase 1 (emit local data) của two-phase render trong vòng 50ms
2. THE MessageBloc SHALL hoàn thành phase 2 (merge server data) của two-phase render trong vòng 200ms sau khi nhận response từ server
3. THE MergeStrategy SHALL xử lý merge cho danh sách lên đến 500 tin nhắn trong vòng 100ms
4. THE Delta_Sync SHALL giảm payload size trung bình ít nhất 60% so với full load cho conversation có hơn 50 tin nhắn đã cache
5. WHILE two-phase render hoặc delta sync đang chạy, THE MessageBloc SHALL không block UI thread (sử dụng async/await, không compute-intensive trên main isolate)

### Requirement 9: Race Condition và Data Consistency

**User Story:** Là developer, tôi muốn hệ thống xử lý đúng các race condition giữa user actions, background fetch, và socket events, để dữ liệu luôn nhất quán.

#### Acceptance Criteria

1. IF người dùng gửi tin nhắn trong khi background fetch đang chạy, THEN THE MessageBloc SHALL giữ optimistic message trong state và merge đúng khi background fetch hoàn tất
2. IF socket event đến trong khi background fetch đang chạy, THEN THE MessageBloc SHALL buffer socket events và apply sau khi merge hoàn tất
3. IF người dùng navigate ra khỏi chat trong khi background fetch đang chạy, THEN THE MessageBloc SHALL cancel background fetch và cleanup resources
4. THE MessageBloc SHALL sử dụng conversation ID để đảm bảo không xử lý response từ conversation cũ khi người dùng đã chuyển sang conversation khác
5. IF hai delta sync requests chạy đồng thời cho cùng một conversation, THEN THE MessageBloc SHALL chỉ xử lý kết quả của request mới nhất (debounce hoặc cancel cũ)

### Requirement 10: Backward Compatibility và Migration

**User Story:** Là developer, tôi muốn Phase 2 và Phase 3 tương thích ngược với Phase 1, để không break existing functionality.

#### Acceptance Criteria

1. THE MessageBloc SHALL giữ nguyên tất cả public events hiện có (LoadMessages, LoadMoreMessages, SendMessage, EditMessage, DeleteMessage, ToggleReaction, v.v.)
2. THE IMessageRepository interface SHALL mở rộng (không breaking change) để hỗ trợ tham số `from` trong getMessages
3. THE MessagesLoaded state SHALL mở rộng (không breaking change) với các fields mới (dataSource, isBackgroundFetching) có giá trị default
4. WHEN LoadMoreMessages được gọi, THE MessageBloc SHALL giữ nguyên behavior offline-first hiện tại (Phase 1)
5. THE BaseRepository patterns (executeOnlineFirst, executeOfflineFirst) SHALL được tái sử dụng, không tạo pattern mới

