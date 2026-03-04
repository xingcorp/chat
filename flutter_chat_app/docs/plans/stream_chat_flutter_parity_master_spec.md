# Stream Chat Flutter Parity - Master Spec va Roadmap

> Date: 2026-03-04  
> Scope: Toan bo cac gap da doi chieu giua `stream_chat_flutter` va app hien tai  
> Muc tieu uu tien: Trien khai truoc cac phan khong can backend

---

## 1. Muc tieu

1. Dat do phu tinh nang chat gan voi bo `stream_chat_flutter` nhung van phu hop kien truc hien tai.
2. Uu tien cac tinh nang co the ship som ma khong can backend moi.
3. Chia phase ro rang theo dependency:
   - Frontend-only
   - Frontend + backend hien co
   - Frontend + backend contract moi
4. Co tieu chi nghiem thu va ke hoach rollout/risk cho tung nhom tinh nang.

---

## 2. Pham vi gap can xu ly

### 2.1 Gap chinh so voi `stream_chat_flutter`

1. Polls (tao poll, vote, ket qua, comments).
2. Threads (thread list, unread thread banner, thread detail flow).
3. Draft UX day du (draft persistence + draft preview/list cap channel).
4. Slash command autocomplete (kieu `/command`).
5. AI assistant chat UI (typing state, streaming/typewriter output).
6. Moderation UI message-level (co bo hanh dong moderation ro rang).
7. Keyboard shortcuts cho desktop chat productivity.

### 2.2 Cac diem "chua dat" trong app hien tai

1. `ChatInfoPanel` bo qua check block status o direct chat.
2. `ChatBloc` khai bao event nhung chua handle day du.
3. Contract message/backend chua mo cho poll/thread/ai.

---

## 3. Nguyen tac trien khai

1. Khong pha vo clean architecture hien tai (domain/data/presentation).
2. Dung feature flag cho cac nhom tinh nang lon.
3. Uu tien backward compatibility voi data cu.
4. Real-time va offline-first la yeu cau bat buoc cho message-critical flow.
5. Frontend ship theo "vertical slice" de co gia tri ngay, sau do mo rong backend.

---

## 4. Ma tran uu tien va dependency

| Feature | Gia tri nguoi dung | Can backend moi | Uu tien | Phase |
|---|---|---|---|---|
| Draft UX day du | Cao | Khong | P0 | Phase 1 |
| Keyboard shortcuts | Trung binh-cao (desktop) | Khong | P0 | Phase 1 |
| Slash command local | Trung binh | Khong (ban dau) | P1 | Phase 1 |
| Moderation UI shell + flow co san | Trung binh | Khong (ban dau) | P1 | Phase 1 |
| ChatInfo block status fix | Trung binh | Khong | P0 | Phase 1 |
| Hoan tat ChatBloc handlers thieu | Cao (on dinh) | Khong | P0 | Phase 1 |
| Polls day du | Cao (group chat) | Co | P1 | Phase 3 |
| Threads day du | Cao | Co | P1 | Phase 4 |
| AI assistant UI + stream response | Trung binh-cao | Co | P2 | Phase 5 |

---

## 5. Roadmap theo phase

## Phase 0 - Foundation va ky thuat chung (3-5 ngay)

### Muc tieu

1. Khoa pham vi va tao nen tang cho rollout an toan.
2. Chuan hoa feature flag, analytics event, va test baseline.

### Deliverables

1. Feature flags:
   - `chat.draft_v2`
   - `chat.shortcuts`
   - `chat.commands_v1`
   - `chat.moderation_v1`
   - `chat.polls_v1`
   - `chat.threads_v1`
   - `chat.ai_v1`
2. Dashboard KPI co ban:
   - Message send success rate
   - Draft restore rate
   - Shortcut usage rate
   - Search-to-jump success rate
3. Regression test baseline cho chat detail/list.

### Acceptance criteria

1. Tat ca flag co default an toan (off cho feature moi lon).
2. Co script/bang huong dan bat/tat flag theo environment.

---

## Phase 1 - Frontend-only (uu tien ship som) (2-3 tuan)

## 5.1 Draft UX V2 (khong can backend)

### Scope

1. Luu draft theo conversation id (text + metadata co ban).
2. Khoi phuc draft khi mo lai conversation.
3. Hien draft preview tren chat list item.
4. Draft lifecycle:
   - Auto-save debounce 300-500ms
   - Clear draft khi send thanh cong
   - Keep draft khi send fail/thoat man hinh

### Kien truc

1. Domain:
   - `DraftEntity { conversationId, text, updatedAt, mentionState }`
   - `IDraftRepository`
2. Data:
   - Isar/SharedPreferences datasource (uu tien Isar de dong bo voi offline)
3. Presentation:
   - Hook vao `ChatDetailsPage` input controller
   - Hook vao chat list item subtitle (`draft` > `lastMessage`)

### Acceptance criteria

1. Thoat vao lai chat, draft duoc phuc hoi dung 100%.
2. Gui message thanh cong thi draft bi xoa.
3. Chat list hien "Draft: ..." neu co draft.

### Test

1. Unit: repository save/load/remove.
2. Bloc/widget: auto-save debounce.
3. Integration: open chat -> type -> back -> reopen -> draft present.

## 5.2 Keyboard shortcuts (desktop/web)

### Scope

1. `Enter` send, `Shift+Enter` newline.
2. `Esc` thoat selection mode/clear reply-edit mode.
3. `Ctrl/Cmd+F` mo search panel.
4. `Ctrl/Cmd+K` focus message input.
5. `Ctrl/Cmd+Shift+C` copy selected messages (khi selection mode).

### Acceptance criteria

1. Shortcut khong xung dot voi text input logic.
2. Hoat dong tren macOS/Windows/web desktop.

## 5.3 Slash command V1 (local command engine)

### Scope

1. Command parser frontend:
   - `/shrug`, `/tableflip`, `/me <text>`, `/mute` (ui action)
2. Command autocomplete dropdown khi user go `/`.
3. Command validation + preview.

### Backend

1. Khong can backend trong V1 (command transform thanh text/system action local).

### Acceptance criteria

1. Dropdown hien command suggestion realtime.
2. Execute command thanh message/action hop le.

## 5.4 Moderation UI V1 (shell + flow san co)

### Scope

1. Bo sung menu moderation trong long press action:
   - Report message
   - Block user (neu direct)
   - Hide message local
2. UI state `hidden locally` cho message (chi client-side, khong xoa server).
3. Tach ro message action thong thuong va moderation action.

### Backend

1. Tan dung API report/block da co.
2. Chua can API moderation moi trong V1.

### Acceptance criteria

1. User report/block duoc tu action sheet.
2. Hide local ton tai toi khi user unhide hoac refresh policy da define.

## 5.5 Fix `ChatInfoPanel` block status va hoan tat `ChatBloc` handlers

### Scope

1. Bat lai check block status cho direct chat trong `ChatInfoPanel`.
2. Implement day du event handlers da khai bao nhung chua dang ky/hoat dong:
   - `_LoadMessages`
   - `_SendMessage`
   - `_AddUsersToChat`
   - `_RemoveUsersFromChat`
   - `_SyncChats`
   - `_SyncMessages`
   - `_MessageStatusUpdated`
3. Dam bao khong event nao "dead declaration".

### Acceptance criteria

1. Khong con event declared-but-not-handled.
2. Block status direct chat load dung.

---

## Phase 2 - Frontend + backend hien co (1-2 tuan)

## 6.1 Hardening va parity UX

### Scope

1. Nang cap message action sheet theo nhom (reply/edit/forward + moderation).
2. Nang cap search panel:
   - Better pagination trigger
   - Error/retry states tinh gon
3. Read receipt va unread separator polish (desktop/mobile parity).
4. Tinh chinh mention UX:
   - Improve keyboard nav trong mention popup
   - Mention formatting consistency khi edit message

### Acceptance criteria

1. Khong doi contract backend.
2. Trac nghiem UX voi 3 profile: 1-1, group nho, group lon.

---

## Phase 3 - Polls V1 (can backend moi) (2-3 tuan)

## 7.1 User stories

1. Group admin/member tao poll trong room.
2. Thanh vien vote 1 hoac nhieu lua chon (tuy setting).
3. Xem ket qua vote realtime.
4. Xem danh sach nguoi vote tung option.
5. Dong poll.

## 7.2 Backend contract de xuat

### GraphQL

1. Mutation:
   - `chatPollCreate`
   - `chatPollVote`
   - `chatPollClose`
2. Query:
   - `chatPollDetail(pollId)`
   - `chatPollVotes(pollId, optionId, page, size)`

### Socket events

1. `poll:created`
2. `poll:updated`
3. `poll:voted`
4. `poll:closed`

## 7.3 Data model frontend

1. `ContentType.poll` trong message entity.
2. `PollPayload { id, question, options[], allowMulti, isClosed, totalVotes }`
3. Mapper DTO <-> entity.

## 7.4 UI

1. Poll creator dialog trong input attachment actions.
2. Poll message card trong timeline.
3. Poll result sheet, option voters sheet.

## 7.5 Acceptance criteria

1. Tao poll thanh cong, room nhan realtime trong <1s.
2. Vote update khong can refresh.
3. Offline vote duoc queue va retry dung.

---

## Phase 4 - Threads V1 (can backend moi) (3-4 tuan)

## 8.1 User stories

1. User mo thread tu 1 message goc.
2. Gui/reply trong thread rieng.
3. Xem unread thread count/banner.
4. Tu thread co the jump ve message goc.

## 8.2 Backend contract de xuat

### Message schema

1. Add fields:
   - `threadRootMessageId`
   - `parentMessageId`
   - `replyCount`
   - `threadParticipants[]`
2. Query:
   - `chatThreadMessages(rootMessageId, cursor, size)`
   - `chatThreadList(conversationId, cursor, size)`

### Socket events

1. `thread:message_added`
2. `thread:updated`
3. `thread:read`

## 8.3 UI

1. Thread entrypoint trong message action.
2. Thread screen/panel:
   - Header message goc
   - Thread message list
   - Input rieng
3. Unread thread banner o chat room.

## 8.4 Acceptance criteria

1. Thread timeline tach biet voi main timeline.
2. Reply count tren message goc cap nhat realtime.
3. Jump qua lai root <-> thread on dinh.

---

## Phase 5 - AI assistant V1 + Moderation V2 (can backend moi) (3-4 tuan)

## 9.1 AI assistant V1

### User stories

1. User goi AI trong conversation hoac AI room.
2. Hien trang thai AI:
   - thinking
   - checking sources
   - streaming response
3. Message AI stream token-by-token.

### Backend contract de xuat

1. Endpoint/Mutation:
   - `chatAiGenerate(conversationId, prompt, context)`
2. Streaming channel:
   - WebSocket event `ai:token`
   - WebSocket event `ai:state`
   - WebSocket event `ai:done`

### Frontend

1. Render component cho:
   - typing indicator AI
   - streaming message bubble
2. Fallback polling neu websocket stream fail.

### Acceptance criteria

1. Time-to-first-token dat muc tieu <= 1.5s (staging target).
2. Stream token on dinh, co retry/fail-safe.

## 9.2 Moderation V2 (server-driven)

### Scope

1. Message moderation status tu server:
   - pending_review
   - blocked
   - allowed
2. UI `moderated message` placeholder.
3. Action cho moderator role.

### Backend

1. Message field `moderationStatus`.
2. Events `message:moderated`.

### Acceptance criteria

1. Message bi block khong render content goc.
2. Moderator action cap nhat realtime.

---

## 6. Kien truc chung cho cac phase backend-required

## 10.1 Compatibility strategy

1. Schema additions phai optional de client cu khong crash.
2. Mapper fallback:
   - Neu field moi null => bo qua, fallback UI cu.
3. Rollout backend truoc, frontend sau (flag off), roi bat canary.

## 10.2 Offline-first strategy

1. Moi action moi (vote poll, thread reply, AI request) phai co queue policy:
   - optimistic allowed?
   - retry policy
   - dedupe key
2. Tombstone/merge strategy khong duoc pha vo.

## 10.3 Telemetry

1. Bat buoc log event cho:
   - feature opened
   - action success/fail
   - latency bucket
2. Khong log PII text message.

---

## 7. Work breakdown va uoc luong

| Workstream | Effort (ideal days) | Backend dependency |
|---|---:|---|
| Foundation + flags + baseline tests | 3-5 | No |
| Draft UX V2 | 4-6 | No |
| Keyboard shortcuts | 2-3 | No |
| Slash command V1 | 3-4 | No |
| Moderation UI V1 | 3-5 | No |
| ChatInfo + ChatBloc completion | 3-4 | No |
| Hardening parity UX | 4-6 | Existing only |
| Polls V1 (FE) | 6-8 | Yes |
| Polls V1 (BE) | 6-10 | Yes |
| Threads V1 (FE) | 8-12 | Yes |
| Threads V1 (BE) | 8-12 | Yes |
| AI V1 (FE) | 6-8 | Yes |
| AI V1 (BE) | 8-12 | Yes |

---

## 8. Ke hoach release

## 12.1 Milestone de xuat

1. M1 (cuoi Phase 1): Ship frontend-only stack sau feature flag.
2. M2 (cuoi Phase 2): On dinh UX, giam debt state/event.
3. M3 (cuoi Phase 3): Polls GA cho group pilot.
4. M4 (cuoi Phase 4): Threads GA theo tenant rollout.
5. M5 (cuoi Phase 5): AI + Moderation V2 canary -> GA.

## 12.2 Rollout strategy

1. Canary 5% -> 20% -> 50% -> 100%.
2. Co rollback nhanh theo feature flag.
3. Monitor saturation:
   - crash-free sessions
   - message send success
   - socket reconnect rate

---

## 9. Risk va giam thieu

1. Risk: Thread/poll lam phuc tap merge/offline  
   Mitigation: Prototype merge strategy truoc khi mo UI.
2. Risk: AI streaming gay qua tai socket  
   Mitigation: Rate limit + separate stream channel.
3. Risk: Keyboard shortcuts xung dot editor behavior  
   Mitigation: Shortcuts test matrix theo platform.
4. Risk: Draft preview gay nhieu re-render chat list  
   Mitigation: Cache draft summary + update incremental.

---

## 10. Definition of Done (DoD)

1. Co unit test + widget/integration test cho feature moi.
2. Co analytics events va dashboard theo doi.
3. Co documentation update (API + troubleshooting).
4. Khong co regression tren:
   - Send/edit/delete/reaction/reply/forward
   - Offline queue
   - Realtime sync
5. Feature flag va rollback verified.

---

## 11. Quy tac "khong can backend len truoc"

Cac hang muc duoi day duoc uu tien lam ngay:

1. Draft UX V2.
2. Keyboard shortcuts.
3. Slash command V1 (local).
4. Moderation UI V1.
5. ChatInfo block status fix.
6. ChatBloc missing handlers completion.

Chi khi cac muc tren on dinh (M1) moi bat dau mo rong phase backend-required.

