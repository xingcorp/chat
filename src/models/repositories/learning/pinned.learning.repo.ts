import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { LearningUserPinned } from "@models/entities";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";

@Injectable()
export class LearningUserPinnedRepo extends Repository<LearningUserPinned> {
    constructor(
        private dataSource: DataSource,
        private redisService: RedisService,
    ) {
        super(LearningUserPinned, dataSource.createEntityManager());
    }

    createQueryBuilderWithCommonData(relations?: string[]): SelectQueryBuilder<LearningUserPinned> {
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

}