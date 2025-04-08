import { ChatConversationMemberRepo, ChatConversationRepo } from "@models/repositories";
import {
    WebSocketGateway,
    WebSocketServer,
    SubscribeMessage,
    MessageBody,
    ConnectedSocket,
    OnGatewayConnection,
    OnGatewayDisconnect,
} from "@nestjs/websockets";
import { Server } from "socket.io";
import { SocketWithAuth } from "../type";
import { OfficeChatMessage, OfficeUser } from "@models/entities";
import { ChatMessageUpdateReactionArgs } from "../chat-message/dto/chat-message.args";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";
import { ChatModuleTTLRedis } from "@helpers/environment.helper";
import { createWriteStream } from 'fs';
import { join } from 'path';
import * as crypto from 'crypto';
import { LoggerService } from "@core/common/logger.service";

@WebSocketGateway({
    cors: {
        origin: "*",
    },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
    logger = new LoggerService(ChatGateway.name)
    @WebSocketServer() server: Server;

    constructor(
        private readonly chatConversationMemberRepo: ChatConversationMemberRepo,
        private readonly chatConversationRepo: ChatConversationRepo,
        private readonly redisService: RedisService
    ) { }

    async handleConnection(client: SocketWithAuth) {
        this.logger.log(`Client Id ${client.officeUserId} ${client.officeUser.fullname} connected`);
        const conversationIds = await this.chatConversationMemberRepo.getConversationIdsJoined(client.officeUserId)
        const conversations = await this.chatConversationRepo.getListByRequesterId(client.officeUserId, conversationIds)
        for (const conversation of conversations) {
            if (!conversation.personalConversation.hide) {
                await this.redisService.zadd(RedisKey.ConversationsOfMember(client.officeUserId), (new Date(conversation.lastMessageAt)).getTime(), conversation.id, ChatModuleTTLRedis)
            }
        }

        await client.join(client.officeUserId);
        for (const conversationId of conversationIds) {
            await client.join(conversationId);
        }

        await this.redisService.setWithTtl(RedisKey.UserStatus(client.officeUserId), 'online', 2592000) // cache user status for 1 month
        await this.redisService.delete(RedisKey.UserOfflineAt(client.officeUserId)) // cache user offline time for 1 month
        this.logger.log("Client joined", client.id);
    }

    async handleDisconnect(client: SocketWithAuth) {
        this.logger.log(`Client Id ${client.officeUserId} ${client.officeUser.fullname} disconnectd`);
        const conversationIds = await this.chatConversationMemberRepo.getConversationIdsJoined(client.officeUserId)
        for (const conversationId of conversationIds) {
            await client.leave(conversationId);
        }

        await this.redisService.setWithTtl(RedisKey.UserStatus(client.officeUserId), 'offline', 2592000) // cache user status for 1 month
        await this.redisService.setWithTtl(RedisKey.UserOfflineAt(client.officeUserId), (new Date()).getTime(), 2592000) // cache user offline time for 1 month
        this.logger.log("Client disconnect", client.id);

    }

    @SubscribeMessage("message:typing")
    messageTyping(
        @MessageBody() { conversationId, isTyping }: { conversationId: string, isTyping: boolean },
        @ConnectedSocket() client: SocketWithAuth,
    ) {
        return this.server.to(conversationId).emit('message:typing', { userId: client.officeUserId, fullName: client.officeUser.fullname, isTyping, conversationId });
    }

    @SubscribeMessage('message:file:upload')
    async handleFileUpload(
        @MessageBody() {
            file,
            fileName
        }: {
            file: Buffer,
            fileName: string
        },
        @ConnectedSocket() client: SocketWithAuth,
    ) {
        try {
            const fileHash = crypto.randomBytes(16).toString('hex');
            const fileExtension = fileName.split('.').pop();
            const newFileName = `${fileHash}.${fileExtension}`;
            const filePath = join(process.cwd(), 'uploads', newFileName);

            const writeStream = createWriteStream(filePath);
            writeStream.write(Buffer.from(file));
            writeStream.end();

            return { success: true, filePath: `/uploads/${newFileName}` };
        } catch (error) {
            this.logger.error('File upload error:', error);
            return { success: false, error: 'File upload failed' };
        }
    }

    @SubscribeMessage("conversation:joined")
    joinConversation(
        @MessageBody() { conversationId }: { conversationId: string },
        @ConnectedSocket() client: SocketWithAuth,
    ) {
        this.logger.log('conversation:joined');
        return client.join(conversationId);
    }

    @SubscribeMessage("conversation:leaved")
    leavedConversation(
        @MessageBody() { conversationId }: { conversationId: string },
        @ConnectedSocket() client: SocketWithAuth,
    ) {
        return client.leave(conversationId);
    }

    sendMessageToDirectUser(userId: string, data: { message: OfficeChatMessage, conversationId: string }) {
        return this.server.to(userId).emit('message:sent', data);
    }

    sendMessageToRoom(conversationId: string, data: { message: OfficeChatMessage, conversationId: string }) {
        return this.server.to(conversationId).emit('message:sent', data);
    }

    emitReadMessage(conversationId: string, data: { message: OfficeChatMessage, reader: OfficeUser }) {
        return this.server.to(conversationId).emit('message:read', data);
    }

    emitReactionMessage(conversationId: string, data: { reactor: OfficeUser, data: ChatMessageUpdateReactionArgs }) {
        return this.server.to(conversationId).emit('message:reaction', data);
    }

    emitEditMessage(conversationId: string, data: { message: OfficeChatMessage, conversationId: string }) {
        return this.server.to(conversationId).emit('message:edit', data);
    }

    emitDeleteMessage(conversationId: string, data: { message: OfficeChatMessage, conversationId: string }) {
        return this.server.to(conversationId).emit('message:delete', data);
    }

    emitJoinConversation(userId: string, conversationId: string) {
        return this.server.to(userId).emit('conversation:joined', { conversationId });
    }

    emitLeaveConversation(userId: string, conversationId: string) {
        return this.server.to(userId).emit('conversation:leaved', { conversationId });
    }
}
