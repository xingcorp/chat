import * as dotenv from 'dotenv';

dotenv.config();

import { Inject, Injectable } from '@nestjs/common';
import { ObjectStoreServiceCloudInterface } from "@service-modules/object-store/object-store-cloud-service.interface";
import { datetimeGetFormat } from "@utils/datetime.utils";
import { buildExceptionResponse } from "@core/common/error.builder";
import { OfficeObjectRepo } from "@repositories/object-store/office-object.repo";
import { ViewObjectArgs } from "@service-modules/object-store/dto/object-store.args";
import { OfficeError } from "@common/office.error";
import { RedisService } from "@core/common/redis.service";
import { OfficeObjectType } from "@enum/object-store/object-store.enum";
import { gcpStorageGetListFiles, gcpStorageMoveFile } from "@services/g-cloud/store.g-cloud";
import { getPathAndNameAndExtFile } from "@utils/file.utils";
import { RandomHelper } from "@common/random";

const GENERAL_OBJECT_STORE = process.env.GENERAL_OBJECT_STORE
const OBJECT_STORE_BUCKET_CORS_ORIGIN = 'OBJECT_STORE_BUCKET_CORS_ORIGIN'
@Injectable()
export class ObjectStoreService {

    constructor(
        @Inject('ObjectStoreCloudService')
        private readonly objectStoreCloudService: ObjectStoreServiceCloudInterface,
        private officeObjectRepo: OfficeObjectRepo,
        private readonly cacheService: RedisService,
    ) {
    }

    async genLinkUpload(args: { filename: string; officeType: OfficeObjectType, mimetype: string }, userId: string) {
        const { filename, officeType, mimetype } = args;

        const filePath = this.getFilePath(filename, officeType, userId)

        try {
            return {
                uploadUrl: await this.objectStoreCloudService.genSignedUrlWriteObject(GENERAL_OBJECT_STORE, filePath, mimetype),
                path: filePath,
            }

        } catch (error) {
            console.log('Gen link upload object store has failed: ', error)
            throw buildExceptionResponse(error)
        }
    }

    private getFilePath(filename: string, officeType: OfficeObjectType, userId: string) {
        return `${officeType}/${userId}/${datetimeGetFormat('YYYY-MM-DD-HH-mm-ss')}/${filename}`
    }

    async officeStoreUploadSuccess(args: { path: string; filename: string }, userId: string) {
        const { path, filename } = args;

        const metadata = await this.getMetadataObj(path)

        const officeStoreData = this.objectStoreCloudService.getDataFromMetadata(metadata, { ...args, userId })

        return this.officeObjectRepo.storeData(officeStoreData)
    }

    private async getMetadataObj(path: string) {
        return this.objectStoreCloudService.getMetadataObj(GENERAL_OBJECT_STORE, path)
    }

    async getPreviewUrl(id: string, query: ViewObjectArgs) {
        await this.checkCorsBucket()

        const object = await this.officeObjectRepo.findOneBy({ id })

        if (!object) {
            throw new Error
        }

        return this.objectStoreCloudService.getSignedUrl(object.bucket, object.key)
    }

    private async checkCorsBucket() {
        const check = await this.cacheService.get(OBJECT_STORE_BUCKET_CORS_ORIGIN)

        if (!check || check !== process.env.OBJECT_STORE_BUCKET_CORS_ORIGIN) {
            await this.objectStoreCloudService.updateObjectStoreCors(GENERAL_OBJECT_STORE)
            await this.cacheService.set(OBJECT_STORE_BUCKET_CORS_ORIGIN, process.env.OBJECT_STORE_BUCKET_CORS_ORIGIN)
        }
    }

    async bucketAiChangeNameToUUID() {
        let bucket = process.env.BUCKET_CALL_AI
        const files = await gcpStorageGetListFiles(bucket)

        console.log('Start change name to UUID')
        for (const file of files) {

            const { path, name, ext } = getPathAndNameAndExtFile(file.name)

            if (!RandomHelper.isUUID(name)) {
                const newName = RandomHelper.generateUUID()
                const newFullName = `${path}${newName}.${ext}`

                console.log('change', file.name, 'to', newFullName)
                await gcpStorageMoveFile(bucket, file.name, newFullName)
            }
        }
        console.log('End change name to UUID')
    }
}
