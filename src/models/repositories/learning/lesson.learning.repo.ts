import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, Repository } from "typeorm";
import { LearnLesson } from "@models/entities";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";
import { LearningLessonFilterInput } from "@modules/graphql/learning/course/section/lesson/dto/lesson.learning.arg";

@Injectable()
export class LessonLearningRepo extends Repository<LearnLesson> {
    constructor(private dataSource: DataSource) {
        super(LearnLesson, dataSource.createEntityManager());
    }

    async getBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getOne()
    }

    async getManyBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getMany()
    }

    async listByFilter(filter: LearningLessonFilterInput) {
        const query = this.createQueryBuilder('qb')

        query.orderBy('qb.createdAt', 'DESC')

        await this.filterQuery(query, filter)

        return query.getManyAndCount()
    }

    private async filterQuery(query: SelectQueryBuilder<LearnLesson>, filter: LearningLessonFilterInput) {
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