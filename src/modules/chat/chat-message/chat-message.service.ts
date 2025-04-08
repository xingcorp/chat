import { Injectable } from '@nestjs/common';
import { ChatConversationMemberRepo, ChatConversationRepo, ChatMessageRepo, OfficeUserRepo } from "@models/repositories";
import {
    ChatAddMessageInput,
    ChatMessageGetListFilter,
    ChatMessageUpdateArgs,
    ChatMessageUpdateReactionArgs,
    ChatMessageUpdateReadArgs,
    DeleteHistoryArgs,
    HandlePushMessageJobData,
    HandleSyncLastMessageJobData,
    HandleSyncUnreadCountJobData
} from "@modules/chat/chat-message/dto/chat-message.args";
import { ChatConversationService } from "@modules/chat/chat-conversation/chat-conversation.service";
import { OfficeError } from "@common/office.error";
import { OfficeChatMessage, OfficeUser } from "@models/entities";
import { ChatGateway } from '../chat-gateway/chat.gateway';
import { RedisService } from '@core/common/redis.service';
import { InjectQueue, Process, Processor } from '@nestjs/bull';
import { Job, Queue } from "bull";
import { RedisKey } from '@core/common/common.type';
import { ChatModuleScheduleAsyncToDb, ChatModuleTTLRedis } from '@helpers/environment.helper';
import { ChatMessageAct, ChatMessageReactionAct, ChatMessageType } from '@enum/chat/message.chat.enum';
import { extractUserIdsInMessage } from '@utils/common.utils';
import { ChatNotifyService } from '../chat-notify/chat-notify.service';
import { isUUID } from 'validator';
import { LoggerService } from '@core/common/logger.service';
import { OpenSearchService } from '@modules/search-engine/open-search/open-search.service';
import { RequestContext } from '@common/context/request.context';

const HANDLE_MESSAGE_SENT = 'handle_message_sent'
const HANDLE_SYNC_UNREAD_COUNT = 'handle_sync_unread_count'
const HANDLE_SYNC_LAST_MESSAGE = 'handle_sync_last_message'

@Injectable()
@Processor('chat_message_queue')
export class ChatMessageService {
    logger = new LoggerService(ChatMessageService.name)

    constructor(
        private readonly chatMessageRepo: ChatMessageRepo,
        private readonly chatConversationService: ChatConversationService,
        private readonly chatGateway: ChatGateway,
        private readonly redisService: RedisService,
        private readonly chatConversationMemberRepo: ChatConversationMemberRepo,
        private readonly chatConversationRepo: ChatConversationRepo,
        @InjectQueue('chat_message_queue') private conversationQueue: Queue,
        private readonly chatNotifyService: ChatNotifyService,
        private readonly openSearchService: OpenSearchService<OfficeChatMessage>,
        private readonly officeUserRepo: OfficeUserRepo
    ) { }

    private _pushMessageToChatMessageQueue(data: HandlePushMessageJobData) {
        return this.conversationQueue.add(
            HANDLE_MESSAGE_SENT,
            data,
            {
                removeOnComplete: true,
                attempts: 3, // Number of attempts
                backoff: {
                    type: 'exponential', // 'fixed' or 'exponential'
                    delay: 3000, // Delay time in milliseconds (1000ms if using exponential)
                },
            }
        )
    }

    @Process({ name: HANDLE_MESSAGE_SENT })
    private async handlePushMessage(job: Job<HandlePushMessageJobData>) {
        try {
            const { conversationId, sender, chatMessage, accessToken, isFirstMessage } = job.data
            const membersIdInConversation = await this.chatConversationRepo.getMemberInConversation(conversationId)
            const conversationName = await this.chatConversationRepo.getCachedConversationName(conversationId)
            const mentionTo = []
            const notifyPayload = {
                receiverIds: membersIdInConversation,
                title: `${conversationName || sender.fullname}`,
                content: `${sender.fullname}: ${chatMessage.message || chatMessage.fileName}`,
                metadata: null,
            }
            const metadataNotify = {
                conversationId,
                conversationName: `${conversationName || sender.fullname}`,
                sender,
                message: chatMessage,
                type: 'chat.notify',
                mentionTo: []
            }
            if (chatMessage.message) {
                const referentIds = extractUserIdsInMessage(chatMessage.message)
                if (referentIds.length > 0) {
                    const isMentionAll = referentIds.find((id) => id.toLocaleLowerCase() === 'all')
                    notifyPayload.receiverIds = isMentionAll ? membersIdInConversation : referentIds
                    notifyPayload.content = `${sender.fullname} mentioned you: ${chatMessage.message || chatMessage.fileName}`;
                    // metadataNotify.type = 'message:mentioned';
                    for (const userId of referentIds) {
                        if (isUUID(userId)) {
                            const userProfile = await this.officeUserRepo.getPublicProfileUser(userId)
                            mentionTo.push(userProfile)
                        }
                    }
                    metadataNotify.mentionTo = mentionTo
                }
            }
            if (isFirstMessage) {
                for (const memberId of membersIdInConversation) {
                    this.chatGateway.sendMessageToDirectUser(memberId, { message: { ...chatMessage, sender, mentionTo }, conversationId })
                }
            } else {
                this.chatGateway.sendMessageToRoom(conversationId, { message: { ...chatMessage, sender, mentionTo }, conversationId })
            }
            for (const memberId of membersIdInConversation) {

                // incr unread count of the member
                if (memberId != sender.id) {
                    await this.chatConversationMemberRepo.incrUnreadCountBy(conversationId, memberId)
                }
                // update sorted set conversations of the member
                await this.chatConversationMemberRepo.upsertConversationSortedSet(memberId, conversationId)

                // sync unread count each member to db
                this._pushJobSyncUnreadCountQueue({ conversationId, userId: memberId })
            }

            notifyPayload.metadata = JSON.parse(JSON.stringify(metadataNotify))
            notifyPayload.receiverIds = notifyPayload.receiverIds.filter(id => id !== sender.id)

            await this.chatNotifyService.sendToUsers(notifyPayload, accessToken)

            // cache last message id of the conversation
            await this.redisService.setWithTtl(RedisKey.ConversationLastMessage(conversationId), JSON.stringify({
                lastMessageId: chatMessage.id,
                lastMessageAt: new Date(chatMessage.createdAt)
            }), ChatModuleTTLRedis)

            // sync last message to db
            await this._pushJobSyncLastMessage({ conversationId })

            // index message to open search
            if (chatMessage.message || chatMessage.fileName)
                await this.openSearchService.indexDocument(chatMessage.id, chatMessage).then(() => {
                }).catch((error) => {
                    this.logger.error('Index document error', error)
                })
        } catch (error) {
            this.logger.error('handlePushMessage: ', { jobData: JSON.stringify(job.data), error });
            throw error; // Rethrow the error to trigger a retry
        }
    }

    private _pushJobSyncUnreadCountQueue(data: HandleSyncUnreadCountJobData) {
        return this.conversationQueue.add(
            HANDLE_SYNC_UNREAD_COUNT,
            data,
            {
                delay: ChatModuleScheduleAsyncToDb,
                removeOnComplete: true,
                jobId: `${RedisKey.ConversationUnreadCount(data.conversationId, data.userId)}`,
                attempts: 3, // Number of attempts
                backoff: {
                    type: 'exponential', // 'fixed' or 'exponential'
                    delay: 3000, // Delay time in milliseconds (1000ms if using exponential)
                },
            }
        )
    }

    @Process({ name: HANDLE_SYNC_UNREAD_COUNT })
    private async handleSyncUnreadCount(job: Job<HandleSyncUnreadCountJobData>) {
        try {
            const { conversationId, userId } = job.data
            const unreadCount = await this.chatConversationMemberRepo.getUnreadCount(conversationId, userId)
            const lastMessageReadId = await this.chatConversationMemberRepo.getLastMessageReadId(conversationId, userId)
            await this.chatConversationMemberRepo.update({
                conversationId: conversationId,
                userId
            }, { unreadCount, lastMessageReadId })
        } catch (error) {
            this.logger.error('handleSyncUnreadCount: ', { jobData: JSON.stringify(job.data), error });
            throw error; // Rethrow the error to trigger a retry
        }
    }

    private _pushJobSyncLastMessage(data: HandleSyncLastMessageJobData) {
        return this.conversationQueue.add(
            HANDLE_SYNC_LAST_MESSAGE,
            data,
            {
                delay: ChatModuleScheduleAsyncToDb,
                removeOnComplete: true,
                jobId: `${RedisKey.ConversationLastMessage(data.conversationId)}`,
                attempts: 3, // Number of attempts
                backoff: {
                    type: 'exponential', // 'fixed' or 'exponential'
                    delay: 3000, // Delay time in milliseconds (1000ms if using exponential)
                },
            }
        )
    }

    @Process({ name: HANDLE_SYNC_LAST_MESSAGE })
    private async handleSyncConversationLastMessage(job: Job<HandleSyncLastMessageJobData>) {
        try {
            const { conversationId } = job.data
            const redisCache = await this.redisService.get(RedisKey.ConversationLastMessage(conversationId))
            const { lastMessageId, lastMessageAt } = JSON.parse(redisCache)
            await this.chatConversationRepo.update({
                id: conversationId,
            }, { lastMessageId, lastMessageAt })
        } catch (error) {
            this.logger.error('handleSyncConversationLastMessage: ', { jobData: JSON.stringify(job.data), error });
            throw error; // Rethrow the error to trigger a retry
        }
    }

    async updateUnreadCount(args: ChatMessageUpdateReadArgs) {
        const user = await RequestContext.currentUser()
        const userId = user.id
        const currentUnreadCount = await this.chatConversationMemberRepo.getUnreadCount(args.conversationId, userId)

        args.readCount = args.readCount == 1000000 ? currentUnreadCount : args.readCount //reset unread count
        if (currentUnreadCount <= 0 || args.readCount <= 0 || (currentUnreadCount > 0 && args.readCount > 0 && currentUnreadCount < args.readCount)) {
            return
        }
        await this.chatConversationMemberRepo.decrUnreadCountBy(args.conversationId, userId, args.readCount)
        const listUnreadMessage = await this.chatMessageRepo.getMessagesForConversation({
            size: currentUnreadCount,
            conversationId: args.conversationId
        })
        if (!listUnreadMessage.messages.at(args.readCount - 1)) {
            return
        }
        const lastMessageReadId = listUnreadMessage.messages.at(args.readCount - 1).id;
        await this.redisService.setWithTtl(RedisKey.MemberLastMessageRead(args.conversationId, userId), lastMessageReadId, ChatModuleTTLRedis)
        for (const message of listUnreadMessage.messages) {
            const readerIds = message.readerIds || []
            readerIds.push(userId)
            await this.chatMessageRepo.updateReaderIds(message.id, readerIds)
            this.chatGateway.emitReadMessage(message.conversationId, { reader: user, message })
        }
        return this._pushJobSyncUnreadCountQueue({ conversationId: args.conversationId, userId })
    }

    async messageList(args: ChatMessageGetListFilter) {
        const conversation = await this.chatConversationRepo.findOne({ where: { id: args.conversationId } })
        if (!conversation) throw OfficeError.ChatConversationNotExist

        if (!args.conversationId) {
            throw OfficeError.ChatMessageNeedReceiverOrConversation
        }
        const userId = RequestContext.currentId()

        const conversationMem = await this.chatConversationMemberRepo.findOne({
            where: {
                conversationId: args.conversationId,
                userId: userId
            }
        })
        if (!conversationMem) throw OfficeError.ChatUserNotInConversation

        args.from =
            args.from && args.from >= (new Date(conversationMem.viewMessagesFrom)).getTime()
                ? args.from
                : (new Date(conversationMem.viewMessagesFrom)).getTime() || (new Date(conversation.createdAt)).getTime()

        return this.chatMessageRepo.getMessagesForConversation(args)
    }

    async messageAdd(args: ChatAddMessageInput) {
        const sender = await RequestContext.currentUser()
        const userId = sender.id
        args.senderId = userId
        if (!args.receiverId && !args.conversationId) {
            throw OfficeError.ChatMessageNeedReceiverOrConversation
        }
        let replyMessage = null
        if (args.replyMessageId) {
            replyMessage = await this.chatMessageRepo.getById(args.replyMessageId)
            if (!replyMessage)
                throw OfficeError.ChatMessageNotFound
        }

        let forwardedFromMessage = null
        if (args.forwardedFromMessageId) {
            forwardedFromMessage = await this.chatMessageRepo.getById(args.forwardedFromMessageId)
            if (!forwardedFromMessage)
                throw OfficeError.ChatMessageNotFound
        }

        let isFirstMessage = false
        if (args.receiverId) {
            let directConversation = await this.chatConversationService.getDirectMessage(userId, args.receiverId)

            if (!directConversation) {
                isFirstMessage = true
                directConversation = await this.chatConversationService.createDirectMessage(userId, args.receiverId)
            }
            args.conversationId = directConversation.id
        }

        const messageSent = await this.chatMessageRepo.createMessage(args)
        messageSent.replyMessage = replyMessage;
        messageSent.forwardedFromMessage = forwardedFromMessage
        this._pushMessageToChatMessageQueue({
            conversationId: messageSent.conversationId,
            sender,
            chatMessage: messageSent,
            accessToken: RequestContext.currentToken(),
            isFirstMessage
        })
        return messageSent
    }

    async deleteHistoryArgs(args: DeleteHistoryArgs) {
        const userId = RequestContext.currentId()

        const conversationMem = await this.chatConversationMemberRepo.findOne({
            where: {
                conversationId: args.conversationId,
                userId
            }
        })
        if (!conversationMem) throw OfficeError.ChatUserNotInConversation
        conversationMem.viewMessagesFrom = new Date()
        return await conversationMem.save()
    }

    private async messageDirectAdd(userId: string, args: ChatAddMessageInput): Promise<OfficeChatMessage> {
        const directMessage = await this.chatConversationService.getConversationBetween(userId, args.receiverId)
        args.conversationId = directMessage.id
        return this.chatMessageRepo.createMessage(args)
    }

    private async messageConversationAdd(userId: string, args: ChatAddMessageInput) {
        await this.chatConversationService.getConversationOfUserById(userId, args.conversationId)
        return this.chatMessageRepo.createMessage(args)
    }

    async updateMessageReaction(args: ChatMessageUpdateReactionArgs): Promise<OfficeChatMessage> {
        const message = await this.chatMessageRepo.getById(args.messageId)
        if (!message)
            throw OfficeError.ChatMessageNotFound

        const user = await RequestContext.currentUser()
        const userId = user.id
        let currentReactions = message.reactions || []
        let currentReactionCode = currentReactions.find(r => r.code === args.code)

        if (!currentReactionCode && args.act === ChatMessageReactionAct.REVOKE) {
            return message
        }

        if (currentReactionCode) {
            const reactorIdSet = new Set(currentReactionCode.reactorIds || [])
            const currentReactionsMap = new Map(currentReactions.map(r => [r.code, r]))

            if (args.act === ChatMessageReactionAct.ADD) {
                reactorIdSet.add(userId)
            } else {
                reactorIdSet.delete(userId)
            }
            if (reactorIdSet.size === 0) {
                currentReactionsMap.delete(currentReactionCode.code)
            } else {
                currentReactionCode.reactorIds = Array.from(reactorIdSet);
                currentReactionsMap.set(currentReactionCode.code, currentReactionCode)
            }
            currentReactions = Array.from(currentReactionsMap.values())
        } else {
            currentReactions.push({
                code: args.code,
                reactorIds: [userId]
            })
        }

        const result = await this.chatMessageRepo.updateReactions(args.messageId, currentReactions)
        if (result) {
            message.reactions = currentReactions
            this.chatGateway.emitReactionMessage(message.conversationId, { reactor: user, data: args })
        }
        await this.redisService.zincrby(RedisKey.MemberReactionUsed(userId), 1, args.code, 2592000) // 1 months
        return message
    }

    async updateMessage(args: ChatMessageUpdateArgs): Promise<OfficeChatMessage> {
        const message = await this.chatMessageRepo.getById(args.messageId)
        const userId = RequestContext.currentId()
        if (!message) {
            throw OfficeError.ChatMessageNotFound
        }

        if (message.type != ChatMessageType.TEXT && args.act === ChatMessageAct.EDIT) {
            throw OfficeError.ChatMessageActNotAllow
        }

        if (message.senderId != userId) {
            throw OfficeError.ChatWrongSender
        }

        if (args.act === ChatMessageAct.DEL) {
            const isUpdateSuccess = await this.chatMessageRepo.deleteMessage(args.messageId)
            if (isUpdateSuccess) {
                await this.openSearchService.deleteDocument(args.messageId)
                this.chatGateway.emitDeleteMessage(message.conversationId, { message, conversationId: message.conversationId })
            }
        } else if (args.message) {
            message.message = args.message
            const isUpdateSuccess = await this.chatMessageRepo.updateMessage(args.messageId, args.message)
            if (isUpdateSuccess) {
                await this.openSearchService.indexDocument(args.messageId, message)
                this.chatGateway.emitEditMessage(message.conversationId, { message, conversationId: message.conversationId })
            }
        }
        return message
    }

}
