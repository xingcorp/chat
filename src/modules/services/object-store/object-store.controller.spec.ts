import { Test, TestingModule } from '@nestjs/testing';
import { ObjectStoreController } from './object-store.controller';

describe('ObjectStoreController', () => {
  let controller: ObjectStoreController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ObjectStoreController],
    }).compile();

    controller = module.get<ObjectStoreController>(ObjectStoreController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
