import { Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, EventSubscriber, InsertEvent, LoadEvent, UpdateEvent } from "typeorm";
import { OfficeChatConversation } from "@models/entities";
import { InjectConnection } from "@nestjs/typeorm";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";
import { LoggerService } from "@core/common/logger.service";

@Injectable()
// @EventSubscriber()
export class ChatConversationSubscriber implements EntitySubscriberInterface<OfficeChatConversation> {
    logger = new LoggerService(ChatConversationSubscriber.name)

    constructor(
        @InjectConnection() readonly connection: Connection,
        private readonly redisService: RedisService
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return OfficeChatConversation
    }

    /**
     * Called after entity insertion.
     */
    // async afterInsert(event: InsertEvent<OfficeChatConversation>) {
    //     try {
    //         switch (event.entity.type) {
    //             case ChatConversationType.Direct:
    //             case ChatConversationType.Group:
    //                 // await typesenseCollectionRemove(CHAT_COLLECTIONS.CONVERSATION)
    //                 return this.searchEngineService.createConversation(event.entity)
    //             default:
    //                 return
    //         }

    //     } catch (e) {
    //         console.log('error create conversation search engine', e)
    //     }
    // }

    /**
     * Called after entity update.
     */
    afterUpdate(event: UpdateEvent<any>) {
        // console.log(`AFTER ENTITY UPDATED: `, event.entity)
    }

    async afterLoad(entity: OfficeChatConversation, event?: LoadEvent<OfficeChatConversation>) {
        if (entity.lastMessageId != undefined || entity.lastMessageAt != undefined) {
            const redisCache = await this.redisService.get(RedisKey.ConversationLastMessage(entity.id))
            if (redisCache) {
                const { lastMessageId, lastMessageAt } = JSON.parse(redisCache)
                entity.lastMessageAt = new Date(lastMessageAt)
                entity.lastMessageId = lastMessageId
            }
        }
    }
}