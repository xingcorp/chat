import { forwardRef, Module } from '@nestjs/common'
import { SchedulerRegistry } from '@nestjs/schedule'
import { AwsSdkModule } from 'nest-aws-sdk'
import { SQS } from 'aws-sdk'
import { IAMModule } from '../core/iam/iam.module'
import { StorageModule } from '../core/storage/storage.module'
import { SqsService } from './aws/sqs.service'

@Module({
  imports: [
    AwsSdkModule.forFeatures([SQS]),
    forwardRef(() => StorageModule),
    forwardRef(() => IAMModule)
  ],
  controllers: [
  ],
  providers: [
    SchedulerRegistry,
    SqsService,
  ],
  exports: [
    SqsService
  ]
})
export class ThirdPartyModule {}
