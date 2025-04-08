import { Injectable } from "@nestjs/common";
import { DataSource, IsNull, Not, Repository } from "typeorm";
import { InfoBlock } from "@models/entities";
import { PayrollBlockArgs, PayrollBlockCreateInput } from "@modules/graphql/management/payroll/dto/payroll.args";
import { OfficeBlockType } from "@enum/block/block.enum";
import { RequestContext } from "@common/context/request.context";

@Injectable()
export class OfficeInfoBlockRepo extends Repository<InfoBlock>{
    constructor(private dataSource: DataSource) {
        super(InfoBlock, dataSource.createEntityManager());
    }

    async createManyPayrollBlocks(blocksData: PayrollBlockArgs[], requesterId: string) {
        let blocks = []
        blocksData.map((item) => {
            let fields = structuredClone(item.fields)
            delete item.fields

            blocks.push({
                block: this.create({
                    ...item,
                    createdBy: requesterId,
                    updatedBy: requesterId,
                    relationType: OfficeBlockType.Payroll
                }),
                fields
            })

        })

        return blocks
    }

    async insertPayrollBlocks(args: PayrollBlockCreateInput, requesterId: string) {
        const relationId = args.payrollId
        delete args.payrollId

        const block = this.create({
            ...args,
            createdBy: requesterId,
            updatedBy: requesterId,
            relationId,
            relationType: OfficeBlockType.Payroll
        })

        return this.save(block)
    }

    async findPayrollBlockRelationByName(relationId: string, name: string, idExclude: string = null) {
        return this.findOne({
            where: {
                name,
                relationId,
                relationType: OfficeBlockType.Payroll,
                id: Not(idExclude ?? IsNull())
            }
        })
    }

    async findPayrollBlockById(id: string) {
        return this.findOne({
            where: {
                id,
                relationType: OfficeBlockType.Payroll
            }
        })
    }

    async findPayrollBlockBy(param: any) {
        return this.findOne({
            where: {
                ...param,
                relationType: OfficeBlockType.Payroll
            }
        })
    }

    async findPayrollBlocksBy(param: any) {
        return this.find({
            where: {
                ...param,
                relationType: OfficeBlockType.Payroll
            },
            order: {
                createdAt: 'ASC'
            }
        })
    }

    async deletePayrollBlockById(id: string, requesterId: string) {
        await this.createQueryBuilder()
            .update()
            .set({
                updatedBy: requesterId,
            })
            .where({
                id: id,
                relationType: OfficeBlockType.Payroll
            })
            .execute()

        return this.createQueryBuilder()
            .softDelete()
            .where({
                id: id,
                relationType: OfficeBlockType.Payroll
            })
            .execute();
    }

    /**
     * Not support more org
     * */
    async getWorkProfile() {
        return this.getWorkProfileByOrgId(await RequestContext.getRootOrgId())
    }

    getWorkProfileByOrgId(id: string) {
        if (!id) return null
        return this.findOne({
            where: {
                relationType: OfficeBlockType.WorkProfile,
                relationId: id
            }
        })
    }

    async createWorkProfileByOrgId(id: string) {
        const block = this.create({
            name: "Quá trình làm việc",
            relationType: OfficeBlockType.WorkProfile,
            relationId: id
        })

        await block.save()
        await block.reload()

        return block
    }
}