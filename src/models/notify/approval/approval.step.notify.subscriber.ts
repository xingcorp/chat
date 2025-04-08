import { forwardRef, Inject, Injectable } from "@nestjs/common";
import {
    BaseEntity,
    Connection,
    EntitySubscriberInterface,
    InsertEvent,
    ObjectLiteral,
    UpdateEvent
} from "typeorm";
import { ApprovalStep, DocumentWiki, OfficeApproval, OfficeOrgChart, OfficeUser } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { NotificationService } from "@core/iam/notification/notification.service";
import { ApprovalStepRepo, OfficeApprovalRepo, OfficeUserRepo, VersionWikiRepo, WikiRepo } from "@repositories/index";
import { ApprovalProcessAction } from "@models/entities/approval.step";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";
import { ApprovalStatus } from "@models/entities/approval";
import { ApprovalAction, ApprovalType } from "@models/entities/approval.form";
import { GrantType } from "@utils/enum.utils";

@Injectable()
// @EventSubscriber()
export class ApprovalStepNotifySubscriber implements EntitySubscriberInterface<ApprovalStep> {
    private newVal: ObjectLiteral;
    private oldVal: any;
    private notifyType: string;
    private notifyTitle: any;
    private notifyContent: string;
    private receiverIds: any;
    private metadata: any;
    private approval: OfficeApproval;
    private requester: OfficeUser;
    private lastActionUser: OfficeUser;
    private fieldsChange: string[];
    private submitStep: ApprovalStep;
    private afterInsertEntity: any;
    private afterUpdateEntity: ObjectLiteral;
    private afterUpdateEvent: UpdateEvent<ApprovalStep>;
    private afterInsertApproval: any;
    private afterUpdateApproval: any;
    private afterInsertRelation: DocumentWiki;
    private approvalRelation: DocumentWiki;
    private afterUpdateRelation: DocumentWiki;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        @InjectRepository(ApprovalStepRepo)
        private readonly approvalStepRepo: ApprovalStepRepo,
        @InjectRepository(OfficeApprovalRepo)
        private readonly officeApprovalRepo: OfficeApprovalRepo,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
        @InjectRepository(WikiRepo)
        private readonly wikiRepo: WikiRepo,
        @InjectRepository(VersionWikiRepo)
        private readonly versionWikiRepo: VersionWikiRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return ApprovalStep
    }

    private async setDataChange(event: UpdateEvent<ApprovalStep>) {
        this.fieldsChange = [
            ...event.updatedColumns.map(i => i.propertyName),
            ...event.updatedRelations.map(i => i.propertyName)
        ]
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
            this.lastActionUser?.id
        )
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<ApprovalStep>) {
        try {
            this.afterInsertEntity = structuredClone(event.entity)

            /*not send notify if step submit*/
            if (this.afterInsertEntity.action === ApprovalProcessAction.Submit) return

            if (!await this.canSendNotify(this.afterInsertEntity)) {
                return
            }

            this.approval = await this.officeApprovalRepo.findOneBy({id: this.afterInsertEntity.approvalId})
            if (!this.approval) return

            this.afterInsertApproval = structuredClone(this.approval)

            await this.setDataCommon(this.afterInsertEntity)
            await this.notifyStepNeeded(this.afterInsertEntity)

        } catch (e) {
            console.log('afterInsert ApprovalStep notify error: ', e)
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<ApprovalStep>) {
        try {
            this.afterUpdateEvent = event
            this.afterUpdateEntity = structuredClone(event.entity)
            if (!this.afterUpdateEntity) return

            if (!await this.canSendNotify(this.afterUpdateEntity)) {
                return
            }

            this.approval = await this.officeApprovalRepo.findOneBy({id: this.afterUpdateEntity.approvalId})

            if (!this.approval) return

            this.afterUpdateApproval = structuredClone(this.approval)

            await this.setDataChange(this.afterUpdateEvent)
            await this.setDataCommon(this.afterUpdateEntity)

            await this.sendNotifyToPastActionUsers(this.afterUpdateEntity)
            await this.checkAndSendNotifyToUserCanAction(this.afterUpdateEntity)
            await this.sendNotifyToSubscribers(this.afterUpdateEntity)

            if (!event.updatedColumns.map(i => i.propertyName).includes('action')) return

        } catch (e) {
            console.log('afterUpdate ApprovalStep error', e)
        }
    }

    private updateEventData(entity: ApprovalStep | ObjectLiteral) {
        if (entity?.id === this.afterInsertEntity?.id) {
            this.approval = this.afterInsertApproval
        } else {
            this.approval = this.afterUpdateApproval
        }

        return !!this.approval
    }

    private getDataToNotifyContent(entity: ApprovalStep | ObjectLiteral) {
        if (!this.updateEventData(entity)) return

        return {
            approvalName: this.approval.name,
            requesterName: this.requester?.fullname,
            userActionName: this.lastActionUser?.fullname
        }
    }

    private async canSendNotify(entity: ApprovalStep | ObjectLiteral) {
        const approval = await this.officeApprovalRepo.findOneBy({id: entity.approvalId})

        /*Not have approval yet - not draft*/
        if (!approval) {
            return false
        }

        return ![ApprovalStatus.Draft, ApprovalStatus.Forward].includes(approval.status)
    }

    private async setDataCommon(entity: ApprovalStep | ObjectLiteral) {
        if (!this.updateEventData(entity)) return

        this.submitStep = await this.approvalStepRepo.getSubmitStepOfApproval(entity.approvalId)
        this.requester = await this.officeUserRepo.getUserAllWayById(this.submitStep.createdBy)
        this.lastActionUser = await this.officeUserRepo.getUserAllWayById(entity.updatedBy ?? entity.createdBy)
        this.metadata = {requestId: this.approval.id, approvalType: this.approval.type}
    }

    private async sendNotifyToUserCanAction(entity: ApprovalStep | ObjectLiteral) {
        if (!this.updateEventData(entity)) return

        switch (entity.approvalAction) {
            case ApprovalAction.Approve:
                this.notifyType = NotifyType.Approval.Submitted
                this.notifyTitle = NotifyMessageTitle.Approval.Submitted(this.approval)
                this.notifyContent = NotifyMessageContent.Approval.Submitted({approvalName: this.approval?.name, requesterName: this.requester?.fullname})
                this.receiverIds = entity.approveBy
                break
            case ApprovalAction.Consent:
                this.notifyType = NotifyType.Approval.Consent
                this.notifyTitle = NotifyMessageTitle.Approval.Submitted(this.approval)
                this.notifyContent = NotifyMessageContent.Approval.Consent({approvalName: this.approval?.name, requesterName: this.requester?.fullname})
                this.receiverIds = entity.consentBy
                break
        }

        if (this.approval.relationId) {
            this.notifyTitle = NotifyMessageTitle.Approval.Title(this.approval)
            this.notifyContent = NotifyMessageContent.Approval.ActionHaveRelation(await this.getDataByRelation(entity))
        }

        this.receiverIds = this.receiverIds?.filter(i => i !== this.lastActionUser?.id)

        return this.notify()
    }

    private async checkAndSendNotifyToUserCanAction(entity: ApprovalStep | ObjectLiteral) {
        if (!this.fieldsChange.includes('canAction') || !entity.canAction) return

        await this.sendNotifyToUserCanAction(entity)
    }

    /*CR: only creator get notify*/
    private async sendNotifyToPastActionUsers(entity: ApprovalStep | ObjectLiteral) {
        if (!this.fieldsChange.includes('canAction') || entity.canAction) return

        if (!this.updateEventData(entity)) return

        switch (entity.action) {
            case ApprovalProcessAction.Approve:
                this.notifyType = NotifyType.Approval.Approved
                this.notifyTitle = NotifyMessageTitle.Approval.Approved(this.approval)
                this.notifyContent = NotifyMessageContent.Approval.Approved(this.getDataToNotifyContent(entity))
                break
            case ApprovalProcessAction.Reject:
                this.notifyType = NotifyType.Approval.Reject
                this.notifyTitle = NotifyMessageTitle.Approval.Reject(this.approval)
                this.notifyContent = NotifyMessageContent.Approval.Reject(this.getDataToNotifyContent(entity))
                break
            case ApprovalProcessAction.Consent:
                this.notifyType = NotifyType.Approval.Consented
                this.notifyTitle = NotifyMessageTitle.Approval.Consented(this.approval)
                this.notifyContent = NotifyMessageContent.Approval.Consented(this.getDataToNotifyContent(entity))
                break
            case ApprovalProcessAction.Grant:
                this.notifyType = NotifyType.Approval.Grant
                this.notifyTitle = NotifyMessageTitle.Approval.Grant(this.approval)
                this.notifyContent = NotifyMessageContent.Approval.Grant(this.getDataToNotifyContent(entity))
                break
            case ApprovalProcessAction.Pending:
                this.notifyType = NotifyType.Approval.Pending
                this.notifyTitle = NotifyMessageTitle.Approval.Pending(this.approval)
                this.notifyContent = NotifyMessageContent.Approval.Pending(this.getDataToNotifyContent(entity))
                break
            default:
                return
        }

        if (this.approval.relationId) {
            this.notifyTitle = NotifyMessageTitle.Approval.Title(this.approval)
            this.notifyContent = NotifyMessageContent.Approval.ActedHaveRelation(await this.getDataByRelation(entity))
        }

        this.receiverIds = [this.requester.id]

        return this.notify()
    }

    private async sendNotifyToSubscribers(entity: ApprovalStep | ObjectLiteral) {
        if (!this.updateEventData(entity)) return

        switch (entity.action) {
            case ApprovalProcessAction.Approve:
                this.notifyType = NotifyType.Approval.Subscriber.Approval.Action
                this.notifyTitle = NotifyMessageTitle.Approval.Approved(this.approval)
                this.notifyContent = NotifyMessageContent.Approval.Subscriber.Approved(this.getDataToNotifyContent(entity))
                break
            case ApprovalProcessAction.Reject:
                this.notifyType = NotifyType.Approval.Subscriber.Approval.Action
                this.notifyTitle = NotifyMessageTitle.Approval.Reject(this.approval)
                this.notifyContent = NotifyMessageContent.Approval.Subscriber.Reject(this.getDataToNotifyContent(entity))
                break
            case ApprovalProcessAction.Grant:
                this.notifyType = NotifyType.Approval.Subscriber.Approval.Action
                this.notifyTitle = NotifyMessageTitle.Approval.Grant(this.approval)
                this.notifyContent = NotifyMessageContent.Approval.Subscriber.Grant(this.getDataToNotifyContent(entity))
                break
            case ApprovalProcessAction.Pending:
                this.notifyType = NotifyType.Approval.Subscriber.Approval.Action
                this.notifyTitle = NotifyMessageTitle.Approval.Pending(this.approval)
                this.notifyContent = NotifyMessageContent.Approval.Subscriber.Pending(this.getDataToNotifyContent(entity))
                break
            case ApprovalProcessAction.Consent:
                this.notifyType = NotifyType.Approval.Subscriber.Approval.Action
                this.notifyTitle = NotifyMessageTitle.Approval.Consented(this.approval)
                this.notifyContent = NotifyMessageContent.Approval.Subscriber.Consented(this.getDataToNotifyContent(entity))
                break
            default:
                return
        }

        this.metadata = {requestId: this.approval.id, approvalType: this.approval.type}
        this.receiverIds = this.approval.subscriberIds

        return this.notify()
    }

    private async notifyStepNeeded(entity: ApprovalStep | ObjectLiteral) {
        switch (entity.action) {
            case ApprovalProcessAction.Grant:
                await this.notifyToGrantUser(entity)
            case ApprovalProcessAction.Pending:
                await this.sendNotifyToPastActionUsers(entity)
                await this.sendNotifyToSubscribers(entity)
                break
        }

        if (entity.canAction) {
            await this.sendNotifyToUserCanAction(entity)
        }
    }

    private async notifyToGrantUser(entity: ApprovalStep | ObjectLiteral) {
        let grantTo = entity.grantTo
        if (entity.grantToType === GrantType.Department) {
            const tmp = await OfficeOrgChart.findOneBy({id: grantTo})
            grantTo = tmp?.approverId
        }

        if (!grantTo) return

        if (!this.updateEventData(entity)) return

        this.notifyType = NotifyType.Approval.Submitted
        this.notifyTitle = NotifyMessageTitle.Approval.Submitted(this.approval)
        this.notifyContent = NotifyMessageContent.Approval.GrantSubmitted({approvalName: this.approval.name, userActionName: this.lastActionUser.fullname})
        this.metadata = {requestId: this.approval?.id, approvalType: this.approval?.type}
        this.receiverIds = [grantTo]

        await this.notify()
    }

    private async getDataByRelation(entity: ApprovalStep | ObjectLiteral) {
        if (!this.updateEventData(entity)) return

        const args = {
            approvalAction: entity.approvalAction,
            type: this.approval.type,
            relationName: null,
            action: entity.action,
        }

        switch (this.approval.type) {
            case ApprovalType.WikiRelease:
                const version = await this.versionWikiRepo.getBy({id: this.approval.relationId}, ['wiki'])
                args.relationName = `${version?.wiki?.name}`
        }

        return args
    }
}