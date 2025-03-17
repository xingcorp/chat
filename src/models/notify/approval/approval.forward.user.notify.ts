import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent, ObjectLiteral, UpdateEvent } from "typeorm";
import { ApprovalForwardUser, OfficeUser } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { NotificationService } from "@core/iam/notification/notification.service";
import { ApprovalForwardRepo, OfficeUserRepo } from "@repositories/index";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";

@Injectable()
// @EventSubscriber()
export class ApprovalForwardUserNotify implements EntitySubscriberInterface<ApprovalForwardUser> {
    private notifyType: string;
    private notifyTitle: any;
    private notifyContent: string;
    private receiverIds: any;
    private metadata: any;
    private entity: ApprovalForwardUser | ObjectLiteral;
    private creator: OfficeUser;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        @InjectRepository(ApprovalForwardRepo)
        private readonly approvalForwardRepo: ApprovalForwardRepo,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return ApprovalForwardUser
    }

    private notify() {
        if (!this.receiverIds?.length) return

        return this.notificationService.systemDestinationPush(
            this.notifyType,
            this.notifyTitle,
            this.notifyContent,
            '',
            JSON.stringify(this.metadata),
            this.receiverIds,
            null,
            process.env.OFFICE_ORGANIZATION_ID,
            this.creator?.id
        )
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<ApprovalForwardUser>) {
        try {
            this.entity = event.entity
            const forward = await this.approvalForwardRepo.findOne({
                relations: ['approval'],
                where: {id: this.entity.forward.id}
            })
            const approval = forward.approval
            this.creator = await this.officeUserRepo.findOneBy({id: forward.createdBy})

            this.notifyType = NotifyType.Approval.Forward.NotifyToUser
            this.notifyTitle = NotifyMessageTitle.Approval.Forward.NotifyToUser()
            this.notifyContent = NotifyMessageContent.Approval.Forward.NotifyToUser({
                name: approval.name,
                creatorName: this.creator.fullname
            })
            this.receiverIds = [this.entity?.user?.id]

            this.metadata = {requestId: approval.id, approvalId: approval.id, approvalType: approval.type}

            await this.notify()

        } catch (e) {
            console.log('Called after ApprovalForwardUser insertion error: ', e)
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<ApprovalForwardUser>) {
        try {
            this.entity = event.entity

        } catch (e) {
            console.log('Called after ApprovalForwardUser update error', e)
        }
    }
}