import { RequestContext } from "@common/context/request.context";
import { LearnAddress } from "@models/entities/learning/address.learn";
import { AddressLearningFilterInput } from "@modules/graphql/learning/address/dto/address.learning.args";
import { LearningSkillFilterInput } from "@modules/graphql/learning/skill/dto/skill.learning.arg";
import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, Repository, SelectQueryBuilder } from "typeorm";

@Injectable()
export class AddressLearningRepo extends Repository<LearnAddress> {
    constructor(private dataSource: DataSource) {
        super(LearnAddress, dataSource.createEntityManager())
    }

    async createQueryBuilderWithCommonData(relations?: string[]): Promise<SelectQueryBuilder<LearnAddress>> {
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


    async getManyBy(where: any, relations?: string[]) {
        const query = await this.createQueryBuilderWithCommonData(relations)

        return query
            .where(where)
            .getMany()
    }

    async getBy(where: any, relations?: string[]) {
        const query = await this.createQueryBuilderWithCommonData(relations)

        return query
            .where(where)
            .getOne()
    }

    async listByFilter(filter: AddressLearningFilterInput) {
        const query = await this.createQueryBuilderWithCommonData()

        query.orderBy('qb.createdAt', 'DESC')

        await this.filterQuery(query, filter)

        return query.getManyAndCount()
    }

    private async filterQuery(query: SelectQueryBuilder<LearnAddress>, filter: AddressLearningFilterInput) {
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
            }))
        }
    }

}