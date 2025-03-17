import { Test, TestingModule } from '@nestjs/testing';
import { ChatConversationResolver } from './chat-conversation.resolver';

describe('ChatConversationResolver', () => {
  let resolver: ChatConversationResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ChatConversationResolver],
    }).compile();

    resolver = module.get<ChatConversationResolver>(ChatConversationResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
