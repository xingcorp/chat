import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent } from "typeorm";
import { OfficeLogs } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { NotificationService } from "@core/iam/notification/notification.service";
import { OfficeApprovalRepo, OfficeLogRepo, OfficeUserPaycheckRepo, OfficeUserRepo } from "@models/repositories";
import { OfficeFeatureLogType, OfficeLogType } from "@enum/logs/logs.enum";

@Injectable()
// @EventSubscriber()
export class OfficeLogSubscriber implements EntitySubscriberInterface<OfficeLogs> {
    private entity: OfficeLogs;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @InjectRepository(OfficeLogRepo)
        private readonly officeLogRepo: OfficeLogRepo,
        @InjectRepository(OfficeUserPaycheckRepo)
        private readonly officeUserPaycheckRepo: OfficeUserPaycheckRepo,
        private readonly approvalRepo: OfficeApprovalRepo,
        private readonly userRepo: OfficeUserRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return OfficeLogs
    }

    private async handleBeforeInsertCommentPaycheck() {
        if (this.entity.userCreator) {
            await this.officeUserPaycheckRepo.changeStatusToInProgressById(this.entity.featureLogId)
        }
    }

    private handleBeforeInsertComment() {
        switch (this.entity.featureLogType) {
            case OfficeFeatureLogType.Paycheck:
                return this.handleBeforeInsertCommentPaycheck()
            default:
                return
        }
    }

    /**
     * Called before entity insertion.
     */
    beforeInsert(event: InsertEvent<OfficeLogs>) {
        try {
            this.entity = event.entity

            switch (this.entity.type) {
                case OfficeLogType.Comment:
                    return this.handleBeforeInsertComment()
                default:
                    return
            }
        } catch (e) {
            console.log('Called before OfficeLogs insertion error: ', e)
        }
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<OfficeLogs>) {
        try {
            this.entity = event.entity

            switch (this.entity.type) {
                case OfficeLogType.Comment:
                    return this.handleAfterInsertComment()
                default:
                    return
            }
        } catch (e) {
            console.log('afterInsert StepApprovalSubscriber err', e)
        }
    }


    private handleAfterInsertComment() {
        switch (this.entity.featureLogType) {
            case OfficeFeatureLogType.Approval:
                return this.handleAfterInsertCommentApproval()
            default:
                return
        }
    }

    private async handleAfterInsertCommentApproval() {
        await this.approvalRepo.onlyReadByUser(
            this.entity.featureLogId,
            await this.userRepo.getById(this.entity?.userCreator?.id)
        )
    }
}
