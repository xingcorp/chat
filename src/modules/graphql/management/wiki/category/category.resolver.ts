import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { CategoryService } from "@modules/graphql/management/wiki/category/category.service";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { CategoryWiki } from "@models/entities/wiki/category.wiki";
import {
    WikiCategoryCreateInput, WikiCategoryFilterInput,
    WikiCategoryUpdateInput, WikiCategoryUpsertInput
} from "@modules/graphql/management/wiki/dto/category.wiki.args";
import { CategoryWikiResponse } from "@modules/graphql/management/wiki/dto/category.wiki.response";

@Resolver()
export class CategoryResolver {
    constructor(private readonly categoryService: CategoryService) {}

    @Mutation(() => CategoryWiki, {name: 'manageWikiCategoryCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiCategoryCreate(
        @Args('arguments', {nullable: false}) args: WikiCategoryCreateInput,
    ): Promise<CategoryWiki> {
        return this.categoryService.create(args)
    }

    @Mutation(() => CategoryWiki, {name: 'manageWikiCategoryUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiCategoryUpdate(
        @Args('arguments', {nullable: false}) args: WikiCategoryUpdateInput,
    ): Promise<CategoryWiki> {
        return this.categoryService.update(args)
    }

    @Mutation(() => CategoryWiki, {name: 'manageWikiCategoryUpsert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiCategoryUpsert(
        @Args('arguments', {nullable: false}) args: WikiCategoryUpsertInput,
    ): Promise<CategoryWiki> {
        return this.categoryService.upsert(args)
    }

    @Query(() => CategoryWiki, {name: 'manageWikiCategoryGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiCategoryGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<CategoryWiki> {
        return this.categoryService.get(id)
    }

    @Query(() => CategoryWikiResponse, {name: 'manageWikiCategoryList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async manageWikiCategoryList(
        @Args('filter', {nullable: true}) filter: WikiCategoryFilterInput,
    ): Promise<CategoryWikiResponse> {
        return this.categoryService.list(filter)
    }

    @Mutation(() => String, {name: 'manageWikiCategoryRemove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageWikiCategoryRemove(
        @Args('id', {nullable: false}) id: string,
    ): Promise<string> {
        return this.categoryService.remove(id)
    }

    /*Office*/
    @Query(() => CategoryWikiResponse, {name: 'officeWikiCategoryList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeWikiCategoryList(
        @Args('filter', {nullable: true}) filter: WikiCategoryFilterInput,
    ): Promise<CategoryWikiResponse> {
        return this.categoryService.list(filter)
    }
}
