import { Test, TestingModule } from '@nestjs/testing';
import { ChatFirebaseResolver } from './chat-firebase.resolver';

describe('ChatResolver', () => {
  let resolver: ChatFirebaseResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ChatFirebaseResolver],
    }).compile();

    resolver = module.get<ChatFirebaseResolver>(ChatFirebaseResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
