import { forwardRef, Inject, Injectable } from '@nestjs/common';
import {
    AssetBulkUpsertInput,
    AssetCreateInput,
    AssetUpdateInput,
    ManagementAssetFilter
} from "@modules/graphql/management/asset/asset/dto/asset.args";
import {
    AssetRepo,
    CategoryAssetRepo,
    OfficeOrgChartRepo,
    OfficeUserRepo,
    WarehouseAssetRepo
} from "@repositories/index";
import { getDateByTimestamp, getDateFutureMonthByDate } from "@utils/datetime.utils";
import { AssetStatus } from "@enum/asset/asset.enum";
import { RequestContext } from "@common/context/request.context";
import { DataSource } from "typeorm";
import { Asset } from "@models/entities";
import {
    ASSET_EXPORT_TYPE, defineAndSetImportAssetHeader,
    IMPORT_ASSET_COMMON_HEADER, importAssetTemplateAddDemoData, styleImportAsset
} from "@modules/graphql/management/asset/asset/helpers/template/import-asset.template.helper";
import * as ExcelJS from "exceljs";
import { FileCleanType } from "@core/storage/objects/file";
import { StorageService } from "@core/storage/storage.service";
import { OfficeSuccessMessage } from "@common/office.success";
import { AssetBulkUpsertRecordResponse } from "@modules/graphql/management/asset/asset/dto/asset.response";
import { OfficeError, OfficeErrorMessage } from "@common/office.error";

@Injectable()
export class AssetService {

    constructor(
        private dataSource: DataSource,
        private readonly assetRepo: AssetRepo,
        private readonly orgChartRepo: OfficeOrgChartRepo,
        private readonly officeUserRepo: OfficeUserRepo,
        private readonly categoryAssetRepo: CategoryAssetRepo,
        private readonly warehouseAssetRepo: WarehouseAssetRepo,
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
    ) {
    }

    async create(args: AssetCreateInput) {
        let count = 0;
        const assets = []

        while (count < args.quantity) {
            const record = await this.createNew(args)

            assets.push(record)
            count++;
        }

        for (const asset of assets) {
            await this.assetRepo.save(asset)
        }

        return assets
    }

    private async createNew(args: AssetCreateInput) {
        const sysId = RequestContext.currentRequestId()
        const inUse = args.assignedUserId || args.assignedDepartmentId

        const record = this.assetRepo.create({
            name: args.name,
            serial: args.serial,
            imageIds: args.imageIds,
            description: args.description,
            price: args.price,
            purchaseAt: getDateByTimestamp(args.purchaseAt),
            monthlyDepreciation: args.monthlyDepreciation,
            warrantyByMonth: args.warrantyByMonth,
            warrantyExpiredAt: getDateByTimestamp(args.warrantyExpiredAt),
            status: inUse ? AssetStatus.InUse : AssetStatus.InStock,
            attachmentIds: args.attachmentIds,
            providerText: args.providerText,
            warehouse: args.warehouseId ? await this.warehouseAssetRepo.findOneBy({id: args.warehouseId}) : null,
            createdBy: sysId,
            department: args.department, //fix
            category: args.categoryId ? await this.categoryAssetRepo.findOneBy({id: args.categoryId}) : null,
        })

        if (args.managementDepartmentId) {
            record.managementDepartment = await this.orgChartRepo.findOneBy({id: args.managementDepartmentId})
            record.managementUser = null
        }

        if (args.managementUserId) {
            record.managementDepartment = null
            record.managementUser = await this.officeUserRepo.getById(args.managementUserId)
        }

        if (inUse) {
            if (args.assignedDepartmentId) {
                record.assignedDepartment = await this.orgChartRepo.findOneBy({id: args.assignedDepartmentId})
                record.assignedUser = null
            }

            if (args.assignedUserId) {
                record.assignedDepartment = null
                record.assignedUser = await this.officeUserRepo.getById(args.assignedUserId)
            }
        }

        return record
    }

    async list(filter: ManagementAssetFilter) {
        const [data, total] = await this.assetRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async update(args: AssetUpdateInput) {
        const sysId = RequestContext.currentRequestId()
        const asset = await this.assetRepo.findOneBy({id: args.id})

        await this.assetRepo.save(
            {
                id: args.id,
                name: args.name ?? asset.name,
                serial: args.serial ?? asset.serial,
                description: args.description ?? asset.description,
                price: args.price ?? asset.price,
                purchaseAt: args.purchaseAt ? getDateByTimestamp(args.purchaseAt) : asset.purchaseAt,
                monthlyDepreciation: args.monthlyDepreciation ?? asset.monthlyDepreciation,
                warrantyByMonth: args.warrantyByMonth ?? asset.warrantyByMonth,
                warrantyExpiredAt: args.warrantyExpiredAt ? getDateByTimestamp(args.warrantyExpiredAt) : asset.warrantyExpiredAt,
                providerText: args.providerText ?? asset.providerText,
                updatedBy: sysId,
            })

        /*Todo: need logic*/
        if (args.warehouseId || args.assignedUserId || args.assignedDepartmentId) {
            const inUse = args.assignedUserId || args.assignedDepartmentId

            asset.status = inUse ? AssetStatus.InUse : AssetStatus.InStock
            asset.warehouse = args.warehouseId ? await this.warehouseAssetRepo.findOneBy({id: args.warehouseId}) : null
        }

        if (args.managementDepartmentId) {
            asset.managementDepartment = await this.orgChartRepo.findOneBy({id: args.managementDepartmentId})
            asset.managementUser = null
        }

        if (args.managementUserId) {
            asset.managementDepartment = null
            asset.managementUser = await this.officeUserRepo.getById(args.managementUserId)
        }

        if (args.assignedDepartmentId) {
            asset.assignedDepartment = await this.orgChartRepo.findOneBy({id: args.assignedDepartmentId})
            asset.assignedUser = null
        }

        if (args.assignedUserId) {
            asset.assignedDepartment = null
            asset.assignedUser = await this.officeUserRepo.getById(args.assignedUserId)
        }

        if (args.attachmentIds) {
            args.attachmentIds.push(...asset.attachmentIds)
            asset.attachmentIds = args.attachmentIds
        }

        if (args.imageIds) {
            args.imageIds.push(...asset.imageIds)
            asset.imageIds = args.imageIds
        }

        await asset.save()
        await asset.reload()

        return asset;
    }

    async bulkUpsert(args: AssetBulkUpsertInput[]) {
        for (const row of args) {
            if (row.errorMessage) continue

            if (row.assignedDepartmentCode && row.assignedUserCode) {
                row.errorMessage = OfficeErrorMessage.AssetOnlyOneAssignData
                continue
            }

            if (row.managementDepartmentCode && row.managementUserCode) {
                row.errorMessage = OfficeErrorMessage.AssetOnlyOneManagementData
                continue
            }

            const data = {
                ...row,
                attachmentIds: [],
                imageIds: [],
                warrantyExpiredAt: (row.monthlyDepreciation && row.warrantyByMonth) ? getDateFutureMonthByDate(row.monthlyDepreciation, row.warrantyByMonth).getTime() : null
            }

            try {
                if (row.assetCode) {
                    /*update*/
                    await this.update({
                        ...data,
                        id: row.assetId
                    } as AssetUpdateInput)

                    row.errorMessage = OfficeSuccessMessage.Update
                } else {
                    /*create*/
                    await this.create(data as AssetCreateInput)

                    row.errorMessage = OfficeSuccessMessage.Create
                }
            } catch (err) {
                const mess = err?.baseMsg
                row.errorMessage = mess ?? (typeof err?.response?.message === 'string' ? err?.response?.message : err?.response?.message?.[0])
            }

        }

        return {
            total: args.length,
            count: args.length,
            records: args.map(i => ({
                ...i,
                warrantyByMonth: i.warrantyByMonth?.toString(),
                monthlyDepreciation: i.monthlyDepreciation?.toString(),
                quantity: i.quantity?.toString(),
                price: i.price?.toString(),
            })) as AssetBulkUpsertRecordResponse[]
        };
    }

    managementImportAssetFieldsKeyList() {
        return {fields : Object.keys(IMPORT_ASSET_COMMON_HEADER)}
    }

    managementImportAssetFieldsTitleList() {
        return {fields : Object.values(IMPORT_ASSET_COMMON_HEADER)}
    }

    importAssetTemplateExport() {
        return this.assetFileDataExport(ASSET_EXPORT_TYPE.TEMPLATE, {
            sheetName: 'Template import tài sản',
            excelName: `Template-import-asset.xlsx`
        })
    }

    private async assetFileDataExport(type: ASSET_EXPORT_TYPE, param: { sheetName: string; excelName: string; data?: Asset[] }) {
        const {sheetName, excelName, data} = param
        const workbook = new ExcelJS.Workbook();

        workbook.created = new Date();
        workbook.modified = new Date();
        workbook.lastPrinted = new Date();

        let chartSheet = workbook.addWorksheet(sheetName)

        defineAndSetImportAssetHeader(chartSheet)
        switch (type) {
            case ASSET_EXPORT_TYPE.TEMPLATE:
                importAssetTemplateAddDemoData(chartSheet)
                break
            case ASSET_EXPORT_TYPE.DATA:
                break

        }

        styleImportAsset(chartSheet)

        const excelBuffer = await workbook.xlsx.writeBuffer()
        return this.storageService.uploadObject(
            RequestContext.currentToken(),
            excelBuffer,
            excelName,
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'management/employee',
            FileCleanType.Never
        )
    }

    get(id: string) {
        return this.assetRepo.getById(id);
    }

    async remove(id: string) {
        const asset = await this.assetRepo.getById(id)

        if (!asset) {
            throw OfficeError.AssetNotFound
        }

        await asset.softRemove()

        return id;
    }
}
