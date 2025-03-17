var CryptoJS = require("crypto-js")
var AES = require("crypto-js/aes")

export function cryptoAesStringEncode(mess: string | number, secret: string) {
    return AES.encrypt(mess.toString(), secret).toString()
}

export function cryptoAesStringDecode(encode: string, secret: string) {
    const bytes = AES.decrypt(encode, secret)

    return bytes.toString(CryptoJS.enc.Utf8)
}