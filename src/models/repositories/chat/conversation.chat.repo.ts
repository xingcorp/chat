import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { OfficeChatConversation } from "@models/entities";
import { ChatConversationType } from "@models/entities/chat/conversation.chat";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";
import { ChatModuleTTLRedis } from "@helpers/environment.helper";
import { ChatConversationMemberRepo } from "./conversation-member.chat.repo";

@Injectable()
export class ChatConversationRepo extends Repository<OfficeChatConversation> {
    constructor(
        private dataSource: DataSource,
        private readonly redisService: RedisService,
        private readonly chatConversationMemberRepo: ChatConversationMemberRepo,
    ) {
        super(OfficeChatConversation, dataSource.createEntityManager());
    }

    async createDirectMessage() {
        return this.create({
            type: ChatConversationType.Direct
        })
    }

    async createGroupMessage() {
        return this.create({
            type: ChatConversationType.Group,
            lastMessageAt: new Date()
        })
    }

    async getCachedConversationName(conversationId: string) {
        const cachedName = await this.redisService.get(RedisKey.ConversationName(conversationId))
        if (!cachedName) {
            const conversation = await this.findOne({
                where: { id: conversationId },
                select: ["id", "name"]
            })
            if (conversation.name)
                await this.redisService.setWithTtl(RedisKey.ConversationName(conversationId), conversation.name)
            return conversation.name
        }
        return cachedName
    }

    async getDirectMessage(senderId: string, receiverId: string) {
        return this
            .createQueryBuilder('conversation')
            .innerJoin('conversation.members', 'sender')
            .innerJoin('conversation.members', 'receiver')
            .where('conversation.type = :type', { type: 'Direct' })
            .andWhere('sender.userId = :senderId', { senderId })
            .andWhere('receiver.userId = :receiverId', { receiverId })
            .getOne();
    }

    async haveDirectBetween(receiverId: string, senderId: string) {
        return !!(await this.getDirectMessage(receiverId, senderId))
    }

    async getByIdIncludesMembers(id: string): Promise<OfficeChatConversation> {
        return this.findOne({
            relations: ['members'],
            where: [
                {
                    id,
                }
            ]
        })
    }

    async getListByRequesterId(requesterId: string, conversationIds?: string[]): Promise<OfficeChatConversation[]> {
        if (!conversationIds) {
            conversationIds = await this.chatConversationMemberRepo.getConversationIdsJoined(requesterId)
        }

        if (conversationIds.length <= 0) return []

        const conversations = await this
            .createQueryBuilder('conversation')
            .leftJoin('conversation.members', 'mc')
            .leftJoin('mc.user', 'user')
            .addSelect(['conversation.lastMessageAt', 'conversation.creatorId', 'mc.id', 'mc.userId', 'mc.conversationId', 'mc.unreadCount', 'mc.hide', 'mc.lastMessageReadId', 'user.id', 'user.fullname', 'user.imageUrls'])
            .where('conversation.id IN (:...conversationIds)', { conversationIds })
            .orderBy('conversation.lastMessageAt', 'DESC')
            .getMany();

        return conversations.map((conversation) => {
            if (conversation.type === ChatConversationType.Direct) {
                const partner = conversation.members.length > 1
                    ? conversation.members
                        .find((mc) => mc.user.id !== requesterId)
                        ?.user
                    : conversation.members[0].user;

                conversation.name = partner?.fullname
                conversation.imgUrl = partner && partner.imageUrls && partner.imageUrls.length > 0 ? partner?.imageUrls[0] : null
            }
            const personalConversation = conversation.members
                .find((mc) => mc.user.id == requesterId)
            conversation.personalConversation = personalConversation
            return conversation;
        });
    }

    async getMemberInConversation(conversationId: string) {
        const isCached = await this.redisService.exists(RedisKey.MembersInConversation(conversationId))
        if (!isCached) {
            const dataDb = await this.chatConversationMemberRepo.getMembers(conversationId)
            await this.redisService.sadd(RedisKey.MembersInConversation(conversationId), dataDb, ChatModuleTTLRedis)
            return dataDb
        }
        const cached = await this.redisService.smember(RedisKey.MembersInConversation(conversationId))
        return cached
    }

    async upsertConversationSet(conversationId: string, memberIds: string[]) {
        const isCached = await this.redisService.exists(RedisKey.MembersInConversation(conversationId))
        if (!isCached) {
            const dataDb = await this.chatConversationMemberRepo.getMembers(conversationId)
            await this.redisService.sadd(RedisKey.MembersInConversation(conversationId), dataDb, ChatModuleTTLRedis)
        }
        await this.redisService.sadd(RedisKey.MembersInConversation(conversationId), memberIds, ChatModuleTTLRedis)
    }
}