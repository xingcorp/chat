import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, In, Repository } from "typeorm";
import { ApprovalFormGroup } from "@models/entities";
import { TASK_WATCHER_BRIDGE_TABLE } from "@models/entities/task/task";
import { BRIDGE_TABLE_DB } from "@common/db/bridge-table.db";
import { RequestContext } from "@common/context/request.context";
import {
    ApprovalFormGroupFilter
} from "@modules/graphql/management/approval/approval-from-group/dto/approval-form-group.args";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";

@Injectable()
export class ApprovalFormGroupRepo extends Repository<ApprovalFormGroup> {
    constructor(
        private dataSource: DataSource,
    ) {
        super(ApprovalFormGroup, dataSource.createEntityManager());
    }

    async getOneBy(where: any, relations?: string[]) {
        const query = this
            .createQueryBuilder('qb')
            .leftJoinAndSelect(BRIDGE_TABLE_DB.APPROVAL_FORM_GROUP_ORG_CHART, 'wBridgeOrg', '"wBridgeOrg"."officeApprovalFormGroupsId" = qb.id')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .andWhere(`"wBridgeOrg"."officeOrgChartsId" in (:...orgIds)`, {orgIds: await RequestContext.getRootOrgIds()})
            .getOne()
    }

    async getBy(where: any, relations?: string[]) {
        const query = this
            .createQueryBuilder('qb')
            .leftJoinAndSelect(BRIDGE_TABLE_DB.APPROVAL_FORM_GROUP_ORG_CHART, 'wBridgeOrg', '"wBridgeOrg"."officeApprovalFormGroupsId" = qb.id')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .andWhere(`"wBridgeOrg"."officeOrgChartsId" in (:...orgIds)`, {orgIds: await RequestContext.getRootOrgIds()})
            .getMany()
    }

    async listByFilter(filter: ApprovalFormGroupFilter) {
        const query = this.createQueryBuilder('qb')
            .leftJoinAndSelect(BRIDGE_TABLE_DB.APPROVAL_FORM_GROUP_ORG_CHART, 'wBridgeOrg', '"wBridgeOrg"."officeApprovalFormGroupsId" = qb.id')
            .where(`"wBridgeOrg"."officeOrgChartsId" in (:...orgIds)`, {orgIds: await RequestContext.getRootOrgIds()})
            .orderBy('qb.createdAt', 'DESC')

        await this.filterQuery(query, filter)

        return query.getManyAndCount()
    }

    private async filterQuery(query: SelectQueryBuilder<ApprovalFormGroup>, filter: ApprovalFormGroupFilter) {
        /*default get all*/
        if (filter.page || filter.size) {
            filter.size = filter.size ? filter.size : 20 //1
            filter.page = filter.page ? (filter.page - 1) : 0

            query.limit(filter.size)
                .offset(filter.page * filter.size)
        }

        if (filter && filter.keyword) {
            query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    // .orWhere(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    // .orWhere(`unaccent(LOWER(qb.serial)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
            }))
        }
    }

    async listApprovalFormById(id: string) {
        const _this = await this.findOne({
            relations: ['forms'],
            where: {id}
        })

        return _this.forms
    }
}