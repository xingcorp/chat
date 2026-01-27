---
title: Backend NestJS Patterns & Best Practices
inclusion: conditional
fileMatchPattern: "src/**/*.ts"
priority: medium
---

# NestJS Backend Patterns & Best Practices

## Module Structure

### Standard Module Pattern
```typescript
// feature.module.ts
@Module({
  imports: [
    TypeOrmModule.forFeature([FeatureEntity]),
    CommonModule,
  ],
  providers: [
    FeatureService,
    FeatureResolver,
    FeatureRepository,
  ],
  controllers: [FeatureController],
  exports: [FeatureService],
})
export class FeatureModule {}
```

### Service Pattern
```typescript
// feature.service.ts
@Injectable()
export class FeatureService {
  private readonly logger = new LoggerService(FeatureService.name);
  
  constructor(
    private readonly featureRepo: FeatureRepository,
    private readonly cacheService: RedisService,
    @InjectConnection() private readonly connection: Connection,
  ) {}
  
  async findById(id: string): Promise<Feature> {
    // Check cache first
    const cached = await this.cacheService.get(`feature:${id}`);
    if (cached) {
      return JSON.parse(cached);
    }
    
    // Fetch from database
    const feature = await this.featureRepo.findOne({ where: { id } });
    if (!feature) {
      throw new NotFoundException(`Feature ${id} not found`);
    }
    
    // Cache result
    await this.cacheService.set(
      `feature:${id}`,
      JSON.stringify(feature),
      3600, // TTL: 1 hour
    );
    
    return feature;
  }
  
  async create(input: CreateFeatureInput): Promise<Feature> {
    const feature = this.featureRepo.create(input);
    
    try {
      const saved = await this.featureRepo.save(feature);
      this.logger.info('Feature created', { id: saved.id });
      return saved;
    } catch (error) {
      this.logger.error('Failed to create feature', error);
      throw new InternalServerErrorException('Failed to create feature');
    }
  }
}
```

## GraphQL Patterns

### Resolver Pattern
```typescript
// feature.resolver.ts
@Resolver(() => Feature)
export class FeatureResolver {
  constructor(private readonly featureService: FeatureService) {}
  
  @Query(() => Feature, { nullable: true })
  async feature(@Args('id', { type: () => ID }) id: string): Promise<Feature | null> {
    return this.featureService.findById(id);
  }
  
  @Query(() => [Feature])
  async features(
    @Args('filter', { nullable: true }) filter?: FeatureFilter,
    @Args('page', { type: () => Int, defaultValue: 1 }) page?: number,
    @Args('size', { type: () => Int, defaultValue: 20 }) size?: number,
  ): Promise<Feature[]> {
    return this.featureService.findAll(filter, page, size);
  }
  
  @Mutation(() => Feature)
  async createFeature(
    @Args('input') input: CreateFeatureInput,
    @Context() context: any,
  ): Promise<Feature> {
    const userId = context.req.user?.id;
    return this.featureService.create(input, userId);
  }
  
  @ResolveField(() => User)
  async creator(@Parent() feature: Feature): Promise<User> {
    return this.featureService.getCreator(feature.creatorId);
  }
}
```

### Input/Output Types
```typescript
// feature.args.ts
@InputType()
export class CreateFeatureInput {
  @Field()
  @IsNotEmpty()
  @Length(3, 100)
  name: string;
  
  @Field({ nullable: true })
  @MaxLength(500)
  description?: string;
  
  @Field(() => FeatureType)
  @IsEnum(FeatureType)
  type: FeatureType;
  
  @Field(() => [String], { nullable: true })
  @IsArray()
  @IsUUID('4', { each: true })
  tagIds?: string[];
}

@InputType()
export class FeatureFilter {
  @Field({ nullable: true })
  keyword?: string;
  
  @Field(() => FeatureType, { nullable: true })
  type?: FeatureType;
  
  @Field(() => [String], { nullable: true })
  tagIds?: string[];
  
  @Field(() => DateRange, { nullable: true })
  dateRange?: DateRange;
}

// feature.response.ts
@ObjectType()
export class Feature {
  @Field(() => ID)
  id: string;
  
  @Field()
  name: string;
  
  @Field({ nullable: true })
  description?: string;
  
  @Field(() => FeatureType)
  type: FeatureType;
  
  @Field(() => User)
  creator: User;
  
  @Field(() => [Tag], { nullable: true })
  tags?: Tag[];
  
  @Field()
  createdAt: Date;
  
  @Field()
  updatedAt: Date;
}

@ObjectType({ implements: PagingData })
export class FeatureListResponse implements PagingData {
  total: number;
  count: number;
  
  @Field(() => [Feature])
  records: Feature[];
}
```

## Database Patterns

### Repository Pattern
```typescript
// feature.repository.ts
@Injectable()
export class FeatureRepository extends Repository<FeatureEntity> {
  constructor(
    @InjectRepository(FeatureEntity)
    private readonly repository: Repository<FeatureEntity>,
  ) {
    super(repository.target, repository.manager, repository.queryRunner);
  }
  
  async findWithRelations(id: string): Promise<FeatureEntity | null> {
    return this.repository.findOne({
      where: { id },
      relations: ['creator', 'tags'],
    });
  }
  
  async findByFilter(filter: FeatureFilter): Promise<FeatureEntity[]> {
    const query = this.repository.createQueryBuilder('feature')
      .leftJoinAndSelect('feature.creator', 'creator')
      .leftJoinAndSelect('feature.tags', 'tags');
    
    if (filter.keyword) {
      query.andWhere(
        '(feature.name ILIKE :keyword OR feature.description ILIKE :keyword)',
        { keyword: `%${filter.keyword}%` },
      );
    }
    
    if (filter.type) {
      query.andWhere('feature.type = :type', { type: filter.type });
    }
    
    if (filter.tagIds?.length) {
      query.andWhere('tags.id IN (:...tagIds)', { tagIds: filter.tagIds });
    }
    
    return query.getMany();
  }
}
```

### Transaction Pattern
```typescript
async createWithRelations(input: CreateFeatureInput): Promise<Feature> {
  return this.connection.transaction(async (manager) => {
    // Create feature
    const feature = manager.create(FeatureEntity, {
      name: input.name,
      description: input.description,
      type: input.type,
    });
    
    const savedFeature = await manager.save(feature);
    
    // Create relations
    if (input.tagIds?.length) {
      const tags = await manager.findByIds(TagEntity, input.tagIds);
      savedFeature.tags = tags;
      await manager.save(savedFeature);
    }
    
    return savedFeature;
  });
}
```

## Error Handling

### Custom Exceptions
```typescript
// office.error.ts
export class OfficeError extends Error {
  constructor(
    public readonly code: string,
    public readonly message: string,
    public readonly statusCode: number = 500,
    public readonly extensions?: Record<string, any>,
  ) {
    super(message);
    this.name = 'OfficeError';
  }
  
  toGraphQLError() {
    return {
      code: this.code,
      message: this.message,
      extensions: {
        code: this.code,
        statusCode: this.statusCode,
        ...this.extensions,
      },
    };
  }
}

// Usage
throw new OfficeError(
  'FEATURE_NOT_FOUND',
  'Feature not found',
  404,
  { featureId: id },
);
```

### Exception Filter
```typescript
// universal-exception.filter.ts
@Catch()
export class UniversalExceptionFilter implements ExceptionFilter {
  private readonly logger = new LoggerService('ExceptionFilter');
  
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest();
    
    let status = 500;
    let message = 'Internal server error';
    let code = 'INTERNAL_ERROR';
    
    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();
      message = typeof exceptionResponse === 'string'
        ? exceptionResponse
        : (exceptionResponse as any).message;
    } else if (exception instanceof OfficeError) {
      status = exception.statusCode;
      message = exception.message;
      code = exception.code;
    }
    
    this.logger.error('Exception caught', {
      exception,
      url: request.url,
      method: request.method,
      status,
    });
    
    response.status(status).json({
      code,
      message,
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
```

## Validation

### Custom Validators
```typescript
// is-exist-user.validator.ts
@ValidatorConstraint({ name: 'IsExistUserDb', async: true })
@Injectable()
export class IsExistUserDbValidate implements ValidatorConstraintInterface {
  constructor(private readonly userRepo: UserRepository) {}
  
  async validate(userIds: string[]): Promise<boolean> {
    if (!userIds || !userIds.length) {
      return true;
    }
    
    const users = await this.userRepo.findByIds(userIds);
    return users.length === userIds.length;
  }
  
  defaultMessage(): string {
    return 'One or more user IDs do not exist';
  }
}

// Usage in DTO
@Field(() => [String])
@IsExistUserDbValidate()
userIds: string[];
```

## Caching

### Redis Caching Pattern
```typescript
@Injectable()
export class FeatureService {
  constructor(
    private readonly featureRepo: FeatureRepository,
    private readonly redisService: RedisService,
  ) {}
  
  async findById(id: string): Promise<Feature> {
    const cacheKey = `feature:${id}`;
    
    // Try cache first
    const cached = await this.redisService.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }
    
    // Fetch from DB
    const feature = await this.featureRepo.findById(id);
    if (!feature) {
      throw new NotFoundException();
    }
    
    // Cache with TTL
    await this.redisService.set(
      cacheKey,
      JSON.stringify(feature),
      3600, // 1 hour
    );
    
    return feature;
  }
  
  async update(id: string, input: UpdateFeatureInput): Promise<Feature> {
    const feature = await this.featureRepo.update(id, input);
    
    // Invalidate cache
    await this.redisService.del(`feature:${id}`);
    
    return feature;
  }
}
```

## Background Jobs

### Bull Queue Pattern
```typescript
// feature.processor.ts
@Processor('feature_queue')
export class FeatureProcessor {
  private readonly logger = new LoggerService(FeatureProcessor.name);
  
  @Process('process_feature')
  async processFeature(job: Job<ProcessFeatureData>) {
    this.logger.info('Processing feature', { jobId: job.id });
    
    try {
      const { featureId, action } = job.data;
      
      // Process feature
      await this.performAction(featureId, action);
      
      // Update progress
      await job.progress(100);
      
      this.logger.info('Feature processed', { jobId: job.id });
    } catch (error) {
      this.logger.error('Failed to process feature', error);
      throw error;
    }
  }
  
  @OnQueueCompleted()
  onCompleted(job: Job) {
    this.logger.info('Job completed', { jobId: job.id });
  }
  
  @OnQueueFailed()
  onFailed(job: Job, error: Error) {
    this.logger.error('Job failed', { jobId: job.id, error });
  }
}

// feature.service.ts
@Injectable()
export class FeatureService {
  constructor(
    @InjectQueue('feature_queue') private readonly featureQueue: Queue,
  ) {}
  
  async queueProcessing(featureId: string, action: string): Promise<void> {
    await this.featureQueue.add('process_feature', {
      featureId,
      action,
    }, {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 2000,
      },
    });
  }
}
```

## Security

### Guards
```typescript
// global.guard.ts
@Injectable()
export class GlobalGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly iamClient: IAMGraphQlClient,
    private readonly redisService: RedisService,
  ) {}
  
  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Check if route is public
    const isPublic = this.reflector.get<boolean>(
      'isPublic',
      context.getHandler(),
    );
    
    if (isPublic) {
      return true;
    }
    
    // Get request
    const ctx = GqlExecutionContext.create(context);
    const { req } = ctx.getContext();
    
    // Extract token
    const token = this.extractToken(req);
    if (!token) {
      throw new UnauthorizedException('No token provided');
    }
    
    // Verify token
    const user = await this.verifyToken(token);
    if (!user) {
      throw new UnauthorizedException('Invalid token');
    }
    
    // Attach user to request
    req.user = user;
    
    return true;
  }
  
  private extractToken(req: any): string | null {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return null;
    }
    
    const [type, token] = authHeader.split(' ');
    return type === 'Bearer' ? token : null;
  }
  
  private async verifyToken(token: string): Promise<User | null> {
    // Check cache first
    const cached = await this.redisService.get(`token:${token}`);
    if (cached) {
      return JSON.parse(cached);
    }
    
    // Verify with IAM service
    const user = await this.iamClient.verifyToken(token);
    
    // Cache result
    if (user) {
      await this.redisService.set(
        `token:${token}`,
        JSON.stringify(user),
        3600,
      );
    }
    
    return user;
  }
}
```

## Testing

### Service Testing
```typescript
describe('FeatureService', () => {
  let service: FeatureService;
  let repository: MockType<FeatureRepository>;
  let cacheService: MockType<RedisService>;
  
  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FeatureService,
        {
          provide: FeatureRepository,
          useFactory: repositoryMockFactory,
        },
        {
          provide: RedisService,
          useFactory: cacheServiceMockFactory,
        },
      ],
    }).compile();
    
    service = module.get<FeatureService>(FeatureService);
    repository = module.get(FeatureRepository);
    cacheService = module.get(RedisService);
  });
  
  describe('findById', () => {
    it('should return cached feature if exists', async () => {
      const feature = { id: '1', name: 'Test' };
      cacheService.get.mockResolvedValue(JSON.stringify(feature));
      
      const result = await service.findById('1');
      
      expect(result).toEqual(feature);
      expect(cacheService.get).toHaveBeenCalledWith('feature:1');
      expect(repository.findById).not.toHaveBeenCalled();
    });
    
    it('should fetch from DB and cache if not in cache', async () => {
      const feature = { id: '1', name: 'Test' };
      cacheService.get.mockResolvedValue(null);
      repository.findById.mockResolvedValue(feature);
      
      const result = await service.findById('1');
      
      expect(result).toEqual(feature);
      expect(repository.findById).toHaveBeenCalledWith('1');
      expect(cacheService.set).toHaveBeenCalledWith(
        'feature:1',
        JSON.stringify(feature),
        3600,
      );
    });
  });
});
```

---

**Key Principles**:
- Use dependency injection everywhere
- Validate all inputs
- Cache aggressively
- Log important operations
- Handle errors gracefully
- Write tests for critical paths
