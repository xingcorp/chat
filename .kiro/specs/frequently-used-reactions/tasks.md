# Kế hoạch Triển khai: Frequently Used Reactions

## Tổng quan

Tính năng nhỏ. Triển khai: GraphQL operation → Service → Tích hợp UI → DI.

## Tasks

- [ ] 1. Thêm GraphQL operation
  - [ ] 1.1 Thêm `getFrequentlyUsedReactions` vào `ChatQueries` trong `flutter_chat_app/lib/data/graphql/chat_operations.dart`
    - Mutation `chatReactionFrequentlyUsed` trả về `[String]`
    - _Requirements: 1.1_

- [ ] 2. Tạo `FrequentReactionService`
  - [ ] 2.1 Tạo `FrequentReactionService` tại `flutter_chat_app/lib/core/services/frequent_reaction_service.dart`
    - `@lazySingleton`, inject `GraphQLClientWrapper`, `AppLogger`
    - Default reactions: `['👍', '❤️', '😂', '😮', '😢', '😡']`
    - `fetch()` — gọi GraphQL, update cache + stream
    - `invalidateAfterReaction()` — debounced 10s refetch
    - `reactionsStream` — `BehaviorSubject<List<String>>`
    - `currentReactions` — getter cho sync access
    - Cache TTL 5 phút
    - Fallback default khi API fail hoặc trả về rỗng
    - `dispose()` — cancel timer, close subject
    - _Requirements: 1.1, 1.2, 1.3, 3.1, 3.2_

- [ ] 3. Tích hợp vào Quick Reaction Bar
  - [ ] 3.1 Cập nhật widget quick reaction bar (tìm widget hiện tại hiển thị reaction options trên message)
    - Inject `FrequentReactionService` qua `getIt`
    - `StreamBuilder` trên `reactionsStream`
    - Hiển thị top 6 emoji + nút "+" mở full picker
    - Sử dụng `AppColors`, `AppDimens`
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 4. Tích hợp vào MessageBloc
  - [ ] 4.1 Sau khi reaction thành công trong `MessageBloc`, gọi `frequentReactionService.invalidateAfterReaction()`
    - _Requirements: 3.1_

- [ ] 5. Trigger fetch khi mở app
  - [ ] 5.1 Gọi `frequentReactionService.fetch()` khi user đăng nhập hoặc app khởi động
    - Có thể đặt trong `ChatModule.init()` hoặc tương đương
    - _Requirements: 1.1_

- [ ] 6. DI Registration và Code Generation
  - [ ] 6.1 Đảm bảo `FrequentReactionService` đăng ký trong DI
  - [ ] 6.2 Chạy `dart run build_runner build --delete-conflicting-outputs`

- [ ] 7. Final checkpoint
  - Đảm bảo frequently used reactions hiển thị đúng trong reaction bar

## Ghi chú

- Tính năng nhỏ, ít rủi ro
- Backend API đã sẵn sàng (`chatReactionFrequentlyUsed`)
- Không cần thay đổi backend
- Tuân thủ design system, base classes
