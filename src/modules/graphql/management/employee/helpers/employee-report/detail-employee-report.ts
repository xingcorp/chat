import * as ExcelJS from "exceljs";
import {
    explainOfficeOrgChartToObj,
    ListOOC,
    ORG_CHART_MAX_LEVER_SHOWING
} from "../../../orgchart/helpers/orgchart.helpers";
import {
    dataStyle,
} from "./summary-employee-report";
import { DataType, InfoField } from "@models/entities/profile.info.field";
import { countMonthBetweenTwoDate } from "@utils/datetime.utils";

const columnsKey = {
    no: 'no',
    code: 'code',
    hr_code: 'hr_code',
    full_name: 'full_name',
    birth: 'birth',
    age: 'age',
    l1: 'l1',
    l2: 'l2',
    l3: 'l3',
    l4: 'l4',
    l5: 'l5',
    l6: 'l6',
    l7: 'l7',
    title: 'title',
    job_quota: 'job_quota',
    manager: 'manager',
    address: 'address',
    id_card: 'id_card',
    id_card_date: 'id_card_date',
    id_card_place: 'id_card_place',
    date_join: 'date_join',
    date_office_working: 'date_office_working',
    date_terminal: 'date_terminal',
    seniority: 'seniority',
}

export const HEADER = {
    no: 'STT',
    code: 'Mã Nhân viên',
    hr_code: 'Mã chấm công',
    full_name: 'Họ và tên đầy đủ',
    birth: 'Ngày sinh',
    age: 'Tuổi',
    l1: 'Tập đoàn',
    l2: 'Đơn vị thành viên',
    l3: 'Khối/Khu vực',
    l4: 'Phòng/Ban',
    l5: 'Bộ phận',
    l6: 'Tổ nhóm',
    l7: 'Cấp bổ sung',
    title: 'Chức danh',
    job_quota: 'Ngạch công việc',
    manager: 'Cấp trên trực tiếp',
    address: 'Địa chỉ thường trú',
    id_card: 'Số CMND',
    id_card_date: 'Ngày cấp CMND',
    id_card_place: 'Nơi cấp CMND',
    date_join: 'Ngày vào công ty',
    date_office_working: 'Ngày ký hợp đồng chính thức đầu tiên',
    date_terminal: 'Ngày thôi việc',
    seniority: 'Thâm niên',
}

export function defineEmployeeReportDetailExportColumns(chartSheet: ExcelJS.Worksheet, fields: InfoField[]) {

    const columns = [
        {key: columnsKey.no, width: 10, style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}},
        {key: columnsKey.code, width: 20, style: dataStyle},
        {key: columnsKey.hr_code, width: 20, style: dataStyle},
        {key: columnsKey.full_name, width: 20, style: dataStyle},
        {key: columnsKey.birth, width: 20, style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}},
        {key: columnsKey.l1, width: 20, style: dataStyle},
        {key: columnsKey.l2, width: 30, style: dataStyle},
        {key: columnsKey.l3, width: 20, style: dataStyle},
        {key: columnsKey.l4, width: 20, style: dataStyle},
        {key: columnsKey.l5, width: 20, style: dataStyle},
        {key: columnsKey.l6, width: 20, style: dataStyle},
        {key: columnsKey.l7, width: 20, style: dataStyle},
        {key: columnsKey.title, width: 20, style: dataStyle},
        {key: columnsKey.job_quota, width: 20, style: dataStyle},
        {key: columnsKey.manager, width: 40, style: dataStyle},
        {key: columnsKey.address, width: 40, style: dataStyle},
        {key: columnsKey.id_card, width: 20, style: dataStyle},
        {
            key: columnsKey.id_card_date,
            width: 20,
            style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}
        },
        {key: columnsKey.id_card_place, width: 20, style: dataStyle},
        {
            key: columnsKey.date_join,
            width: 20,
            style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}
        },
        {
            key: columnsKey.date_office_working,
            width: 20,
            style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}
        },
        {
            key: columnsKey.date_terminal,
            width: 20,
            style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}
        },
        {key: columnsKey.seniority, width: 20, style: dataStyle},
    ]

    fields.map(i => columns.push({
        key: i.code,
        width: 20,
        style: dataStyle
    }))

    chartSheet.columns = columns as any
}

export function setEmployeeReportDetailExportHeader(chartSheet: ExcelJS.Worksheet, fields: InfoField[]) {
    const rows = HEADER

    fields.map(i => rows[i.code] = i.name)

    chartSheet.addRow(rows)
}

export function styleEmployeeReportDetailExport(chartSheet: ExcelJS.Worksheet, dataCount: number, headerCount = 1) {
    chartSheet.getRows(1, headerCount).map(row => {
        row.font = {'bold': true}
        row.alignment = {vertical: 'middle', horizontal: 'center'}
    })

    chartSheet.getRows(1, dataCount + headerCount).map(row => {
        row.border = {
            top: {style: 'thin'},
            left: {style: 'thin'},
            bottom: {style: 'thin'},
            right: {style: 'thin'}
        }
    })
}

export function addDataEmployeeReportDetailExport(chartSheet: ExcelJS.Worksheet, employees: Object, officeOrgs: ListOOC[], fields: InfoField[]) {
    let no = 1;
    for (const emp of Object.values(employees)) {
        chartSheet.addRow(getRowDataDetail(emp, no++, officeOrgs, fields))
    }

    return no - 1;
}

function getFullAddress(address: any, separator: string = ', ') {
    let res = []
    address?.address ? res.push(address?.address) : null
    address?.ward ? res.push(address?.ward) : null
    address?.district ? res.push(address?.district) : null
    address?.province ? res.push(address?.province) : null

    return res.join(separator)
}

export function getRowDataDetail(emp, no: number, officeOrgs: ListOOC[], fields: InfoField[], officeOrgChartLever: number = ORG_CHART_MAX_LEVER_SHOWING) {
    const lever = explainOfficeOrgChartToObj(emp?.department?.path, officeOrgs, officeOrgChartLever)
    const metadata = JSON.parse(emp?.metadata)

    const res = {
        no: no,
        code: emp['code'],
        hr_code: emp['hrCode'],
        full_name: emp['fullname'],
        birth: emp['dateOfBirth'],
        age: emp['age'],
        ...lever,
        l_current: emp?.department?.name,
        title: emp?.title?.name,
        job_quota: emp['major'],
        manager: emp?.approve?.fullname,
        address: emp?.address ? getFullAddress(emp?.address) : null,
        id_card: emp['identityCard'],
        id_card_date: emp['idCardIssuedOn'],
        id_card_place: emp['idCardIssuedPlace'],
        date_join: emp['onboardingOn'],
        date_terminal: emp['lastWorkingOn'] ?? '-',
        seniority: countMonthBetweenTwoDate(emp['onboardingOn'], emp['leaveOn']) + ' tháng',
    }

    fields.map(i => res[i.code] = metadata ? getMetadata(metadata[i.code], i.dataType) : null)

    return res
}

function getMetadata(value: any, dataType: DataType) {
    if (!value) return ''

    switch (dataType) {
        case DataType.Number:
            return value.toString()
        case DataType.Date:
            return (new Date(value as string)).toLocaleDateString("en-US")
        default:
            return value
    }
}
