import * as ExcelJS from "exceljs";
import {
    identifyCardPlaceListValue
} from "@modules/graphql/master-data/helpers/identify-card-place.master-data.helper";

export const IMPORT_USER_SHEET_DATA_NAME = 'SheetData'
export const IMPORT_USER_COMMON_HEADER = {
    id: "ID",
    code: "Mã nhân viên",
    status: "Trạng thái (*)",
    fullname: "Họ và tên (*)",
    phone: "Số điện thoại (*)",
    title: "Chức danh",
    department: "Phòng ban (*)",
    leaderCode: "Quản lý trực tiếp (*)",
    email: "Email công ty",
    personalEmail: "Email cá nhân",
    address: "Địa chỉ chi tiết",
    province: "Tỉnh/Thành phố (*)",
    district: "Quận/Huyện (*)",
    ward: "Xã/Phường (*)",
    identityCard: "Số CCCD/CMND (*)",
    idCardIssuedOn: "Ngày cấp (*)",
    idCardIssuedPlace: "Nơi cấp (*)",
    birthday: "Ngày sinh (*)",
    hrCode: "Mã chấm công",
    major: "Ngạch bậc (*)",
    onboardingOn: "Ngày vào công ty (*)",
    officalWorkingOn: "Ngày chính thức",
    /*resigned: "Thôi việc (*)",
    resignationType: "Loại thôi việc",
    resignationReason: "Lý do thôi việc",
    resignationDetailReason: "Diễn giải lý do",
    lastWorkingOn: "Ngày làm việc cuối cùng",
    leaveOn: "Ngày hiệu lực thôi việc",*/
    taxCode: "Mã số thuế cá nhân",
    socialInsuranceCode: "Mã số BHXH",
    relativePhone: "SĐT người thân",
    bankName: "Tên ngân hàng",
    bankBranch: "Chi nhánh",
    accountHolder: "Chủ tài khoản",
    accountNumber: "STK",
}

export const IMPORT_USER_COMMON_DATA_DEMO = [
    {
        id: "",
        code: "T0000001",
        status: "Active",
        fullname: "Nguyễn Văn A",
        phone: "098395421",
        title: "CV1",
        department: "MB1",
        leaderCode: "T000120001",
        email: "nguyenvana@email-test.com",
        personalEmail: "Email cá nhân",
        address: "Số 9 ngõ 120",
        province: "Hà Nội",
        district: "Thanh Trì",
        ward: "Thanh Liệt",
        identityCard: "2345677332",
        idCardIssuedOn: "DD/MM/YYYY",
        idCardIssuedPlace: "Hà Nội",
        birthday: "DD/MM/YYYY",
        hrCode: "11AB",
        major: "1",
        onboardingOn: "DD/MM/YYYY",
        officalWorkingOn: "DD/MM/YYYY",
        resigned: "Có",
        resignationType: "Nghỉ không lý do",
        resignationReason: "Khác",
        resignationDetailReason: "Diễn giải lý do",
        lastWorkingOn: "DD/MM/YYYY",
        leaveOn: "DD/MM/YYYY",
        taxCode: "12345",
        socialInsuranceCode: "12345",
        relativePhone: "098395421",
        bankName: "Vietcombank",
        bankBranch: "Hà Nội",
        accountHolder: "Nguyễn Văn A",
        accountNumber: "12345",
    },
    {
        id: "12345",
        code: "T0000002",
        status: "Inactive",
        fullname: "Nguyễn Văn A",
        phone: "098395421",
        title: "CV1",
        department: "MB1",
        leaderCode: "T000120001",
        email: "nguyenvana@email-test.com",
        personalEmail: "Email cá nhân",
        address: "Số 9 ngõ 120",
        province: "Hà Nội",
        district: "Thanh Trì",
        ward: "Thanh Liệt",
        identityCard: "2345677332",
        idCardIssuedOn: "DD/MM/YYYY",
        idCardIssuedPlace: "Hà Nội",
        birthday: "DD/MM/YYYY",
        hrCode: "11AB",
        major: "1",
        onboardingOn: "DD/MM/YYYY",
        officalWorkingOn: "DD/MM/YYYY",
        resigned: "Có",
        resignationType: "Nghỉ không lý do",
        resignationReason: "Khác",
        resignationDetailReason: "Diễn giải lý do",
        lastWorkingOn: "DD/MM/YYYY",
        leaveOn: "DD/MM/YYYY",
        taxCode: "12345",
        socialInsuranceCode: "12345",
        relativePhone: "098395421",
        bankName: "Vietcombank",
        bankBranch: "Hà Nội",
        accountHolder: "Nguyễn Văn A",
        accountNumber: "12345",
    },
]

const dataStyle: Partial<ExcelJS.Style> = {
    alignment: {vertical: 'middle', horizontal: 'center'},
    font: {size: 11},
}

export function defineAndSetImportUserHeader(chartSheet: ExcelJS.Worksheet, softRows: object) {
    const rows = {
        ...IMPORT_USER_COMMON_HEADER,
        ...softRows
    }

    const columns = []
    Object.keys(rows).map(i => columns.push({key: i, width: 10 + rows[i].length, style: dataStyle}))

    chartSheet.columns = columns
    chartSheet.addRow(rows)
}

export function styleImportUser(chartSheet: ExcelJS.Worksheet) {
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

export function importUserTemplateAddDemoData(chartSheet: ExcelJS.Worksheet, softRowsDemoData: object) {
    for (const row of IMPORT_USER_COMMON_DATA_DEMO) {
        chartSheet.addRow({
            ...row,
            ...softRowsDemoData
        })
    }
}

export function addListToCells(chartSheet: ExcelJS.Worksheet) {
    chartSheet.getColumn('idCardIssuedPlace').eachCell(cell => cell.dataValidation = {
        type: 'list',
        allowBlank: true,
        showErrorMessage: true,
        formulae: [`=${IMPORT_USER_SHEET_DATA_NAME}!$A$1:$A$1000`]
    })
}

export function importUserTemplateExportSheetDataAddData(chartSheet: ExcelJS.Worksheet) {
    chartSheet.columns = [{key: 'idCardIssuedPlace', letter: 'A'}]

    const idCardIssuedPlaceFormulae = identifyCardPlaceListValue()

    identifyCardPlaceListValue().map(i => ( chartSheet.addRow({idCardIssuedPlace: i})))
}
