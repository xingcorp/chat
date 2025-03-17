import { Test, TestingModule } from '@nestjs/testing';
import { TypesenseService } from './typesense.service';

describe('TypesenseService', () => {
  let service: TypesenseService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [TypesenseService],
    }).compile();

    service = module.get<TypesenseService>(TypesenseService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
