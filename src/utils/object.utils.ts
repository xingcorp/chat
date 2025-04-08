export function pluck(obs: Object, val: string, key: string | null = null) {
    let array = []

    for (const ob of Object.values(obs)) {
        if (key === null) {
            array.push(ob[val])
        } else {
            array[ob[key]] = ob[val]
        }
    }

    return array
}

export function removeUndefinedValue(obj: any) {
    Object.keys(obj).forEach(key => obj[key] === undefined && delete obj[key])

    return obj
}

export function isEmptyObject(obj) {
    for (var prop in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, prop)) {
            return false;
        }
    }

    return true
}