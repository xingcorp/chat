import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, Repository } from "typeorm";
import { LearnCertification } from "@models/entities";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";
import { RequestContext } from "@common/context/request.context";
import { LearningSkillFilterInput } from "@modules/graphql/learning/skill/dto/skill.learning.arg";
import { LearningCertificateFilterInput } from "@modules/graphql/learning/certificate/dto/certificate.learning.arg";

@Injectable()
export class CertificateLearningRepo extends Repository<LearnCertification> {
    constructor(private dataSource: DataSource) {
        super(LearnCertification, dataSource.createEntityManager());
    }

    async createQueryBuilderWithCommonData(relations?: string[]): Promise<SelectQueryBuilder<LearnCertification>> {
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

    async listByFilter(filter: LearningCertificateFilterInput) {
        const query = await this.createQueryBuilderWithCommonData()

        query.orderBy('qb.createdAt', 'DESC')

        await this.filterQuery(query, filter)

        return query.getManyAndCount()
    }

    private async filterQuery(query: SelectQueryBuilder<LearnCertification>, filter: LearningSkillFilterInput) {
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