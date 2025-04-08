import { Injectable } from "@nestjs/common";
import {
    Connection,
    EntitySubscriberInterface,
    InsertEvent,
    ObjectLiteral,
    SoftRemoveEvent,
    UpdateEvent
} from "typeorm";
import { DocumentWiki } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { VersionWikiRepo } from "@models/repositories";

@Injectable()
// @EventSubscriber()
export class WikiSubscriber implements EntitySubscriberInterface<DocumentWiki> {
    private entity: ObjectLiteral;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @InjectRepository(VersionWikiRepo)
        private readonly versionWikiRepo: VersionWikiRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to DocumentWiki events.
     */
    listenTo() {
        return DocumentWiki
    }

    /**
     * Called before entity insertion.
     */
    async beforeInsert(event: InsertEvent<DocumentWiki>) {
    }

    /**
     * Called before entity removal.
     */
    async beforeSoftRemove(event: SoftRemoveEvent<DocumentWiki>) {
        try {
            const notApprovalVersions = await this.versionWikiRepo.getWaitToApprovalOfWiki(event.entity.id)

            for (const version of notApprovalVersions) {
                await version.softRemove()
            }

        } catch (e) {
            console.log(`beforeSoftRemove DocumentWiki error`, e)
        }
    }
}