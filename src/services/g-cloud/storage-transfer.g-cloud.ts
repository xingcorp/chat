import * as dotenv from 'dotenv';

dotenv.config();

import { StorageTransferServiceClient } from "@google-cloud/storage-transfer";

const client = new StorageTransferServiceClient({
    credentials: JSON.parse(process.env.GOOGLE_AUTH_CERTS ?? ""),
});

const CREDENTIALS = JSON.parse(process.env.GOOGLE_AUTH_CERTS ?? "")

export const gclGetCredentialValue = (key: string) => CREDENTIALS[key] ?? null

export const gclStorageTransferFromS3 = async (
    s3Source: { bucketName: string, path?: string },
    gcsSinkBucket: { bucketName: string, path?: string }
) => {
    const projectId = gclGetCredentialValue('project_id')
    const createRequest = {
        transferJob: {
            projectId: projectId,
            transferSpec: {
                awsS3DataSource: {
                    ...s3Source,
                    awsAccessKey: {
                        accessKeyId: process.env.AWS_IAM_ACCESS_KEY_ID,
                        secretAccessKey: process.env.AWS_IAM_ACCESS_KEY_SECRET,
                    }
                },
                gcsDataSink: gcsSinkBucket,
            },
            status: 1, //enable
        },
    };

    // Runs the request and creates the job
    const [transferJob] = await client.createTransferJob(createRequest);

    const runRequest = {
        jobName: transferJob.name,
        projectId: projectId,
    };
    await client.runTransferJob(runRequest);

    console.log(
        `Created and ran a transfer job from s3: ${s3Source.bucketName}/${s3Source.path} ` +
        `to gcs: ${gcsSinkBucket.bucketName}/${gcsSinkBucket.path} with name ${transferJob.name}`
    );

    return transferJob
}

export const gclStorageTransferGetJob = async (jobName: string) => {
    // Construct request
    const request = {
        jobName,
        projectId: gclGetCredentialValue('project_id'),
    };

    // Run request
    const response = await client.getTransferJob(request);
    console.log(response);

    return response
}

// latestOperationName
// metadata status
// https://cloud.google.com/storage-transfer/docs/reference/rest/v1/transferOperations
export const gclStorageTransferCheckRunJob = async (jobName: string) => {
    // Run request
    const response = await client.checkRunTransferJobProgress(jobName);
    console.log(response);

    return response
}

export const gclStorageTransferListJobs = async () => {
    const request = {
        filter:  JSON.stringify({
            projectId: gclGetCredentialValue('project_id')
        }),
    };

    const res = []

    const iterable = client.listTransferJobsAsync(request);
    for await (const response of iterable) {
        console.log(response);
        res.push(response)
    }

    return res
}
