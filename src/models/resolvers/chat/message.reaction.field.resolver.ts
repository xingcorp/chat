import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { OfficeChatMessageReaction, OfficeUser } from "@models/entities";
import { OfficeUserRepo } from "@models/repositories";
import { isUUID } from "validator";
import { LoggerService } from "@core/common/logger.service";

@Resolver(_of => OfficeChatMessageReaction)
export class ChatMessageReactionFieldResolver {
    logger = new LoggerService(ChatMessageReactionFieldResolver.name)

    constructor(
        private readonly officeUserRepo: OfficeUserRepo
    ) { }

    @ResolveField('reactors', _return => [OfficeUser], { nullable: true })
    async sender(
        @Parent() root: OfficeChatMessageReaction
    ) {
        try {
            if (!root.reactorIds || root.reactorIds.length <= 0) {
                return []
            }

            const reactorIds = root.reactorIds
            return await Promise.all(
                reactorIds.filter(userId => isUUID(userId))
                    .map(userId => this.officeUserRepo.getPublicProfileUser(userId))
            )
        } catch (error) {
            this.logger.error(`[ChatMessageReactionFieldResolver] Field reactors `, error);
        }
    }
}