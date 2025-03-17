import * as ExcelJS from "exceljs";
import { countMonthBetweenTwoDate} from "@utils/datetime.utils";
import {
    explainOfficeOrgChartToObj,
    ListOOC,
    ORG_CHART_MAX_LEVER_SHOWING
} from "../../../orgchart/helpers/orgchart.helpers";

const columnsKey = {
    no: 'no',
    code: 'code',
    full_name: 'full_name',
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
    date_join: 'date_join',
    birth: 'birth',
    phone: 'phone',
    email_company: 'email_company',
    date_terminal: 'date_terminal',
    seniority: 'seniority',
}

export const COMMON_HEADER = {
    no: 'STT',
    code: 'Mã Nhân viên',
    full_name: 'Họ và tên đầy đủ',
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
    date_join: 'Ngày vào công ty',
    birth: 'Ngày sinh',
    phone: 'Số di động',
    email_company: 'Email công ty',
    date_terminal: 'Ngày thôi việc',
    seniority: 'Thâm niên',
}

export const dataStyle: Partial<ExcelJS.Style> = {
    alignment: {vertical: 'middle', horizontal: 'left'},
    font: {size: 11},
}

export function defineEmployeeReportSummaryExportColumns(chartSheet: ExcelJS.Worksheet) {

    chartSheet.columns = [
        {key: columnsKey.no, width: 10, style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}},
        {key: columnsKey.code, width: 20, style: dataStyle},
        {key: columnsKey.full_name, width: 20, style: dataStyle},
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
        {
            key: columnsKey.date_join,
            width: 20,
            style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}
        },
        {key: columnsKey.birth, width: 20, style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}},
        {key: columnsKey.phone, width: 20, style: dataStyle},
        {key: columnsKey.email_company, width: 20, style: dataStyle},
        {key: columnsKey.date_terminal, width: 20, style: dataStyle},
        {key: columnsKey.seniority, width: 20, style: dataStyle},
    ]

}

export function setEmployeeReportSummaryExportHeader(chartSheet: ExcelJS.Worksheet) {
    // chartSheet.addRow(HEADER1)
    chartSheet.addRow(COMMON_HEADER)
}

export function styleEmployeeReportSummaryExport(chartSheet: ExcelJS.Worksheet, dataCount: number, headerCount = 1) {
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

export function addDataEmployeeReportSummaryExport(chartSheet: ExcelJS.Worksheet, employees: Object, officeOrgs: ListOOC[]) {
    let no = 1;
    for (const emp of Object.values(employees)) {
        chartSheet.addRow(getRowDataSummary(emp, no++, officeOrgs))
    }

    return no - 1;
}

export function getRowDataSummary(emp, no: number, officeOrgs: ListOOC[], officeOrgChartLever: number = ORG_CHART_MAX_LEVER_SHOWING) {
    const lever = explainOfficeOrgChartToObj(emp?.department?.path, officeOrgs, officeOrgChartLever)
    return {
        no: no,
        code: emp['code'],
        full_name: emp['fullname'],
        ...lever,
        title: emp?.title?.name,
        job_quota: emp['major'],
        manager: emp?.approve?.fullname,
        date_join: emp['onboardingOn'],
        birth: emp['dateOfBirth'],
        phone: emp['phone'],
        email_company: emp['email'],
        date_terminal: emp['lastWorkingOn'] ?? '-',
        seniority: countMonthBetweenTwoDate(emp['onboardingOn'], emp['leaveOn']) + ' tháng',
    }
}