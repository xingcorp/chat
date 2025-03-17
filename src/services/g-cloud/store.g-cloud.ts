import * as dotenv from 'dotenv';

dotenv.config();

import { Storage, TransferManager } from '@google-cloud/storage';
import { FileOptions, GetSignedUrlConfig } from "@google-cloud/storage/build/cjs/src/file";
import { ReadStream } from "fs-capacitor";
import { TIMESTAMP } from "@utils/datetime.utils";
import { DeleteOptions } from "@google-cloud/storage/build/cjs/src/nodejs-common/service-object";
import { DeleteFilesOptions } from "@google-cloud/storage/build/cjs/src/bucket";

const getStoreClient = async () => new Storage({
    credentials: JSON.parse(process.env.GOOGLE_AUTH_CERTS ?? ""),
})

const getStoreClientSigned = async () => {
    const credentials = (process.env.GOOGLE_AUTH_CERTS_SIGNED && process.env.GOOGLE_AUTH_CERTS_SIGNED.length)
        ? JSON.parse(process.env.GOOGLE_AUTH_CERTS_SIGNED)
        : JSON.parse(process.env.GOOGLE_AUTH_CERTS)

    return new Storage({credentials})
}

const MEDIA_CONVERT_PREFIX =
    (!process.env.GCL_MEDIA_CONVERT_BUCKET || process.env.GCL_MEDIA_CONVERT_BUCKET === process.env.GCL_DOCUMENT_BUCKET)
        ? 'media-convert/'
        : ''

export const gclGetUri = (bucket: string, source?: string) => `gs://${bucket}/${source ?? ''}`

export const gclGetDocumentStoreUri = (source?: string) => gclGetUri(process.env.GCL_DOCUMENT_BUCKET, source)
export const gclGetMediaConvertStoreUri = (source?: string) => gclGetUri(process.env.GCL_MEDIA_CONVERT_BUCKET, `${MEDIA_CONVERT_PREFIX}${source}`)

const uploadStreamFile = async (file, readStream: ReadStream) => {
    return new Promise((resolve) => {
        readStream
            .pipe(file.createWriteStream())
            .on('finish', () => {
                resolve('success')
            });
    });
}
export const uploadStreamFileToGCL = async (bucket: string, filename: string, readStream: ReadStream, options?: FileOptions) => {
    const file = (await getStoreClient()).bucket(bucket).file(filename, options)

    await uploadStreamFile(file, readStream).catch(e => {
        console.log('upload file to GLC failed with error: ', e)
    })
}

export async function listBuckets() {
    const client = await getStoreClient();
    const [buckets] = await client.getBuckets();

    console.log('Buckets:');
    buckets.forEach(bucket => {
        console.log(bucket.name);
    });
}

export async function getMetadataObjFromGCL(bucket: string, filename: string) {
    const [metadata] = await (await getStoreClient()).bucket(bucket).file(filename).getMetadata()

    return metadata
}

export async function getSourceFileFromGCL(bucket: string, filename: string) {
    return (await getStoreClient()).bucket(bucket).file(filename);
}

export async function copyFileByGCL(cloneSourceFile, originBucket: string, originFilename: string, options?: FileOptions) {
    return (await getStoreClient()).bucket(originBucket).file(originFilename).copy(cloneSourceFile, options);
}

export async function gcpStorageMoveFile(originBucket: string, originFilename: string, cloneSourceFile: string, options?: FileOptions) {
    return (await getStoreClient()).bucket(originBucket).file(originFilename).move(cloneSourceFile, options);
}

export async function generateSignedUrlByGCL(bucket: string, filename: string, expires?: number, v4: boolean = true) {
    const options = {
        version: v4 ? 'v4' : 'v2',
        action: 'read',
        expires: Date.now() + (expires ??  TIMESTAMP["1H"]),
    };

    const [url] = await (await getStoreClientSigned()).bucket(bucket).file(filename).getSignedUrl(options as GetSignedUrlConfig)

    return url
}

export async function deleteFileByGCL(bucket: string, filename: string, options?: DeleteOptions) {
    return (await getStoreClient()).bucket(bucket).file(filename).delete(options)
}

export async function deleteFolderByGCL(bucket: string, prefix: string, options?: DeleteFilesOptions) {
    return (await getStoreClient()).bucket(bucket).deleteFiles({...options, prefix})
}


const transferManager = async () => new TransferManager((await getStoreClient()).bucket('my-bucket'));
export const glcUploadFolder = async () => {
    const response = await (await transferManager()).uploadManyFiles('/local/path');
}

export const glcUpdateCorsCloudStorage = async (bucket?: string) => {
    console.log('Update Cors Cloud Storage', bucket ?? process.env.GCL_DOCUMENT_BUCKET)
    await (await getStoreClient()).bucket(bucket ?? process.env.GCL_DOCUMENT_BUCKET).setCorsConfiguration([
        {
            "origin": ["*"],
            "method": ["GET", "POST", "PUT", "OPTIONS", "HEAD"],
            "responseHeader": ["*"],
            "maxAgeSeconds": 3600
        }
    ])

    const [metadata] = await (await getStoreClient()).bucket(process.env.GCL_DOCUMENT_BUCKET).getMetadata();

    console.log(JSON.stringify(metadata, null, 2));
}


export async function gcpGenerateSignedUrlWriteObject(bucket: string, filename: string, mimetype: string, expires?: number, v4: boolean = true) {
    const options = {
        version: v4 ? 'v4' : 'v2',
        action: 'write',
        expires: Date.now() + TIMESTAMP["15m"],
        contentType: mimetype,
    };

    const [url] = await (await getStoreClientSigned()).bucket(bucket).file(filename).getSignedUrl(options as GetSignedUrlConfig)

    return url
}

export async function gcpStorageGetListFiles(bucket: string) {
    const [files] = await (await getStoreClient()).bucket(bucket).getFiles();

    return files.filter(i => !i.name.endsWith('/'));
}