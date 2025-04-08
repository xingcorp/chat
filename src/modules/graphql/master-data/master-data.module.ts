import { Module } from '@nestjs/common';
import { MasterDataService } from './master-data.service';
import { MasterDataResolver } from './master-data.resolver';

@Module({
  providers: [MasterDataService, MasterDataResolver]
})
export class MasterDataModule {}
