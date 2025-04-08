import * as ExcelJS from "exceljs";

export enum WORK_PROFILE_EXPORT_TYPE {
    TEMPLATE = 'TEMPLATE',
    DATA = 'DATA',
}

export const IMPORT_WORK_PROFILE_COMMON_HEADER = {
    id: "ID",
    userCodeUpdate: "Mã nhân viên cũ",
    typeText: "Hình thức (*)",
    activeDate: "Ngày hiệu lực (*)",
    endDate: "Ngày hết hạn",
    reason: "Lý do thay đổi",
    decided: "Quyết định",
    decidedNumber: "Số quyết định",
    decidedDate: "Ngày quyết định",
    userCode: "Mã nhân viên mới",
    major: "Ngạch bậc",
    department: "Phòng ban",
    title: "Chức danh",
    leader: "Quản lý trực tiếp",
    note: "Ghi chú",
}

export const IMPORT_USER_COMMON_DATA_DEMO = [
    {
        id: "12345",
        userCodeUpdate: "",
        typeText: "Chính thức",
        activeDate: "DD/MM/YYYY",
        endDate: "DD/MM/YYYY",
        reason: "Lý do thay đổi",
        decided: "Có",
        decidedNumber: "QDD214123-123",
        decidedDate: "DD/MM/YYYY",
        userCode: "U123412",
        title: "CV1",
        department: "MB1",
        leader: "T000120001",
        major: "1",
        note: "Xinh",
    },
    {
        id: "",
        userCodeUpdate: "U123412",
        typeText: "Tuyển mới",
        activeDate: "DD/MM/YYYY",
        endDate: "DD/MM/YYYY",
        reason: "Lý do thay đổi",
        decided: "Không",
        decidedNumber: "",
        decidedDate: "",
        userCode: "U123413",
        title: "CV1",
        department: "MB1",
        leader: "T000120001",
        major: "1",
        note: "Đep",
    },
]

const dataStyle: Partial<ExcelJS.Style> = {
    alignment: {vertical: 'middle', horizontal: 'center'},
    font: {size: 11},
}

export function defineAndSetImportWorkProfileHeader(chartSheet: ExcelJS.Worksheet, softRows: object) {
    const rows = {
        ...IMPORT_WORK_PROFILE_COMMON_HEADER,
        ...softRows
    }

    const columns = []
    Object.keys(rows).map(i => columns.push({key: i, width: 10 + rows[i].length, style: dataStyle}))

    chartSheet.columns = columns
    chartSheet.addRow(rows)
}

export function styleImportWorkProfile(chartSheet: ExcelJS.Worksheet) {
    chartSheet.getRows(1, 1).map(row => {
        row.font = {'bold': true}
        row.border = {
            top: {
                style: 'medium',
                color: {
                    argb: "FF000000"
                }
            },
            bottom: {
                style: 'medium',
                color: {
                    argb: "FF000000"
                }
            },
            right: {
                style: 'medium',
                color: {
                    argb: "FF000000"
                }
            },
        }
        row.fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: {
                argb: "FF9BC2E6"
            }
        }
    })
}

export function importWorkProfileTemplateAddDemoData(chartSheet: ExcelJS.Worksheet, softRowsDemoData: object) {
    for (const row of IMPORT_USER_COMMON_DATA_DEMO) {
        chartSheet.addRow({
            ...row,
            ...softRowsDemoData
        })
    }
}
