import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent, ObjectLiteral, UpdateEvent } from "typeorm";
import { VersionWiki } from "@models/entities";
import { NotificationService } from "@core/iam/notification/notification.service";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";
import { VersionWikiRepo, WikiRepo } from "@models/repositories";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { DocumentService } from "@modules/graphql/management/document/document.service";
import { WIKI_COPY_VERSION } from "../../../constant/wiki.const";

@Injectable()
// @EventSubscriber()
export class VersionWikiNotify implements EntitySubscriberInterface<VersionWiki> {
    private eventUpdate: UpdateEvent<VersionWiki>;
    private oldVal: VersionWiki;
    private newVal: ObjectLiteral;
    private fieldsChange: string[];
    private notifyType: string;
    private notifyTitle: any;
    private notifyContent: string;
    private receiverIds: any;
    private metadata: any;
    private userActionId: string;
    private eventInsert: InsertEvent<VersionWiki>;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        @Inject(forwardRef(() => DocumentService))
        private readonly documentService: DocumentService,
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
        return VersionWiki
    }

    private notify() {
        if (!this.receiverIds?.length) return

        return this.notificationService.systemDestinationPushQueue(
            this.notifyType,
            this.notifyTitle,
            this.notifyContent,
            '',
            JSON.stringify(this.metadata),
            this.receiverIds,
            null,
            process.env.OFFICE_ORGANIZATION_ID,
            this.userActionId
        )
    }

    /**
     * Called before entity insertion.
     */
    async beforeInsert(event: InsertEvent<VersionWiki>) {
        try {
            this.eventInsert = event

            await this.notifyIfIsCopy(event.entity)

        } catch (e) {
            console.log('beforeInsert VersionWiki notify error: ', e)
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<VersionWiki>) {
        try {
            this.eventUpdate = event

            this.getDataChange()

            // await this.checkLatest()
        } catch (e) {
            console.log('afterUpdate VersionWiki notify error', e)
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

    private async checkLatest() {
        if (!this.fieldsChange.includes('isLatestVersion') || !this.eventUpdate.entity.isLatestVersion) return

        const entity = await this.versionWikiRepo.getBy({id: this.eventUpdate.entity.id}, ['wiki'])
        const wiki = await this.wikiRepo.getBy({id: entity.wiki.id}, ['folder'])

        this.notifyType = NotifyType.Wiki.Public
        this.notifyTitle = NotifyMessageTitle.Wiki.Public()
        this.notifyContent = NotifyMessageContent.Wiki.Public({
            name: `${entity.name} ${entity.versionTitle}`
        })
        this.metadata = {wikiId: wiki?.id, versionId: entity?.id}
        this.receiverIds = await this.documentService.getAllUserIdCanViewDocument(wiki.folder.id)
        this.userActionId = entity?.createdBy

        await this.notify()
    }

    private async notifyIfIsCopy(entity: VersionWiki) {
        if (entity.version === WIKI_COPY_VERSION) {
            const wiki = await this.wikiRepo.getBy({id: entity.wiki.id}, ['folder'])

            this.notifyType = NotifyType.Wiki.Copy
            this.notifyTitle = NotifyMessageTitle.Wiki.Default()
            this.notifyContent = NotifyMessageContent.Wiki.Copy(entity)
            this.metadata = {wikiId: wiki?.id, versionId: entity?.id}
            this.receiverIds = [entity?.createdBy]
            this.userActionId = entity?.createdBy

            await this.notify()
        }
    }
}