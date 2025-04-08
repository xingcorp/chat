import { Injectable } from '@nestjs/common';
import { CHAT_COLLECTIONS, SearchEngineServiceInterface } from "@modules/search-engine/search-engine.service.interface";
import { OfficeChatConversation, OfficeChatConversationMember, OfficeChatMessage } from "@models/entities";
import {
    typesenseCheckAndGetDocument,
    typesenseCheckCreateCollection,
    typesenseCollectionRemove,
    typesenseDocumentCreate, typesenseDocumentEmplace, typesenseDocumentSearch
} from "@services/typesense/index.typesense";
import { CollectionCreateSchema } from "typesense/src/Typesense/Collections";
import { normalizeSearchText } from "@utils/string.utils";
import { ChatConversationType } from "@models/entities/chat/conversation.chat";
import { ChatMessageType } from "@enum/chat/message.chat.enum";
import {
    OfficeChatMessageSearchArgs,
} from "@modules/chat-firebase/dto/chat-firebase.arg";

@Injectable()
export class TypesenseService implements SearchEngineServiceInterface {
    async createMessage(entity: OfficeChatMessage): Promise<any> {
        await this.collectionCreateMessage()

        return this.createMessageDocument(entity)
    }

    private async createMessageDocument(entity: OfficeChatMessage) {

        const conversation: any = await typesenseCheckAndGetDocument(CHAT_COLLECTIONS.CONVERSATION, entity.conversationId)

        let document = {
            id: entity.id,
            conversationId: entity.conversationId,
            senderId: entity.senderId,
            memberIds: conversation?.members?.map(i => i.id).filter(i => i !== undefined),
            members: conversation?.members,
            message: entity.message ?? "",
            type: entity.type,
            fullTextSearch: this.getFullTextSearchField(entity.message)
        }

        await typesenseDocumentCreate(CHAT_COLLECTIONS.MESSAGES, document)

        return document
    }

    async createConversation(entity: OfficeChatConversation): Promise<any> {
        await this.collectionCreateConversation()

        return this.upsertConversationDocument(entity)
    }
    async createConversationMember(entity: OfficeChatConversationMember): Promise<any> {
        return this.updateConversationMemberDocument(entity)
    }

    private async upsertConversationDocument(entity: OfficeChatConversation) {
        let document = await typesenseCheckAndGetDocument(CHAT_COLLECTIONS.CONVERSATION, entity.id)

        if (!document) {
            document = {
                id: entity.id,
                type: entity.type,
                lastActiveAt: entity.createdAt.getTime() as number,
                connected: false,
                members: [],
                memberIds: [],
                name: entity.name ?? "",
                imgUrl: entity.imgUrl ?? "",
                groupType: "",
            }
        }

        return typesenseDocumentEmplace(CHAT_COLLECTIONS.CONVERSATION, document)
    }

    private async updateConversationMemberDocument(entity: OfficeChatConversationMember) {
        // let document = await typesenseCheckAndGetDocument(CHAT_COLLECTIONS.CONVERSATION, entity.conversation.id)

        // const user = {
        //     ...entity.user,
        //     fullTextSearch: this.getFullTextSearchField(entity.user.fullname)
        // }
        // if (entity.roomMaster) {
        //     document['senderId'] = entity.user.id
        //     document['sender'] = user
        // } else {
        //     switch(entity.conversation.type) {
        //         case ChatConversationType.Direct:
        //             document['receiverId'] = entity.user.id
        //             document['receiver'] = user
        //             break
        //         case ChatConversationType.Group:
        //         default:
        //     }
        // }
        // document['memberIds'].push(user.id)
        // document['members'].push(user)

        // return typesenseDocumentEmplace(CHAT_COLLECTIONS.CONVERSATION, document)
    }

    async updateConversation(entity: OfficeChatMessage, latestMessage: any): Promise<any> {
        return typesenseDocumentEmplace(CHAT_COLLECTIONS.CONVERSATION, {
            // id: entity.conversation.id,
            latestMessage,
            lastActiveAt: latestMessage.createdAt
        })
    }

    async messageFindBy(param: {
        minTime?: string;
        maxTime?: string;
        size: number;
        conversationId?: string;
        partnerId?: string;
        keyword?: string;
        type?: ChatMessageType;
        userId: string
    }): Promise<any> {
        let searchParameters = {
            'q': '*',
            'filter_by': ``,
            'sort_by': 'createdAt:desc',
            'limit': param.size
        }

        if (param.partnerId) {
            const members = [param.userId, param.partnerId]
            searchParameters['filter_by'] += `senderId:=[${members}] && receiverId:=[${members}]`
        } else {
            searchParameters['filter_by'] += `(senderId:=[${param.userId}] || receiverId:=[${param.userId}])`
        }

        if (param.keyword) {
            searchParameters['q'] = param.keyword
            searchParameters['query_by'] = 'message,stickerPath'
        }

        if (param.conversationId) {
            searchParameters['filter_by'] += ` && conversationId:${param.conversationId}`
        }

        if (param.type) {
            searchParameters['filter_by'] += ` && type:=${param.type}`
        }

        if (param.minTime) {
            searchParameters['filter_by'] += ` && createdAt:>${param.minTime}`
        }

        if (param.maxTime) {
            searchParameters['filter_by'] += ` && createdAt:<${param.maxTime}`
        }

        console.log('search', searchParameters)

        return typesenseDocumentSearch(CHAT_COLLECTIONS.MESSAGES, searchParameters)
    }

    async removeCollection(collection: string): Promise<any> {
        return typesenseCollectionRemove(collection)
    }

    private async collectionCreateConversation() {
        const schema: CollectionCreateSchema = {
            "name": CHAT_COLLECTIONS.CONVERSATION,
            "enable_nested_fields": true,
            "fields": [
                {
                    "facet": false,
                    "index": true,
                    "infix": true,
                    "locale": "",
                    "name": ".*",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "auto"
                },
                {
                    "facet": true,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "connected",
                    "optional": true,
                    "sort": true,
                    "stem": false,
                    "type": "bool"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "groupType",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "lastActiveAt",
                    "optional": true,
                    "sort": true,
                    "stem": false,
                    "type": "int64"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "memberIds",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string[]"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": true,
                    "locale": "",
                    "name": "name",
                    "optional": true,
                    "sort": false,
                    "stem": true,
                    "type": "string"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": true,
                    "locale": "",
                    "name": "imgUrl",
                    "optional": true,
                    "sort": false,
                    "stem": true,
                    "type": "string"
                },
                {
                    "facet": true,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "senderId",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "type",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
                {
                    "facet": true,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "receiverId",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
                {
                    "facet": true,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "members",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "object[]"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "latestMessage.createdAt",
                    "optional": true,
                    "sort": true,
                    "stem": false,
                    "type": "int64"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": true,
                    "locale": "",
                    "name": "latestMessage.fullTextSearch",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "receiver.fullTextSearch",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "sender.fullTextSearch",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": true,
                    "locale": "",
                    "name": "receiver.code",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": true,
                    "locale": "",
                    "name": "sender.code",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
            ],
        }

        return typesenseCheckCreateCollection(schema)
    }

    private async collectionCreateMessage() {
        const schema: CollectionCreateSchema = {
            "name": CHAT_COLLECTIONS.MESSAGES,
            "enable_nested_fields": true,
            "fields": [
                {
                    "facet": false,
                    "index": true,
                    "infix": true,
                    "locale": "",
                    "name": ".*",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "auto"
                },
                {
                    "facet": true,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "conversationId",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "createdAt",
                    "optional": true,
                    "sort": true,
                    "stem": false,
                    "type": "int64"
                },
                {
                    "facet": true,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "isMe",
                    "optional": true,
                    "sort": true,
                    "stem": false,
                    "type": "bool"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "latitude",
                    "optional": true,
                    "sort": true,
                    "stem": false,
                    "type": "float"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "longitude",
                    "optional": true,
                    "sort": true,
                    "stem": false,
                    "type": "float"
                },
                {
                    'name': 'location',
                    'type': 'geopoint'
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": true,
                    "locale": "",
                    "name": "memberIds",
                    "optional": true,
                    "sort": false,
                    "stem": true,
                    "type": "string[]"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": true,
                    "locale": "",
                    "name": "message",
                    "optional": true,
                    "sort": false,
                    "stem": true,
                    "type": "string"
                },
                {
                    "facet": true,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "readBy",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string[]"
                },
                {
                    "facet": true,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "receiverId",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
                {
                    "facet": true,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "senderId",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "stickerPath",
                    "optional": true,
                    "sort": false,
                    "stem": true,
                    "type": "string"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "type",
                    "optional": true,
                    "sort": false,
                    "stem": false,
                    "type": "string"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": false,
                    "locale": "",
                    "name": "photoUrl",
                    "optional": true,
                    "sort": false,
                    "stem": true,
                    "type": "string"
                },
                {
                    "facet": false,
                    "index": true,
                    "infix": true,
                    "locale": "",
                    "name": "fullTextSearch",
                    "optional": true,
                    "sort": false,
                    "stem": true,
                    "type": "string"
                },
            ],
        }

        return typesenseCheckCreateCollection(schema)
    }

    async messageListBy(param: {
        lastTime?: string;
        size: number;
        conversationId?: string;
        partnerId?: string;
        keyword?: string;
        type?: ChatMessageType;
        userId: string
    }): Promise<any> {
        const search = await this.messageFindBy(param)

        return {
            total: search.found,
            records: search.hits.map((i: any) => i.document),
            from: search.hits.length ? search.hits.at(-1).document.createdAt : null,
            to: search.hits.length ? search.hits[0].document.createdAt : null,
        }
    }

    async conversationListBy(param: {
        maxTime?: string;
        size: number;
        minTime?: string;
        keyword?: string;
        userId: string
    }): Promise<any> {
        const search = await this.conversationFindBy(param)

        return {
            total: search.found,
            records: search.hits.map((i: any) => i.document),
            from: search.hits.length ? search.hits.at(-1).document.lastActiveAt : null,
            to: search.hits.length ? search.hits[0].document.lastActiveAt : null,
        }
    }

    private async conversationFindBy(param: {
        maxTime?: string;
        size: number;
        minTime?: string;
        keyword?: string;
        userId: string
    }): Promise<any> {
        let searchParameters = {
            'q': '*',
            'filter_by': `(memberIds:=[${param.userId}])`,
            'sort_by': 'lastActiveAt:desc',
            'limit': param.size
        }

        if (param.keyword) {
            searchParameters['q'] = param.keyword
            searchParameters['query_by'] = 'name,sender.fullTextSearch,receiver.fullTextSearch,sender.code,receiver.code'
            searchParameters['infix'] = 'off,off,off,always,always'
            // searchParameters['query_by'] = 'members.fullTextSearch,members.code'
            // searchParameters['infix'] = 'off,always'
            // searchParameters['filter_by'] +=
            //     ` && ((sender.id:!=[${param.userId}] && sender.fullTextSearch:${param.keyword}) `
            //     + `|| (receiver.id:!=[${param.userId}] && receiver.fullTextSearch:${param.keyword}))`
        }

        if (param.minTime) {
            searchParameters['filter_by'] += ` && lastActiveAt:>${param.minTime}`
        }

        if (param.maxTime) {
            searchParameters['filter_by'] += ` && lastActiveAt:<${param.maxTime}`
        }

        console.log('search', searchParameters)

        return typesenseDocumentSearch(CHAT_COLLECTIONS.CONVERSATION, searchParameters)
    }

    private getFullTextSearchField(...args: string[]) {
        let res = ``
        for (const arg of args) {
            const item = arg ?? ""
            res += ` ${item}`
            res += ` ${normalizeSearchText(item)}`
        }

        return res
    }

    searchMessage(args: OfficeChatMessageSearchArgs): Promise<any> {
        return Promise.resolve(undefined);
    }
}
