import { Injectable } from "@nestjs/common";
import {
    Connection,
    EntitySubscriberInterface,
    InsertEvent,
    ObjectLiteral,
    SoftRemoveEvent,
    UpdateEvent
} from "typeorm";
import { VersionWiki } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { OfficeApprovalRepo, VersionWikiRepo, WikiRepo } from "@models/repositories";
import { VersionWikiStatus } from "@enum/wiki/wiki.enum";

@Injectable()
// @EventSubscriber()
export class VersionWikiSubscriber implements EntitySubscriberInterface<VersionWiki> {
    private entity: VersionWiki | ObjectLiteral;
    private latestVersion: VersionWiki;
    private eventUpdate: UpdateEvent<VersionWiki>;
    private oldVal: VersionWiki;
    private newVal: ObjectLiteral;
    private fieldsChange: string[];
    private newestVersion: VersionWiki;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @InjectRepository(VersionWikiRepo)
        private readonly versionWikiRepo: VersionWikiRepo,
        @InjectRepository(WikiRepo)
        private readonly wikiRepo: WikiRepo,
        @InjectRepository(OfficeApprovalRepo)
        private readonly approvalRepo: OfficeApprovalRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to VersionWiki events.
     */
    listenTo() {
        return VersionWiki
    }

    /**
     * Called before entity insertion.
     */
    async beforeInsert(event: InsertEvent<VersionWiki>) {
        try {
            this.entity = event.entity
            this.latestVersion = await this.versionWikiRepo.getLatestVersionOfWiki(this.entity?.wiki?.id, ['wiki'])
            this.newestVersion = await this.versionWikiRepo.getNewestVersionOfWiki(this.entity?.wiki?.id, ['wiki'])

            this.genNo()
            this.genVer()
            this.setLastVersion()

        } catch (e) {
            console.log('VersionWikiSubscriber beforeInsert error: ', e)
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<VersionWiki>) {
        try {
            this.eventUpdate = event

            this.getDataChange()

            await this.checkChangeLatestVersion()
            
        } catch (e) {
            console.log('afterUpdate VersionWiki error', e)
        }
    }

    /**
     * Called before entity removal.
     */
    async beforeSoftRemove(event: SoftRemoveEvent<VersionWiki>) {
        try {
            const approval = await this.approvalRepo.getOfVersion(event.entity.id)

            await approval.softRemove()

        } catch (e) {
            console.log(`beforeSoftRemove DocumentWiki error`, e)
        }
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

    private genNo() {
        if (!this.latestVersion) {
            this.entity.no = 1
        } else {
            this.entity.no = this.newestVersion.no + 1
        }
    }

    private genVer() {
        if (this.entity?.status === VersionWikiStatus.Draft) {
            if (this.entity?.version) this.entity.version = null
            return
        }

        if (!this.latestVersion) {
            this.entity.version = this.versionWikiRepo.genFirstVersionDefault()
        } else {
            this.entity.version = this.versionWikiRepo.genNextVersion(this.entity.updateType, this.latestVersion.version)
        }
    }

    private async checkChangeLatestVersion() {
        if (
            this.fieldsChange.includes('isLatestVersion')
            && this.newVal.isLatestVersion
        ) {
            const version = await this.versionWikiRepo.getBy({id: this.newVal?.id}, ['tags', 'wiki'])
            await this.wikiRepo.updateLatestVersion(version)
        }
    }

    private setLastVersion() {
        this.entity.lastVersion = this.latestVersion
    }
}