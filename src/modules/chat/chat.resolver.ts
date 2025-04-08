import { Args, Resolver, Query } from '@nestjs/graphql';
import { SetMetadata } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { OfficeRequesterId } from "@core/middleware/decorator/user.decorator";
import { ChatMessageService } from "@modules/chat/chat-message/chat-message.service";
import { ChatSearchArgs } from './chat.args';
import { ChatConversationRepo } from '@models/repositories';
import { OpenSearchService } from '@modules/search-engine/open-search/open-search.service';
import { OfficeChatMessage } from '@models/entities';
import { LoggerService } from '@core/common/logger.service';

@Resolver()
export class ChatResolver {
    private readonly logger = new LoggerService(ChatResolver.name)

    constructor(
        private readonly chatMessageService: ChatMessageService,
        private readonly conversationRepo: ChatConversationRepo,
        private readonly openSearchService: OpenSearchService<OfficeChatMessage>
    ) { }

    @Query(() => [OfficeChatMessage], { name: 'chatSearch', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async search(
        @Args('filters') args: ChatSearchArgs,
        @OfficeRequesterId() userId: string
    ): Promise<OfficeChatMessage[]> {
        const conversationQuery = this.conversationRepo
            .createQueryBuilder('conversation')
            .leftJoin('conversation.members', 'mc')
            .select(['conversation.id'])
            .where('mc.userId = :userId', { userId })
        if (args.conversationIds) {
            conversationQuery.andWhere('conversation.id IN (:...conversationIds)', { conversationIds: args.conversationIds })
        }
        if (args.conversationTypes) {
            conversationQuery.andWhere('conversation.type IN (:...conversationTypes)', { conversationTypes: args.conversationTypes })
        }
        const conversations = await conversationQuery.getMany();
        const conversationIds = conversations.map(c => c.id)
        if (conversationIds.length <= 0) return []
        const query: any = {
            "bool": {
                "must": [
                    {
                        "terms": {
                            "conversationId": conversationIds
                        }
                    },
                ]
            }
        }
        if (args.senderIds) {
            query.bool.must.push({
                "terms": {
                    "senderId": args.senderIds
                }
            })
        }
        if (args.messageTypes) {
            query.bool.must.push({
                "terms": {
                    "type": args.messageTypes
                }
            })
        }
        if (args.from) {
            query.bool.must.push({
                "range": {
                    "createdAt": {
                        "gte": args.from
                    }
                }
            })
        }
        if (args.to) {
            query.bool.must.push({
                "range": {
                    "createdAt": {
                        "lte": args.to
                    }
                }
            })
        }

        if (args.keyword) {
            query.bool.must.push({
                "bool": {
                    "should": [
                        {
                            "match_phrase": {
                                "message": args.keyword
                            }
                        },
                        {
                            "match_phrase": {
                                "fileName": args.keyword
                            }
                        }
                    ]
                }
            })
        }

        const result = await this.openSearchService.search({
            from: args.page * args.size,
            size: args.size,
            query,
            "highlight": {
                "pre_tags": [
                    '<highlight_pre_tags>'
                ],
                "post_tags": [
                    "</em>"
                ],
                "fields": {
                    "message": {},
                    "fileName": {}
                }
            }
        })
        return result.map(messageOb => {
            Object.keys(messageOb.highlight).forEach(key => {
                messageOb._source[key] = formatHighLightText(messageOb.highlight[key][0])
            })
            return messageOb._source
        })
    }
}

function formatHighLightText(text: string) {
    const textArr = text.split(' ')
    if (textArr.length <= 15) return text.replaceAll('<highlight_pre_tags>', '<em style="color: #00B1D2">')
    const indexHighlight = textArr.findIndex(t => t.includes('<highlight_pre_tags>'))
    const end = indexHighlight + 15
    const start = end >= textArr.length ? textArr.length - 15 : indexHighlight
    const formattedText = textArr.slice(start, end).join(' ').replaceAll('<highlight_pre_tags>', '<em style="color: #00B1D2">')
    if (end >= textArr.length) {
        return `...${formattedText}`
    } else if (end < textArr.length && start > 0) {
        return `...${formattedText}...`
    }
    return `${formattedText}...`
}
