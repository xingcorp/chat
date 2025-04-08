import { forwardRef, Inject, Injectable } from "@nestjs/common";
import {
    InfoBlock,
    InfoField,
    OfficeOrgChart,
    OfficeTitle,
    OfficeUser,
    UserAddress,
    UserBankAccount,
    UserDepartment
} from "@models/entities";
import { Brackets, DataSource, In, LessThanOrEqual, Not } from "typeorm";
import { ObjectStatus } from "@models/entities/profile.info.block";
import {
    AddEmployeeArgs,
    AnalysisNumberOfUserUsedAppFilter, EditEmployeeArgs, EmployeeBulkCreateImport,
    EmployeeReportFilterArgs,
    EmployeeReportFilterListArgs,
    ImportEmployeeArgs, OfficeEmployeeAvatarUpdateInput,
    OfficeUserFilter
} from "./employee.args";
import * as ExcelJS from "exceljs";
import { FileCleanType } from "@core/storage/objects/file";
import { StorageService } from "@core/storage/storage.service";
import {
    addDataEmployeeReportSummaryExport,
    defineEmployeeReportSummaryExportColumns,
    setEmployeeReportSummaryExportHeader,
    styleEmployeeReportSummaryExport
} from "./helpers/employee-report/summary-employee-report";
import { pluck } from "@utils/object.utils";
import {
    addDataEmployeeResignReportExport,
    defineEmployeeResignReportExportColumns,
    setEmployeeResignReportExportHeader,
    styleEmployeeResignReportExport
} from "./helpers/employee-report/employee-resign-report";
import {
    addDataEmployeeReportDetailExport,
    defineEmployeeReportDetailExportColumns,
    setEmployeeReportDetailExportHeader,
    styleEmployeeReportDetailExport
} from "./helpers/employee-report/detail-employee-report";
import { OfficeOrgChartRepo } from "@models/repositories/office-org-chart.repo";
import { OfficeSysUserRepo } from "@models/repositories/office-sys-user.repo";
import { OfficeError, OfficeErrorMessage } from "@common/office.error";
import { OfficeUserRepo } from "@repositories/profile.user.repo";
import { OfficeInfoFieldRepo, TitleRepo } from "@models/repositories";
import { RequestContext } from "@common/context/request.context";
import {
    EmployeeBulkCreateResponse, ImportBulkCreateResponse,
    ImportEmployeeResponse
} from "@modules/graphql/management/employee/employee.response";
import { LangVi } from "@utils/lang";
import { validateEmail, validatePhoneNumber } from "@common/regex";
import validator, { isUUID } from "validator";
import { DateFormater } from "@common/date.formater";
import { RandomHelper } from "@common/random";
import { IdentityService } from "@core/iam/identity/identity.service";
import { AddressService } from "@core/iam/organization/location/address.service";
import {
    addListToCells,
    defineAndSetImportUserHeader,
    IMPORT_USER_COMMON_HEADER,
    IMPORT_USER_SHEET_DATA_NAME,
    importUserTemplateAddDemoData,
    importUserTemplateExportSheetDataAddData,
    styleImportUser
} from "@modules/graphql/management/employee/helpers/template/import-user.template";
import { getRootOOCByDepartmentId } from "@modules/graphql/management/orgchart/helpers/orgchart.helpers";
import { AddressType } from "@models/entities/profile.address";
import { datetimeGetDateFromFormat } from "@utils/datetime.utils";
import { CRMError } from "@common/crm.error";
import { OfficeSuccessMessage } from "@common/office.success";
import {
    defineAndSetImportCreateUserHeader, IMPORT_USER_CREATE_COMMON_HEADER, importUserCreateTemplateAddDemoData
} from "@modules/graphql/management/employee/helpers/template/import-user-create.template";

export const MAX_DETAIL_COL = 129; // common cow = 20 => max_all = 150
export const COMMON_COL = 21;
export const USER_CODE_LENGTH = 5
export const HEAD_OFFICE_USER_CODE = 'T'

@Injectable()
export class EmployeeService {
    constructor(
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,

        private orgChartRepository: OfficeOrgChartRepo,
        private officeSysUserRepo: OfficeSysUserRepo,
        private officeUserRepo: OfficeUserRepo,
        private officeInfoFieldRepo: OfficeInfoFieldRepo,
        private titleRepo: TitleRepo,
        @Inject(forwardRef(() => IdentityService))
        private readonly identityService: IdentityService,

        @Inject(forwardRef(() => AddressService))
        private readonly addressService: AddressService,
        private dataSource: DataSource,
    ) {
    }

    async deactivateStaffAccounts() {
        console.log('CronJob DeactivateStaffAccounts Is Running ====>');
        const today = new Date()
        const tomorrow = today.setDate(today.getDate() + 1)
        const staffToDeactivate = await OfficeUser.find({
            where: {
                leaveOn: LessThanOrEqual(new Date(tomorrow)),
                status: ObjectStatus.Active
            },
            select: ["id"]
        });

        if (staffToDeactivate.length > 0) {
            await OfficeUser.update(
                {leaveOn: LessThanOrEqual(new Date(tomorrow))},
                {status: ObjectStatus.Inactive},
            );
            console.log(`Deactivated ${staffToDeactivate.length} staff accounts.`);
        }
    }

    public async employeeReportSummaryExport(token: string, filter: EmployeeReportFilterArgs, requesterId: string) {
        const workbook = new ExcelJS.Workbook();

        workbook.created = new Date();
        workbook.modified = new Date();
        workbook.lastPrinted = new Date();

        const sheetName = 'Báo cáo nhân viên tóm tắt';

        let chartSheet = workbook.addWorksheet(sheetName)

        defineEmployeeReportSummaryExportColumns(chartSheet)
        setEmployeeReportSummaryExportHeader(chartSheet)

        let [employees, total] = await this.getAllEmployeesAndFilter(filter, requesterId)

        const officeOrgs = pluck(await OfficeOrgChart.find(), 'name', 'id')
        const dataCount = addDataEmployeeReportSummaryExport(chartSheet, employees, officeOrgs)

        styleEmployeeReportSummaryExport(chartSheet, dataCount)

        const excelName = `employee_report_summary.xlsx`;
        const excelBuffer = await workbook.xlsx.writeBuffer()
        return this.storageService.uploadObject(
            token,
            excelBuffer,
            excelName,
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'management/employee',
            FileCleanType.Never
        )
    }

    public async employeeResignReportExport(token: string, filter: EmployeeReportFilterArgs, requesterId: string) {
        const workbook = new ExcelJS.Workbook();

        workbook.created = new Date();
        workbook.modified = new Date();
        workbook.lastPrinted = new Date();

        const sheetName = 'Báo cáo nhân viên nghỉ việc';

        let chartSheet = workbook.addWorksheet(sheetName)

        defineEmployeeResignReportExportColumns(chartSheet)
        setEmployeeResignReportExportHeader(chartSheet)

        let [employees, total] = await this.getAllEmployeesAndFilter(filter, requesterId, true)

        const officeOrgs = pluck(await OfficeOrgChart.find(), 'name', 'id')
        const dataCount = addDataEmployeeResignReportExport(chartSheet, employees, officeOrgs)

        styleEmployeeResignReportExport(chartSheet, dataCount)

        const excelName = `employee_resign_report.xlsx`;
        const excelBuffer = await workbook.xlsx.writeBuffer()
        return this.storageService.uploadObject(
            token,
            excelBuffer,
            excelName,
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'management/employee',
            FileCleanType.Never
        )
    }

    public async employeeReportDetailExport(token: string, filter: EmployeeReportFilterArgs, requesterId: string) {
        const workbook = new ExcelJS.Workbook();

        workbook.created = new Date();
        workbook.modified = new Date();
        workbook.lastPrinted = new Date();

        const sheetName = 'Báo cáo nhân viên chi tiết';

        let chartSheet = workbook.addWorksheet(sheetName)

        const fields = await this.officeInfoFieldRepo.getListFieldExport()

        defineEmployeeReportDetailExportColumns(chartSheet, fields)
        setEmployeeReportDetailExportHeader(chartSheet, fields)

        let [employees, total] = await this.getAllEmployeesAndFilter(filter, requesterId)

        const officeOrgs = pluck(await OfficeOrgChart.find(), 'name', 'id')
        const dataCount = addDataEmployeeReportDetailExport(chartSheet, employees, officeOrgs, fields)

        styleEmployeeReportDetailExport(chartSheet, dataCount)

        const excelName = `employee_report_detail.xlsx`;
        const excelBuffer = await workbook.xlsx.writeBuffer()
        return this.storageService.uploadObject(
            token,
            excelBuffer,
            excelName,
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'management/employee',
            FileCleanType.Never
        )
    }

    async filterEmployeesQuery(query, filter: EmployeeReportFilterArgs) {
        if (filter && filter.l1Id) {
            query.andWhere(`SPLIT_PART(dd.path, '/', 2) = :l1Id`, {l1Id: filter.l1Id})
        }

        if (filter && filter.l2Id) {
            query.andWhere(`SPLIT_PART(dd.path, '/', 3) = :l2Id`, {l2Id: filter.l2Id})
        }

        if (filter && filter.l3Id) {
            query.andWhere(`SPLIT_PART(dd.path, '/', 4) = :l3Id`, {l3Id: filter.l3Id})
        }

        if (filter && filter.l4Id) {
            query.andWhere(`SPLIT_PART(dd.path, '/', 5) = :l4Id`, {l4Id: filter.l4Id})
        }

        if (filter && filter.l5Id) {
            query.andWhere(`SPLIT_PART(dd.path, '/', 6) = :l5Id`, {l5Id: filter.l5Id})
        }

        if (filter && filter.l6Id) {
            query.andWhere(`SPLIT_PART(dd.path, '/', 7) = :l6Id`, {l6Id: filter.l6Id})
        }

        if (filter && filter.lCurrentId) {
            query.andWhere(`dd.id::text = :lCurrentId`, {lCurrentId: filter.lCurrentId})
        }

        if (filter && filter.titleId) {
            query.andWhere(`dt.id::text = :titleId`, {titleId: filter.titleId})
        }

        if (filter && filter.major) {
            query.andWhere(`ou.major = :major`, {major: filter.major})
        }

        if (filter && filter.onboardingOn) {
            if (filter.onboardingOn.start) query.andWhere(`ou."onboardingOn" >= :onboardingOnStart`, {onboardingOnStart: new Date(filter.onboardingOn.start).toISOString()})
            if (filter.onboardingOn.end) query.andWhere(`ou."onboardingOn" <= :onboardingOnEnd`, {onboardingOnEnd: new Date(filter.onboardingOn.end).toISOString()})
        }

        if (filter && filter.leaveOn) {
            if (filter.leaveOn.start) query.andWhere(`ou."leaveOn" >= :leaveOnStart`, {leaveOnStart: new Date(filter.leaveOn.start).toISOString()})
            if (filter.leaveOn.end) query.andWhere(`ou."leaveOn" <= :leaveOnEnd`, {leaveOnEnd: new Date(filter.leaveOn.end).toISOString()})
        }

        if (filter && filter.seniority) {
            query.andWhere(`CASE 
                WHEN ou."leaveOn" IS NULL 
                    THEN ((
                        (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM ou."onboardingOn")) * 12
                        +   EXTRACT(MONTH FROM CURRENT_DATE)
                        -   EXTRACT(MONTH FROM ou."onboardingOn")
                    )::int = :seniority::int) 
                    ELSE ((
                        (EXTRACT(YEAR FROM ou."leaveOn") - EXTRACT(YEAR FROM ou."onboardingOn")) * 12
                        +   EXTRACT(MONTH FROM ou."leaveOn")
                        -   EXTRACT(MONTH FROM ou."onboardingOn")
                    )::int = :seniority::int)
                END`
            , {seniority: filter.seniority})
        }

        if (filter && filter.resignationType) {
            query.andWhere(`ou."resignationType" = :resignationType`, {resignationType: filter.resignationType})
        }

        if (filter && filter.resignationReason) {
            query.andWhere(`ou."resignationReason" = :resignationReason`, {resignationReason: filter.resignationReason})
        }

        if (filter && filter.lastWorkingOn) {
            if (filter.lastWorkingOn.start) query.andWhere(`ou."lastWorkingOn" >= :lastWorkingOnStart`, {lastWorkingOnStart: new Date(filter.lastWorkingOn.start).toISOString()})
            if (filter.lastWorkingOn.end) query.andWhere(`ou."lastWorkingOn" <= :lastWorkingOnEnd`, {lastWorkingOnEnd: new Date(filter.lastWorkingOn.end).toISOString()})
        }

        if (filter instanceof EmployeeReportFilterListArgs) {
            filter.size = filter.size ? filter.size : 20
            filter.page = filter.page ? (filter.page - 1) : 0

            query.take(filter.size)
                .skip(filter.page * filter.size)
        }

        /*old filter*/
        if (filter instanceof OfficeUserFilter) {
            if (filter && filter.status) {
                query.andWhere({status: filter.status})
            }

            if (filter && filter.departmentIds && filter.departmentIds.length > 0) {
                const userDepartments = await UserDepartment.find({
                    where: {departmentId: In(filter.departmentIds)}
                })

                query.andWhere({id: In(userDepartments.map(ud => ud.userId))})
            }

            if (filter && filter.keyword) {
                query.andWhere(new Brackets(db => {
                        db.where(`unaccent(LOWER(ou.fullname)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                            .orWhere(`unaccent(LOWER(ou.code)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                            .orWhere(`unaccent(LOWER(ou.phone)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                            .orWhere(`unaccent(LOWER(ou.email)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                            .orWhere(`unaccent(LOWER(ou.note)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    }))
            }
        }

    }

    async getAllEmployeesAndFilter(filter: EmployeeReportFilterArgs, requesterId: string, resigned: boolean = false) {
        const query = OfficeUser.createQueryBuilder('ou')
            .leftJoinAndMapMany('ou.departments', UserDepartment, 'd', 'd."userId" = ou.id::text')
            .leftJoinAndMapOne('ou.department', OfficeOrgChart, 'dd', 'dd.id::text = d."departmentId"::text')
            .leftJoinAndMapOne('ou.title', OfficeTitle, 'dt', 'dt.id::text = d."titleId"::text')
            .where({})
            .orderBy('ou.createdAt', 'DESC')

        const oogIds = RequestContext.currentListOrgIds()

        query.andWhere(`d."departmentId"::text IN (:...oogIds)`, {oogIds})

        if (resigned) {
            query.andWhere("ou.resigned = :resigned", {resigned: true})
        } else {
            query
                .leftJoinAndMapOne('ou.approve', OfficeUser, 'ap', `ap.id::text = dd."approverId"::text and ap.status = :status`, {status: ObjectStatus.Active})
                .leftJoinAndMapOne('ou.address', UserAddress, 'adr', `ou.id::text = adr."userId"::text`)
        }

        await this.filterEmployeesQuery(query, filter)

        return query.getManyAndCount()
    }

    async getBlocksDataForDetailReport() {
        const blocks = await InfoBlock.createQueryBuilder('bl')
            .leftJoinAndMapMany(
                'bl.fields',
                InfoField,
                'f',
                'f."blockId" = bl.id::text and f.status = :f_status',
                {f_status: ObjectStatus.Active}
            )
            .select([
                'bl.name',
                'f.name',
                'f.code',
                'f.no',
                'f.dataType',
            ])
            .where('bl.status = :status', {status: ObjectStatus.Active})
            .getMany()

        let blocksColumn = []
        let header = '';
        let count = 1;
        let blockLength = [];
        let fieldsColumn = {}
        let fieldType = {}
        for (const block of Object.values(blocks)) {
            header = block.name;
            blockLength.push(block['fields'].length)

            for (const field of block['fields']) {
                if (count++ > MAX_DETAIL_COL) break

                blocksColumn.push({
                    key: field.code,
                    header,
                    width: 20
                })

                fieldType[field.code] = field.dataType
                fieldsColumn[field.code] = field.name

                header = '';
            }

            if (count > MAX_DETAIL_COL) break
        }

        return [blockLength, blocksColumn, fieldType, fieldsColumn]
    }

    public checkEditOfficeUserCodeCorrect(officeUserCode: string, officeCode: string) {
        return `${HEAD_OFFICE_USER_CODE}${officeCode}` === officeUserCode.substring(0, officeUserCode.length - USER_CODE_LENGTH)
    }

    async managementGetEmployeeList(token: string, filter: EmployeeReportFilterListArgs, requesterId: string) {
        const [data, total] = await this.getAllEmployeesAndFilter(filter, requesterId, !!(filter?.resigned))

        return {
            total: total as number,
            count: [...data as OfficeUser[]].length,
            officeUsers: data as OfficeUser[]
        }
    }

    async analysisNumberOfUserUsedApp(isSysOfficeAdmin: boolean, filters: AnalysisNumberOfUserUsedAppFilter) {
        if (!isSysOfficeAdmin) {
            throw OfficeError.ActionNotAllowed()
        }

        return this.officeUserRepo.analysisNumberOfUserUsedApp(filters);
    }

    async getListFieldRequiredAtImport(param: any) {
        if (!param) return []
        const keys = Object.keys(param)
        if (!keys.length) return []

        const list = await InfoField.findBy({
            code: In(keys),
            required: true
        })

        return list.map(i => i.code)
    }

    async importUserTemplateExport() {
        const workbook = new ExcelJS.Workbook();

        workbook.created = new Date();
        workbook.modified = new Date();
        workbook.lastPrinted = new Date();

        await this.importUserTemplateExportSheetImport(workbook)
        await this.importUserTemplateExportSheetData(workbook)

        const excelName = `Template-import-employee-basic-info.xlsx`;
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

    async importUserCreateTemplateExport() {
        const workbook = new ExcelJS.Workbook();

        workbook.created = new Date();
        workbook.modified = new Date();
        workbook.lastPrinted = new Date();

        await this.importUserTemplateCreateExportSheetImport(workbook)
        await this.importUserTemplateExportSheetData(workbook)

        const excelName = `Template-import-employee-create.xlsx`;
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

    private async importUserTemplateExportSheetImport(workbook) {
        const sheetName = 'Template import thông tin cơ bản';

        let chartSheet = workbook.addWorksheet(sheetName)

        const {softRows, softRowsDemoData} = await this.officeInfoFieldRepo.listSoftWorkDetailDataDefaultField()

        defineAndSetImportUserHeader(chartSheet, softRows)
        importUserTemplateAddDemoData(chartSheet, softRowsDemoData)

        addListToCells(chartSheet)
        styleImportUser(chartSheet)

        return chartSheet
    }

    private async importUserTemplateCreateExportSheetImport(workbook) {
        const sheetName = 'Template import tạo mới';

        let chartSheet = workbook.addWorksheet(sheetName)


        defineAndSetImportCreateUserHeader(chartSheet)
        importUserCreateTemplateAddDemoData(chartSheet)

        addListToCells(chartSheet)
        styleImportUser(chartSheet)

        return chartSheet
    }

    private async importUserTemplateExportSheetData(workbook) {
        let chartSheet = workbook.addWorksheet(IMPORT_USER_SHEET_DATA_NAME)

        chartSheet.state = 'hidden'

        importUserTemplateExportSheetDataAddData(chartSheet)
    }

    async importUserFieldsGet() {
        const fields = Object.keys(IMPORT_USER_COMMON_HEADER)
        const softWorkDetailFields = await this.officeInfoFieldRepo.listSoftWorkDetailDefaultField()
        fields.push(...(pluck(softWorkDetailFields, 'code').map(i => `data.${i}`)))

        return {fields}
    }

    async importUserFieldsGetTitle() {
        const fields = Object.values(IMPORT_USER_COMMON_HEADER)
        const softWorkDetailFields = await this.officeInfoFieldRepo.listSoftWorkDetailDefaultField()
        fields.push(...(pluck(softWorkDetailFields, 'name')))

        return {fields}
    }

    importUserCreateFieldsGet() {
        return {fields: Object.keys(IMPORT_USER_CREATE_COMMON_HEADER)}
    }

    importUserCreateFieldsGetTitle() {
        return {fields: Object.values(IMPORT_USER_CREATE_COMMON_HEADER)}
    }

    async managementAddEmployee(args: AddEmployeeArgs) {
        const token = RequestContext.currentToken()
        const requesterId = RequestContext.currentRequestId()

        await this.validateCreateData(args)

        let company: OfficeOrgChart = null
        const userDepartments: UserDepartment[] = []
        if (args.departments) {
            const existedDepartmentIds = []
            for (const departmentData of args.departments) {
                if (!existedDepartmentIds.includes(departmentData.departmentId)) {
                    const department = await OfficeOrgChart.findOne({ where: { id: departmentData.departmentId } })
                    if (!department) throw OfficeError.OrgChartNotFound

                    company = await getRootOOCByDepartmentId(department.id)
                }
            }
        }

        const { data, error } = await this.identityService.userCreate(
            token,
            args.fullname,
            args.email,
            args.phone
        )
        if (error) throw error

        const officeUser = OfficeUser.create({
            id: RandomHelper.generateUUID(),
            fullname: args.fullname,
            hrCode: args.hrCode ?? "",
            code: args.code ?? null,
            major: args.major,
            companyId: args?.departments?.[0]?.departmentId, //to generator code
            phone: args.phone,
            email: args.email,
            personalEmail: args.personalEmail,
            identityCard: args.identityCard,
            idCardIssuedOn: args.idCardIssuedOn ? new Date(args.idCardIssuedOn) : null,
            idCardIssuedPlace: args.idCardIssuedPlace,
            socialInsuranceCode: args.socialInsuranceCode,
            taxCode: args.taxCode,
            relativePhone: args.relativePhone,
            status: args.status,
            onboardingOn: args.onboardingOn ? new Date(args.onboardingOn) : null,
            leaveOn: args.leaveOn ? new Date(args.leaveOn) : null,
            officalWorkingOn: args.officalWorkingOn ? new Date(args.officalWorkingOn) : null,
            dateOfBirth: args.dateOfBirth ? new Date(args.dateOfBirth) : null,
            iamUserId: data.id,
            iamUserUsedIds: [data.id],
            note: args.note,
            metadata: [JSON.stringify(args.data)],
            createdBy: requesterId,
            updatedBy: requesterId
        })

        if (args.leaderId) {
            const checkLeader = await OfficeUser.findOne({ where: { id: args.leaderId } })
            if (!checkLeader) throw OfficeError.OfficeLeaderUserNotExisted
            officeUser.leaderId = checkLeader.id
        }

        let userAddress = null
        if (args.address || args.addressZoneId) {
            var provinceId = null
            var province = null
            var districtId = null
            var district = null
            var wardId = null
            var ward = null
            if (args.addressZoneId) {
                const addressZone = await this.addressService.addressZoneFindById(token, args.addressZoneId)
                if (!addressZone) throw OfficeError.AddressZoneInvalid
                var currentZone = addressZone
                while (currentZone != null) {
                    switch (currentZone.level) {
                        case "Province":
                            provinceId = currentZone.id
                            province = currentZone.name
                            break
                        case "District":
                            districtId = currentZone.id
                            district = currentZone.name
                            break
                        case "Ward":
                            wardId = currentZone.id
                            ward = currentZone.name
                            break
                    }
                    currentZone = currentZone.parent
                }
            }

            userAddress = UserAddress.create({
                address: args.address,
                addressZoneId: args.addressZoneId,
                provinceId: provinceId,
                province: province,
                districtId: districtId,
                district: district,
                wardId: wardId,
                ward: ward,
                userId: officeUser.id
            })
        }

        let temporaryUserAddress = null
        if (args.tempAddress || args.tempAddressZoneId) {
            let provinceId = null
            let province = null
            let districtId = null
            let district = null
            let wardId = null
            let ward = null
            if (args.tempAddressZoneId) {
                const addressZone = await this.addressService.addressZoneFindById(token, args.tempAddressZoneId)
                if (!addressZone) throw OfficeError.AddressZoneInvalid
                let currentZone = addressZone
                while (currentZone != null) {
                    switch (currentZone.level) {
                        case "Province":
                            provinceId = currentZone.id
                            province = currentZone.name
                            break
                        case "District":
                            districtId = currentZone.id
                            district = currentZone.name
                            break
                        case "Ward":
                            wardId = currentZone.id
                            ward = currentZone.name
                            break
                    }
                    currentZone = currentZone.parent
                }
            }

            temporaryUserAddress = UserAddress.create({
                address: args.tempAddress,
                addressZoneId: args.tempAddressZoneId,
                provinceId: provinceId,
                province: province,
                districtId: districtId,
                district: district,
                wardId: wardId,
                ward: ward,
                userId: officeUser.id,
                addressType: AddressType.Temporary
            })
        }

        if (args.imageIds) {
            for (const imageId of args.imageIds) {
                const { data, error } = await this.storageService.getFileDetail(token, imageId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted

                if (officeUser.imageIds) {
                    officeUser.imageIds.push(imageId)
                } else {
                    officeUser.imageIds = [imageId]
                }

                if (officeUser.imageUrls) {
                    officeUser.imageUrls.push(data.location)
                } else {
                    officeUser.imageUrls = [data.location]
                }
            }
        }

        if (args.attachFileIds) {
            for (const attachFileId of args.attachFileIds) {
                const { data, error } = await this.storageService.getFileDetail(token, attachFileId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted

                if (officeUser.attachFileIds) {
                    officeUser.attachFileIds.push(attachFileId)
                } else {
                    officeUser.attachFileIds = [attachFileId]
                }

                if (officeUser.attachFileUrls) {
                    officeUser.attachFileUrls.push(data.location)
                } else {
                    officeUser.attachFileUrls = [data.location]
                }
            }
        }

        var userBankAccount = null
        if (args.bankId || args.bankBranch || args.accountNumber || args.accountHolder) {
            userBankAccount = UserBankAccount.create({
                accountHolder: args.accountHolder,
                accountNumber: args.accountNumber,
                bankBranch: args.bankBranch,
                userId: officeUser.id
            })
            if (args.bankId) {
                const bank = await this.identityService.getBankDetail(args.bankId)
                if (!bank) throw OfficeError.BankNotExisted

                userBankAccount.bankId = bank.id
                userBankAccount.bankName = bank.brandName
            }
        }

        if (args.departments) {
            const existedDepartmentIds = []
            for (const departmentData of args.departments) {
                if (!existedDepartmentIds.includes(departmentData.departmentId)) {
                    const department = await OfficeOrgChart.findOne({ where: { id: departmentData.departmentId } })
                    if (!department) throw OfficeError.OrgChartNotFound

                    const userDepartment = UserDepartment.create({
                        departmentId: department.id,
                        userId: officeUser.id
                    })

                    if (departmentData.titleId) {
                        const title = await OfficeTitle.findOne({ where: { id: departmentData.titleId } })
                        if (!title) throw OfficeError.OfficeTitleNotExisted
                        userDepartment.titleId = title.id
                    }

                    userDepartments.push(userDepartment)
                    existedDepartmentIds.push(department.id)
                }
            }
        }

        //address, department, image, bank, title

        await UserDepartment.save(userDepartments)
        if (userAddress) {
            await userAddress.save()
        }
        if (temporaryUserAddress) {
            await temporaryUserAddress.save()
        }
        if (userBankAccount) {
            await userBankAccount.save()
        }

        return officeUser.save()
    }

    private async validateCreateData(args: any) {
        if (args.hrCode) {
            const checkHrCode = await this.officeUserRepo.getBy({hrCode: args.hrCode})
            if (checkHrCode) throw OfficeError.EmployeeHrCodeIsExisted
        }

        if (args.code) {
            const checkCode = await this.officeUserRepo.getBy({code: args.code})
            if (checkCode) throw OfficeError.EmployeeCodeIsExisted
        }

        /*One phone - one account IAM*/
        if (!validatePhoneNumber(args.phone)) throw OfficeError.PhoneNumberInvalid
        const checkPhone = await this.officeUserRepo.findOne({ where: { phone: args.phone } })
        if (checkPhone) throw OfficeError.EmployeePhoneIsExisted

        if (args.identityCard) {
            const checkIdCard = await this.officeUserRepo.getBy( {identityCard: args.identityCard })
            if (checkIdCard) throw OfficeError.EmployeeIDCardIsExisted
        }

        if (args.socialInsuranceCode) {
            const checkSocialInsuranceCode = await this.officeUserRepo.getBy({ socialInsuranceCode: args.socialInsuranceCode })
            if (checkSocialInsuranceCode) throw OfficeError.EmployeeSocialInsuranceCodeIsExisted
        }

        if (args.taxCode) {
            const checkTaxCode = await this.officeUserRepo.getBy({ taxCode: args.taxCode })
            if (checkTaxCode) throw OfficeError.EmployeeTaxCodeIsExisted
        }
    }

    async managementEditEmployee(args: EditEmployeeArgs) {
        const token = RequestContext.currentToken()
        const requesterId = RequestContext.currentRequestId()

        const officeUser = await OfficeUser.findOne({
            where: {
                id: args.id
            }
        })

        if (!officeUser) throw OfficeError.EmployeeNotFound

        // if (args.code) {
        //     const checkCode = await OfficeUser.findOne({
        //         where: {
        //             id: Not(args.id),
        //             code: args.code
        //         }
        //     })
        //     if (checkCode) throw OfficeError.EmployeeCodeIsExisted
        // }

        // if (args.code) officeUser.code = args.code
        if (args.fullname) officeUser.fullname = args.fullname
        if (args.onboardingOn) officeUser.onboardingOn = new Date(args.onboardingOn)
        if (args.leaveOn) officeUser.leaveOn = new Date(args.leaveOn)
        if (args.officalWorkingOn) officeUser.officalWorkingOn = new Date(args.officalWorkingOn)
        if (args.dateOfBirth) officeUser.dateOfBirth = new Date(args.dateOfBirth)
        if (args.status) officeUser.status = args.status
        if (args.companyId) officeUser.companyId = args.companyId
        if (args.hrCode && args.hrCode !== officeUser.hrCode) {
            const checkHrCode = await OfficeUser.findOne({ where: { hrCode: args.hrCode } })
            if (checkHrCode) throw OfficeError.EmployeeHrCodeIsExisted
            officeUser.hrCode = args.hrCode
        }
        if (args.data) officeUser.metadata = [JSON.stringify(args.data)]
        if (args.email !== undefined) officeUser.email = args.email
        if (args.personalEmail !== undefined) officeUser.personalEmail = args.personalEmail
        // if (args.major !== undefined) officeUser.major = args.major
        if (args.resigned !== undefined && args.resigned !== null) officeUser.resigned = args.resigned
        if (args.lastWorkingOn) officeUser.lastWorkingOn = new Date(args.lastWorkingOn)
        if (args.resignationType !== undefined) officeUser.resignationType = args.resignationType
        if (args.resignationReason !== undefined) officeUser.resignationReason = args.resignationReason
        if (args.resignationDetailReason !== undefined) officeUser.resignationDetailReason = args.resignationDetailReason
        if (args.identityCard && args.identityCard !== officeUser.identityCard) {
            const checkIdCard = await OfficeUser.findOne({ where: { identityCard: args.identityCard } })
            if (checkIdCard) throw OfficeError.EmployeeIDCardIsExisted
            officeUser.identityCard = args.identityCard
        }
        if (args.idCardIssuedOn) officeUser.idCardIssuedOn = new Date(args.idCardIssuedOn)
        if (args.idCardIssuedPlace !== undefined) officeUser.idCardIssuedPlace = args.idCardIssuedPlace
        if (args.socialInsuranceCode && args.socialInsuranceCode !== officeUser.socialInsuranceCode) {
            const checkInsuranceCode = await OfficeUser.findOne({ where: { socialInsuranceCode: args.socialInsuranceCode } })
            if (checkInsuranceCode) throw OfficeError.EmployeeSocialInsuranceCodeIsExisted
            officeUser.socialInsuranceCode = args.socialInsuranceCode
        }
        if (args.taxCode && args.taxCode !== officeUser.taxCode) {
            const checkTaxCode = await OfficeUser.findOne({ where: { taxCode: args.taxCode } })
            if (checkTaxCode) throw OfficeError.EmployeeTaxCodeIsExisted
            officeUser.taxCode = args.taxCode
        }
        if (args.relativePhone !== undefined) officeUser.relativePhone = args.relativePhone
        // if (args.leaderId && args.leaderId !== officeUser.leaderId) {
        //     const checkLeader = await OfficeUser.findOne({ where: { id: args.leaderId } })
        //     if (!checkLeader) throw OfficeError.OfficeLeaderUserNotExisted
        //     officeUser.leaderId = checkLeader.id
        // }

        var userAddress = null
        if (args.address || args.addressZoneId) {
            userAddress = await UserAddress.findOne({ where: { userId: args.id } })
            if (userAddress) {
                if (userAddress.address !== args.address) userAddress.address = args.address
                if (args.addressZoneId && userAddress.addressZoneId !== args.addressZoneId) {
                    var provinceId = null
                    var province = null
                    var districtId = null
                    var district = null
                    var wardId = null
                    var ward = null
                    const addressZone = await this.addressService.addressZoneFindById(token, args.addressZoneId)
                    if (!addressZone) throw OfficeError.AddressZoneInvalid
                    var currentZone = addressZone
                    while (currentZone != null) {
                        switch (currentZone.level) {
                            case "Province":
                                provinceId = currentZone.id
                                province = currentZone.name
                                break
                            case "District":
                                districtId = currentZone.id
                                district = currentZone.name
                                break
                            case "Ward":
                                wardId = currentZone.id
                                ward = currentZone.name
                                break
                        }
                        currentZone = currentZone.parent
                    }

                    userAddress.addressZoneId = args.addressZoneId
                    userAddress.provinceId = provinceId
                    userAddress.province = province
                    userAddress.districtId = districtId
                    userAddress.district = district
                    userAddress.wardId = wardId
                    userAddress.ward = ward
                }
            } else {
                var provinceId = null
                var province = null
                var districtId = null
                var district = null
                var wardId = null
                var ward = null
                if (args.addressZoneId) {
                    const addressZone = await this.addressService.addressZoneFindById(token, args.addressZoneId)
                    if (!addressZone) throw OfficeError.AddressZoneInvalid
                    var currentZone = addressZone
                    while (currentZone != null) {
                        switch (currentZone.level) {
                            case "Province":
                                provinceId = currentZone.id
                                province = currentZone.name
                                break
                            case "District":
                                districtId = currentZone.id
                                district = currentZone.name
                                break
                            case "Ward":
                                wardId = currentZone.id
                                ward = currentZone.name
                                break
                        }
                        currentZone = currentZone.parent
                    }
                }

                userAddress = UserAddress.create({
                    address: args.address,
                    addressZoneId: args.addressZoneId,
                    provinceId: provinceId,
                    province: province,
                    districtId: districtId,
                    district: district,
                    wardId: wardId,
                    ward: ward,
                    userId: officeUser.id
                })
            }
        }

        let temporaryUserAddress = null
        if (args.tempAddress || args.tempAddressZoneId) {
            let provinceId = null
            let province = null
            let districtId = null
            let district = null
            let wardId = null
            let ward = null
            if (args.tempAddressZoneId) {
                const addressZone = await this.addressService.addressZoneFindById(token, args.tempAddressZoneId)
                if (!addressZone) throw OfficeError.AddressZoneInvalid
                let currentZone = addressZone
                while (currentZone != null) {
                    switch (currentZone.level) {
                        case "Province":
                            provinceId = currentZone.id
                            province = currentZone.name
                            break
                        case "District":
                            districtId = currentZone.id
                            district = currentZone.name
                            break
                        case "Ward":
                            wardId = currentZone.id
                            ward = currentZone.name
                            break
                    }
                    currentZone = currentZone.parent
                }
            }

            temporaryUserAddress = UserAddress.create({
                address: args.tempAddress,
                addressZoneId: args.tempAddressZoneId,
                provinceId: provinceId,
                province: province,
                districtId: districtId,
                district: district,
                wardId: wardId,
                ward: ward,
                userId: officeUser.id,
                addressType: AddressType.Temporary
            })
        }

        if (args.imageIds) {
            if (officeUser.imageIds) {
                officeUser.imageIds = []
                officeUser.imageUrls = []
            }
            for (const imageId of args.imageIds) {
                const { data, error } = await this.storageService.getFileDetail(token, imageId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted

                if (officeUser.imageIds) {
                    officeUser.imageIds.push(imageId)
                } else {
                    officeUser.imageIds = [imageId]
                }

                if (officeUser.imageUrls) {
                    officeUser.imageUrls.push(data.location)
                } else {
                    officeUser.imageUrls = [data.location]
                }
            }
        }

        if (args.attachFileIds) {
            if (officeUser.attachFileIds) {
                officeUser.attachFileIds = []
                officeUser.attachFileUrls = []
            }
            for (const attachFileId of args.attachFileIds) {
                const { data, error } = await this.storageService.getFileDetail(token, attachFileId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted

                if (officeUser.attachFileIds) {
                    officeUser.attachFileIds.push(attachFileId)
                } else {
                    officeUser.attachFileIds = [attachFileId]
                }

                if (officeUser.attachFileUrls) {
                    officeUser.attachFileUrls.push(data.location)
                } else {
                    officeUser.attachFileUrls = [data.location]
                }
            }
        }

        var userBankAccount = null
        if (args.bankId || args.bankBranch || args.accountNumber || args.accountHolder) {
            userBankAccount = await UserBankAccount.findOne({ where: { userId: args.id } })
            if (userBankAccount) {
                if (userBankAccount.accountHolder !== args.accountHolder) userBankAccount.accountHolder = args.accountHolder
                if (userBankAccount.accountNumber !== args.accountNumber) userBankAccount.accountNumber = args.accountNumber
                if (userBankAccount.bankBranch !== args.bankBranch) userBankAccount.bankBranch = args.bankBranch
                if (args.bankId && userBankAccount.bankId !== args.bankId) {
                    const bank = await this.identityService.getBankDetail(args.bankId)
                    if (!bank) throw OfficeError.BankNotExisted

                    userBankAccount.bankId = bank.id
                    userBankAccount.bankName = bank.brandName
                }
            } else {
                userBankAccount = UserBankAccount.create({
                    accountHolder: args.accountHolder,
                    accountNumber: args.accountNumber,
                    bankBranch: args.bankBranch,
                    userId: officeUser.id
                })
                if (args.bankId) {
                    const bank = await this.identityService.getBankDetail(args.bankId)
                    if (!bank) throw OfficeError.BankNotExisted

                    userBankAccount.bankId = bank.id
                    userBankAccount.bankName = bank.brandName
                }
            }
        }

        const userDepartments: UserDepartment[] = []
        var updateDepartments = false
        // if (args.departments) {
        //     updateDepartments = true
        //     const existedDepartmentIds = []
        //     for (const departmentData of args.departments) {
        //         if (!existedDepartmentIds.includes(departmentData.departmentId)) {
        //             const department = await OfficeOrgChart.findOne({ where: { id: departmentData.departmentId } })
        //             if (!department) throw OfficeError.OrgChartNotFound
        //
        //             const userDepartment = UserDepartment.create({
        //                 departmentId: department.id,
        //                 userId: officeUser.id
        //             })
        //
        //             if (departmentData.titleId) {
        //                 const title = await OfficeTitle.findOne({ where: { id: departmentData.titleId } })
        //                 if (!title) throw OfficeError.OfficeTitleNotExisted
        //                 userDepartment.titleId = title.id
        //             }
        //
        //             userDepartments.push(userDepartment)
        //             existedDepartmentIds.push(department.id)
        //         }
        //     }
        // }

        if (args.phoneNumber && args.phoneNumber !== officeUser.phone) {
            const getUserSOfficeByPhone = await OfficeUser.findOne({ where: { phone: args.phoneNumber } });
            if (getUserSOfficeByPhone) {
                throw CRMError.CrmUserWithPhoneExisted
            }

            const { data, error } = await this.identityService.userCreate(token, args.fullname, args.email, args.phoneNumber)
            if (data) {
                officeUser.phone = args.phoneNumber;
                if (officeUser.iamUserUsedIds) {
                    officeUser.iamUserUsedIds.push(structuredClone(officeUser.iamUserId))
                } else {
                    officeUser.iamUserUsedIds = [structuredClone(officeUser.iamUserId)]
                }

                officeUser.iamUserId = data.id;
            } else {
                console.log('managementEditEmployee error: ', JSON.stringify(error))
                throw error;
            }
        }

        // if (updateDepartments === true) {
        //     await UserDepartment.delete({
        //         userId: officeUser.id
        //     })
        //     await UserDepartment.save(userDepartments)
        // }

        if (userAddress) {
            await userAddress.save()
        }

        if (temporaryUserAddress) {
            await temporaryUserAddress.save()
        }

        if (userBankAccount) {
            await userBankAccount.save()
        }

        officeUser.updatedBy = requesterId
        return officeUser.save()
    }

    async managementEmployeeBulkUpsert(officeUsers: ImportEmployeeArgs[], token: string, requesterId: string, isAllRequired: boolean = true) {
        try {
            const response: ImportEmployeeResponse[] = []
            const existedEmpCodes: String[] = []
            const upsertEmployees: OfficeUser[] = []
            const departmentDict: any = {}
            const titleDict: any = {}
            const removeUserDepartments: UserDepartment[] = []
            const upsertUserDepartments: UserDepartment[] = []
            const upsertUserBankAccounts: UserBankAccount[] = []
            const upsertUserAddresses: UserAddress[] = []
            for (const input of officeUsers) {
                // if (input.id) {
                //     response.push({ ...input, errorMessage: OfficeErrorMessage.DoNotUpdateUserAtHere })
                //     continue
                // }
                if (!input.fullname || !input.phone || !input.title || !input.department || !input.address || !input.identityCard || !input.idCardIssuedOn || !input.idCardIssuedPlace || !input.birthday || !input.major || !input.onboardingOn || !input.officalWorkingOn || !input.taxCode || !input.socialInsuranceCode || !input.status || !input.resigned) {
                    response.push({ ...input, errorMessage: OfficeErrorMessage.RequiredField })
                    continue
                }
                if (isAllRequired && !input.leaderCode) {
                    response.push({ ...input, errorMessage: OfficeErrorMessage.RequiredField })
                    continue
                }

                /*Required resigned*/
                if (![LangVi.YES, LangVi.NO].includes(input?.resigned?.trim())) {
                    response.push({ ...input, errorMessage: OfficeErrorMessage.OfficeUserResignedTypeError })
                    continue
                }
                if (input.resigned && input?.resigned?.trim() === LangVi.YES && (!input.resignationType || !input.resignationReason || !input.resignationDetailReason || !input.lastWorkingOn || !input.leaveOn)) {
                    response.push({ ...input, errorMessage: OfficeErrorMessage.RequiredField })
                    continue
                }
                if (input?.resigned?.trim() === LangVi.NO) {
                    input.resignationType = null
                    input.resignationReason = null
                    input.resignationDetailReason = null
                    input.lastWorkingOn = null
                    input.leaveOn = null
                }

                /*Validate title*/
                if (!await OfficeTitle.findOneBy({ code: input.title })) {
                    response.push({
                        ...input,
                        errorMessage: OfficeErrorMessage.OfficeTitleNotExisted
                    })
                    continue
                }

                let leader = {id: null}
                if (input.leaderCode) {
                    leader = await OfficeUser.findOneBy({code: input.leaderCode})
                    if (!leader) {
                        response.push({
                            ...input,
                            errorMessage: OfficeErrorMessage.OfficeLeaderNotExisted
                        })
                        continue
                    }
                }


                const invalidFields = []
                if (!validatePhoneNumber(input.phone)) invalidFields.push('Số điện thoại')
                if (input.email && !validateEmail(input.email)) invalidFields.push('Email công ty')
                if (input.personalEmail && !validateEmail(input.personalEmail)) invalidFields.push('Email cá nhân')
                if (!validator.isDate(input.idCardIssuedOn, { format: 'DD/MM/yyyy' })) invalidFields.push('Ngày cấp')
                if (!validator.isDate(input.birthday, { format: 'DD/MM/yyyy' })) invalidFields.push('Ngày sinh')
                if (!validator.isDate(input.onboardingOn, { format: 'DD/MM/yyyy' })) invalidFields.push('Ngày vào công ty')
                if (input.officalWorkingOn && !validator.isDate(input.officalWorkingOn, { format: 'DD/MM/yyyy' })) invalidFields.push('Ngày chính thức')
                if (input.lastWorkingOn && !validator.isDate(input.lastWorkingOn, { format: 'DD/MM/yyyy' })) invalidFields.push('Ngày làm việc cuối cùng')
                if (input.leaveOn && !validator.isDate(input.leaveOn, { format: 'DD/MM/yyyy' })) invalidFields.push('Ngày hiệu lực thôi việc')
                if (input.relativePhone && !validatePhoneNumber(input.relativePhone)) invalidFields.push('SĐT người thân')
                if (invalidFields.length > 0) {
                    let invalidFieldStr = ''
                    for (const iterator of invalidFields) {
                        if (invalidFieldStr) {
                            invalidFieldStr += (`, ${iterator}`)
                        } else {
                            invalidFieldStr += iterator
                        }
                    }
                    response.push({ ...input, errorMessage: `Vui lòng nhập đúng định dạng trường ${invalidFieldStr}` })
                    continue
                }

                if (!Object.keys(ObjectStatus).includes(input.status)) {
                    response.push({ ...input, errorMessage: 'Vui lòng nhập giá trị là Active hoặc Inactive' })
                    continue
                }

                let existedEmployeeCode
                if (input.code) {
                    existedEmployeeCode = await OfficeUser.findOne({
                        where: {
                            code: input.code
                        }
                    })
                }

                if (input.id) {
                    if (!validator.isUUID(input.id)) {
                        response.push({ ...input, errorMessage: 'ID không hợp lệ' })
                        continue
                    }

                    // update
                    const existedEmployee = await OfficeUser.findOne({
                        where: { id: input.id }
                    })

                    if (!existedEmployee) {
                        response.push({ ...input, errorMessage: 'Không tìm thấy thông tin nhân viên' })
                        continue
                    }

                    if ((existedEmployeeCode && existedEmployeeCode.code !== existedEmployee.code) || existedEmpCodes.includes(input.code)) {
                        response.push({ ...input, errorMessage: 'Mã nhân viên đã tồn tại trên hệ thống' })
                        continue
                    }

                    if (existedEmployee && existedEmployee.phone !== input.phone) {
                        response.push({ ...input, errorMessage: 'Không được phép cập nhật Số điện thoại của nhân viên' })
                        continue
                    }

                    const checkPhone = await OfficeUser.findOne({
                        where: {
                            phone: input.phone,
                            id: Not(input.id)
                        }
                    })
                    if (checkPhone) {
                        response.push({ ...input, errorMessage: 'Số điện thoại đã thuộc về một nhân sự khác' })
                        continue
                    }

                    //department & title
                    const unrecognizeDepartments = []
                    const unrecognizeTitles = []
                    // const departments = input.departments.split(",")
                    const departments = [`${input.department}::${input.title}`]
                    const newUserDepartments: UserDepartment[] = []
                    for (const departmentInput of departments) {
                        const departmentArr = departmentInput.split("::")
                        const department = departmentArr.length > 0 ? departmentArr[0] : null
                        const title = departmentArr.length > 1 ? departmentArr[1] : null
                        if (department) {
                            var departmentEntity = departmentDict[department]
                            if (!departmentEntity) {
                                departmentEntity = await OfficeOrgChart.findOne({
                                    where: { code: department }
                                })

                                if (!departmentEntity) {
                                    unrecognizeDepartments.push(department)
                                } else {
                                    departmentDict[department] = departmentEntity
                                }
                            }

                            if (departmentEntity) {
                                const userDepartment = UserDepartment.create({
                                    departmentId: departmentEntity.id,
                                    userId: existedEmployee.id
                                })

                                if (title) {
                                    var titleEntity = titleDict[title]
                                    if (!titleEntity) {
                                        titleEntity = await OfficeTitle.findOne({
                                            where: { code: title }
                                        })
                                    }

                                    if (titleEntity) {
                                        titleDict[title] = titleEntity
                                        userDepartment.titleId = titleEntity.id
                                    } else {
                                        unrecognizeTitles.push(title)
                                    }
                                }

                                newUserDepartments.push(userDepartment)
                            }
                        }
                    }

                    if (unrecognizeDepartments.length > 0) {
                        var departmentStr = ''
                        unrecognizeDepartments.forEach((value, index) => {
                            if (index < unrecognizeDepartments.length - 1) {
                                departmentStr += `${value}, `
                            } else {
                                departmentStr += `${value}`
                            }
                        })
                        response.push({ ...input, errorMessage: `Mã phòng ban ${departmentStr} chưa tồn tại trên hệ thống` })
                        continue
                    }

                    if (unrecognizeTitles.length > 0) {
                        var titleStr = ''
                        unrecognizeTitles.forEach((value, index) => {
                            if (index < unrecognizeTitles.length - 1) {
                                titleStr += `${value}, `
                            } else {
                                titleStr += `${value}`
                            }
                        })
                        response.push({ ...input, errorMessage: `Mã chức vụ ${titleStr} chưa tồn tại trên hệ thống` })
                        continue
                    }

                    const existedUserDepartments = await UserDepartment.find({
                        where: {
                            userId: existedEmployee.id
                        }
                    })
                    existedUserDepartments.forEach(ud => {
                        removeUserDepartments.push(ud)
                    })
                    newUserDepartments.forEach(nud => {
                        upsertUserDepartments.push(nud)
                    })

                    existedEmployee.code = input.code ?? null
                    existedEmployee.leaderId = leader?.id ?? existedEmployee.leaderId
                    existedEmployee.fullname = input.fullname
                    existedEmployee.email = input.email
                    existedEmployee.personalEmail = input.personalEmail
                    existedEmployee.identityCard = input.identityCard
                    existedEmployee.idCardIssuedOn = input.idCardIssuedOn ? DateFormater.stringToDateWithFormat(input.idCardIssuedOn, 'DD/MM/yyyy') : null
                    existedEmployee.idCardIssuedPlace = input.idCardIssuedPlace
                    existedEmployee.dateOfBirth = input.birthday ? DateFormater.stringToDateWithFormat(input.birthday, 'DD/MM/yyyy') : null
                    existedEmployee.hrCode = input.hrCode
                    existedEmployee.major = input.major
                    existedEmployee.onboardingOn = input.onboardingOn ? DateFormater.stringToDateWithFormat(input.onboardingOn, 'DD/MM/yyyy') : null
                    existedEmployee.officalWorkingOn = input.officalWorkingOn ? DateFormater.stringToDateWithFormat(input.officalWorkingOn, 'DD/MM/yyyy') : null
                    if (input.resigned) {
                        existedEmployee.resigned = input.resigned?.trim() === LangVi.YES
                        existedEmployee.resignationType = input.resignationType
                        existedEmployee.resignationReason = input.resignationReason
                        existedEmployee.resignationDetailReason = input.resignationDetailReason
                        existedEmployee.lastWorkingOn = input.lastWorkingOn ? DateFormater.stringToDateWithFormat(input.lastWorkingOn, 'DD/MM/yyyy') : null
                        existedEmployee.leaveOn = input.leaveOn ? DateFormater.stringToDateWithFormat(input.leaveOn, 'DD/MM/yyyy') : null
                    }
                    existedEmployee.taxCode = input.taxCode
                    existedEmployee.socialInsuranceCode = input.socialInsuranceCode
                    existedEmployee.relativePhone = input.relativePhone

                    //address & addressZoneId & bank
                    var userBankAccount = await UserBankAccount.findOne({
                        where: { userId: existedEmployee.id }
                    })
                    if (userBankAccount) {
                        userBankAccount.bankBranch = input.bankBranch
                        userBankAccount.accountHolder = input.accountHolder
                        userBankAccount.accountNumber = input.accountNumber
                        if (userBankAccount.bankName !== input.bankName) {
                            userBankAccount.bankId = null
                            userBankAccount.bankName = null
                            if (input.bankName) {
                                const { data, error } = await this.identityService.getBankDetailByName(input.bankName)
                                userBankAccount.bankId = data?.id
                                userBankAccount.bankName = data?.brandName
                            }
                        }
                    } else {
                        if (input.bankBranch || input.accountHolder || input.accountNumber) {
                            userBankAccount = UserBankAccount.create({
                                accountHolder: input.accountHolder,
                                accountNumber: input.accountNumber,
                                bankBranch: input.bankBranch,
                                userId: existedEmployee.id
                            })
                        }

                        if (input.bankName) {
                            const { data, error } = await this.identityService.getBankDetailByName(input.bankName)
                            if (data) {
                                if (userBankAccount) {
                                    userBankAccount.bankId = data.id
                                    userBankAccount.bankName = data.brandName
                                } else {
                                    userBankAccount = UserBankAccount.create({
                                        bankId: data.id,
                                        bankName: data.brandName,
                                        userId: existedEmployee.id
                                    })
                                }
                            }
                        }
                    }
                    if (userBankAccount) upsertUserBankAccounts.push(userBankAccount)

                    var userAddress = await UserAddress.findOne({
                        where: { userId: existedEmployee.id }
                    })
                    if (userAddress) {
                        userAddress.address = input.address
                        userAddress.addressZoneId = null
                        userAddress.provinceId = null
                        userAddress.province = null
                        userAddress.districtId = null
                        userAddress.district = null
                        userAddress.wardId = null
                        userAddress.ward = null
                        const addressZone = await this.addressService.addressZoneFindByDetailName(token, {
                            province: input.province || "",
                            district: input.district || "",
                            ward: input.ward || ""
                        })
                        if (addressZone) {
                            userAddress.addressZoneId = addressZone.id
                            var currentZone = addressZone
                            while (currentZone != null) {
                                switch (currentZone.level) {
                                    case "Province":
                                        userAddress.provinceId = currentZone.id
                                        userAddress.province = currentZone.name
                                        break
                                    case "District":
                                        userAddress.districtId = currentZone.id
                                        userAddress.district = currentZone.name
                                        break
                                    case "Ward":
                                        userAddress.wardId = currentZone.id
                                        userAddress.ward = currentZone.name
                                        break
                                }
                                currentZone = currentZone.parent
                            }
                        }
                    } else {
                        const addressZone = await this.addressService.addressZoneFindByDetailName(token, {
                            province: input.province || "",
                            district: input.district || "",
                            ward: input.ward || ""
                        })
                        if (input.address || addressZone) {
                            userAddress = UserAddress.create({
                                address: input.address,
                                userId: existedEmployee.id
                            })
                            userAddress.addressZoneId = addressZone.id
                            var currentZone = addressZone
                            while (currentZone != null) {
                                switch (currentZone.level) {
                                    case "Province":
                                        userAddress.provinceId = currentZone.id
                                        userAddress.province = currentZone.name
                                        break
                                    case "District":
                                        userAddress.districtId = currentZone.id
                                        userAddress.district = currentZone.name
                                        break
                                    case "Ward":
                                        userAddress.wardId = currentZone.id
                                        userAddress.ward = currentZone.name
                                        break
                                }
                                currentZone = currentZone.parent
                            }
                        }
                    }
                    if (userAddress) upsertUserAddresses.push(userAddress)

                    existedEmployee.status = ObjectStatus[input.status]
                    existedEmployee.updatedBy = requesterId
                    upsertEmployees.push(existedEmployee)
                    response.push({ ...input, errorMessage: 'Cập nhật thành công' })
                } else {
                    // insert
                    if (existedEmployeeCode || existedEmpCodes.includes(input.code)) {
                        response.push({ ...input, errorMessage: 'Mã nhân viên đã tồn tại trên hệ thống' })
                        continue
                    }

                    // if (!validatePhoneNumber(input.phone)) {
                    //     response.push({ ...input, errorMessage: 'Số điện thoại không đúng định dạng' })
                    //     continue
                    // }

                    const checkPhone = await OfficeUser.findOne({
                        where: {
                            phone: input.phone
                        }
                    })
                    if (checkPhone) {
                        response.push({ ...input, errorMessage: 'Số điện thoại đã thuộc về một nhân sự khác' })
                        continue
                    }

                    const officeUser = OfficeUser.create({
                        id: RandomHelper.generateUUID(),
                        fullname: input.fullname,
                        code: input.code,
                        phone: input.phone,
                        email: input.email,
                        status: ObjectStatus[input.status],
                        createdBy: requesterId,
                        updatedBy: requesterId,
                        // iamUserId: data.id,
                        // note: input.note,
                        // metadata: [JSON.stringify(args.data)]
                        personalEmail: input.personalEmail,
                        identityCard: input.identityCard,
                        idCardIssuedOn: input.idCardIssuedOn ? DateFormater.stringToDateWithFormat(input.idCardIssuedOn, 'DD/MM/yyyy') : null,
                        idCardIssuedPlace: input.idCardIssuedPlace,
                        dateOfBirth: input.birthday ? DateFormater.stringToDateWithFormat(input.birthday, 'DD/MM/yyyy') : null,
                        hrCode: input.hrCode,
                        major: input.major,
                        onboardingOn: input.onboardingOn ? DateFormater.stringToDateWithFormat(input.onboardingOn, 'DD/MM/yyyy') : null,
                        officalWorkingOn: input.officalWorkingOn ? DateFormater.stringToDateWithFormat(input.officalWorkingOn, 'DD/MM/yyyy') : null,
                        resigned: input.resigned?.trim() === LangVi.YES,
                        resignationType: input.resigned ? input.resignationType : null,
                        resignationReason: input.resigned ? input.resignationReason : null,
                        resignationDetailReason: input.resigned ? input.resignationDetailReason : null,
                        lastWorkingOn: (input.resigned && input.lastWorkingOn) ? DateFormater.stringToDateWithFormat(input.lastWorkingOn, 'DD/MM/yyyy') : null,
                        leaveOn: (input.resigned && input.leaveOn) ? DateFormater.stringToDateWithFormat(input.leaveOn, 'DD/MM/yyyy') : null,
                        taxCode: input.taxCode,
                        socialInsuranceCode: input.socialInsuranceCode,
                        relativePhone: input.relativePhone,
                        leaderId: leader?.id
                    })

                    //department & title
                    const unrecognizeDepartments = []
                    // const departments = input.departments.split(",")
                    const departments = [`${input.department}::${input.title}`]
                    const newUserDepartments: UserDepartment[] = []
                    for (const departmentInput of departments) {
                        const departmentArr = departmentInput.split("::")
                        const department = departmentArr.length > 0 ? departmentArr[0] : null
                        const title = departmentArr.length > 1 ? departmentArr[1] : null
                        if (department) {
                            var departmentEntity = departmentDict[department]
                            if (!departmentEntity) {
                                departmentEntity = await OfficeOrgChart.findOne({
                                    where: { code: department }
                                })

                                if (!departmentEntity) {
                                    unrecognizeDepartments.push(department)
                                } else {
                                    departmentDict[department] = departmentEntity
                                }
                            }

                            if (departmentEntity) {
                                const userDepartment = UserDepartment.create({
                                    departmentId: departmentEntity.id,
                                    userId: officeUser.id
                                })

                                if (title) {
                                    var titleEntity = titleDict[title]
                                    if (!titleEntity) {
                                        titleEntity = await OfficeTitle.findOne({
                                            where: { code: title }
                                        })
                                    }

                                    if (titleEntity) {
                                        titleDict[title] = titleEntity
                                        userDepartment.titleId = titleEntity.id
                                    }
                                }

                                newUserDepartments.push(userDepartment)
                            }
                        }
                    }

                    if (unrecognizeDepartments.length > 0) {
                        var departmentStr = ''
                        unrecognizeDepartments.forEach((value, index) => {
                            if (index < unrecognizeDepartments.length - 1) {
                                departmentStr += `${value}, `
                            } else {
                                departmentStr += `${value}`
                            }
                        })
                        response.push({ ...input, errorMessage: `Mã phòng ban ${departmentStr} chưa tồn tại trên hệ thống` })
                        continue
                    }

                    const { data, error } = await this.identityService.userCreate(
                        token,
                        input.fullname,
                        input.email,
                        input.phone
                    )
                    if (error) {
                        response.push({ ...input, errorMessage: `Lỗi hệ thống` })
                        continue
                    }
                    officeUser.iamUserId = data.id
                    officeUser.iamUserUsedIds = [data.id]

                    var newUserBankAccount = null
                    if (input.bankBranch || input.accountHolder || input.accountNumber) {
                        newUserBankAccount = UserBankAccount.create({
                            accountHolder: input.accountHolder,
                            accountNumber: input.accountNumber,
                            bankBranch: input.bankBranch,
                            userId: officeUser.id
                        })
                    }
                    if (input.bankName) {
                        const { data, error } = await this.identityService.getBankDetailByName(input.bankName)
                        if (data) {
                            if (newUserBankAccount) {
                                newUserBankAccount.bankId = data.id
                                newUserBankAccount.bankName = data.brandName
                            } else {
                                newUserBankAccount = UserBankAccount.create({
                                    bankId: data.id,
                                    bankName: data.brandName,
                                    userId: officeUser.id
                                })
                            }
                        }
                    }
                    if (newUserBankAccount) upsertUserBankAccounts.push(newUserBankAccount)

                    const addressZone = await this.addressService.addressZoneFindByDetailName(token, {
                        province: input.province || "",
                        district: input.district || "",
                        ward: input.ward || ""
                    })
                    if (input.address || addressZone) {
                        userAddress = UserAddress.create({
                            address: input.address,
                            userId: officeUser.id
                        })
                        userAddress.addressZoneId = addressZone?.id
                        var currentZone = addressZone
                        while (currentZone != null) {
                            switch (currentZone.level) {
                                case "Province":
                                    userAddress.provinceId = currentZone.id
                                    userAddress.province = currentZone.name
                                    break
                                case "District":
                                    userAddress.districtId = currentZone.id
                                    userAddress.district = currentZone.name
                                    break
                                case "Ward":
                                    userAddress.wardId = currentZone.id
                                    userAddress.ward = currentZone.name
                                    break
                            }
                            currentZone = currentZone.parent
                        }
                    }
                    if (userAddress) upsertUserAddresses.push(userAddress)

                    newUserDepartments.forEach(nud => {
                        upsertUserDepartments.push(nud)
                    })

                    upsertEmployees.push(officeUser)
                    response.push({ ...input, errorMessage: 'Tạo mới thành công' })
                    existedEmpCodes.push(input.code)
                }
            }

            // for (const iterator of upsertEmployees) {
            //     await iterator.save()
            // }

            /*await this.dataSource.manager.transaction(async entity => {

                await entity.remove(removeUserDepartments)
                await entity.save(upsertUserDepartments)
                await entity.save(upsertUserBankAccounts)
                await entity.save(upsertUserAddresses)

                for (const item of upsertEmployees) {
                    await entity.save(item)
                }
            })*/

            await this.dataSource.manager.remove(removeUserDepartments)
            await this.dataSource.manager.save(upsertUserDepartments)
            await this.dataSource.manager.save(upsertUserBankAccounts)
            await this.dataSource.manager.save(upsertUserAddresses)

            for (const item of upsertEmployees) {
                await this.dataSource.manager.save(item)
            }

            return {
                total: response.length,
                count: response.length,
                records: response
            }
        } catch (error) {
            console.log(`Bulk upsert employee has error: ${error}`)
            throw error
        }
    }

    async managementEmployeeBulkUpsertBasicData(officeUsers: ImportEmployeeArgs[]) {
        const response: ImportEmployeeResponse[] = []

        for (const officeUser of officeUsers) {
            if (officeUser.errorMessage) {
                response.push(officeUser as ImportEmployeeResponse)
                continue
            }

            response.push(await this.managementEmployeeUpsertBasicData(officeUser))
        }

        return {
            total: response.length,
            count: response.length,
            records: response
        }
    }

    async managementEmployeeBulkCreate(officeUsers: EmployeeBulkCreateImport[]) {
        const response: ImportBulkCreateResponse[] = []

        for (const officeUser of officeUsers) {
            if (officeUser.errorMessage) {
                response.push(officeUser as ImportBulkCreateResponse)
                continue
            }

            response.push(await this.managementEmployeeCreate(officeUser))
        }

        return {
            total: response.length,
            count: response.length,
            records: response
        }
    }

    private async managementEmployeeCreate(input: EmployeeBulkCreateImport) {
        let validation = await this.validateEmployeeCreateRequired(input)
        if (validation) return validation

        validation = await this.validateEmployeeUpsertBasicField(input)
        if (validation) return validation

        return this.importToCreateUser({
            ...input,
        })
    }

    private async validateEmployeeCreateRequired(input: EmployeeBulkCreateImport) {
        const basicFieldsNormalRequired = [
            input.status,
            input.fullname,
            input.phone,
            input.identityCard,
            input.idCardIssuedOn,
            input.idCardIssuedPlace,
            input.birthday,
            input.onboardingOn,
            input.department,
            input.major,
        ]

        if ([...basicFieldsNormalRequired].filter(i => !i).length) {
            return { ...input, errorMessage: OfficeErrorMessage.RequiredField }
        }

        return null
    }

    private async managementEmployeeUpsertBasicData(input: ImportEmployeeArgs) {
        let validation: any = await this.validateEmployeeUpsertBasicDataRequired(input)
        if (validation) return validation

        validation = await this.validateEmployeeUpsertBasicField(input)
        if (validation) return validation

        if (!input.id) {
            return this.importToCreateUser(input)
        }

        if (!isUUID(input.id)) {
            return { ...input, errorMessage: OfficeErrorMessage.WrongUserId }
        }

        return this.importToUpdateUserBasicData(input)
    }

    private async validateEmployeeUpsertBasicDataRequired(input: ImportEmployeeArgs) {
        const basicFieldsNormalRequired = [
            input.status,
            input.fullname,
            input.phone,
            // input.address,
            input.province,
            input.district,
            input.ward,
            input.identityCard,
            input.idCardIssuedOn,
            input.idCardIssuedPlace,
            input.birthday,
            input.onboardingOn,
            // input.officalWorkingOn,
            // input.taxCode,
            // input.socialInsuranceCode,
            // input.resigned
        ]
        const basicFieldsWorkProfileRequired = [
            // input.title,
            input.department,
            input.major,
            input.leaderCode
        ]

        /*const resignedFields = [
            input.resignationType,
            input.resignationReason,
            input.resignationDetailReason,
            input.lastWorkingOn,
            input.leaveOn
        ]*/

        if (input.id) {
            /*validate update data*/
            // if (basicFieldsNormalRequired.filter(i => !i).length) {
            //     return { ...input, errorMessage: OfficeErrorMessage.RequiredField }
            // }
        } else {
            /*validate create data*/
            if ([...basicFieldsNormalRequired, ...basicFieldsWorkProfileRequired].filter(i => !i).length) {
                return { ...input, errorMessage: OfficeErrorMessage.RequiredField }
            }
        }

        /*Required resigned fields*/
        /*if (![LangVi.YES, LangVi.NO].includes(input?.resigned?.trim())) {
            return { ...input, errorMessage: OfficeErrorMessage.OfficeUserResignedTypeError }
        }
        if (input.resigned && input?.resigned?.trim() === LangVi.YES && resignedFields.filter(i => !i).length) {
            return { ...input, errorMessage: OfficeErrorMessage.RequiredField }
        }*/

        /*Todo: move out*/
        /*if (input?.resigned?.trim() === LangVi.NO) {
            input.resignationType = null
            input.resignationReason = null
            input.resignationDetailReason = null
            input.lastWorkingOn = null
            input.leaveOn = null
        }*/

        /*Validate title*/
        if (input.title && !await this.titleRepo.getBy({ code: input.title })) {
            return {
                ...input,
                errorMessage: OfficeErrorMessage.OfficeTitleNotExisted
            }
        }

        /*validate leader*/
        let leader = {id: null}
        if (input.leaderCode) {
            leader = await this.officeUserRepo.getBy({code: input.leaderCode})
            if (!leader) {
                return {
                    ...input,
                    errorMessage: OfficeErrorMessage.OfficeLeaderNotExisted
                }
            }
        }

        return null
    }

    private async validateEmployeeUpsertBasicField(input: ImportEmployeeArgs | EmployeeBulkCreateImport) {
        const invalidFields = []
        if (input.phone && !validatePhoneNumber(input.phone)) invalidFields.push('Số điện thoại')
        if (input.email && !validateEmail(input.email)) invalidFields.push('Email công ty')
        if (input.personalEmail && !validateEmail(input.personalEmail)) invalidFields.push('Email cá nhân')
        if (input.idCardIssuedOn && !validator.isDate(input.idCardIssuedOn, { format: 'DD/MM/yyyy' })) invalidFields.push('Ngày cấp')
        if (input.birthday && !validator.isDate(input.birthday, { format: 'DD/MM/yyyy' })) invalidFields.push('Ngày sinh')
        if (input.onboardingOn && !validator.isDate(input.onboardingOn, { format: 'DD/MM/yyyy' })) invalidFields.push('Ngày vào công ty')
        if (input.officalWorkingOn && !validator.isDate(input.officalWorkingOn, { format: 'DD/MM/yyyy' })) invalidFields.push('Ngày chính thức')
        if (input.relativePhone && !validatePhoneNumber(input.relativePhone)) invalidFields.push('SĐT người thân')

        if (input instanceof ImportEmployeeArgs) {
            if (input?.lastWorkingOn && !validator.isDate(input?.lastWorkingOn, { format: 'DD/MM/yyyy' })) invalidFields.push('Ngày làm việc cuối cùng')
            if (input?.leaveOn && !validator.isDate(input?.leaveOn, { format: 'DD/MM/yyyy' })) invalidFields.push('Ngày hiệu lực thôi việc')
        }

        if (invalidFields.length > 0) {
            let invalidFieldStr = ''
            for (const iterator of invalidFields) {
                if (invalidFieldStr) {
                    invalidFieldStr += (`, ${iterator}`)
                } else {
                    invalidFieldStr += iterator
                }
            }
            return { ...input, errorMessage: `Vui lòng nhập đúng định dạng trường ${invalidFieldStr}` }
        }

        if (input.status && !Object.keys(ObjectStatus).includes(input.status)) {
            return { ...input, errorMessage: 'Vui lòng nhập giá trị là Active hoặc Inactive' }
        }

        return null
    }

    private async importToCreateUser(input: ImportEmployeeArgs | EmployeeBulkCreateImport) {
        const department = input.department ? await this.orgChartRepository.getBy({code: input.department}) : null
        const title = input.title ? await this.titleRepo.getBy({code: input.title}) : null
        const leader = input.leaderCode ? await this.officeUserRepo.getBy({code: input.leaderCode}) : null

        const addressZone = await this.addressService.addressZoneFindByDetailName(RequestContext.currentToken(), {
            province: input.province || "",
            district: input.district || "",
            ward: input.ward || ""
        })

        // const data = await this.getSoftBasicData(input)

        const bank = await this.getBankInfoByName(input?.bankName)

        const param: AddEmployeeArgs = {
            ...input,
            departments: [{
                companyId: null,
                departmentId: department?.id,
                titleId: title?.id
            }],
            addressZoneId: addressZone?.id,
            note: null,
            tempAddress: null,
            tempAddressZoneId: null,
            attachFileIds: null,
            bankId: bank?.id,
            imageIds: null,
            leaderId: leader?.id,
            dateOfBirth: datetimeGetDateFromFormat('DD/MM/yyyy', input.birthday)?.getTime(),
            idCardIssuedOn: datetimeGetDateFromFormat('DD/MM/yyyy', input.idCardIssuedOn)?.getTime(),
            status: ObjectStatus[input.status],
            onboardingOn: datetimeGetDateFromFormat('DD/MM/yyyy', input.onboardingOn)?.getTime(),
            officalWorkingOn: input.officalWorkingOn ? datetimeGetDateFromFormat('DD/MM/yyyy', input.officalWorkingOn)?.getTime() : null,
            leaveOn: null,
            data: null
        }

        if (input instanceof ImportEmployeeArgs) {
            param.leaveOn = input.leaveOn ? datetimeGetDateFromFormat('DD/MM/yyyy', input.leaveOn)?.getTime() : null
            param.data = input.data
        }

        try {
            await this.managementAddEmployee(param)
        } catch (err) {
            const mess = err?.baseMsg
            return {
                ...input,
                errorMessage: mess ?? (typeof err?.response?.message === 'string' ? err?.response?.message : err?.response?.message?.[0])
            }
        }

        return { ...input, errorMessage: OfficeSuccessMessage.Create }
    }

    private async importToUpdateUserBasicData(input: ImportEmployeeArgs) {
        const validation = await this.validateFieldCannotUpdate(input)

        if (validation) {
            return validation
        }
        
        const addressZone = await this.addressService.addressZoneFindByDetailName(RequestContext.currentToken(), {
            province: input.province || "",
            district: input.district || "",
            ward: input.ward || ""
        })

        let bank = null
        if (input.bankName) bank = await this.getBankInfoByName(input.bankName)

        let resigned: boolean | undefined = undefined
        if (input.resigned !== null) resigned = input.resigned === LangVi.YES

        const param: EditEmployeeArgs = {
            ...input,
            addressZoneId: addressZone?.id,
            attachFileIds: null,
            bankId: bank ? bank?.id : null,
            companyId: null,
            data: undefined,
            departments: null,
            imageIds: null,
            leaderId: null,
            note: null,
            phoneNumber: input.phone,
            tempAddress: null,
            tempAddressZoneId: null,
            resigned,
            dateOfBirth: datetimeGetDateFromFormat('DD/MM/yyyy', input.birthday)?.getTime() ?? null,
            idCardIssuedOn: datetimeGetDateFromFormat('DD/MM/yyyy', input.idCardIssuedOn)?.getTime() ?? null,
            status: input.status ? ObjectStatus[input.status] : null,
            onboardingOn: datetimeGetDateFromFormat('DD/MM/yyyy', input.onboardingOn)?.getTime() ?? null,
            leaveOn: datetimeGetDateFromFormat('DD/MM/yyyy', input.leaveOn)?.getTime() ?? null,
            officalWorkingOn: datetimeGetDateFromFormat('DD/MM/yyyy', input.officalWorkingOn)?.getTime() ?? null,
            lastWorkingOn: datetimeGetDateFromFormat('DD/MM/yyyy', input.lastWorkingOn)?.getTime() ?? null
        }

        try {
            await this.managementEditEmployee(param)
        } catch (err) {
            const mess = err?.baseMsg
            return {
                ...input,
                errorMessage: mess ?? (typeof err?.response?.message === 'string' ? err?.response?.message : err?.response?.message?.[0])
            }
        }

        return { ...input, errorMessage: OfficeSuccessMessage.Update }
    }

    private async validateFieldCannotUpdate(input: ImportEmployeeArgs) {
        const workProfileFields = [
            'title',
            'department',
            'major',
            'leaderCode',
            'code',
        ]

        const softWorkDetailFields = await this.officeInfoFieldRepo.listSoftWorkDetailDefaultField()
        workProfileFields.push(...pluck(softWorkDetailFields, 'code'))
        const softFieldsTitle = pluck(softWorkDetailFields, 'name', 'code')

        const fields = workProfileFields.filter(i => input.data?.[i])

        if (fields.length) {
            const fieldsName = fields
                .map(i => IMPORT_USER_COMMON_HEADER[i]
                    ? IMPORT_USER_COMMON_HEADER[i]
                    : softFieldsTitle[i]
                )
                .join(', ')

            return {
                ...input,
                errorMessage: `${OfficeErrorMessage.CannotUpdateWorkProfileDataWhenUpdateUser}, trường vi phạm: ${fieldsName}`
            }
        }

        return null
    }

    private async getBankInfoByName(bankName: string) {
        if (bankName) {
            const { data, error } = await this.identityService.getBankDetailByName(bankName)
            if (data) {
                return data
            }
        }

        return null
    }

    async officeEmployeeAvatarUpdate(args: OfficeEmployeeAvatarUpdateInput) {
        const user = await this.officeUserRepo.getCurrentUser()
        user.imageIds = [args.imageId, ...(user?.imageIds?.length ? user.imageIds : [])]
        user.imageUrls = [args['file'][0].location, ...(user?.imageUrls?.length ? user.imageUrls : [])]

        await this.officeUserRepo.save(user)
        return args['file'][0];
    }
}