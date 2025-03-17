import { forwardRef, Inject, Injectable } from "@nestjs/common";
import {
    ApprovalField,
    ApprovalFormField,
    ApprovalFormStep,
    ApprovalStep,
    OfficeApproval,
    OfficeFilter,
    OfficeOrgChart, OfficeSysUser,
    OfficeUser,
    OrgChartApprovalForm,
    UserDepartment
} from "src/models/entities";
import {
    ApprovalActionArgs,
    ApprovalApproveStepUpdateInput,
    ApprovalArgs,
    ApprovalCommentCreate,
    ApprovalFilter,
    ApprovalFilterCreateInput,
    ApprovalFilterListFilter,
    ApprovalFilterUpdateInput,
    ApprovalFormArgs,
    ApprovalFormFilter, ApprovalForwardDataInput,
    ApprovalSubscriberUpdateInput,
    ApprovalUpdateInput,
    EditApprovalFormArgs
} from "./approval.args";
import { RandomHelper } from "src/common/random";
import { ApprovalProcessAction } from "src/models/entities/approval.step";
import { ApprovalOwnerStatus, ApprovalSource, ApprovalStatus } from "src/models/entities/approval";
import { OfficeError } from "src/common/office.error";
import {
    ArrayContains,
    Between,
    Brackets,
    Connection,
    ILike,
    In,
    IsNull, LessThan,
    LessThanOrEqual,
    MoreThanOrEqual,
    Not
} from "typeorm";
import { DataType } from "src/models/entities/profile.info.field";
import { BaseError } from "src/modules/core/core.error";
import { ActionUnit, ApprovalAction, ApprovalForm, ApprovalType, ObjectScope } from "src/models/entities/approval.form";
import { StorageService } from "src/modules/core/storage/storage.service";
import { ApprovalTableRow, TableRowStatus } from "src/models/entities/approval.table.row";
import { ApprovalFormTableColumn } from "src/models/entities/approval.form.table.column";
import { ApprovalTableRowData } from "src/models/entities/approval.table.row.data";
import { InjectConnection } from "@nestjs/typeorm";
import { OfficeOrgChartRepo } from "@models/repositories/office-org-chart.repo";
import { OfficeSysUserRepo } from "@models/repositories/office-sys-user.repo";
import { OfficeUserRepo } from "@repositories/profile.user.repo";
import { UserType } from "@core/middleware/guard/service.action";
import { ObjectStatus } from "@models/entities/profile.info.block";
import {
    ApprovalFormRepo,
    ApprovalForwardRepo, ApprovalForwardUserRepo,
    ApprovalStepRepo,
    FilterRepo,
    OfficeApprovalRepo, OfficeLogRepo
} from "@models/repositories";
import { LogAction, OfficeFeatureLogType } from "@enum/logs/logs.enum";
import { LogService } from "@modules/graphql/log/log.service";
import { OfficeLogCommentArgs, OfficeLogHistoryArgs } from "@modules/graphql/log/dto/log.args";
import { RequestContext } from "@common/context/request.context";
import { BRIDGE_TABLE_DB, BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import { ApprovalSubmitTypeEnum, YourActionEnum } from "@enum/approval/approval/approval.enum";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";
import { ApprovalMenuCategoryItemResponse } from "@modules/graphql/approval/approval.response";
import { GrantType } from "@utils/enum.utils";

@Injectable()
export class ApprovalService {
    constructor(
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
        @InjectConnection()
        private readonly connection: Connection,
        private orgChartRepository: OfficeOrgChartRepo,
        private officeSysUserRepo: OfficeSysUserRepo,
        private officeUserRepo: OfficeUserRepo,
        private officeApprovalRepo: OfficeApprovalRepo,
        private approvalStepRepo: ApprovalStepRepo,
        private approvalFormRepo: ApprovalFormRepo,
        private readonly logService: LogService,
        private readonly filterRepo: FilterRepo,
        @Inject(forwardRef(() => OfficeOrgChartRepo))
        private readonly officeOrgChartRepo: OfficeOrgChartRepo,
        private readonly approvalForwardRepo: ApprovalForwardRepo,
        private readonly approvalForwardUserRepo: ApprovalForwardUserRepo,
        private readonly logRepo: OfficeLogRepo,
    ) {
    }

    public async submitApproval(args: ApprovalArgs, requestId: string = null, approval?: OfficeApproval): Promise<OfficeApproval> {
        console.log("[submitApproval] args: ", JSON.stringify(args))
        const token = RequestContext.currentToken()
        const requesterId = RequestContext.currentRequestId()
        const now = new Date()

        let requester = await RequestContext.currentUser()

        if (args.draftId && args.submitType !== ApprovalSubmitTypeEnum.Draft) {
            await this.removeByRequester(args.draftId, requester)
        }

        if (!approval) {
            approval = OfficeApproval.create({
                id: RandomHelper.generateUUID(),
                source: args.source,
                requestId: requestId,
                createdBy: requester.id,
                updatedBy: requester.id
            })
        } else {
            await this.approvalDeleteAllRelationTable(approval)
        }

        var fields: ApprovalField[] = []
        var steps: ApprovalStep[] = [ApprovalStep.create({
            id: RandomHelper.generateUUID(),
            order: 1,
            createdBy: requester.id,
            updatedBy: requester.id,
            approvalId: approval.id,
            action: ApprovalProcessAction.Submit,
            actionBy: requester.id,
            actionAt: now
        })]
        var fieldTableRows: ApprovalTableRow[] = []
        var fieldTableRowDatas: ApprovalTableRowData[] = []
        var notiApproverIds = []

        let checkAutoApprove = true
        let isAutoApprove = false
        switch (approval.source) {
            case ApprovalSource.Blank:
                if (!args.name) throw OfficeError.ApprovalNameIsRequired
                approval.name = args.name
                approval.note = args.note
                approval.subscriberIds = args.subscriberIds
                approval.type = args.type ?? ApprovalType.Other
                approval.relationId = args.relationId ?? null
                /*if (args.structure.subscriber.length > 0) {
                    const subscribers = await OfficeUser.find({
                        where: {
                            id: In(args.structure.subscriber)
                        }
                    })
                    if (subscribers.length > 0) {
                        approval.subscriberIds = subscribers.map(sub => sub.id)
                    }
                }*/
                if (args.structure.fields) {
                    for (const element of args.structure.fields) {
                        const field = ApprovalField.create({
                            id: RandomHelper.generateUUID(),
                            name: element.name,
                            required: element.required,
                            dataType: element.dataType,
                            order: (fields.length + 1),
                            createdBy: requester.id,
                            updatedBy: requester.id,
                            approvalId: approval.id
                        })
                        if ([DataType.Text, DataType.Text_Area, DataType.Text_Html].includes(field.dataType)) {
                            if (field.required && !element.textValue) throw new BaseError(OfficeError.ApprovalFieldIsRequired.code, `Trường thông tin [${field.name}] bắt buộc nhập`)
                            field.hintText = element.hintText
                            field.textValue = element.textValue
                        } else if (field.dataType === DataType.Date) {
                            if (field.required && !element.dateValue) throw new BaseError(OfficeError.ApprovalFieldIsRequired.code, `Trường thông tin [${field.name}] bắt buộc nhập`)
                            field.timeInPast = element.timeInPast
                            field.dateValue = new Date(element.dateValue)
                        } else if (field.dataType === DataType.List) {
                            // if (field.required && (!element.listValues || element.listValues.length === 0) ) throw new BaseError(OfficeError.ApprovalFieldIsRequired.code, `Trường thông tin [${field.name}] bắt buộc nhập`)
                            field.optionItems = element.optionItems
                            field.multiSelect = element.multiSelect
                            field.listValues = (element.listValues || []).filter(v => (element.optionItems || []).includes(v))
                            if (field.required && (!field.listValues || field.listValues.length === 0)) throw new BaseError(OfficeError.ApprovalFieldIsRequired.code, `Trường thông tin [${field.name}] bắt buộc nhập`)
                        }

                        fields.push(field)
                    }
                }
                if (args.structure.steps && this.isNotForwardData(args.submitType)) {
                    await this.blankApprovalStepCreate(args, steps, approval)
                }

                break
            case ApprovalSource.Template:
                const template = await ApprovalForm.findOne({
                    where: {
                        id: args.formId ?? approval.formId
                    }
                })
                if (!template) throw OfficeError.ApprovalFormNotFound

                approval.note = args.note
                approval.name = args.name ? args.name : template.name
                approval.formId = template.id
                approval.type = template.type
                approval.relationId = args.relationId ?? null
                // approval.subscriberIds = template.subscriberIds
                approval.subscriberIds = arrayConvertToDistinctAndNotNull([
                    ...(args.subscriberIds ?? []),
                    ...(template.subscriberIds ?? [])])
                const templateFields = await ApprovalFormField.find({
                    where: {formId: template.id},
                    order: {order: "ASC"}
                })
                for (const tf of templateFields) {
                    const approvalField = ApprovalField.create({
                        id: RandomHelper.generateUUID(),
                        name: tf.name,
                        required: tf.required,
                        dataType: tf.dataType,
                        hintText: tf.hintText,
                        timeInPast: tf.timeInPast,
                        optionItems: tf.optionItems,
                        multiSelect: tf.multiSelect,
                        order: tf.order,
                        createdBy: requester.id,
                        updatedBy: requester.id,
                        approvalId: approval.id
                    })
                    const value = args.formFieldData ? args.formFieldData[`_${tf.order}`] : null
                    if (approvalField.required && !value) {
                        throw new BaseError(OfficeError.ApprovalFieldIsRequired.code, `Trường thông tin [${tf.name}] bắt buộc nhập`)
                    }
                    if ([DataType.Text, DataType.Text_Area, DataType.Text_Html].includes(approvalField.dataType)) {
                        approvalField.textValue = value
                    } else if (approvalField.dataType === DataType.Date) {
                        if (Number(value)) {
                            approvalField.dateValue = new Date(Number(value))
                        } else if (approvalField.required) {
                            throw new BaseError(OfficeError.ApprovalFieldInvalid.code, `Dữ liệu đầu vào trường thông tin [${tf.name}] không hợp lệ`)
                        }
                    } else if (approvalField.dataType === DataType.List) {
                        if (Array.isArray(value)) {
                            approvalField.listValues = value.filter(v => (tf.optionItems || []).includes(v))
                            if (approvalField.required && approvalField.listValues.length === 0) throw new BaseError(OfficeError.ApprovalFieldIsRequired.code, `Trường thông tin [${tf.name}] bắt buộc nhập`)
                        } else if (approvalField.required) {
                            throw new BaseError(OfficeError.ApprovalFieldIsRequired.code, `Trường thông tin [${tf.name}] phải có dạng danh sách`)
                        }
                    } else if (approvalField.dataType === DataType.Table) {
                        if (Array.isArray(value)) {
                            const tableColumns = await ApprovalFormTableColumn.find({
                                where: {fieldId: tf.id},
                                order: {order: "ASC"}
                            })
                            for (let i = 0; i < value.length; i++) {
                                const rowObject = value[i];
                                const fieldRow = ApprovalTableRow.create({
                                    id: RandomHelper.generateUUID(),
                                    fieldId: approvalField.id,
                                    approvalId: approval.id,
                                    order: i + 1
                                })
                                for (let index = 0; index < tableColumns.length; index++) {
                                    const column = tableColumns[index]
                                    const objectValue = rowObject[`_${column.order}`]
                                    const rowData = ApprovalTableRowData.create({
                                        id: RandomHelper.generateUUID(),
                                        name: column.name,
                                        required: column.required,
                                        dataType: column.dataType,
                                        hintText: column.hintText,
                                        timeInPast: column.timeInPast,
                                        optionItems: column.optionItems,
                                        multiSelect: column.multiSelect,
                                        order: column.order,
                                        createdBy: requester.id,
                                        updatedBy: requester.id,
                                        approvalId: approval.id,
                                        rowId: fieldRow.id,
                                        fieldId: approvalField.id
                                    })
                                    if ([DataType.Text, DataType.Text_Area, DataType.Text_Html].includes(column.dataType)) {
                                        rowData.textValue = objectValue
                                    } else if (column.dataType === DataType.Date) {
                                        if (Number(objectValue)) {
                                            rowData.dateValue = new Date(Number(objectValue))
                                        }
                                    } else if (column.dataType === DataType.List) {
                                        if (Array.isArray(objectValue)) {
                                            rowData.listValues = objectValue.filter(v => (column.optionItems || []).includes(v))
                                        }
                                    }
                                    fieldTableRowDatas.push(rowData)
                                }
                                fieldTableRows.push(fieldRow)
                            }
                        } else if (approvalField.required) {
                            throw new BaseError(OfficeError.ApprovalFieldIsRequired.code, `Trường thông tin [${tf.name}] phải có dạng bảng`)
                        }
                    }

                    fields.push(approvalField)
                }
                const templateSteps = await ApprovalFormStep.find({
                    where: {formId: template.id},
                    order: {order: "ASC"}
                })

                if (this.isNotForwardData(args.submitType)) {
                    let currentStepAuto = true
                    for (const ts of templateSteps) {
                        var approverIds = ts.approveBy || []
                        if (ts.action === ApprovalAction.Approve && ts.unit === ActionUnit.Department) {
                            const department = await OfficeOrgChart.findOne({
                                where: {id: ts.departmentId}
                            })
                            if (!department) throw OfficeError.OrgChartNotFound
                            // approverIds = department.approverId ? [department.approverId] : []
                            if (department.approverId) approverIds.push(department.approverId)
                        }
                        if (ts.action === ApprovalAction.Approve && ts.unit === ActionUnit.Level) {
                            //Tìm phòng ban theo level
                            const departments = await this.getDepartmentByRequesterId(requesterId)
                            const department = departments.length > 0 ? departments[0] : null
                            const orgChartIds = department ? department.path.substring(1).split("/").reverse() : []
                            if (ts.approverLevel && ts.approverLevel <= orgChartIds.length) {
                                const departmentId = orgChartIds[ts.approverLevel - 1]
                                const apprpvalDepartment = await OfficeOrgChart.findOne({
                                    where: {id: departmentId}
                                })
                                console.log("apprpvalDepartment: ", apprpvalDepartment)
                                if (!apprpvalDepartment) throw OfficeError.OrgChartNotFound
                                // approverIds = department.approverId ? [department.approverId] : []
                                if (apprpvalDepartment.approverId) approverIds.push(apprpvalDepartment.approverId)
                            }
                        }
                        if (ts.action === ApprovalAction.Approve && ts.unit === ActionUnit.Leader) {
                            if (requester.leaderId && !approverIds.includes(requester.leaderId)) {
                                approverIds.push(requester.leaderId)
                            }
                        }
                        if (approverIds.length === 0 && ts.action === ApprovalAction.Approve) throw OfficeError.FormApproverNotFound

                        let action = this.checkStepAutoApprove(checkAutoApprove, ts.action, approverIds, requester.id)

                        checkAutoApprove = action === ApprovalProcessAction.Approve
                        isAutoApprove = isAutoApprove || action === ApprovalProcessAction.Approve

                        steps.push(ApprovalStep.create({
                            id: RandomHelper.generateUUID(),
                            approveBy: approverIds,
                            // approveBy: ts.approveBy,
                            action,
                            actionBy: action ? requester.id : null,
                            actionAt: action ? new Date() : null,
                            approverLevel: ts.approverLevel,
                            departmentId: ts.departmentId,
                            consentBy: ts.consentBy,
                            unit: ts.unit,
                            approvalAction: ts.action,
                            order: ts.order + 1,
                            createdBy: requester.id,
                            updatedBy: requester.id,
                            approvalId: approval.id,
                        }))

                        currentStepAuto = checkAutoApprove

                        notiApproverIds = notiApproverIds.concat(approverIds)
                    }
                }

                break
        }

        if (args.imageIds) {
            /*reset*/
            approval.imageIds = []

            for (const imageId of args.imageIds) {
                const {data, error} = await this.storageService.getFileDetail(token, imageId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted
                if (approval.imageIds) {
                    approval.imageIds.push(imageId)
                } else {
                    approval.imageIds = [imageId]
                }
                if (approval.imageUrls) {
                    approval.imageUrls.push(data.location)
                } else {
                    approval.imageUrls = [data.location]
                }
            }
        }
        if (args.attachmentIds) {
            /*reset*/
            approval.attachmentIds = []

            for (const attachmentId of args.attachmentIds) {
                const {data, error} = await this.storageService.getFileDetail(token, attachmentId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted
                if (approval.attachmentIds) {
                    approval.attachmentIds.push(attachmentId)
                } else {
                    approval.attachmentIds = [attachmentId]
                }
                if (approval.attachmentUrls) {
                    approval.attachmentUrls.push(data.location)
                } else {
                    approval.attachmentUrls = [data.location]
                }
            }
        }

        /*store approval first if draft*/
        this.setApprovalStatus(approval, args)

        if (checkAutoApprove && isAutoApprove) {
            approval.status = ApprovalStatus.Approved
        }

        await approval.save()

        if (fields.length > 0) await ApprovalField.save(fields)
        if (fieldTableRows.length > 0) await ApprovalTableRow.save(fieldTableRows)
        if (fieldTableRowDatas.length > 0) await ApprovalTableRowData.save(fieldTableRowDatas)

        if (this.isNotForwardData(args.submitType)) {
            for (const step of steps) {
                await step.save()
            }
        } else {
            await this.approvalForwardSetData(approval, args.forwardData)
        }

        await approval.save()
        return approval
    }

    update(args: ApprovalUpdateInput) {
        return this.submitApproval(args as ApprovalArgs, null, args.approval)
    }

    public async getColumnNameByTableField(fieldId: string) {
        let query = `select oatrd."name"
                    from office."office-approval-table-row-datas" oatrd 
                    where oatrd."deletedAt" is null and oatrd."fieldId" = '${fieldId}'
                    group by oatrd."name", oatrd."order" 
                    order by oatrd."order" asc`

        return this.connection.query(query)
    }

    public async getDepartmentByRequesterId(requesterId: string): Promise<OfficeOrgChart[]> {
        let query = `select ooc.*
                    from office."office-org-charts" ooc 
                    where ooc."deletedAt" is null and ooc.id::text in (select oud."departmentId" 
                    from office."office-user-departments" oud where oud."deletedAt" is null
                    and oud."userId" in (select ou.id::text from office."office-users" ou where ou."deletedAt" is null and ou."iamUserId" = '${requesterId}'))`

        return this.connection.query(query)
    }

    public async getApprovalFormList(filter: ApprovalFormFilter, userType: string, requesterId: string) {
        filter.size = filter.size ? filter.size : 20 // 4
        filter.page = filter.page ? (filter.page - 1) : 0

        let query

        switch (userType) {
            case UserType.NORMAL_USER.toString():
                query = await this.getApprovalFormListUser(filter)

                break
            case UserType.SYSTEM_USER.toString():
                query = await this.getApprovalFormListAdmin(filter)
                break
            default:
        }

        await this.getApprovalFormListFilter(query, filter)

        return query.getManyAndCount()
    }

    private async getApprovalFormListUser(filter: ApprovalFormFilter) {
        const userId = await RequestContext.currentId()

        const query = ApprovalForm.createQueryBuilder('ap')
            .leftJoinAndMapMany('ap.departments', OrgChartApprovalForm, 'oc', 'oc."formId" = ap.id::text')
            .leftJoinAndSelect(BRIDGE_TABLE_DB.APPROVAL_FORM_USER, 'wBridge', '"wBridge"."officeApprovalFormsId" = ap.id')
            .where({})
            .take(filter.size)
            .skip(filter.page * filter.size)
            .orderBy('ap.createdAt', 'DESC')
            .andWhere({status: ObjectStatus.Active})

        const departmentId = await this.officeUserRepo.getDepartmentIdBy({iamUserId: RequestContext.currentRequestId()})
        // const orgIds = await this.orgChartRepository.getAllIdsCurrentAndChild([departmentId])

        query.andWhere(new Brackets(db => {
            db.where(`oc."departmentId"::text IN (:...orgIds)`, {orgIds: [departmentId]})
            .orWhere(`"wBridge"."officeUsersId" = :userId`, {userId})
        }))

        if (filter && !filter.type) {
            query.andWhere({type: ApprovalType.Other})
        }

        return query
    }

    private async getApprovalFormListAdmin(filter: ApprovalFormFilter) {
        const requesterId = RequestContext.currentRequestId()
        const query = ApprovalForm.createQueryBuilder('ap')
            .leftJoinAndMapMany('ap.departments', OrgChartApprovalForm, 'oc', 'oc."formId" = ap.id::text')
            .where({})
            .take(filter.size)
            .skip(filter.page * filter.size)
            .orderBy('ap.createdAt', 'DESC')

        const oogIds = await this.officeSysUserRepo.getOrgChartIds(requesterId)

        if (oogIds) {
            const ids = await this.orgChartRepository.getAllIdsCurrentAndChild(oogIds)

            query.andWhere(`oc."departmentId"::text IN (:...oogIds)`, {oogIds: ids})
        }

        return query
    }

    private async getApprovalFormListFilter(query, filter: ApprovalFormFilter) {
        if (filter && filter.status) {
            query.andWhere({status: filter.status})
        }



        if (filter && filter.keyword) {
            query.andWhere(`unaccent(LOWER(ap.name)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
        }

        if (filter && filter.orgChartIds) {
            const relations = await OrgChartApprovalForm.find({
                where: {
                    departmentId: In(filter.orgChartIds)
                }
            })
            query.andWhere({id: In(relations.map(r => r.formId))})
        }
    }

    async getApprovalList(filter: ApprovalFilter, officeRequester: OfficeUser) {
        const page = filter.page ? (filter.page - 1) : 0
        const size = filter.size ? filter.size : 20
        let query = OfficeApproval.createQueryBuilder('qb')
            .where({
                isPublic: true
            })
            .skip(page * size)
            .take(size)
            .orderBy('qb.createdAt', 'DESC')

        if (filter.status) {
            switch (filter.status) {
                case ApprovalOwnerStatus.NextAction:
                    filter.yourAction = filter?.yourAction?.length
                        ? [YourActionEnum.Approve, YourActionEnum.Consent].filter(i => filter.yourAction.includes(i))
                        : [YourActionEnum.Approve, YourActionEnum.Consent]
                    if (!filter.yourAction.length) return this.defaultZeroApprovalRecord()
                    await this.approvalListWaiting(query, officeRequester)
                    break
                case ApprovalOwnerStatus.Waiting:
                    filter.yourAction = filter?.yourAction?.length
                        ? [YourActionEnum.Waiting].filter(i => filter.yourAction.includes(i))
                        : [YourActionEnum.Waiting]
                    if (!filter.yourAction.length) return this.defaultZeroApprovalRecord()
                    await this.approvalListWaiting(query, officeRequester)
                    break
                case ApprovalOwnerStatus.Approved:
                    await this.approvalListApproved(query, officeRequester)
                    break
                case ApprovalOwnerStatus.Notify:
                    await this.approvalListNotify(query, officeRequester)
                    break
                case ApprovalOwnerStatus.Submitted:
                    await this.approvalListSubmitted(query, officeRequester)
                    break
                case ApprovalOwnerStatus.Draft:
                    await this.approvalListDraft(query, officeRequester)
                    break
                case ApprovalOwnerStatus.Forward:
                    await this.approvalListForward(query, officeRequester)
                    break
            }
        } else {
            await this.approvalListNoStatus(query, officeRequester)
        }

        await this.approvalListWithFilter(query, filter)

        const [list, total] = await query.getManyAndCount()
        return {
            total,
            count: list.length,
            approvals: list
        }
    }

    private checkStepAutoApprove(checkAutoApprove: boolean, approvalAction: ApprovalAction, approverIds: string[], requestId: string) {
        if (!checkAutoApprove) return null;

        if (approverIds.includes(requestId) && approvalAction === ApprovalAction.Approve) return ApprovalProcessAction.Approve

        return null;
    }

    async commentCreate(args: ApprovalCommentCreate) {
        const approval = await this.officeApprovalRepo.getBy({id: args.approvalId})
        let param: any = args

        param.featureLogType = OfficeFeatureLogType.Approval
        param.featureLogId = approval.id
        param.description = args.comment

        delete param.approvalId
        delete param.comment

        await this.logService.commentCreate(param as OfficeLogCommentArgs)

        await approval.reload()
        return approval;
    }

    private async getApprovalUserCanComment(args: ApprovalCommentCreate) {
        const approval = await this.officeApprovalRepo.getApprovalUserCanSeeById(args.approvalId)

        if (!approval) {
            throw OfficeError.ApprovalNotFound
        }

        return approval
    }

    async addApprovalForm(args: ApprovalFormArgs, token: string, requesterId: string) {
        const existedForm = await ApprovalForm.findOne({
            where: {
                name: args.name
            }
        })

        if (existedForm) {
            throw OfficeError.ApprovalFormIsExisted
        }

        const form = ApprovalForm.create({
            id: RandomHelper.generateUUID(),
            name: args.name,
            note: args.note,
            status: args.status,
            createdBy: requesterId,
            updatedBy: requesterId
        })

        if (args.type) {
            form.type = args.type
        }

        const orgChartForms: OrgChartApprovalForm[] = []
        if (args.departmentIds.length > 0) {
            const departments = await OfficeOrgChart.find({
                where: {
                    id: In(args.departmentIds)
                }
            })
            if (departments.length === 0) {
                form.scope = ObjectScope.Common
            } else {
                form.scope = ObjectScope.Specified
                for (const department of departments) {
                    orgChartForms.push(OrgChartApprovalForm.create({
                        formId: form.id,
                        departmentId: department.id
                    }))
                }
            }
        } else {
            form.scope = ObjectScope.Common
        }

        if (args.userIds && args.userIds.length) {
            form.scope = ObjectScope.Specified
            form.users = await this.officeUserRepo.listByIds(args.userIds)
        }

        const formFields: ApprovalFormField[] = []
        const formTableColumns: ApprovalFormTableColumn[] = []
        if (args.fields) {
            for (const element of args.fields) {
                const field = ApprovalFormField.create({
                    id: RandomHelper.generateUUID(),
                    name: element.name,
                    dataType: element.dataType,
                    required: element.required,
                    formId: form.id,
                    order: (formFields.length + 1)
                })
                if ([DataType.Text, DataType.Text_Area, DataType.Text_Html].includes(field.dataType)) {
                    field.hintText = element.hintText
                } else if (field.dataType === DataType.Date) {
                    field.timeInPast = element.timeInPast
                } else if (field.dataType === DataType.List) {
                    /*Todo: No need now*/
                    /*if (arrayHaveDuplicateValue(element.optionItems)) {
                        throw OfficeError.ListHaveSameValue
                    }*/

                    field.optionItems = element.optionItems
                    field.multiSelect = element.multiSelect
                } else if (field.dataType === DataType.Table) {
                    if (element.columns && element.columns.length > 0) {
                        for (let i = 0; i < element.columns.length; i++) {
                            const column = element.columns[i];
                            formTableColumns.push(ApprovalFormTableColumn.create({
                                name: column.name,
                                required: column.required,
                                fieldId: field.id,
                                formId: form.id,
                                order: i + 1
                            }))
                        }
                    } else {
                        throw OfficeError.ApprovalFormTableFieldEmptyColumn
                    }
                }

                formFields.push(field)
            }
        }

        if (args.subscriber.length > 0) {
            const subscribers = await OfficeUser.find({
                where: {
                    id: In(args.subscriber)
                }
            })
            if (subscribers.length > 0) {
                form.subscriberIds = subscribers.map(sub => sub.id)
            }
        } else {
            form.subscriberIds = []
        }

        const formSteps: ApprovalFormStep[] = []
        if (args.steps) {
            for (const element of args.steps) {
                const step = ApprovalFormStep.create({
                    action: element.action,
                    formId: form.id,
                    order: (formSteps.length + 1)
                })
                if (element.action === ApprovalAction.Approve && element.approver) {
                    step.unit = element.approver.unit
                    if (element.approver.unit === ActionUnit.Person) {
                        const approvers = await OfficeUser.find({
                            where: { id: In(element.approver.approveBy) }
                        })
                        if (approvers.length === 0) throw OfficeError.FormApproverNotFound
                        step.approveBy = approvers.map(a => a.id)
                    } else if (element.approver.unit === ActionUnit.Department) {
                        if (!element.approver.departmentId) throw OfficeError.FormDepartmentNotFound
                        const department = await OfficeOrgChart.findOne({
                            where: { id: element.approver.departmentId }
                        })
                        if (!department) throw OfficeError.FormDepartmentNotFound
                        step.departmentId = department.id
                        if (element.approver.approveBy.length > 0) { //phê duyệt song song
                            const approvers = await OfficeUser.find({
                                where: { id: In(element.approver.approveBy) }
                            })
                            step.approveBy = approvers.map(a => a.id)
                        }
                    } else if (element.approver.unit === ActionUnit.Level) {
                        step.approverLevel = element.approver.level
                        if (element.approver.approveBy.length > 0) { //phê duyệt song song
                            const approvers = await OfficeUser.find({
                                where: { id: In(element.approver.approveBy) }
                            })
                            step.approveBy = approvers.map(a => a.id)
                        }
                    } else if (element.approver.unit === ActionUnit.Leader) {
                        if (element.approver.approveBy.length > 0) { //phê duyệt song song
                            const approvers = await OfficeUser.find({
                                where: { id: In(element.approver.approveBy) }
                            })
                            step.approveBy = approvers.map(a => a.id)
                        }
                    }
                } else if (element.action === ApprovalAction.Consent && element.consentBy.length > 0) {
                    step.unit = ActionUnit.Person
                    const consentBy = await OfficeUser.find({
                        where: { id: In(element.consentBy) }
                    })
                    if (consentBy.length === 0) throw OfficeError.FormConsentByNotFound
                    step.consentBy = consentBy.map(c => c.id)
                }

                formSteps.push(step)
            }
        }

        if (args.imageIds) {
            for (const imageId of args.imageIds) {
                const { data, error } = await this.storageService.getFileDetail(token, imageId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted

                if (form.imageIds) {
                    form.imageIds.push(imageId)
                } else {
                    form.imageIds = [imageId]
                }

                if (form.imageUrls) {
                    form.imageUrls.push(data.location)
                } else {
                    form.imageUrls = [data.location]
                }
            }
        }

        if (orgChartForms.length > 0) await OrgChartApprovalForm.save(orgChartForms)
        if (formFields.length > 0) await ApprovalFormField.save(formFields)
        if (formSteps.length > 0) await ApprovalFormStep.save(formSteps)
        if (formTableColumns.length > 0) await ApprovalFormTableColumn.save(formTableColumns)

        /*store group*/
        form.groups = args.formGroups

        return form.save()
    }

    async officeApprovalEditForm(args: EditApprovalFormArgs, token: string, requesterId: string) {
        const existedForm = await ApprovalForm.findOne({
            where: {
                id: args.id
            }
        })

        if (!existedForm) {
            throw OfficeError.ApprovalFormNotFound
        }

        // if (args.name) existedForm.name = args.name
        if (args.name && args.name !== existedForm.name) {
            const checkExistedName = await ApprovalForm.findOne({
                where: {
                    name: args.name
                }
            })
            if (checkExistedName) throw OfficeError.ApprovalFormIsExisted
            existedForm.name = args.name
        }
        if (args.note !== undefined) existedForm.note = args.note
        if (args.status) existedForm.status = args.status
        if (args.subscriber) {
            const subscribers = await OfficeUser.find({
                where: {
                    id: In(args.subscriber)
                }
            })
            existedForm.subscriberIds = subscribers.map(sub => sub.id)
        }
        const orgChartForms: OrgChartApprovalForm[] = []
        if (args.departmentIds) {
            const departments = await OfficeOrgChart.find({
                where: {
                    id: In(args.departmentIds)
                }
            })
            if (departments.length === 0) {
                existedForm.scope = ObjectScope.Common
            } else {
                existedForm.scope = ObjectScope.Specified
                for (const department of departments) {
                    orgChartForms.push(OrgChartApprovalForm.create({
                        formId: existedForm.id,
                        departmentId: department.id
                    }))
                }
            }
        }

        if (args.userIds) {
            existedForm.scope = ObjectScope.Specified
            existedForm.users = await this.officeUserRepo.listByIds(args.userIds)
        }

        if (args.fields) {
            const formFields: ApprovalFormField[] = []
            const formTableColumns: ApprovalFormTableColumn[] = []
            for (const element of args.fields) {
                const field = ApprovalFormField.create({
                    id: RandomHelper.generateUUID(),
                    name: element.name,
                    dataType: element.dataType,
                    required: element.required,
                    formId: existedForm.id,
                    order: (formFields.length + 1)
                })
                if ([DataType.Text, DataType.Text_Area, DataType.Text_Html].includes(field.dataType)) {
                    field.hintText = element.hintText
                } else if (field.dataType === DataType.Date) {
                    field.timeInPast = element.timeInPast
                } else if (field.dataType === DataType.List) {
                    /*Todo: No need now*/
                    /*if (arrayHaveDuplicateValue(element.optionItems)) {
                        throw OfficeError.ListHaveSameValue
                    }*/

                    field.optionItems = element.optionItems
                    field.multiSelect = element.multiSelect
                } else if (field.dataType === DataType.Table) {
                    if (element.columns && element.columns.length > 0) {
                        for (let i = 0; i < element.columns.length; i++) {
                            const column = element.columns[i];
                            formTableColumns.push(ApprovalFormTableColumn.create({
                                name: column.name,
                                required: column.required,
                                fieldId: field.id,
                                formId: existedForm.id,
                                order: i + 1
                            }))
                        }
                    } else {
                        throw OfficeError.ApprovalFormTableFieldEmptyColumn
                    }
                }

                formFields.push(field)
            }

            await ApprovalFormField.delete({ formId: existedForm.id })
            await ApprovalFormField.save(formFields)
            await ApprovalFormTableColumn.delete({ formId: existedForm.id })
            await ApprovalFormTableColumn.save(formTableColumns)
        } else {
            await ApprovalFormField.delete({ formId: existedForm.id })
            await ApprovalFormTableColumn.delete({ formId: existedForm.id })
        }

        if (args.steps) {
            const formSteps: ApprovalFormStep[] = []
            for (const element of args.steps) {
                const step = ApprovalFormStep.create({
                    action: element.action,
                    formId: existedForm.id,
                    order: (formSteps.length + 1)
                })
                if (element.action === ApprovalAction.Approve && element.approver) {
                    step.unit = element.approver.unit
                    if (element.approver.unit === ActionUnit.Person) {
                        const approvers = await OfficeUser.find({
                            where: { id: In(element.approver.approveBy) }
                        })
                        if (approvers.length === 0) throw OfficeError.FormApproverNotFound
                        step.approveBy = approvers.map(a => a.id)
                    } else if (element.approver.unit === ActionUnit.Department) {
                        if (!element.approver.departmentId) throw OfficeError.FormDepartmentNotFound
                        const department = await OfficeOrgChart.findOne({
                            where: { id: element.approver.departmentId }
                        })
                        if (!department) throw OfficeError.FormDepartmentNotFound
                        step.departmentId = department.id
                        if (element.approver.approveBy.length > 0) { //phê duyệt song song
                            const approvers = await OfficeUser.find({
                                where: { id: In(element.approver.approveBy) }
                            })
                            step.approveBy = approvers.map(a => a.id)
                        }
                    } else if (element.approver.unit === ActionUnit.Level) {
                        step.approverLevel = element.approver.level
                        if (element.approver.approveBy.length > 0) { //phê duyệt song song
                            const approvers = await OfficeUser.find({
                                where: { id: In(element.approver.approveBy) }
                            })
                            step.approveBy = approvers.map(a => a.id)
                        }
                    }
                } else if (element.action === ApprovalAction.Consent && element.consentBy.length > 0) {
                    step.unit = ActionUnit.Person
                    const consentBy = await OfficeUser.find({
                        where: { id: In(element.consentBy) }
                    })
                    if (consentBy.length === 0) throw OfficeError.FormConsentByNotFound
                    step.consentBy = consentBy.map(c => c.id)
                }

                formSteps.push(step)
            }

            await ApprovalFormStep.delete({ formId: existedForm.id })
            await ApprovalFormStep.save(formSteps)
        }

        if (args.imageIds) {
            for (const imageId of args.imageIds) {
                const { data, error } = await this.storageService.getFileDetail(token, imageId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted

                if (existedForm.imageIds) {
                    existedForm.imageIds.push(imageId)
                } else {
                    existedForm.imageIds = [imageId]
                }

                if (existedForm.imageUrls) {
                    existedForm.imageUrls.push(data.location)
                } else {
                    existedForm.imageUrls = [data.location]
                }
            }
        }

        if (existedForm.scope === ObjectScope.Common || orgChartForms.length > 0) {
            await OrgChartApprovalForm.delete({
                formId: existedForm.id
            })
            if (orgChartForms.length > 0) await OrgChartApprovalForm.save(orgChartForms)
        }
        existedForm.updatedBy = requesterId

        /*store group*/
        existedForm.groups = args.formGroups

        return existedForm.save()
    }

    async approvalGet(id: string) {
        const approval = await this.officeApprovalRepo.findOne({
            where: { id: id }
        })

        if (!approval) throw OfficeError.ApprovalNotFound

        await this.officeUserRepo.readApproval(approval)

        return approval
    }

    async approvalGetPublic(id: string) {
        const approval = await this.officeApprovalRepo.findOne({
            where: { id: id }
        })

        if (!approval) throw OfficeError.ApprovalNotFound

        return approval
    }

    private setApprovalStatus(approval: OfficeApproval, args: ApprovalArgs) {
        switch (args.submitType) {
            case ApprovalSubmitTypeEnum.Draft:
                approval.status = ApprovalStatus.Draft
                return
            case ApprovalSubmitTypeEnum.Forward:
                approval.status = ApprovalStatus.Forward
                return
            default:
                return
        }
    }

    async remove(id: string) {
        const approval = await this.officeApprovalRepo.getOneBy({id})

        if (!approval) {
            throw OfficeError.ApprovalNotFound
        }

        await this.officeApprovalRepo.softRemove(approval)

        return approval
    }

    async removeByRequester(id: string, requester: OfficeUser|OfficeSysUser) {
        // const approval = await this.officeApprovalRepo.getOneBy({id})
        const approval = await this.officeApprovalRepo.findOne({
            where: {
                id: id,
                createdBy: requester.id
            },
            withDeleted: true
        })

        if (approval.deletedAt) return approval

        if (!approval) {
            throw OfficeError.ApprovalNotFound
        }

        await this.officeApprovalRepo.softRemove(approval)

        return approval
    }

    private async approvalListWaiting(query: SelectQueryBuilder<OfficeApproval>, officeRequester: OfficeUser) {
        const pendingSteps = await ApprovalStep.find({
            where: [{
                approvalAction: ApprovalAction.Approve,
                // currentStep: true,
                actionBy: IsNull(),
                // approverId: officeRequester.id
                approveBy: ArrayContains([officeRequester.id])
            }, {
                approvalAction: ApprovalAction.Consent,
                // currentStep: true,
                actionBy: IsNull(),
                consentBy: ArrayContains([officeRequester.id]),
                actionAt: IsNull(),
            }]
        })

        // const allApprovalUserId = await this.approvalFormStepRepo.getAllOfUserByAction(officeRequester.id, ApprovalAction.Approve)

        query.andWhere({ status: In([ApprovalStatus.Pending, ApprovalStatus.UnderReview]) })
        query.andWhere(new Brackets(db => {
            db.where(`1 = 2`)

            if (pendingSteps.length) db.orWhere(`qb.id IN (:...ids)`, {ids: pendingSteps.map(s => s.approvalId)})

            // if (allApprovalUserId.length) db.orWhere(`qb."formId" IN (:...formIds)`, {formIds: allApprovalUserId})
        }))
    }

    private async approvalListApproved(query: SelectQueryBuilder<OfficeApproval>, officeRequester: OfficeUser) {
        const approvedSteps = await this.approvalStepRepo.getAllStepsApprovalByRequester()
        this.setQueryForNormalApproval(query)

        query
            .andWhere(new Brackets(db => {
                db.where(`:followId = ANY(qb.followerIds)`, {followId: officeRequester.id})

                if (approvedSteps.length) db.orWhere(`qb.id IN (:...ids)`, {ids: approvedSteps.map(s => s.approvalId)})
            }))
    }

    private async approvalListNotify(query: SelectQueryBuilder<OfficeApproval>, officeRequester: OfficeUser) {
        this.setQueryForNormalApproval(query)
        query
            .andWhere({subscriberIds: ArrayContains([officeRequester.id])})
    }

    private async approvalListSubmitted(query: SelectQueryBuilder<OfficeApproval>, officeRequester: OfficeUser) {
        this.setQueryForNormalApproval(query)

        query.andWhere({createdBy: In([officeRequester.id, officeRequester.iamUserId, ...(officeRequester.iamUserUsedIds?.length ? officeRequester.iamUserUsedIds: [])])})
            .andWhere({createdBy: Not(IsNull())})
    }

    private async approvalListDraft(query: SelectQueryBuilder<OfficeApproval>, officeRequester: OfficeUser) {
        query.andWhere({status: ApprovalStatus.Draft})
            .andWhere({createdBy: In([officeRequester.id, officeRequester.iamUserId, ...(officeRequester.iamUserUsedIds?.length ? officeRequester.iamUserUsedIds: [])])})
            .andWhere({createdBy: Not(IsNull())})
    }

    private async approvalListForward(query: SelectQueryBuilder<OfficeApproval>, officeRequester: OfficeUser) {
        const userId = await RequestContext.currentId()
        query
            .leftJoinAndSelect(`qb.forward`, `forward`)
            .leftJoinAndSelect(`forward.users`, `wBridgeFwUser`)
            .leftJoinAndSelect(`wBridgeFwUser.user`, `forwardUser`)
            .andWhere({status: ApprovalStatus.Forward})
            .andWhere(new Brackets(db => {
                db.where(`forward."createdBy" = :userId`, {userId})
                    .orWhere(`"forwardUser".id = :forwardId`, {forwardId: userId})
            }))
    }

    private async approvalListNoStatus(query: SelectQueryBuilder<OfficeApproval>, officeRequester: OfficeUser) {
        //All step related to requester
        const relatedSteps = await ApprovalStep.find({
            where: [{
                approvalAction: ApprovalAction.Approve,
                // currentStep: true,
                // actionBy: IsNull(),
                // approverId: officeRequester.id
                approveBy: ArrayContains([officeRequester.id])
            }, {
                approvalAction: ApprovalAction.Consent,
                // currentStep: true,
                // actionBy: IsNull(),
                consentBy: ArrayContains([officeRequester.id])
            }]
        })

        query.andWhere(new Brackets(async (ownerQuery) => {
            ownerQuery.where(`1 = 2`)
            //thuộc line phê duyệt
            if (relatedSteps.length) ownerQuery.orWhere(new Brackets(qb => {
                qb.where(`qb.id IN (:...ids)`, {ids: relatedSteps.map(s => s.approvalId)})
                .andWhere({ status: Not(In([ApprovalStatus.Draft])) })
            }))
            // ownerQuery.orWhere(new Brackets(subQuery => {
            //     subQuery.where
            // }))

            //người ủy quyền
            // ownerQuery.orWhere(`:followId = ANY(qb.followerIds)`, {followId: officeRequester.id})
            ownerQuery.orWhere({followerIds: ArrayContains([officeRequester.id])})

            //người theo dõi
            // ownerQuery.orWhere({subscriberIds: ArrayContains([officeRequester.id])})
            ownerQuery.orWhere(new Brackets(qb => {
                qb.where({subscriberIds: ArrayContains([officeRequester.id])})
                .andWhere({ status: Not(In([ApprovalStatus.Draft])) })
            }))

            //người tạo
            ownerQuery.orWhere(new Brackets(qb => {
                qb.andWhere({createdBy: In([officeRequester.id, officeRequester.iamUserId, ...(officeRequester.iamUserUsedIds?.length ? officeRequester.iamUserUsedIds: [])])})
                .andWhere({createdBy: Not(IsNull())})
            }))
        }))
    }

    private async approvalListWithFilter(query: SelectQueryBuilder<OfficeApproval>, filter: ApprovalFilter) {
        if (filter && filter.type) {
            query.andWhere({type: filter.type})
        }

        if (filter && filter.statuses && filter.statuses.length) {
            query.andWhere({ status: In(filter.statuses) })
        }

        if (filter && filter.formIds && filter.formIds.length) {
            let hasNull = false
            const formIdList = filter.formIds.filter(fi => {
                if (fi) {
                    return true
                } else {
                    hasNull = true
                    return false
                }
            })
            console.log(`[approvalListWithFilter] hasNull: `, true)
            // query.andWhere({ formId: In(formIdList) })
            if (hasNull) {
                query.andWhere(
                    new Brackets((qb) => {
                        qb.where({ formId: In(formIdList) })
                          .orWhere('"formId" IS NULL');
                    })
                )
            } else {
                query.andWhere({ formId: In(formIdList) })
            }
        }

        if (filter.createdFrom) {
            if (filter.createdTo) {
                query.andWhere({ createdAt: Between(new Date(filter.createdFrom), new Date(filter.createdTo)) })
            } else {
                query.andWhere({ createdAt: MoreThanOrEqual(new Date(filter.createdFrom)) })
            }
        } else if (filter.createdTo) {
            query.andWhere({ createdAt: LessThanOrEqual(new Date(filter.createdTo)) })
        }

        if (filter && filter.keyword) {
            query
                .leftJoinAndMapMany('qb.field', ApprovalField, 'field', 'field."approvalId"::text = qb.id::text')
                .leftJoinAndMapMany(
                    'qb.requester',
                    OfficeUser,
                    'rq',
                    `qb."createdBy"::text = rq."id"::text OR qb."createdBy"::text = rq."iamUserId"::text OR rq."iamUserUsedIds" LIKE '%' || qb."createdBy" || '%'`
                )

            query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(qb.note)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(rq."fullname")) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(field."textValue")) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(ARRAY_TO_STRING(field."listValues", ','))) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(to_char(field."dateValue", 'dd/mm/yyyy'))) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
            }))
        }

        if (filter && filter.doneAt && (filter.doneAt.start || filter.doneAt.end)) {
            query.andWhere({
                status: In([ApprovalStatus.Approved, ApprovalStatus.Rejected])
            })
            if (filter.doneAt.start) query.andWhere(`qb."updatedAt" >= :doneAtStart`, {doneAtStart: new Date(filter.doneAt.start).toISOString()})
            if (filter.doneAt.end) query.andWhere(`qb."updatedAt" <= :doneAtEnd`, {doneAtEnd: new Date(filter.doneAt.end).toISOString()})
        }

        if (filter && filter.departmentIds && filter.departmentIds?.length) {
            query
                .leftJoinAndMapOne('qb.creator', OfficeUser, 'creator', 'creator.id::text = qb."createdBy"::text OR creator."iamUserId"::text = qb."createdBy"::text')
                .leftJoinAndMapMany('qb.departments', UserDepartment, 'd', 'd."userId" = creator.id::text')
                .leftJoinAndMapOne('qb.department', OfficeOrgChart, 'department', 'department.id::text = d."departmentId"::text')
                .andWhere(`department."id" IN (:...departmentIds)`, {departmentIds: filter.departmentIds})
        }

        if (filter && filter.creatorIds && filter.creatorIds?.length) {
            query.andWhere(`qb."createdBy" IN (:...creatorIds)`, {creatorIds: filter.creatorIds})
        }

        if (filter && filter.approvalIds && filter.approvalIds?.length) {
            query.andWhere(`EXISTS (SELECT 1
              FROM "office"."office-approval-steps" step
              WHERE step."approveBy" && '{${filter.approvalIds.join(',')}}'
                AND step."approvalId"::text = qb.id::text AND "step"."deletedAt" IS NULL)`
            )
        }

        if (filter && filter.yourAction && filter.yourAction?.length) {
            await this.getQueryFilterYourAction(query, filter.yourAction)
        }

        // console.log(query.getQueryAndParameters())
    }

    private async approvalDeleteAllRelationTable(approval: OfficeApproval) {

        await ApprovalField.delete({approvalId: approval.id})

        await ApprovalStep.delete({approvalId: approval.id})

        await ApprovalTableRow.delete({approvalId: approval.id})

        await ApprovalTableRowData.delete({approvalId: approval.id})
    }

    async updateSubscriber(args: ApprovalSubscriberUpdateInput) {
        const approval = await this.officeApprovalRepo.findOneBy({id: args.approvalId})

        // console.log('approval', approval)
        if (!approval) {
            throw OfficeError.NotFound
        }

        approval.subscriberIds = args.subscriberIds ?? []

        await approval.save()

        return approval
    }

    async approvalFilterCreate(args: ApprovalFilterCreateInput) {
        const filter = await this.filterRepo.userApprovalCreate(args)

        await filter.save()

        return filter;
    }

    async approvalFilterUpdate(args: ApprovalFilterUpdateInput) {
        const item = args.approvalFilter

        item.name = args.name ?? item.name
        item.filter = args.filter ?? item.filter

        await item.save()

        return item
    }

    async approvalFilterRemove(id: string) {
        const userId = await RequestContext.currentId()
        const filter = await this.approvalFilterGet(id)

        filter.updatedBy = userId
        await filter.save()
        await filter.softRemove()

        return filter
    }

    async approvalFilterGet(id: string) {
        const userId = await RequestContext.currentId()
        const filter = await this.filterRepo.userApprovalGetOneBy({
            id,
            relationId: userId
        })

        if (!filter) throw OfficeError.FilterUserApprovalNotFound

        return filter
    }

    async approvalMenuList() {
        const count = await this.approvalMenuCountGet()

        // const category = await this.approvalMenuCategoryGet()
        // const categoryFilter = await this.approvalFilterListByRequester()

        return {
            count,
            // categoryFilter
        };
    }

    private async approvalMenuCountGet() {
        const userId = await RequestContext.currentId()
        const submitted = await this.officeApprovalRepo.countBy({
            createdBy: userId
        })
        const draft = await this.officeApprovalRepo.countBy({
            createdBy: userId,
            status: ApprovalStatus.Draft,
        })

        const waiting = await this.countApprovalWaitingUnreadByUser()

        const approved = await this.countApprovalApprovedByUser()

        const notify = await this.countApprovalNotifyByUser()

        return {
            waiting,
            approved,
            notify,
            submitted,
            draft,
        }
    }

    private async countApprovalWaitingUnreadByUser() {
        const allWaitingQuery = await this.approvalListWaitingQuery()
        const allWaitingReadQuery = await this.approvalListWaitingReadQuery()

        const count1 = await allWaitingQuery.getCount()
        const count2 = await allWaitingReadQuery.getCount()

        return count1 - count2
    }

    private async approvalListWaitingQuery() {
        const user = await RequestContext.currentUser()
        let query = OfficeApproval.createQueryBuilder('qb')
            .where({})

        await this.approvalListWaiting(query, user)

        return query
    }

    private async approvalListWaitingReadQuery() {
        const user = await RequestContext.currentUser()
        let query = OfficeApproval.createQueryBuilder('qb')
            .where({})

        await this.approvalListWaiting(query, user)

        query
            .leftJoinAndSelect(BRIDGE_TABLE_DB.USER_READ_APPROVAL, 'wBridge', '"wBridge"."officeApprovalsId" = qb.id')
            .andWhere(`"wBridge"."officeUsersId" = :userId`, {userId: user.id})

        return query
    }

    private async countApprovalApprovedByUser() {
        const user = await RequestContext.currentUser()
        let query = OfficeApproval.createQueryBuilder('qb')
            .where({})

        await this.approvalListApproved(query, user)

        return query.getCount()
    }

    private async countApprovalNotifyByUser() {
        const allQuery = await this.approvalListNotifyQuery()
        const allReadQuery = await this.approvalListNotifyReadQuery()

        const count1 = await allQuery.getCount()
        const count2 = await allReadQuery.getCount()

        return count1 - count2
    }

    private async approvalListNotifyQuery() {
        const user = await RequestContext.currentUser()
        let query = OfficeApproval.createQueryBuilder('qb')
            .where({})

        await this.approvalListNotify(query, user)

        return query
    }

    private async approvalListNotifyReadQuery() {
        const user = await RequestContext.currentUser()
        let query = OfficeApproval.createQueryBuilder('qb')
            .where({})

        await this.approvalListNotify(query, user)

        query
            .leftJoinAndSelect(BRIDGE_TABLE_DB.USER_READ_APPROVAL, 'wBridge', '"wBridge"."officeApprovalsId" = qb.id')
            .andWhere(`"wBridge"."officeUsersId" = :userId`, {userId: user.id})

        return query
    }

    private async approvalMenuCategoryGet() {
        const filters = await this.filterRepo.userApprovalGetAllOfRequester()

        const forms = await this.approvalMenuCategorySearchGet(filters, 'formIds')
        const departments = await this.approvalMenuCategorySearchGet(filters, 'departmentIds')
        const creators = await this.approvalMenuCategorySearchGet(filters, 'creatorIds')
        const approvals = await this.approvalMenuCategorySearchGet(filters, 'approvalIds')
        const statuses = await this.approvalMenuCategorySearchGet(filters, 'statuses', 'type')

        return {
            forms,
            departments,
            creators,
            approvals,
            statuses,
        }
    }

    private async approvalMenuCategorySearchGet(fullFilters: OfficeFilter[], keyWord: string, keySearch: 'id' | 'type' = 'id') {
        if (!fullFilters.length) return null
        const filters = fullFilters.filter(i => i.filter[keyWord])

        let res: ApprovalMenuCategoryItemResponse[] = []

        for (const filter of filters) {
            const keys = filter.filter[keyWord]

            for (const key of keys) {
                if (res.filter(i => i[keySearch] === key).length) {
                    res = res.map(i => {
                        if (i[keySearch] === key) i.list.push(filter)

                        return i
                    })
                } else {
                    const data = {list: [filter]}
                    data[keySearch] = key

                    res.push(data)
                }
            }
        }

        return res
    }

    private async approvalFilterListByRequester() {
        return this.filterRepo.userApprovalGetAllOfRequester()
    }

    async approvalFilterList(filter: ApprovalFilterListFilter) {
        const [data, total] = await this.filterRepo.userApprovalListByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    private async getQueryFilterYourAction(query: SelectQueryBuilder<OfficeApproval>, yourAction: YourActionEnum[]) {
        const requesterId = await RequestContext.currentId()

        const consents = await ApprovalStep.find({
            where: {
                canAction: true,
                consentBy: ArrayContains([requesterId]),
                actionAt: IsNull()
            }
        })

        const approvals = await ApprovalStep.find({
            where: {
                currentStep: true,
                approveBy: ArrayContains([requesterId]),
                actionAt: IsNull(),
                approvalId: Not(In(consents.map(i => i.approvalId)))
            }
        })

        query
            .andWhere({
                status: In([ApprovalStatus.UnderReview, ApprovalStatus.Pending])
            })
            .andWhere(new Brackets(db => {
            db.where('0 = 1')

            if (yourAction.includes(YourActionEnum.Consent) && consents.length) {
                db.orWhere({
                    id: In(consents.map(i => i.approvalId)),
                })
            }

            if (yourAction.includes(YourActionEnum.Approve) && approvals.length) {
                db.orWhere({
                    id: In(approvals.map(i => i.approvalId)),
                })
            }

            const listNotIn = [...consents, ...approvals].length ? [...consents, ...approvals].map(i => i.approvalId) : []
            if (yourAction.includes(YourActionEnum.Waiting) && listNotIn.length) {
                db.orWhere({
                    id: Not(In(listNotIn)),
                })
            }
        }))
    }

    private defaultZeroApprovalRecord() {
        return {
            total: 0,
            count: 0,
            approvals: []
        }
    }

    private async blankApprovalStepCreate(args: ApprovalArgs, steps: ApprovalStep[], approval: OfficeApproval) {
        const requester = await RequestContext.currentUser()
        let canAutoApproval = true
        for (let i = 0; i < args.structure.steps.length; i++) {
            const element = args.structure.steps[i];
            const step = ApprovalStep.create({
                id: RandomHelper.generateUUID(),
                approvalAction: element.action,
                order: (steps.length + 1),
                createdBy: requester.id,
                updatedBy: requester.id,
                approvalId: approval.id,
                currentStep: false,
            })

            let actionByList = []
            let actionType
            if (step.approvalAction === ApprovalAction.Approve) {
                const approvers = await OfficeUser.find({
                    where: {id: In(element.approveBy)}
                })
                if (approvers.length === 0) throw OfficeError.FormApproverNotFound
                step.approveBy = approvers.map(a => a.id)

                actionByList = step.approveBy
                actionType = ApprovalProcessAction.Approve

            } else if (step.approvalAction === ApprovalAction.Consent) {
                const consentBy = await OfficeUser.find({
                    where: {id: In(element.consentBy)}
                })
                if (consentBy.length === 0) throw OfficeError.FormConsentByNotFound

                step.consentBy = consentBy.map(c => c.id)

                actionByList = step.consentBy
                actionType = ApprovalProcessAction.Consent
            }

            if (canAutoApproval && actionByList.includes(requester.id)) {
                step.action = actionType
                step.actionAt = new Date()
                step.actionBy = requester.id
                step.currentStep = false
            } else {
                canAutoApproval = false
            }

            steps.push(step)
        }

        if (canAutoApproval) {
            approval.status = ApprovalStatus.Approved
        }
    }

    async onOff(id: string) {
        const form = await this.approvalFormRepo.getOneBy({id})

        if (!form) {
            throw OfficeError.ApprovalFormNotFound
        }

        form.status = (form.status === ObjectStatus.Active) ? ObjectStatus.Inactive : ObjectStatus.Active

        await form.save()

        return form;
    }

    async recallById(id: string) {
        const approval = await this.officeApprovalRepo.findOne({
            where: {id}
        })

        approval.status = ApprovalStatus.Recalled

        await approval.save()
    }

    async removeById(id: string) {
        const approval = await this.officeApprovalRepo.findOne({
            where: {id}
        })

        approval.status = ApprovalStatus.Recalled
        approval.updatedBy = await  RequestContext.currentId()

        await approval.save()
        await approval.softRemove()
    }

    async updateApproveStep(args: ApprovalApproveStepUpdateInput) {
        const approval = args.approval
        const newSteps = args.newSteps
        const inactionOldSteps = await this.approvalStepRepo.getAllInactionStepByApprovalId(approval.id)
        const currentStepNumber = inactionOldSteps[0].order
        const user = await RequestContext.currentUser()

        await this.approvalStepRepo.softRemove(inactionOldSteps)

        let order = currentStepNumber
        let currentStep = true
        const inactionNewSteps: ApprovalStep[] = []
        for (const step of newSteps) {
            const record = this.approvalStepRepo.create({
                approveBy: step.approveBy,
                consentBy: step.consentBy,
                approvalAction: step.action,
                order,
                createdBy: user.id,
                updatedBy: user.id,
                approvalId: approval.id,
                currentStep: currentStep && step.action === ApprovalAction.Approve
            })

            await record.save()
            inactionNewSteps.push(record)

            if (step.action === ApprovalAction.Approve) currentStep = false
            order++;
        }

        await this.updateApprovalStepHistoryStore(approval, {
            newSteps: inactionNewSteps,
            oldSteps: inactionOldSteps,
            note: args.note,
            approval
        })

        await approval.reload()

        return approval
    }

    async updateApprovalAction(args: ApprovalActionArgs) {
        const approval = await OfficeApproval.findOne({
            where: { id: args.id, status: In([ApprovalStatus.UnderReview, ApprovalStatus.Pending]) }
        })
        if (!approval) throw OfficeError.ApprovalNotFound
        const now = new Date()
        const latestActionStep =  await ApprovalStep.findOne({
            where: {
                approvalId: approval.id,
                action: Not(IsNull())
            },
            order: {
                order: 'DESC'
            }
        })
        let step: ApprovalStep
        switch (args.action) {
            case ApprovalProcessAction.Cancel:
                step = await this.updateApprovalActionCancel(args, approval, latestActionStep, now)
                break
            case ApprovalProcessAction.Comment:
                step = await this.updateApprovalActionComment(args, approval, latestActionStep, now)
                break
            case ApprovalProcessAction.Grant:
                step = await this.updateApprovalActionGrant(args, approval, latestActionStep, now)
                break
            case ApprovalProcessAction.Consent:
                step = await this.updateApprovalActionConsent(args, approval, latestActionStep, now)
                break
            case ApprovalProcessAction.Reject:
                step = await this.updateApprovalActionReject(args, approval, latestActionStep, now)
                break
            case ApprovalProcessAction.Pending:
                step = await this.updateApprovalActionPending(args, approval, latestActionStep, now)
                break
            case ApprovalProcessAction.Approve:
                step = await this.updateApprovalActionApprove(args, approval, latestActionStep, now)
                break
        }

        await this.updateApprovalActionAttachmentAdd(args, step)
        await step.save()

        await approval.save()

        return step
    }

    async updateApprovalActionOld(args: ApprovalActionArgs) {
        const token = RequestContext.currentToken()
        const officeRequester = await RequestContext.currentUser()
        const approval = await OfficeApproval.findOne({
            where: { id: args.id, status: In([ApprovalStatus.UnderReview, ApprovalStatus.Pending]) }
        })
        if (!approval) throw OfficeError.ApprovalNotFound
        const now = new Date()
        let step = await ApprovalStep.findOne({
            where: {
                approvalId: approval.id,
                currentStep: true
            }
        })
        const currentStepOrder = step.order
        var nextStep = null
        var skipConsent = false
        let grantStep: ApprovalStep = null
        let approvalRows: ApprovalTableRow[] = []
        let userHaveRequestApprovalIds = []
        switch (args.action) {
            case ApprovalProcessAction.Cancel:
                if (![officeRequester.id, officeRequester.iamUserId, ...(officeRequester.iamUserUsedIds?.length ? officeRequester.iamUserUsedIds: [])].includes(approval.createdBy)) throw OfficeError.ApprovalNotFound
                step = ApprovalStep.create({
                    id: RandomHelper.generateUUID(),
                    createdBy: officeRequester.id,
                    updatedBy: officeRequester.id,
                    approvalId: approval.id,
                    action: args.action,
                    comment: args.comment,
                    actionBy: officeRequester.id,
                    actionAt: now
                })

                approval.status = ApprovalStatus.Recalled
                approval.updatedBy = officeRequester.id
                break
            case ApprovalProcessAction.Comment:
                step = ApprovalStep.create({
                    id: RandomHelper.generateUUID(),
                    createdBy: officeRequester.id,
                    updatedBy: officeRequester.id,
                    approvalId: approval.id,
                    action: args.action,
                    comment: args.comment,
                    actionBy: officeRequester.id,
                    actionAt: now,
                    order: currentStepOrder
                })

                approval.updatedBy = officeRequester.id
                break
            case ApprovalProcessAction.Grant:
                let grantTo = args.grantTo

                if (args.grantToType === GrantType.Department) {
                    grantTo = await this.getDepartmentApprovalId(grantTo)

                    if (!grantTo) {
                        throw OfficeError.DepartmentNotHaveManager
                    }
                }

                const grantStep = await ApprovalStep.findOne({
                    where: {
                        approvalId: approval.id,
                        id: args.grantStepId
                    }
                })
                if (grantStep.approveBy && grantStep.approveBy.includes(officeRequester.id)) {
                    grantStep.approveBy = grantStep.approveBy.map(a => {
                        if (a === officeRequester.id) {
                            return grantTo
                        } else {
                            return a
                        }
                    })
                    if (args.grantToType === GrantType.Department) grantStep.departmentId = args.grantTo
                    userHaveRequestApprovalIds.push(grantTo)
                    grantStep.currentStep = true
                    grantStep.order += 1
                    nextStep = grantStep.order
                } else {
                    throw OfficeError.ActionNotAllowed()
                }

                step = ApprovalStep.create({
                    id: RandomHelper.generateUUID(),
                    createdBy: officeRequester.id,
                    updatedBy: officeRequester.id,
                    approvalId: approval.id,
                    action: args.action,
                    comment: args.comment,
                    grantFrom: officeRequester.id,
                    grantTo: args.grantTo,
                    grantToType: args.grantToType,
                    actionBy: officeRequester.id,
                    actionAt: now,
                    order: currentStepOrder
                })

                approval.followerIds = approval.followerIds ? [...new Set([step.grantFrom, ...approval.followerIds])] : [step.grantFrom]
                approval.updatedBy = officeRequester.id

                break
            case ApprovalProcessAction.Consent:
                if (
                    !step.consentBy.filter(i => [officeRequester.id, officeRequester.iamUserId, ...(officeRequester.iamUserUsedIds?.length ? officeRequester.iamUserUsedIds: [])].includes(i)).length
                    || step.approvalAction !== ApprovalAction.Consent
                ) throw OfficeError.ApprovalNotFound

                step.updatedBy = officeRequester.id
                step.action = args.action
                step.comment = args.comment
                step.actionBy = officeRequester.id
                step.actionAt = now
                // step.currentStep = false
                nextStep = step.order + 1

                approval.updatedBy = officeRequester.id
                break
            case ApprovalProcessAction.Reject:
                step = await ApprovalStep.findOne({
                    where: {
                        approvalId: approval.id,
                        approvalAction: ApprovalAction.Approve,
                        order: MoreThanOrEqual(step.order)
                    },
                    order: {
                        order: "ASC"
                    }
                })
                if (!step.approveBy.includes(officeRequester.id)) throw OfficeError.ApprovalNotFound

                step.updatedBy = officeRequester.id
                step.action = args.action
                step.comment = args.comment
                step.actionBy = officeRequester.id
                step.actionAt = now
                // step.currentStep = false
                // nextStep = step.order + 1

                approval.status = ApprovalStatus.Rejected
                approval.updatedBy = officeRequester.id
                skipConsent = true
                break
            case ApprovalProcessAction.Pending:
                step = await ApprovalStep.findOne({
                    where: {
                        approvalId: approval.id,
                        approvalAction: ApprovalAction.Approve,
                        order: MoreThanOrEqual(step.order)
                    },
                    order: {
                        order: "ASC"
                    }
                })
                if (!step.approveBy.filter(i => [officeRequester.id, officeRequester.iamUserId, ...(officeRequester.iamUserUsedIds?.length ? officeRequester.iamUserUsedIds: [])].includes(i)).length) throw OfficeError.ApprovalNotFound

                step = ApprovalStep.create({
                    id: RandomHelper.generateUUID(),
                    createdBy: officeRequester.id,
                    updatedBy: officeRequester.id,
                    approvalId: approval.id,
                    action: args.action,
                    comment: args.comment,
                    actionBy: officeRequester.id,
                    actionAt: now,
                    order: currentStepOrder
                })

                approval.updatedBy = officeRequester.id
                approval.status = ApprovalStatus.Pending
                break
            case ApprovalProcessAction.Approve:
                step = await ApprovalStep.findOne({
                    where: {
                        approvalId: approval.id,
                        approvalAction: ApprovalAction.Approve,
                        order: MoreThanOrEqual(step.order)
                    },
                    order: {
                        order: "ASC"
                    }
                })
                if (!step.approveBy.filter(i => [officeRequester.id, officeRequester.iamUserId, ...(officeRequester.iamUserUsedIds?.length ? officeRequester.iamUserUsedIds: [])].includes(i)).length) throw OfficeError.ApprovalNotFound

                const lastestApproveStep = await ApprovalStep.findOne({
                    where: {
                        approvalId: approval.id,
                        approvalAction: ApprovalAction.Approve,
                        order: Not(IsNull())
                    },
                    order: {
                        order: "DESC"
                    }
                })

                step.updatedBy = officeRequester.id
                step.action = args.action
                step.comment = args.comment
                step.actionBy = officeRequester.id
                step.actionAt = now
                approval.status = ApprovalStatus.UnderReview
                if (lastestApproveStep.id !== step.id) {
                    // step.currentStep = false
                    nextStep = step.order + 1
                } else {
                    approval.status = ApprovalStatus.Approved
                }

                approval.updatedBy = officeRequester.id
                skipConsent = true

                if (approval.type === ApprovalType.OfficeShopping && args.approvalRowIds) {
                    approvalRows = await ApprovalTableRow.find({
                        where: {
                            // id: In(args.approvalRowIds),
                            approvalId: approval.id
                        }
                    })

                    for (const row of approvalRows) {
                        if (args.approvalRowIds.includes(row.id)) {
                            row.status = TableRowStatus.Approved
                            step.approvalRowIds = step.approvalRowIds ? [...step.approvalRowIds, row.id] : [row.id]
                        } else {
                            row.status = TableRowStatus.Rejected
                        }
                        row.actionAt = now
                        row.actionBy = officeRequester.id
                        row.actionStepId = step.id
                    }
                }
                break
        }
        step.currentStep = false
        if (args.imageIds) {
            for (const imageId of args.imageIds) {
                const { data, error } = await this.storageService.getFileDetail(token, imageId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted
                if (step.imageIds) {
                    step.imageIds.push(imageId)
                } else {
                    step.imageIds = [imageId]
                }
                if (step.imageUrls) {
                    step.imageUrls.push(data.location)
                } else {
                    step.imageUrls = [data.location]
                }
            }
        }
        if (args.attachmentIds) {
            for (const attachmentId of args.attachmentIds) {
                const { data, error } = await this.storageService.getFileDetail(token, attachmentId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted
                if (step.attachmentIds) {
                    step.attachmentIds.push(attachmentId)
                } else {
                    step.attachmentIds = [attachmentId]
                }
                if (step.attachmentUrls) {
                    step.attachmentUrls.push(data.location)
                } else {
                    step.attachmentUrls = [data.location]
                }
            }
        }

        if (skipConsent === true) await ApprovalStep.update({ approvalId: approval.id, actionAt: IsNull(), order: LessThan(step.order) }, { actionAt: now, currentStep: false })
        await approval.save()
        if (approvalRows.length > 0) await ApprovalTableRow.save(approvalRows)
        if (grantStep) await grantStep.save()
        await step.save()

        if (nextStep) {
            await ApprovalStep.update({ approvalId: approval.id, order: Not(nextStep) }, { currentStep: false })
            await ApprovalStep.update({ approvalId: approval.id, order: nextStep }, { currentStep: true })
        }

        return step
    }

    private async getDepartmentApprovalId(grantTo: string) {
        const oog = await this.officeOrgChartRepo.findOneBy({id: grantTo});

        if (!oog) {
            throw OfficeError.DepartmentNotExist
        }

        return oog.approverId
    }

    private async updateApprovalStepHistoryStore(approval: OfficeApproval, args: {
        note: string;
        newSteps: ApprovalStep[];
        oldSteps: ApprovalStep[];
        approval: OfficeApproval
    }) {
        const {note, newSteps, oldSteps} = args
        const passSteps = await this.approvalStepRepo.getAllActionStepByApprovalId(approval.id)
        const passStepValue = await this.mapStepDataToStoreLog(passSteps)

        console.log('passStepValue', passStepValue)

        const log: OfficeLogHistoryArgs = {
            featureLogType: OfficeFeatureLogType.Approval,
            featureLogId: approval.id,
            logs: [
                {
                    action: LogAction.Update,
                    actionAt: new Date().getTime(),
                    field: 'pipe_approve',
                    oldValue: [...passStepValue, ...(await this.mapStepDataToStoreLog(oldSteps))],
                    newValue: [...passStepValue, ...(await this.mapStepDataToStoreLog(newSteps))],
                    note
                }
            ]
        }

        await this.logService.historyCreate(log)
    }

    private async mapStepDataToStoreLog(steps: ApprovalStep[]) {
        const res = []
        for (const step of steps) {
            const approveUsers = await this.officeUserRepo.getManyWithDepartmentByIds(step.approveBy)
            const consentUsers = await this.officeUserRepo.getManyWithDepartmentByIds(step.consentBy)
            const actionUsers = await this.officeUserRepo.getManyWithDepartmentByIds([step.actionBy])

            res.push({
                id: step.id,
                order: step.order,
                approveBy: step.approveBy,
                approveByUsers: approveUsers ? approveUsers.map(i => this.getLogDataForUser(i)) : [],
                consentBy: step.consentBy,
                consentByUser: consentUsers ? consentUsers.map(i => this.getLogDataForUser(i)) : [],
                approvalAction: step.approvalAction,
                action: step.action,
                actionBy: step.actionBy,
                actionByUser: actionUsers.length ? this.getLogDataForUser(actionUsers[0]) : null,
            })
        }

        return res
    }

    getLogDataForUser(user: any) {
        return {
            code: user.code,
            fullname: user.fullname,
            phone: user.phone,
            departmentName: user?.department?.name,
            titleName: user?.title?.name,
            optionTitle: `${user.code} - ${user.fullname} - ${user?.department?.name ?? 'Chưa có phòng ban'} - ${user?.title?.name ?? 'Chưa có chức danh'}`
        }
    }

    private async approvalForwardSetData(approval: OfficeApproval, forwardData: ApprovalForwardDataInput) {
        const {originApproval} = forwardData

        await this.approvalForwardSetApprovalData(approval, originApproval)

        await this.approvalForwardSetStepData(approval, originApproval)

        await this.approvalForwardSetLogData(approval, originApproval)

        await this.approvalForwardSetForwardData(approval, forwardData)
    }

    private isNotForwardData(submitType: ApprovalSubmitTypeEnum) {
        return submitType !== ApprovalSubmitTypeEnum.Forward;
    }

    private setQueryForNormalApproval(query: SelectQueryBuilder<OfficeApproval>) {
        query
            .andWhere({status: Not(In([ApprovalStatus.Draft, ApprovalStatus.Forward]))})
    }

    private async approvalForwardSetForwardData(approval: OfficeApproval, forwardData: ApprovalForwardDataInput) {
        const {originApproval, forwardUserData, note} = forwardData
        const requestUser = await RequestContext.currentId()

        const forward = this.approvalForwardRepo.create({
            note,
            approval,
            originApproval,
            createdBy: requestUser
        })

        await forward.save()
        await forward.reload()

        for (const item of forwardUserData) {
            const forwardUser = this.approvalForwardUserRepo.create({
                showItems: item.showItems,
                createdBy: requestUser,
                forward,
                user: item.user
            })

            await forwardUser.save()
        }
    }

    private async approvalForwardSetApprovalData(approval: OfficeApproval, originApproval: OfficeApproval) {
        approval.type = originApproval.type
    }

    private async approvalForwardSetStepData(approval: OfficeApproval, originApproval: OfficeApproval) {
        const steps = await this.approvalStepRepo.getAllStepByApprovalId(originApproval.id)
        const forwardSteps = await this.officeApprovalRepo.cloneRelation(steps, approval, 'approvalId')
        await this.approvalStepRepo.save(forwardSteps)
    }

    private async approvalForwardSetLogData(approval: OfficeApproval, originApproval: OfficeApproval) {
        const logs = await this.logRepo.getAllByRelationId(originApproval.id, ['userCreator', 'adminCreator', 'orgCharts'])
        let forwardLogs = await this.officeApprovalRepo.cloneRelation(logs, approval, 'featureLogId')

        forwardLogs = forwardLogs.map(i => ({
            ...i,
            objectType: i['objectType'] ? JSON.stringify(i['objectType']) : null,
            logs: i['logs'] ? JSON.stringify(i['logs']) : null
        }))

        await this.logRepo.save(forwardLogs)
    }

    async updateApprovalActionCancel(args: ApprovalActionArgs, approval: OfficeApproval, latestActionStep: ApprovalStep, now: Date) {
        const officeRequester = await RequestContext.currentUser()

        if (![officeRequester.id, officeRequester.iamUserId, ...(officeRequester.iamUserUsedIds?.length ? officeRequester.iamUserUsedIds: [])].includes(approval.createdBy)) throw OfficeError.NotAllow

        const step = ApprovalStep.create({
            id: RandomHelper.generateUUID(),
            createdBy: officeRequester.id,
            updatedBy: officeRequester.id,
            approvalId: approval.id,
            action: args.action,
            comment: args.comment,
            actionBy: officeRequester.id,
            actionAt: now,
            order: latestActionStep.order + 1,
        })

        await step.save()

        approval.status = ApprovalStatus.Recalled
        approval.updatedBy = officeRequester.id

        return step
    }

    async updateApprovalActionComment(args: ApprovalActionArgs, approval: OfficeApproval, latestActionStep: ApprovalStep, now: Date) {
        const officeRequester = await RequestContext.currentUser()

        const step = ApprovalStep.create({
            id: RandomHelper.generateUUID(),
            createdBy: officeRequester.id,
            updatedBy: officeRequester.id,
            approvalId: approval.id,
            action: args.action,
            comment: args.comment,
            actionBy: officeRequester.id,
            actionAt: now,
            order: latestActionStep.order + 1,
        })

        await step.save()

        approval.updatedBy = officeRequester.id

        return step
    }

    async updateApprovalActionGrant(args: ApprovalActionArgs, approval: OfficeApproval, latestActionStep: ApprovalStep, now: Date) {
        const officeRequester = await RequestContext.currentUser()
        let grantTo = args.grantTo

        if (args.grantStepId && args.grantTo) {
            if (args.grantToType === GrantType.Department) {
                grantTo = await this.getDepartmentApprovalId(grantTo)

                if (!grantTo) {
                    throw OfficeError.DepartmentNotHaveManager
                }

                if (grantTo === officeRequester.id) {
                    throw OfficeError.YouIsManagerOfDepartment
                }
            }

            /*update current step*/
            const approvalStep = await ApprovalStep.findOne({
                where: {
                    approvalId: approval.id,
                    id: args.grantStepId
                }
            })

            if (!approvalStep.approveBy.includes(officeRequester.id)) {
                throw OfficeError.ActionNotAllowed()
            }
            approvalStep.approveBy = [...approvalStep.approveBy, grantTo].filter(i => i !== officeRequester.id)
            await approvalStep.save()

            /*create new step*/
            const grantStep = this.approvalStepRepo.create({
                createdBy: officeRequester.id,
                updatedBy: officeRequester.id,
                approvalId: approval.id,
                action: args.action,
                comment: args.comment,
                grantFrom: officeRequester.id,
                grantTo: args.grantTo,
                grantToType: args.grantToType,
                actionBy: officeRequester.id,
                actionAt: now,
                order: latestActionStep.order + 1,
            })

            await grantStep.save()

            /*update approval*/
            approval.followerIds = approval.followerIds ? [...new Set([grantStep.grantFrom, ...approval.followerIds])] : [grantStep.grantFrom]
            approval.updatedBy = officeRequester.id

            return grantStep
        }
    }

    async updateApprovalActionConsent(args: ApprovalActionArgs, approval: OfficeApproval, latestActionStep: ApprovalStep, now: Date) {
        const officeRequester = await RequestContext.currentUser()
        const step = await ApprovalStep.findOne({
            where: {
                approvalId: approval.id,
                canAction: true,
                approvalAction: ApprovalAction.Consent
            },
            order: {
                order: 'ASC'
            }
        })

        if (
            !step.consentBy.filter(i => [officeRequester.id, officeRequester.iamUserId, ...(officeRequester.iamUserUsedIds?.length ? officeRequester.iamUserUsedIds: [])].includes(i)).length
            || step.approvalAction !== ApprovalAction.Consent
        ) throw OfficeError.ApprovalNotFound

        step.updatedBy = officeRequester.id
        step.action = args.action
        step.comment = args.comment
        step.actionBy = officeRequester.id
        step.actionAt = now
        step.canAction = false

        await step.save()

        approval.updatedBy = officeRequester.id

        return step
    }

    private async updateApprovalActionReject(args: ApprovalActionArgs, approval: OfficeApproval, latestActionStep: ApprovalStep, now: Date) {
        const officeRequester = await RequestContext.currentUser()
        const step = await this.getApprovalStepCurrent(approval)

        await this.checkUserCanApproveStep(step, officeRequester)

        step.updatedBy = officeRequester.id
        step.action = args.action
        step.comment = args.comment
        step.actionBy = officeRequester.id
        step.actionAt = now
        step.currentStep = false
        step.canAction = false

        await step.save()

        approval.status = ApprovalStatus.Rejected
        approval.updatedBy = officeRequester.id

        return step
    }

    private async updateApprovalActionPending(args: ApprovalActionArgs, approval: OfficeApproval, latestActionStep: ApprovalStep, now: Date) {
        const officeRequester = await RequestContext.currentUser()

        const approvalStep = await this.getApprovalStepCurrent(approval)

        await this.checkUserCanApproveStep(approvalStep, officeRequester)

        const step = ApprovalStep.create({
            id: RandomHelper.generateUUID(),
            createdBy: officeRequester.id,
            updatedBy: officeRequester.id,
            approvalId: approval.id,
            action: args.action,
            comment: args.comment,
            actionBy: officeRequester.id,
            actionAt: now,
            order: latestActionStep.order + 1
        })

        await step.save()

        approval.updatedBy = officeRequester.id
        approval.status = ApprovalStatus.Pending

        return step
    }

    private async updateApprovalActionApprove(args: ApprovalActionArgs, approval: OfficeApproval, latestActionStep: ApprovalStep, now: Date) {
        const officeRequester = await RequestContext.currentUser()
        const approvalStep = await this.getApprovalStepCurrent(approval)

        await this.checkUserCanApproveStep(approvalStep, officeRequester)

        /*update passed consent step*/
        await ApprovalStep.update(
            {
                approvalId: approval.id,
                order: LessThan(approvalStep.order),
                approvalAction: ApprovalAction.Consent,
            },
            {
                canAction: false,
                actionAt: now,
                actionBy: officeRequester.id
            })

        /*update approval step*/
        approvalStep.updatedBy = officeRequester.id
        approvalStep.action = args.action
        approvalStep.comment = args.comment
        approvalStep.actionBy = officeRequester.id
        approvalStep.actionAt = now
        approvalStep.canAction = false
        approvalStep.currentStep = false

        await approvalStep.save()

        /*update approval*/
        const currentStep = await this.approvalStepRepo.getCurrentStepByApprovalId(approval.id)

        approval.status = currentStep ? ApprovalStatus.UnderReview : ApprovalStatus.Approved
        approval.updatedBy = officeRequester.id

        return approvalStep
    }

    private getApprovalStepCurrent(approval: OfficeApproval) {
        return ApprovalStep.findOne({
            where: {
                approvalId: approval.id,
                approvalAction: ApprovalAction.Approve,
                currentStep: true
            }
        })
    }

    private async checkUserCanApproveStep(approvalStep: ApprovalStep, officeRequester: OfficeUser) {
        if (!approvalStep.approveBy.filter(i => [officeRequester.id, officeRequester.iamUserId, ...(officeRequester.iamUserUsedIds?.length ? officeRequester.iamUserUsedIds: [])].includes(i)).length) {
            throw OfficeError.NotAllow
        }
    }

    private async updateApprovalActionAttachmentAdd(args: ApprovalActionArgs, step: ApprovalStep) {
        const token = RequestContext.currentToken()

        if (args.imageIds) {
            for (const imageId of args.imageIds) {
                const { data, error } = await this.storageService.getFileDetail(token, imageId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted
                if (step.imageIds) {
                    step.imageIds.push(imageId)
                } else {
                    step.imageIds = [imageId]
                }
                if (step.imageUrls) {
                    step.imageUrls.push(data.location)
                } else {
                    step.imageUrls = [data.location]
                }
            }
        }
        if (args.attachmentIds) {
            for (const attachmentId of args.attachmentIds) {
                const { data, error } = await this.storageService.getFileDetail(token, attachmentId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted
                if (step.attachmentIds) {
                    step.attachmentIds.push(attachmentId)
                } else {
                    step.attachmentIds = [attachmentId]
                }
                if (step.attachmentUrls) {
                    step.attachmentUrls.push(data.location)
                } else {
                    step.attachmentUrls = [data.location]
                }
            }
        }
    }

    async approvalCopyToDraftCreate(id: string, relationId: string | undefined) {
        const approvalOrigin = await this.officeApprovalRepo.justOneBy({id})

        if (!approvalOrigin) return null

        const user = await RequestContext.currentUser()

        const approvalCopy = this.officeApprovalRepo.create(structuredClone(approvalOrigin))

        delete approvalCopy.id
        delete approvalCopy.no
        delete approvalCopy.code
        delete approvalCopy.createdAt
        delete approvalCopy.updatedAt
        delete approvalCopy.updatedBy

        approvalCopy.status = ApprovalStatus.Draft
        approvalCopy.createdBy = user.id
        approvalCopy.readBy = null
        approvalCopy.forward = null
        approvalCopy.relationId = relationId ?? null

        await approvalCopy.save()

        await this.copyApprovalField(approvalOrigin, approvalCopy.id)
        await this.copyApprovalStep(approvalOrigin, approvalCopy.id)

        return approvalCopy
    }

    async getOfVersionWikiId(id: string | undefined) {
        return this.officeApprovalRepo.getBy({
            type: ApprovalType.WikiRelease,
            relationId: id
        })
    }

    async copyApprovalByVersionId(id: string, newId: string) {
        const approvalOrigin = await this.officeApprovalRepo.justOneBy({relationId: id})

        if (!approvalOrigin) return null

        const user = await RequestContext.currentUser()

        const approvalCopy = this.officeApprovalRepo.create(structuredClone(approvalOrigin))

        delete approvalCopy.id
        delete approvalCopy.no
        delete approvalCopy.code
        delete approvalCopy.createdAt
        delete approvalCopy.updatedAt
        delete approvalCopy.updatedBy

        approvalCopy.status = ApprovalStatus.UnderReview
        approvalCopy.createdBy = user.id
        approvalCopy.readBy = null
        approvalCopy.forward = null
        approvalCopy.relationId = newId ?? null

        await this.officeApprovalRepo.save(approvalCopy)

        await this.copyApprovalField(approvalOrigin, approvalCopy.id)
        await this.copyApprovalStep(approvalOrigin, approvalCopy.id)

        return approvalCopy
    }

    private async copyApprovalField(approvalOrigin: OfficeApproval, newId: string) {
        const fields = await ApprovalField.find({
            where: { approvalId: approvalOrigin.id}
        })

        const user = await RequestContext.currentUser()

        for (const field of fields) {
            const fieldCopy = ApprovalField.create(structuredClone(field))

            delete fieldCopy.id
            delete fieldCopy.createdAt
            delete fieldCopy.updatedAt
            delete fieldCopy.updatedBy

            fieldCopy.createdBy = user.id
            fieldCopy.approvalId = newId

            await fieldCopy.save()
        }
    }

    private async copyApprovalStep(approvalOrigin: OfficeApproval, newId: string) {
        const steps = await ApprovalStep.find({
            where: { approvalId: approvalOrigin.id}
        })

        const user = await RequestContext.currentUser()

        let count = 1
        for (const step of steps) {
            if (!(step.approvalAction || step.action === ApprovalProcessAction.Submit)) continue
            const stepCopy = ApprovalStep.create(structuredClone(step))

            delete stepCopy.id
            delete stepCopy.createdAt
            delete stepCopy.updatedAt
            delete stepCopy.updatedBy
            if (stepCopy.action !== ApprovalProcessAction.Submit) {
                delete stepCopy.action
                delete stepCopy.actionAt
                delete stepCopy.actionBy
            } else {
                stepCopy.actionAt = new Date()
                stepCopy.actionBy = user.id
            }

            stepCopy.createdBy = user.id
            stepCopy.approvalId = newId
            stepCopy.order = count

            await stepCopy.save()

            count++
        }
    }
}