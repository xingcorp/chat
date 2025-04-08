import { Injectable } from "@nestjs/common";
import * as ExcelJS from 'exceljs'

export interface ColumnInterface {
    header: string,
    key?: string,
    width?: number,
}

export interface WriteFileExcelArgs {
    data: any[],
    keysName: string[],
    columns: ColumnInterface[],
}

@Injectable()
export class ExcelService {
    writeFileExcel(args: WriteFileExcelArgs) {
        const workbook = new ExcelJS.Workbook()

        const worksheet = workbook.addWorksheet("Products", {
            views: [
                { state: 'frozen', xSplit: 1, ySplit: 1 },
            ]
        });
        worksheet.columns = args.columns;
        const firstRow = worksheet.getRow(1);
        firstRow.alignment = {
            vertical: 'middle',
            horizontal: 'center'
        };
        firstRow.font = {
            'bold': true,
            'size': 13
        };
        args.data.forEach(element => {
            const rowData = []
            args.keysName.forEach(key => {
                rowData.push(element[key])
            })
            worksheet.addRow(rowData).commit();
        });
        return workbook.xlsx.writeBuffer()
    }
}