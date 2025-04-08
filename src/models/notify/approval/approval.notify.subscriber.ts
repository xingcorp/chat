import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent, ObjectLiteral, UpdateEvent } from "typeorm";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { NotificationService } from "@core/iam/notification/notification.service";
import { OfficeApproval } from "@models/entities";
import { OfficeUserRepo } from "@repositories/index";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";
import { ApprovalStatus } from "@models/entities/approval";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import { RequestContext } from "@common/context/request.context";

@Injectable()
// @EventSubscriber()
export class ApprovalNotifySubscriber implements EntitySubscriberInterface<OfficeApproval> {
    private entity: OfficeApproval | ObjectLiteral;
    private newVal: ObjectLiteral;
    private oldVal: any;
    private notifyType: string;
    private notifyTitle: any;
    private notifyContent: string;
    private receiverIds: any;
    private metadata: any;
    private eventUpdate: UpdateEvent<OfficeApproval>;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return OfficeApproval
    }

    private notify() {
        if (!this.receiverIds.length) return

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
    async afterInsert(event: InsertEvent<OfficeApproval>) {
        this.entity = event.entity
        if (!this.canSendNotify()) return

        try {
            this.entity = event.entity
            await this.notifyNewApproval()


            this.receiverIds = arrayConvertToDistinctAndNotNull(this.entity.subscriberIds ?? [])
            await this.notifySubscribers()
        } catch (e) {
            console.log('Called after ApprovalStep insert error', e)
        }
    }

    async afterUpdate(event: UpdateEvent<OfficeApproval>) {
        this.entity = event.entity
        if (!this.canSendNotify()) return

        try {
            this.eventUpdate = event

            await this.notifySubscribersAfterUpdate()

        } catch (e) {
            console.log('Called after ApprovalStep update error', e)
        }
    }

    private async notifyNewApproval() {
        const requester = await this.officeUserRepo.findOneBy({id: this.entity.createdBy})
        if (this.entity.status === ApprovalStatus.Approved) {
            this.notifyType = NotifyType.Approval.Approved
            this.notifyTitle = NotifyMessageTitle.Approval.Approved(this.entity)
            this.notifyContent = NotifyMessageContent.Approval.Approved({approvalName: this.entity.name, userActionName: requester.fullname})
            this.receiverIds = arrayConvertToDistinctAndNotNull([requester.id, ...(this.entity.subscriberIds ?? [])])
            this.metadata = {requestId: this.entity.id, approvalType: this.entity.type}
            await this.notify()
        }

        return
    }

    private async notifySubscribersAfterUpdate() {
        if (!this.eventUpdate.updatedColumns.map(i => i.propertyName).includes('subscriberIds')) return

        this.receiverIds = this.eventUpdate.databaseEntity.subscriberIds
            ? this.entity.subscriberIds.filter(i => !this.eventUpdate.databaseEntity.subscriberIds.includes(i))
            : this.entity.subscriberIds
        await this.notifySubscribers()

        this.receiverIds = this.eventUpdate.databaseEntity.subscriberIds.filter(i => !this.entity.subscriberIds.includes(i))
        return this.notifyRemoveSubscribers()
    }

    private async notifySubscribers() {
        if (!this.receiverIds || !this.receiverIds.length) return

        const requester = await RequestContext.currentUser()

        this.notifyType = NotifyType.Approval.Subscriber.Create
        this.notifyTitle = NotifyMessageTitle.Approval.Subscriber.Create(this.entity)
        this.notifyContent = NotifyMessageContent.Approval.Subscriber.Create({
            approvalName: this.entity.name,
            userActionName: requester.fullname,
            creatorName: (await this.officeUserRepo.getById(this.entity.createdBy))?.fullname
        })
        this.metadata = {requestId: this.entity.id, approvalType: this.entity.type}

        return this.notify()
    }

    private async notifyRemoveSubscribers() {
        if (!this.receiverIds || !this.receiverIds.length) return

        const requester = await RequestContext.currentUser()

        this.notifyType = NotifyType.Approval.Subscriber.Remove
        this.notifyTitle = NotifyMessageTitle.Approval.Subscriber.Remove(this.entity)
        this.notifyContent = NotifyMessageContent.Approval.Subscriber.Remove({approvalName: this.entity.name, userActionName: requester.fullname})
        this.metadata = {requestId: this.entity.id, approvalType: this.entity.type}

        return this.notify()
    }

    private canSendNotify() {
        /*not send if draft of forward*/
        return ![ApprovalStatus.Draft, ApprovalStatus.Forward].includes(this.entity.status)
    }
}