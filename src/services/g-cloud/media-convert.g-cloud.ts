/**
 * https://www.npmjs.com/package/@google-cloud/video-transcoder
 * https://cloud.google.com/transcoder/docs/transcode-video#create-job-from-preset-nodejs
 * https://stackoverflow.com/questions/66903572/gcp-transcoder-api-mov-mp4-to-hls-fmp4-no-audio-output-on-ios
 * */

import * as dotenv from 'dotenv';

dotenv.config();

import { TranscoderServiceClient } from "@google-cloud/video-transcoder";
import { gclGetCredentialValue } from "@services/g-cloud/auth.g-cloud";
import { gclGetDocumentStoreUri, gclGetMediaConvertStoreUri } from "@services/g-cloud/store.g-cloud";


const transcoderServiceClient = new TranscoderServiceClient({
    credentials: JSON.parse(process.env.GOOGLE_AUTH_CERTS ?? ""),
});

const DEFAULT_CONFIG = {
    elementaryStreams: [
        {
            key: 'video-stream0',
            videoStream: {
                h264: {
                    heightPixels: 360,
                    widthPixels: 640,
                    bitrateBps: 550000,
                    frameRate: 60,
                },
            },
        },
        {
            key: 'video-stream1',
            videoStream: {
                h264: {
                    heightPixels: 720,
                    widthPixels: 1280,
                    bitrateBps: 2500000,
                    frameRate: 60,
                },
            },
        },
        {
            videoStream: {
                h264: {
                    "tune": 'zerolatency',
                    "preset": 'superfast',
                    "heightPixels": 1080,
                    "widthPixels": 1920,
                    "bitrateBps": 3000000,
                    "rateControlMode": "vbr",
                    "frameRate": 60,
                    "crfLevel": 21,
                    "gopMode": {"gopDuration": "1.0s",},
                    "profile": "high",
                },
            },
            key: "video-streamR720P"
        },
        {
            videoStream: {
                h264: {
                    "tune": 'zerolatency',
                    "preset": 'superfast',
                    "heightPixels": 1440,
                    "widthPixels": 2560,
                    "bitrateBps": 6000000,
                    "rateControlMode": "vbr",
                    "frameRate": 60,
                    "crfLevel": 21,
                    "gopMode": {"gopDuration": "1.0s",},
                    "profile": "high",
                },
            },
            key: "video-streamR1080P"
        },
    ],
    muxStreams: [
        {
            "key": "mux-streamR720P",
            "fileName": 'R720P.m4s',
            "container": "fmp4",
            "elementaryStreams": ["video-streamR720P"],
            "segmentSettings": {
                "segmentDuration": {"seconds": "3.0s"},
                "individualSegments": true
            },
        },
        {
            "key": "mux-streamR1080P",
            "fileName": 'R1080P.m4s',
            "container": "fmp4",
            "elementaryStreams": ["video-streamR1080P"],
            "segmentSettings": {
                "segmentDuration": {"seconds": "3.0s"},
                "individualSegments": true
            },
        }
    ] as any[],
    manifests: []
}

const getConfigWithAudio = () => {
    const res = structuredClone(DEFAULT_CONFIG)

    const elementaryStreams = [
        {
            key: 'audio-stream0',
            audioStream: {
                codec: 'aac',
                bitrateBps: 64000,
            },
        },
    ] as any[]
    const muxStreams = [
        {
            key: 'sd-with-audio',
            fileName: 'sd.mp4',
            container: 'mp4',
            elementaryStreams: ['video-stream0', 'audio-stream0'],
        },
        {
            key: 'hd-with-audio',
            fileName: 'hd.mp4',
            container: 'mp4',
            elementaryStreams: ['video-stream1', 'audio-stream0'],
        },
        {
            key: "audio-fmp4",
            fileName: 'audio.m4s',
            container: "fmp4",
            elementaryStreams: ["audio-stream0"],
            segmentSettings: {
                "segmentDuration": {"seconds": "2.0s"},
                "individualSegments": true
            }
        }
    ]
    const manifests = [
        {
            "fileName": ".m3u8",
            "type": 1, //HLS
            "muxStreams": [
                "mux-streamR720P",
                "mux-streamR1080P",
                'audio-fmp4'
            ]
        },
        {
            "fileName": ".mpd",
            "type": 2, //DASH
            "muxStreams": [
                "mux-streamR720P",
                "mux-streamR1080P",
                'audio-fmp4'
            ]
        }
    ]

    res.elementaryStreams.push(...elementaryStreams)
    res.muxStreams.push(...muxStreams)
    res.manifests.push(...manifests)

    return res
}

const getConfigWithoutAudio = () => {
    const res = structuredClone(DEFAULT_CONFIG)

    const muxStreams = [
        {
            key: 'sd-only',
            fileName: 'sd-ns.mp4', //ns: no sound
            container: 'mp4',
            elementaryStreams: ['video-stream0'],
        },
        {
            key: 'hd-only',
            fileName: 'hd-ns.mp4',
            container: 'mp4',
            elementaryStreams: ['video-stream1'],
        },
    ]
    const manifests = [
        {
            "fileName": "-ns.m3u8",
            "type": 1, //HLS
            "muxStreams": [
                "mux-streamR720P",
                "mux-streamR1080P",
            ]
        },
        {
            "fileName": "-ns.mpd",
            "type": 2, //DASH
            "muxStreams": [
                "mux-streamR720P",
                "mux-streamR1080P",
            ]
        }
    ]

    res.muxStreams.push(...muxStreams)
    res.manifests.push(...manifests)

    return res
}


function getConfigWithFilename(config: any, name: string) {
    let res = config
    res.muxStreams = config.muxStreams.map(item => ({
        ...item,
        fileName: `${name}-${item.fileName}`
    }))
    res.manifests = config.manifests.map(item => ({
        ...item,
        fileName: `${name}${item.fileName}`
    }))

    return config
}

async function gclMediaConvertCreateJob(inputUri: string, outputUri: string, fileName: string, withAudio: boolean = true) {
    const config = withAudio ? getConfigWithAudio() : getConfigWithoutAudio()

    const request = {
        parent: transcoderServiceClient.locationPath(
            gclGetCredentialValue('project_id'),
            process.env.GOOGLE_AUTH_LOCATION
        ),
        job: {
            inputUri,
            outputUri,
            config: getConfigWithFilename(config, fileName),
        },
    };

    // Run request
    const [response] = await transcoderServiceClient.createJob(request as any);
    console.log(`Job: `, response.name);

    return response;
}

export async function gclMediaConvert(inputSource: string, outputSource: string, fileName: string) {
    const inputUri = gclGetDocumentStoreUri(inputSource)
    const outputUri = gclGetMediaConvertStoreUri(outputSource)

    await gclMediaConvertCreateJob(inputUri, outputUri, fileName)

    /*problems: https://issuetracker.google.com/issues/211671037*/
    return gclMediaConvertCreateJob(inputUri, outputUri, fileName, false)
}

export async function listJobs() {
    const iterable = await transcoderServiceClient.listJobsAsync({
        parent: transcoderServiceClient.locationPath(
            gclGetCredentialValue('project_id'),
            process.env.GOOGLE_AUTH_LOCATION
        ),
    });

    console.info('Jobs:');
    let res = []
    let count = 0
    for await (const response of iterable) {
        console.log(response.name);
        count++
        // await deleteJob(response.name.split('/').pop());
        res.push(response);
    }

    console.log('Number of jobs: ', count)
    return res;
}

export async function deleteJob(id: string) {
    const request = {
        name: transcoderServiceClient.jobPath(
            gclGetCredentialValue('project_id'),
            process.env.GOOGLE_AUTH_LOCATION,
            id
        ),
    };

    return transcoderServiceClient.deleteJob(request)
}