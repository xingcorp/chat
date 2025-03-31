import { v4 as uuidv4 } from 'uuid';

export const generateUUID = () => {
    // return uuidv4().replace('-','')
    return uuidv4()
}

export const generateNoneDashUUID = () => {
    return `${uuidv4()}`.replaceAll('-', '').replaceAll(' - ', '')
}