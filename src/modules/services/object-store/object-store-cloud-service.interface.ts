import { ReadStream } from "fs-capacitor";

export interface ObjectStoreServiceCloudInterface {
    storeNewObject(bucket: string, path: string, readStream: ReadStream): any;

    getForeverDownloadUrl(bucket: any, path: string): Promise<string>;

    getMetadataObj(bucket: string, path: string): any;

    getSignedUrl(bucket: string, path: string, expires?: number, v4?: boolean): any;

    getFirebaseUrl(bucket: string, path: string): any;

    genSignedUrlWriteObject(bucket: string, path: string, mimetype: string): any;

    getDataFromMetadata(metadata: any, args: { path: string; filename: string; userId: string }): any;

    updateObjectStoreCors(bucket: string): any;
}
