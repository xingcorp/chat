import { v4 as uuidv4, validate as uuidValidate } from 'uuid'

export class RandomHelper {
    static randomInt = (min: number, max: number) => {
        return Math.floor(Math.random() * (max - min + 1) + min)
    }

    static generateOTP = () => {
        var digits = '0123456789'
        let OTP = ''
        for (let i = 0; i < 6; i++) {
            OTP += digits[Math.floor(Math.random() * 10)]
        }
        return OTP
    }

    static generateUUID = () => {
        return uuidv4()
    }

    static generateNoneDashUUID = () => {
        return `${uuidv4()}`.replaceAll('-', '').replaceAll(' - ', '')
    }

    static isUUID = (str: string) => uuidValidate(str)
}

