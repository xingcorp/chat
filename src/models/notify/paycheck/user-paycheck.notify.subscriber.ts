import { Connection, EntitySubscriberInterface, EventSubscriber, InsertEvent, RemoveEvent, UpdateEvent } from "typeorm";
import { OfficeUserPaycheck } from "@models/entities";
import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { InjectConnection } from "@nestjs/typeorm";
import { NotificationService } from "@core/iam/notification/notification.service";
import { RequestContext } from "@common/context/request.context";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";
import { PaycheckStatus } from "@enum/payroll/paycheck.enum";

@Injectable()
// @EventSubscriber()
export class UserPaycheckNotifySubscriber implements EntitySubscriberInterface<OfficeUserPaycheck> {

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUserPaycheck events.
     */
    listenTo() {
        return OfficeUserPaycheck
    }

    private async notifyToUser(entity: any, isUpdate: boolean = false) {
        let token = RequestContext.currentToken();

        const messageDynamicData = {
            paycheckName: entity.name,
            paycheckMonth: entity.month,
            paycheckYear: entity.year,
            username: entity.user.fullname,
        }

        await this.notificationService.destinationPush(
            token,
            isUpdate ? NotifyType.PaycheckUpdate : NotifyType.PaycheckCreate,
            NotifyMessageTitle.UserPaycheckUpsert(messageDynamicData),
            NotifyMessageContent.UserPaycheckUpsert(messageDynamicData),
            '',
            JSON.stringify({paycheckId: entity.id, createdAt: entity.createdAt}),
            [entity.user.id],
            null,
            process.env.OFFICE_ORGANIZATION_ID
        )
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<OfficeUserPaycheck>) {
        try {
            await this.notifyToUser(event.entity)
        } catch (e) {
            console.log('create user paycheck error', e)
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<OfficeUserPaycheck>) {
        try {
            /*Not do this notify when user comment paycheck*/
            if (this.isChangeStatusToInProgress(event)) return

            await this.notifyToUser(event.entity, true)
        } catch (e) {
            console.log('update user paycheck error', e)
        }
    }

    /**
     * Called after entity removal.
     */
    async afterRemove(event: RemoveEvent<OfficeUserPaycheck>) {
        try {
        } catch (e) {
            console.log('remove user paycheck error', e)
        }
    }

    private isChangeStatusToInProgress(event: UpdateEvent<OfficeUserPaycheck>) {
        return event.entity.status !== event.databaseEntity.status && event.entity.status === PaycheckStatus.In_progress;
    }
}