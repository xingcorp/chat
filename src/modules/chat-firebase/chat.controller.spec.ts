import { Test, TestingModule } from '@nestjs/testing';
import { ChatFirebaseController } from './chat-firebase.controller';

describe('ChatController', () => {
  let controller: ChatFirebaseController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ChatFirebaseController],
    }).compile();

    controller = module.get<ChatFirebaseController>(ChatFirebaseController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
