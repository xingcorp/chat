import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { OfficeChatMessage, OfficeUser } from "@models/entities";
import { ChatMessageRepo, OfficeUserRepo } from "@models/repositories";
import { extractUserIdsInMessage } from "@utils/common.utils";
import { isUUID } from "validator";
import { LoggerService } from "@core/common/logger.service";

@Resolver(_of => OfficeChatMessage)
export class ChatMessageFieldResolver {
    logger = new LoggerService(ChatMessageFieldResolver.name)
    constructor(
        private readonly chatMessageRepo: ChatMessageRepo,
        private readonly officeUserRepo: OfficeUserRepo
    ) { }


    @ResolveField('sender', _return => OfficeUser, { nullable: true })
    async sender(
        @Parent() root: OfficeChatMessage
    ) {
        try {
            if (!root.senderId) {
                return null
            }
            return await this.officeUserRepo.getPublicProfileUser(root.senderId)
        } catch (error) {
            this.logger.error(`[ConversationMemberFieldResolver] Field sender`, JSON.stringify(error));
        }
    }

    @ResolveField('replyMessage', _return => OfficeChatMessage, { nullable: true })
    async replyMessage(
        @Parent() root: OfficeChatMessage
    ) {
        try {
            if (!root.replyMessageId) {
                return null
            }
            return await this.chatMessageRepo.getById(root.replyMessageId)
        } catch (error) {
            this.logger.error(`[ChatMessageFieldResolver] Field replyMessage`, JSON.stringify(error));
        }
    }

    @ResolveField('mentionTo', _return => [OfficeUser], { nullable: true })
    async mentionTo(
        @Parent() root: OfficeChatMessage
    ) {
        try {
            if (!root.message) {
                return []
            }
            const referentIds = extractUserIdsInMessage(root.message)
            if (referentIds.length <= 0) return []

            return await Promise.all(
                referentIds.filter(userId => isUUID(userId))
                    .map(userId => this.officeUserRepo.getPublicProfileUser(userId))
            )
        } catch (error) {
            this.logger.error(`[ChatMessageFieldResolver] Field mentionTo `, JSON.stringify(error));
        }
    }

    @ResolveField('readers', _return => [OfficeUser], { nullable: true })
    async readers(
        @Parent() root: OfficeChatMessage
    ) {
        try {
            if (root.readerIds && root.readerIds.length > 0) {
                const readerIds = root.readerIds

                return await Promise.all(
                    readerIds.filter(userId => isUUID(userId))
                        .map(userId => this.officeUserRepo.getPublicProfileUser(userId))
                )
            }
        } catch (error) {
            this.logger.error(`[ChatMessageReactionFieldResolver] Field readers`, JSON.stringify(error));
        }
    }
}