import { Injectable } from '@nestjs/common';
import { SearchEngineServiceInterface } from "@modules/search-engine/search-engine.service.interface";
import { OfficeChatConversation, OfficeChatConversationMember, OfficeChatMessage } from "@models/entities";
import { ChatMessageType } from "@enum/chat/message.chat.enum";
import {
    OfficeChatMessageSearchArgs
} from "@modules/chat-firebase/dto/chat-firebase.arg";
import { algoliaSearchMessage } from "@services/algolia/search.algolia";

@Injectable()
export class AlgoliaService implements SearchEngineServiceInterface {
    conversationListBy(param: {
        maxTime?: string;
        size: number;
        minTime?: string;
        keyword?: string;
        userId: string
    }): Promise<any> {
        return Promise.resolve(undefined);
    }

    createConversation(entity: OfficeChatConversation): Promise<any> {
        return Promise.resolve(undefined);
    }

    createConversationMember(entity: OfficeChatConversationMember): Promise<any> {
        return Promise.resolve(undefined);
    }

    createMessage(entity: OfficeChatMessage): Promise<any> {
        return Promise.resolve(undefined);
    }

    messageFindBy(param: {
        minTime?: string;
        maxTime?: string;
        conversationId?: string;
        partnerId?: string;
        size: number;
        keyword?: string;
        type?: ChatMessageType;
        userId: string
    }): Promise<any> {
        return Promise.resolve(undefined);
    }

    messageListBy(param: {
        lastTime?: string;
        size: number;
        conversationId?: string;
        partnerId?: string;
        keyword?: string;
        type?: ChatMessageType;
        userId: string
    }): Promise<any> {
        return Promise.resolve(undefined);
    }

    removeCollection(collection: string): Promise<any> {
        return Promise.resolve(undefined);
    }

    updateConversation(entity: OfficeChatMessage, document: any): Promise<any> {
        return Promise.resolve(undefined);
    }

    searchMessage(args: OfficeChatMessageSearchArgs): Promise<any> {
        return algoliaSearchMessage(args)
    }
}
