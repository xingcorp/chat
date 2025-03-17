import { Injectable } from '@nestjs/common';
import {
    PayrollBlockBulkUpsertInput,
    PayrollBlockCreateInput,
    PayrollBlockFieldCreateInput,
    PayrollBlockFieldUpdateInput,
    PayrollBlockUpdateInput,
    PayrollBulkUpsertInput,
    PayrollCreateInput,
    PayrollCreateWithBlockInput,
    PayrollListFilter,
    PayrollUpdateInput
} from "@modules/graphql/management/payroll/dto/payroll.args";
import { OfficePayrollRepo } from "@repositories/payroll/office-payroll.repo";
import { DataSource, In, IsNull, Not } from "typeorm";
import { OfficeInfoBlockRepo } from "@repositories/office-info-block.repo";
import { OfficeError, OfficeErrorMessage } from "@common/office.error";
import { OfficeInfoFieldRepo } from "@repositories/office-info-field.repo";
import {
    PayrollBlockBulkResponse,
    PayrollBulkResponse
} from "@modules/graphql/management/payroll/dto/payroll.response";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { OfficeSuccessMessage } from "@common/office.success";
import { OfficeOrgChartRepo } from "@repositories/office-org-chart.repo";
import { OfficeUserRepo } from "@models/repositories";

@Injectable()
export class PayrollService {
    constructor(
        private dataSource: DataSource,
        private officePayrollRepo: OfficePayrollRepo,
        private officeInfoBlockRepo: OfficeInfoBlockRepo,
        private officeInfoFieldRepo: OfficeInfoFieldRepo,
        private officeOrgChartRepo: OfficeOrgChartRepo,
        private officeUserRepo: OfficeUserRepo
    ) {
    }

    private async validatePayrollNameExist(name: string, idExclude: string = null) {
        console.log('where', {
            name,
            id: Not(idExclude ?? IsNull())
        })

        if (await this.officePayrollRepo.findOne({
            where: {
                name,
                id: Not(idExclude ?? IsNull())
            }
        })) {
            throw OfficeError.PayrollExist
        }
    }

    async validateAndGetExistPayroll(id: string) {
        const payroll = await this.officePayrollRepo.findOneBy({id})

        if (!payroll) {
            throw OfficeError.PayrollNotExist
        }

        return payroll
    }

    async validateAndGetExistPayrollByCode(code: string) {
        const payroll = await this.officePayrollRepo.findOneBy({code})

        if (!payroll) {
            throw OfficeError.PayrollCodeNotExist
        }

        return payroll
    }

    private async validateExistPayroll(id: string) {
        const payroll = await this.officePayrollRepo.findOneBy({id})

        if (payroll) {
            throw OfficeError.PayrollExist
        }
    }

    private async validateExistPayrollCode(code: string) {
        if (await this.officePayrollRepo.findOneBy({code})) {
            throw OfficeError.PayrollCodeExist
        }
    }

    private async validateAndGetExistPayrollBlock(id: string) {
        const block = await this.officeInfoBlockRepo.findPayrollBlockById(id)
        if (!block) {
            throw OfficeError.ProfileBlockNotExisted
        }

        return block
    }

    private async validateAndGetExistPayrollBlockBy(expect: object, error: string) {
        const block = await this.officeInfoBlockRepo.findPayrollBlockBy({
            ...expect
        })

        if (!block) {
            throw OfficeError[error]
        }

        return block
    }

    private async validatePayrollBlockExistBy(expect: object, error: string) {
        const block = await this.officeInfoBlockRepo.findPayrollBlockBy({
            ...expect
        })

        if (block) {
            throw OfficeError[error]
        }

        return block
    }

    private async validatePayrollBlockRelationExistBy(id: string, relationId: string, expect: object, error: string) {
        const block = await this.officeInfoBlockRepo.findPayrollBlockBy({
            id: Not(id ?? IsNull()),
            relationId,
            ...expect
        })

        if (block) {
            throw OfficeError[error]
        }
    }

    private async validatePayrollFieldExistBy(id: string, blockId: string, expect: object, error: string) {
        if (await this.officeInfoFieldRepo.findOneBy({
            id: Not(id),
            blockId,
            ...expect
        })) {
            throw OfficeError[error]
        }
    }

    async createFull(requesterId: string, args: PayrollCreateWithBlockInput) {
        const blocksData = args.blocks
        delete args.blocks

        const payroll = this.officePayrollRepo.create({
            ...args,
            createdBy: requesterId,
            updatedBy: requesterId,
        })

        const blocks = await this.officeInfoBlockRepo.createManyPayrollBlocks(blocksData, requesterId)

        for (const index in blocks) {
            blocks[index].fields = await this.officeInfoFieldRepo.createManyPayrollBlockFields(blocks[index].fields, requesterId)
        }

        /*await this.dataSource.manager.transaction(async (entity) => {
            const savePayroll = await entity.save(payroll);

            for (const item of blocks) {
                const block = await entity.save({
                    ...item.block,
                    relationId: savePayroll.id
                });

                for (const field of item.field) {
                    await entity.save({
                        ...field,
                        blockId: block.id
                    });
                }
            }
        });*/

        const savePayroll = await this.dataSource.manager.save(payroll);

        for (const item of blocks) {
            const block = await this.dataSource.manager.save({
                ...item.block,
                relationId: savePayroll.id
            });

            for (const field of item.field) {
                await this.dataSource.manager.save({
                    ...field,
                    blockId: block.id
                });
            }
        }
    }

    async create(requesterId: string, args: PayrollCreateInput) {
        await this.validatePayrollNameExist(args.name)

        const res = this.officePayrollRepo.create({
            ...args,
            createdBy: requesterId,
            updatedBy: requesterId,
        })

        res.orgCharts = await this.getListOrgCharts(args.orgChartIds)

        return this.officePayrollRepo.save(res)
    }

    async update(requesterId: string, args: PayrollUpdateInput) {
        const payroll = await this.validateAndGetExistPayroll(args.id)

        if (args.name) {
            await this.validatePayrollNameExist(args.name, args.id)
        }

        // if (args.code && payroll.code !== args.code) {
        //     await this.validateExistPayrollCode(args.code)
        // }

        // payroll.code = args.code ?? payroll.code
        payroll.name = args.name ?? payroll.name
        payroll.status = args.status ?? payroll.status
        payroll.updatedBy = requesterId

        payroll.orgCharts = args.orgChartIds ? await this.getListOrgCharts(args.orgChartIds ?? []) : payroll.orgCharts

        return this.officePayrollRepo.save(payroll)
    }

    async bulkUpsert(requesterId: string, args: PayrollBulkUpsertInput[]) {
        let response: PayrollBulkResponse[] = []

        for (const item of args) {
            let payroll = null

            if (item.code) {
                try {
                    payroll = await this.validateAndGetExistPayrollByCode(item.code)
                } catch (e) {
                    response.push({
                        ...item,
                        errorMessage: e.baseMsg,
                        id: null
                    })
                    continue
                }
            }

            if (item.name && (!payroll || (payroll && payroll.name !== item.name))) {
                try {
                    await this.validatePayrollNameExist(item.name)
                } catch (e) {
                    response.push({
                        ...item,
                        errorMessage: e.baseMsg,
                        id: null
                    })
                    continue
                }
            }

            if (!item.name || !item.status || !item.orgChartIds) {
                response.push({
                    ...item,
                    errorMessage: OfficeErrorMessage.RequiredField,
                    id: null
                })
                continue
            }

            if (!Object.values(ObjectStatus).includes(item.status as ObjectStatus)) {
                response.push({
                    ...item,
                    errorMessage: OfficeErrorMessage.StatusWrongType,
                    id: null
                })
                continue
            }

            try {
                if (payroll) {
                    payroll.name = item.name
                    payroll.status = item.status

                    payroll.orgCharts = await this.getListOrgCharts(item.orgChartIds)

                    await this.officePayrollRepo.save(payroll)
                    response.push({
                        ...item,
                        errorMessage: OfficeSuccessMessage.Update,
                        id: payroll.id
                    })

                } else {
                    payroll = this.officePayrollRepo.create({
                        ...item,
                        status: item.status as ObjectStatus,
                        createdBy: requesterId,
                        updatedBy: requesterId
                    })

                    payroll.orgCharts = await this.getListOrgCharts(item.orgChartIds)

                    await this.officePayrollRepo.save(payroll)

                    response.push({
                        ...item,
                        errorMessage: OfficeSuccessMessage.Create,
                        id: payroll.id,
                        code: payroll.code,
                    })
                }
            } catch {
                response.push({
                    ...item,
                    errorMessage: OfficeErrorMessage.DBRequestError,
                    id: null
                })
            }
        }

        return {records: response}
    }

    async getById(id: string, orgIds: string[]) {
        if (!orgIds) {
            throw OfficeError.ActionNotAllowed()
        }
        const payroll = await this.officePayrollRepo.findOne({
            relations: ['orgCharts'],
            where: {
                orgCharts: {
                    id: In(orgIds)
                },
                id
            }
        });

        if (!payroll) {
            throw OfficeError.PayrollNotExist
        }

        return payroll
    }

    async getList(args: PayrollListFilter, orgIds: string[]) {
        let departmentId = null

        if (args.userId) {
            departmentId = await this.officeUserRepo.getDepartmentIdBy({id: args.userId})
        }

        if (!orgIds) {
            throw OfficeError.ActionNotAllowed()
        }

        const [data, total] = await this.officePayrollRepo.getListAndCount(args, orgIds, departmentId)

        return {
            total: total as number,
            count: data.length,
            payrolls: data
        }
    }

    async createBlock(requesterId: string, args: PayrollBlockCreateInput) {
        if (await this.officeInfoBlockRepo.findPayrollBlockRelationByName(args.payrollId, args.name)) {
            throw OfficeError.ProfileBlockIsExisted
        }

        return this.officeInfoBlockRepo.insertPayrollBlocks(args, requesterId)
    }

    async updateBlock(requesterId: string, args: PayrollBlockUpdateInput) {
        const block = await this.validateAndGetExistPayrollBlock(args.id)

        if (args.payrollId) await this.validateAndGetExistPayroll(args.payrollId)

        if (args.name && args.payrollId) {
            await this.validatePayrollBlockRelationExistBy(args.id, args.payrollId, {name: args.name}, 'ProfileBlockIsExisted')
        }

        // if (args.code && block.code !== args.code) {
        //     await this.validatePayrollBlockRelationExistBy(args.id, args.payrollId, {code: args.code}, 'ProfileBlockCodeIsExisted')
        // }

        // block.code = args.code ?? block.code
        block.name = args.name ?? block.name
        block.status = args.status ?? block.status
        block.note = args.note ?? block.note
        block.relationId = args.payrollId ?? block.relationId
        block.updatedBy = requesterId

        return this.officeInfoBlockRepo.save(block)
    }

    async bulkUpsertBlock(requesterId: string, args: PayrollBlockBulkUpsertInput[]) {
        let response: PayrollBlockBulkResponse[] = []

        for (const item of args) {
            let payroll = null
            let block = null

            /*Check require*/
            if (!item.name || !item.status || !item.payrollCode) {
                response.push({
                    ...item,
                    errorMessage: OfficeErrorMessage.RequiredField,
                    id: null
                })
                continue
            }

            /*Check payroll*/
            try {
                payroll = await this.validateAndGetExistPayrollByCode(item.payrollCode)
            } catch (e) {
                response.push({
                    ...item,
                    errorMessage: e.baseMsg,
                    id: null
                })
                continue
            }

            /*Check block*/
            if (item.code) {
                try {
                    block = await this.validateAndGetExistPayrollBlockBy({code: item.code}, 'ProfileBlockNotExisted')
                } catch (e) {
                    response.push({
                        ...item,
                        errorMessage: e.baseMsg,
                        id: null
                    })
                    continue
                }
            }

            /*Check name*/
            if (item.name && (!block || (block && block.name !== item.name))) {
                try {
                    await this.validatePayrollBlockExistBy({name: item.name}, 'ProfileBlockIsExisted')
                } catch (e) {
                    response.push({
                        ...item,
                        errorMessage: e.baseMsg,
                        id: null
                    })
                    continue
                }
            }

            /*Check status*/
            if (!Object.values(ObjectStatus).includes(item.status as ObjectStatus)) {
                response.push({
                    ...item,
                    errorMessage: OfficeErrorMessage.StatusWrongType,
                    id: null
                })
                continue
            }

            /*Upsert*/
            try {
                const blockData = structuredClone(item)
                delete blockData.payrollCode

                if (block) {
                    block.name = item.name
                    block.status = item.status
                    block.relationId = payroll.id

                    await this.officeInfoBlockRepo.save(block)
                    response.push({
                        ...item,
                        errorMessage: OfficeSuccessMessage.Update,
                        id: block.id
                    })

                } else {
                    block = await this.officeInfoBlockRepo.insertPayrollBlocks(
                        {
                            ...item,
                            payrollId: payroll.id
                        } as PayrollBlockCreateInput
                        , requesterId
                    )

                    response.push({
                        ...item,
                        errorMessage: OfficeSuccessMessage.Create,
                        id: block.id,
                        code: block.code,
                    })
                }
            } catch {
                response.push({
                    ...item,
                    errorMessage: OfficeErrorMessage.DBRequestError,
                    id: null
                })
            }
        }

        return {records: response}
    }

    async createBlockField(requesterId: string, args: PayrollBlockFieldCreateInput) {
        await this.validateAndGetExistPayrollBlock(args.blockId)

        if (await this.officeInfoFieldRepo.findOneBy({
            name: args.name,
            blockId: args.blockId
        })) {
            throw OfficeError.ProfileFieldIsExisted
        }

        const field = this.officeInfoFieldRepo.create({
            ...args,
            createdBy: requesterId,
            updatedBy: requesterId,
            optionItems: args.optionItems || []
        })

        return this.officeInfoFieldRepo.save(field);
    }

    async updateBlockField(requesterId: string, args: PayrollBlockFieldUpdateInput) {
        const field = await this.officeInfoFieldRepo.findOneBy({id: args.id})
        if (!field) {
            throw OfficeError.ProfileFieldNotExisted
        }

        if (args.blockId) await this.validateAndGetExistPayrollBlock(args.blockId)

        if (args.blockId && args.name) {
            await this.validatePayrollFieldExistBy(args.id, args.blockId, {name: args.name}, 'ProfileFieldIsExisted')
        }

        // if (args.code && field.code !== args.code) {
        //     await this.validatePayrollFieldExistBy(args.id, args.blockId, {code: args.code}, 'ProfileFieldCodeIsExisted')
        // }

        // field.code = args.code ?? field.code

        field.name = args.name ?? field.name
        field.status = args.status ?? field.status
        field.note = args.note ?? field.note
        field.blockId = args.blockId ?? field.blockId
        field.dataType = args.dataType ?? field.dataType
        field.required = args.required ?? field.required
        field.optionItems = args.optionItems ?? field.optionItems
        field.updatedBy = requesterId

        return this.officeInfoFieldRepo.save(field)
    }

    async getInfoFieldById(id: string) {
        return this.officeInfoFieldRepo.findOneBy({id});
    }

    private async getListOrgCharts(orgChartIds: string[]) {
        const orgCharts = []
        for (const orgId of orgChartIds) {
            const org = await this.officeOrgChartRepo.findOneBy({id: orgId})

            if (!org) {
                throw OfficeError.DepartmentNotExist
            }

            orgCharts.push(org)
        }

        return orgCharts
    }

    async deleteBlock(requesterId: string, id: string) {
        await this.officeInfoBlockRepo.deletePayrollBlockById(id, requesterId);

        return id
    }
}
