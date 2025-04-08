import { Test, TestingModule } from '@nestjs/testing';
import { ObjectStoreResolver } from './object-store.resolver';

describe('ObjectStoreResolver', () => {
  let resolver: ObjectStoreResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ObjectStoreResolver],
    }).compile();

    resolver = module.get<ObjectStoreResolver>(ObjectStoreResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
