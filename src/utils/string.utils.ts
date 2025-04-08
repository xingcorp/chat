export enum StringCase {
    Lower = 'Lower',
    Upper = 'Upper',
}

export const lowerFirstChar = (str: string): string => str.charAt(0).toLowerCase() + str.slice(1)
export const capitalizeString = (str: string): string => str.charAt(0).toUpperCase() + str.slice(1)

export const stringNumberWithZeroLeading = (input: string | number, length: number = 5): string => {
    let res = ''

    for (let i = input.toString().length; i < length; i++) res += '0'

    return res + input.toString()
}

export const normalizeSearchText = (str: string, caseChange: StringCase = null): string => {
    const res = str.normalize("NFKD")
        .replace(/[\u0300-\u036f]/g, "")
        .trim()

    switch (caseChange) {
        case StringCase.Lower:
            return res.toLowerCase()
        case StringCase.Upper:
            return res.toUpperCase()
        default:
            return res
    }
}

export const substringArray = (str: string): string[] => {
    const res = []
    for (let i = 0; i <= str.length; i++) {
        res.push(str.substring(0, i));
    }

    return res
}