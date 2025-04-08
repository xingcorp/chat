import { Int, Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { OfficeChatConversationMember, OfficeUser } from "@models/entities";
import { RedisService } from "@core/common/redis.service";
import { ChatConversationMemberRepo, OfficeUserRepo } from "@models/repositories";
import { LoggerService } from "@core/common/logger.service";

@Resolver(_of => OfficeChatConversationMember)
export class ConversationMemberFieldResolver {
    logger = new LoggerService(ConversationMemberFieldResolver.name)

    constructor(
        private readonly redisService: RedisService,
        private readonly chatConversationMemberRepo: ChatConversationMemberRepo,
        private readonly officeUserRepo: OfficeUserRepo
    ) { }

    @ResolveField('user', _return => OfficeUser, { nullable: true })
    async user(
        @Parent() root: OfficeChatConversationMember
    ) {
        try {
            if (root.userId) {
                const userProfile = await this.officeUserRepo.getPublicProfileUser(root.userId)
                return userProfile
            }
        } catch (error) {
            this.logger.error(`[ConversationMemberFieldResolver] Field user`, error);
        }
    }

    @ResolveField('unreadCount', _return => Int, { nullable: true })
    async unreadCount(
        @Parent() root: OfficeChatConversationMember
    ) {
        if (!root.conversationId || !root.userId) {
            return root.unreadCount
        }

        const unreadCount = await this.chatConversationMemberRepo.getUnreadCount(root.conversationId, root.userId);
        return unreadCount
    }

    @ResolveField('lastMessageReadId', _return => String, { nullable: true })
    async lastMessageReadId(
        @Parent() root: OfficeChatConversationMember
    ) {
        if (!root.conversationId || !root.userId) {
            return root.lastMessageReadId
        }

        const redisValue = await this.chatConversationMemberRepo.getLastMessageReadId(root.conversationId, root.userId);

        return redisValue
    }
}