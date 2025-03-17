import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { TagService } from "@modules/graphql/management/document/tag/tag.service";
import { TagDocument } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import {
    DocumentTagCreateInput, DocumentTagFilterInput,
    DocumentTagUpdateInput,
    DocumentTagUpsertInput
} from "@modules/graphql/management/document/dto/tag.args";
import { DocumentTagResponse } from "@modules/graphql/management/document/dto/tag.response";

@Resolver()
export class TagResolver {

    constructor(private readonly tagService: TagService) {
    }

    @Mutation(() => TagDocument, {name: 'manageDocumentTagCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageDocumentTagCreate(
        @Args('arguments', {nullable: false}) args: DocumentTagCreateInput,
    ): Promise<TagDocument> {
        return this.tagService.create(args)
    }

    @Mutation(() => TagDocument, {name: 'manageDocumentTagUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageDocumentTagUpdate(
        @Args('arguments', {nullable: false}) args: DocumentTagUpdateInput,
    ): Promise<TagDocument> {
        return this.tagService.update(args)
    }

    @Mutation(() => TagDocument, {name: 'manageDocumentTagUpsert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageDocumentTagUpsert(
        @Args('arguments', {nullable: false}) args: DocumentTagUpsertInput,
    ): Promise<TagDocument> {
        return this.tagService.upsert(args)
    }

    @Query(() => TagDocument, {name: 'manageDocumentTagGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageDocumentTagGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<TagDocument> {
        return this.tagService.get(id)
    }

    @Query(() => DocumentTagResponse, {name: 'manageDocumentTagList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async manageDocumentTagList(
        @Args('filter', {nullable: true}) filter: DocumentTagFilterInput,
    ): Promise<DocumentTagResponse> {
        return this.tagService.list(filter)
    }

    @Mutation(() => String, {name: 'manageDocumentTagRemove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageDocumentTagRemove(
        @Args('id', {nullable: false}) id: string,
    ): Promise<string> {
        return this.tagService.remove(id)
    }

    /*Office*/
    @Query(() => DocumentTagResponse, {name: 'officeDocumentTagList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeDocumentTagList(
        @Args('filter', {nullable: true}) filter: DocumentTagFilterInput,
    ): Promise<DocumentTagResponse> {
        return this.tagService.list(filter)
    }

}
