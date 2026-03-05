# Backend NestJS Rules
# Applies to: src/**/*.ts

## Module Pattern
- Modules in `src/modules/{feature}/` with service, resolver, args, response files
- Models/entities in `src/models/entities/`
- Shared code in `src/common/`, `src/helpers/`, `src/utils/`
- Path aliases: `@common/*`, `@models/*`, `@core/*`, `@modules/*`, `@services/*`

## GraphQL Pattern (Code-First)
- Use decorators: `@ObjectType`, `@InputType`, `@Resolver`, `@Query`, `@Mutation`
- Validation via class-validator: `@IsNotEmpty`, `@IsEmail`, `@MinLength`, etc.
- Errors: throw `OfficeError(code, message, statusCode)` from `src/common/office.error.ts`

## Service Pattern
- `@Injectable()` decorator
- Constructor injection with `private readonly`
- Use LoggerService for logging
- Cache with Redis: check cache → fetch DB → cache result
- Wrap DB writes in transactions when needed

## Naming
- Files: `kebab-case.ts` (e.g., `chat-message.service.ts`)
- Classes: `PascalCase`
- Variables/methods: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`

## Database
- PostgreSQL via TypeORM for Conversations, Members
- DynamoDB for Messages (high-throughput)
- Redis for caching + Pub/Sub
- OpenSearch for message search

## Key Principles
- Validate all inputs with class-validator
- Cache aggressively with Redis + TTL
- Use Bull queues for background jobs (retry: 3, exponential backoff)
- Auth via Bearer JWT token, verified in GlobalGuard
- Real-time: Socket.IO with Redis adapter
