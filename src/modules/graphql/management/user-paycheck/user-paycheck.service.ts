import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { OfficeUserPaycheckRepo } from "@repositories/payroll/office-user-paycheck.repo";
import {
    UserPaycheckBulkUpsertInput, UserPaycheckCommentCreate,
    UserPaycheckCreateInput, UserPaycheckListFilter,
    UserPaycheckUpdateInput
} from "@modules/graphql/management/user-paycheck/dto/user-paycheck.args";
import { OfficeError, OfficeErrorMessage } from "@common/office.error";
import { OfficeUserRepo } from "@repositories/profile.user.repo";
import { PayrollService } from "@modules/graphql/management/payroll/payroll.service";
import { In, IsNull, Not } from "typeorm";
import { UserPaycheckBulkResponse } from "@modules/graphql/management/user-paycheck/dto/user-paycheck.response";
import { OfficeInfoFieldRepo } from "@repositories/office-info-field.repo";
import { OfficeInfoBlockRepo } from "@repositories/office-info-block.repo";
import { DataType } from "@models/entities/profile.info.field";
import { validateDateFormat, validateEmail, validatePhoneNumber } from "@common/regex";
import { OfficeSuccessMessage } from "@common/office.success";
import { dayMonthYearToTime } from "@utils/datetime.utils";
import { NotificationService } from "@core/iam/notification/notification.service";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { RequestContext } from "@common/context/request.context";
import { OfficeUserPaycheck } from "@models/entities";
import { LogService } from "@modules/graphql/log/log.service";
import { OfficeFeatureLogType } from "@enum/logs/logs.enum";
import { OfficeLogCommentArgs } from "@modules/graphql/log/dto/log.args";

@Injectable()
export class UserPaycheckService {
    constructor(
        private officeUserPaycheckRepo: OfficeUserPaycheckRepo,
        private officeUserRepo: OfficeUserRepo,
        private officeInfoBlockRepo: OfficeInfoBlockRepo,
        private officeInfoFieldRepo: OfficeInfoFieldRepo,
        private readonly payrollService: PayrollService,
        private readonly logService: LogService,
    ) {
    }

    private async validateExistUserPaycheckDate(args: UserPaycheckCreateInput | UserPaycheckUpdateInput | UserPaycheckBulkUpsertInput, idExclude: string = null) {
        let whereUser = {}
        let whereExclude = {}
        if ('userId' in args) {
            whereUser = {
                id: args.userId ? args.userId : Not(IsNull())
            }
            whereExclude = {
                id: Not(idExclude ?? IsNull())
            }
        }

        console.log('args.userCode', args)
        console.log('asd', 'userId' in args, 'userCode' in args)

        if ('userCode' in args) {
            whereUser = {
                code: args.userCode
            }
            whereExclude = {
                code: Not(idExclude ?? IsNull())
            }
        }
        let whereToFind = {
            user: whereUser,
            ...whereExclude
        }

        if (args.name) whereToFind['name'] = args.name.trim()
        if (args.month) whereToFind['month'] = args.month
        if (args.year) whereToFind['year'] = args.year

        if (await this.officeUserPaycheckRepo.findOne({
            relations: ['user'],
            where: whereToFind
        })) {
            console.log('whereToFind', whereToFind)
            throw OfficeError.UserPaycheckExistInDate
        }
    }

    private async validateUpdateUserPaycheckDate(args: UserPaycheckUpdateInput) {
        const paycheck = await this.officeUserPaycheckRepo.findOneBy({id: args.id})

        if (!paycheck) {
            throw OfficeError.UserPaycheckNotExist
        }

        if (await this.officeUserPaycheckRepo.findOne({
            where: {
                id: Not(paycheck.id),
                user: {
                    id: args.userId ?? paycheck.user.id
                },
                name: args.name ?? paycheck.name,
                month: args.month ?? paycheck.month,
                year: args.year ?? paycheck.year,
            }
        })) {
            console.log('here')
            throw OfficeError.UserPaycheckExistInDate
        }
    }

    private async validateAndGetExistUser(id: string) {
        const user = await this.officeUserRepo.findOneBy({id})
        if (!user) {
            throw OfficeError.SysUserNotExisted
        }

        return user
    }

    private async validateAndGetExistUserBy(expect: object) {
        const user = await this.officeUserRepo.findOneBy(expect)
        if (!user) {
            throw OfficeError.SysUserNotExisted
        }

        return user
    }

    private async validateAndGetExistUserPaycheck(id: string, byCode: boolean = false) {
        let user

        if (byCode) {
            user = await this.officeUserPaycheckRepo.findOneBy({code: id})
        } else {
            user = await this.officeUserPaycheckRepo.findOneBy({id})
        }

        if (!user) {
            throw OfficeError.UserPaycheckNotExist
        }

        return user
    }

    async create(requesterId: string, args: UserPaycheckCreateInput, token: string) {
        await this.validateExistUserPaycheckDate(args)

        const user = await this.validateAndGetExistUser(args.userId)
        const departmentId = await this.officeUserRepo.getDepartmentIdBy({id: user.id})
        const payroll = await this.payrollService.validateAndGetExistPayroll(args.payrollId)

        if (!payroll.orgCharts.map(i => i.id).includes(departmentId)) {
            throw OfficeError.UserNotHavePayroll
        }

        const userPaycheckData = structuredClone(args)
        delete userPaycheckData.userId
        delete userPaycheckData.payrollId

        const userPaycheck = this.officeUserPaycheckRepo.create({
            ...userPaycheckData,
            wage: userPaycheckData.wage.toString(),
            metadata: [JSON.stringify(args.metadata)],
            createdBy: requesterId,
            updatedBy: requesterId,
        })

        userPaycheck.user = user
        userPaycheck.payroll = payroll

        await this.officeUserPaycheckRepo.save(userPaycheck)

        return userPaycheck
    }

    async update(requesterId: string, args: UserPaycheckUpdateInput, token: string) {
        await this.validateUpdateUserPaycheckDate(args)

        const userPaycheck = await this.validateAndGetExistUserPaycheck(args.id)

        const user = args.userId ? await this.validateAndGetExistUser(args.userId) : null

        const payroll = args.payrollId ? await this.payrollService.validateAndGetExistPayroll(args.payrollId) : null

        userPaycheck.user = user ?? userPaycheck.user
        userPaycheck.payroll = payroll ?? userPaycheck.payroll
        userPaycheck.name = args.name ?? userPaycheck.name
        userPaycheck.month = args.month ?? userPaycheck.month
        userPaycheck.year = args.year ?? userPaycheck.year
        userPaycheck.wage = args.wage ? args.wage.toString() : userPaycheck.wage
        userPaycheck.status = args.status ?? userPaycheck.status
        userPaycheck.metadata = args.metadata ? [JSON.stringify(args.metadata)] as string[] : userPaycheck.metadata
        userPaycheck.updatedBy = requesterId

        await this.officeUserPaycheckRepo.save(userPaycheck)

        return userPaycheck
    }

    async bulkUpsert(requesterId: string, args: UserPaycheckBulkUpsertInput[], token: string) {
        let response: UserPaycheckBulkResponse[] = []

        for (const item of args) {
            if (item.errorMessage) {
                response.push({
                    ...item,
                    errorMessage: item.errorMessage,
                    id: null
                })
                continue
            }
            try {
                if (
                    !Number.isInteger(item.month)
                    && !Number.isInteger(item.year)
                    && !Number.isInteger(item.wage)
                    && item.month > 12
                    && item.month < 1
                ) {
                    response.push({
                        ...item,
                        errorMessage: OfficeErrorMessage.WrongDataInput,
                        id: null
                    })
                    continue
                }

                let paycheck = null
                if (!item.code) {

                    /*Check duplicate*/
                    await this.validateExistUserPaycheckDate(item)
                } else {

                    /*Check duplicate*/
                    await this.validateExistUserPaycheckDate(item, item.code)

                    paycheck = await this.validateAndGetExistUserPaycheck(item.code, true)
                }

                /*Check user*/
                let user
                try {
                    user = await this.validateAndGetExistUserBy({code: item.userCode})
                } catch (e) {
                    response.push({
                        ...item,
                        errorMessage: e.baseMsg,
                        id: null
                    })
                    continue
                }

                /*Check payroll*/
                let payroll
                try {
                    payroll = await this.payrollService.validateAndGetExistPayrollByCode(item.payrollCode)
                } catch (e) {
                    response.push({
                        ...item,
                        errorMessage: e.baseMsg,
                        id: null
                    })
                    continue
                }

                /*Check metadata*/
                const blocks = await this.officeInfoBlockRepo.findPayrollBlocksBy({
                    relationId: payroll.id,
                    status: ObjectStatus.Active
                })
                const fields = await this.officeInfoFieldRepo.find({
                    where: {
                        blockId: In(blocks.map(i => i.id))
                    },
                    order: {
                        no: "ASC"
                    }
                })

                const filterData: any = {}
                const responseData: any = {}
                let errorMessage = null
                fields.forEach(f => {
                    if (!errorMessage) {
                        if (f.required && !item.metadata[f.code]) {
                            errorMessage = `Thông tin ${f.name} là bắt buộc`
                        }
                        if (item.metadata[f.code] && item.metadata[f.code].length > 30) {
                            errorMessage = `Giá trị dữ liệu không vượt quá 30 kí tự`
                        }
                        if (f.dataType === DataType.Date && item.metadata[f.code] && !validateDateFormat(item.metadata[f.code])) {
                            errorMessage = `Vui lòng nhập đúng định dạng, giá trị trường ${f.name}`
                        }
                        if (f.dataType === DataType.List && item.metadata[f.code] && !f.optionItems.includes(item.metadata[f.code])) {
                            errorMessage = `Vui lòng nhập đúng định dạng, giá trị trường ${f.name}`
                        }
                        if (f.dataType === DataType.Email && item.metadata[f.code] && !validateEmail(item.metadata[f.code])) {
                            errorMessage = `Vui lòng nhập đúng định dạng, giá trị trường ${f.name}`
                        }
                        if (f.dataType === DataType.Number_Limit_Length_10 && item.metadata[f.code] && !validatePhoneNumber(item.metadata[f.code])) {
                            errorMessage = `Vui lòng nhập đúng định dạng, giá trị trường ${f.name}`
                        }
                    }

                    filterData[f.code] = item.metadata[f.code]
                    responseData[f.code] = item.metadata[f.code]
                    if (f.dataType === DataType.Date && item.metadata[f.code] && validateDateFormat(item.metadata[f.code])) {
                        filterData[f.code] = dayMonthYearToTime(item.metadata[f.code])
                    } else {
                        filterData[f.code] = item.metadata[f.code]
                    }
                })

                if (errorMessage) {
                    response.push({
                        ...item,
                        id: null,
                        errorMessage: errorMessage
                    })
                } else {
                    try {
                        let metadata = filterData

                        if (!item.code) {
                            const field = await this.create(
                                requesterId,
                                {
                                    ...item,
                                    metadata,
                                    userId: user.id,
                                    payrollId: payroll.id,
                                } as UserPaycheckCreateInput,
                                token
                            )

                            response.push({
                                ...item,
                                errorMessage: OfficeSuccessMessage.Create,
                                id: field.id,
                                code: field.code,
                            })
                        } else {
                            if (paycheck?.user?.id !== user.id) {
                                response.push({
                                    ...item,
                                    errorMessage: OfficeErrorMessage.UserPaycheckCannotEditUser,
                                    id: null
                                })
                                continue
                            }
                            if (paycheck?.payroll?.id !== payroll.id) {
                                response.push({
                                    ...item,
                                    errorMessage: OfficeErrorMessage.UserPaycheckCannotEditPayroll,
                                    id: null
                                })
                                continue
                            }

                            const field = await this.update(
                                requesterId,
                                {
                                    ...item,
                                    metadata,
                                    id: paycheck?.id,
                                } as UserPaycheckUpdateInput,
                                token
                            )

                            response.push({
                                ...item,
                                errorMessage: OfficeSuccessMessage.Update,
                                id: field.id,
                                code: field.code,
                            })
                        }

                    } catch (e) {
                        response.push({
                            ...item,
                            errorMessage: e.baseMsg,
                            id: null
                        })
                    }
                }
            } catch (e) {
                response.push({
                    ...item,
                    errorMessage: e.baseMsg,
                    id: null
                })
            }

        }

        return {records: response}
    }

    async getById(id: string) {
        return this.officeUserPaycheckRepo.findOneBy({id})
    }

    async getListFilters(requesterId: string, args: UserPaycheckListFilter, orgData: any) {
        const [data, total] = await this.officeUserPaycheckRepo.getListAndCountByFilter(args, null, orgData)

        return {
            total: total as number,
            count: data.length,
            userPaychecks: data
        }
    }

    async officeGetListFilters(requesterId: string, args: UserPaycheckListFilter) {
        const [data, total] = await this.officeUserPaycheckRepo.getListAndCountByFilterByUserId(args, requesterId)

        return {
            total: total as number,
            count: data.length,
            userPaychecks: data
        }
    }

    async officeGet(requesterId: string, id: string) {
        return this.officeUserPaycheckRepo.getOfUserById(requesterId, id)
    }

    getPaycheckOfUser(id: string, userIds: any) {
        return this.officeUserPaycheckRepo.getOfUsersById(id, userIds)
    }

    async commentCreate(args: UserPaycheckCommentCreate) {
        const paycheck = await this.getPaycheckCanComment(args.paycheckId)

        let param: any = args

        param.featureLogType = OfficeFeatureLogType.Paycheck
        param.featureLogId = paycheck.id
        param.description = args.comment

        delete param.approvalId
        delete param.comment

        await this.logService.commentCreate(param as OfficeLogCommentArgs)

        await paycheck.reload()
        return paycheck;
    }

    private async getPaycheckCanComment(paycheckId: string) {
        let paycheck: OfficeUserPaycheck
        if (RequestContext.isNormalUser()) {
            paycheck = await this.officeUserPaycheckRepo.getOfRequesterById(paycheckId)
        } else {
            paycheck = await this.officeUserPaycheckRepo.getOfAdminNotSupperById(paycheckId)
        }

        if (!paycheck) {
            throw OfficeError.UserPaycheckNotExist
        }

        return paycheck
    }
}
