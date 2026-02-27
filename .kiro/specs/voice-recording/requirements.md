# Tài liệu Yêu cầu — Ghi âm Tin nhắn Thoại (Voice Recording / Voice Note)

## Giới thiệu

Tính năng ghi âm và gửi tin nhắn thoại (voice note) trong cuộc trò chuyện. Backend đã hỗ trợ `ChatMessageType.VOICE_NOTE` riêng biệt. Flutter app hiện có `ChatInput` widget với callbacks `onVoiceRecordingStarted/Ended/Cancelled` và `AppVoiceWaveform` widget, nhưng logic ghi âm thực tế là giả (fakePath = `recording_...`). Cần tích hợp thư viện ghi âm thật, upload file lên server, và gửi tin nhắn loại `VOICE_NOTE`.

### Phân tích hiện trạng

**Backend đã hỗ trợ:**
- `ChatMessageType.VOICE_NOTE` trong enum `message.chat.enum.ts`
- `chatMessageAdd` mutation nhận `type: "VOICE_NOTE"`, `urls: [String]`, `fileName: String`
- Socket.IO event `message:file:upload` để upload file binary, trả về `filePath`
- `storageGeneratePresignedUrls` mutation để upload qua presigned URL (2-step upload)
- Message list query trả về đầy đủ thông tin cho voice note (urls, fileName, type)

**Flutter app đã có:**
- `ChatInput` widget (`chat_input.dart`) có UI ghi âm: long press mic → recording UI → slide to cancel
- Callbacks: `onVoiceRecordingStarted`, `onVoiceRecordingEnded(String path)`, `onVoiceRecordingCancelled`
- `AppVoiceWaveform` widget cho hiển thị waveform
- `MessageType.voiceNote` trong enum
- `ChatMessageType` mapping trong DTO layer
- Upload flow qua `storageGeneratePresignedUrls` đã có cho image/video/file

**Cần bổ sung:**
- Tích hợp thư viện ghi âm thật (package `record`) thay thế fakePath
- Service ghi âm với permission handling, start/stop/cancel/pause
- Upload file audio lên server qua presigned URL flow
- Gửi message type `VOICE_NOTE` với URL audio
- Widget phát lại voice note trong message bubble (player với waveform, duration, play/pause)
- Hiển thị duration khi đang ghi âm (đã có timer nhưng cần kết nối với recorder thật)

## Thuật ngữ

- **Voice_Note**: Tin nhắn thoại được ghi âm và gửi trong cuộc trò chuyện, type = `VOICE_NOTE`
- **Voice_Recorder_Service**: Service quản lý ghi âm thực tế, sử dụng package `record`
- **Voice_Player_Widget**: Widget phát lại voice note trong message bubble
- **Recording_UI**: Giao diện hiển thị khi đang ghi âm (đã có trong `ChatInput`)
- **Presigned_Upload**: Flow upload 2 bước: lấy presigned URL → upload file → dùng URL trong message
- **Waveform**: Biểu đồ sóng âm hiển thị trong voice note player

## Yêu cầu

### Yêu cầu 1: Tích hợp thư viện ghi âm thật

**User Story:** Là người dùng, tôi muốn ghi âm tin nhắn thoại thực sự khi long press nút mic, thay vì chỉ giả lập.

#### Tiêu chí chấp nhận

1. THE Voice_Recorder_Service SHALL sử dụng package `record` để ghi âm audio thực tế
2. THE Voice_Recorder_Service SHALL yêu cầu quyền microphone trước khi ghi âm, hiển thị dialog giải thích nếu bị từ chối
3. THE Voice_Recorder_Service SHALL ghi âm ở định dạng AAC (`.m4a`) với bitrate 128kbps, sample rate 44100Hz
4. THE Voice_Recorder_Service SHALL lưu file tạm vào thư mục cache của app (`getTemporaryDirectory`)
5. THE Voice_Recorder_Service SHALL giới hạn thời lượng ghi âm tối đa 5 phút, tự động dừng khi đạt giới hạn
6. WHEN người dùng huỷ ghi âm (slide to cancel), THE Voice_Recorder_Service SHALL xoá file tạm đã ghi

### Yêu cầu 2: Upload và gửi Voice Note

**User Story:** Là người dùng, tôi muốn voice note được upload và gửi tự động sau khi tôi thả nút ghi âm.

#### Tiêu chí chấp nhận

1. WHEN người dùng kết thúc ghi âm (thả nút), THE system SHALL upload file audio qua presigned URL flow (giống upload image/file hiện có)
2. THE system SHALL gửi mutation `chatMessageAdd` với `type: "VOICE_NOTE"`, `urls: [audioUrl]`, `fileName: "voice_note_{timestamp}.m4a"`
3. WHILE đang upload, THE system SHALL hiển thị tin nhắn tạm (optimistic update) với trạng thái "đang gửi"
4. IF upload thất bại, THE system SHALL hiển thị trạng thái "gửi thất bại" với nút retry
5. THE system SHALL xoá file tạm sau khi upload thành công

### Yêu cầu 3: Hiển thị Voice Note trong Message Bubble

**User Story:** Là người dùng, tôi muốn thấy voice note hiển thị dạng player với waveform và nút play/pause trong message bubble.

#### Tiêu chí chấp nhận

1. THE Voice_Player_Widget SHALL hiển thị: nút play/pause, waveform/progress bar, và duration
2. THE Voice_Player_Widget SHALL tải và phát audio từ URL trong message `urls[0]`
3. WHEN người dùng nhấn play, THE Voice_Player_Widget SHALL phát audio và hiển thị progress trên waveform
4. WHEN audio đang phát và người dùng nhấn pause, THE Voice_Player_Widget SHALL tạm dừng phát
5. WHEN audio phát xong, THE Voice_Player_Widget SHALL reset về trạng thái ban đầu (hiển thị tổng duration)
6. THE Voice_Player_Widget SHALL chỉ cho phép phát 1 voice note tại một thời điểm — phát voice note mới sẽ dừng voice note đang phát
7. THE Voice_Player_Widget SHALL hiển thị duration ở định dạng `mm:ss`

### Yêu cầu 4: Giao diện ghi âm cải thiện

**User Story:** Là người dùng, tôi muốn giao diện ghi âm hiển thị thời gian thực và phản hồi trực quan khi đang ghi.

#### Tiêu chí chấp nhận

1. THE Recording_UI SHALL hiển thị thời gian ghi âm real-time (đã có, cần kết nối với recorder thật)
2. THE Recording_UI SHALL hiển thị amplitude indicator (thanh sóng âm) phản ánh mức âm lượng thực tế
3. THE Recording_UI SHALL sử dụng `AppColors` và `AppDimens` từ design system
4. THE Recording_UI SHALL sử dụng `context.l10n` cho tất cả chuỗi hiển thị

### Yêu cầu 5: Permission Handling

**User Story:** Là người dùng, tôi muốn app xin quyền microphone rõ ràng và xử lý trường hợp bị từ chối.

#### Tiêu chí chấp nhận

1. WHEN người dùng long press mic lần đầu, THE system SHALL kiểm tra và yêu cầu quyền microphone
2. IF quyền bị từ chối, THE system SHALL hiển thị `AppAlertDialog` giải thích lý do cần quyền và nút mở Settings
3. IF quyền bị từ chối vĩnh viễn, THE system SHALL hướng dẫn người dùng vào Settings để cấp quyền
4. THE system SHALL sử dụng `context.l10n` cho tất cả chuỗi trong dialog permission
