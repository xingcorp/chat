---
name: status
description: Analyze current project status — completion percentage, working vs broken features, next priorities, effort estimates
---

# Project Status Analysis

Use this skill to analyze the current state of the Sharitek Office Chat project and recommend next actions.

## Steps

### 1. Read Project Status

- Read `.kiro/PROJECT_STATUS_ANALYSIS.md` for the full gap analysis
- Read `.kiro/steering/project-architecture.md` for architecture overview
- Read `AGENTS.md` for current known issues

### 2. Check Current Implementation

- Scan `flutter_chat_app/lib/domain/usecases/` for implemented use cases
- Scan `flutter_chat_app/lib/data/graphql/` for GraphQL operations
- Scan `flutter_chat_app/lib/presentation/blocs/` for BLoC implementation
- Check `flutter_chat_app/lib/core/services/` for real-time event coverage
- Check dual-mode integration files:
  - `flutter_chat_app/lib/chat_module.dart` — lifecycle completeness
  - `flutter_chat_app/lib/core/di/chat_module_injection.dart` — package DI coverage
  - `flutter_chat_app/lib/flutter_chat_module.dart` — public API completeness

### 3. Report

Provide a concise status report:
- Overall completion percentage
- What's working vs what's broken
- Dual-mode (standalone vs package) status
- Next highest-priority tasks
- Estimated effort for each task

### 4. Suggest Next Action

Based on the analysis, recommend the single most impactful thing to work on next, considering both deployment modes.

## Known Issues (as of last analysis)

- **35% overall completion**
- GraphQL operations use WRONG names (Flutter ≠ Backend)
- UseCase layer mostly EMPTY (needs 15+ use cases)
- Real-time events only 40% implemented (missing reactions, edit, delete)
- Socket events missing: `message:reaction`, `message:edit`, `message:delete`, `conversation:leaved`, `message:file:upload`
