import { Args, Mutation, Resolver } from '@nestjs/graphql';
import { SetMetadata } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ChatNotifyService } from "@modules/chat/chat-notify/chat-notify.service";
import { ChatNotifyUserData } from "@modules/chat/chat-notify/dto/chat-notify.args";

@Resolver()
export class ChatNotifyResolver {

    constructor(
        private chatNotifyService: ChatNotifyService
    ) {
    }

    @Mutation(() => Boolean, { name: 'chatNotifyUser', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async chatNotifyUser(
        @Args('arguments', { nullable: true }) args: ChatNotifyUserData,
    ): Promise<boolean> {
        return this.chatNotifyService.sendToUsers(args)
    }
}
