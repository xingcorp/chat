import { Test, TestingModule } from '@nestjs/testing';
import { ChatObjectService } from './chat-object.service';

describe('ChatObjectService', () => {
  let service: ChatObjectService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ChatObjectService],
    }).compile();

    service = module.get<ChatObjectService>(ChatObjectService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
