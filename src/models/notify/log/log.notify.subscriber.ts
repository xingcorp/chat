import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent } from "typeorm";
import { OfficeApproval, OfficeLogs } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { OfficeApprovalRepo, OfficeLogRepo, OfficeUserPaycheckRepo, VersionWikiRepo } from "@repositories/index";
import { OfficeFeatureLogType, OfficeLogType } from "@enum/logs/logs.enum";
import { NotificationService } from "@core/iam/notification/notification.service";
import { NotifyType } from "@common/notify.message";
import { RequestContext } from "@common/context/request.context";
import { ApprovalStatus } from "@models/entities/approval";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";

@Injectable()
// @EventSubscriber()
export class LogNotifySubscriber implements EntitySubscriberInterface<OfficeLogs> {
    private receiverIds: string[] = [];
    private metadata: object = {};
    private entity: OfficeLogs;
    private notifyType: string;
    private notifyTitle: string;
    private notifyContent: string;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        @InjectRepository(OfficeLogRepo)
        private readonly officeLogRepo: OfficeLogRepo,
        @InjectRepository(OfficeUserPaycheckRepo)
        private readonly officeUserPaycheckRepo: OfficeUserPaycheckRepo,
        @InjectRepository(OfficeApprovalRepo)
        private readonly officeApprovalRepo: OfficeApprovalRepo,
        @InjectRepository(VersionWikiRepo)
        private readonly versionWikiRepo: VersionWikiRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return OfficeLogs
    }

    private async notifyCommentCreate() {
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
    async afterInsert(event: InsertEvent<OfficeLogs>) {
        try {
            this.entity = event.entity

            switch (this.entity.type) {
                case OfficeLogType.Comment:
                    return this.notifyLogCommentCreate()
                default:
                    return
            }
        } catch (e) {
            console.log('Called after OfficeLogs insertion error: ', e)
        }
    }

    private notifyLogCommentCreate() {
        switch (this.entity.featureLogType) {
            case OfficeFeatureLogType.Paycheck:
                return this.notifyPaycheckCommentCreate()
            case OfficeFeatureLogType.Approval:
                return this.notifyApprovalCommentCreate()
            case OfficeFeatureLogType.VersionWiki:
                return this.notifyVersionWikiCommentCreate()
            default:
                return
        }
    }

    private async notifyPaycheckCommentCreate() {
        if (RequestContext.isNormalUser()) return null

        const paycheck = await this.officeUserPaycheckRepo.getById(this.entity.featureLogId)
        this.notifyType = NotifyType.PaycheckCommentCreate
        this.notifyTitle = paycheck.name
        this.notifyContent = this.entity.description ?? ''
        this.metadata = {
            paycheckId: this.entity.featureLogId
        }
        this.receiverIds = [paycheck.user.id]

        return this.notifyCommentCreate()
    }

    private async notifyApprovalCommentCreate() {
        const approval = await this.officeApprovalRepo.findOneBy({id: this.entity.featureLogId})

        if (!this.isApprovalCanSendNotify(approval)) return

        this.notifyType = NotifyType.ApprovalCommentCreate
        this.notifyTitle = approval.name
        this.notifyContent = this.entity.description ?? ''
        this.metadata = {
            requestId: approval.id,
            approvalType: approval.type
        }
        const currentId = await RequestContext.currentId()
        this.receiverIds = (await this.officeApprovalRepo.getAllUserIdListenerById(approval.id)).filter(i => i !== currentId)

        return this.notifyCommentCreate()
    }

    private async notifyVersionWikiCommentCreate() {
        const version = await this.versionWikiRepo.getBy({id: this.entity.featureLogId}, ['wiki'])

        this.notifyType = NotifyType.Wiki.Version.Comment
        this.notifyTitle = version.fullName
        this.notifyContent = this.entity.description ?? ''
        this.metadata = {
            wikiId: version.wiki.id,
            versionId: version.id
        }
        const currentId = await RequestContext.currentId()
        this.receiverIds = arrayConvertToDistinctAndNotNull([version.createdBy, version.wiki.createdBy].filter(i => i !== currentId))

        return this.notifyCommentCreate()
    }

    private isApprovalCanSendNotify(approval: OfficeApproval) {
        return ![ApprovalStatus.Draft, ApprovalStatus.Forward].includes(approval.status)
    }
}