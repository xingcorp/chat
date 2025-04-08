import { Test, TestingModule } from '@nestjs/testing';
import { UserPaycheckResolver } from './user-paycheck.resolver';

describe('UserPaycheckResolver', () => {
  let resolver: UserPaycheckResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [UserPaycheckResolver],
    }).compile();

    resolver = module.get<UserPaycheckResolver>(UserPaycheckResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
