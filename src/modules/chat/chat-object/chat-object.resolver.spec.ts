import { Test, TestingModule } from '@nestjs/testing';
import { ChatObjectResolver } from './chat-object.resolver';

describe('ChatObjectResolver', () => {
  let resolver: ChatObjectResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ChatObjectResolver],
    }).compile();

    resolver = module.get<ChatObjectResolver>(ChatObjectResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
