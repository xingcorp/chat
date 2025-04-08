export const OnlyNumberRegex = /^\d+$/

export const validateEmail = (email: string) => {
    // return String(email)
    //   .toLowerCase()
    //   .match(
    //     /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    //   );
    // return /^[A-Za-z0-9_!#$%&'*+\/=?`{|}~^.-]+@[A-Za-z0-9.-]+$/.test(email)
    const validRegexp = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/
    return validRegexp.test(email)
}

export const validatePhoneNumber = (phone: string) => {
    const validRegexp = /(0)(3|5|7|8|9)+([0-9]{8})\b/
    return validRegexp.test(phone)

    // return /(((\+|)84)|0)(3|5|7|8|9)+([0-9]{8})\b/.test(phone)
}

export const validateNumeric = (numeric: string) => {
    const validRegexp = /^-?(0|[1-9]\d*)(\.\d+)?$/
    return validRegexp.test(numeric)
}

export const validateDateFormat = (date: string) => {
    const validRegexp = /^(?:(?:31(\/|-|\.)(?:0?[13578]|1[02]))\1|(?:(?:29|30)(\/|-|\.)(?:0?[13-9]|1[0-2])\2))(?:(?:1[6-9]|[2-9]\d)?\d{2})$|^(?:29(\/|-|\.)0?2\3(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\d|2[0-8])(\/|-|\.)(?:(?:0?[1-9])|(?:1[0-2]))\4(?:(?:1[6-9]|[2-9]\d)?\d{2})$/
    return validRegexp.test(date)
}