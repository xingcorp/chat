import { Args, Query, Resolver } from '@nestjs/graphql';
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { CategoryAssetService } from "@modules/graphql/management/asset/category-asset/category-asset.service";
import {
    ManagementCategoryAssetFilter
} from "@modules/graphql/management/asset/category-asset/dto/category-asset.args";
import {
    CategoryAssetListResponse
} from "@modules/graphql/management/asset/category-asset/dto/category-asset.response";

@Resolver()
export class CategoryAssetResolver {
    constructor(private readonly categoryAssetService: CategoryAssetService) {
    }

    @Query(() => CategoryAssetListResponse, {name: 'managementCategoryAssetList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementCategoryAssetList(
        @Args('filter', {nullable: true}) filter: ManagementCategoryAssetFilter,
    ): Promise<CategoryAssetListResponse> {
        return this.categoryAssetService.list(filter)
    }
}
