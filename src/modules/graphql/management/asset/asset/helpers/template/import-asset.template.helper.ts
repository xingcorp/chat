import * as ExcelJS from "exceljs";

export enum ASSET_EXPORT_TYPE {
    TEMPLATE = 'TEMPLATE',
    DATA = 'DATA',
}
export const IMPORT_ASSET_COMMON_HEADER = {
    assetCode: "Mã tài sản",
    name: "Tên tài sản (*)",
    quantity: "Số lượng (*)",
    serial: "Model/Serial",
    description: "Mô tả",
    categoryCode: "Danh mục tài sản (*)",
    purchaseDate: "Ngày mua (*)",
    warrantyByMonth: "Thời gian bảo hành (tháng)",
    // warrantyExpiredDate: "Hạn bảo hành",
    providerText: "Nhà cung cấp",
    warehouseCode: "Kho lưu trữ",
    managementUserCode: "Cá nhân quản lý",
    managementDepartmentCode: "Phòng ban quản lý",
    assignedUserCode: "Cá nhân sử dụng",
    assignedDepartmentCode: "Phòng ban sử dụng",
    price: "Giá mua",
    monthlyDepreciation: "Khấu hao",
}

export const IMPORT_ASSET_DATA_DEMO = [
    {
        assetCode: "",
        name: "Laptop 1",
        quantity: "1",
        serial: "S123",
        description: "Mô tả",
        categoryCode: "CA123",
        purchaseDate: "'DD/MM/YYYY",
        warrantyByMonth: "12",
        warrantyExpiredDate: "'DD/MM/YYYY",
        providerText: "Điện Máy Xanh",
        warehouseCode: "WH01",
        managementUserCode: "U123",
        managementDepartmentCode: "P123",
        assignedUserCode: "U124",
        assignedDepartmentCode: "P124",
        price: "1000000",
        monthlyDepreciation: "50000",
    },
    {
        assetCode: "",
        name: "Laptop 2",
        quantity: "1",
        serial: "S123",
        description: "Mô tả",
        categoryCode: "CA123",
        purchaseDate: "'DD/MM/YYYY",
        warrantyByMonth: "12",
        warrantyExpiredDate: "'DD/MM/YYYY",
        providerText: "Điện Máy Xanh",
        warehouseCode: "WH01",
        managementUserCode: "U123",
        managementDepartmentCode: "P123",
        assignedUserCode: "U124",
        assignedDepartmentCode: "P124",
        price: "1000000",
        monthlyDepreciation: "50000",
    },
]

const dataStyle: Partial<ExcelJS.Style> = {
    alignment: {vertical: 'middle', horizontal: 'center'},
    font: {size: 11},
}

export function defineAndSetImportAssetHeader(chartSheet: ExcelJS.Worksheet) {
    const rows = {
        ...IMPORT_ASSET_COMMON_HEADER
    }

    const columns = []
    Object.keys(rows).map(i => columns.push({key: i, width: 10 + rows[i].length, style: dataStyle}))

    chartSheet.columns = columns
    chartSheet.addRow(rows)
}

export function importAssetTemplateAddDemoData(chartSheet: ExcelJS.Worksheet) {
    for (const row of IMPORT_ASSET_DATA_DEMO) {
        chartSheet.addRow({
            ...row,
        })
    }
}

export function styleImportAsset(chartSheet: ExcelJS.Worksheet) {
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