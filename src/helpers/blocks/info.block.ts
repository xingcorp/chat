import { DataType } from "@models/entities/profile.info.field";

export function infoBlockHelperGetDataDemo(source: any[]) {
    const res = {}
    source.map(i => {
        switch (i.dataType) {
            case DataType.List:
                res[i.code] = i.optionItems[Math.floor(Math.random() * i.optionItems.length)]
                break
            case DataType.Text:
            case DataType.Text_Area:
            case DataType.Text_Html:
                res[i.code] = 'Text'
                break
            case DataType.Date:
                res[i.code] = "'DD/MM/YYYY"
                break
            default:
                res[i.code] = ''
        }
    })

    return res
}