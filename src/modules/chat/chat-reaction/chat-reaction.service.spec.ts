import { Test, TestingModule } from '@nestjs/testing';
import { ChatReactionService } from './chat-reaction.service';

describe('ChatReactionService', () => {
  let service: ChatReactionService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ChatReactionService],
    }).compile();

    service = module.get<ChatReactionService>(ChatReactionService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
