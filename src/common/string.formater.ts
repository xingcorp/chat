
export class StringFormater {
    static removeAccents = (str: string) => {
        return str.normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/đ/g, 'd').replace(/Đ/g, 'D');
    }

    static minify = (str: string) => {
        return StringFormater.removeAccents(str.trim()).toLowerCase()
    }
}
