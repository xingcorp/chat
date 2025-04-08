import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { DocumentWiki, VersionWiki } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import {
    FixedDataOrgChartUserAllAndWChildInterceptor,
    FixedDataOrgChartUserAllInterceptor
} from "@interceptors/org-chart.interceptor";
import { DocumentPermissions } from "@core/middleware/decorator/user.decorator";
import { DocumentWikiListResponse } from "../../../../arguments/wiki/response.wiki";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import {
    OfficeWikiFilter,
    VersionWikiCommentCreateInput,
    WikiCommentCreateInput
} from "@modules/graphql/management/wiki/dto/wiki.args";
import { WikiService } from "@modules/graphql/management/wiki/wiki.service";

@Resolver()
export class ClientWikiResolver {
    constructor(private readonly wikiService: WikiService) {
    }

    @Query(() => DocumentWiki, {name: 'officeWikiGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeWikiGet(
        @Args('id', {nullable: false}) id: string,
        @DocumentPermissions() documentPermissions: any,
    ): Promise<DocumentWiki> {
        return this.wikiService.clientGet(id, documentPermissions)
    }

    @Query(() => DocumentWikiListResponse, {name: 'officeWikiList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeWikiList(
        @Args('filter', {nullable: true}) filter: OfficeWikiFilter,
        @DocumentPermissions() documentPermissions: any,
    ): Promise<DocumentWikiListResponse> {
        return this.wikiService.clientList(filter, documentPermissions)
    }

    @Query(() => DocumentWikiListResponse, {name: 'officeWikiLatestList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeWikiLatestList(
        @DocumentPermissions() documentPermissions: any,
    ): Promise<DocumentWikiListResponse> {
        return this.wikiService.clientLatestList(documentPermissions)
    }

    @Mutation(() => VersionWiki, { name: 'officeWikiComment', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeWikiComment(
        @Args('arguments', { nullable: false }) args: WikiCommentCreateInput,
    ): Promise<VersionWiki> {
        return this.wikiService.clientWikiCommentCreate(args)
    }

    @Mutation(() => VersionWiki, { name: 'officeVersionWikiComment', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeVersionWikiComment(
        @Args('arguments', { nullable: false }) args: VersionWikiCommentCreateInput,
    ): Promise<VersionWiki> {
        return this.wikiService.clientVersionCommentCreate(args)
    }
}
