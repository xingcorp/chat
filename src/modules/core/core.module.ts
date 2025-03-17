import { Module } from '@nestjs/common'
import { CommonModule } from './common/common.module'
// import { FactoryModule } from "./factory/factory.module"
import { IAMModule } from './iam/iam.module'
import { StorageModule } from './storage/storage.module'

@Module({
  imports: [
    CommonModule,
    IAMModule,
    StorageModule
  ],
  exports: [StorageModule]
})
export class CoreModule { }
