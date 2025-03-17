export function arrayRemoveValue(array: any[], value) {
    var index = array.indexOf(value);
    if (index !== -1) {
        array.splice(index, 1);
    }

    return array
}

export function arrayConvertToDistinctAndNotNull(arr: any[]) {
    return [...new Set(arr)].filter(i => i)
}

export function arrayObjectSortNormalKey(arr: any[], key: string) {
    return arr.sort(function(a, b) {
        if (a[key] < b[key]) return -1;
        if (a[key] > b[key]) return 1;
        return 0;
    });
}

export function arrayHaveDuplicateValue(arr: any[]) {
    const oriLength = arr.length
    const uniLength = [...new Set(arr)].length

    return oriLength !== uniLength
}

export function arrayIsTheSame(array1: any[] = [], array2: any[] = []) {
    return (array1.length == array2.length) && array1.every(function(element, index) {
        return element === array2[index];
    })
}

export function arrayChunk(array: any[] = [], chunkSize: number = 10) {
    const res = []
    for (let i = 0; i < array.length; i += chunkSize) {
        const chunk = array.slice(i, i + chunkSize);
        res.push(chunk)
    }

    return res
}
