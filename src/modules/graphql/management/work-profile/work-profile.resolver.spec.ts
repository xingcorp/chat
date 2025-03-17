import { Test, TestingModule } from '@nestjs/testing';
import { WorkProfileResolver } from './work-profile.resolver';

describe('WorkProfileResolver', () => {
  let resolver: WorkProfileResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [WorkProfileResolver],
    }).compile();

    resolver = module.get<WorkProfileResolver>(WorkProfileResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
