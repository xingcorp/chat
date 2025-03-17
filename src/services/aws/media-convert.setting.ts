/**
 * Convert from: https://github.com/aws-samples/aws-media-services-simple-vod-workflow/blob/master/7-MediaConvertJobLambda/README.md
 * */

import * as dotenv from 'dotenv';
dotenv.config();

import {
    CreateJobCommand,
    CreateJobCommandInput,
    JobSettings,
    MediaConvertClient
} from "@aws-sdk/client-mediaconvert";
import { getExtByType, getNameFile, VIDEO_FILE_TYPE } from "@utils/file.utils";
import { getS3Uri } from "@services/aws/s3.aws";
import defaultSettings from "@services/aws/convert-setting.json";

enum MEDIA_CONVERT_NAME_MODIFIER {
    LOW = '_low',
    VERYLOW = '_very_low',
}

const mediaConvertClient = new MediaConvertClient({
    region: process.env.AWS_S3_REGION,
    credentials: {
        accessKeyId: process.env.AWS_IAM_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_IAM_ACCESS_KEY_SECRET
    }
});

const MEDIA_CONVERT_FOLDER = 'converts'

export const mediaConvertCreateJob = async (Settings: JobSettings, Role?: string, options?: Partial<CreateJobCommandInput>) => {
    let input = {
        Settings,
        Role: Role ?? process.env.MEDIA_CONVERT_ROLE,
        ...options
    }

    const command = new CreateJobCommand(input);

    return mediaConvertClient.send(command)
}

export const getMediaConvertDestination = (type: string, sourceKey: string) => getS3Uri(process.env.AWS_S3_MEDIA_CONVERT_BUCKET, `${MEDIA_CONVERT_FOLDER}/${type}/${getNameFile(sourceKey)}`)
const getMediaConvertKey = (type: string, sourceKey: string, nameModifier: string) => `${MEDIA_CONVERT_FOLDER}/${type}/${getNameFile(sourceKey)}${nameModifier}.${getExtByType(type)}`

export const getLowMediaConvertKey = (type: string, sourceKey: string) => getMediaConvertKey(type, sourceKey, MEDIA_CONVERT_NAME_MODIFIER.LOW)

export const getVeryLowMediaConvertKey = (type: string, sourceKey: string) => getMediaConvertKey(type, sourceKey, MEDIA_CONVERT_NAME_MODIFIER.VERYLOW)

const getConvertSettings = (sourceBucket: string, sourceKey: string) => {
    let settings = defaultSettings;

    settings['Inputs'][0]['FileInput'] = getS3Uri(sourceBucket, sourceKey)
    settings['OutputGroups'][0]['OutputGroupSettings']['HlsGroupSettings']['Destination'] = getMediaConvertDestination(VIDEO_FILE_TYPE.HLS, sourceKey)
    settings['OutputGroups'][1]['OutputGroupSettings']['FileGroupSettings']['Destination'] = getMediaConvertDestination(VIDEO_FILE_TYPE.MP4, sourceKey)

    return settings
}

export const s3ConvertVideo = async (sourceBucket: string, sourceKey: string) => {
    const settings = getConvertSettings(sourceBucket, sourceKey)

    console.log('start convert')
    return mediaConvertCreateJob(settings as JobSettings)
}
