import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, In, Repository } from "typeorm";
import { OfficeFilter } from "@models/entities";
import { ApprovalFilterCreateInput, ApprovalFilterListFilter } from "@modules/graphql/approval/approval.args";
import { FilterRelationType } from "@enum/filter/filter.enum";
import { RequestContext } from "@common/context/request.context";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";
import { TaskFilterList } from "@modules/graphql/task/task/dto/task.args";
import { TaskSpeciesEnum } from "@enum/task/task.enum";

@Injectable()
export class FilterRepo extends Repository<OfficeFilter> {
    constructor(private dataSource: DataSource) {
        super(OfficeFilter, dataSource.createEntityManager());
    }

    async userApprovalCreate(args: ApprovalFilterCreateInput) {
        return this.createNew({
            ...args,
            relationType: FilterRelationType.UserApproval,
        })
    }

    async taskCreate(args: ApprovalFilterCreateInput) {
        return this.createNew({
            ...args,
            relationType: FilterRelationType.Task,
        })
    }

    async taskReportCreate(args: ApprovalFilterCreateInput) {
        return this.createNew({
            ...args,
            relationType: FilterRelationType.TaskReport,
        })
    }

    async createNew(args: object) {
        const currentId = await RequestContext.currentId()

        return this.create({
            ...args,
            relationId: currentId,
            createdBy: currentId
        })
    }

    async userApprovalGetOneBy(where: any, relations?: string[]) {
        return this.getOneBy({
            ...where,
            relationType: FilterRelationType.UserApproval
        }, relations)
    }

    async taskGetOneBy(where: any, relations?: string[]) {
        return this.getOneBy({
            ...where,
            relationType: In([FilterRelationType.Task, FilterRelationType.TaskReport])
        }, relations)
    }


    async getOneBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getOne()
    }

    async userApprovalGetAllOfRequester() {
        return this.find({
            where: {
                relationType: FilterRelationType.UserApproval,
                relationId: await RequestContext.currentId()
            },
            order: {
                order: 'DESC'
            }
        })
    }

    async userApprovalListByFilter(filter: ApprovalFilterListFilter) {
        const query = this.createQueryBuilder('qb')
            .where({
                relationType: FilterRelationType.UserApproval,
                relationId: await RequestContext.currentId()
            })
            .orderBy('qb.order', 'DESC')

        await this.approvalFilterListByFilterQuery(query, filter)

        return query.getManyAndCount()
    }

    async taskListByFilter(filter: TaskFilterList) {
        const query = this.createQueryBuilder('qb')
            .where({
                relationType: filter.species === TaskSpeciesEnum.REPORT ? FilterRelationType.TaskReport : FilterRelationType.Task,
                relationId: await RequestContext.currentId()
            })
            .orderBy('qb.order', 'DESC')

        await this.taskFilterListByFilterQuery(query, filter)

        return query.getManyAndCount()
    }

    private async approvalFilterListByFilterQuery(query: SelectQueryBuilder<OfficeFilter>, filter: ApprovalFilterListFilter) {
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

    private async taskFilterListByFilterQuery(query: SelectQueryBuilder<OfficeFilter>, filter: TaskFilterList) {
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