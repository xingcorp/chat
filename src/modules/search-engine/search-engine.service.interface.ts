import { OfficeChatConversation, OfficeChatConversationMember, OfficeChatMessage } from "@models/entities";
import { ChatMessageType } from "@enum/chat/message.chat.enum";
import {
    OfficeChatMessageSearchArgs
} from "@modules/chat-firebase/dto/chat-firebase.arg";
export enum CHAT_COLLECTIONS {
    MESSAGES = "messages",
    CONVERSATION = "conversation",
    GROUP = "group",
}

export interface SearchEngineServiceInterface {
    createMessage(entity: OfficeChatMessage): Promise<any>;

    createConversation(entity: OfficeChatConversation): Promise<any>;

    createConversationMember(entity: OfficeChatConversationMember): Promise<any>;

    updateConversation(entity: OfficeChatMessage, document: any): Promise<any>;

    messageFindBy(param: {
        minTime?: string;
        maxTime?: string;
        conversationId?: string;
        partnerId?: string;
        size: number;
        keyword?: string;
        type?: ChatMessageType;
        userId: string
    }): Promise<any>;

    removeCollection(collection: string): Promise<any>;

    messageListBy(param: {lastTime?: string; size: number; conversationId?: string; partnerId?: string; keyword?: string; type?: ChatMessageType; userId: string}): Promise<any>;

    conversationListBy(param: {maxTime?: string; size: number; minTime?: string; keyword?: string; userId: string}): Promise<any>;

    searchMessage(args: OfficeChatMessageSearchArgs): Promise<any>;
}
