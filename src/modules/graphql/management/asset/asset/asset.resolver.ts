import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { AssetService } from "@modules/graphql/management/asset/asset/asset.service";
import { Asset } from "@models/entities";
import { ParseArrayPipe, SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import {
    FixedDataOrgChartUserAllAndWChildInterceptor, FixedDataOrgChartUserAllAndWithChildInterceptor,
} from "@interceptors/org-chart.interceptor";
import {
    AssetBulkUpsertInput,
    AssetCreateInput,
    AssetUpdateInput,
    ManagementAssetFilter
} from "@modules/graphql/management/asset/asset/dto/asset.args";
import { AssetBulkUpsertResponse, AssetListResponse } from "@modules/graphql/management/asset/asset/dto/asset.response";
import { ValidateDataTypeBulkUpsertInterceptor } from "@interceptors/validate-data-type.interceptor";
import { File } from "@core/storage/objects/file";
import { FieldsListResponse } from "@models/base/index.response";

@Resolver()
export class AssetResolver {

    constructor(private readonly assetService: AssetService) {
    }

    @Mutation(() => [Asset], {name: 'managerAssetCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managerAssetCreate(
        @Args('arguments', {nullable: false}) args: AssetCreateInput,
    ): Promise<Asset[]> {
        return this.assetService.create(args)
    }

    @Mutation(() => Asset, {name: 'managerAssetUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managerAssetUpdate(
        @Args('arguments', {nullable: false}) args: AssetUpdateInput,
    ): Promise<Asset> {
        return this.assetService.update(args)
    }

    @Query(() => Asset, {name: 'managementAssetGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managementAssetGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<Asset> {
        return this.assetService.get(id)
    }

    @Query(() => AssetListResponse, {name: 'managementAssetList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementAssetList(
        @Args('filter', {nullable: true}) filter: ManagementAssetFilter,
    ): Promise<AssetListResponse> {
        return this.assetService.list(filter)
    }

    @Mutation(() => String, {name: 'managerAssetRemove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managerAssetRemove(
        @Args('id', {nullable: false}) id: string,
    ): Promise<string> {
        return this.assetService.remove(id)
    }

    @Query(() => FieldsListResponse, {name: 'managementImportAssetFieldsKeyList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementImportAssetFieldsKeyList(): Promise<FieldsListResponse> {
        return this.assetService.managementImportAssetFieldsKeyList()
    }

    @Query(() => FieldsListResponse, {name: 'managementImportAssetFieldsTitleList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementImportAssetFieldsTitleList(): Promise<FieldsListResponse> {
        return this.assetService.managementImportAssetFieldsTitleList()
    }

    @Query(() => File, {name: 'managementImportAssetTemplateExport', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementImportAssetTemplateExport(): Promise<File> {
        return this.assetService.importAssetTemplateExport()
    }

    @Mutation(() => AssetBulkUpsertResponse, {name: 'managementAssetBulkUpsert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ValidateDataTypeBulkUpsertInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managementAssetBulkUpsert(
        @Args(
            'arguments',
            {type: () => [AssetBulkUpsertInput]},
            new ParseArrayPipe({items: AssetBulkUpsertInput})
        ) args: AssetBulkUpsertInput[],
    ): Promise<AssetBulkUpsertResponse> {
        return this.assetService.bulkUpsert(args)
    }
}
