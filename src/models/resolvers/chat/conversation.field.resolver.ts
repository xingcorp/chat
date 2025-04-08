import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { OfficeChatConversation, OfficeChatConversationMember, OfficeChatMessage, OfficeUser } from "@models/entities";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";
import { ChatConversationMemberRepo, ChatMessageRepo, OfficeUserRepo } from "@models/repositories";
import { ChatModuleTTLRedis } from "@helpers/environment.helper";
import { RequestContext } from "@common/context/request.context";
import { LoggerService } from "@core/common/logger.service";

@Resolver(_of => OfficeChatConversation)
export class ConversationFieldResolver {
    logger = new LoggerService(ConversationFieldResolver.name)
    constructor(
        private readonly redisService: RedisService,
        private readonly chatMessageRepo: ChatMessageRepo,
        private readonly chatConversationMember: ChatConversationMemberRepo,
        private readonly officeUserRepo: OfficeUserRepo
    ) { }


    @ResolveField('lastMessage', _return => OfficeChatMessage, { nullable: true })
    async lastMessage(
        @Parent() root: OfficeChatConversation
    ) {
        try {
            if (root.id && root.lastMessageId && root.lastMessageAt) {
                const redisValue = await this.redisService.get(RedisKey.ConversationLastMessage(root.id));
                let lastMessageId = root.lastMessageId
                if (redisValue) {
                    lastMessageId = JSON.parse(redisValue).lastMessageId
                } else {
                    await this.redisService.setWithTtl(RedisKey.ConversationLastMessage(root.id), JSON.stringify({
                        lastMessageId: lastMessageId,
                        lastMessageAt: new Date(root.lastMessageAt)
                    }), ChatModuleTTLRedis)
                }
                const messageCached = await this.redisService.get(RedisKey.Message(lastMessageId))
                if (!messageCached) {
                    const message = await this.chatMessageRepo.getById(lastMessageId)
                    if (message)
                        await this.redisService.setWithTtl(RedisKey.Message(lastMessageId), JSON.stringify(message), ChatModuleTTLRedis)
                    return message
                }
                return JSON.parse(messageCached)
            }
        } catch (error) {
            this.logger.error(`[ConversationFieldResolver] Field lastMessage`, error);
        }
    }

    @ResolveField('personalConversation', _return => OfficeChatConversationMember, { nullable: true })
    async personalConversation(@Parent() root: OfficeChatConversation) {
        try {
            if (!root.id || root.personalConversation) {
                return root.personalConversation
            }
            const conversationId = root.id
            const requesterId = RequestContext.currentOfficeRequesterId();

            const unreadCount = await this.chatConversationMember.getUnreadCount(conversationId, requesterId);
            const personalConversation = await this.chatConversationMember.findOne({
                where: { userId: requesterId, conversationId },
            })

            personalConversation.unreadCount = unreadCount

            return personalConversation
        } catch (error) {
            this.logger.error(`[ConversationFieldResolver] Field personalConversation`, error);
        }
    }

    @ResolveField('creator', _return => OfficeUser, { nullable: true })
    async creator(
        @Parent() root: OfficeChatConversation
    ) {
        try {
            if (!root.creatorId) {
                return null
            }
            return await this.officeUserRepo.getPublicProfileUser(root.creatorId)
        } catch (error) {
            this.logger.error(`[ConversationFieldResolver] Field creator`, JSON.stringify(error));
        }
    }
}