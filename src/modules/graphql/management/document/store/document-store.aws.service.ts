import { Injectable } from '@nestjs/common';
import { DocumentStoreInterface, STORE_SERVICE } from "./document-store-interface.interface";
import { DocumentFile } from "@models/entities";
import { FileUpload } from "graphql-upload";
import {
    s3CopyObject, s3DeleteObject, s3DeleteObjects,
    s3GetDefaultBucket,
    s3GetLocation,
    s3GetSignedUrl,
    s3HeadObject, s3ListObject,
    s3UploadObject
} from "@services/aws/s3.aws";
import { lowerFirstChar } from "@utils/string.utils";
import { s3ConvertVideo } from "@services/aws/media-convert.setting";

@Injectable()
export class DocumentStoreAwsService implements DocumentStoreInterface{
    async copyFile(originFile: DocumentFile, cloneFile: DocumentFile): Promise<any> {
        return s3CopyObject({
            Bucket: null,
            CopySource: `${originFile.bucket}/${originFile.key}`,
            Key: cloneFile.key
        });
    }

    async deleteFile(deleteFile: DocumentFile): Promise<any> {
        return s3DeleteObject({Bucket: deleteFile.bucket, Key: deleteFile.key});
    }

    async deleteFolder(folderPath: string): Promise<any> {
        const list = await s3ListObject({
            Bucket: null,
            Prefix: folderPath
        })

        return list?.Contents ? await s3DeleteObjects({
            Bucket: null,
            Delete: {
                Objects: list.Contents.map((item) => ({ Key: item.Key })),
                Quiet: false,
            }
        }) : null
    }

    async getMetadataObj(filename: string): Promise<any> {
        const metadata = {}
        const headObject = await s3HeadObject({
            Bucket: null,
            Key: filename
        });

        delete headObject['$metadata']
        delete headObject['Metadata']

        for (const key of Object.keys(headObject)) {
            metadata[lowerFirstChar(key)] = headObject[key];
        }

        metadata['selfLink'] = s3GetLocation(filename)
        metadata['location'] = s3GetLocation(filename)
        metadata['bucket'] = s3GetDefaultBucket()
        metadata['size'] = headObject['ContentLength']
        metadata['etag'] = headObject['ETag']

        return metadata
    }

    async getSignedUrl(bucket: string, key: string): Promise<any> {
        return s3GetSignedUrl({Bucket: bucket, Key: key})
    }

    async uploadFile(file: FileUpload, filename: string): Promise<any> {
        return s3UploadObject({
            Body: file.createReadStream(),
            Key: filename,
            ContentType: file.mimetype,
            ContentEncoding: file.encoding,
            Bucket: null
        });
    }

    async convertMedia(bucket: string, key: string): Promise<any> {
        return s3ConvertVideo(bucket, key);
    }

    async transferFromOutside(outsideService?: STORE_SERVICE): Promise<any> {
        return Promise.resolve(undefined);
    }

    async jobRunningSuccess(job: any): Promise<boolean> {
        return false;
    }

    updateDocumentStoreCors(): Promise<any> {
        return Promise.resolve(undefined);
    }

    genSignedUrlWriteObject(filename: string, mimetype: string): Promise<any> {
        return Promise.resolve(undefined);
    }
}
