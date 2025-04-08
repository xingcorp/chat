import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent } from "typeorm";
import { OfficeTask, OfficeTaskLog, OfficeUser } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { OfficeTaskRepo, OfficeUserRepo } from "@repositories/index";
import {
    TaskAction, TaskKindEnum,
    TaskLogType,
    TaskPriorityTitle,
    TaskStatus,
    TaskStatusTitle,
    TaskTypeEnum
} from "@enum/task/task.enum";
import { NotificationService } from "@core/iam/notification/notification.service";
import { RequestContext } from "@common/context/request.context";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";
import { capitalizeString } from "@utils/string.utils";

@Injectable()
// @EventSubscriber()
export class TaskLogNotifySubscriber implements EntitySubscriberInterface<OfficeTaskLog> {
    private token: string;
    private receiverIds: string[];
    private task: OfficeTask;
    private taskKey: string;
    private creator: OfficeUser;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
        @InjectRepository(OfficeTaskRepo)
        private readonly officeTaskRepo: OfficeTaskRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return OfficeTaskLog
    }

    private async getListUserIdGetNotify(entity: OfficeTaskLog) {
        const task = entity.task
        const isCreateLogs = this.isCreateLogs(entity)

        switch (entity.task.taskKind) {
            case TaskKindEnum.ReportChild:
                if (isCreateLogs) {
                    return [...new Set([
                        task?.assigned?.id,
                        ...(task?.watchers?.map(i => i.id) ?? [])
                    ])]
                }
            case TaskKindEnum.ReportParent:
                if (isCreateLogs) {
                    return [...new Set([
                        task.reporter?.id,
                        ...(task?.watchers?.map(i => i.id) ?? [])
                    ])]
                }
            default:
                return [...new Set([
                    task.reporter.id,
                    task?.assigned?.id,
                    ...(task?.assignees?.map(i => i.id) ?? []),
                    ...(task?.watchers?.map(i => i.id) ?? [])
                ])]
        }
    }

    private notifyCreateTaskComment(taskLog: OfficeTaskLog) {
        return this.notificationService.destinationPush(
            this.token,
            NotifyType.Task.Create,
            NotifyMessageTitle.TaskUpdateComment({key: this.taskKey}),
            taskLog.description,
            '',
            JSON.stringify({taskId: this.task.id, key: this.taskKey}),
            this.receiverIds,
            null,
            process.env.OFFICE_ORGANIZATION_ID
        )
    }

    private async notifyUpdateTask(log: any) {
        const notifies = []
        const requesterId = await RequestContext.currentId()

        switch (log.field) {
            case 'startTimeIn':
            case 'periodType':
            case 'weekDays':
            case 'monthDays':
            case 'workDays':
                notifies.push({
                    key: log.key ?? await this.officeTaskRepo.getKey(this.task),
                    title: NotifyMessageTitle[`TaskUpdate${capitalizeString(log.field)}`](log),
                    content: NotifyMessageContent[`TaskUpdate${capitalizeString(log.field)}`](log),
                    receivers: this.receiverIds
                })
                break
            case 'status':
            case 'priority':
                log['newValueName'] = (log.field === 'status' ? TaskStatusTitle : TaskPriorityTitle)[log.newValue ?? TaskStatus.Undefined]
            case 'description':
            case 'startTime':
            case 'finishTime':
            case 'startAt':
            case 'endAt':
                notifies.push({
                    key: log.key ?? await this.officeTaskRepo.getKey(this.task),
                    title: NotifyMessageTitle[`TaskUpdate${capitalizeString(log.field)}`](log),
                    content: NotifyMessageContent[`TaskUpdate${capitalizeString(log.field)}`](log),
                    receivers: this.receiverIds
                })
                break;
            case 'assigned':
            case 'reporter':
            case 'watchers':
            case 'assignees':
                let oldUser = []
                let newUser = []
                if (Array.isArray(log.oldValue)) {
                    oldUser = log.oldValue.map(i => i.id)
                    newUser = log.newValue.map(i => i.id)
                } else {
                    oldUser = [log.oldValue.id]
                    newUser = [log.newValue.id]
                }

                notifies.push({
                    key: log.key ?? await this.officeTaskRepo.getKey(this.task),
                    title: NotifyMessageTitle[`TaskUpdate${capitalizeString(log.field)}`](log),
                    content: NotifyMessageContent[`TaskUpdate${capitalizeString(log.field)}`](log),
                    receivers: [...new Set([...this.receiverIds, ...oldUser].filter(i => !newUser.includes(i)))],
                })
                notifies.push({
                    key: log.key ?? await this.officeTaskRepo.getKey(this.task),
                    title: NotifyMessageTitle[`TaskUpdate${capitalizeString(log.field)}NewUser`](log),
                    content: NotifyMessageContent[`TaskUpdate${capitalizeString(log.field)}NewUser`](log),
                    receivers: newUser,
                })
                break;
            default:
                return
        }

        for (const notify of notifies) {
            await this.notificationService.destinationPush(
                this.token,
                NotifyType.Task.Update,
                notify.title,
                notify.content,
                '',
                JSON.stringify({taskId: this.task.id, key: notify.key}),
                notify.receivers?.filter(i => i !== requesterId),
                null,
                process.env.OFFICE_ORGANIZATION_ID
            )
        }

        return true
    }

    private notifyCreateTask(log: any) {
        if (this.token || RequestContext.currentToken()) {
            return this.notificationService.destinationPush(
                this.token,
                NotifyType.Task.Create,
                NotifyMessageTitle[this.task.assigned ? 'TaskCreate' : 'TaskCreateNoAssigned'](log),
                NotifyMessageContent[this.task.assigned ? 'TaskCreate' : 'TaskCreateNoAssigned'](log),
                '',
                JSON.stringify({taskId: this.task.id, key: log.key}),
                this.receiverIds,
                null,
                process.env.OFFICE_ORGANIZATION_ID
            )
        }

        return this.notificationService.systemDestinationPush(
            NotifyType.Task.Create,
            NotifyMessageTitle[this.task.assigned ? 'TaskCreate' : 'TaskCreateNoAssigned'](log),
            NotifyMessageContent[this.task.assigned ? 'TaskCreate' : 'TaskCreateNoAssigned'](log),
            '',
            JSON.stringify({taskId: this.task.id, key: log.key}),
            this.receiverIds,
            null,
            process.env.OFFICE_ORGANIZATION_ID,
            this.task?.creator?.id
        )


    }

    private async notifyToUser(taskLog: OfficeTaskLog) {
        this.task = await this.officeTaskRepo.findOne({
            relations: ['creator', 'reporter', 'assigned', 'watchers', 'assignees'],
            where: {id: taskLog.task.id}
        })

        taskLog.task = this.task

        this.receiverIds = await this.getListUserIdGetNotify(taskLog)
        this.taskKey = await this.officeTaskRepo.getKey(this.task)
        this.creator = taskLog.creator

        if (taskLog.type === TaskLogType.Comment) {
            this.receiverIds = this.receiverIds?.filter(i => i !== this.creator?.id)
            return this.notifyCreateTaskComment(taskLog)
        }

        const data = JSON.parse(taskLog.logs)
        for (const log of data) {
            log['key'] = this.taskKey
            log['title'] = this.task.title
            if (this.task.assigned) log['assigned'] = this.task.assigned
            log['reporter'] = this.task.reporter
            log['creator'] = this.creator

            if (log?.taskType === TaskTypeEnum.ReportConfig) continue
            switch (log.action) {
                case TaskAction.Create:
                    await this.notifyCreateTask(log)
                    break
                case TaskAction.Update:
                    await this.notifyUpdateTask(log)
                    break
            }
        }
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<OfficeTaskLog>) {
        try {
            this.token = RequestContext.currentToken();

            await this.notifyToUser(event.entity)
        } catch (e) {
            console.log('Called after OfficeTaskLog insertion error: ', e)
        }
    }

    private isCreateLogs(entity: OfficeTaskLog) {
        const data = JSON.parse(entity.logs)

        return data[0]?.action === TaskAction.Create
    }
}