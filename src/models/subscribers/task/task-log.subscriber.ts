import { Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent, ObjectLiteral, UpdateEvent } from "typeorm";
import { OfficeTaskLog } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { OfficeTaskLogRepo, OfficeUserRepo } from "@models/repositories";
import { TaskAction } from "@enum/task/task.enum";

@Injectable()
// @EventSubscriber()
export class TaskLogSubscriber implements EntitySubscriberInterface<OfficeTaskLog> {

    constructor(
        @InjectConnection() readonly connection: Connection,
        @InjectRepository(OfficeTaskLogRepo)
        private readonly officeTaskLogRepo: OfficeTaskLogRepo,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return OfficeTaskLog
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<OfficeTaskLog>) {
        try {
        } catch (e) {
            console.log('Called after OfficeTaskLog insertion error: ', e)
        }
    }

    /**
     * Called before entity update.
     */
    async beforeUpdate(event: UpdateEvent<any>) {
        try {
            const oldVal = event.databaseEntity
            const newVal = event.entity
            const fieldsChange = [
                ...event.updatedColumns.map(i => i.propertyName),
                ...event.updatedRelations.map(i => i.propertyName)
            ]

            const logs = await this.createLogs(fieldsChange, oldVal, newVal)
            if (event.entity.logs) {
                const oldLogs = event.entity.logs
                oldLogs.push(...logs)
                event.entity.logs = JSON.stringify(oldLogs)
            } else {
                event.entity.logs = JSON.stringify(logs)
            }

        } catch (e) {
            console.log('Called after OfficeTaskLog update error', e)
        }
    }

    private async createLogs(fieldsChange: string[], oldVal: any, newVal: ObjectLiteral) {
        const logs = []
        for (const field of fieldsChange) {
            switch (field) {
                case 'description':
                    logs.push({
                        action: TaskAction.Update,
                        actionAt: new Date().getTime(),
                        field: 'comment',
                        oldValue: oldVal[field],
                        newValue: newVal[field],
                    })
                    break;
            }
        }

        return logs
    }
}