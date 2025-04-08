import { Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, EventSubscriber, InsertEvent, RemoveEvent, UpdateEvent } from "typeorm";
import { OfficeChatConversationMember } from "@models/entities";
import { InjectConnection } from "@nestjs/typeorm";
import { LoggerService } from "@core/common/logger.service";
import { ChatConversationMemberRepo } from "@models/repositories";

@Injectable()
@EventSubscriber()
export class ChatConversationMemberSubscriber implements EntitySubscriberInterface<OfficeChatConversationMember> {
    logger = new LoggerService(ChatConversationMemberSubscriber.name)

    constructor(
        @InjectConnection() readonly connection: Connection,
        private readonly chatConversationMemberRepo: ChatConversationMemberRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return OfficeChatConversationMember
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<OfficeChatConversationMember>) {
        try {
            await this.chatConversationMemberRepo.upsertConversationSortedSet(event.entity.userId, event.entity.conversationId)

        } catch (e) {
            console.log('error create conversation search engine', e)
        }
    }

    /**
     * Called after entity is updated in the database.
     */
    async afterUpdate(event: UpdateEvent<OfficeChatConversationMember>) {
        this.logger.log('afterUpdate');
    }

    /**
     * Called after entity is removed from the database.
     */
    async afterRemove(event: RemoveEvent<OfficeChatConversationMember>) {
        this.logger.log('afterRemove');
    }
}
