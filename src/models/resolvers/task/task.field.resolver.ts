import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { CloneByDate, OfficeLogs, OfficeTask, OfficeTaskLog, OfficeTaskProject, OfficeUser } from "@models/entities";
import { datetimeGetFormat } from "@utils/datetime.utils";
import { TaskLogType, TaskStatus, TaskTypeEnum } from "@enum/task/task.enum";
import { InjectRepository } from "@nestjs/typeorm";
import { OfficeTaskRepo } from "@models/repositories";
import { In } from "typeorm";
import { File } from '@core/storage/objects/file'
import { forwardRef, Inject } from "@nestjs/common";
import { StorageService } from "@core/storage/storage.service";
import { RequestContext } from "@common/context/request.context";
import { RedisService } from "@core/common/redis.service";
import { CACHE_KEY } from "@common/cache-key.common";
import { CloneDateTypeEnum } from "@enum/clone/date.clone.enum";

@Resolver(_of => OfficeTask)
export class OfficeTaskFieldResolver {
    constructor(
        @InjectRepository(OfficeTaskRepo)
        private readonly officeTaskRepo: OfficeTaskRepo,
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
        @Inject(forwardRef(() => RedisService))
        private readonly redisService: RedisService
    ) {
    }

    @ResolveField('project', _return => OfficeTaskProject, { nullable: true })
    async project(
        @Parent() root: OfficeTask
    ) {
        const task = await this.officeTaskRepo.getBy({ id: root.id }, ['project'])

        return task.project
    }

    @ResolveField('creator', _return => OfficeUser, { nullable: true })
    async creator(
        @Parent() root: OfficeTask
    ) {
        const task = await this.officeTaskRepo.getBy({ id: root.id }, ['creator', 'reporter'])

        return task.creator ?? task.reporter
    }

    @ResolveField('reporter', _return => OfficeUser, { nullable: true })
    async reporter(
        @Parent() root: OfficeTask
    ) {
        const task = await this.officeTaskRepo.getBy({ id: root.id }, ['reporter'])

        return task.reporter
    }

    @ResolveField('assigned', _return => OfficeUser, { nullable: true })
    async assigned(
        @Parent() root: OfficeTask
    ) {
        const task = await this.officeTaskRepo.getBy({ id: root.id }, ['assigned'])

        return task.assigned
    }

    @ResolveField('watchers', _return => [OfficeUser], { nullable: true })
    async watchers(
        @Parent() root: OfficeTask
    ) {
        const task = await this.officeTaskRepo.getBy({ id: root.id }, ['watchers'])

        return task.watchers
    }

    @ResolveField('assignees', _return => [OfficeUser], { nullable: true })
    async assignees(
        @Parent() root: OfficeTask
    ) {
        const task = await this.officeTaskRepo.getBy({ id: root.id }, ['assignees'])

        return task.assignees
    }

    @ResolveField('templateTask', _return => OfficeTask, { nullable: true })
    async templateTask(
        @Parent() root: OfficeTask
    ) {
        const task = await this.officeTaskRepo.getBy({ id: root.id }, ['templateTask'])

        return task.templateTask
    }

    @ResolveField('clonesTask', _return => [OfficeTask], { nullable: true })
    async clonesTask(
        @Parent() root: OfficeTask
    ) {
        const task = await this.officeTaskRepo.getBy({ id: root.id }, ['clonesTask'])

        return task.clonesTask
    }

    @ResolveField('parentTask', _return => OfficeTask, { nullable: true })
    async parentTask(
        @Parent() root: OfficeTask
    ) {
        const task = await this.officeTaskRepo.getBy({ id: root.id }, ['parentTask'])

        return task.parentTask
    }

    @ResolveField('linkTasks', _return => [OfficeTask], { nullable: true })
    async linkTasks(
        @Parent() root: OfficeTask
    ) {
        // console.log(root.id)
        // const [linkedFromTasks, linkedToTasks] = await Promise.all([
        //     this.officeTaskRepo.getBy({ id: root.id }, ['linkTasks']),
        //     this.officeTaskRepo.find({
        //         where: {
        //             linkTasks: {
        //                 id: root.id
        //             }
        //         },
        //         relations: ['linkTasks']
        //     })
        // ]);
        // // Combine both directions of links and remove duplicates
        // const allLinkedTasks = [...(linkedFromTasks.linkTasks || []), ...linkedToTasks];
        // return [...new Set(allLinkedTasks)];
        const task = await this.officeTaskRepo.getBy({ id: root.id }, ['linkTasks'])

        return task.linkTasks
    }

    @ResolveField('childrenTask', _return => [OfficeTask], { nullable: true })
    async childrenTask(
        @Parent() root: OfficeTask
    ) {
        const task = await this.officeTaskRepo.getBy({ id: root.id }, ['childrenTask'])

        return task.childrenTask
    }

    @ResolveField('key', _return => String, { nullable: true })
    async key(
        @Parent() root: OfficeTask
    ) {
        const cacheKey = CACHE_KEY.TASK.GET_KEY(root.id)
        const cached = await this.redisService.get(cacheKey)

        if (cached) {
            return cached
        }

        const key = await this.officeTaskRepo.getKey(root)

        await this.redisService.set(cacheKey, key)

        return key
    }

    @ResolveField('comments', _return => [OfficeTaskLog], { nullable: true })
    async comments(
        @Parent() root: OfficeTask
    ) {
        return OfficeTaskLog.find({
            where: {
                task: {
                    id: root.id
                },
                type: TaskLogType.Comment,
            },
            order: {
                createdAt: 'ASC'
            }
        })
    }

    @ResolveField('histories', _return => [OfficeTaskLog], { nullable: true })
    async histories(
        @Parent() root: OfficeTask
    ) {
        return OfficeTaskLog.find({
            where: {
                task: {
                    id: root.id
                },
                type: TaskLogType.History
            },
            order: {
                createdAt: 'ASC'
            }
        })
    }

    @ResolveField('attachments', _return => [File], { nullable: true })
    async attachments(
        @Parent() root: OfficeTask
    ) {
        if (!root.attachmentIds || !root.attachmentIds.length) return []

        const redisKey = `${CACHE_KEY.TASK.LOG.ATTACHMENT}__${root.id}`
        // await this.redisService.delete(redisKey)
        const cached = await this.redisService.get(redisKey)
        if (cached) {
            const resCached = JSON.parse(cached)
            return resCached.length ? resCached : []
        }

        const { data } = await this.storageService.getFilesDetail(RequestContext.currentToken(), root.attachmentIds)

        const res = data?.files ?? []

        await this.redisService.setWithTtl(redisKey, JSON.stringify(res), 30 * 24 * 60 * 60)

        return res
    }

    @ResolveField('isLate', _return => Boolean, { nullable: true })
    async isLate(
        @Parent() root: OfficeTask
    ) {
        return !!(root.finishTime && (new Date()) > root.finishTime && ![TaskStatus.Done, TaskStatus.Cancel, TaskStatus.Reject].includes(root.status))
    }

    @ResolveField('config', _return => CloneByDate, { nullable: true })
    async config(
        @Parent() root: OfficeTask
    ) {
        if (root.taskType !== TaskTypeEnum.ReportConfig) return null

        return CloneByDate.findOneBy({
            relationType: CloneDateTypeEnum.TaskReportConfig,
            relationId: root.id
        })
    }
}