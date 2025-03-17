import { Injectable } from "@nestjs/common";
import {
    Brackets,
    DataSource,
    FindOptionsUtils,
    In,
    IsNull,
    Not,
    Repository,
    Or,
    LessThanOrEqual,
    MoreThan
} from "typeorm";
import { OfficeTask } from "@models/entities";
import { TaskListFilter, TaskReportConfigList } from "@modules/graphql/task/task/dto/task.args";
import { TASK_WATCHER_BRIDGE_TABLE } from "@models/entities/task/task";
import {
    TaskComplete,
    TaskKindEnum,
    TaskPriority,
    TaskQuickSearchEnum, TaskSpeciesEnum,
    TaskStatus,
    TaskTypeEnum
} from "@enum/task/task.enum";
import { RequestContext } from "@common/context/request.context";
import { BRIDGE_TABLE_DB } from "@common/db/bridge-table.db";
import { enumGetKey, enumTextGetKeys } from "@utils/enum.utils";

@Injectable()
export class OfficeTaskRepo extends Repository<OfficeTask> {
    constructor(
        private dataSource: DataSource
    ) {
        super(OfficeTask, dataSource.createEntityManager());
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

    getManyBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getMany()
    }

    private getValidTasks(rootOrgId: string, userId: string) {
        const query = this.createQueryBuilder('qb')
            .leftJoinAndSelect('qb.project', 'project')
            .leftJoinAndSelect('qb.reporter', 'reporter')
            .leftJoinAndSelect('qb.creator', 'creator')
            .leftJoinAndSelect('qb.assigned', 'assigned')
            .leftJoinAndSelect('qb.assignees', 'assignees')
            .leftJoinAndSelect('qb.watchers', 'watchers')
            .leftJoinAndSelect(TASK_WATCHER_BRIDGE_TABLE, 'wBridge', '"wBridge"."officeTasksId" = qb.id')
            .leftJoinAndSelect(BRIDGE_TABLE_DB.TASK_CONFIG_ASSIGNEES, 'wBridgeAssign', '"wBridgeAssign"."officeTasksId" = qb.id')
            .where({
                project: {
                    rootOrg: {
                        id: rootOrgId,
                    }
                }
            })
            .andWhere(new Brackets(db => {
                db
                    .where({
                        creator: {
                            id: userId,
                        }
                    })
                    .orWhere({
                        reporter: {
                            id: userId,
                        }
                    })
                    .orWhere({
                        assigned: {
                            id: userId,
                        }
                    })
                    .orWhere(`"wBridge"."officeUsersId" = :userIdWatch`, { userIdWatch: userId })
                    .orWhere(`"wBridgeAssign"."officeUsersId" = :userIdAssign`, { userIdAssign: userId })
            }))

        return query
    }

    async getListAndCountByFilter(params: { rootOrgId: string; userId: string }, filter: TaskListFilter) {
        const query = await this.getCommonFilterQuery(params, filter)

        filter.size = filter.size ? filter.size : 20
        filter.page = filter.page ? (filter.page - 1) : 0

        query
            .take(filter.size)
            .skip(filter.page * filter.size)
            .orderBy('qb.createdAt', 'DESC')

        return query.getManyAndCount()
    }

    async getStatisticByFilter(params: { rootOrgId: string; userId: string }, filter: TaskListFilter) {
        const query = await this.getCommonFilterQuery(params, filter, true)

        const selects = []
        for (const key of enumTextGetKeys(TaskStatus)) {
            selects.push(`count(distinct case when "qb"."status" = '${TaskStatus[key]}' then "qb"."id" end) as "${TaskStatus[key]}"`)
        }

        query.select(selects)

        const [data] = await query.execute()

        const res = []
        for (const key of enumTextGetKeys(TaskStatus)) {
            if (key === enumGetKey(TaskStatus, TaskStatus.Undefined)) continue

            res.push({
                status: key,
                count: parseInt(data[key])
            })
        }

        return res
    }


    async getListAndCountAndStatisticByFilter(params: { rootOrgId: string; userId: string }, filter: TaskListFilter) {
        const [data, total] = await this.getListAndCountByFilter(params, structuredClone(filter))
        const statistics = await this.getStatisticByFilter(params, structuredClone(filter))

        return {
            data,
            total,
            statistics
        }
    }

    async getCommonFilterQuery(params: { rootOrgId: string; userId: string }, filter: TaskListFilter, forStatistic: boolean = false) {
        const { rootOrgId, userId } = params
        const requester = await RequestContext.currentUser()

        const query = this.getValidTasks(rootOrgId, userId)

        await this.updateFilter(filter)

        if (filter && filter.keyword) {
            query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(project.key || '-' || qb."keyPostfix")) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                    .orWhere(`unaccent(LOWER(qb."keyPostfix")) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                    .orWhere(`unaccent(LOWER(qb.title)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                // .orWhere(`unaccent(LOWER(qb.description)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
            }))
        }

        if (filter && filter.creatorIds && filter.creatorIds.length) {
            query.andWhere({
                creator: {
                    id: In(filter.creatorIds),
                },
                taskKind: Or(Not(TaskKindEnum.ReportChild), IsNull()),
            })
        }

        if (filter && filter.reportedIds && filter.reportedIds.length) {
            query.andWhere({
                reporter: {
                    id: In(filter.reportedIds),
                },
                taskKind: Or(Not(TaskKindEnum.ReportChild), IsNull()),
            })
        }

        if (filter && filter.assignedIds && filter.assignedIds.length) {
            query
                .andWhere(new Brackets(db => {
                    db
                        .where({
                            assigned: {
                                id: In(filter.assignedIds),
                            }
                        })
                        .orWhere(new Brackets(db => {
                            db.where({
                                taskKind: Not(TaskKindEnum.ReportParent),
                            })
                                .andWhere(`"wBridgeAssign"."officeUsersId" IN  (:...assignedIds)`, { assignedIds: filter.assignedIds })
                        }))
                }))
        }


        if (filter && filter.watchersIds && filter.watchersIds.length) {
            query
                .andWhere(new Brackets(db => {
                    db.where({
                        reporter: {
                            id: Or(Not(requester?.id), IsNull()),
                        },
                        assigned: {
                            id: Or(Not(requester?.id), IsNull()),
                        },
                        creator: {
                            id: Or(Not(requester?.id), IsNull()),
                        },
                    })
                        .andWhere(`"wBridge"."officeUsersId"::text IN (:...watcherIds)`, { watcherIds: filter.watchersIds })
                }))
        }

        if (filter && filter.status && !forStatistic) {
            let statuses = [{
                status: In(filter.status)
            }]
            if (filter.status.includes(TaskStatus.Undefined)) {
                statuses.push({
                    status: IsNull()
                })
            }
            query.andWhere(statuses)
        }

        if (filter && filter.priority) {
            let priorities = [{
                priority: In(filter.priority)
            }]
            if (filter.priority.includes(TaskPriority.Undefined)) {
                priorities.push({
                    priority: IsNull()
                })
            }
            query.andWhere(priorities)
        }

        if (filter && filter.startTime) {
            if (filter.startTime.start) query.andWhere(`qb."startTime" >= :startTimeStart`, { startTimeStart: new Date(filter.startTime.start).toISOString() })
            if (filter.startTime.end) query.andWhere(`qb."startTime" <= :startTimeEnd`, { startTimeEnd: new Date(filter.startTime.end).toISOString() })
        }

        if (filter && filter.finishTime) {
            if (filter.finishTime.start) query.andWhere(`qb."finishTime" >= :finishTimeStart`, { finishTimeStart: new Date(filter.finishTime.start).toISOString() })
            if (filter.finishTime.end) query.andWhere(`qb."finishTime" <= :finishTimeEnd`, { finishTimeEnd: new Date(filter.finishTime.end).toISOString() })
        }

        if (filter && typeof filter.isLate === 'boolean') {
            if (filter.isLate) {
                query.andWhere(`qb."finishTime" < :nowTime`, { nowTime: new Date().toISOString() })
                    .andWhere({
                        status: Not(In([TaskStatus.Done, TaskStatus.Cancel, TaskStatus.Reject]))
                    })
            } else {
                query.andWhere(new Brackets(db => {
                    db.where(`qb."finishTime" >= :nowTime`, { nowTime: new Date().toISOString() })
                        .orWhere(`qb."finishTime" IS NULL`)
                        .orWhere({
                            status: In([TaskStatus.Done, TaskStatus.Cancel, TaskStatus.Reject])
                        })
                }))
            }
        }

        if (filter && filter.complete) {
            query.andWhere({
                status: TaskStatus.Done
            })

            switch (filter.complete) {
                case TaskComplete.In_Time:
                    query
                        .andWhere(`qb."doneAt" <= qb."finishTime"`)
                        .andWhere({
                            doneAt: Not(IsNull())
                        })
                    break
                case TaskComplete.Late:
                    query
                        .andWhere(`qb."doneAt" > qb."finishTime"`)
                        .andWhere({
                            doneAt: Not(IsNull())
                        })
                    break
            }
        }


        if (filter && filter.taskTypes && filter.taskTypes.length) {
            query.andWhere({
                taskType: In(filter.taskTypes)
            })
        }

        if (filter && filter.templateTaskIds && filter.templateTaskIds.length) {
            query.andWhere([
                {
                    templateTask: {
                        id: In(filter.templateTaskIds)
                    }
                },
                {
                    id: In(filter.templateTaskIds)
                }
            ])
        }

        if (filter && filter.excludeLinkedTaskId) {
            const linkedTasks = await this.getBy({ id: filter.excludeLinkedTaskId }, ['linkTasks'])
            query.andWhere({
                id: Not(In(linkedTasks.linkTasks.map(i => i.id)))
            })
        }
        return query
    }

    async reportConfigList(filter: TaskReportConfigList) {
        const query = this.getValidTasks(await RequestContext.getRootOrgId(), await RequestContext.currentId())
            .andWhere({
                taskType: TaskTypeEnum.ReportConfig
            })
            .orderBy('qb.createdAt', 'DESC')

        /*default get all*/
        if (filter.page || filter.size) {
            filter.size = filter.size ? filter.size : 20 //1
            filter.page = filter.page ? (filter.page - 1) : 0

            query.limit(filter.size)
                .offset(filter.page * filter.size)
        }

        if (filter && filter.keyword) {
            query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(project.key || '-' || qb."keyPostfix")) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                    .orWhere(`unaccent(LOWER(qb."keyPostfix")) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                    .orWhere(`unaccent(LOWER(qb.title)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                // .orWhere(`unaccent(LOWER(qb.description)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
            }))
        }

        return query.getManyAndCount()
    }

    async getValidById(params: { rootOrgId: string; userId: string }, id: string) {
        const { rootOrgId, userId } = params

        return this.getValidTasks(rootOrgId, userId).andWhere({ id }).getOne()
    }

    async genKey(task: OfficeTask) {
        const prefix = task?.project?.showKey ? `${task?.project?.key}-` : ''
        return `${prefix}${task?.keyPostfix ?? task?.no}`
    }

    async getKey(task: OfficeTask) {
        const _self = await this.findOne({
            relations: ['project'],
            where: {
                id: task.id
            }
        })

        return this.genKey(_self)
    }

    async getKeyById(id: string) {
        const _self = await this.findOne({
            relations: ['project'],
            where: {
                id
            }
        })

        return this.genKey(_self)
    }

    async listNeedToDoneInTime() {
        return this.find({
            relations: ['assigned', 'reporter', 'project'],
            where: {
                status: Not(In([TaskStatus.Done, TaskStatus.Cancel, TaskStatus.Reject])),
                finishTime: MoreThan(new Date()),
                assigned: Not(IsNull())
            }
        })
    }

    async listLate() {
        return this.find({
            relations: ['assigned', 'reporter', 'project'],
            where: {
                status: Not(In([TaskStatus.Done, TaskStatus.Cancel, TaskStatus.Reject])),
                finishTime: LessThanOrEqual(new Date()),
                assigned: Not(IsNull())
            }
        })
    }

    async getAllChildrenTaskOfTaskId(id: string) {
        return this.find({
            where: {
                parentTask: { id }
            }
        })
    }

    private async updateFilter(filter: TaskListFilter) {
        const userId = await RequestContext.currentId()
        if (filter && filter.species) {
            let types: TaskTypeEnum[]
            switch (filter.species) {
                case TaskSpeciesEnum.REPORT:
                    types = [TaskTypeEnum.Report, TaskTypeEnum.ReportArise, TaskTypeEnum.ReportConfig]
                    break
                case TaskSpeciesEnum.TASK:
                    types = [TaskTypeEnum.Task]
                    break
            }

            if (filter.taskTypes && filter.taskTypes.length) {
                filter.taskTypes = types.filter(i => filter.taskTypes.includes(i))
            } else {
                filter.taskTypes = types
            }
        }

        if (filter && filter.quickSearches && filter.quickSearches.length) {
            if (filter.quickSearches.includes(TaskQuickSearchEnum.ASSIGN_TO_ME)) {
                if (filter.assignedIds && filter.assignedIds.length) {
                    filter.assignedIds.push(userId)
                } else {
                    filter.assignedIds = [userId]
                }
            }

            if (filter.quickSearches.includes(TaskQuickSearchEnum.IM_REPORT)) {
                if (filter.reportedIds && filter.reportedIds.length) {
                    filter.reportedIds.push(userId)
                } else {
                    filter.reportedIds = [userId]
                }
            }

            if (filter.quickSearches.includes(TaskQuickSearchEnum.IM_CREATED)) {
                if (filter.creatorIds && filter.creatorIds.length) {
                    filter.creatorIds.push(userId)
                } else {
                    filter.creatorIds = [userId]
                }
            }

            if (filter.quickSearches.includes(TaskQuickSearchEnum.IM_WATCHED)) {
                if (filter.watchersIds && filter.watchersIds.length) {
                    filter.watchersIds.push(userId)
                } else {
                    filter.watchersIds = [userId]
                }
            }
        }
    }
}

