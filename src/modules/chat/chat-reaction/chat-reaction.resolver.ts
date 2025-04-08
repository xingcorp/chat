import { Mutation, Resolver } from '@nestjs/graphql';
import { SetMetadata } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ChatReactionService } from "@modules/chat/chat-reaction/chat-reaction.service";
import { OfficeRequesterId } from '@core/middleware/decorator/user.decorator';
import { RedisService } from '@core/common/redis.service';
import { RedisKey } from '@core/common/common.type';

@Resolver()
export class ChatReactionResolver {
    constructor(
        private chatReactionService: ChatReactionService,
        private readonly redisService: RedisService,
    ) { }

    @Mutation(() => [String], { name: 'chatReactionFrequentlyUsed', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatReactionMessage(
        @OfficeRequesterId() userId: string
    ): Promise<string[]> {
        const reactionCodes = await this.redisService.zrevrange(RedisKey.MemberReactionUsed(userId), 0, 10)
        return reactionCodes
    }
}
