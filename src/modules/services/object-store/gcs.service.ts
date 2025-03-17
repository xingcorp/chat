import { Injectable } from '@nestjs/common';
import { ObjectStoreServiceCloudInterface } from "@service-modules/object-store/object-store-cloud-service.interface";
import { ReadStream } from "fs-capacitor";
import {
    gcpGenerateSignedUrlWriteObject,
    generateSignedUrlByGCL,
    getMetadataObjFromGCL, glcUpdateCorsCloudStorage,
    uploadStreamFileToGCL
} from "@services/g-cloud/store.g-cloud";
import { firebaseDownloadUrl } from "@services/g-cloud/firebase.g-cloud";
import { TIMESTAMP } from "@utils/datetime.utils";

/*TODO: Project problem*/
@Injectable()
export class GcsService implements ObjectStoreServiceCloudInterface {
    async storeNewObject(bucket: string, path: string, readStream: ReadStream): Promise<any> {
        await uploadStreamFileToGCL(bucket, path, readStream)
    }

    async getForeverDownloadUrl(bucket: any, path: string): Promise<string> {
        return firebaseDownloadUrl(bucket, path)
    }

    async getMetadataObj(bucket: string, path: string): Promise<any> {
        return getMetadataObjFromGCL(bucket, path)
    }

    async getSignedUrl(bucket: string, path: string, expires: number = TIMESTAMP['1D'], v4: boolean = true): Promise<string> {
        return generateSignedUrlByGCL(bucket, path, expires, v4)
    }

    async getFirebaseUrl(bucket: any, path: string): Promise<any> {
        return firebaseDownloadUrl(bucket, path)
    }

    async genSignedUrlWriteObject(bucket: any, path: string, mimetype: string): Promise<any> {
        return gcpGenerateSignedUrlWriteObject(bucket, path, mimetype)
    }

    getDataFromMetadata(metadata: any, args: { path: string; filename: string; userId: string }): any {
        const {path, filename, userId} = args;

        return {
            relationType: path.split('/')[0],
            name: filename,
            mimetype: metadata.contentType,
            etag: metadata.etag as string,
            key: path,
            bucket: metadata.bucket,
            location: metadata.selfLink,
            size: metadata.size as string,
            createdBy: userId,
            updatedBy: userId
        }
    }

    updateObjectStoreCors(bucket: string): any {
        return glcUpdateCorsCloudStorage(bucket)
    }
}
