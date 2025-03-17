import { Test, TestingModule } from '@nestjs/testing';
import { SqlScalingController } from './sql-scaling.controller';

describe('SqlScalingController', () => {
  let controller: SqlScalingController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [SqlScalingController],
    }).compile();

    controller = module.get<SqlScalingController>(SqlScalingController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
