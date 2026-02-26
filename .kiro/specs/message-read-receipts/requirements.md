# Tài liệu Yêu cầu — Xác nhận đã đọc tin nhắn (Message Read Receipts)

## Giới thiệu

Tính năng hiển thị trạng thái "đã xem" (read receipts) cho từng tin nhắn trong trang chi tiết cuộc trò chuyện. Trong chat 1-1, hiển thị trạng thái "Đã xem" hoặc avatar nhỏ của người nhận bên dưới tin nhắn cuối cùng đã đọc. Trong chat nhóm, hiển thị avatar nhỏ của những người đã đọc từng tin nhắn — tương tự Messenger và Zalo.

### Phân tích hiện trạng

**Backend đã hỗ trợ:**
- Mutation `chatMessageUpdateRead` cập nhật `readerIds` trên từng message và emit socket event `message:read` với `{ message, reader }` tới room
- Mỗi message trong `chatMessageList` query trả về field `readerIds` (danh sách userId đã đọc)
- Mỗi `ConversationMember` có `lastMessageReadId` và `unreadCount`

**Flutter app đã có:**
- Entity `ChatMessage` có field `readBy: List<String>` (mapped từ `readerIds`)
- DTO `MessageDto` có field `readerIds` được map sang `readBy` trong domain
- Socket event mapper `mapMessageRead()` parse event `message:read` thành `MessageReadEvent`
- Widget `AppReadReceipt` hiển thị checkmark (✓✓ xanh) cho trạng thái read — chỉ hiển thị icon, chưa hiển thị avatar người đọc
- Enum `ReadReceiptMode` đã định nghĩa: `checkmarks`, `checkmarksWithTime`, `avatars`, `avatarsWithCount`
- `ConversationMember` entity có `userId`, `fullName`, `avatarUrl` — đủ thông tin để hiển thị avatar

**Cần bổ sung:**
- Widget hiển thị avatar người đã đọc bên dưới message bubble
- Logic xác định vị trí hiển thị read receipt avatars (chỉ hiển thị ở tin nhắn cuối cùng mà mỗi người đã đọc tới)
- Cập nhật real-time `readBy` khi nhận socket event `message:read`
- Tích hợp vào message list trong `ChatDetailsPage`

## Thuật ngữ

- **Read_Receipt_System**: Hệ thống hiển thị trạng thái đã đọc tin nhắn, bao gồm widget avatar, logic xác định vị trí, và cập nhật real-time
- **Message_Bubble**: Widget hiển thị nội dung một tin nhắn trong danh sách tin nhắn (`AppMessageBubble`)
- **Read_Receipt_Indicator**: Widget hiển thị avatar nhỏ của những người đã đọc, đặt bên dưới Message_Bubble
- **Reader**: Người dùng đã xem/đọc một tin nhắn cụ thể (có userId nằm trong `readerIds` của message)
- **Last_Read_Position**: Tin nhắn cuối cùng mà một Reader đã đọc tới trong cuộc trò chuyện — vị trí hiển thị avatar của Reader đó
- **Conversation_Members**: Danh sách thành viên trong cuộc trò chuyện, cung cấp thông tin `userId`, `fullName`, `avatarUrl` để hiển thị avatar
- **Current_User**: Người dùng đang đăng nhập và sử dụng ứng dụng
- **Direct_Chat**: Cuộc trò chuyện 1-1 giữa hai người
- **Group_Chat**: Cuộc trò chuyện nhóm có từ 3 thành viên trở lên
- **Message_List**: Danh sách tin nhắn trong trang chi tiết cuộc trò chuyện (`ChatDetailsPage`)

## Yêu cầu

### Yêu cầu 1: Xác định vị trí hiển thị Read Receipt

**User Story:** Là người dùng, tôi muốn thấy avatar của người đã đọc được đặt đúng vị trí bên dưới tin nhắn cuối cùng mà họ đọc tới, để tôi biết chính xác mỗi người đã đọc đến đâu.

#### Tiêu chí chấp nhận

1. THE Read_Receipt_System SHALL xác định Last_Read_Position của mỗi Reader bằng cách tìm tin nhắn cuối cùng (theo thứ tự thời gian) có `readerIds` chứa userId của Reader đó
2. THE Read_Receipt_System SHALL chỉ hiển thị Read_Receipt_Indicator cho các tin nhắn do Current_User gửi
3. THE Read_Receipt_System SHALL loại trừ Current_User khỏi danh sách Reader khi hiển thị Read_Receipt_Indicator
4. WHEN nhiều Reader có cùng Last_Read_Position tại một tin nhắn, THE Read_Receipt_System SHALL gộp tất cả avatar của các Reader đó vào một Read_Receipt_Indicator duy nhất bên dưới tin nhắn đó
5. WHEN một Reader đọc thêm tin nhắn mới, THE Read_Receipt_System SHALL di chuyển avatar của Reader đó từ vị trí cũ sang Last_Read_Position mới

### Yêu cầu 2: Hiển thị Read Receipt trong Chat 1-1 (Direct Chat)

**User Story:** Là người dùng, tôi muốn thấy trạng thái "đã xem" kèm avatar nhỏ của người nhận bên dưới tin nhắn cuối cùng họ đã đọc, để tôi biết họ đã đọc tin nhắn của tôi chưa.

#### Tiêu chí chấp nhận

1. WHILE Current_User đang xem một Direct_Chat, THE Read_Receipt_Indicator SHALL hiển thị avatar nhỏ (kích thước 16dp) của người nhận bên dưới bên phải tin nhắn cuối cùng mà người nhận đã đọc
2. WHEN người nhận chưa đọc bất kỳ tin nhắn nào của Current_User, THE Read_Receipt_Indicator SHALL không hiển thị avatar nào
3. THE Read_Receipt_Indicator SHALL sử dụng widget `AppAvatar` từ design system với kích thước `AppDimens` phù hợp

### Yêu cầu 3: Hiển thị Read Receipt trong Chat Nhóm (Group Chat)

**User Story:** Là người dùng, tôi muốn thấy avatar nhỏ của những người đã đọc tin nhắn trong nhóm, để tôi biết ai đã xem tin nhắn của tôi.

#### Tiêu chí chấp nhận

1. WHILE Current_User đang xem một Group_Chat, THE Read_Receipt_Indicator SHALL hiển thị danh sách avatar nhỏ (kích thước 16dp) của các Reader bên dưới bên phải tin nhắn tương ứng
2. WHEN số lượng Reader tại một tin nhắn vượt quá 5 người, THE Read_Receipt_Indicator SHALL hiển thị tối đa 4 avatar và một badge "+N" cho số Reader còn lại
3. WHEN người dùng nhấn vào Read_Receipt_Indicator trong Group_Chat, THE Read_Receipt_System SHALL hiển thị bottom sheet chứa danh sách đầy đủ các Reader với tên và avatar
4. THE Read_Receipt_Indicator SHALL sắp xếp avatar theo thứ tự thời gian đọc (người đọc gần nhất hiển thị trước)

### Yêu cầu 4: Cập nhật Real-time Read Receipt qua Socket.IO

**User Story:** Là người dùng, tôi muốn thấy trạng thái đã đọc được cập nhật ngay lập tức khi người khác đọc tin nhắn, mà không cần tải lại trang.

#### Tiêu chí chấp nhận

1. WHEN nhận được socket event `message:read` với dữ liệu `{ message, reader }`, THE Read_Receipt_System SHALL cập nhật `readBy` của tin nhắn tương ứng trong Message_List
2. WHEN `readBy` của một tin nhắn được cập nhật, THE Read_Receipt_Indicator SHALL cập nhật hiển thị avatar trong vòng 100ms
3. THE Read_Receipt_System SHALL xử lý socket event `message:read` bằng cách thêm `reader.id` vào danh sách `readBy` của message nếu chưa tồn tại
4. IF socket event `message:read` chứa `messageId` không tồn tại trong Message_List hiện tại, THEN THE Read_Receipt_System SHALL bỏ qua event đó mà không gây lỗi

### Yêu cầu 5: Gửi Read Receipt khi người dùng đọc tin nhắn

**User Story:** Là người dùng, tôi muốn hệ thống tự động gửi xác nhận đã đọc khi tôi xem tin nhắn, để người gửi biết tôi đã đọc.

#### Tiêu chí chấp nhận

1. WHEN Current_User mở một cuộc trò chuyện có tin nhắn chưa đọc, THE Read_Receipt_System SHALL gọi mutation `chatMessageUpdateRead` với `readCount` tương ứng số tin nhắn chưa đọc
2. WHEN Current_User cuộn tới và xem thêm tin nhắn chưa đọc trong cuộc trò chuyện đang mở, THE Read_Receipt_System SHALL gọi mutation `chatMessageUpdateRead` để cập nhật trạng thái đã đọc
3. THE Read_Receipt_System SHALL debounce việc gọi mutation `chatMessageUpdateRead` với khoảng thời gian 500ms để tránh gọi API quá nhiều khi cuộn nhanh
4. IF mutation `chatMessageUpdateRead` thất bại, THEN THE Read_Receipt_System SHALL ghi log lỗi và thử lại tối đa 2 lần với backoff 1 giây

### Yêu cầu 6: Tích hợp Read Receipt vào Message List

**User Story:** Là người dùng, tôi muốn read receipt hiển thị tự nhiên trong danh sách tin nhắn mà không ảnh hưởng đến trải nghiệm cuộn và đọc tin nhắn.

#### Tiêu chí chấp nhận

1. THE Read_Receipt_Indicator SHALL được đặt bên dưới Message_Bubble, căn phải, với khoảng cách `AppDimens.spacingXSmall` từ bubble
2. THE Read_Receipt_Indicator SHALL không làm thay đổi chiều cao của message item một cách đột ngột — sử dụng `AnimatedSize` hoặc animation tương đương khi avatar xuất hiện hoặc biến mất
3. WHILE Message_List đang tải thêm tin nhắn (pagination), THE Read_Receipt_System SHALL giữ nguyên vị trí Read_Receipt_Indicator của các tin nhắn đã hiển thị
4. THE Read_Receipt_System SHALL sử dụng thông tin từ Conversation_Members (đã có sẵn trong BLoC) để map `userId` trong `readBy` sang `fullName` và `avatarUrl` cho hiển thị avatar
5. IF một userId trong `readBy` không tìm thấy trong Conversation_Members, THEN THE Read_Receipt_System SHALL hiển thị avatar mặc định với chữ cái đầu tiên của userId

### Yêu cầu 7: Hỗ trợ Dark Mode và Accessibility

**User Story:** Là người dùng, tôi muốn read receipt hiển thị đúng trong cả light mode và dark mode, và có thể truy cập được bằng screen reader.

#### Tiêu chí chấp nhận

1. THE Read_Receipt_Indicator SHALL sử dụng `AppColors` từ design system để đảm bảo hiển thị đúng trong cả light mode và dark mode
2. THE Read_Receipt_Indicator SHALL cung cấp `Semantics` label mô tả danh sách người đã đọc (ví dụ: "Đã xem bởi Nguyễn Văn A, Trần Thị B") sử dụng chuỗi từ `context.l10n`
3. THE Read_Receipt_Indicator SHALL có kích thước touch target tối thiểu 24dp khi có thể nhấn (trong Group_Chat) theo hướng dẫn accessibility

### Yêu cầu 8: Hiệu năng hiển thị Read Receipt

**User Story:** Là người dùng, tôi muốn read receipt không làm chậm việc cuộn danh sách tin nhắn hoặc tăng mức sử dụng bộ nhớ đáng kể.

#### Tiêu chí chấp nhận

1. THE Read_Receipt_System SHALL tính toán Last_Read_Position một cách hiệu quả với độ phức tạp O(n) trong đó n là số tin nhắn hiển thị, không phải O(n*m) với m là số thành viên
2. THE Read_Receipt_System SHALL cache kết quả tính toán Last_Read_Position và chỉ tính lại khi `readBy` của bất kỳ tin nhắn nào thay đổi
3. THE Read_Receipt_Indicator SHALL sử dụng `const` constructor khi dữ liệu không thay đổi để tối ưu rebuild
4. THE Message_List SHALL duy trì tốc độ cuộn 60fps khi hiển thị Read_Receipt_Indicator
