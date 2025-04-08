import { forwardRef, Module } from '@nestjs/common';
import { GcsService } from './gcs.service';
import { S3Service } from './s3.service';
import { ObjectStoreResolver } from './object-store.resolver';
import { ObjectStoreService } from './object-store.service';
import { OfficeObjectRepo } from "@models/repositories";
import { ObjectStoreController } from './object-store.controller';
import { CommonModule } from "@core/common/common.module";

export enum OBJECT_STORE_SERVICE {
  AWS = 'AWS',
  GCLOUD = 'GCLOUD'
}
const getStoreService = () => {
  switch (process.env.OBJECT_STORE_SERVICE) {
    case OBJECT_STORE_SERVICE.AWS:
      return S3Service;
    case OBJECT_STORE_SERVICE.GCLOUD:
    default:
      return GcsService;
  }
}

@Module({
  imports: [
    forwardRef(() => CommonModule),
  ],
  providers: [
    {
      provide: 'ObjectStoreCloudService',
      useClass: getStoreService()
    },
    ObjectStoreResolver,
    ObjectStoreService,
    OfficeObjectRepo
  ],
  exports: [
    {
      provide: 'ObjectStoreCloudService',
      useClass: getStoreService()
    },
    ObjectStoreService
  ],
  controllers: [ObjectStoreController]
})
export class ObjectStoreModule {}
