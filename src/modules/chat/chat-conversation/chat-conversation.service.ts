import { Injectable } from '@nestjs/common';
import { ChatConversationMemberRepo, ChatConversationRepo, OfficeUserRepo } from "@models/repositories";
import { Brackets, DataSource } from "typeorm";
import {
    ChatConversationListFilter,
    ChatGroupAddInput,
    ChatGroupEditInput,
    ChatGroupLeaveArgs
} from "@modules/chat/chat-conversation/dto/chat-conversation.args";
import { ChatConversationGroupType, ChatConversationType, OfficeChatConversation } from "@models/entities/chat/conversation.chat";
import { OfficeError } from "@common/office.error";
import { ChatConversationListResponse } from './dto/chat-conversation.response';
import { OfficeChatConversationMember } from '@models/entities';
import * as _ from 'lodash';
import { ChatGateway } from '../chat-gateway/chat.gateway';
import { RedisKey } from '@core/common/common.type';
import { RedisService } from '@core/common/redis.service';
import { RequestContext } from '@common/context/request.context';
import { LoggerService } from '@core/common/logger.service';

@Injectable()
export class ChatConversationService {
    logger = new LoggerService(ChatConversationService.name);

    constructor(
        private dataSource: DataSource,
        private readonly chatConversationRepo: ChatConversationRepo,
        private readonly chatConversationMemberRepo: ChatConversationMemberRepo,
        private readonly officeUserRepo: OfficeUserRepo,
        private readonly chatGateway: ChatGateway,
        private readonly redisService: RedisService,
    ) { }

    async haveDirectBetween(senderId: string, receiverId: string) {
        return this.chatConversationRepo.haveDirectBetween(senderId, receiverId);
    }

    async getConversationDetail(conversationId: string, receiverId: string): Promise<OfficeChatConversation> {
        const requesterId = RequestContext.currentOfficeRequesterId();

        if (receiverId && !conversationId) {
            const conversation = await this.getDirectMessage(receiverId, requesterId)
            if (!conversation) {
                return null
            }
            conversationId = conversation.id
        }

        const conversation = await this.chatConversationRepo.findOne({
            where: { id: conversationId },
            relations: ['creator', 'members', 'members.user']
        })
        if (!conversation) throw OfficeError.ChatConversationNotExist

        if (conversation.type === ChatConversationType.Direct) {
            const partner = conversation.members.length > 1
                ? conversation.members
                    .find((mc) => mc.user.id !== requesterId)
                    ?.user
                : conversation.members[0].user;

            conversation.name = partner?.fullname
            conversation.imgUrl = partner && partner.imageUrls && partner.imageUrls.length > 0 ? partner?.imageUrls[0] : null
        }
        return conversation;
    }

    async createDirectMessage(senderId: string, receiverId: string) {
        const directMessage = await this.chatConversationRepo.createDirectMessage()
        const sender = await this.officeUserRepo.getById(senderId)
        const receiver = await this.officeUserRepo.getById(receiverId)
        const directMemberSender = this.chatConversationMemberRepo.createDirectMemberMaster()
        const directMemberReceive = this.chatConversationMemberRepo.createConversationMember()
        directMemberSender.creator = sender
        directMemberSender.user = sender
        directMemberSender.conversation = directMessage

        directMemberReceive.creator = sender
        directMemberReceive.user = receiver
        directMemberReceive.conversation = directMessage
        directMemberReceive.viewMessagesFrom = new Date()

        /*await this.dataSource.manager.transaction(async entity => {
            await entity.save(directMessage)
            await entity.save(directMemberSender)
            await entity.save(directMemberReceive)
        })*/

        await this.dataSource.manager.save(directMessage)
        await this.dataSource.manager.save(directMemberSender)
        await this.dataSource.manager.save(directMemberReceive)

        return directMessage
    }

    async getConversationBetween(senderId: string, receiverId: string) {
        const directMessage = await this.getDirectMessage(senderId, receiverId)

        if (!directMessage) {
            return this.createDirectMessage(senderId, receiverId)
        }

        return directMessage
    }

    getDirectMessage(senderId: string, receiverId: string) {
        return this.chatConversationRepo.getDirectMessage(senderId, receiverId)
    }

    async getConversationOfUserById(userId: string, conversationId: string) {
        const conversation = await this.chatConversationRepo.getByIdIncludesMembers(conversationId)

        if (!conversation.members.map(item => item.userId).includes(userId)) {
            throw OfficeError.ChatUserNotInConversation
        }

        return conversation
    }

    async searchConversation(args: ChatConversationListFilter, requesterId: string, conversationIdJoined: string[]): Promise<OfficeChatConversation[]> {
        if (conversationIdJoined.length <= 0) return []

        const query = this.chatConversationRepo
            .createQueryBuilder('conversation')
            .leftJoin('conversation.members', 'mc')
            .leftJoin('mc.user', 'user')
            .addSelect(['conversation.lastMessageAt', 'conversation.creatorId', 'mc.id', 'mc.userId', 'mc.conversationId', 'mc.unreadCount', 'mc.hide', 'mc.lastMessageReadId', 'user.id', 'user.fullname', 'user.imageUrls'])
            .where('conversation.id IN (:...conversationIdJoined)', { conversationIdJoined })
            .orderBy('conversation.lastMessageAt', 'DESC')

        if (args.keyword) {
            query.andWhere(new Brackets(qb => {
                qb.where("conversation.type = 'Group' AND conversation.name ILIKE :name", { name: `%${args.keyword}%` })
                    .orWhere("conversation.type = 'Direct' AND user.fullname ILIKE :name AND user.id != :requesterId", { name: `%${args.keyword}%`, requesterId })
            }))
        }
        if (args.type) {
            query.andWhere('conversation.type = :type', { type: args.type })
        }
        const conversations = await query.getMany();
        return conversations.map((conversation) => {
            if (conversation.type === ChatConversationType.Direct) {
                const partner = conversation.members.length > 1
                    ? conversation.members
                        .find((mc) => mc.user.id !== requesterId)
                        ?.user
                    : conversation.members[0]?.user;

                conversation.name = partner?.fullname
                conversation.imgUrl = partner && partner.imageUrls && partner.imageUrls.length > 0 ? partner?.imageUrls[0] : null
            }
            const personalConversation = conversation.members
                .find((mc) => mc.user.id == requesterId)
            conversation.personalConversation = personalConversation
            return conversation;
        });
    }

    async getList(userId: string, args: ChatConversationListFilter): Promise<ChatConversationListResponse> {
        let conversationIds = []
        let conversations = []
        conversationIds = await this.chatConversationMemberRepo.getConversationFromSortedSet(userId, args ? { page: args.page, size: args.size } : null)
        if (args.keyword || args.type) {
            conversations = await this.searchConversation(args, userId, conversationIds)
        } else {
            conversations = await this.chatConversationRepo.getListByRequesterId(userId, conversationIds)
        }
        const resultMap = new Map(conversations.map((row) => [row.id, row]));

        const orderedResults = conversationIds
            .map(id => resultMap.get(id)) // Match the Redis order
            .filter(row => row !== undefined); // Ensure no undefined rows if SQL missed some IDs

        return { conversations: orderedResults, total: orderedResults.length }
    }

    async groupCreate(creatorId: string, args: ChatGroupAddInput) {
        const group = await this.chatConversationRepo.createGroupMessage()
        const sender = await this.officeUserRepo.getById(creatorId)
        const creator = this.chatConversationMemberRepo.createDirectMemberMaster()

        group.name = args.name
        group.description = args?.description
        group.groupType = args?.groupType ?? ChatConversationGroupType.Private
        group.imgUrl = args?.imgUrl
        group.creator = sender

        creator.user = sender
        creator.conversation = group
        creator.creator = sender

        const members = []
        args.memberIds = _.uniq(args.memberIds)
        args.memberIds = _.remove(args.memberIds, (id) => id !== creatorId)
        for (const memberId of args.memberIds) {
            const member = await this.officeUserRepo.getById(memberId)
            const conversationMember = this.chatConversationMemberRepo.createConversationMember(member)
            conversationMember.conversation = group
            conversationMember.creator = sender
            conversationMember.viewMessagesFrom = group.createdAt
            members.push(conversationMember)
        }
        await this.dataSource.manager.save(group)
        await this.dataSource.manager.save(creator)
        await this.chatConversationMemberRepo.bulkInsertMembers(members, group.id)

        return group
    }

    async groupEdit(userId: string, args: ChatGroupEditInput) {
        const conversationId = args.conversationId
        const conversation = await this.chatConversationRepo.getByIdIncludesMembers(conversationId)
        if (!conversation) throw OfficeError.ChatConversationNotExist

        const isEditorIsAdmin = conversation.members.filter(i => i.admin).map(item => item.userId).includes(userId)

        if (args.name) {
            conversation.name = args.name
            await this.redisService.setWithTtl(RedisKey.ConversationName(conversationId), conversation.name)
        }
        conversation.description = args?.description ?? conversation.description
        conversation.groupType = args?.groupType ?? conversation.groupType
        conversation.imgUrl = args?.imgUrl ?? conversation.imgUrl

        await conversation.save()
        if (args.memberIds && args.memberIds.length > 0) {
            const currentMemberIds = conversation.members.map(item => item.userId)

            const removeMemberIds = _.difference(currentMemberIds, args.memberIds)
            if (!isEditorIsAdmin && removeMemberIds.length > 0) {
                throw OfficeError.ChatNotAdmin
            }

            if (removeMemberIds.includes(userId)) {
                throw OfficeError.ChatCanNotRemoveSelf
            }

            if (removeMemberIds.length > 0) {
                await this.chatConversationMemberRepo.removeMembers(removeMemberIds, conversationId)
                await Promise.all(removeMemberIds.map((id) =>
                    this.chatGateway.emitLeaveConversation(id, conversation.id)
                ))
                conversation.members = conversation.members.filter(i => !removeMemberIds.includes(i.userId))
            }

            const addMemberIds = _.difference(args.memberIds, currentMemberIds)
            if (addMemberIds.length > 0) {
                const addMembers: OfficeChatConversationMember[] = []
                for (const memberId of addMemberIds) {
                    const member = await this.officeUserRepo.getById(memberId)
                    const conversationMember = this.chatConversationMemberRepo.createConversationMember(member)
                    conversationMember.conversation = conversation
                    conversationMember.creatorId = userId
                    conversationMember.viewMessagesFrom = conversation.createdAt
                    addMembers.push(conversationMember)
                }
                await this.chatConversationMemberRepo.bulkInsertMembers(addMembers, conversationId)
                conversation.members.push(...addMembers)
                await Promise.all(addMemberIds.map((id) => this.chatGateway.emitJoinConversation(id, conversation.id)))
            }
        }

        if (args.adminIds && args.adminIds.length > 0) {
            if (!isEditorIsAdmin) {
                throw OfficeError.ChatNotAdmin
            }
            const currentAdmins = conversation.members.filter(i => i.admin).map(item => item.userId)

            const addAdminIds = _.difference(args.adminIds, currentAdmins)
            const addAdmins = []
            if (addAdminIds.length > 0) {
                addAdminIds.forEach(aAdminId => {
                    const newAdmin = conversation.members.find(member => member.userId === aAdminId)
                    if (newAdmin) {
                        newAdmin.admin = true
                        addAdmins.push(newAdmin)
                    }
                })
                if (addAdmins.length > 0) {
                    await OfficeChatConversationMember.save(addAdmins)
                }
            }

            const removeAdminIds = _.difference(currentAdmins, args.adminIds)
            const removeAdmins = []
            if (removeAdminIds.length > 0) {
                removeAdminIds.forEach(rAdminId => {
                    const rAdmin = conversation.members.find(member => member.userId === rAdminId)
                    if (rAdmin) {
                        rAdmin.admin = false
                        removeAdmins.push(rAdmin)
                    }
                })
                if (removeAdmins.length > 0) {
                    await OfficeChatConversationMember.save(removeAdmins)
                }
            }
        }
        return conversation
    }

    async leaveConversation(userId: string, { conversationId }: ChatGroupLeaveArgs) {
        const conversation = await this.chatConversationRepo.getByIdIncludesMembers(conversationId)
        if (!conversation) throw OfficeError.ChatConversationNotExist
        if (conversation.type === ChatConversationType.Direct) throw OfficeError.ChatCanNotLeaveDirectConversation

        const isAdmin = conversation.members
            .filter(i => i.admin)
            .map(item => item.userId)
            .includes(userId)

        if (isAdmin) {
            const remainingAdmins = conversation.members
                .filter(i => i.admin && i.userId != userId)
            if (remainingAdmins.length === 0) {
                const newAdmin = conversation.members
                    .sort((a, b) => (new Date(a.createdAt)).getTime() - (new Date(b.createdAt)).getTime())
                    .find(i => !i.admin && i.userId != userId)
                if (newAdmin) {
                    newAdmin.admin = true
                    await newAdmin.save()
                }
            }
        }
        await this.chatConversationMemberRepo.removeMembers([userId], conversationId)
        this.chatGateway.emitLeaveConversation(userId, conversationId)

        return conversation
    }

    async deleteConversation(userId: string, { conversationId }: ChatGroupLeaveArgs) {
        if (!conversationId) {
            throw OfficeError.ChatMessageNeedReceiverOrConversation
        }
        const conversationMem = await this.chatConversationMemberRepo.findOne({
            where: {
                conversationId: conversationId,
                userId: userId
            }
        })
        if (!conversationMem) throw OfficeError.ChatUserNotInConversation
        conversationMem.hide = true
        conversationMem.viewMessagesFrom = new Date()
        await conversationMem.save()
        await this.redisService.zrem(RedisKey.ConversationsOfMember(userId), [conversationId])

        return conversationMem
    }
}
