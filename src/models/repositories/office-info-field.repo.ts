import * as dotenv from 'dotenv';

dotenv.config();
import { Injectable } from "@nestjs/common";
import { DataSource, In, IsNull, Not, Repository } from "typeorm";
import { InfoBlock, InfoField } from "@models/entities";
import { PayrollFieldArgs } from "@modules/graphql/management/payroll/dto/payroll.args";
import { OfficeBlockType } from "@enum/block/block.enum";
import { RequestContext } from "@common/context/request.context";
import { infoBlockHelperGetDataDemo } from "@helpers/blocks/info.block";
import { LinkTableType } from "@enum/block/field.enum";
import { DataType } from "@models/entities/profile.info.field";
import { validateDateFormat, validateEmail, validateNumeric, validatePhoneNumber } from "@common/regex";
import { dayMonthYearToTime } from "@utils/datetime.utils";
import { OfficeErrorMessage } from "@common/office.error";

@Injectable()
export class OfficeInfoFieldRepo extends Repository<InfoField>{
    constructor(private dataSource: DataSource) {
        super(InfoField, dataSource.createEntityManager());
    }

    async createManyPayrollBlockFields(fieldsData: PayrollFieldArgs[], requesterId: string) {
        let fields = []
        fieldsData.map((item) => {
            fields.push(this.create({
                ...item,
                createdBy: requesterId,
                updatedBy: requesterId
            }))

        })

        return fields
    }

    async getListFieldExport() {
        const listId = process.env.INFO_FIELDS_EMPLOYEE_EXPORT.split(',')

        return this.findBy({
            id: In(listId ?? [])
        })
    }

    getByBlockId(id: string | undefined) {
        return this.find({
            where: {
                blockId: id
            },
            order: {
                order: "ASC"
            }
        })
    }

    async listSoftWorkDetailField() {
        return this.createQueryBuilder('qb')
            .leftJoinAndMapOne('qb.block', InfoBlock, 'block', 'qb."blockId"::text = block."id"::text')
            .where(`block.relationType = :relationType`, {relationType: OfficeBlockType.WorkProfile})
            .andWhere(`block.relationId = :rootId`, {rootId: await RequestContext.getRootOrgId()}) //not support
            .orderBy(`qb.order`, 'ASC')
            .getMany()
    }

    async listSoftWorkDetailDefaultField() {
        return this.createQueryBuilder('qb')
            .leftJoinAndMapOne('qb.block', InfoBlock, 'block', 'qb."blockId"::text = block."id"::text')
            .where(`block."relationType" = :relationType`, {relationType: OfficeBlockType.WorkProfile})
            .andWhere(`block."relationId" = :rootId`, {rootId: await RequestContext.getRootOrgId()}) // not support
            .andWhere(`qb."linkTableType" IS NULL`)
            .orderBy(`qb.order`, 'ASC')
            .getMany()
    }

    async listSoftWorkDetailDataDefaultField() {
        const softWorkDetailFields = await this.listSoftWorkDetailDefaultField()
        const softRows = {}
        const softRowsDemoData = infoBlockHelperGetDataDemo(softWorkDetailFields)

        softWorkDetailFields.map(i => {
            softRows[i.code] = i.name
        })

        return {
            softRows,
            softRowsDemoData
        }
    }

    async listSoftWorkDetailDataField() {
        const softWorkDetailFields = await this.listSoftWorkDetailField()
        const softRows = {}
        const softRowsDemoData = infoBlockHelperGetDataDemo(softWorkDetailFields)

        softWorkDetailFields.map(i => {
            softRows[i.code] = i.name
        })

        return {
            softRows,
            softRowsDemoData
        }
    }

    async getSoftFieldLinkedOfKOrg(blockId: string) {
        return this.find({
            where: {
                blockId,
                linkFieldType: Not(IsNull())
            }
        })
    }

    async getWorkProfileDefaultFieldByBlockId(blockId: string) {
        return this.find({
            where: {
                blockId,
                linkTableType: IsNull()
            }
        })
    }

    async getWorkProfileResignFieldByBlockId(blockId: string) {
        const linkFieldTypeList = ['lastWorkingOn', 'resignationType', 'resignationReason', 'resignationDetailReason', 'leaveOn']

        return this.find({
            where: {
                blockId,
                linkTableType: LinkTableType.User,
                linkFieldType: In(linkFieldTypeList),
            }
        })
    }

    async validateAndTransformData(metadata: JSON) {
        const fields = await this.find({
            where: {
                code: In(Object.keys(metadata))
            },
            order: {
                no: "ASC"
            }
        })

        const filterData: any = {}
        const responseData: any = {}
        let errorMessage
        fields.forEach(f => {
            if (!errorMessage) {
                /* https://jr.smarthiz.vn/browse/SOF-693 */
                // if (!metadata[f.code] && f.required) {
                //     errorMessage = 'Vui lòng không để trống trường bắt buộc'
                // }
                if (
                    (f.dataType === DataType.Date && metadata[f.code] && !validateDateFormat(metadata[f.code]))
                    || (f.dataType === DataType.List && metadata[f.code] && !f.optionItems.map(i => i.trim()).includes(metadata[f.code]))
                    || (f.dataType === DataType.Email && metadata[f.code] && !validateEmail(metadata[f.code]))
                    || (f.dataType === DataType.Number_Limit_Length_10 && metadata[f.code] && !validatePhoneNumber(metadata[f.code]))
                    || (f.dataType === DataType.Number && metadata[f.code] && !validateNumeric(metadata[f.code]))
                ) {
                    errorMessage = OfficeErrorMessage.WrongFormatField(f.name)
                }
            }

            responseData[f.code] = metadata[f.code]
            if (f.dataType === DataType.Date && metadata[f.code] && validateDateFormat(metadata[f.code])) {
                filterData[f.code] = dayMonthYearToTime(metadata[f.code])
            } else {
                filterData[f.code] = metadata[f.code]
            }
        })

        return {
            transformData: filterData,
            errorMessage
        }

    }
}