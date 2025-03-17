import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent, ObjectLiteral, UpdateEvent } from "typeorm";
import { ApprovalForward } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { NotificationService } from "@core/iam/notification/notification.service";
import { ApprovalForwardRepo, OfficeApprovalRepo, OfficeUserRepo } from "@repositories/index";

@Injectable()
// @EventSubscriber()
export class ApprovalForwardNotify implements EntitySubscriberInterface<ApprovalForward> {
    private notifyType: string;
    private notifyTitle: any;
    private notifyContent: string;
    private receiverIds: any;
    private metadata: any;
    private entity: ApprovalForward | ObjectLiteral;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        @InjectRepository(ApprovalForwardRepo)
        private readonly approvalStepRepo: ApprovalForwardRepo,
        @InjectRepository(OfficeApprovalRepo)
        private readonly approvalRepo: OfficeApprovalRepo,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return ApprovalForward
    }

    private notify() {
        if (!this.receiverIds?.length) return

        return this.notificationService.destinationPush(
            null,
            this.notifyType,
            this.notifyTitle,
            this.notifyContent,
            '',
            JSON.stringify(this.metadata),
            this.receiverIds,
            null,
            process.env.OFFICE_ORGANIZATION_ID
        )
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<ApprovalForward>) {
        try {
            this.entity = event.entity

        } catch (e) {
            console.log('Called after ApprovalForward insertion error: ', e)
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<ApprovalForward>) {
        try {
            this.entity = event.entity

        } catch (e) {
            console.log('Called after ApprovalForward update error', e)
        }
    }
}