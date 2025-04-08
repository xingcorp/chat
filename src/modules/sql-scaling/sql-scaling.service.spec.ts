import { Test, TestingModule } from '@nestjs/testing';
import { SqlScalingService } from './sql-scaling.service';

describe('SqlScalingService', () => {
  let service: SqlScalingService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [SqlScalingService],
    }).compile();

    service = module.get<SqlScalingService>(SqlScalingService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
