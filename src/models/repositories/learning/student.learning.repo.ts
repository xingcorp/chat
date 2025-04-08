import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, Repository } from "typeorm";
import { LearnStudent } from "@models/entities";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";
import { LearningSectionFilterInput } from "@modules/graphql/learning/course/section/dto/section.learning.arg";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";

@Injectable()
export class StudentLearningRepo extends Repository<LearnStudent> {
    constructor(
        private dataSource: DataSource,
        private redisService: RedisService,
    ) {
        super(LearnStudent, dataSource.createEntityManager());
    }

    createQueryBuilderWithCommonData(relations?: string[]): SelectQueryBuilder<LearnStudent> {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
    }

    async getCachedById(id: string) {
        const key = RedisKey.ELearningLearnStudent(id)
        const cached = await this.redisService.get(key)
        if (!cached) {
            const data = await this.getBy({ id })
            await this.redisService.setWithTtl(key, JSON.stringify(data))
            return data
        }
        return JSON.parse(cached)
    }

    async getBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilderWithCommonData(relations)

        return query
            .where(where)
            .getOne()
    }

    async getManyBy(where: any, relations?: string[], selects?: string[]) {
        const query = this.createQueryBuilderWithCommonData(relations)

        if (selects) {
            query.select(selects.map(i => `qb.${i}`))
        }

        return query
            .where(where)
            .getMany()
    }

    async listByFilter(filter: LearningSectionFilterInput) {
        const query = this.createQueryBuilderWithCommonData()

        query.orderBy('qb.createdAt', 'DESC')

        await this.filterQuery(query, filter)

        return query.getManyAndCount()
    }

    private async filterQuery(query: SelectQueryBuilder<LearnStudent>, filter: LearningSectionFilterInput) {
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