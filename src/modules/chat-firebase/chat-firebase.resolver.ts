import { Args, Query, Resolver } from '@nestjs/graphql';
import { ChatFirebaseService } from "@modules/chat-firebase/chat-firebase.service";
import { SetMetadata, UseGuards, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import {
    FixedDataOrgChartUserAllInterceptor,
} from "@interceptors/org-chart.interceptor";
import {
    OfficeChatMessageSearchArgs
} from "@modules/chat-firebase/dto/chat-firebase.arg";
import {
    OfficeChatLinkPreviewResponse,
    OfficeChatMessageSearchResponse
} from "@modules/chat-firebase/dto/chat-firebase.response";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { Throttle } from "@nestjs/throttler";
import { GqlThrottlerGuard } from "../../guards/gql-throttler.guard";


@Resolver()
export class ChatFirebaseResolver {
    constructor(
        private readonly chatService: ChatFirebaseService,
    ) {
    }

    // @Query(_return => String, { name: "testSearch" })
    // async testSearch(
    //     @Args('filter', { nullable: true }) filter: FirebaseFilterMessageArgs
    // ): Promise<any> {
    //
    //     const test = await this.chatService.searchMessage(filter)
    //     return 'gi'
    // }

    @UseGuards(GqlThrottlerGuard)
    @Throttle({ default: { limit: 1, ttl: 1000 } })
    @Query(() => OfficeChatMessageSearchResponse, { name: 'officeChatMessageSearch', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeChatMessageSearch(
        @Args('filter', { nullable: true}) args: OfficeChatMessageSearchArgs,
    ): Promise<OfficeChatMessageSearchResponse> {
        return this.chatService.list(args)
    }

    @Query(() => OfficeChatLinkPreviewResponse, { name: 'officeChatLinkPreview', nullable: true })
    @UseInterceptors(ErrorInterceptor)
    async officeChatLinkPreview(
        @Args('url', { nullable: false}) url: string,
    ): Promise<OfficeChatLinkPreviewResponse> {
        return this.chatService.linkPreviewGet(url)
    }
}
