# Architecture & Migration Plan (Single Source of Truth)

## Goal
Unify configuration, auth/token, GraphQL, and realtime into a single maintainable architecture suitable for large Flutter chat apps.

## Key Decisions
- Authoritative GraphQL layer: `lib/core/network/graphql_client.dart`
- Architecture style: Feature-first + Clean Architecture (presentation/domain/data) + BLoC
- Principle: each concern has exactly one authoritative implementation

## Non-Negotiable Rules
- **Single Source of Truth** for:
  - endpoints/environment
  - token storage + refresh
  - GraphQL client wrapper
  - realtime facade
- **No random defaults** in staging/production builds (fail fast if config is missing)
- **Domain layer is pure** (no Flutter/IO/GraphQL/SharedPreferences imports)

## Phased Migration (PR-sized steps)

### PR0 — Environment/Endpoint Unification (Foundation)
**Outcome**: app always loads the correct env file per flavor; GraphQL/Socket endpoints are consistent.

- Update startup order in `main.dart`:
  - load dotenv for the active flavor
  - then run DI
  - then initialize `EnvironmentManager`
- Ensure `.env.staging` and `.env.production` contain:
  - `GRAPHQL_API_URL`
  - `GRAPHQL_WS_URL`
  - `SOCKET_URL`
- Add startup validation (warn in debug; fail in release if missing/placeholder)

Acceptance checklist:
- staging/prod builds do not use placeholder domains
- GraphQL HTTP and WS endpoints come from the selected env file

### PR1 — TokenModule (Single Token System)
**Outcome**: one token source, one storage, one refresh orchestration.

- Introduce `TokenRepository` + `TokenStorage` (SecureStorage)
- Standardize keys: `access_token`, `refresh_token`
- Add refresh lock + retry policy

Acceptance checklist:
- no duplicate token keys in SharedPreferences
- refresh flow end-to-end (no TODO)

### PR2 — GraphQL Wrapper Uses TokenRepository
**Outcome**: GraphQL auth header and subscription payload are always correct.

- Update `GraphQLClientWrapperImpl` to read token via `TokenRepository`
- Implement UNAUTHENTICATED -> refresh -> retry (once)

Acceptance checklist:
- all queries/mutations go through `core/network/graphql_client.dart`

### PR3 — Auth Login Matches Backend Reference
**Outcome**: login matches `@.kiro/BACKEND_API_REFERENCE.md`.

- Update login mutation/DTO mapping to `accessToken`, `refreshToken`, user fields
- Persist tokens via `TokenRepository`

### PR4 — Realtime Unification
**Outcome**: one realtime facade with correct auth + reconnect behavior.

- Single realtime facade (`RealtimeService`)
- Socket connect includes token; token changes trigger reconnect
- Standardize join/leave/events

## Regression Checklist (Run per PR)
- login/logout
- load conversations
- open conversation + pagination
- send message
- receive realtime message
- offline/online switching

## Status
- PR0: planned
- PR1: planned
- PR2: planned
- PR3: planned
- PR4: planned
