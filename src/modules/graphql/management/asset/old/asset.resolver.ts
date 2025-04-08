// import { Inject, SetMetadata, forwardRef } from "@nestjs/common";
// import { Args, Mutation, Query, Resolver } from "@nestjs/graphql";
// import { FileUpload, GraphQLUpload } from "graphql-upload";
// import { IdentityService } from "@core/iam/identity/identity.service";
// import { AddressService } from "@core/iam/organization/location/address.service";
// import { BearerAccessToken } from "@core/middleware/decorator/request.decorator";
// import { OfficeRequester, RequesterId, RootOfficeOrganization } from "@core/middleware/decorator/user.decorator";
// import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
// import { StorageService } from "@core/storage/storage.service";
// import * as ExcelJS from 'exceljs';
// import { OfficeError } from "@common/office.error";
// import { Asset, AssetStatus } from "@models/entities/asset/asset";
// import { OfficeOrgChart, OfficeUser, UserDepartment } from "@models/entities";
// import { CategoryAsset } from "@models/entities/asset/category.asset";
// import { AssetOwner } from "@models/entities/asset.owner";
// import { AssetMaintenance } from "@models/entities/asset.maintenance";
// import { RandomHelper } from "@common/random";
// import { DateFormater } from "@common/date.formater";
// import ShortUniqueId from 'short-unique-id';
// import { AssetNfcResponse, AssetResponse, UpsertAssetResult, UpsertAssetResultResponse } from "./asset.response";
// import { AssetServiceOld } from "./asset.service";
// import { ILike, In, IsNull, Not } from "typeorm";
// import { AssetFilter, AuditAssetArgs, NFCInfoArgs, NfcAssignmentArgs } from "./asset.args";
// import { AwsQLDBService } from "@modules/3rd/aws/qldb.service";
// import { AssetAudit } from "@models/entities/asset.audit";
// import { AssetAuditItem } from "@models/entities/asset.audit.item";
// import { BaseError } from "@core/core.error";
// import { AssetAssignment } from "@models/entities/asset.assignment";
// import { AssetAssignmentItem } from "@models/entities/asset.assignment.item";
//
// @Resolver()
// export class AssetResolver {
//     constructor(
//         @Inject(forwardRef(() => IdentityService))
//         private readonly identityService: IdentityService,
//
//         @Inject(forwardRef(() => StorageService))
//         private readonly storageService: StorageService,
//
//         @Inject(forwardRef(() => AddressService))
//         private readonly addressService: AddressService,
//
//         @Inject(forwardRef(() => AssetServiceOld))
//         private readonly assetService: AssetServiceOld,
//
//         @Inject(forwardRef(() => AwsQLDBService))
//         private readonly qldbService: AwsQLDBService,
//     ) { }
//
//     @Mutation(_type => UpsertAssetResultResponse, { nullable: true, name: "managementCreateAssetImport" })
//     @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
//     @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
//     async managementCreateAssetImport(
//         @Args({ name: "file", type: () => GraphQLUpload }) { createReadStream }: FileUpload,
//         @BearerAccessToken() token: string,
//         @RequesterId() requesterId: string,
//         // @OfficeRequester() officeRequester: OfficeUser,
//     ): Promise<UpsertAssetResultResponse> {
//         try {
//             const workbook = new ExcelJS.Workbook()
//             await workbook.xlsx.read(createReadStream())
//
//             const dataSheet = workbook.getWorksheet('ASSET')
//             if (!dataSheet) {
//                 throw OfficeError.EmptyExcelFile
//             }
//
//             const columnName = {
//                 AssetCategory: 'Danh mục tài sản*',
//                 AssetCode: 'Mã tài sản*',
//                 AssetName: 'Tên tài sản*',
//                 OrgChart: 'Tổ chức sở hữu*',
//                 Serial: 'SN#',
//                 Parameters: 'Thông số',
//                 Price: 'Giá tiền',
//                 PurchaseDate: 'Ngày mua',
//                 WarrantyDate: 'Thời gian bảo hành',
//                 Provider: 'Đơn vị bán',
//                 SupplyDate: 'Ngày cấp',
//                 OfficeUser: 'Nhân viên sử dụng',
//                 SupplyReason: 'Lý do cấp',
//                 UpgradeRepair: 'Nâng cấp - sửa chữa',
//                 HandOverReceipt: 'Mã BBTH tài sản',
//                 HandOverDate: 'Ngày bàn giao Kho HC',
//                 HandOverReason: 'Lý do bàn giao',
//                 HandOverStatus: 'Tình trạng máy khi bàn giao',
//                 HandOverUser: 'Nhân sự nhận bàn giao'
//             }
//
//             let columnIndexDict: any = {}
//             const headerColumn = dataSheet.getRow(1).values
//             for (let index = 1; index <= Number(headerColumn.length); index++) {
//                 columnIndexDict[headerColumn[index]] = index
//             }
//
//             const assetCategoryList = await CategoryAsset.find()
//             const uniqueGenerator = new ShortUniqueId({
//                 dictionary: ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
//                 length: 10
//             })
//             const insertAssets: Asset[] = []
//             const insertAssetOwners: AssetOwner[] = []
//             const insertAssetMaintenances: AssetMaintenance[] = []
//             const existedAssetCodes: String[] = []
//             const existedAssetSerials: String[] = []
//             const orgChartList: OfficeOrgChart[] = []
//             const employeeList: OfficeUser[] = []
//             const response: UpsertAssetResult[] = []
//             const rowData = dataSheet.getRows(2, dataSheet.rowCount - 1)
//             for (let row of rowData) {
//                 const input: UpsertAssetResult = {
//                     assetCategory: row.getCell(columnIndexDict[columnName.AssetCategory]).text.trim(),
//                     assetCode: row.getCell(columnIndexDict[columnName.AssetCode]).text.trim(),
//                     assetName: row.getCell(columnIndexDict[columnName.AssetName]).text.trim(),
//                     orgChart: row.getCell(columnIndexDict[columnName.OrgChart]).text.trim(),
//                     serial: row.getCell(columnIndexDict[columnName.Serial]).text.trim(),
//                     parameters: row.getCell(columnIndexDict[columnName.Parameters]).text.trim(),
//                     price: row.getCell(columnIndexDict[columnName.Price]).text.trim(),
//                     purchaseDate: row.getCell(columnIndexDict[columnName.PurchaseDate]).text.trim(),
//                     warrantyDate: row.getCell(columnIndexDict[columnName.WarrantyDate]).text.trim(),
//                     provider: row.getCell(columnIndexDict[columnName.Provider]).text.trim(),
//                     supplyDate: row.getCell(columnIndexDict[columnName.SupplyDate]).text.trim(),
//                     officeUser: row.getCell(columnIndexDict[columnName.OfficeUser]).text.trim(),
//                     supplyReason: row.getCell(columnIndexDict[columnName.SupplyReason]).text.trim(),
//                     upgradeRepair: row.getCell(columnIndexDict[columnName.UpgradeRepair]).text.trim(),
//                     handOverReceipt: row.getCell(columnIndexDict[columnName.HandOverReceipt]).text.trim(),
//                     handOverDate: row.getCell(columnIndexDict[columnName.HandOverDate]).text.trim(),
//                     handOverReason: row.getCell(columnIndexDict[columnName.HandOverReason]).text.trim(),
//                     handOverStatus: row.getCell(columnIndexDict[columnName.HandOverStatus]).text.trim(),
//                     handOverUser: row.getCell(columnIndexDict[columnName.HandOverUser]).text.trim()
//                 }
//                 if (input.purchaseDate) input.purchaseDate = DateFormater.dateStringToStringWithFormat(input.purchaseDate, 'DD/MM/yyyy')
//                 if (input.warrantyDate) input.warrantyDate = DateFormater.dateStringToStringWithFormat(input.warrantyDate, 'DD/MM/yyyy')
//                 if (input.supplyDate) input.supplyDate = DateFormater.dateStringToStringWithFormat(input.supplyDate, 'DD/MM/yyyy')
//                 if (input.handOverDate) input.handOverDate = DateFormater.dateStringToStringWithFormat(input.handOverDate, 'DD/MM/yyyy')
//
//                 if (!input.assetCategory || !input.assetCode || !input.assetName || !input.orgChart) {
//                     response.push({ ...input, result: 'Vui lòng không để trống trường bắt buộc' })
//                     continue
//                 }
//
//                 if (existedAssetCodes.includes(input.assetCode)) {
//                     response.push({ ...input, result: 'Mã tài sản đã tồn tại trên hệ thống' })
//                     continue
//                 } else {
//                     const existedAsset = await Asset.findOne({ where: { code: input.assetCode } })
//                     if (existedAsset) {
//                         existedAssetCodes.push(input.assetCode)
//                         response.push({ ...input, result: 'Mã tài sản đã tồn tại trên hệ thống' })
//                         continue
//                     }
//                 }
//
//                 let orgChart = orgChartList.find(oc => oc.code === input.orgChart)
//                 if (!orgChart) {
//                     orgChart = await OfficeOrgChart.findOne({ where: { code: input.orgChart } })
//                     if (!orgChart) {
//                         response.push({ ...input, result: 'Mã tổ chức không tồn tại trên hệ thống' })
//                         continue
//                     } else {
//                         orgChartList.push(orgChart)
//                     }
//                 }
//
//                 let category = assetCategoryList.find(c => c.code === input.assetCategory)
//                 if (!category) {
//                     response.push({ ...input, result: 'Mã danh mục tài sản không tồn tại trên hệ thống' })
//                     continue
//                 }
//
//                 let serial = null
//                 if (input.serial) {
//                     if (existedAssetSerials.includes(input.serial)) {
//                         response.push({ ...input, result: 'SN# đã tồn tại trên hệ thống' })
//                         continue
//                     } else {
//                         const existedAsset = await Asset.findOne({ where: { serial: input.serial } })
//                         if (existedAsset) {
//                             existedAssetSerials.push(input.serial)
//                             response.push({ ...input, result: 'SN# đã tồn tại trên hệ thống' })
//                             continue
//                         } else {
//                             serial = input.serial
//                         }
//                     }
//                 } else {
//                     serial = `TS${uniqueGenerator.randomUUID()}`
//                 }
//
//                 let officeUser = null
//                 if (input.officeUser) {
//                     officeUser = employeeList.find(e => e.code === input.officeUser)
//                     if (!officeUser) {
//                         officeUser = await OfficeUser.findOne({ where: { code: input.officeUser } })
//                         if (!officeUser) {
//                             response.push({ ...input, result: `Mã nhân viên không tồn tại trên hệ thống` })
//                             continue
//                         } else {
//                             employeeList.push(officeUser)
//                         }
//                     }
//                 }
//
//                 let handOverUser = null
//                 if (input.handOverUser) {
//                     handOverUser = employeeList.find(e => e.code === input.handOverUser)
//                     if (!handOverUser) {
//                         handOverUser = await OfficeUser.findOne({ where: { code: input.handOverUser } })
//                         if (!handOverUser) {
//                             response.push({ ...input, result: `Mã nhân viên không tồn tại trên hệ thống` })
//                             continue
//                         } else {
//                             employeeList.push(handOverUser)
//                         }
//                     }
//                 }
//
//                 const newAsset = Asset.create({
//                     id: RandomHelper.generateUUID(),
//                     categoryId: category.id,
//                     name: input.assetName,
//                     code: input.assetCode,
//                     departmentId: orgChart.id,
//                     serial: serial,
//                     status: officeUser ? AssetStatus.InUse : AssetStatus.InStock,
//                     parameters: input.parameters,
//                     price: input.price ? Number(input.price) : null,
//                     purchaseAt: input.purchaseDate ? DateFormater.stringToDateWithFormat(input.purchaseDate, 'DD/MM/yyyy') : null,
//                     warrantyExpiredAt: input.warrantyDate ? DateFormater.stringToDateWithFormat(input.warrantyDate, 'DD/MM/yyyy') : null,
//                     // purchaseAt: input.purchaseDate ? new Date(input.purchaseDate) : null,
//                     // warrantyExpiredAt: input.warrantyDate ? new Date(input.warrantyDate) : null,
//                     provider: input.provider,
//                     createdBy: requesterId,
//                     updatedBy: requesterId
//                 })
//                 if (input.supplyDate || input.officeUser || input.supplyReason) {
//                     const assetOwner = AssetOwner.create({
//                         id: RandomHelper.generateUUID(),
//                         assetId: newAsset.id,
//                         ownerId: officeUser?.id,
//                         supplyAt: input.supplyDate ? DateFormater.stringToDateWithFormat(input.supplyDate, 'DD/MM/yyyy') : null,
//                         // supplyAt: input.supplyDate ? new Date(input.warrantyDate) : null,
//                         reason: input.supplyReason,
//                         createdBy: requesterId,
//                         updatedBy: requesterId
//                     })
//                     newAsset.supplyId = assetOwner.id
//                     insertAssetOwners.push(assetOwner)
//                 }
//                 if (input.upgradeRepair || input.handOverReceipt || input.handOverDate || input.handOverReason || input.handOverStatus || input.handOverUser) {
//                     const assetMaintenance = AssetMaintenance.create({
//                         id: RandomHelper.generateUUID(),
//                         assetId: newAsset.id,
//                         content: input.upgradeRepair,
//                         handOverReceipt: input.handOverReceipt,
//                         handOverAt: input.handOverDate ? DateFormater.stringToDateWithFormat(input.handOverDate, 'DD/MM/yyyy') : null,
//                         // handOverAt: input.handOverDate ? new Date(input.warrantyDate) : null,
//                         reason: input.handOverReason,
//                         handOverStatus: input.handOverStatus,
//                         handOverUserId: handOverUser?.id,
//                         createdBy: requesterId,
//                         updatedBy: requesterId
//                     })
//                     newAsset.maintenanceId = assetMaintenance.id
//                     insertAssetMaintenances.push(assetMaintenance)
//                 }
//
//                 insertAssets.push(newAsset)
//                 response.push({ ...input, serial: serial, result: 'Tạo mới thành công' })
//                 existedAssetCodes.push(input.assetCode)
//                 existedAssetSerials.push(serial)
//             }
//
//             await Asset.save(insertAssets)
//             await AssetOwner.save(insertAssetOwners)
//             await AssetMaintenance.save(insertAssetMaintenances)
//             const resultFileUrl = await this.assetService.createImportResultFile(
//                 token,
//                 'CREATE',
//                 // officeRequester,
//                 columnName,
//                 response
//             )
//
//             return {
//                 total: rowData.length,
//                 count: insertAssets.length,
//                 resultFileUrl: resultFileUrl,
//                 // resultFileUrl: "",
//                 rows: response
//             }
//         } catch (error) {
//             console.log(`Import assets has error: ${error}`)
//             throw error
//         }
//     }
//
//     @Query(_return => AssetResponse, { name: "managementAssetGetAppList" })
//     @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
//     @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
//     async managementAssetGetAppList(
//         @Args("filter", { nullable: true }) filter: AssetFilter,
//         @RootOfficeOrganization() rootOrgIds: string[]
//     ): Promise<AssetResponse> {
//         var options: any = {}
//         //skip
//         if (filter && filter.page) {
//             let skip = !filter.size ? 0 : filter.size * (filter.page - 1)
//             skip = skip < 0 ? 0 : skip
//             options.skip = skip
//         } else {
//             options.skip = 0
//         }
//
//         //take
//         if (filter && filter.size) {
//             options.take = filter.size
//         } else {
//             options.take = 20
//         }
//
//         const departments = await OfficeOrgChart.find({
//             where: rootOrgIds.map(r => {
//                 return { path: ILike(`/${r}%`) }
//             })
//         })
//
//         let whereOptions: any = {
//             departmentId: In(departments.map(d => d.id))
//         }
//         if (filter && filter.hasNFC === true) {
//             whereOptions.nfcId = Not(IsNull())
//         }
//         if (filter && filter.hasNFC === false) {
//             whereOptions.nfcId = IsNull()
//         }
//         if (filter && filter.keyword) {
//             options.where = [
//                 {
//                     ...whereOptions,
//                     name: ILike(`%${filter.keyword}%`)
//                 },
//                 {
//                     ...whereOptions,
//                     code: ILike(`%${filter.keyword}%`)
//                 }
//             ]
//         } else {
//             options.where = whereOptions
//         }
//
//         options.order = {
//             name: "ASC"
//         }
//         const [list, count] = await Asset.findAndCount(options)
//
//         return {
//             total: count,
//             count: list.length,
//             assets: list
//         }
//     }
//
//     @Mutation(_type => UpsertAssetResultResponse, { nullable: true, name: "managementUpdateAssetImport" })
//     @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
//     @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
//     async managementUpdateAssetImport(
//         @Args({ name: "file", type: () => GraphQLUpload }) { createReadStream }: FileUpload,
//         @BearerAccessToken() token: string,
//         @RequesterId() requesterId: string,
//         // @OfficeRequester() officeRequester: OfficeUser,
//     ): Promise<UpsertAssetResultResponse> {
//         try {
//             const workbook = new ExcelJS.Workbook()
//             await workbook.xlsx.read(createReadStream())
//
//             const dataSheet = workbook.getWorksheet('ASSET')
//             if (!dataSheet) {
//                 throw OfficeError.EmptyExcelFile
//             }
//
//             const columnName = {
//                 AssetCategory: 'Danh mục tài sản*',
//                 AssetCode: 'Mã tài sản*',
//                 AssetName: 'Tên tài sản*',
//                 OrgChart: 'Tổ chức sở hữu*',
//                 Serial: 'SN#',
//                 Parameters: 'Thông số',
//                 Price: 'Giá tiền',
//                 PurchaseDate: 'Ngày mua',
//                 WarrantyDate: 'Thời gian bảo hành',
//                 Provider: 'Đơn vị bán',
//                 SupplyDate: 'Ngày cấp',
//                 OfficeUser: 'Nhân viên sử dụng',
//                 SupplyReason: 'Lý do cấp',
//                 UpgradeRepair: 'Nâng cấp - sửa chữa',
//                 HandOverReceipt: 'Mã BBTH tài sản',
//                 HandOverDate: 'Ngày bàn giao Kho HC',
//                 HandOverReason: 'Lý do bàn giao',
//                 HandOverStatus: 'Tình trạng máy khi bàn giao',
//                 HandOverUser: 'Nhân sự nhận bàn giao'
//             }
//
//             let columnIndexDict: any = {}
//             const headerColumn = dataSheet.getRow(1).values
//             for (let index = 1; index <= Number(headerColumn.length); index++) {
//                 columnIndexDict[headerColumn[index]] = index
//             }
//
//             const assetCategoryList = await CategoryAsset.find()
//             const uniqueGenerator = new ShortUniqueId({
//                 dictionary: ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
//                 length: 10
//             })
//             const insertAssets: Asset[] = []
//             const insertAssetOwners: AssetOwner[] = []
//             const insertAssetMaintenances: AssetMaintenance[] = []
//             // const existedAssetCodes: String[] = []
//             const existedAssetSerials: String[] = []
//             const orgChartList: OfficeOrgChart[] = []
//             const employeeList: OfficeUser[] = []
//             const response: UpsertAssetResult[] = []
//             const rowData = dataSheet.getRows(2, dataSheet.rowCount - 1)
//             for (let row of rowData) {
//                 const input: UpsertAssetResult = {
//                     assetCategory: row.getCell(columnIndexDict[columnName.AssetCategory]).text.trim(),
//                     assetCode: row.getCell(columnIndexDict[columnName.AssetCode]).text.trim(),
//                     assetName: row.getCell(columnIndexDict[columnName.AssetName]).text.trim(),
//                     orgChart: row.getCell(columnIndexDict[columnName.OrgChart]).text.trim(),
//                     serial: row.getCell(columnIndexDict[columnName.Serial]).text.trim(),
//                     parameters: row.getCell(columnIndexDict[columnName.Parameters]).text.trim(),
//                     price: row.getCell(columnIndexDict[columnName.Price]).text.trim(),
//                     purchaseDate: row.getCell(columnIndexDict[columnName.PurchaseDate]).text.trim(),
//                     warrantyDate: row.getCell(columnIndexDict[columnName.WarrantyDate]).text.trim(),
//                     provider: row.getCell(columnIndexDict[columnName.Provider]).text.trim(),
//                     supplyDate: row.getCell(columnIndexDict[columnName.SupplyDate]).text.trim(),
//                     officeUser: row.getCell(columnIndexDict[columnName.OfficeUser]).text.trim(),
//                     supplyReason: row.getCell(columnIndexDict[columnName.SupplyReason]).text.trim(),
//                     upgradeRepair: row.getCell(columnIndexDict[columnName.UpgradeRepair]).text.trim(),
//                     handOverReceipt: row.getCell(columnIndexDict[columnName.HandOverReceipt]).text.trim(),
//                     handOverDate: row.getCell(columnIndexDict[columnName.HandOverDate]).text.trim(),
//                     handOverReason: row.getCell(columnIndexDict[columnName.HandOverReason]).text.trim(),
//                     handOverStatus: row.getCell(columnIndexDict[columnName.HandOverStatus]).text.trim(),
//                     handOverUser: row.getCell(columnIndexDict[columnName.HandOverUser]).text.trim()
//                 }
//                 if (input.purchaseDate) input.purchaseDate = DateFormater.dateStringToStringWithFormat(input.purchaseDate, 'DD/MM/yyyy')
//                 if (input.warrantyDate) input.warrantyDate = DateFormater.dateStringToStringWithFormat(input.warrantyDate, 'DD/MM/yyyy')
//                 if (input.supplyDate) input.supplyDate = DateFormater.dateStringToStringWithFormat(input.supplyDate, 'DD/MM/yyyy')
//                 if (input.handOverDate) input.handOverDate = DateFormater.dateStringToStringWithFormat(input.handOverDate, 'DD/MM/yyyy')
//
//                 if (!input.assetCategory || !input.assetCode || !input.assetName || !input.orgChart) {
//                     response.push({ ...input, result: 'Vui lòng không để trống trường bắt buộc' })
//                     continue
//                 }
//
//                 // if (existedAssetCodes.includes(input.assetCode)) {
//                 //     response.push({ ...input, result: 'Mã tài sản đã tồn tại trên hệ thống' })
//                 //     continue
//                 // } else {
//                 //     const existedAsset = await Asset.findOne({ where: { code: input.assetCode } })
//                 //     if (existedAsset) {
//                 //         existedAssetCodes.push(input.assetCode)
//                 //         response.push({ ...input, result: 'Mã tài sản đã tồn tại trên hệ thống' })
//                 //         continue
//                 //     }
//                 // }
//                 const checkAsset = await Asset.findOne({ where: { code: input.assetCode } })
//                 if (!checkAsset) {
//                     response.push({ ...input, result: 'Mã tài sản không tồn tại trên hệ thống' })
//                     continue
//                 }
//
//                 let orgChart = orgChartList.find(oc => oc.code === input.orgChart)
//                 if (!orgChart) {
//                     orgChart = await OfficeOrgChart.findOne({ where: { code: input.orgChart } })
//                     if (!orgChart) {
//                         response.push({ ...input, result: 'Mã tổ chức không tồn tại trên hệ thống' })
//                         continue
//                     } else {
//                         orgChartList.push(orgChart)
//                     }
//                 }
//
//                 let category = assetCategoryList.find(c => c.code === input.assetCategory)
//                 if (!category) {
//                     response.push({ ...input, result: 'Mã danh mục tài sản không tồn tại trên hệ thống' })
//                     continue
//                 }
//
//                 let serial = null
//                 if (input.serial) {
//                     if (existedAssetSerials.includes(input.serial)) {
//                         response.push({ ...input, result: 'SN# đã tồn tại trên hệ thống' })
//                         continue
//                     } else {
//                         const existedAsset = await Asset.findOne({ where: { serial: input.serial } })
//                         if (existedAsset) {
//                             existedAssetSerials.push(input.serial)
//                             response.push({ ...input, result: 'SN# đã tồn tại trên hệ thống' })
//                             continue
//                         } else {
//                             serial = input.serial
//                         }
//                     }
//                 } else {
//                     serial = `TS${uniqueGenerator.randomUUID()}`
//                 }
//
//                 let officeUser = null
//                 if (input.officeUser) {
//                     officeUser = employeeList.find(e => e.code === input.officeUser)
//                     if (!officeUser) {
//                         officeUser = await OfficeUser.findOne({ where: { code: input.officeUser } })
//                         if (!officeUser) {
//                             response.push({ ...input, result: `Mã nhân viên không tồn tại trên hệ thống` })
//                             continue
//                         } else {
//                             employeeList.push(officeUser)
//                         }
//                     }
//                 }
//
//                 let handOverUser = null
//                 if (input.handOverUser) {
//                     handOverUser = employeeList.find(e => e.code === input.handOverUser)
//                     if (!handOverUser) {
//                         handOverUser = await OfficeUser.findOne({ where: { code: input.handOverUser } })
//                         if (!handOverUser) {
//                             response.push({ ...input, result: `Mã nhân viên không tồn tại trên hệ thống` })
//                             continue
//                         } else {
//                             employeeList.push(handOverUser)
//                         }
//                     }
//                 }
//
//                 // const newAsset = Asset.create({
//                 //     id: RandomHelper.generateUUID(),
//                 //     categoryId: category.id,
//                 //     name: input.assetName,
//                 //     code: input.assetCode,
//                 //     departmentId: orgChart.id,
//                 //     serial: serial,
//                 //     status: officeUser ? AssetStatus.InUse : AssetStatus.InStock,
//                 //     parameters: input.parameters,
//                 //     price: input.price ? Number(input.price) : null,
//                 //     purchaseAt: input.purchaseDate ? DateFormater.stringToDateWithFormat(input.purchaseDate, 'DD/MM/yyyy') : null,
//                 //     warrantyExpiredAt: input.warrantyDate ? DateFormater.stringToDateWithFormat(input.warrantyDate, 'DD/MM/yyyy') : null,
//                 //     // purchaseAt: input.purchaseDate ? new Date(input.purchaseDate) : null,
//                 //     // warrantyExpiredAt: input.warrantyDate ? new Date(input.warrantyDate) : null,
//                 //     provider: input.provider,
//                 //     createdBy: requesterId,
//                 //     updatedBy: requesterId
//                 // })
//                 checkAsset.categoryId = category.id
//                 checkAsset.name = input.assetName
//                 checkAsset.departmentId = orgChart.id
//                 if (input.serial) checkAsset.serial = input.serial
//                 checkAsset.status = officeUser ? AssetStatus.InUse : AssetStatus.InStock
//                 checkAsset.parameters = input.parameters
//                 checkAsset.price = input.price ? Number(input.price) : null
//                 checkAsset.purchaseAt = input.purchaseDate ? DateFormater.stringToDateWithFormat(input.purchaseDate, 'DD/MM/yyyy') : null
//                 checkAsset.warrantyExpiredAt = input.warrantyDate ? DateFormater.stringToDateWithFormat(input.warrantyDate, 'DD/MM/yyyy') : null
//                 checkAsset.provider = input.provider
//                 checkAsset.updatedBy = requesterId
//
//                 if (input.supplyDate || input.officeUser || input.supplyReason) {
//                     const assetOwner = AssetOwner.create({
//                         id: RandomHelper.generateUUID(),
//                         assetId: checkAsset.id,
//                         ownerId: officeUser?.id,
//                         supplyAt: input.supplyDate ? DateFormater.stringToDateWithFormat(input.supplyDate, 'DD/MM/yyyy') : null,
//                         // supplyAt: input.supplyDate ? new Date(input.warrantyDate) : null,
//                         reason: input.supplyReason,
//                         createdBy: requesterId,
//                         updatedBy: requesterId
//                     })
//                     checkAsset.supplyId = assetOwner.id
//                     insertAssetOwners.push(assetOwner)
//                 }
//                 if (input.upgradeRepair || input.handOverReceipt || input.handOverDate || input.handOverReason || input.handOverStatus || input.handOverUser) {
//                     const assetMaintenance = AssetMaintenance.create({
//                         id: RandomHelper.generateUUID(),
//                         assetId: checkAsset.id,
//                         content: input.upgradeRepair,
//                         handOverReceipt: input.handOverReceipt,
//                         handOverAt: input.handOverDate ? DateFormater.stringToDateWithFormat(input.handOverDate, 'DD/MM/yyyy') : null,
//                         // handOverAt: input.handOverDate ? new Date(input.warrantyDate) : null,
//                         reason: input.handOverReason,
//                         handOverStatus: input.handOverStatus,
//                         handOverUserId: handOverUser?.id,
//                         createdBy: requesterId,
//                         updatedBy: requesterId
//                     })
//                     checkAsset.maintenanceId = assetMaintenance.id
//                     insertAssetMaintenances.push(assetMaintenance)
//                 }
//
//                 insertAssets.push(checkAsset)
//                 response.push({ ...input, serial: serial, result: 'Cập nhật thành công' })
//                 // existedAssetCodes.push(input.assetCode)
//                 existedAssetSerials.push(serial)
//             }
//
//             await Asset.save(insertAssets)
//             await AssetOwner.save(insertAssetOwners)
//             await AssetMaintenance.save(insertAssetMaintenances)
//             const resultFileUrl = await this.assetService.createImportResultFile(
//                 token,
//                 'UPDATE',
//                 // officeRequester,
//                 columnName,
//                 response
//             )
//
//             return {
//                 total: rowData.length,
//                 count: insertAssets.length,
//                 resultFileUrl: resultFileUrl,
//                 // resultFileUrl: "",
//                 rows: response
//             }
//         } catch (error) {
//             console.log(`Import update assets has error: ${error}`)
//             throw error
//         }
//     }
//
//     @Query(_return => AssetNfcResponse, { name: "managementAssetNfcCheck" })
//     @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
//     @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
//     async managementAssetNfcCheck(
//         @Args('serial', { nullable: false }) serial: string,
//         @Args("NFC", { nullable: true, defaultValue: null }) NFC: NFCInfoArgs,
//     ): Promise<AssetNfcResponse> {
//         // const checkSerial = await this.stampService.findUniqueCodeByCode(serial)
//         // const serialQuery = await this.stampService.getUnicodeByCode(serial)
//         const checkSerial = await Asset.findOne({ where: { serial: serial } })
//         if (!checkSerial) {
//             throw OfficeError.SerialAssetNotFound
//         }
//
//         if (NFC.uId) {
//             //2. Gửi Serial và đồng thời gửi cả ID bảo hành + UID
//             if (checkSerial.nfcId !== NFC.uId) throw OfficeError.StampNFCuIdInvalid
//
//             const uniqueCode = await this.qldbService.findUniqueCodeEventBySerialAndRollingCode(serial, NFC.rollingCode)
//             if (!uniqueCode) throw OfficeError.StampNFCrollingCodeNotFound
//             // console.log("uniqueCode: ", uniqueCode?.data?.rollingCode.toString())
//             const currentSerial = await this.qldbService.findLastestUniqueCodeEventBySerialHasRollingCode(serial)
//             // console.log("currentSerial: ", currentSerial?.data?.rollingCode.toString())
//
//             return {
//                 rollingCode: {
//                     code: NFC.rollingCode,
//                     lastestRollingCode: (uniqueCode?.data?.rollingCode && uniqueCode?.data?.rollingCode?.toString() === currentSerial?.data?.rollingCode?.toString() ? true : false)
//                 },
//                 tempCode: RandomHelper.generateUUID(),
//                 serialInfo: checkSerial
//             }
//         } else {
//             //1. Chỉ gửi duy nhất Serial mà ko gửi ID bảo hành, UID
//             if (checkSerial.nfcId) throw OfficeError.StampNFCuIdIsRequired
//
//             return {
//                 rollingCode: null,
//                 tempCode: RandomHelper.generateUUID(),
//                 serialInfo: checkSerial
//             }
//         }
//     }
//
//     @Mutation(_return => Asset, { name: "managementAssetWriteNfcRollingCode" })
//     @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
//     @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
//     async managementAssetWriteNfcRollingCode(
//         @Args('serial', { nullable: false }) serial: string,
//         @Args("NFC", { nullable: false }) NFC: NFCInfoArgs,
//         @RequesterId() requesterId: string,
//         // @BusinessRoleId() businessRoleId: string,
//         @BearerAccessToken() accessToken: string
//     ): Promise<Asset> {
//         const checkSerial = await Asset.findOne({ where: { serial: serial } })
//         if (!checkSerial) {
//             throw OfficeError.SerialAssetNotFound
//         }
//
//         if (checkSerial.nfcId) {
//             if (checkSerial.nfcId !== NFC.uId) throw OfficeError.StampNFCuIdInvalid
//         } else {
//             checkSerial.nfcId = NFC.uId
//         }
//
//         // const rs = await this.stampService.getUnicodeByCode(serial)
//         // const rsSerial = rs.length > 0 ? rs[0] : null
//         // if (!rsSerial) {
//         //     throw FactoryError.StampNotFound
//         // }
//
//         const checkExistedCode = await this.qldbService.findUniqueCodeEventBySerial(serial)
//         if (checkExistedCode) {
//             const updateRollingCode = await this.qldbService.updateSerialRollingCode(serial, NFC)
//             console.log("[updateRollingCode] Result: ", updateRollingCode)
//         } else {
//             const insertRollingCode = await this.qldbService.insertSerialRollingCode(serial, NFC, checkSerial)
//             console.log("[insertRollingCode] Result: ", insertRollingCode)
//         }
//
//         // await checkSerial.save()
//
//         if (NFC.longitude && NFC.latitude) {
//             const location = await this.addressService.getZoneByLocation(accessToken, {
//                 longitude: NFC.longitude,
//                 latitude: NFC.latitude
//             })
//
//             let provinceId = null
//             let province = null
//             let districtId = null
//             let district = null
//             let wardId = null
//             let ward = null
//             let currentZone = location?.addressZone
//             while (currentZone != null) {
//                 switch (currentZone.level) {
//                     case "Province":
//                         provinceId = currentZone.id
//                         province = currentZone.name
//                         break
//                     case "District":
//                         districtId = currentZone.id
//                         district = currentZone.name
//                         break
//                     case "Ward":
//                         wardId = currentZone.id
//                         ward = currentZone.name
//                         break
//                 }
//                 currentZone = currentZone.parent
//             }
//
//             const nfcHistory = await this.assetService.nfcHistoryCreate({
//                 id: null,
//                 serial: checkSerial.serial,
//                 nfcId: checkSerial.nfcId,
//                 rollingCode: NFC.rollingCode,
//                 longitude: NFC.longitude,
//                 latitude: NFC.latitude,
//                 address: location?.address || "",
//                 provinceId: provinceId || "",
//                 province: province || "",
//                 districtId: districtId || "",
//                 district: district || "",
//                 wardId: wardId || "",
//                 ward: ward || "",
//                 convertAddress: location?.fullAddress || "",
//                 assetCode: checkSerial.code,
//                 assetName: checkSerial.name
//             }, requesterId)
//             checkSerial.lastestNfcHistoryId = nfcHistory.id
//         }
//
//         return checkSerial.save()
//     }
//
//     @Mutation(() => AssetAudit, { name: 'managementAssetAudit', nullable: true })
//     @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
//     @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
//     async managementAssetAudit(
//         @Args('arguments', { nullable: false }) args: AuditAssetArgs,
//         @BearerAccessToken() token: string,
//         @RequesterId() requesterId: string,
//     ): Promise<AssetAudit> {
//         const assetAudit = AssetAudit.create({
//             id: RandomHelper.generateUUID(),
//             latitude: args.latitude,
//             longitude: args.longitude,
//             createdBy: requesterId,
//             updatedBy: requesterId
//         })
//
//         const assets = await Asset.find({
//             where: {
//                 id: In(args.assetIds)
//             }
//         })
//
//         const auditItems: AssetAuditItem[] = []
//         for (const item of assets) {
//             auditItems.push(AssetAuditItem.create({
//                 assetId: item.id,
//                 auditId: assetAudit.id,
//                 createdBy: requesterId,
//                 updatedBy: requesterId
//             }))
//         }
//
//         await AssetAuditItem.save(auditItems)
//         return assetAudit.save()
//     }
//
//     @Mutation(_return => AssetAssignment, { name: "managementAssetWriteNfc" })
//     @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
//     @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
//     async managementAssetWriteNfc(
//         @Args("arguments") args: NfcAssignmentArgs,
//         @RequesterId() requesterId: string,
//         @BearerAccessToken() accessToken: string
//     ): Promise<AssetAssignment> {
//         const upperCaseCodes = []
//         args.nfc.map(nfc => {
//             if (nfc.serial.length > 0) {
//                 upperCaseCodes.push(nfc.serial.toUpperCase().trim())
//             }
//         })
//
//         const [existedList, count] = await Asset.findAndCount({
//             where: {
//                 serial: In(upperCaseCodes)
//             }
//         })
//
//         const existedCodes = existedList.map(c => c.serial)
//         const notExistedCodes = upperCaseCodes.filter(c => !existedCodes.includes(c))
//
//         if (notExistedCodes.length > 0) {
//             throw new BaseError(
//                 OfficeError.UnrecognizedAssetSerials.code,
//                 OfficeError.UnrecognizedAssetSerials.baseMsg,
//                 notExistedCodes
//             )
//         }
//
//         const assignmentAssets: Asset[] = []
//         for (const checkSerial of existedList) {
//             const NFC = args.nfc.find(n => checkSerial.serial === n.serial.toUpperCase().trim())
//             checkSerial.nfcId = NFC.uId
//
//             const checkExistedCode = await this.qldbService.findUniqueCodeEventBySerial(checkSerial.serial)
//             if (checkExistedCode) {
//                 const updateRollingCode = await this.qldbService.updateSerialRollingCode(checkSerial.serial, {
//                     uId: NFC.uId,
//                     rollingCode: NFC.rollingCode,
//                     longitude: args.longitude,
//                     latitude: args.latitude
//                 })
//                 console.log("[updateRollingCode] Result: ", updateRollingCode)
//             } else {
//                 const insertRollingCode = await this.qldbService.insertSerialRollingCode(checkSerial.serial, {
//                     uId: NFC.uId,
//                     rollingCode: NFC.rollingCode,
//                     longitude: args.longitude,
//                     latitude: args.latitude
//                 }, checkSerial)
//                 console.log("[insertRollingCode] Result: ", insertRollingCode)
//             }
//
//             await checkSerial.save()
//             assignmentAssets.push(checkSerial)
//         }
//
//         const assetAssignment = AssetAssignment.create({
//             id: RandomHelper.generateUUID(),
//             latitude: args.latitude,
//             longitude: args.longitude,
//             createdBy: requesterId,
//             updatedBy: requesterId
//         })
//
//         const assignItems: AssetAssignmentItem[] = []
//         for (const item of assignmentAssets) {
//             assignItems.push(AssetAssignmentItem.create({
//                 assetId: item.id,
//                 assignmentId: assetAssignment.id,
//                 createdBy: requesterId,
//                 updatedBy: requesterId
//             }))
//         }
//
//         await AssetAssignmentItem.save(assignItems)
//
//         return assetAssignment.save()
//     }
// }