import { forwardRef, Inject, Injectable } from '@nestjs/common';
import {
    DateCloneRepo,
    FilterRepo,
    OfficeTaskLogRepo,
    OfficeTaskProjectRepo,
    OfficeTaskRepo,
    OfficeUserRepo
} from "@repositories/index";
import {
    TaskCreateInput,
    TaskFilterCreateInput, TaskFilterList, TaskFilterUpdateInput,
    TaskListFilter, TaskReportConfigList,
    TaskStatusUpdateInput,
    TaskUpdateInput
} from "@modules/graphql/task/task/dto/task.args";
import { CloneByDate, OfficeFilter, OfficeOrgChart, OfficeTask, OfficeUser } from "@models/entities";
import { OfficeError } from "@common/office.error";
import { DataSource, In, IsNull, Not } from "typeorm";
import {
    TaskAction,
    TaskKindEnum,
    TaskPriority,
    TaskSpeciesEnum,
    TaskStatus,
    TaskTypeEnum
} from "@enum/task/task.enum";
import { StorageService } from "@core/storage/storage.service";
import { CACHE_KEY } from "@common/cache-key.common";
import { seedUpdateTaskKey } from "@models/seeds/task/task.seed";
import { RedisService } from "@core/common/redis.service";
import { seedUpdateProjectData } from "@models/seeds/task/project.task.seed";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";
import { NotificationService } from "@core/iam/notification/notification.service";
import {
    datetimeDateRoundToHourGet, datetimeDateRoundToMinuteGet, datetimeGetNextDateByDays,
    datetimeGetNextDateByHours,
    datetimeOfLocalDayToString
} from "@utils/datetime.utils";
import { sleep } from "@utils/common.utils";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import { CloneDatePeriodTitleEnum, CloneDateTypeEnum } from "@enum/clone/date.clone.enum";
import { RequestContext } from "@common/context/request.context";
import { difference } from 'lodash';
import { LoggerService } from '@core/common/logger.service';

@Injectable()
export class TaskService {
    logger = new LoggerService(TaskService.name)
    private notifyType: string;
    private notifyTitle: string;
    private notifyContent: string;
    private metadata: { taskId: string; key: string };
    private receiverIds: string[];
    private requester: string;

    constructor(
        private dataSource: DataSource,
        private readonly officeTaskRepo: OfficeTaskRepo,
        private readonly officeTaskProjectRepo: OfficeTaskProjectRepo,
        private readonly officeUserRepo: OfficeUserRepo,
        private readonly officeTaskLogRepo: OfficeTaskLogRepo,
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        @Inject(forwardRef(() => RedisService))
        private readonly redisService: RedisService,
        private readonly dateCloneRepo: DateCloneRepo,
        private readonly filterRepo: FilterRepo,
    ) {
    }

    private async validateAndGetTask(id: string) {
        const task = await this.officeTaskRepo.findOne({
            relations: ['creator', 'reporter', 'assigned', 'watchers', 'assignees', 'linkTasks'],
            where: { id }
        })
        if (!task) {
            throw OfficeError.TaskNotExist
        }

        return task
    }

    private async validateAndGetExistUser(ids: string | string[]) {
        let isArray = true
        if (!Array.isArray(ids)) {
            isArray = false
            ids = [ids]
        }

        ids = arrayConvertToDistinctAndNotNull(ids)

        const users = await this.officeUserRepo.findBy({ id: In(ids) })
        if (!users.length || users.length !== ids.length) {
            throw OfficeError.SysUserNotExisted
        }

        return isArray ? users : users[0]
    }

    private async cannotUpdateDoneOrCancelTask(task: OfficeTask) {
        if (task.taskType === TaskTypeEnum.ReportConfig) return

        switch (task.status) {
            case TaskStatus.Done:
                throw OfficeError.TaskNotAllowEditDoneTask
            case TaskStatus.Cancel:
                throw OfficeError.TaskNotAllowEditCancelTask
            default:
        }
    }


    private async checkUserPermissionToUpdateTask(userId: string, task: OfficeTask, rootOrgId: string, subscriberCanDo: boolean) {
        if (
            ![
                ...(subscriberCanDo ? task.watchers.map(i => i.id) : []),
                ...(task.assignees?.length ? task.assignees.map(i => i.id) : []),
                task.reporter.id, task?.assigned?.id, task?.creator?.id
            ].includes(userId)
            || task.project.rootOrg.id !== rootOrgId
        ) {
            throw OfficeError.TaskUserNotHavePermission
        }
    }

    async validateTaskAndUser(taskId: string, userId: string, rootOrgId: string, subscriberCanDo: boolean = false) {
        /*check task*/
        const task = await this.validateAndGetTask(taskId)

        /*check user*/
        const user = (await this.validateAndGetExistUser(userId)) as OfficeUser

        await this.checkUserPermissionToUpdateTask(user.id, task, rootOrgId, subscriberCanDo)

        return { task, user }
    }

    async create(params: { userId: string; rootOrg: OfficeOrgChart, token: string }, args: TaskCreateInput) {

        const task = await this.taskNormalDataCreate(params, args)
        await task.save()

        if (args.taskType === TaskTypeEnum.ReportConfig) {
            await this.taskConfigDataCreate(task, args)
        }

        /*create office-log create task*/
        await this.officeTaskLogRepo.storeHistoryTaskCreate(task)

        await task.reload()
        return task
    }

    async update(params: { rootOrg: OfficeOrgChart; userId: string, token: string }, args: TaskUpdateInput) {
        const { rootOrg, userId, token } = params

        /*default priority*/
        if (!args.priority || args.priority === TaskPriority.Undefined) args.priority = TaskPriority.Medium

        /*validate*/
        const { task, user } = await this.validateTaskAndUser(args.id, userId, rootOrg.id)

        await this.cannotUpdateDoneOrCancelTask(task)

        if (
            !(args.startTime && args.finishTime)
            && ((args.startTime && task.finishTime && new Date(args.startTime) > task.finishTime)
                || (args.finishTime && task.startTime && new Date(args.finishTime) < task.startTime))
        ) {
            throw OfficeError.WrongDatePeriod
        }

        /*update*/
        return this.updateTask(task, args, { userId, token });
    }

    private async updateTask(task: OfficeTask, args: TaskUpdateInput, params: { userId: string, token: string }) {

        await this.taskNormalDataUpdate(task, params, args)

        if (task.taskType === TaskTypeEnum.ReportConfig) {
            await this.taskConfigDataUpdate(task, args)
        }

        await task.reload()
        return task

    }

    async list(params: { rootOrg: OfficeOrgChart; userId: string }, args: TaskListFilter) {
        const { data, total, statistics } = await this.officeTaskRepo.getListAndCountAndStatisticByFilter({
            rootOrgId: params.rootOrg.id,
            userId: params.userId
        }, args)

        return {
            total: total as number,
            count: data.length,
            records: data,
            statistics
        }
    }

    async get(params: { rootOrg: OfficeOrgChart; userId: string }, id: string) {
        return this.officeTaskRepo.getValidById({
            rootOrgId: params.rootOrg.id,
            userId: params.userId
        }, id);
    }

    private async logObserverUsersChange(task: OfficeTask, keyChange: string, oldVal: OfficeUser[], newVal: OfficeUser[]) {
        const data = {
            creator: await RequestContext.currentUser(),
            task,
            logs: [
                {
                    action: TaskAction.Update,
                    actionAt: new Date().getTime(),
                    field: keyChange,
                    oldValue: oldVal.map(i => ({
                        id: i.id,
                        fullname: i.fullname,
                        code: i.code,
                        phone: i.phone,
                    })),
                    newValue: newVal.map(i => ({
                        id: i.id,
                        fullname: i.fullname,
                        code: i.code,
                        phone: i.phone,
                    })),
                }
            ]
        }

        return this.officeTaskLogRepo.storeHistoryTaskUpdate(data)
    }

    private async logUpdateWatchers(task: OfficeTask, watchers: OfficeUser[], newWatchers: OfficeUser[]) {
        return this.logObserverUsersChange(task, 'watchers', watchers, newWatchers)
    }

    private async logUpdateAssignees(task: OfficeTask, assignees: OfficeUser[], newAssignees: OfficeUser[]) {
        return this.logObserverUsersChange(task, 'assignees', assignees, newAssignees)
    }

    async seedDataForNewCr() {
        console.log('seedUpdateTaskKey, seed new task data after deploy 10 sec')
        if (!process.env.K_ORG_ID) return
        const key = CACHE_KEY.SEED.seedUpdateTaskKey
        const cached = await this.redisService.get(key)
        // await this.redisService.delete(key)

        if (cached !== undefined && parseInt(cached) === 0) {
            return
        }

        console.log('seedUpdateTaskKey', key, cached)
        await seedUpdateProjectData()
        const count = await seedUpdateTaskKey()
        console.log('seedUpdateTaskKey done')

        await this.redisService.set(key, count)
    }

    private notify() {
        return this.notificationService.systemDestinationPush(
            this.notifyType,
            this.notifyTitle,
            this.notifyContent,
            '',
            JSON.stringify(this.metadata),
            this.receiverIds,
            null,
            process.env.OFFICE_ORGANIZATION_ID,
            this.requester
        )
    }

    async notifyTaskNeedToDoneInTime() {
        console.log('notifyTaskNeedToDoneInTime', new Date())

        /*const key = CACHE_KEY.TASK.NOTIFY.NEED_TO_DO
        const cached = await this.redisService.get(key)
        const val = datetimeGetFormat('DD/MM HH:00', new Date())

        if (cached.toString() === val.toString()) {
            return
        }
        await this.redisService.set(key, val)*/

        try {
            const tasks = await this.officeTaskRepo.listNeedToDoneInTime()
            console.log('notifyTaskNeedToDoneInTime data', tasks.length)

            this.notifyType = NotifyType.Task.Notify.NeedToDone
            for (const task of tasks) {
                try {
                    const key = await this.officeTaskRepo.genKey(task)
                    // console.log('notifyTaskNeedToDoneInTime task', task.id, key)
                    this.notifyTitle = NotifyMessageTitle.Task.Notify.NeedToDone({ ...task, key })
                    this.notifyContent = NotifyMessageContent.Task.Notify.NeedToDone({ ...task, key })
                    this.metadata = { taskId: task.id, key }
                    this.receiverIds = [task.assigned.id]
                    this.requester = task.reporter.id

                    this.notify()
                    await sleep(1000)
                } catch (e) {
                    console.log('notifyTaskNeedToDoneInTime err', e)
                }
            }
            console.log('notifyTaskNeedToDoneInTime done')
        } catch (e) {
            console.log('notifyTaskNeedToDoneInTime err1', e)
        }
    }

    async notifyTaskLate() {
        console.log('notifyTaskLate', new Date())

        /*const key = CACHE_KEY.TASK.NOTIFY.LATE
        const cached = await this.redisService.get(key)
        const val = datetimeGetFormat('DD/MM HH:00', new Date())

        if (cached.toString() === val.toString()) {
            return
        }
        await this.redisService.set(key, val)*/

        try {
            const tasks = await this.officeTaskRepo.listLate()
            console.log('notifyTaskLate data', tasks.length)

            this.notifyType = NotifyType.Task.Notify.Late
            for (const task of tasks) {
                try {
                    const key = await this.officeTaskRepo.genKey(task)
                    // console.log('notifyTaskLate task', task.id, key)
                    this.notifyTitle = NotifyMessageTitle.Task.Notify.Late({ ...task, key })
                    this.notifyContent = NotifyMessageContent.Task.Notify.Late({ ...task, key })
                    this.metadata = { taskId: task.id, key }
                    this.receiverIds = [task.assigned.id]
                    this.requester = task.reporter.id

                    this.notify()
                    await sleep(1000)
                } catch (e) {
                    console.log('notifyTaskLate err', e)
                }
            }

            console.log('notifyTaskLate done')
        } catch (e) {
            console.log('notifyTaskLate err1', e)
        }
    }

    private async taskNormalDataCreate(params: {
        userId: string;
        rootOrg: OfficeOrgChart;
        token: string
    }, args: TaskCreateInput) {
        const { userId, rootOrg, token } = params

        /*default priority*/
        if (!args.priority || args.priority === TaskPriority.Undefined) args.priority = TaskPriority.Medium

        /*create*/
        const { assignedId, watcherIds } = args

        delete args.assignedId
        delete args.watcherIds

        const task = this.officeTaskRepo.create({
            ...args,
            startTime: args.startTime ? new Date(args.startTime) : null,
            finishTime: args.finishTime ? new Date(args.finishTime) : null,
        })

        /*add project*/
        let project = await this.officeTaskProjectRepo.getFirstByOrgId(rootOrg.id)
        if (!project) {
            project = this.officeTaskProjectRepo.createDefault()

            project.rootOrg = rootOrg
        }
        task.project = project

        /*add creator*/
        task.creator = await this.validateAndGetExistUser(userId) as OfficeUser

        /*add reporter*/
        task.reporter = args.reporterId ? await this.validateAndGetExistUser(args.reporterId) as OfficeUser : task.creator

        /*add assigned*/
        if (assignedId) {
            task.assigned = await this.validateAndGetExistUser(assignedId) as OfficeUser
        }

        /*add list assigned*/
        if (args.assignedIds) {
            task.assignees = await this.validateAndGetExistUser(args.assignedIds) as OfficeUser[]
        }

        /*add link tasks*/
        if (args.linkTaskIds) {
            task.linkTasks = args.linkTasks
            const linkTasks = await this.officeTaskRepo.getManyBy({ id: In(args.linkTaskIds) }, ['linkTasks'])
            for (const linkTask of linkTasks) {
                linkTask.linkTasks = [...linkTask.linkTasks, task]
                await linkTask.save()
            }
        }

        /*add watchers*/
        task.watchers = await this.officeUserRepo.getManyByIds([...new Set(watcherIds ?? [])])

        /*add attachments*/
        args['attachmentUrls'] = []
        if (args.attachmentIds) {
            for (const attachmentId of args.attachmentIds) {
                const { data, error } = await this.storageService.getFileDetail(token, attachmentId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted

                args['attachmentUrls'].push(data.location)
            }
        }
        task.attachmentUrls = args['attachmentUrls']
        task.createdBy = task.creator.id
        task.updatedBy = task.creator.id

        /*save*/
        /*await this.dataSource.manager.transaction(async entity => {
            await entity.save(project)
            await entity.save(task)
        })*/

        await this.dataSource.manager.save(project)

        return task;
    }

    private async taskConfigDataCreate(task: OfficeTask, args: TaskCreateInput) {
        const cloneConfig = this.dateCloneRepo.create({
            ...args.config,
            startAt: args?.config?.startAt ? new Date(args.config.startAt) : null,
            endAt: args?.config?.endAt ? new Date(args.config.endAt) : null,
        })

        cloneConfig.relationId = task.id
        cloneConfig.relationType = CloneDateTypeEnum.TaskReportConfig
        cloneConfig.relationData = {
            workDays: args?.config?.workDays ?? null,
        }
        cloneConfig.createdBy = RequestContext.currentId()

        await cloneConfig.save()
    }

    private async taskNormalDataUpdate(task: OfficeTask, params: { userId: string; token: string }, args: TaskUpdateInput) {
        const { userId, token } = params

        if (args.linkTaskIds !== undefined) {
            args.linkTasks = args.linkTasks ?? []
            const oldIds = task.linkTasks?.map(i => i.id) || [];
            const removedIds = difference(oldIds, args.linkTaskIds || []);
            const addedIds = difference(args.linkTaskIds || [], oldIds);
            if (removedIds.length || addedIds.length) {
                const linkTasksToUpdate = await this.officeTaskRepo.getManyBy({ id: In([...removedIds, ...addedIds]) }, ['linkTasks'])
                task.linkTasks = linkTasksToUpdate;

                // Batch update removed and added tasks
                const updatePromises = [];
                if (removedIds.length) {
                    const removeLinkTasks = linkTasksToUpdate.filter(t => removedIds.includes(t.id));
                    updatePromises.push(...removeLinkTasks.map(removeLinkTask => {
                        removeLinkTask.linkTasks = removeLinkTask.linkTasks?.filter(i => i.id !== task.id);
                        return removeLinkTask.save();
                    }));
                }

                if (addedIds.length) {
                    const addLinkTasks = linkTasksToUpdate.filter(t => addedIds.includes(t.id));
                    updatePromises.push(...addLinkTasks.map(addLinkTask => {
                        addLinkTask.linkTasks = [...addLinkTask.linkTasks, task];
                        return addLinkTask.save();
                    }));
                }

                await Promise.all(updatePromises);
            }

            task.linkTasks = args.linkTasks;
        }

        if (args.watcherIds !== undefined) {
            args.watcherIds = args.watcherIds ?? []
            const oldIds = task.watchers ? task.watchers.map(i => i.id) : []

            if (
                difference(oldIds, args.watcherIds).length
                || difference(args.watcherIds, oldIds).length
            ) {
                const newWatchers = await this.officeUserRepo.getManyByIds(args.watcherIds)

                /*observer*/
                await this.logUpdateWatchers(task, task.watchers, newWatchers || [])

                /*change*/
                task.watchers = newWatchers
            }
        }

        /*add list assigned*/
        if (args.assignedIds !== undefined) {

            if (!args.assignedIds || !args.assignedIds.length) {
                task.assignees = []
            } else {
                const oldIds = task.assignees.map(i => i.id)

                if (
                    oldIds.filter(i => !args.assignedIds.includes(i)).length
                    || args.assignedIds.filter(i => !oldIds.includes(i)).length
                ) {
                    const newAssignees = await this.officeUserRepo.getManyByIds(args.assignedIds)

                    /*observer*/
                    await this.logUpdateAssignees(task, task.assignees, newAssignees)

                    /*change*/
                    task.assignees = newAssignees
                }
            }
        }

        if (
            ((task.assigned && args.assignedId && args.assignedId !== task?.assigned?.id)
                || (task.reporter && args.reporterId && args.reporterId !== task?.reporter?.id))
            && task.taskType !== TaskTypeEnum.ReportConfig
        ) {
            task.watchers = [...new Set([...task.watchers, task.assigned, task.reporter])]
        }

        if (args.assignedId !== undefined) {
            if (args.assignedId === null) {
                task.assigned = null
            }
            if (args.assignedId) {
                task.assigned = await this.validateAndGetExistUser(args.assignedId) as OfficeUser
            }
        }

        if (args.reporterId !== undefined) {
            if (args.reporterId === null) {
                task.reporter = null
            }
            if (args.assignedId) {
                task.reporter = await this.validateAndGetExistUser(args.reporterId) as OfficeUser
            }
        }

        args['attachmentUrls'] = []
        if (args.attachmentIds) {
            for (const attachmentId of args.attachmentIds) {
                const { data, error } = await this.storageService.getFileDetail(token, attachmentId)
                if (error) throw error
                if (!data) throw OfficeError.FileNotExisted

                args['attachmentUrls'].push(data.location)
            }

            task.attachmentUrls = args['attachmentUrls']
            task.attachmentIds = args.attachmentIds
        }

        task.title = args.title ?? task.title
        task.description = args.description ?? task.description
        task.status = args.status ?? task.status
        task.priority = args.priority ?? task.priority
        task.startTime = args.startTime ? new Date(args.startTime) : task.startTime
        task.finishTime = args.finishTime ? new Date(args.finishTime) : task.finishTime
        task.updatedBy = userId

        return this.officeTaskRepo.save(task)
    }

    private async taskConfigDataUpdate(task: OfficeTask, args: TaskUpdateInput) {
        const configs = args?.config
        const cloneConfig = await this.dateCloneRepo.taskReportConfigGetOneBy({
            relationId: task.id
        })

        if (!cloneConfig) {
            throw OfficeError.CloneConfigNotFound
        }

        cloneConfig.updatedBy = RequestContext.currentId()
        cloneConfig.periodType = configs?.periodType ?? cloneConfig.periodType
        cloneConfig.startTimeIn = configs?.startTimeIn ?? cloneConfig.startTimeIn
        cloneConfig.timeZone = configs?.timeZone ?? cloneConfig.timeZone
        cloneConfig.weekDays = configs?.weekDays ?? cloneConfig.weekDays
        cloneConfig.monthDays = configs?.monthDays ?? cloneConfig.monthDays
        cloneConfig.startAt = (configs?.startAt ? new Date(configs?.startAt) : null) ?? cloneConfig.startAt
        cloneConfig.endAt = (configs?.endAt ? new Date(configs?.endAt) : null) ?? cloneConfig.endAt
        cloneConfig.customDays = configs?.customDays ?? cloneConfig.customDays

        if (args?.config?.workDays) {
            cloneConfig.relationData = {
                workDays: args.config.workDays,
            }
        }

        await cloneConfig.save()
    }

    async taskReportCreate() {
        const now = datetimeDateRoundToMinuteGet(new Date())
        const configs = await this.dateCloneRepo.getAllHaveCloneRightNowByRelationType(CloneDateTypeEnum.TaskReportConfig)

        // console.log('taskReportCreate config', configs.length, configs)

        if (!configs.length) return

        for (const config of configs) {
            const template = await this.officeTaskRepo.findOne({
                relations: ['creator', 'reporter', 'assigned', 'watchers', 'assignees'],
                where: {
                    id: config.relationId,
                    status: Not(In([TaskStatus.Pending, TaskStatus.Reject, TaskStatus.Cancel]))
                }
            })

            console.log('taskReportCreate template', template)

            if (!template || !template.assignees?.length) continue

            await this.taskReportClone(template, config, now)
        }
    }

    private async taskReportClone(configTask: OfficeTask, cloneConfig: CloneByDate, now: Date = new Date()) {
        const template: OfficeTask = structuredClone(configTask)

        delete template.id
        delete template.assignees
        delete template.clonesTask
        delete template.logs

        template.startTime = now
        template.createdAt = now
        template.updatedAt = now
        template.taskType = TaskTypeEnum.Report
        template.status = TaskStatus.Todo
        template.creator = template.reporter

        /*to gen name*/
        template.title = template.title
            + ` - ` + CloneDatePeriodTitleEnum[cloneConfig.periodType]
            + ` - ` + datetimeOfLocalDayToString('DDMMYYYY', now)

        if (cloneConfig.relationData?.workDays) {
            template.finishTime = datetimeGetNextDateByDays(now, +cloneConfig.relationData?.workDays)
        }

        let parentTask = structuredClone(template)
        parentTask.templateTask = configTask
        parentTask = await this.taskReportCreateNew(parentTask)

        for (const assigned of configTask.assignees) {
            let reportTask = structuredClone(template)

            reportTask.title = reportTask.title + ' - ' + assigned.fullname
            reportTask.assigned = assigned

            await this.taskReportCreateNew(reportTask, parentTask)
        }
    }

    private async taskReportCreateNew(reportTask: OfficeTask, parentTask?: OfficeTask) {
        await this.removeReportTemplateData(reportTask)

        reportTask = this.officeTaskRepo.create(reportTask)

        reportTask.parentTask = parentTask

        if (parentTask) {
            reportTask.taskKind = TaskKindEnum.ReportChild
        } else {
            reportTask.taskKind = TaskKindEnum.ReportParent
        }

        await reportTask.save()
        await reportTask.reload()

        console.log('reportTask', reportTask)

        await this.officeTaskLogRepo.storeHistoryTaskCreate(reportTask)

        return reportTask
    }

    async taskFilterCreate(args: TaskFilterCreateInput) {
        const species = args.species
        delete args.species

        let filter: OfficeFilter
        switch (species) {
            case TaskSpeciesEnum.REPORT:
                filter = await this.filterRepo.taskReportCreate(args)
                break
            case TaskSpeciesEnum.TASK:
                filter = await this.filterRepo.taskCreate(args)
                break
        }

        await filter.save()

        return filter;
    }

    async taskFilterUpdate(args: TaskFilterUpdateInput) {
        const item = args.taskFilter

        item.name = args.name ?? item.name
        item.filter = args.filter ?? item.filter

        await item.save()

        return item
    }

    async taskFilterRemove(id: string) {
        const userId = await RequestContext.currentId()
        const filter = await this.taskFilterGet(id)

        filter.updatedBy = userId
        await filter.save()
        await filter.softRemove()

        return filter
    }

    async taskFilterGet(id: string) {
        const userId = await RequestContext.currentId()
        const filter = await this.filterRepo.taskGetOneBy({
            id,
            relationId: userId
        })

        if (!filter) throw OfficeError.FilterNotFound

        return filter
    }

    async taskFilterList(filter: TaskFilterList) {
        const [data, total] = await this.filterRepo.taskListByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async statusUpdate(args: TaskStatusUpdateInput) {
        const task = args.task
        const oldValue = structuredClone(task.status)

        if (oldValue === args.status) {
            throw OfficeError.DataNotChange
        }

        const requester = await RequestContext.currentUser()

        task.status = args.status
        task.updatedBy = requester?.id
        await task.save()

        const data = {
            creator: requester,
            logs: [{
                action: TaskAction.Update,
                actionAt: new Date().getTime(),
                field: 'status',
                oldValue,
                newValue: args.status,
                note: args.note
            }],
            task: task,
            note: args.note
        }

        await this.officeTaskLogRepo.storeHistoryTaskUpdate(data)

        return task;
    }

    private async statusNormalUpdateStoreLog(oldValue: any, task: OfficeTask) {
        const requester = await RequestContext.currentUser()

        const data = {
            creator: requester,
            logs: [{
                action: TaskAction.Update,
                actionAt: new Date().getTime(),
                field: 'status',
                oldValue,
                newValue: task.status
            }],
            task: task
        }

        await this.officeTaskLogRepo.storeHistoryTaskUpdate(data)
    }

    async seedDataCreator() {
        const tasks = await this.officeTaskRepo.find({
            relations: ['creator', 'reporter'],
            where: {
                creator: IsNull()
            }
        })

        for (const task of tasks) {
            task.creator = task.reporter
        }

        await this.officeTaskRepo.save(tasks)
    }

    async reportConfigList(args: TaskReportConfigList) {
        const [data, total] = await this.officeTaskRepo.reportConfigList(args)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    private async removeReportTemplateData(reportTask: OfficeTask) {
        delete reportTask.keyPostfix
        delete reportTask.createdAt
        delete reportTask.createdBy
        delete reportTask.updatedAt
        delete reportTask.updatedBy
    }
}
