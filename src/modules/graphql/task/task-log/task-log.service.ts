import { Injectable } from '@nestjs/common';
import { TaskCommentCreate, TaskCommentUpdate } from "@modules/graphql/task/task-log/dto/task-log.args";
import { TaskService } from "@modules/graphql/task/task/task.service";
import { OfficeTaskLogRepo, OfficeTaskRepo, OfficeUserRepo } from "@models/repositories";
import { OfficeError } from "@common/office.error";
import { BaseEntity, DataSource, ObjectLiteral } from "typeorm";
import { CloneByDate, OfficeTask } from "@models/entities";
import { TaskAction } from "@enum/task/task.enum";
import { arrayIsTheSame } from "@utils/array.utils";
import { RequestContext } from "@common/context/request.context";
import { CACHE_KEY } from "@common/cache-key.common";
import { RedisService } from "@core/common/redis.service";
import { StorageService } from "@core/storage/storage.service";

@Injectable()
export class TaskLogService {
    constructor(
        private dataSource: DataSource,
        private readonly taskService: TaskService,
        private readonly officeTaskLogRepo: OfficeTaskLogRepo,
        private readonly officeTaskRepo: OfficeTaskRepo,
        private readonly officeUserRepo: OfficeUserRepo,
        private readonly storageService: StorageService,
        private readonly redisService: RedisService,
    ) {
    }

    async commentCreate(param: { userId: string; rootOrgId: string }, args: TaskCommentCreate) {
        const { rootOrgId, userId } = param

        const { task, user } = await this.taskService.validateTaskAndUser(args.taskId, userId, rootOrgId, true)

        const comment = this.officeTaskLogRepo.createComment(args)
        comment.creator = user
        comment.task = task
        comment.createdBy = userId
        comment.updatedBy = userId

        task.updatedBy = userId
        task.updatedAt = new Date()

        console.log('comment', comment)

        /*await this.dataSource.manager.transaction(async entity => {
            await entity.save(task)
            await entity.save(comment)
        })*/

        await this.dataSource.manager.save(task)
        await this.dataSource.manager.save(comment)

        return comment;
    }

    async commentUpdate(userId: string, args: TaskCommentUpdate) {
        const comment = await this.officeTaskLogRepo.getCommentById(args.id)

        if (comment.creator.id !== userId) {
            throw OfficeError.TaskCommentNotOwnUser
        }

        comment.description = args.comment
        comment.updatedBy = userId

        /*update task*/

        const task = await this.officeTaskRepo.findOneBy({
            id: comment.task.id
        })

        task.updatedBy = userId
        task.updatedAt = new Date()

        /*await this.dataSource.manager.transaction(async entity => {
            await entity.save(task)
            await entity.save(comment)
        })*/

        await this.dataSource.manager.save(task)
        await this.dataSource.manager.save(comment)

        return comment;
    }

    async createLogs(fieldsChange: string[], oldVal: OfficeTask, newVal: ObjectLiteral) {
        const logs = []
        for (const field of fieldsChange) {
            switch (field) {
                case 'title':
                case 'description':
                case 'priority':
                    // case 'status':
                    logs.push(await this.taskLogForText(field, oldVal, newVal))
                    break;
                case 'startTime':
                case 'finishTime':
                case 'doneAt':
                    logs.push(await this.taskLogForDate(field, oldVal, newVal))
                    break;
                case 'assigned':
                case 'reporter':

                    if ((!oldVal[field].id && !newVal[field]) || oldVal[field].id === newVal[field].id) break

                    const oldAssigned = await this.officeUserRepo.getById(oldVal[field].id);
                    logs.push({
                        action: TaskAction.Update,
                        actionAt: new Date(newVal.updatedAt).getTime(),
                        field,
                        oldValue: {
                            id: oldAssigned?.id,
                            fullname: oldAssigned?.fullname,
                            code: oldAssigned?.code,
                            phone: oldAssigned?.phone,
                            iamUserId: oldAssigned?.iamUserId,
                            imageUrls: oldAssigned?.imageUrls,
                        },
                        newValue: {
                            id: newVal[field]?.id,
                            fullname: newVal[field]?.fullname,
                            code: newVal[field]?.code,
                            phone: newVal[field]?.phone,
                            iamUserId: newVal[field]?.iamUserId,
                            imageUrls: newVal[field]?.imageUrls,
                        },
                    })
                    break;
                case 'attachmentIds':
                    if (arrayIsTheSame(oldVal.attachmentIds, newVal.attachmentIds)) break

                    await this.clearCacheAttachment(newVal)

                    const { data: oldAttachments } = await this.storageService.getFilesDetail(RequestContext.currentToken(), oldVal.attachmentIds)
                    const { data: newAttachments } = await this.storageService.getFilesDetail(RequestContext.currentToken(), newVal.attachmentIds)

                    logs.push({
                        action: TaskAction.Update,
                        actionAt: new Date(newVal.updatedAt).getTime(),
                        field,
                        oldValue: oldAttachments?.files ?? [],
                        newValue: newAttachments?.files ?? [],
                    })
                    break;
            }
        }

        return logs
    }

    private async clearCacheAttachment(entity: ObjectLiteral) {
        const redisKey = `${CACHE_KEY.TASK.LOG.ATTACHMENT}__${entity.id}`
        await this.redisService.delete(redisKey)
    }

    async createLogsByCloneDate(fieldsChange: string[], oldVal: CloneByDate, newVal: ObjectLiteral) {
        const logs = []
        for (const field of fieldsChange) {
            switch (field) {
                case 'periodType':
                case 'weekDays':
                case 'monthDays':
                    logs.push(await this.taskLogForText(field, oldVal, newVal))
                    break;
                case 'startAt':
                case 'endAt':
                    logs.push(await this.taskLogForDate(field, oldVal, newVal))
                    break;
                case 'startTimeIn':
                    logs.push(await this.taskLogForGetFirstOfArray(field, oldVal, newVal))
                    break;
                case 'relationData':
                    if (oldVal[field]?.['workDays'] !== newVal[field]?.['workDays']) {
                        logs.push(await this.taskLogForRawData('workDays', oldVal[field]?.['workDays'], newVal[field]?.['workDays'], new Date(newVal.updatedAt).getTime()))
                    }
                    break;
            }
        }

        return logs
    }

    private async taskLogForText(field: string, oldVal: BaseEntity, newVal: ObjectLiteral) {
        return {
            action: TaskAction.Update,
            actionAt: new Date(newVal.updatedAt).getTime(),
            field,
            oldValue: oldVal[field],
            newValue: newVal[field],
        }
    }

    private async taskLogForDate(field: string, oldVal: BaseEntity, newVal: ObjectLiteral) {
        return {
            action: TaskAction.Update,
            actionAt: new Date(newVal.updatedAt).getTime(),
            field,
            oldValue: oldVal[field] ? new Date(oldVal[field]).getTime() : null,
            newValue: newVal[field] ? new Date(newVal[field]).getTime() : null,
        }
    }

    private async taskLogForGetFirstOfArray(field: string, oldVal: BaseEntity, newVal: ObjectLiteral) {
        return {
            action: TaskAction.Update,
            actionAt: new Date(newVal.updatedAt).getTime(),
            field,
            oldValue: oldVal[field][0],
            newValue: newVal[field][0],
        }
    }

    private async taskLogForRawData(field: string, oldVal: any, newVal: any, actionAt: number) {
        return {
            action: TaskAction.Update,
            actionAt,
            field,
            oldValue: oldVal,
            newValue: newVal,
        }
    }
}
