import { Args, Query, Resolver } from '@nestjs/graphql';
import { CategoryAssetService } from "@modules/graphql/management/asset/category-asset/category-asset.service";
import {
    CategoryAssetListResponse
} from "@modules/graphql/management/asset/category-asset/dto/category-asset.response";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import {
    ManagementCategoryAssetFilter
} from "@modules/graphql/management/asset/category-asset/dto/category-asset.args";
import { WarehouseAssetService } from "@modules/graphql/management/asset/warehouse-asset/warehouse-asset.service";
import {
    WarehouseAssetListResponse
} from "@modules/graphql/management/asset/warehouse-asset/dto/warehouse-asset.response";
import {
    ManagementWarehouseAssetFilter
} from "@modules/graphql/management/asset/warehouse-asset/dto/warehouse-asset.args";

@Resolver()
export class WarehouseAssetResolver {
    constructor(private readonly warehouseAssetService: WarehouseAssetService) {
    }

    @Query(() => WarehouseAssetListResponse, {name: 'managementWarehouseAssetList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementWarehouseAssetList(
        @Args('filter', {nullable: true}) filter: ManagementWarehouseAssetFilter,
    ): Promise<WarehouseAssetListResponse> {
        return this.warehouseAssetService.list(filter)
    }
}
