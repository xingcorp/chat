import { Test, TestingModule } from '@nestjs/testing';
import { MasterDataResolver } from './master-data.resolver';

describe('MasterDataResolver', () => {
  let resolver: MasterDataResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [MasterDataResolver],
    }).compile();

    resolver = module.get<MasterDataResolver>(MasterDataResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
