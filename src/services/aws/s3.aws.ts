import * as dotenv from 'dotenv';

dotenv.config();

import {
    CopyObjectCommand,
    CopyObjectCommandInput,
    DeleteObjectCommand,
    DeleteObjectCommandInput,
    DeleteObjectsCommand,
    DeleteObjectsCommandInput,
    GetObjectCommand,
    GetObjectCommandInput,
    HeadObjectCommand,
    HeadObjectCommandInput,
    ListObjectsCommand,
    ListObjectsCommandInput,
    PutObjectCommand,
    PutObjectCommandInput,
    S3Client
} from "@aws-sdk/client-s3";
import { RequestPresigningArguments } from "@smithy/types";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { SECONDS_TIMESTAMP } from "@utils/datetime.utils";
import { Upload } from "@aws-sdk/lib-storage";

export const DEFAULT_S3_BUCKET = process.env.AWS_S3_DOCUMENT_BUCKET

const s3Client = new S3Client({
    credentials: {
        accessKeyId: process.env.AWS_IAM_ACCESS_KEY_ID as string,
        secretAccessKey: process.env.AWS_IAM_ACCESS_KEY_SECRET as string
    },
    region: process.env.AWS_S3_REGION,
});

const s3ClientSigned = new S3Client({
    credentials: {
        accessKeyId: (process.env.AWS_IAM_SIGNED_ACCESS_KEY_ID ?? process.env.AWS_IAM_ACCESS_KEY_ID) as string,
        secretAccessKey: (process.env.AWS_IAM_SIGNED_ACCESS_KEY_SECRET ?? process.env.AWS_IAM_ACCESS_KEY_SECRET) as string
    },
    region: (process.env.AWS_S3_SIGNED_REGION ?? process.env.AWS_S3_REGION),
});

export const s3GetObject = async ({Bucket, Key}: GetObjectCommandInput) => {
    try {
        const input: GetObjectCommandInput = {
            Bucket,
            Key,
        };

        return s3Client.send(new GetObjectCommand(input));
    } catch (e) {
        console.log('S3 get object err:', e);

        throw e;
    }
};

export const s3GetObjectMediaConvert = async (Key: string) => s3GetObject({
    Key,
    Bucket: process.env.AWS_S3_MEDIA_CONVERT_BUCKET
})

export const s3GetObjectDocument = async (Key: string) => s3GetObject({
    Key,
    Bucket: DEFAULT_S3_BUCKET
})
export const s3GetDefaultBucket = () => DEFAULT_S3_BUCKET

export const getS3Uri = (bucket: string, path: string) => `s3://${bucket}/${path}`

export const s3GetLocation = (path: string, bucket?: string, region?: string) =>
    `https://${bucket ?? DEFAULT_S3_BUCKET}.s3.${region ?? process.env.AWS_S3_REGION}.amazonaws.com/${encodeURI(path)}`

export const s3GetSignedUrl = async ({Bucket, Key}: GetObjectCommandInput, options?: RequestPresigningArguments) => {
    try {
        const input: GetObjectCommandInput = {
            Bucket,
            Key,
        };

        options = options ?? {}
        options.expiresIn = options.expiresIn ?? SECONDS_TIMESTAMP['1H']

        return getSignedUrl(s3ClientSigned, new GetObjectCommand(input), options)
    } catch (e) {
        console.log('S3 get signed url err:', e);

        throw e;
    }
}

export const s3PutObject = (input: Partial<PutObjectCommandInput>) => {
    try {
        const commandInput: PutObjectCommandInput = {
            ...input,
            Bucket: input.Bucket ?? DEFAULT_S3_BUCKET
        } as PutObjectCommandInput;

        return s3Client.send(new PutObjectCommand(commandInput));
    } catch (e) {
        console.log('S3 put object err:', e);

        throw e;
    }
}

export const s3UploadObject = async (input: PutObjectCommandInput) => {
    try {
        const parallelUploads3 = new Upload({
            client: s3Client,
            params: {
                ...input,
                Bucket: input.Bucket ?? DEFAULT_S3_BUCKET
            },
            queueSize: 4,

            // (optional) size of each part, in bytes, at least 5MB
            partSize: 1024 * 1024 * 5,

            // (optional) when true, do not automatically call AbortMultipartUpload when
            // a multipart upload fails to complete. You should then manually handle
            // the leftover parts.
            leavePartsOnError: false,
        });

        parallelUploads3.on("httpUploadProgress", (progress) => {
            console.log(progress);
        });

        return await parallelUploads3.done();
    } catch (e) {
        console.log('S3 upload object err:', e);

        throw e;
    }
}

export const s3HeadObject = async (input: HeadObjectCommandInput) => {
    try {
        const commandInput: HeadObjectCommandInput = {
            ...input,
            Bucket: input.Bucket ?? DEFAULT_S3_BUCKET,
        };

        return s3Client.send(new HeadObjectCommand(commandInput));
    } catch (e) {
        console.log('S3 head object err:', e);

        throw e;
    }
}

export const s3CopyObject = async (input: CopyObjectCommandInput) => {
    try {
        const commandInput: CopyObjectCommandInput = {
            ...input,
            Bucket: input.Bucket ?? DEFAULT_S3_BUCKET,
        };

        return s3Client.send(new CopyObjectCommand(commandInput));
    } catch (e) {
        console.log('S3 copy object err:', e);

        throw e;
    }
}

export const s3DeleteObject = async (input: DeleteObjectCommandInput) => {
    try {
        const commandInput: DeleteObjectCommandInput = {
            ...input,
            Bucket: input.Bucket ?? DEFAULT_S3_BUCKET,
        };

        return s3Client.send(new DeleteObjectCommand(commandInput));
    } catch (e) {
        console.log('S3 delete object err:', e);

        throw e;
    }
}

export const s3DeleteObjects = async (input: DeleteObjectsCommandInput) => {
    try {
        const commandInput: DeleteObjectsCommandInput = {
            ...input,
            Bucket: input.Bucket ?? DEFAULT_S3_BUCKET,
        };

        return s3Client.send(new DeleteObjectsCommand(commandInput));
    } catch (e) {
        console.log('S3 delete objects err:', e);

        throw e;
    }
}

export const s3ListObject = async (input: ListObjectsCommandInput) => {
    try {
        const commandInput: ListObjectsCommandInput = {
            ...input,
            Bucket: input.Bucket ?? DEFAULT_S3_BUCKET,
        };

        return s3Client.send(new ListObjectsCommand(commandInput));
    } catch (e) {
        console.log('S3 delete object err:', e);

        throw e;
    }
}
