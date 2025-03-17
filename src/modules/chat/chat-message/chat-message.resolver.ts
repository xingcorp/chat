import { Args, Mutation, Resolver, Query } from '@nestjs/graphql';
import { SetMetadata } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ChatMessageService } from "@modules/chat/chat-message/chat-message.service";
import { ChatAddMessageInput, ChatMessageGetListFilter, ChatMessageUpdateArgs, ChatMessageUpdateReactionArgs, ChatMessageUpdateReadArgs, DeleteHistoryArgs } from "@modules/chat/chat-message/dto/chat-message.args";
import { ChatMessageListResponse, ChatMessageUpdateReadResponse } from "@modules/chat/chat-message/dto/chat-message.response";
import { OfficeChatConversationMember, OfficeChatMessage, OfficeUser } from '@models/entities';

@Resolver()
export class ChatMessageResolver {

    constructor(
        private readonly chatMessageService: ChatMessageService,
    ) { }

    @Mutation(() => OfficeChatMessage, { name: 'chatMessageAdd', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatMessageAdd(
        @Args('arguments', { nullable: false }) args: ChatAddMessageInput,
    ): Promise<OfficeChatMessage> {
        return this.chatMessageService.messageAdd(args)
    }

    @Mutation(() => OfficeChatConversationMember, { name: 'chatMessageDeleteHistory', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatMessageDeleteHistory(
        @Args('arguments', { nullable: false }) args: DeleteHistoryArgs,
    ): Promise<OfficeChatConversationMember> {
        return this.chatMessageService.deleteHistoryArgs(args)
    }

    @Query(() => ChatMessageListResponse, { name: 'chatMessageList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatMessageList(
        @Args('filters', { nullable: false }) args: ChatMessageGetListFilter,
    ) {
        return this.chatMessageService.messageList(args)
    }

    @Mutation(() => ChatMessageUpdateReadResponse, { name: 'chatMessageUpdateRead', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatMessageUpdateRead(
        @Args('arguments', { nullable: false }) args: ChatMessageUpdateReadArgs,
    ): Promise<ChatMessageUpdateReadResponse> {
        await this.chatMessageService.updateUnreadCount(args)
        return { conversationId: args.conversationId }
    }

    @Mutation(() => OfficeChatMessage, { name: 'chatMessageUpdateReaction', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async updateReaction(
        @Args('arguments', { nullable: false }) args: ChatMessageUpdateReactionArgs,
    ): Promise<OfficeChatMessage> {
        return this.chatMessageService.updateMessageReaction(args)
    }

    @Mutation(() => OfficeChatMessage, { name: 'chatMessageEdit', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async editMessage(
        @Args('arguments', { nullable: false }) args: ChatMessageUpdateArgs,
    ): Promise<OfficeChatMessage> {
        return this.chatMessageService.updateMessage(args)
    }
}
