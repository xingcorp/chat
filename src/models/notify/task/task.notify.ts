import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent, UpdateEvent } from "typeorm";
import { OfficeTask } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { OfficeTaskRepo, OfficeUserRepo } from "@models/repositories";
import { NotificationService } from "@core/iam/notification/notification.service";

@Injectable()
// @EventSubscriber()
export class TaskNotify implements EntitySubscriberInterface<OfficeTask> {
    private updateEvent: UpdateEvent<OfficeTask>;
    private task: OfficeTask;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        @InjectRepository(OfficeTaskRepo)
        private readonly officeTaskRepo: OfficeTaskRepo,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
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
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<OfficeTask>) {
        try {

        } catch (e) {
            console.log('Called after OfficeTaskLog insertion error: ', e)
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<OfficeTask>) {
        try {
        } catch (e) {
            console.log('TaskNotify afterUpdate error', e)
        }
    }
}