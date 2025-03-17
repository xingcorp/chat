import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { SetMetadata } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { OfficeRequesterId } from "@core/middleware/decorator/user.decorator";
import { ChatConversationService } from "@modules/chat/chat-conversation/chat-conversation.service";
import {
    ChatConversationListFilter,
    ChatGroupAddInput, ChatGroupEditInput,
    ChatGroupLeaveArgs
} from "@modules/chat/chat-conversation/dto/chat-conversation.args";
import {
    ChatConversationListResponse
} from "@modules/chat/chat-conversation/dto/chat-conversation.response";
import { OfficeChatConversation, OfficeChatConversationMember } from '@models/entities';
import { BaseError } from '@core/core.error';

@Resolver()
export class ChatConversationResolver {

    constructor(
        private readonly chatConversationService: ChatConversationService,
    ) {
    }

    @Mutation(() => OfficeChatConversation, { name: 'chatGroupAdd', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatGroupAdd(
        @Args('arguments', { nullable: false }) args: ChatGroupAddInput,
        @OfficeRequesterId() userId: string,
    ): Promise<OfficeChatConversation> {
        return this.chatConversationService.groupCreate(userId, args)
    }

    @Mutation(() => OfficeChatConversation, { name: 'chatGroupEdit', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatGroupEdit(
        @Args('arguments', { nullable: false }) args: ChatGroupEditInput,
        @OfficeRequesterId() userId: string,
    ): Promise<OfficeChatConversation> {
        return this.chatConversationService.groupEdit(userId, args)
    }

    @Mutation(() => OfficeChatConversation, { name: 'chatConversationLeave', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatGroupLeave(
        @Args('arguments', { nullable: false }) args: ChatGroupLeaveArgs,
        @OfficeRequesterId() userId: string,
    ): Promise<OfficeChatConversation> {
        return this.chatConversationService.leaveConversation(userId, args)
    }

    @Mutation(() => OfficeChatConversationMember, { name: 'chatConversationDelete', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async deleteConversation(
        @Args('arguments', { nullable: false }) args: ChatGroupLeaveArgs,
        @OfficeRequesterId() userId: string,
    ): Promise<OfficeChatConversationMember> {
        return this.chatConversationService.deleteConversation(userId, args)
    }

    @Query(() => ChatConversationListResponse, { name: 'chatConversationList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatConversationList(
        @Args('filters') args: ChatConversationListFilter,
        @OfficeRequesterId() userId: string,
    ): Promise<ChatConversationListResponse> {
        return this.chatConversationService.getList(userId, args)
    }

    @Query(() => OfficeChatConversation, { name: 'chatConversationDetail', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatConversationDetail(
        @Args('conversationId', { nullable: true }) conversationId: string,
        @Args('receiverId', { nullable: true }) receiverId: string,
    ): Promise<OfficeChatConversation> {
        if (!conversationId && !receiverId) {
            throw new BaseError('chatConversationDetail', 'conversationId or receiverId is required')
        }
        return this.chatConversationService.getConversationDetail(conversationId, receiverId)
    }
}
