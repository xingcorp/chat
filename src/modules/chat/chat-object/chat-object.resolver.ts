import { Args, Mutation, Query, registerEnumType, Resolver } from '@nestjs/graphql';
import { ObjectGenLinkWriteResponse } from "@modules/graphql/management/document/document.response";
import { forwardRef, Inject, SetMetadata } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { OfficeRequesterId } from "@core/middleware/decorator/user.decorator";
import { ChatObjectService } from "@modules/chat/chat-object/chat-object.service";
import { typesenseCollectionRemove } from "@services/typesense/index.typesense";
import { CHAT_COLLECTIONS } from "@modules/search-engine/search-engine.service.interface";
import { ChatObjectGetUrlResponse } from "@modules/chat/chat-object/dto/chat-object.response";

export enum ChatObjectType {
    MESSAGE= "MESSAGE",
    GROUP= "GROUP",
    STORY= "STORY",
}

registerEnumType(ChatObjectType, { name: 'ChatObjectType' })

@Resolver()
export class ChatObjectResolver {

    constructor(
        @Inject(forwardRef(() => ChatObjectService))
        private readonly chatObjectService: ChatObjectService
    ) {
    }

    @Mutation(() => ObjectGenLinkWriteResponse, { name: 'chatObjectGenLinkUpload' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatObjectGenLinkUpload(
        @Args({ name: 'filename', type: () => String }) filename: string,
        @Args({ name: 'conversationId', type: () => String, nullable: true }) conversationId: string,
        @Args({ name: 'type', type: () => ChatObjectType }) type: ChatObjectType,
        @Args({ name: 'mimetype', type: () => String }) mimetype: string,
        @OfficeRequesterId() userId: string,
    ): Promise<ObjectGenLinkWriteResponse> {
        return this.chatObjectService.genLinkUpload({filename, mimetype, conversationId, type}, userId);
    }

    @Query(() => ChatObjectGetUrlResponse, { name: 'chatObjectGetUrl', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatObjectGetUrl(
        @Args({ name: 'path', type: () => String }) path: string,
    ): Promise<ChatObjectGetUrlResponse> {
        return this.chatObjectService.getFirebaseUrl(path);
    }
}
