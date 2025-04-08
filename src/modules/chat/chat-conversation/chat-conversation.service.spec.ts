import { Test, TestingModule } from '@nestjs/testing';
import { ChatConversationService } from './chat-conversation.service';

describe('ChatConversationService', () => {
  let service: ChatConversationService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ChatConversationService],
    }).compile();

    service = module.get<ChatConversationService>(ChatConversationService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
