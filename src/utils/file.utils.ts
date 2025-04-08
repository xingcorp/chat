import * as readline from "node:readline";
import * as fs from "fs";

export enum VIDEO_FILE_TYPE {
    MP4 = 'mp4',
    HLS = 'hls'
}

export const getNameAndExtFile = (fullPath: string) => {
    const arr = fullPath.split('.')
    const ext = arr.pop()
    const name = arr.join('.')

    return [name, ext]
}

export const getPathAndNameAndExtFile = (fullPath: string) => {
    let arr = fullPath.split('.')
    const ext = arr.pop()
    arr = arr.join('.').split('/')
    const name = arr.pop()
    const path = arr.join('/') + '/'

    return {path, name, ext}
}

export const getNameFile = (fullPath: string) => getNameAndExtFile(fullPath)[0]
export const getExtFile = (fullPath: string) => getNameAndExtFile(fullPath)[1]

export const isVideoFile = (fullPath: string) => {
    switch (getExtFile(fullPath).toLowerCase()) {
        case 'm4v':
        case 'avi':
        case 'mpg':
        case 'mp4':
            return true;
        default:
    }

    return false
}

export const getExtByType = (type: string) => {
    switch (type) {
        case VIDEO_FILE_TYPE.HLS:
            return 'm3u8';
        case VIDEO_FILE_TYPE.MP4:
            return 'mp4';
    }

    return ''
}

export const changeFilename = (newName: string, oldName: string, isNewNameExt: boolean = false) => {
    if (isNewNameExt) return getNameFile(newName) + '.' + getExtFile(oldName)

    return newName + '.' + getExtFile(oldName)
}

export async function readFileToArray() {
    const fileStream = fs.createReadStream('haproxy.cfg.txt');

    const rl = readline.createInterface({
        input: fileStream,
        crlfDelay: Infinity
    });
    // Note: we use the crlfDelay option to recognize all instances of CR LF
    // ('\r\n') in input.txt as a single line break.

    let res = []
    for await (const line of rl) {
        // Each line in input.txt will be successively available here as `line`.
        // console.log(`Line from file: ${line}`);
        res.push(line)
    }

    return res
}