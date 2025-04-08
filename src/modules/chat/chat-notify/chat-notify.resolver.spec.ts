import { Test, TestingModule } from '@nestjs/testing';
import { ChatNotifyResolver } from './chat-notify.resolver';

describe('ChatNotifyResolver', () => {
  let resolver: ChatNotifyResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ChatNotifyResolver],
    }).compile();

    resolver = module.get<ChatNotifyResolver>(ChatNotifyResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
