import { Test, TestingModule } from '@nestjs/testing';
import { UserPaycheckService } from './user-paycheck.service';

describe('UserPaycheckService', () => {
  let service: UserPaycheckService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [UserPaycheckService],
    }).compile();

    service = module.get<UserPaycheckService>(UserPaycheckService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
