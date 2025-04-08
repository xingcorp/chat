import { Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent, ObjectLiteral, UpdateEvent } from "typeorm";
import { OfficeApproval, VersionWiki } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { VersionWikiRepo } from "@models/repositories";
import { VersionWikiStatus } from "@enum/wiki/wiki.enum";
import { ApprovalStatus } from "@models/entities/approval";

@Injectable()
// @EventSubscriber()
export class ApprovalSubscriber implements EntitySubscriberInterface<OfficeApproval> {
    private entity: ObjectLiteral;
    private eventUpdate: UpdateEvent<OfficeApproval>;
    private newVal: ObjectLiteral;
    private oldVal: OfficeApproval;
    private fieldsChange: string[];
    private entityInsert: OfficeApproval;
    constructor(
        @InjectConnection() readonly connection: Connection,
        @InjectRepository(VersionWikiRepo)
        private readonly versionWikiRepo: VersionWikiRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return OfficeApproval
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<OfficeApproval>) {
        try {
            this.entityInsert = event.entity

            await this.handleAutoApproved()
        } catch (e) {
            console.log('ApprovalSubscriber afterInsert error', e)
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<OfficeApproval>) {
        try {
            this.eventUpdate = event

            await this.subscriberApterUpdateApprovalOfWiki()
        } catch (e) {
            console.log('ApprovalSubscriber afterUpdate error', e)
        }
    }

    private async subscriberApterUpdateApprovalOfWiki() {
        const event = this.eventUpdate

        this.entity = event.entity

        const version = await this.versionWikiRepo.getBy({
            id: event.entity.relationId
        }, ['wiki'])

        if (!version) return

        this.getDataChange()

        await this.versionWikiUpdateStatus(version)

        await version.save()
    }

    private getDataChange() {
        const event = this.eventUpdate

        this.oldVal = event.databaseEntity
        this.newVal = event.entity
        this.fieldsChange = [...new Set([
            ...event.updatedColumns.map(i => i.propertyName),
            ...event.updatedRelations.map(i => i.propertyName)
        ])]
    }

    private async versionWikiUpdateStatus(version: VersionWiki) {
        if (this.fieldsChange.includes('status')) {
            version.status = VersionWikiStatus[this.newVal.status]

            if (version.status === VersionWikiStatus.Approved) {
                version.isPublic = true

                await this.versionWikiRepo.setLatestVersion(version)
            }
        }
    }

    private async handleAutoApproved() {
        if (this.entityInsert.status === ApprovalStatus.Approved) {
            const version = await this.versionWikiRepo.getBy({
                id: this.entityInsert.relationId
            }, ['wiki'])

            version.status = VersionWikiStatus.Approved
            version.isPublic = true

            await this.versionWikiRepo.setLatestVersion(version)

            await version.save()
        }
    }
}