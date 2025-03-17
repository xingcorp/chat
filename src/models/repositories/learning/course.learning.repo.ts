import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, Repository } from "typeorm";
import { LearnCourse } from "@models/entities";
import { LearningCourseFilterInput } from "@modules/graphql/learning/course/dto/course.learning.arg";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";

@Injectable()
export class CourseLearningRepo extends Repository<LearnCourse> {
    constructor(private dataSource: DataSource) {
        super(LearnCourse, dataSource.createEntityManager());
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

    async getManyBy(where: any, relations: string[] = []) {
        let alias = 'qb';
        const query = this.createQueryBuilder(alias);
        const aliasMap = new Map<string, string>();

        relations.forEach(relation => {
            const path = relation.split('.');
            alias = 'qb';
            path.forEach((part) => {
                const parentAlias = alias;
                alias = `${parentAlias}_${part}`;

                if (!aliasMap.has(alias)) {
                    query.leftJoinAndSelect(`${parentAlias}.${part}`, alias);
                    aliasMap.set(alias, alias);
                }
            });
        });
        return query.where(where).getMany();
    }


    async listByFilter(filter: LearningCourseFilterInput) {
        const query = this.createQueryBuilder('qb')

        query.orderBy('qb.createdAt', 'DESC')

        await this.filterQuery(query, filter)

        return query.getManyAndCount()
    }

    private async filterQuery(query: SelectQueryBuilder<LearnCourse>, filter: LearningCourseFilterInput) {
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