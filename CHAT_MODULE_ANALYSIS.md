# Flutter Chat vs Backend (@src) - Gap Analysis & Implementation Blueprint

**Last updated:** 2026-03-03  
**Scope:** `flutter_chat_app` (Flutter client) so với `src/modules/chat` (NestJS backend)  
**Audience:** Mobile team, backend team, QA, Tech Lead

---

## 1) Executive Summary

Flutter chat đã có phần lớn core flow (gửi/sửa/xóa tin nhắn, reaction, read receipt, typing, media attachment, location, voice note, thêm/xóa member, search cơ bản).  
Tuy nhiên vẫn còn một số khoảng trống quan trọng so với backend:

1. Rủi ro mất đồng bộ realtime khi nhận event xóa tin nhắn.
2. Chưa có flow UI hoàn chỉnh cho leave/delete conversation.
3. Chức năng group admin chưa expose đầy đủ lên UI.
4. Create/update group chưa map hết field backend (`description`, `groupType`, avatar, admin list).
5. Search tin nhắn chưa đạt parity filter/pagination.
6. `Delete history` mới dừng ở datasource, chưa đi đến use case/UI.
7. Realtime event conversation join/leave chưa đồng bộ tên event.
8. Chưa support đầy đủ message type `CALL`.
9. Chưa có client path cho socket event `message:file:upload` (nếu sản phẩm cần).
10. Một phần UI chat còn hardcoded string, chưa đạt chuẩn i18n.

Mức ưu tiên cao nhất là các lỗi ảnh hưởng tính đúng dữ liệu realtime và thao tác destructive action (P0).

---

## 2) Methodology & Baseline

### 2.1 Phạm vi đối chiếu

- Backend:
  - `src/modules/chat/chat-conversation/*`
  - `src/modules/chat/chat-message/*`
  - `src/modules/chat/chat-gateway/*`
  - `src/modules/chat/chat.args.ts`
  - `src/enum/chat/message.chat.enum.ts`
- Flutter:
  - Chat data sources/repositories/usecases/blocs/pages/widgets
  - Realtime service/socket handling
  - Search/member/group-management flows
  - i18n usage trong chat-related screens

### 2.2 Nguyên tắc kỹ thuật khi triển khai

- Tuân thủ Clean Architecture hiện tại (data -> domain -> presentation).
- Không phá vỡ pattern BLoC/state và error handling đang dùng.
- Sử dụng shared component trong design system theo `.kiro/steering/design-system-usage.md`.
- Không hardcode string mới; mọi text qua `context.l10n`.
- Tương thích backward với payload backend hiện có (đặc biệt socket).

---

## 3) Parity Matrix (Backend Capability vs Flutter Status)

| # | Capability | Backend | Flutter | Status | Priority |
|---|---|---|---|---|---|
| 1 | Realtime delete message | `message:delete` emit | Parse payload bằng model sai shape | Missing parity (risky) | P0 |
| 2 | Leave/Delete conversation | Resolver + mutation có sẵn | UI còn TODO, chưa dispatch action hoàn chỉnh | Partial | P0 |
| 3 | Group admin management | `adminIds` update | BLoC có logic, UI thiếu action promote/demote | Partial | P1 |
| 4 | Group metadata parity | `description/groupType/imgUrl/adminIds` | Create/update flow chưa map đủ | Partial | P1 |
| 5 | Message search advanced | Filter nâng cao + paging | Chỉ keyword + convId + limit; load more chưa đúng paging | Partial | P1 |
| 6 | Delete history | `chatMessageDeleteHistory` | Datasource có nhưng không expose end-to-end | Missing | P1 |
| 7 | Conversation join/leave realtime | `conversation:joined/leaved` emit | FE lắng nghe `chat_updated` | Missing parity | P1 |
| 8 | Message type CALL | Enum backend có `CALL` | FE enum/mapper chưa parse đầy đủ | Missing parity | P2 |
| 9 | File upload socket event | `message:file:upload` | FE chưa có consumer path rõ ràng | TBD/Partial | P2 |
| 10 | i18n completeness | N/A | Còn hardcoded string trong chat info/location | Partial | P1 |

---

## 4) Evidence (Current Code Pointers)

### 4.1 Realtime delete parsing mismatch

- FE listener:
  - `flutter_chat_app/lib/core/services/realtime_service.dart` (`message:delete` -> `ChatMessage.fromJson(...)`)
- FE model parse shape:
  - `flutter_chat_app/lib/shared/domain/entities/chat_message.dart` (`fromJson` cần `chatId/contentType/content`)
- BE event emit:
  - `src/modules/chat/chat-gateway/chat.gateway.ts` (emit `message:delete`)

### 4.2 Leave/Delete conversation chưa hoàn thiện

- UI TODO:
  - `flutter_chat_app/lib/presentation/widgets/chat_info/chat_info_panel.dart` (`TODO: Implement leave group logic`, `TODO: Implement delete chat logic`)
- Use case có sẵn:
  - `flutter_chat_app/lib/features/chat/domain/usecases/chat/delete_conversation_usecase.dart`
- ChatBloc có inject use case nhưng chưa thấy event flow đầy đủ:
  - `flutter_chat_app/lib/features/chat/presentation/blocs/chat/chat_bloc.dart`

### 4.3 Group admin UI gap

- BLoC đã có:
  - `flutter_chat_app/lib/presentation/blocs/chat_members/chat_members_bloc.dart` (`ChatMembersMakeAdmin`, `ChatMembersRemoveAdmin`, `ChatMembersLeaveGroup`)
- UI member page thiếu action promote/demote:
  - `flutter_chat_app/lib/presentation/pages/chat_members_page.dart`

### 4.4 Group create/update metadata gap

- Backend DTO có:
  - `src/modules/chat/chat-conversation/dto/chat-conversation.args.ts`
- FE use case/UI chưa truyền đủ field:
  - `flutter_chat_app/lib/features/chat/domain/usecases/chat/create_group_usecase.dart`
  - `flutter_chat_app/lib/features/chat/domain/usecases/chat/update_group_usecase.dart`
  - `flutter_chat_app/lib/features/chat/presentation/pages/chat/create_group_page.dart`

### 4.5 Search parity gap

- Backend filter mạnh:
  - `src/modules/chat/chat.args.ts`
- FE use case/repo/bloc:
  - `flutter_chat_app/lib/features/chat/domain/usecases/chat/search_messages_usecase.dart`
  - `flutter_chat_app/lib/features/chat/data/repositories/chat_repository.dart`
  - `flutter_chat_app/lib/features/chat/presentation/blocs/message_search/message_search_bloc.dart` (`LoadMore` không truyền page/cursor xuống API)

### 4.6 Delete history chưa E2E

- Backend mutation:
  - `src/modules/chat/chat-message/chat-message.resolver.ts`
- FE datasource có method:
  - `flutter_chat_app/lib/features/chat/data/datasources/chat/chat_remote_datasource.dart`
  - `flutter_chat_app/lib/data/datasources/message/message_remote_datasource.dart`
- Chưa thấy domain/usecase/presentation call chain.

### 4.7 Conversation events mismatch

- BE emit:
  - `src/modules/chat/chat-gateway/chat.gateway.ts` (`conversation:joined`, `conversation:leaved`)
- FE đang nghe:
  - `flutter_chat_app/lib/features/chat/data/datasources/chat/chat_remote_datasource.dart` (`chat_updated`)

### 4.8 CALL type gap

- BE enum:
  - `src/enum/chat/message.chat.enum.ts` (`CALL`)
- FE:
  - `flutter_chat_app/lib/shared/domain/entities/chat_message.dart`
  - `flutter_chat_app/lib/data/mappers/message_mapper.dart`

### 4.9 File upload socket event gap

- BE subscribe:
  - `src/modules/chat/chat-gateway/chat.gateway.ts` (`message:file:upload`)
- FE chưa có path xử lý tương ứng rõ ràng.

### 4.10 i18n hardcoded text

- Chat details/location:
  - `flutter_chat_app/lib/features/chat/presentation/pages/chat/chat_details_page.dart`
- Chat info panel:
  - `flutter_chat_app/lib/presentation/widgets/chat_info/chat_info_panel.dart`

---

## 5) Target Architecture (Không phá vỡ pattern dự án)

### 5.1 Data Layer

- Tách rõ mapper cho socket payload backend (`ServerMessageEventMapper`) thay vì dùng `ChatMessage.fromJson` trực tiếp cho mọi event.
- Đồng bộ contract tên event realtime tại một nơi (const class hoặc enum).
- Chuẩn hóa repository return `Either<Failure, T>` như pattern hiện tại.

### 5.2 Domain Layer

- Bổ sung use cases thiếu:
  - `LeaveConversationUseCase`
  - `DeleteMessageHistoryUseCase`
  - `SearchMessagesAdvancedUseCase` (hoặc mở rộng use case hiện có)
- Mở rộng entity/filter object cho search (`receiverIds`, `messageTypes`, time range, pagination/cursor).

### 5.3 Presentation Layer

- BLoC event/state rõ cho destructive action:
  - `LeaveConversationRequested`
  - `DeleteConversationRequested`
  - `DeleteHistoryRequested`
- UI action qua design-system components (`AppButton`, `AppConfirmDialog`, `AppSnackBar`, ...), không dùng widget raw nếu project đã có wrapper chuẩn.
- Tách widget theo trách nhiệm: action sheet/menu của member quản trị group không nhúng logic networking trực tiếp.

### 5.4 Realtime Consistency Layer

- Quy ước mapping event:
  - Message-level: sent/read/reaction/edit/delete
  - Conversation-level: joined/leaved/updated
- Mọi incoming socket event cần:
  1. Validate payload.
  2. Map về domain model.
  3. Emit state update idempotent (tránh duplicate).
  4. Fallback log/metrics khi parse fail.

---

## 6) Implementation Backlog (Senior-level Breakdown)

## Phase P0 (Blocker/Correctness)

### P0.1 Fix realtime `message:delete` payload mapping

**Goal:** Event delete từ user khác phải phản ánh đúng ngay lập tức.  
**Changes:**

- Data:
  - Tạo mapper riêng cho socket payload backend -> domain delete event model.
  - Không dùng `ChatMessage.fromJson` cho payload không tương thích.
- Presentation:
  - BLoC/state update theo `messageId + conversationId`.
- QA:
  - Test parse payload chuẩn và payload thiếu field.

**Acceptance criteria:**

- Khi user A xóa tin nhắn, user B thấy tin nhắn bị thu hồi trong <1s.
- Không crash khi payload thiếu optional fields.

### P0.2 Implement leave/delete conversation E2E

**Goal:** Nút leave/delete trong chat info phải hoạt động thật và an toàn.  
**Changes:**

- BLoC:
  - Thêm event/state thành công/thất bại/loading.
- UI:
  - Dialog confirm + loading + disable repeat tap.
  - Sau success: điều hướng về chat list, refresh danh sách.
- Data/Domain:
  - Đảm bảo mutation mapping + error surface nhất quán.

**Acceptance criteria:**

- Leave group xong user không còn nhìn thấy conversation trong list sau refresh realtime/pull.
- Delete conversation thành công phản ánh cả local state + server state.

## Phase P1 (Parity & Product Completeness)

### P1.1 Expose group admin actions lên UI

**Goal:** Admin có thể promote/demote member từ member list.  
**Changes:**

- UI menu theo role hiện tại của user + target member.
- Dispatch events có sẵn trong `ChatMembersBloc`.
- Bảo vệ quyền ở UI lẫn xử lý lỗi permission từ backend.

### P1.2 Complete group metadata flow (create/update)

**Goal:** Field người dùng nhập phải tới backend đầy đủ (`description`, `avatar`, `groupType`, `adminIds`).  
**Changes:**

- Create group page: upload avatar + truyền description/groupType.
- Update group use case/repo: pass-through đầy đủ params.
- Mapper kiểm tra nullability thống nhất.

### P1.3 Search advanced + pagination đúng

**Goal:** Search feature đạt parity backend và load-more không lặp dữ liệu.  
**Changes:**

- Domain filter model mở rộng.
- Repository truyền page/size hoặc cursor rõ ràng.
- Bloc lưu state paging chuẩn: current page, hasMore, isLoadingMore, dedupe by messageId.

### P1.4 Implement delete history E2E

**Goal:** Có thể xóa lịch sử theo yêu cầu sản phẩm từ UI và sync đúng.  
**Changes:**

- Add use case + bloc event + UI confirm.
- Xác định scope xóa: theo conversation/by timestamp theo backend contract.
- Cập nhật local cache/index sau mutation.

### P1.5 Sync conversation realtime events

**Goal:** Join/leave group từ nơi khác phải reflect vào chat list mà không cần mở lại app.  
**Changes:**

- FE subscribe `conversation:joined`/`conversation:leaved`.
- Merge vào source of truth chat list.
- Nếu vẫn cần `chat_updated`, chuẩn hóa event aggregator để không conflict.

### P1.6 i18n cleanup trong chat area

**Goal:** Không còn hardcoded text trong các màn chat chính.  
**Changes:**

- Replace hardcoded string bằng `context.l10n`.
- Add key cho en/vi (và các locale khác đang support).
- Snapshot/widget test cho đa ngôn ngữ (ít nhất en + vi).

## Phase P2 (Future-proof / Optional by Product Decision)

### P2.1 Add `CALL` message type parity

**Goal:** Tin nhắn loại call không bị fallback sai hoặc hiển thị text generic.  
**Changes:**

- Extend content type enum/domain mapper.
- UI bubble cho call event (missed/ended/duration nếu backend cung cấp).

### P2.2 Clarify `message:file:upload` socket path

**Goal:** Chỉ implement nếu backend/client cần progress realtime ngoài GraphQL upload flow hiện tại.  
**Changes:**

- Làm rõ use case sản phẩm.
- Nếu cần: thêm progress event model + UI progress binding.

---

## 7) Test Strategy & Test Matrix

## 7.1 Unit Tests

- Mapper:
  - Socket delete payload -> domain model (happy path + malformed payload).
  - Message type mapping gồm `CALL`.
- Use cases:
  - Leave/Delete conversation.
  - Delete history.
  - Search advanced filter validation.
- BLoC:
  - ChatBloc/ChatMembersBloc/MessageSearchBloc action flow.
  - Paging state transitions (`idle -> loading -> success/error -> loadingMore`).

## 7.2 Widget Tests

- Chat info action buttons:
  - Leave group confirm/cancel/success/failure states.
  - Delete chat confirm/cancel/success/failure states.
- Member list:
  - Admin menu visible/hidden theo quyền.
- Search:
  - Infinite scroll load more không duplicate.
- i18n:
  - Render text đúng theo locale (`vi`, `en`).

## 7.3 Integration Tests

- Realtime:
  - Nhận `message:delete` từ socket -> UI update.
  - Nhận `conversation:joined/leaved` -> list update.
- Conversation actions:
  - Leave/delete thành công -> navigation và state sync.
- Search:
  - Page 1 + page 2 + dedupe + hasMore false.

## 7.4 Contract Tests (Recommended)

- Tạo contract test nhỏ cho GraphQL input/output:
  - `chatMessageDeleteHistory`
  - `chatSearch` filter object
  - `chatConversationLeave` / `chatConversationDelete`
- Tạo fixture socket payload theo backend schema thực tế.

---

## 8) i18n Plan (Required)

### 8.1 Key naming convention

- Prefix theo feature: `chat.*`
- Ví dụ:
  - `chat.leaveGroup.title`
  - `chat.leaveGroup.confirm`
  - `chat.deleteChat.title`
  - `chat.location.permissionDenied`

### 8.2 Minimum locales

- `en` và `vi` là bắt buộc.
- Các locale khác theo baseline app hiện tại.

### 8.3 Guardrails

- CI check fail nếu còn hardcoded string ở feature chat (ngoại trừ test data/dev-only logs).

---

## 9) Definition of Done (DoD)

Một hạng mục chỉ được coi là hoàn tất khi:

1. Đã merge đầy đủ 3 layer (data/domain/presentation) nếu có thay đổi hành vi.
2. Có unit test + widget test tương ứng, test pass trong CI.
3. Không thêm hardcoded text mới; key i18n đủ cho `vi/en`.
4. Không dùng widget raw nếu dự án đã có equivalent trong design system.
5. Được verify thủ công trên ít nhất:
   - 1-1 chat
   - group chat
   - online/offline transition

---

## 10) Rollout Plan & Risk Control

### 10.1 Rollout order

1. P0.1 realtime delete fix.
2. P0.2 leave/delete conversation.
3. P1.5 conversation realtime events.
4. P1.3 search paging/filter.
5. P1.1 + P1.2 + P1.4 + P1.6.
6. P2 items theo product decision.

### 10.2 Key risks

- Event schema drift giữa backend và mobile.
- Regression do sửa state sync và pagination.
- UI inconsistencies nếu không bám design system.

### 10.3 Mitigation

- Contract fixtures versioned.
- Feature flags cho các luồng có rủi ro cao (nếu cần).
- Test automation bắt buộc cho realtime + destructive flows.

---

## 11) Suggested Jira/Epic Structure

- **Epic:** Chat Backend Parity
- **Stories:**
  - P0-RealtimeDeleteMapping
  - P0-LeaveDeleteConversationE2E
  - P1-ConversationRealtimeParity
  - P1-SearchAdvancedAndPagination
  - P1-GroupAdminUI
  - P1-GroupMetadataParity
  - P1-DeleteHistoryE2E
  - P1-ChatI18nCleanup
  - P2-CallMessageTypeSupport
  - P2-FileUploadSocketFlow (conditional)

---

## 12) Final Recommendation

Ưu tiên xử lý P0 ngay trong sprint hiện tại để đảm bảo **data correctness** và **user trust** cho realtime chat.  
Sau đó gom P1 theo cụm “conversation consistency + search + admin controls” để giảm overhead review/QA và giữ kiến trúc sạch, dễ maintain, dễ scale.
