import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, In, Not, Repository } from "typeorm";
import { LearningUserPinned, LearnProject } from "@models/entities";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";
import { RequestContext } from "@common/context/request.context";
import { LearningProjectFilterInput } from "@modules/graphql/learning/project/dto/project.learning.arg";
import { LearnProjectStatusEnum } from "@enum/learning/learning.enum";
import { RedisKey } from "@core/common/common.type";
import { RedisService } from "@core/common/redis.service";

@Injectable()
export class ProjectLearningRepo extends Repository<LearnProject> {
    constructor(
        private dataSource: DataSource,
        private redisService: RedisService
    ) {
        super(LearnProject, dataSource.createEntityManager());
    }

    async createQueryBuilderWithCommonData(relations?: string[]): Promise<SelectQueryBuilder<LearnProject>> {
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

    async getCachedById(id: string) {
        const key = RedisKey.ELearningProjectLearning(id)
        const cached = await this.redisService.get(key)
        if (!cached) {
            const data = await this.getBy({ id })
            await this.redisService.setWithTtl(key, JSON.stringify(data))
            return data
        }
        return JSON.parse(cached)
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

    async listByFilter(filter?: LearningProjectFilterInput) {
        const query = await this.createQueryBuilderWithCommonData();

        if (RequestContext.isNormalUser()) {
            query.andWhere({
                status: Not(LearnProjectStatusEnum.DRAFT),
                isHide: false
            })
        }

        await this.filterQuery(query, filter)
        return query.getManyAndCount();
    }

    private async filterQuery(query: SelectQueryBuilder<LearnProject>, filter?: LearningProjectFilterInput) {

        if (filter.page || filter.size) {
            filter.size = filter.size ? filter.size : 20 //1
            filter.page = filter.page ? (filter.page - 1) : 0

            query.limit(filter.size)
                .offset(filter.page * filter.size)
        }

        if (filter.status) {
            query.andWhere('qb.status = :status', { status: filter.status })
        }

        if (filter.departmentIds?.length) {
            query.innerJoin('qb.departments', 'departments')
                .andWhere('departments.id IN (:...departmentIds)', {
                    departmentIds: filter.departmentIds
                })
        }

        if (filter.skillIds?.length) {
            query
                .innerJoin('qb.skills', 'skills')
                .andWhere('skills.id IN (:...skillIds)', {
                    skillIds: filter.skillIds
                })
        }

        if (filter.startDate) {
            query.andWhere('qb.startDate >= :startDate', {
                startDate: new Date(filter.startDate)
            })
        }

        if (filter.endDate) {
            query.andWhere('qb.endDate <= :endDate', {
                endDate: new Date(filter.endDate)
            })
        }

        if (filter.orderBy && filter.orderBy.length > 0) {
            filter.orderBy.forEach(order => {
                query.addOrderBy(`qb.${order.key}`, order.direction);
            })
        } else {
            query.leftJoinAndSelect(LearningUserPinned, "up", 'qb.id = up."projectId" AND up."userId" = :userId', { userId: RequestContext.currentId() })
                .addSelect('CASE WHEN up."userId" IS NOT NULL THEN 1 ELSE 0 END', "is_pinned")
                .orderBy("is_pinned", "DESC")
                .addOrderBy('qb.createdAt', 'DESC');
        }

        if (filter && filter.keyword) {
            query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                    .orWhere(`qb.code ILIKE :keyword`, { keyword: `%${filter.keyword.trim()}%` })
            }))
        }
    }

    async getSkillsByProjectLearningId(projectLearningId: string) {
        const cached = await this.redisService.get(RedisKey.ELearningProjectLearningSkill(projectLearningId))
        if (cached) return JSON.parse(cached)
        const _root = await this.getBy({ id: projectLearningId }, ['skills'])
        await this.redisService.setWithTtl(RedisKey.ELearningProjectLearningSkill(projectLearningId), JSON.stringify(_root.skills))
        return _root.skills
    }
}