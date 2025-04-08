import { Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent, ObjectLiteral, UpdateEvent } from "typeorm";
import { OfficeTask } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { OfficeTaskLogRepo, OfficeTaskRepo, OfficeUserRepo } from "@models/repositories";
import { TaskStatus } from "@enum/task/task.enum";
import { TaskLogService } from "@modules/graphql/task/task-log/task-log.service";

@Injectable()
// @EventSubscriber()
export class TaskSubscriber implements EntitySubscriberInterface<OfficeTask> {
    private entity: ObjectLiteral;
    private updateEvent: UpdateEvent<OfficeTask>;
    private task: any;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @InjectRepository(OfficeTaskLogRepo)
        private readonly officeTaskLogRepo: OfficeTaskLogRepo,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
        private readonly taskLogService: TaskLogService,
        @InjectRepository(OfficeTaskRepo)
        private readonly officeTaskRepo: OfficeTaskRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return OfficeTask
    }

    /**
     * Called before entity insertion.
     */
    async beforeInsert(event: InsertEvent<OfficeTask>) {
        await this.modifyTaskDataInsert(event.entity)
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<OfficeTask>) {
        try {
            // not working at here
            // await this.officeTaskLogRepo.storeHistoryTaskCreate(event.entity, event.manager)
        } catch (e) {
            console.log('Called after OfficeTask insertion error: ', e)
        }
    }

    /**
     * Called before entity update.
     */
    async beforeUpdate(event: UpdateEvent<OfficeTask>) {
        await this.modifyTaskDataUpdate(event.entity, event)
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<OfficeTask>) {
        try {
            this.updateEvent = event
            this.entity = event.entity
            const oldVal = event.databaseEntity
            const newVal = event.entity
            const fieldsChange = [...new Set([
                ...event.updatedColumns.map(i => i.propertyName),
                ...event.updatedRelations.map(i => i.propertyName)
            ])]

            const data = {
                creator: await this.officeUserRepo.getById(event.entity.updatedBy),
                logs: await this.taskLogService.createLogs(fieldsChange, oldVal, newVal),
                task: event.databaseEntity
            }

            if (data.logs.length) await this.officeTaskLogRepo.storeHistoryTaskUpdate(data, event.manager)

            await this.checkWhenTaskDone()
        } catch (e) {
            console.log('Called after OfficeTask update error', e)
        }
    }

    private async modifyTaskDataUpdate(entity: ObjectLiteral, event: UpdateEvent<OfficeTask>) {
        const fieldsChange = [
            ...event.updatedColumns.map(i => i.propertyName),
            ...event.updatedRelations.map(i => i.propertyName)
        ]

        if (fieldsChange.includes('status') && entity.status === TaskStatus.Done) entity.doneAt = new Date()
    }

    private async modifyTaskDataInsert(entity: OfficeTask) {
        if (entity.status && entity.status === TaskStatus.Done) entity.doneAt = new Date()
        return
    }

    private async checkWhenTaskDone() {
        if (!this.updateEvent.updatedColumns.map(i => i.propertyName).includes('status')) return

        this.task = await this.officeTaskRepo.getBy({id: this.updateEvent.entity.id}, ['parentTask'])

        await this.checkIsReportParentTaskDone()
        await this.checkIsReportParentTaskReturnToDo()

    }

    private async checkIsReportParentTaskDone() {
        if (
            this.updateEvent.databaseEntity.isReportChild()
            && this.updateEvent.entity.status === TaskStatus.Done
        ) {
            const parent = await this.officeTaskRepo.getBy({id: this.task.parentTask.id}, ['childrenTask'])

            if (!(parent.childrenTask
                .filter(i => i.id !== this.updateEvent.entity.id)
                .filter(i => i.status !== TaskStatus.Done)
                .length)
            ) {
                parent.status = TaskStatus.Done

                await parent.save()
            }
        }
    }

    private async checkIsReportParentTaskReturnToDo() {
        if (
            this.updateEvent.databaseEntity.isReportChild()
            && this.updateEvent.entity.status !== TaskStatus.Done
        ) {
            const parent = await this.officeTaskRepo.getBy({id: this.task.parentTask.id}, ['childrenTask'])

            if (parent.status === TaskStatus.Done) {
                parent.status = TaskStatus.Todo

                await parent.save()
            }
        }
    }
}