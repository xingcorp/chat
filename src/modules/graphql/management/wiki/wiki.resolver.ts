import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { DocumentWiki, VersionWiki } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import {
    FixedDataOrgChartUserAllAndWChildInterceptor,
    FixedDataOrgChartUserAllInterceptor
} from "@interceptors/org-chart.interceptor";
import { WikiService } from "@modules/graphql/management/wiki/wiki.service";
import {
    ManageWikiFilter,
    VersionWikiCommentCreateInput,
    WikiCreateInput,
    WikiUpdateInput,
    WikiNewVersionCreateInput,
    WikiSetImportantInput,
    WikiCopyCreateInput,
    WikiMoveInput,
    WikiNewVersionRevertInput,
    WikiCommentCreateInput, WikiInfoUpdateInput
} from "@modules/graphql/management/wiki/dto/wiki.args";
import { DocumentWikiListResponse } from "../../../../arguments/wiki/response.wiki";
@Resolver()
export class WikiResolver {

    constructor(private readonly wikiService: WikiService) {
    }

    @Mutation(() => DocumentWiki, {name: 'manageWikiCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiCreate(
        @Args('arguments', {nullable: false}) args: WikiCreateInput,
    ): Promise<DocumentWiki> {
        return this.wikiService.create(args)
    }

    @Mutation(() => DocumentWiki, {name: 'manageWikiUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiUpdate(
        @Args('arguments', {nullable: false}) args: WikiUpdateInput,
    ): Promise<DocumentWiki> {
        return this.wikiService.update(args)
    }

    @Mutation(() => DocumentWiki, {name: 'manageWikiSetImportant', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiSetImportant(
        @Args('arguments', {nullable: false}) args: WikiSetImportantInput,
    ): Promise<DocumentWiki> {
        return this.wikiService.setImportant(args)
    }

    @Mutation(() => DocumentWiki, {name: 'manageWikiOnOff', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiOnOff(
        @Args('id', {nullable: false}) id: string,
    ): Promise<DocumentWiki> {
        return this.wikiService.manageWikiOnOff(id)
    }

    @Mutation(() => DocumentWiki, {name: 'manageWikiInfoUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiInfoUpdate(
        @Args('arguments', {nullable: false}) args: WikiInfoUpdateInput,
    ): Promise<DocumentWiki> {
        return this.wikiService.infoUpdate(args)
    }

    @Query(() => DocumentWiki, {name: 'manageWikiGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<DocumentWiki> {
        return this.wikiService.get(id)
    }

    @Query(() => DocumentWikiListResponse, {name: 'manageWikiList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async manageWikiList(
        @Args('filter', {nullable: true}) filter: ManageWikiFilter,
    ): Promise<DocumentWikiListResponse> {
        return this.wikiService.list(filter)
    }

    @Mutation(() => String, {name: 'manageWikiRemove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiRemove(
        @Args('id', {nullable: false}) id: string,
    ): Promise<string> {
        return this.wikiService.remove(id)
    }

    @Mutation(() => [DocumentWiki], {name: 'manageWikiCopy', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiCopy(
        @Args('arguments', {nullable: false}) args: WikiCopyCreateInput,
    ): Promise<DocumentWiki[]> {
        return this.wikiService.copy(args)
    }

    @Mutation(() => DocumentWiki, {name: 'manageWikiMove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiMove(
        @Args('arguments', {nullable: false}) args: WikiMoveInput,
    ): Promise<DocumentWiki> {
        return this.wikiService.move(args)
    }

    @Mutation(() => VersionWiki, { name: 'manageWikiComment', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async manageWikiComment(
        @Args('arguments', { nullable: false }) args: WikiCommentCreateInput,
    ): Promise<VersionWiki> {
        return this.wikiService.adminWikiCommentCreate(args)
    }

    /*version*/

    @Mutation(() => DocumentWiki, {name: 'manageWikiNewVersionCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiNewVersionCreate(
        @Args('arguments', {nullable: false}) args: WikiNewVersionCreateInput,
    ): Promise<DocumentWiki> {
        return this.wikiService.versionCreate(args)
    }

    @Mutation(() => DocumentWiki, {name: 'manageWikiNewVersionRevert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiNewVersionRevert(
        @Args('arguments', {nullable: false}) args: WikiNewVersionRevertInput,
    ): Promise<DocumentWiki> {
        return this.wikiService.versionRevert(args)
    }

    @Mutation(() => VersionWiki, {name: 'manageVersionWikiRecall', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageVersionWikiRecall(
        @Args('versionWikiId', {nullable: false}) versionWikiId: string,
    ): Promise<VersionWiki> {
        return this.wikiService.versionRecall(versionWikiId)
    }

    @Mutation(() => VersionWiki, { name: 'manageVersionWikiComment', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async manageVersionWikiComment(
        @Args('arguments', { nullable: false }) args: VersionWikiCommentCreateInput,
    ): Promise<VersionWiki> {
        return this.wikiService.adminVersionCommentCreate(args)
    }
}
