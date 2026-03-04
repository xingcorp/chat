# Chat Phase 1 Clean Architecture Refactor Plan

Date: 2026-03-04
Owner: Chat Team (Senior-guided)
Scope: Refactor Draft UX (5.1), Keyboard Shortcuts (5.2), Slash Commands (5.3) to align with project architecture.

## 1. Problem Statement

Current implementation delivers features but violates target architecture boundaries in several places:

1. Draft persistence implemented as `core/services` with page-driven business logic.
2. `ChatDetailsPage` contains complex draft lifecycle decisions (restore/autosave/clear-on-ack) that should live in BLoC/domain.
3. Chat list preview depends on service listenable instead of repository/use case + bloc state pipeline.
4. Slash command execution path is page-centric instead of use-case-driven orchestration.

This creates maintainability risk, weak testability, and inconsistent dependency direction.

## 2. Target Architecture

### 2.1 Dependency Direction

`Presentation (Page/Widget) -> BLoC -> UseCase -> Repository Interface -> Repository Impl -> Local DataSource (Isar)`

### 2.2 Draft Module (5.1)

1. Domain
- `ChatDraftEntity`
- `IDraftRepository`
- UseCases: `GetDraft`, `SaveDraft`, `RemoveDraft`, `WatchDrafts`

2. Data
- `ChatDraftModel` (Isar collection)
- `DraftLocalDataSource`
- `DraftRepositoryImpl` returning `Either<Failure, T>`

3. Presentation
- `ChatDraftBloc` as single source of truth for draft map + pending-clear reconciliation.
- Page only dispatches events and renders state.
- Chat list preview reads from bloc state, not core service.

### 2.3 Shortcuts (5.2)

1. Keep keyboard capture in presentation layer.
2. Move decision handling to bloc events where business decisions are involved.
3. Keep UI-level focus behavior in page/widget.

### 2.4 Slash Commands (5.3)

1. Keep parser/transform as pure engine (domain/presentation-model boundary).
2. Move execution policy to bloc/use case path.
3. Page only triggers command execution event and displays UI feedback.

## 3. Refactor Principles

1. No business persistence logic directly inside page state.
2. No feature-specific persistence service under `core/services`.
3. All new persistence must pass through repository contracts.
4. Keep backward-compatible UX while replacing internals.
5. Incremental migration: wire new architecture first, then remove legacy path.

## 4. Phased Execution

### Phase A - Foundation (Draft data/domain)

1. Add `ChatDraftModel` Isar schema.
2. Register schema in `DatabaseService` (web + native).
3. Create `ChatDraftEntity`, `IDraftRepository`, and draft usecases.
4. Implement local datasource + repository with error mapping.

Acceptance:
- Unit-testable draft data path exists independent of UI.

### Phase B - Presentation State Refactor (Draft)

1. Create `ChatDraftBloc` with:
- watch all drafts
- debounced save
- remove draft
- pending-send reconciliation (clear on success, keep on fail)
2. Replace `ChatDetailsPage` direct draft service usage with bloc events.
3. Replace chat list draft preview dependency from service listenable to bloc state.

Acceptance:
- No direct `ChatDraftService` usage in `ChatDetailsPage`, `ChatListPage`, `ChatListPanel`.

### Phase C - Slash/Shortcut Orchestration

1. Move slash command execution decision out of page imperative branch to bloc event handling.
2. Keep keyboard intent mapping in UI, dispatch action events to bloc for stateful behavior.

Acceptance:
- Page logic reduced to view concerns + event dispatch.

### Phase D - Cleanup + Hardening

1. Remove legacy `ChatDraftService` and DI registration.
2. Add regression tests for draft lifecycle.
3. Run analyzer + verify no architecture regression.

## 5. Risks and Mitigation

1. Risk: Draft clear timing mismatch.
- Mitigation: retain reconciliation against delivered messages and guard with pending token.

2. Risk: Extra rebuilds in chat list.
- Mitigation: bloc state map diff + lightweight preview resolver.

3. Risk: Isar schema migration issues.
- Mitigation: additive schema only, no destructive migration.

## 6. Deliverables

1. Architecture-compliant draft stack (domain/data/presentation).
2. Updated chat pages wired to bloc-based draft state.
3. Task board + implementation progress log.
4. Analyzer-clean changed modules.

## 7. Definition of Done

1. Feature parity maintained for 5.1/5.2/5.3 behaviors.
2. New code follows project clean architecture boundaries.
3. No feature-specific persistence logic in page state.
4. No `ChatDraftService` references in active chat presentation flow.
5. Static analysis passes for modified files.
