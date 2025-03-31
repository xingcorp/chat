import { forwardRef, Module } from '@nestjs/common'
import { IAMModule } from '../iam/iam.module'
import { StorageResolver } from './storage.resolver'
import { StorageService } from './storage.service'

@Module({
  imports: [
    forwardRef(() => IAMModule)
  ],
  providers: [
    StorageResolver,
    StorageService
  ],
  exports: [
    StorageService
  ]
})
export class StorageModule { }
