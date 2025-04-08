import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, ObjectLiteral, UpdateEvent } from "typeorm";
import { DocumentWiki } from "@models/entities";
import { NotificationService } from "@core/iam/notification/notification.service";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";
import { FolderDocumentRepo, VersionWikiRepo, WikiRepo } from "@models/repositories";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { DocumentService } from "@modules/graphql/management/document/document.service";

@Injectable()
// @EventSubscriber()
export class WikiNotify implements EntitySubscriberInterface<DocumentWiki> {
    private eventUpdate: UpdateEvent<DocumentWiki>;
    private oldVal: DocumentWiki;
    private newVal: ObjectLiteral;
    private fieldsChange: string[];
    private notifyType: string;
    private notifyTitle: any;
    private notifyContent: string;
    private receiverIds: any;
    private metadata: any;
    private userActionId: string;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        @Inject(forwardRef(() => DocumentService))
        private readonly documentService: DocumentService,
        @InjectRepository(WikiRepo)
        private readonly wikiRepo: WikiRepo,
        @InjectRepository(FolderDocumentRepo)
        private readonly folderDocumentRepo: FolderDocumentRepo,
        @InjectRepository(VersionWikiRepo)
        private readonly versionWikiRepo: VersionWikiRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return DocumentWiki
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
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<DocumentWiki>) {
        try {
            this.eventUpdate = event

            this.fieldsChange = this.getDataChange()

            await this.sendNotifyIfWikiPublic(event)
            await this.sendNotifyIfWikiMove(event)
        } catch (e) {
            console.log('afterUpdate DocumentWiki notify error', e)
        }
    }

    private getDataChange() {
        const event = this.eventUpdate

        this.oldVal = event.databaseEntity
        this.newVal = event.entity

        return [...new Set([
            ...event.updatedColumns.map(i => i.propertyName),
            ...event.updatedRelations.map(i => i.propertyName)
        ])]
    }

    private async sendNotifyIfWikiMove(event: UpdateEvent<DocumentWiki>) {
        if (!this.fieldsChange.includes('folder')) return

        const oldWiki = await this.wikiRepo.getBy({id: event.entity.id}, ['folder'])
        const oldFolder = oldWiki.folder

        const newFolderId = event.entity?.folder?.id
        const newFolder = await this.folderDocumentRepo.getBy({id: newFolderId})

        const listUserIdCanViewOld = await this.documentService.getAllUserIdCanViewWiki(oldFolder.id, event.entity.id)
        const listUserIdCanViewNew = await this.documentService.getAllUserIdCanViewWiki(newFolder.id, event.entity.id)

        /*notify to list user still viewing this wiki*/
        const listUserIdStillViewing = listUserIdCanViewNew.filter(i => listUserIdCanViewOld.includes(i))
        await this.notifyWikiHasMove(oldWiki, listUserIdStillViewing)
    }

    private async notifyWikiHasMove(entity: DocumentWiki, receiver: any[]) {
        if (!receiver?.length) return

        this.notifyType = NotifyType.Wiki.Move
        this.notifyTitle = NotifyMessageTitle.Wiki.Default()
        this.notifyContent = NotifyMessageContent.Wiki.Move.StillView({
            name: `${entity.name}`
        })
        this.metadata = {wikiId: entity?.id}
        this.receiverIds = receiver
        this.userActionId = entity?.createdBy

        await this.notify()
    }

    private async sendNotifyIfWikiPublic(event: UpdateEvent<DocumentWiki>) {
        if (!this.fieldsChange.includes('isPublic') || !event.entity.isPublic) return

        try {
            const wiki = await this.wikiRepo.getBy({id: event.entity.id}, ['folder'])
            const version = await this.versionWikiRepo.getLatestVersionOfWiki(wiki.id) ??
                await this.versionWikiRepo.getNewestVersionOfWiki(wiki.id)

            this.notifyType = NotifyType.Wiki.Public
            this.notifyTitle = NotifyMessageTitle.Wiki.Public()
            this.notifyContent = NotifyMessageContent.Wiki.Public({
                name: `${event.entity.name}`
            })
            this.metadata = {wikiId: event.entity?.id, versionId: version?.id}
            this.receiverIds = await this.documentService.getAllUserIdCanViewWiki(wiki.folder.id, wiki.id)
            this.userActionId = version?.createdBy

            console.log('sendNotifyIfWikiPublic data', this.notifyType, this.notifyTitle, this.notifyContent, this.metadata, this.userActionId)

            await this.notify()
        } catch (e) {
            console.log('sendNotifyIfWikiPublic error', e)
        }

    }
}