import * as dotenv from 'dotenv';

dotenv.config();

import { searchClient } from "@algolia/client-search";
import { ChatType } from "@enum/chat/chat.enum";
import {
    OfficeChatMessageSearchArgs
} from "@modules/chat-firebase/dto/chat-firebase.arg";
import { RequestContext } from "@common/context/request.context";

const client = searchClient(process.env.ALGOLIA_API_ID, process.env.ALGOLIA_API_KEY)
const clientP = process.env.ALGOLIA_API_ID_P ? searchClient(process.env.ALGOLIA_API_ID_P, process.env.ALGOLIA_API_KEY_P) : client

export const getSearchClient = () => client

async function algoliaSearchMessageCommon(param: OfficeChatMessageSearchArgs, ids?: string[]) {
    const request = getSearchRequestCommon(param)

    request['filters'] = await getSearchRequestFilters(param, ids)

    const { results } = await client.search({
        requests: [request],
    })

    return results[0]
}

async function algoliaSearchMessageConversation(param: OfficeChatMessageSearchArgs) {
    const ownerId = await RequestContext.currentId()
    const { results } = await client.search({
        requests: [{
            indexName: process.env.ALGOLIA_APP_INDEX_MESSAGE,
            advancedSyntax: true,
            query: `"messages/${ownerId}/${param.partnerId}"`,
            hitsPerPage: 10000,
            restrictSearchableAttributes: ['path']
        }],
    })
    return results[0]['hits'].map(i => i.id);
}

export async function algoliaSearchMessage(param: OfficeChatMessageSearchArgs) {
    switch (param.chatType) {
        case ChatType.Group:
            return algoliaSearchMessageCommon(param)
        case ChatType.Conversation:
            const ids = await algoliaSearchMessageConversation(param)
            return algoliaSearchMessageCommon(param, ids)
        default:
            return null
    }
}

export async function algoliaUpdateGroupMessage() {
    const request = {
        indexName: process.env.ALGOLIA_APP_INDEX_GROUP,
        hitsPerPage: 1000,
    }

    const { results } = await clientP.search({
        requests: [request],
    })

    console.log('algoliaUpdateGroupMessage result', results[0]['hits'].length)

    const data = results[0]['hits'].filter(i => !i.groupId)

    // console.log('result', results[0]['hits'])
    console.log('algoliaUpdateGroupMessage data', data.length)

    if (data.length) {
        await clientP.partialUpdateObjects({
            indexName: process.env.ALGOLIA_APP_INDEX_GROUP,
            objects: data.map(i => ({
                objectID: i.objectID,
                groupId: i.path ? i.path.split('/')[1] : ''
            }))
        })
    }
}

function getSearchRequestCommon(param: OfficeChatMessageSearchArgs) {
    const {chatType, page, size, keyword} = param

    let indexName = process.env.ALGOLIA_APP_INDEX_MESSAGE

    if (chatType === ChatType.Group) indexName = process.env.ALGOLIA_APP_INDEX_GROUP

    const request = {
        indexName,
        query: keyword,
        restrictSearchableAttributes: ['message']
    }

    if (page && size) {
        request['page'] = page - 1
        request['hitsPerPage'] = size
    }

    return request
}

function addFilterIfNotNull(filters: string, newFilter: string | null, operation: string = 'AND') {
    if (!newFilter) return filters

    return `${filters} ${operation} (${newFilter})`
}

async function getSearchRequestFilters(param: OfficeChatMessageSearchArgs, ids?: string[]) {
    const {chatType, partnerId, groupId, chatMessageType} = param
    const messageTypeFilter = chatMessageType ? chatMessageType.map(i => `messageType:${i}`).join(' OR ') : null
    let filters: string

    switch (chatType) {
        case ChatType.Group:
            filters = addFilterIfNotNull(`groupId:${groupId}`, messageTypeFilter)
            break
        case ChatType.Conversation:
        default:
            const ownerId = await RequestContext.currentId()
            filters = addFilterIfNotNull(`(senderId:${ownerId} OR senderId:${partnerId}) AND (receiverId:${ownerId} OR receiverId:${partnerId})`, messageTypeFilter)
            break
    }

    if (ids) {
        const objectId = ids.map(i => `id:${i}`).join(' OR ')
        filters = addFilterIfNotNull(filters, objectId)
    }

    return filters
}