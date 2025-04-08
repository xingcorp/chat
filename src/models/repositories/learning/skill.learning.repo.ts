import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, Repository } from "typeorm";
import { LearnSkill } from "@models/entities";
import { LearningSkillFilterInput } from "@modules/graphql/learning/skill/dto/skill.learning.arg";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";
import { RequestContext } from "@common/context/request.context";

@Injectable()
export class SkillLearningRepo extends Repository<LearnSkill> {
    constructor(private dataSource: DataSource) {
        super(LearnSkill, dataSource.createEntityManager());
    }

    async createQueryBuilderWithCommonData(relations?: string[]): Promise<SelectQueryBuilder<LearnSkill>> {
        const query = this
            .createQueryBuilder('qb')
            .where(
                { orgChartId: await RequestContext.getRootOrgId() }
            )

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
    }

    async getBy(where: any, relations?: string[]) {
        const query = await this.createQueryBuilderWithCommonData(relations)

        return query
            .where(where)
            .getOne()
    }

    async getManyBy(where: any, relations?: string[]) {
        const query = await this.createQueryBuilderWithCommonData(relations)

        return query
            .where(where)
            .getMany()
    }

    async listByFilter(filter: LearningSkillFilterInput) {
        const query = await this.createQueryBuilderWithCommonData()

        query.orderBy('qb.createdAt', 'DESC')

        await this.filterQuery(query, filter)

        return query.getManyAndCount()
    }

    private async filterQuery(query: SelectQueryBuilder<LearnSkill>, filter: LearningSkillFilterInput) {
        /*default get all*/
        if (filter.page || filter.size) {
            filter.size = filter.size ? filter.size : 20 //1
            filter.page = filter.page ? (filter.page - 1) : 0

            query.limit(filter.size)
                .offset(filter.page * filter.size)
        }

        if (filter && filter.keyword) {
            query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                // .orWhere(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                // .orWhere(`unaccent(LOWER(qb.serial)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
            }))
        }
    }
}