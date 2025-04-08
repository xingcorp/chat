import { Test, TestingModule } from '@nestjs/testing';
import { WorkProfileService } from './work-profile.service';

describe('WorkProfileService', () => {
  let service: WorkProfileService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [WorkProfileService],
    }).compile();

    service = module.get<WorkProfileService>(WorkProfileService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
