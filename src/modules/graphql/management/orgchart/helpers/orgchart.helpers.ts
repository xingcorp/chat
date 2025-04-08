import { OfficeOrgChart } from "@models/entities";
import { OfficeError } from "@common/office.error";

export const ORG_CHART_MAX_LEVER_SHOWING = 7

export interface ListOOC {
    [key: string]: string;
}
export function explainOfficeOrgChart(path: string, list: ListOOC[] | null = null, level?: number) {
    let arr = []
    for(const id of path?.substring(1).split('/') ?? []) {
        arr.push(list[id])
    }

    let res = []
    if (level) {
        res = arr.slice(0, level - 1)
        if (level < arr.length) {
            // res.push(arr.slice(level - 1).join('/'))
            res.push(arr.at(-1))
        } else {
            res.push(...Array(level - arr.length).fill(''))
        }
    } else {
        res = arr
    }

    return res;
}

export function explainOfficeOrgChartToObj(path: string, list: ListOOC[] | null = null, level: number = ORG_CHART_MAX_LEVER_SHOWING) {
    const arr = explainOfficeOrgChart(path, list, level)
    const obj = {};

    let count = 1;
    arr.map(item => obj[`l${count++}`] = item);

    return obj;
}

export async function getRootOOCByDepartmentId(id: string) {
    const current= await OfficeOrgChart.findOneBy({id})

    if (!current) return null

    const rootId = current['path']?.split('/')[1] ?? ''

    return OfficeOrgChart.findOneBy({id: rootId})
}

export async function getCompanyByDepartmentId(id: string) {
    const department = await OfficeOrgChart.findOne({ where: { id } })
    if (!department) {
        throw OfficeError.OrgChartNotFound;
    }

    if (department.parentId === 'root') return department

    return OfficeOrgChart.findOne({ where: { id: department.path.split('/')[2] } })
}

