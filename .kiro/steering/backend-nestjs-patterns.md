---
inclusion: fileMatch
fileMatchPattern: "src/**/*.ts"
---

# NestJS Backend Patterns

> Rules and patterns for the NestJS backend. GraphQL-first, module-based architecture.

## Key Source Files

- App module: #[[file:src/app.module.ts]]
- Chat module: #[[file:src/modules/chat/chat.module.ts]]
- Chat resolver: #[[file:src/modules/chat/chat.resolver.ts]]
- Chat args: #[[file:src/modules/chat/chat.args.ts]]
- Error handling: #[[file:src/common/office.error.ts]]
- Error interceptor: #[[file:src/interceptors/error.interceptor.ts]]
- Guard: #[[file:src/guards/gql-throttler.guard.ts]]
- Base model: #[[file:src/models/office.base.ts]]

## Architecture

- Modules in `src/modules/{feature}/` with service, resolver, args, response files
- Models/entities in `src/models/entities/`
- Shared code in `src/common/`, `src/helpers/`, `src/utils/`
- Path aliases: `@common/*`, `@models/*`, `@core/*`, `@modules/*`, `@services/*`

## Module Pattern

```typescript
@Module({
  imports: [TypeOrmModule.forFeature([Entity]), CommonModule],
  providers: [FeatureService, FeatureResolver],
  exports: [FeatureService],
})
export class FeatureModule {}
```

## Service Pattern

- `@Injectable()` decorator
- Constructor injection with `private readonly`
- Use LoggerService for logging
- Cache with Redis (check cache → fetch DB → cache result)
- Wrap DB writes in transactions when needed

## GraphQL Pattern

- Code-first with decorators (`@ObjectType`, `@InputType`, `@Resolver`, `@Query`, `@Mutation`)
- Validation via class-validator (`@IsNotEmpty`, `@IsEmail`, `@MinLength`, etc.)
- Custom validators in `src/decorators/validation/`
- Errors: throw `OfficeError(code, message, statusCode)` from `src/common/office.error.ts`

## Naming

- Files: `kebab-case.ts` (e.g., `chat-message.service.ts`)
- Classes: `PascalCase`
- Variables/methods: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`

## Key Principles

- Validate all inputs with class-validator
- Cache aggressively with Redis + TTL
- Use Bull queues for background jobs (retry: 3, exponential backoff)
- Auth via Bearer JWT token, verified in GlobalGuard
- Log important operations, handle errors gracefully
- Multi-database: PostgreSQL (TypeORM), DynamoDB, Redis
- Real-time: Socket.IO with Redis adapter
