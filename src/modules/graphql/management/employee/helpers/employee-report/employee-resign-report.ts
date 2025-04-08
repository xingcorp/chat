import * as ExcelJS from "exceljs";
import { countYearBetweenTwoDate } from "@utils/datetime.utils";
import {
    explainOfficeOrgChartToObj,
    ListOOC,
    ORG_CHART_MAX_LEVER_SHOWING
} from "../../../orgchart/helpers/orgchart.helpers";

const columnsKey = {
    no: 'no',
    code: 'code',
    full_name: 'full_name',
    title: 'title',
    resign_type: 'resign_type',
    resign_reason: 'resign_reason',
    last_working_day: 'last_working_day',
    last_effective_date: 'last_effective_date',
    year_at_cpn: 'year_at_cpn',
    l1: 'l1',
    l2: 'l2',
    l3: 'l3',
    l4: 'l4',
    l5: 'l5',
    l6: 'l6',
    l7: 'l7',
}

const HEADER = [
    "STT",
    "Mã NV",
    "Họ và tên",
    "Chức danh",
    "Loại thôi việc",
    "Lý do thôi việc",
    "Ngày làm việc cuối",
    "Ngày hiệu lực",
    "Số năm làm việc",
    "Tập đoàn",
    "Đơn vị thành viên",
    'Khối/Khu vực',
    'Phòng/Ban',
    'Bộ phận',
    'Tổ nhóm',
    'Cấp bổ sung',
]

export function defineEmployeeResignReportExportColumns(chartSheet: ExcelJS.Worksheet) {
    const dataStyle: Partial<ExcelJS.Style> = {
        alignment: {vertical: 'middle', horizontal: 'left'},
        font: {size: 11},
    }

    chartSheet.columns = [
        {key: columnsKey.no, width: 10, style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}},
        {key: columnsKey.code, width: 20, style: dataStyle},
        {key: columnsKey.full_name, width: 20, style: dataStyle},
        {key: columnsKey.title, width: 20, style: dataStyle},
        {key: columnsKey.resign_type, width: 20, style: dataStyle},
        {key: columnsKey.resign_reason, width: 30, style: dataStyle},
        {
            key: columnsKey.last_working_day,
            width: 20,
            style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}
        },
        {
            key: columnsKey.last_effective_date,
            width: 20,
            style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}
        },
        {
            key: columnsKey.year_at_cpn,
            width: 20,
            style: {...dataStyle, alignment: {vertical: 'middle', horizontal: 'right'}}
        },
        {key: columnsKey.l1, width: 20, style: dataStyle},
        {key: columnsKey.l2, width: 30, style: dataStyle},
        {key: columnsKey.l3, width: 20, style: dataStyle},
        {key: columnsKey.l4, width: 20, style: dataStyle},
        {key: columnsKey.l5, width: 20, style: dataStyle},
        {key: columnsKey.l6, width: 20, style: dataStyle},
        {key: columnsKey.l7, width: 20, style: dataStyle},
    ]
}

export function setEmployeeResignReportExportHeader(chartSheet: ExcelJS.Worksheet) {
    chartSheet.addRow(HEADER)
}

export function styleEmployeeResignReportExport(chartSheet: ExcelJS.Worksheet, dataCount: number, headerCount = 1) {
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

export function addDataEmployeeResignReportExport(chartSheet: ExcelJS.Worksheet, employees: Object, officeOrgs: ListOOC[]) {
    let no = 1;
    for (const emp of Object.values(employees)) {
        const lever = explainOfficeOrgChartToObj(emp?.department?.path, officeOrgs, ORG_CHART_MAX_LEVER_SHOWING)

        chartSheet.addRow({
            no: no++,
            code: emp['code'],
            full_name: emp['fullname'],
            title: emp?.title?.name,
            resign_type: emp?.resignationType,
            resign_reason: emp.resignationReason,
            last_working_day: emp.lastWorkingOn,
            last_effective_date: emp.leaveOn,
            year_at_cpn: emp.onboardingOn ? countYearBetweenTwoDate(emp.onboardingOn, emp.leaveOn) : '-',
            ...lever,
        })
    }

    return no - 1;
}