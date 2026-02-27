# Kế hoạch Triển khai: Ghi âm Tin nhắn Thoại (Voice Recording / Voice Note)

## Tổng quan

Triển khai theo thứ tự: Core Services → Domain → Data → Presentation → Tích hợp. Tận dụng upload flow hiện có (`storageGeneratePresignedUrls`), `ChatInput` recording UI, `MessageType.voiceNote`, optimistic update pattern.

## Tasks

- [ ] 1. Thêm dependencies và tạo `VoiceRecorderService`
  - [ ] 1.1 Thêm package `record` vào `flutter_chat_app/pubspec.yaml`
  - [ ] 1.2 Thêm package `just_audio` vào `flutter_chat_app/pubspec.yaml`
  - [ ] 1.3 Cấu hình permission microphone trong `AndroidManifest.xml` và `Info.plist` (nếu chưa có)
  - [ ] 1.4 Tạo `VoiceRecorderService` tại `flutter_chat_app/lib/core/services/voice_recorder_service.dart`
    - `@lazySingleton`, inject `AppLogger`
    - `requestPermission()` — kiểm tra và yêu cầu quyền microphone
    - `startRecording()` — ghi âm AAC .m4a, 128kbps, 44100Hz, lưu vào cache dir
    - `stopRecording()` — dừng ghi âm, trả về file path
    - `cancelRecording()` — huỷ ghi âm, xoá file tạm
    - `amplitudeStream` — stream amplitude cho UI
    - Giới hạn 5 phút, tự động dừng
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [ ] 2. Tạo `VoiceNotePlaybackManager`
  - [ ] 2.1 Tạo `VoiceNotePlaybackState` class tại `flutter_chat_app/lib/core/services/voice_note_playback_manager.dart`
    - `isPlaying`, `position`, `duration` fields
  - [ ] 2.2 Tạo `VoiceNotePlaybackManager` tại cùng file
    - `@lazySingleton`, sử dụng `just_audio` AudioPlayer
    - `play(messageId, audioUrl)` — dừng audio cũ, phát mới
    - `pause()`, `seek(position)`, `stop()`
    - `getPlaybackStream(messageId)` — stream state cho widget
    - Dispose player trong `dispose()`
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] 3. Mở rộng Data layer — upload và gửi voice note
  - [ ] 3.1 Thêm method `uploadAndSendVoiceNote` vào `IMessageRemoteDataSource` interface
    - Parameters: `filePath`, `conversationId`, `receiverId?`, `durationSeconds`
    - Flow: presigned URL → upload binary → chatMessageAdd type VOICE_NOTE
  - [ ] 3.2 Implement trong `MessageRemoteDataSource`
    - Gọi `storageGeneratePresignedUrls` với fileName `.m4a`, fileType `audio/mp4`
    - Upload file qua HTTP PUT đến presigned URL
    - Gọi `chatMessageAdd` với type `VOICE_NOTE`, urls, fileName
    - _Requirements: 2.1, 2.2_
  - [ ] 3.3 Thêm method `sendVoiceNote` vào `IMessageRepository` interface và `MessageRepositoryImpl`
    - Wrap trong try/catch, return `Either<Failure, ChatMessage>`
    - Xoá file tạm sau upload thành công
    - _Requirements: 2.5_

- [ ] 4. Mở rộng MessageBloc — event SendVoiceNote
  - [ ] 4.1 Thêm `SendVoiceNote` event vào `flutter_chat_app/lib/presentation/blocs/message/message_event.dart`
    - Fields: `filePath`, `durationSeconds`
  - [ ] 4.2 Thêm handler `_onSendVoiceNote` trong `MessageBloc`
    - Tạo temp message với type voiceNote, status sending
    - Emit optimistic update
    - Gọi repository.sendVoiceNote
    - Thành công: replace temp message với server message
    - Thất bại: update temp message status = failed
    - _Requirements: 2.3, 2.4_

- [ ] 5. Checkpoint — Đảm bảo core services và BLoC logic hoạt động
  - Verify VoiceRecorderService, VoiceNotePlaybackManager, MessageBloc handler

- [ ] 6. Tạo `VoiceNotePlayerWidget`
  - [ ] 6.1 Thêm localization keys vào ARB files
    - `app_en.arb`: `voiceNote`, `voiceNoteDuration`, `voiceNoteRecording`, `microphonePermissionTitle`, `microphonePermissionMessage`, `openSettings`, `recordingLimitReached`
    - `app_vi.arb`: tương ứng tiếng Việt
    - Chạy `flutter gen-l10n`
    - _Requirements: 4.4, 5.4_
  - [ ] 6.2 Tạo `VoiceNotePlayerWidget` tại `flutter_chat_app/lib/presentation/widgets/design_system/chat/voice_note_player.dart`
    - Extends `BaseStatefulWidget`
    - StreamBuilder kết nối `VoiceNotePlaybackManager.getPlaybackStream(messageId)`
    - Hiển thị: `AppIconButton` play/pause + progress bar + duration `mm:ss`
    - Sử dụng `AppColors`, `AppDimens`, `context.l10n`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.7_

- [ ] 7. Cập nhật `ChatInput` — tích hợp VoiceRecorderService thật
  - [ ] 7.1 Inject `VoiceRecorderService` vào `ChatInput` hoặc parent widget
  - [ ] 7.2 Thay thế logic giả trong `_startRecording()` bằng `voiceRecorderService.startRecording()`
  - [ ] 7.3 Thay thế `_stopRecording()` — gọi `voiceRecorderService.stopRecording()` trả về real path
  - [ ] 7.4 Kết nối `amplitudeStream` để hiển thị amplitude indicator trong Recording_UI
  - [ ] 7.5 Thêm permission check trước khi ghi âm, hiển thị `AppAlertDialog` nếu bị từ chối
  - [ ] 7.6 Cập nhật Recording_UI sử dụng `AppColors`, `AppDimens`, `context.l10n`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3_

- [ ] 8. Tích hợp VoiceNotePlayerWidget vào Message Bubble
  - [ ] 8.1 Trong message bubble builder, khi `message.type == MessageType.voiceNote`, render `VoiceNotePlayerWidget`
    - Truyền `messageId`, `audioUrl` từ `message.mediaUrls[0]`, `duration`
    - _Requirements: 3.1_

- [ ] 9. DI Registration và Code Generation
  - [ ] 9.1 Đảm bảo `VoiceRecorderService` và `VoiceNotePlaybackManager` được đăng ký trong DI
  - [ ] 9.2 Chạy `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 9.3 Chạy `flutter gen-l10n`

- [ ] 10. Final checkpoint
  - Đảm bảo ghi âm thật hoạt động, upload thành công, player phát đúng

## Ghi chú

- Tận dụng upload flow hiện có (`storageGeneratePresignedUrls`) — không tạo flow mới
- `ChatInput` đã có UI ghi âm (timer, slide to cancel) — chỉ cần kết nối với recorder thật
- Optimistic update pattern giống `SendMessage` hiện có trong `MessageBloc`
- Tuân thủ Clean Architecture: Domain → Data → Presentation
- Tất cả UI sử dụng design system, base classes, `context.l10n`
