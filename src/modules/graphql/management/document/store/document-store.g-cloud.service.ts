import * as dotenv from 'dotenv';

dotenv.config();

import { Injectable } from '@nestjs/common';
import { DocumentStoreInterface, STORE_SERVICE } from "./document-store-interface.interface";
import { FileUpload } from "graphql-upload";
import {
    copyFileByGCL, deleteFileByGCL, deleteFolderByGCL, gcpGenerateSignedUrlWriteObject, generateSignedUrlByGCL,
    getMetadataObjFromGCL, getSourceFileFromGCL, glcUpdateCorsCloudStorage,
    uploadStreamFileToGCL
} from "@services/g-cloud/store.g-cloud";
import { DocumentFile } from "@models/entities";
import { CopyResponse } from "@google-cloud/storage/build/cjs/src/file";
import { gclMediaConvert } from "@services/g-cloud/media-convert.g-cloud";
import {
    gclStorageTransferCheckRunJob,
    gclStorageTransferFromS3,
    gclStorageTransferGetJob
} from "@services/g-cloud/storage-transfer.g-cloud";

const GCL_DOCUMENT_BUCKET = process.env.GCL_DOCUMENT_BUCKET

@Injectable()
export class DocumentStoreGCloudService implements DocumentStoreInterface {
    async uploadFile(file: FileUpload, filename: string): Promise<any> {
        const readStream = file.createReadStream()

        return uploadStreamFileToGCL(GCL_DOCUMENT_BUCKET, filename, readStream);
    }

    async getMetadataObj(filename: string): Promise<any> {
        return getMetadataObjFromGCL(GCL_DOCUMENT_BUCKET, filename)
    }

    async copyFile(originFile: DocumentFile, cloneFile: DocumentFile): Promise<CopyResponse> {
        const cloneFileSource = await getSourceFileFromGCL(GCL_DOCUMENT_BUCKET, cloneFile.key)

        return copyFileByGCL(cloneFileSource, GCL_DOCUMENT_BUCKET, originFile.key)
    }

    async deleteFile(document: DocumentFile): Promise<any> {
        const bucket = document.bucket
        const name = document.key

        return deleteFileByGCL(bucket, name)
    }

    async deleteFolder(folderPath: string): Promise<any> {
        return deleteFolderByGCL(GCL_DOCUMENT_BUCKET, folderPath);
    }

    async getSignedUrl(bucket: string, key: string): Promise<any> {
        return generateSignedUrlByGCL(bucket, key);
    }

    async convertMedia(bucket: string, key: string): Promise<any> {
        const path = structuredClone(key).split('/')
        const name = path.pop().split('.')
        name.pop()
        path.join('/')

        return gclMediaConvert(key, path.join('/') + '/', name.join('.'))
    }

    async transferFromOutside(outsideService?: STORE_SERVICE): Promise<any> {
        outsideService = outsideService ?? STORE_SERVICE.AWS

        const gcsSinkBucket = {
            bucketName: process.env.GCL_DOCUMENT_BUCKET,
        }

        switch (outsideService) {
            case STORE_SERVICE.AWS:
            default:
                const s3Source = {
                    bucketName: process.env.AWS_S3_DOCUMENT_BUCKET
                }

                return gclStorageTransferFromS3(s3Source, gcsSinkBucket)
            case STORE_SERVICE.GCLOUD:
                return null
        }
    }

    async jobRunningSuccess(job: any): Promise<boolean> {
        const jobDetail = await gclStorageTransferGetJob(job.name)

        const operation = await gclStorageTransferCheckRunJob(jobDetail[0].latestOperationName)

        return operation.metadata['status'] === 3;
    }

    async updateDocumentStoreCors(): Promise<any> {
        return glcUpdateCorsCloudStorage()
    }

    async genSignedUrlWriteObject(filename: string, mimetype: string): Promise<any> {
        return gcpGenerateSignedUrlWriteObject(GCL_DOCUMENT_BUCKET, filename, mimetype);
    }
}
