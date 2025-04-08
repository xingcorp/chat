import { forwardRef, Inject, Injectable } from '@nestjs/common';
import {
    DetailWorkProfileRepo,
    InfoWorkProfileRepo,
    OfficeInfoBlockRepo,
    OfficeInfoFieldRepo,
    OfficeOrgChartRepo,
    OfficeUserRepo,
    TitleRepo,
    UserDepartmentRepo,
    WorkProfileRepo
} from "@models/repositories";
import {
    ManagementWorkProfileFilter,
    OfficeWorkProfileFilter,
    WorkProfileBulkUpsertInput,
    WorkProfileCreateInput,
    WorkProfileUpdateInput
} from "@modules/graphql/management/work-profile/dto/work-profile.args";
import { DataSource, ILike, LessThanOrEqual, ObjectLiteral } from "typeorm";
import {
    WorkProfileAction,
    WorkProfileActionKind,
    WorkProfileChangeType,
    WorkProfileChangeTypeExplain
} from "@enum/work-profile/work-profile.enum";
import { enumGetKey, enumTextGetKeys } from "@utils/enum.utils";
import { arrayObjectSortNormalKey } from "@utils/array.utils";
import { EntityManager } from "typeorm/entity-manager/EntityManager";
import {
    OfficeUser,
    UserDepartment,
    UserWorkProfile,
    UserWorkProfileDetail,
    UserWorkProfileInfo
} from "@models/entities";
import { OfficeSuccessMessage } from "@common/office.success";
import { OfficeError, OfficeErrorMessage } from "@common/office.error";
import * as ExcelJS from "exceljs";
import { RequestContext } from "@common/context/request.context";
import { FileCleanType } from "@core/storage/objects/file";
import { StorageService } from "@core/storage/storage.service";
import {
    defineAndSetImportWorkProfileHeader,
    IMPORT_WORK_PROFILE_COMMON_HEADER,
    importWorkProfileTemplateAddDemoData,
    styleImportWorkProfile,
    WORK_PROFILE_EXPORT_TYPE
} from "@modules/graphql/management/work-profile/helper/template/import-work-profile.template";
import { pluck, removeUndefinedValue } from "@utils/object.utils";
import {
    datetimeEndOfLocalDay,
    datetimeGetDateLocalFromFormat,
    datetimeGetTimestampLocalFromFormat
} from "@utils/datetime.utils";
import { LangVi } from "@utils/lang";
import {
    WorkProfileBulkUpsertRecordResponse
} from "@modules/graphql/management/work-profile/dto/work-profile.response";
import { isUUID } from "validator";
import { exportWorkProfileData } from "@modules/graphql/management/work-profile/helper/export/work-profile.export";
import { CACHE_KEY } from "@common/cache-key.common";
import {
    seedFieldWorkProfile,
    seedWorkProfileResignSoftField
} from "@models/seeds/work-profile/field.work-profile.seed";
import { RedisService } from "@core/common/redis.service";
import { LinkFieldType } from "@enum/block/field.enum";
import { stringNumberWithZeroLeading } from "@utils/string.utils";
import { ObjectStatus } from "@models/entities/profile.info.block";

@Injectable()
export class WorkProfileService {
    private manager: EntityManager;

    constructor(
        private dataSource: DataSource,
        private officeUserRepo: OfficeUserRepo,
        private orgChartRepo: OfficeOrgChartRepo,
        private titleRepo: TitleRepo,
        private officeInfoBlockRepo: OfficeInfoBlockRepo,
        private officeInfoFieldRepo: OfficeInfoFieldRepo,
        private workProfileRepo: WorkProfileRepo,
        private infoWorkProfileRepo: InfoWorkProfileRepo,
        private detailWorkProfileRepo: DetailWorkProfileRepo,
        private userDepartmentRepo: UserDepartmentRepo,
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
        @Inject(RedisService)
        private readonly redisService: RedisService,
    ) {
    }

    async getSoftFields() {
        let block = await this.officeInfoBlockRepo.getWorkProfile()

        if (!block) {
            return null
        }

        return this.officeInfoFieldRepo.getByBlockId(block.id);
    }

    async create(args: WorkProfileCreateInput, manager: EntityManager = this.dataSource.manager) {
        const workProfile = this.workProfileRepo.createNew()
        const user = await this.officeUserRepo.getById(args.userId)
        workProfile.user = args.user ?? user

        const info = this.infoWorkProfileRepo.createNew(args)
        info.workProfile = workProfile

        if (user) {
            const userDepartment = await this.userDepartmentRepo.getByUserId(user.id)
            args.departmentId = args.departmentId ?? userDepartment.departmentId
            args.titleId = args.titleId ?? userDepartment.titleId
            args.leaderId = args.leaderId ?? user.leaderId
            args.major = args.major ?? user.major
            args.userCode = args.userCode ?? user.code
        }

        const detail = this.detailWorkProfileRepo.createNew(args)
        detail.department = args.departmentId ? await this.orgChartRepo.findOneBy({ id: args.departmentId }) : null
        detail.title = args.titleId ? await this.titleRepo.findOneBy({ id: args.titleId }) : null
        detail.leader = args.leaderId ? await this.officeUserRepo.getById(args.leaderId) : null
        detail.workProfile = workProfile

        /*await manager.transaction(async entity => {
            await entity.save(workProfile)
            await entity.save(info)
            await entity.save(detail)
        })*/

        await workProfile.save()
        await info.save()
        await detail.save()

        await workProfile.reload()

        return workProfile;
    }

    async update(args: WorkProfileUpdateInput) {
        const workProfile = await this.workProfileRepo.findOneBy({ id: args.id })
        const info = await this.infoWorkProfileRepo.changeByWorkProfileId(args.id, args)
        const detail = await this.detailWorkProfileRepo.changeByWorkProfileId(args.id, args)
        const requesterId = await RequestContext.currentId()

        const actionType = args.type ? this.infoWorkProfileRepo.getActionTypeByType(args.type) : info.actionType
        if (actionType !== info.actionType) {
            throw OfficeError.WorkProfileInfoActionTypeCannotUpdate
        }

        detail.department = args.departmentId ? await this.orgChartRepo.findOneBy({ id: args.departmentId }) : detail.department
        detail.title = args.titleId ? await this.titleRepo.findOneBy({ id: args.titleId }) : detail.title
        detail.leader = args.leaderId ? await this.officeUserRepo.getById(args.leaderId) : detail.leader

        workProfile.updatedBy = requesterId
        info.updatedBy = requesterId
        detail.updatedBy = requesterId
        detail.updatedAt = new Date()

        /*await this.dataSource.manager.transaction(async entity => {
            await entity.save(workProfile)
            await entity.save(info)
            await entity.save(detail)
        })*/

        await workProfile.save()
        await info.save()
        await detail.save()

        await workProfile.reload()

        return workProfile;
    }

    infoTypeGetList() {
        const res = []

        enumTextGetKeys(WorkProfileChangeType).map(i => {
            res.push({
                key: WorkProfileChangeType[i],
                type: this.infoWorkProfileRepo.getActionTypeByType(WorkProfileChangeType[i]),
                title: WorkProfileChangeTypeExplain[i]
            })
        })

        return arrayObjectSortNormalKey(res, 'title');
    }

    get(id: string) {
        return this.workProfileRepo.getValidById(id);
    }

    async listOfUser(filter: OfficeWorkProfileFilter) {
        const [data, total] = await this.workProfileRepo.listWithFilterOfUser(filter as ManagementWorkProfileFilter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async listByUserId(filter: ManagementWorkProfileFilter) {
        const [data, total] = await this.workProfileRepo.listWithFilterByUserId(filter.userId, filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async exportWorkProfile(filter: ManagementWorkProfileFilter) {
        const [data, total] = await this.workProfileRepo.listWithFilterByUserId(filter.userId, filter)

        let excelName = `work-profile`
        if (filter.userId) excelName += `-${filter.userId}`

        return this.workProfileFileDataExport(WORK_PROFILE_EXPORT_TYPE.DATA, {
            sheetName: 'Quá trình làm việc',
            excelName: `${excelName}.xlsx`,
            data
        })
    }

    async cronUpdateWorkProfileDataToUser() {
        const wpsActiveToday = await this.infoWorkProfileRepo.allActiveTodayRecord()

        const workProfiles = wpsActiveToday?.map(i => i?.workProfile)

        for (const workProfile of workProfiles) {
            console.log('cronUpdateWorkProfileDataToUser update code:', workProfile.code)
            const detail = await this.detailWorkProfileRepo.getByWorkProfileId(workProfile.id)

            await this.updateUserWorkProfileData(workProfile?.user?.id, detail)
            console.log('cronUpdateWorkProfileDataToUser update code:', workProfile.code, 'done')
        }
    }

    async updateUserWorkProfileData(userId: string, workProfileDetail: UserWorkProfileDetail | ObjectLiteral, manager: EntityManager = this.dataSource.manager, action: WorkProfileActionKind = WorkProfileActionKind.Create) {
        const user = await this.officeUserRepo.getById(userId)
        console.log('updateUserWorkProfileData 1111', workProfileDetail.userCode, user.code)
        user.code = workProfileDetail.userCode ?? user.code
        user.major = workProfileDetail.major ?? user.major
        user.leaderId = workProfileDetail.leader ? workProfileDetail.leader.id : user.leaderId

        console.log('updateUserWorkProfileData 2222')

        const department = await this.userDepartmentRepo.getByUserId(user.id)
        department.departmentId = workProfileDetail.department ? workProfileDetail.department.id : department.departmentId
        department.titleId = workProfileDetail.title ? workProfileDetail.title.id : department.titleId

        console.log('updateUserWorkProfileData 3333')

        const info = await manager.getRepository(UserWorkProfileInfo).findOne({
            relations: ['workProfile'],
            where: {
                workProfile: {
                    id: workProfileDetail.workProfile.id
                },
            }
        })

        this.manager = manager

        console.log('updateUserWorkProfileData 4444')

        if (info) {
            switch (info.actionType) {
                case WorkProfileAction.Remove:
                    await this.updateUserResignData(user, workProfileDetail, info)
                    break
                case WorkProfileAction.Create:
                    if (action === WorkProfileActionKind.Create) {
                        await this.updateCreateData(user, workProfileDetail, info)
                    }

                    break
            }
        }

        console.log('updateUserWorkProfileData 5555', user)

        await department.save()
        await user.save()

        console.log('updateUserWorkProfileData 6666', workProfileDetail)
    }

    private async updateUserResignData(user: OfficeUser, workProfileDetail: UserWorkProfileDetail | ObjectLiteral, info: UserWorkProfileInfo) {
        const orgId = await this.orgChartRepo.getRootIdOfDepartmentId(workProfileDetail.department.id)
        const block = await this.officeInfoBlockRepo.getWorkProfileByOrgId(orgId)
        const resignFields = await this.officeInfoFieldRepo.getWorkProfileResignFieldByBlockId(block.id)
        const metadata = workProfileDetail.metadata

        user.resigned = true
        if (resignFields.map(i => i.code).some(i => Object.keys(metadata).includes(i))) {
            for (const resignField of resignFields) {
                switch (resignField.linkFieldType) {
                    case LinkFieldType.resignationType:
                    case LinkFieldType.resignationReason:
                    case LinkFieldType.resignationDetailReason:
                        user[resignField.linkFieldType] = metadata[resignField.code] ?? user[resignField.linkFieldType]
                        break
                    case LinkFieldType.lastWorkingOn:
                    case LinkFieldType.leaveOn:
                        user[resignField.linkFieldType] = metadata[resignField.code] ? new Date(metadata[resignField.code]) : user[resignField.linkFieldType]
                        break
                }
            }
        }

        /*add default soft data*/
        const workProfilePenultimate = await this.getPenultimateRecord(user.id, 1, this.manager)
        const workProfileDetailPenultimate = await this.detailWorkProfileRepo.getByWorkProfileId(workProfilePenultimate.id)
        workProfileDetail.metadata = {
            ...removeUndefinedValue(workProfileDetailPenultimate.metadata),
            ...removeUndefinedValue(workProfileDetail.metadata)
        }
    }

    private async updateCreateData(user: OfficeUser, workProfileDetail: UserWorkProfileDetail | ObjectLiteral, info: UserWorkProfileInfo) {
        this.activeUser(user)

        switch (info.type) {
            case WorkProfileChangeType.NewRecruitment:
            case WorkProfileChangeType.TransferCompany:
                await this.updateCreateDataUserNewRecruitment(user, workProfileDetail)
                break
            default:
                break
        }
    }
    async bulkUpsert(args: WorkProfileBulkUpsertInput[]) {
        for (const row of args) {
            if (row.errorMessage) continue

            let user: OfficeUser
            let userDepartment: UserDepartment
            if (row.userCodeUpdate) {
                user = await this.officeUserRepo.getBy({ code: row.userCodeUpdate })
                userDepartment = await UserDepartment.findOne({
                    where: {
                        userId: user.id
                    }
                })
            }
            const type = WorkProfileChangeType[enumGetKey(WorkProfileChangeTypeExplain, row.typeText)]

            const { transformData, errorMessage } = await this.officeInfoFieldRepo.validateAndTransformData(row.metadata)

            if (errorMessage) {
                row.errorMessage = errorMessage
                continue
            }

            const data = {
                ...row,
                attachmentIds: null,
                activeDate: row.activeDate ? datetimeGetTimestampLocalFromFormat(datetimeGetDateLocalFromFormat('DD/MM/yyyy', row.activeDate)) : null,
                endDate: row.endDate ? datetimeGetTimestampLocalFromFormat(datetimeGetDateLocalFromFormat('DD/MM/yyyy', row.endDate)) : null,
                decidedDate: row.decidedDate ? datetimeGetTimestampLocalFromFormat(datetimeGetDateLocalFromFormat('DD/MM/yyyy', row.decidedDate)) : null,
                departmentId: userDepartment?.departmentId,
                isDecided: row.decided === LangVi.YES,
                leaderId: user?.leaderId,
                titleId: userDepartment?.titleId,
                userCode: row.userCode ?? user.code,
                major: row.major ?? user.major,
                type,
                metadata: transformData
            }

            if (row.department) {
                const department = await this.orgChartRepo.getBy({ code: row.department })
                data.departmentId = department.id
            }

            if (row.title) {
                const title = await this.titleRepo.getBy({ code: row.title })
                data.titleId = title.id
            }

            if (row.leader) {
                const leader = await this.officeUserRepo.getBy({ code: row.leader })
                data.leaderId = leader.id
            }

            try {
                if (row.id) {
                    /*update*/

                    /*can not update user*/
                    if (row.userCodeUpdate) {
                        row.errorMessage = OfficeErrorMessage.CannotChangeUser
                        continue
                    }

                    if (!isUUID(row.id)) {
                        row.errorMessage = OfficeErrorMessage.WrongUserId
                        continue
                    }

                    await this.update(data)

                    row.errorMessage = OfficeSuccessMessage.Update
                } else {
                    /*required user data*/
                    if (!row.userCodeUpdate) {
                        row.errorMessage = OfficeErrorMessage.RequiredField
                        continue
                    }

                    const user = await this.officeUserRepo.getBy({ code: row.userCodeUpdate })

                    /*create*/
                    await this.create({ ...data, userId: user.id })

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
            records: args as WorkProfileBulkUpsertRecordResponse[]
        };
    }

    private async workProfileFileDataExport(type: WORK_PROFILE_EXPORT_TYPE, param: {
        sheetName: string;
        excelName: string;
        data?: UserWorkProfile[]
    }) {
        const { sheetName, excelName, data } = param
        const workbook = new ExcelJS.Workbook();

        workbook.created = new Date();
        workbook.modified = new Date();
        workbook.lastPrinted = new Date();

        let chartSheet = workbook.addWorksheet(sheetName)

        const { softRows, softRowsDemoData } = await this.officeInfoFieldRepo.listSoftWorkDetailDataField()

        defineAndSetImportWorkProfileHeader(chartSheet, softRows)
        switch (type) {
            case WORK_PROFILE_EXPORT_TYPE.TEMPLATE:
                importWorkProfileTemplateAddDemoData(chartSheet, softRowsDemoData)
                break
            case WORK_PROFILE_EXPORT_TYPE.DATA:
                exportWorkProfileData(chartSheet, data)
                break

        }

        styleImportWorkProfile(chartSheet)

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

    async importWorkProfileTemplateExport() {
        return this.workProfileFileDataExport(WORK_PROFILE_EXPORT_TYPE.TEMPLATE, {
            sheetName: 'Template import quá trình làm việc',
            excelName: `Template-import-work-profile.xlsx`
        })
    }

    async importWorkProfileFieldsGet() {
        const fields = Object.keys(IMPORT_WORK_PROFILE_COMMON_HEADER)
        const softWorkDetailFields = await this.officeInfoFieldRepo.listSoftWorkDetailField()
        fields.push(...(pluck(softWorkDetailFields, 'code').map(i => `metadata.${i}`)))

        return { fields }
    }

    async importWorkProfileFieldsGetTitle() {
        const fields = Object.values(IMPORT_WORK_PROFILE_COMMON_HEADER)
        const softWorkDetailFields = await this.officeInfoFieldRepo.listSoftWorkDetailField()
        fields.push(...(pluck(softWorkDetailFields, 'name')))

        return { fields }
    }

    async seedData() {
        console.log('seedFieldWorkProfile check')
        if (!process.env.K_ORG_ID) return
        const key = CACHE_KEY.K_ORG_WORK_PROFILE
        const cached = await this.redisService.get(key)

        if (cached && cached === process.env.K_ORG_ID) {
            return
        }

        await this.redisService.set(key, process.env.K_ORG_ID)

        let block = await this.officeInfoBlockRepo.getWorkProfileByOrgId(process.env.K_ORG_ID)

        if (!block) {
            console.log('seedFieldWorkProfile start')
            await seedFieldWorkProfile()
        }

        return true
    }

    async seedSoftResignField() {
        console.log('seedSoftResignField check')

        const roots = await this.orgChartRepo.getAllRoot()

        for (const root of roots) {
            let block = await this.officeInfoBlockRepo.getWorkProfileByOrgId(root.id)
            if (!block) {
                block = await this.officeInfoBlockRepo.createWorkProfileByOrgId(root.id)
            }
            console.log('seedSoftResignField block', block.id)
            const checkNotSeed = !((await this.officeInfoFieldRepo.getSoftFieldLinkedOfKOrg(block.id)).length)

            if (!checkNotSeed) {
                console.log('seedSoftResignField seeded', block.code)
                continue
            }

            console.log('seedSoftResignField start', block.code)
            await seedWorkProfileResignSoftField(root.id)
            console.log('seedSoftResignField done', block.code)
        }
    }

    private async updateCreateDataUserNewRecruitment(user: OfficeUser, workProfileDetail: UserWorkProfileDetail | ObjectLiteral) {
        await this.genUserCode(user, workProfileDetail)
    }

    async genUserCode(user: OfficeUser, workProfileDetail: UserWorkProfileDetail | ObjectLiteral) {
        const company = await this.orgChartRepo.getL2OrgById(workProfileDetail.department.id)

        let lastOrgUser = await this.officeUserRepo.findOne({
            where: {
                companyId: company.id
            },
            order: {
                code: 'DESC'
            }
        })

        if (lastOrgUser) {
            lastOrgUser = await OfficeUser.findOne({
                where: {
                    code: ILike(`${company.code}%`)
                },
                order: {
                    code: 'DESC'
                }
            })
        }

        const numberLength = 7
        let currentNumber = parseInt(lastOrgUser ? lastOrgUser.code.slice(-numberLength).replace(/\D/g, "") : '0')

        let check = true
        while (check) {
            currentNumber = currentNumber + 1
            user.code = `${company.code}${stringNumberWithZeroLeading(currentNumber, numberLength)}`
            check = !!(await OfficeUser.count({
                where: {
                    code: user.code
                }
            }))
        }
        workProfileDetail.userCode = user.code
    }

    async fillNewDataActionType() {
        const list = await this.infoWorkProfileRepo.listNullActionType()

        for (const item of list) {
            item.actionType = this.infoWorkProfileRepo.getActionTypeByType(item.type)
        }

        return this.infoWorkProfileRepo.save(list)
    }

    private async getPenultimateRecord(userId: string, ordinal: number = 1, manager: EntityManager = this.dataSource.manager) {
        const infos = await manager.getRepository(UserWorkProfileInfo).find({
            relations: ['workProfile'],
            where: {
                workProfile: {
                    user: { id: userId }
                },
                activeDate: LessThanOrEqual(datetimeEndOfLocalDay())
            },
            order: {
                activeDate: "DESC"
            }
        })

        if (infos.length < (ordinal + 1)) return null

        return this.workProfileRepo.findOneBy({ id: infos[ordinal].workProfile.id })
    }

    private activeUser(user: OfficeUser) {
        user.status = ObjectStatus.Active
        user.resigned = false
    }
}
