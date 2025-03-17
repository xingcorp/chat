import { Connection, EntitySubscriberInterface, EventSubscriber, InsertEvent, RemoveEvent, UpdateEvent } from "typeorm";
import { OfficeUser } from "@models/entities";
import { Inject, Injectable } from "@nestjs/common";
import { ChatFirebaseService } from "@modules/chat-firebase/chat-firebase.service";
import { InjectConnection } from "@nestjs/typeorm";

@Injectable()
// @EventSubscriber()
export class CrudChatUserSubscriber implements EntitySubscriberInterface<OfficeUser> {

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(ChatFirebaseService) public readonly chatService: ChatFirebaseService,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return OfficeUser
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<OfficeUser>) {
        try {
            await this.chatService.createUser(event.entity)
        } catch (e) {
            console.log('create user firebase error', e)
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<OfficeUser>) {
        try {
            await this.chatService.updateUser(event.entity)
        } catch (e) {
            console.log('update user firebase error', e)
        }
    }

    /**
     * Called after entity removal.
     */
    async afterRemove(event: RemoveEvent<OfficeUser>) {
        try {
            await this.chatService.removeUser(event.entity)
        } catch (e) {
            console.log('remove user firebase error', e)
        }
    }
}