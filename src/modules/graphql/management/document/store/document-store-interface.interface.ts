import { FileUpload } from "graphql-upload";
import { DocumentFile } from "@models/entities";

export enum STORE_SERVICE {
    AWS = 'AWS',
    GCLOUD = 'GCLOUD'
}

export interface DocumentStoreInterface {
    uploadFile(file: FileUpload, filename: string): Promise<any>;

    getMetadataObj(filename: string): Promise<any>;

    copyFile(originFile: DocumentFile, cloneFile: DocumentFile): Promise<any>;

    deleteFile(deleteFile: DocumentFile): Promise<any>;

    deleteFolder(folderPath: string): Promise<any>;

    getSignedUrl(bucket: string, key: string): Promise<any>;

    convertMedia(bucket: string, key: string): any;

    transferFromOutside(outsideService?: STORE_SERVICE): Promise<any>;

    jobRunningSuccess(job: any): Promise<boolean>;

    updateDocumentStoreCors(): Promise<any>;

    genSignedUrlWriteObject(filename: string, mimetype: string): Promise<any>;
}
