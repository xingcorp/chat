import { Inject, Injectable, forwardRef } from "@nestjs/common";
import * as ExcelJS from 'exceljs';
import { OfficeUser } from "@models/entities";
import { FileCleanType } from "@core/storage/objects/file";
import { StorageService } from "@core/storage/storage.service";
import { UpsertAssetResult } from "./asset.response";
import { InjectModel, Model } from 'nestjs-dynamoose';
import { RandomHelper } from "@common/random";
import { NfcHistoryArgs } from "./asset.args";
import { NfcHistory, NfcHistoryKey } from "@modules/graphql/management/asset/old/schema/nfc.history.schema";

@Injectable()
export class AssetServiceOld {
    constructor(
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,

        @InjectModel('nfc-history')
        private readonly model: Model<NfcHistory, NfcHistoryKey>,
    ) { }

    public createImportResultFile = async (
        token: string,
        actionType: string,
        // actionBy: OfficeUser,
        columnName: any,
        results: UpsertAssetResult[]
    ) => {
        const workbook = new ExcelJS.Workbook()
        // workbook.creator = actionBy.fullname ? actionBy.fullname : actionBy.email
        // workbook.lastModifiedBy = actionBy.fullname ? actionBy.fullname : actionBy.email
        workbook.created = new Date()
        workbook.modified = new Date()
        workbook.lastPrinted = new Date()

        const rsSheet = workbook.addWorksheet('ASSET_RESULT')
        const keys = Object.keys(columnName)
        const headers = Object.values(columnName)
        const columns = headers.map((headerText, index) => {
            return {
                header: headerText as string,
                key: keys[index],
                width: 20
            }
        })
        columns.push({ header: 'Kết quả', key: 'result', width: 40 })
        rsSheet.columns = columns

        rsSheet.autoFilter = {
            from: 'A1',
            to: 'T1',
        }

        const firstRow = rsSheet.getRow(1);
        firstRow.alignment = {
            vertical: 'middle',
            horizontal: 'center'
        };

        firstRow.font = {
            'bold': true,
            'size': 13
        };

        for (const rs of results) {
            const rowValues = Object.values(rs)
            rsSheet.addRow(rowValues)
        }

        const excelName = `${actionType}-${(new Date()).getTime()}.xlsx`
        const excelBuffer = await workbook.xlsx.writeBuffer()
        const uploadedExcel = await this.storageService.uploadObject(
            token,
            excelBuffer,
            excelName,
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'assets',
            FileCleanType.Never
        )

        return uploadedExcel.location
    }

    public async nfcHistoryCreate(payload: NfcHistoryArgs, requesterId: string) {
        return this.model.create({
            ...payload,
            id: payload.id ? payload.id : RandomHelper.generateUUID(),
            createdAt: new Date(),
            updatedAt: new Date(),
            createdBy: requesterId,
            updatedBy: requesterId
        })
    }
}