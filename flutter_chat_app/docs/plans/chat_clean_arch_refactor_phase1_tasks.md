# Chat Phase 1 Refactor Task Board

Date: 2026-03-04

## Epic 1: Draft Architecture Refactor (5.1)

- [x] T1.1 Add `ChatDraftModel` (Isar) and register schema in `DatabaseService`.
- [x] T1.2 Add `ChatDraftEntity` and `IDraftRepository`.
- [x] T1.3 Implement `DraftLocalDataSource` (Isar) and `DraftRepositoryImpl`.
- [x] T1.4 Add draft usecases: get/save/remove/watch.
- [x] T1.5 Create `ChatDraftBloc` with debounced autosave + pending clear reconciliation.
- [x] T1.6 Wire `ChatDetailsPage` to `ChatDraftBloc` (remove page-driven persistence logic).
- [x] T1.7 Wire `ChatListPage` and `ChatListPanel` to bloc draft map for preview.
- [x] T1.8 Remove `ChatDraftService` and DI registration.

## Epic 2: Slash Command Refactor (5.3)

- [x] T2.1 Move slash command execution decision to bloc/use-case flow.
- [x] T2.2 Keep parser pure and deterministic; UI only for suggestions/feedback rendering.
- [x] T2.3 Add tests for command parse + execution mapping.

## Epic 3: Keyboard Shortcut Refactor (5.2)

- [x] T3.1 Keep shortcut capture in UI, dispatch stateful actions to bloc.
- [x] T3.2 Ensure no business side-effects handled directly in page shortcuts.
- [x] T3.3 Add regression checks for desktop/web shortcuts.

## Verification

- [x] V1 Run `dart run build_runner build --delete-conflicting-outputs`.
- [x] V2 Run `dart analyze` for modified scope.
- [x] V3 Run impacted tests (draft + chat presentation where available).

## Progress Log

- 2026-03-04: Plan and task board created.
- 2026-03-04: Completed draft clean architecture stack (Isar model/datasource/repository/usecases/bloc) and removed ChatDraftService from active flow.
- 2026-03-04: Wired ChatDetailsPage, ChatListPage, ChatListPanel to bloc-based draft state.
- 2026-03-04: Added ChatComposerBloc and moved slash-command send + dismiss shortcut decision logic out of page.
- 2026-03-04: Ran build_runner successfully. Analyzer on modified scope still has pre-existing warnings in core files.
- 2026-03-04: Added unit tests for slash parser, composer execution mapping, shortcut dismiss mapping, and draft lifecycle reconciliation.
- 2026-03-04: Ran targeted `flutter test` for new test suites (all passed) and targeted `dart analyze` for tests + modified scope.
