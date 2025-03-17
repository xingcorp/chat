import { Test, TestingModule } from '@nestjs/testing';
import { ChatReactionResolver } from './chat-reaction.resolver';

describe('ChatReactionResolver', () => {
  let resolver: ChatReactionResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ChatReactionResolver],
    }).compile();

    resolver = module.get<ChatReactionResolver>(ChatReactionResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
