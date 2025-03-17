import { Test, TestingModule } from '@nestjs/testing';
import { WorkingShiftResolver } from './working-shift.resolver';

describe('WorkingShiftResolver', () => {
  let resolver: WorkingShiftResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [WorkingShiftResolver],
    }).compile();

    resolver = module.get<WorkingShiftResolver>(WorkingShiftResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
