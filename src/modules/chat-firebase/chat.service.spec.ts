import { Test, TestingModule } from '@nestjs/testing';
import { ChatFirebaseService } from './chat-firebase.service';

describe('ChatService', () => {
  let service: ChatFirebaseService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ChatFirebaseService],
    }).compile();

    service = module.get<ChatFirebaseService>(ChatFirebaseService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
