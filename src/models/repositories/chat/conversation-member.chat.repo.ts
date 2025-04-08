import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { DataSource, In, Repository } from "typeorm";
import { OfficeChatConversation, OfficeChatConversationMember, OfficeUser } from "@models/entities";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";
import { ChatModuleTTLRedis } from "@helpers/environment.helper";
import { ChatConversationRepo } from "./conversation.chat.repo";
import { ChatMessageRepo } from "./message.chat.repo";

@Injectable()
export class ChatConversationMemberRepo extends Repository<OfficeChatConversationMember> {
    constructor(
        private dataSource: DataSource,
        private readonly redisService: RedisService,
        @Inject(forwardRef(() => ChatConversationRepo))
        private readonly chatConversationRepo: ChatConversationRepo,
        private readonly chatMessageRepo: ChatMessageRepo,
    ) {
        super(OfficeChatConversationMember, dataSource.createEntityManager());
    }

    createDirectMemberMaster() {
        return this.create({
            // roomMaster: true,
            // superAdmin: true,
            admin: true,
            connected: true,
        })
    }

    createConversationMember(member?: OfficeUser) {
        const cm = this.create()

        if (member) cm.user = member

        return cm
    }

    async findById(ids: string[]) {
        return this.find({
            relations: ['user'],
            where: {
                id: In(ids)
            }
        })
    }

    async getConversationIdsJoined(memberId: string) {
        const result = await this.find({
            where: { userId: memberId },
            select: ["id", "conversationId"]
        });

        return result.map((mc) => mc.conversationId)
    }

    async getMembers(conversationId: string) {
        const result = await this.find({
            where: { conversationId: conversationId },
        });

        return result.map((mc) => mc.userId)
    }

    async getLastMessageReadId(conversationId: string, userId: string): Promise<string> {
        const redisKey = RedisKey.MemberLastMessageRead(conversationId, userId)
        const isCached = await this.redisService.exists(redisKey)
        if (!isCached) {
            const conversationMem = await this.findOne({
                where: { conversationId, userId },
                select: ["id", "lastMessageReadId"]
            })
            if (!conversationMem) return null
            let lastMessageReadId = conversationMem.lastMessageReadId
            if (!lastMessageReadId) {
                const currentUnreadCount = await this.getUnreadCount(conversationId, userId)

                const listUnreadMessage = await this.chatMessageRepo.getMessagesForConversation({
                    size: currentUnreadCount + 1,
                    conversationId
                })
                if (!listUnreadMessage || listUnreadMessage.messages.length <= 0) return null
                lastMessageReadId = listUnreadMessage?.messages?.at(- 1).id;
            }
            await this.redisService.setWithTtl(redisKey, lastMessageReadId, ChatModuleTTLRedis);
        }
        return await this.redisService.get(redisKey)
    }

    async getUnreadCount(conversationId: string, userId: string): Promise<number> {
        const redisKey = RedisKey.ConversationUnreadCount(conversationId, userId)
        const isCached = await this.redisService.exists(redisKey)
        if (!isCached) {
            const conversationMem = await this.findOne({
                where: { conversationId, userId },
                select: ["id", "unreadCount"]
            })
            await this.redisService.setWithTtl(redisKey, conversationMem.unreadCount || 0, ChatModuleTTLRedis);
        }
        return +(await this.redisService.get(redisKey))
    }

    async decrUnreadCountBy(conversationId: string, userId: string, quantity: number) {
        const redisKey = RedisKey.ConversationUnreadCount(conversationId, userId)
        const isCached = await this.redisService.exists(redisKey)
        if (!isCached) {
            const conversationMem = await this.findOne({
                where: { conversationId, userId },
                select: ["id", "unreadCount"]
            })
            await this.redisService.setWithTtl(redisKey, conversationMem.unreadCount || 0, ChatModuleTTLRedis);
        }
        await this.redisService.decrby(redisKey, quantity)
    }

    async incrUnreadCountBy(conversationId: string, userId: string) {
        const redisKey = RedisKey.ConversationUnreadCount(conversationId, userId)
        const isCached = await this.redisService.exists(redisKey)
        if (!isCached) {
            const conversationMem = await this.findOne({
                where: { conversationId, userId },
                select: ["id", "unreadCount"]
            })
            await this.redisService.setWithTtl(redisKey, conversationMem.unreadCount || 0, ChatModuleTTLRedis);
        }
        await this.redisService.incr(redisKey)
    }

    async removeMembers(memberIds: string[], conversationId: string) {
        await this.delete({ userId: In(memberIds), conversationId })
        await this.redisService.srem(RedisKey.MembersInConversation(conversationId), memberIds)
        for (const id of memberIds) {
            await this.redisService.zrem(RedisKey.ConversationsOfMember(id), [conversationId])
        }
    }

    async bulkInsertMembers(members: OfficeChatConversationMember[], conversationId: string) {
        await this.save(members)
        await this.redisService.sadd(RedisKey.MembersInConversation(conversationId), members.map(m => m.userId), ChatModuleTTLRedis)
        for (const mem of members) {
            await this.upsertConversationSortedSet(mem.userId, mem.conversationId)
        }
    }

    async upsertConversationSortedSet(userId: string, conversationId: string, score: number = (new Date()).getTime()) {
        const redisKey = RedisKey.ConversationsOfMember(userId)
        const isCached = await this.redisService.exists(redisKey)
        if (!isCached) {
            const conversations = await this.chatConversationRepo.getListByRequesterId(userId)
            for (const conversation of conversations) {
                if (!conversation.personalConversation.hide && conversation.id != conversationId) {
                    await this.redisService.zadd(redisKey, (new Date(conversation.lastMessageAt)).getTime(), conversation.id, ChatModuleTTLRedis)
                }
                else if (conversation.id == conversationId && conversation.personalConversation.hide) { // unhide conversation
                    await this.update({ conversationId, userId }, { hide: false })
                }
            }
        }
        await this.redisService.zadd(redisKey, score, conversationId, ChatModuleTTLRedis)
    }

    async getConversationFromSortedSet(userId: string, args?: { page: number, size: number }) {
        const redisKey = RedisKey.ConversationsOfMember(userId)
        const isCached = await this.redisService.exists(redisKey)
        if (!isCached) {
            const conversations = await this.chatConversationRepo.getListByRequesterId(userId)
            for (const conversation of conversations) {
                if (!conversation.personalConversation.hide) {
                    await this.redisService.zadd(redisKey, (new Date(conversation.lastMessageAt)).getTime(), conversation.id, ChatModuleTTLRedis)
                }
            }
        }
        const conversationIds = await this.redisService.zrevrange(redisKey, args ? args.page * args.size : 0, args ? args.size : -1)
        return conversationIds
    }
}