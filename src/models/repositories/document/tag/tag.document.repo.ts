import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, In, Repository } from "typeorm";
import { TagDocument } from "@models/entities";
import { RequestContext } from "@common/context/request.context";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";
import { WikiCategoryFilterInput } from "@modules/graphql/management/wiki/dto/category.wiki.args";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";

@Injectable()
export class TagDocumentRepo extends Repository<TagDocument> {
    constructor(private dataSource: DataSource) {
        super(TagDocument, dataSource.createEntityManager());
    }

    async createQueryBuilderWithCommonData(relations?: string[]): Promise<SelectQueryBuilder<TagDocument>> {
        const query = this
            .createQueryBuilder('qb')
            .leftJoinAndSelect(
                BRIDGE_TABLE_DB_OBJ.DOCUMENT_TAG_ORG_CHART.name,
                'wBridgeOrg',
                `"wBridgeOrg"."${BRIDGE_TABLE_DB_OBJ.DOCUMENT_TAG_ORG_CHART.joinColumn.name}" = qb.id`)
            .where(
                `"wBridgeOrg"."${BRIDGE_TABLE_DB_OBJ.DOCUMENT_TAG_ORG_CHART.inverseJoinColumn.name}" in (:...orgIds)`,
                {orgIds: await RequestContext.getRootOrgIds()})

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
    }

    async getOneBy(where: any, relations?: string[]) {
        const query = await this.createQueryBuilderWithCommonData(relations)

        return query
            .andWhere(where)
            .getOne()
    }

    async getBy(where: any, relations?: string[]) {
        const query = await this.createQueryBuilderWithCommonData(relations)

        return query
            .andWhere(where)
            .getMany()
    }

    async listByFilter(filter: WikiCategoryFilterInput) {
        const query = await this.createQueryBuilderWithCommonData()

        query.orderBy('qb.createdAt', 'DESC')

        await this.filterQuery(query, filter)

        return query.getManyAndCount()
    }

    private async filterQuery(query: SelectQueryBuilder<TagDocument>, filter: WikiCategoryFilterInput) {
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
}