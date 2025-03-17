import { Test, TestingModule } from '@nestjs/testing';
import { ChatNotifyService } from './chat-notify.service';

describe('ChatNotifyService', () => {
  let service: ChatNotifyService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ChatNotifyService],
    }).compile();

    service = module.get<ChatNotifyService>(ChatNotifyService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
