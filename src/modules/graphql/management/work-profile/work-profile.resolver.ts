import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import {
    InfoField,
    UserWorkProfile
} from "@models/entities";
import { ParseArrayPipe, SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import {
    FixedDataOrgChartUserAllAndWChildInterceptor, FixedDataOrgChartUserAllAndWithChildInterceptor,
    FixedDataOrgChartUserAllInterceptor,
} from "@interceptors/org-chart.interceptor";
import { WorkProfileService } from "@modules/graphql/management/work-profile/work-profile.service";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import {
    ManagementWorkProfileFilter, OfficeWorkProfileFilter, WorkProfileBulkUpsertInput,
    WorkProfileCreateInput, WorkProfileUpdateInput,
} from "@modules/graphql/management/work-profile/dto/work-profile.args";
import {
    WorkProfileBulkUpsertResponse,
    WorkProfileInfoType,
    WorkProfileListResponse
} from "@modules/graphql/management/work-profile/dto/work-profile.response";
import { ValidateDataTypeBulkUpsertInterceptor } from "@interceptors/validate-data-type.interceptor";
import { File } from "@core/storage/objects/file";
import { ImportUserFieldsGetResponse } from "@modules/graphql/management/employee/employee.response";

@Resolver()
export class WorkProfileResolver {

    constructor(private readonly workProfileService: WorkProfileService) {
    }

    @Query(() => [InfoField], {name: 'managementWorkProfileGetSoftFields', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    async managementWorkProfileGetSoftFields(): Promise<InfoField[]> {
        return this.workProfileService.getSoftFields()
    }

    @Query(() => [WorkProfileInfoType], {name: 'managementWorkProfileInfoTypeGetList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    async managementWorkProfileInfoTypeGetList(): Promise<WorkProfileInfoType[]> {
        return this.workProfileService.infoTypeGetList()
    }

    @Mutation(() => UserWorkProfile, {name: 'managementWorkProfileCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managementWorkProfileCreate(
        @Args('arguments', {nullable: false}) args: WorkProfileCreateInput,
    ): Promise<UserWorkProfile> {
        return this.workProfileService.create(args)
    }

    @Mutation(() => UserWorkProfile, {name: 'managementWorkProfileUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managementWorkProfileUpdate(
        @Args('arguments', {nullable: false}) args: WorkProfileUpdateInput,
    ): Promise<UserWorkProfile> {
        return this.workProfileService.update(args)
    }

    @Query(() => UserWorkProfile, {name: 'managementWorkProfileGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managementWorkProfileGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<UserWorkProfile> {
        return this.workProfileService.get(id)
    }

    @Query(() => WorkProfileListResponse, {name: 'managementWorkProfileList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementWorkProfileList(
        @Args('filter', {nullable: true}) filter: ManagementWorkProfileFilter,
    ): Promise<WorkProfileListResponse> {
        return this.workProfileService.listByUserId(filter)
    }

    @Query(() => File, {name: 'managementImportWorkProfileTemplateExport', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementImportWorkProfileTemplateExport(): Promise<File> {
        return this.workProfileService.importWorkProfileTemplateExport()
    }

    @Query(() => ImportUserFieldsGetResponse, {name: 'managementImportWorkProfileFieldsGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementImportWorkProfileFieldsGet(): Promise<ImportUserFieldsGetResponse> {
        return this.workProfileService.importWorkProfileFieldsGet()
    }

    @Query(() => ImportUserFieldsGetResponse, {name: 'managementImportWorkProfileFieldsGetTitle', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementImportWorkProfileFieldsGetTitle(): Promise<ImportUserFieldsGetResponse> {
        return this.workProfileService.importWorkProfileFieldsGetTitle()
    }

    @Mutation(() => WorkProfileBulkUpsertResponse, {name: 'managementWorkProfileBulkUpsert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ValidateDataTypeBulkUpsertInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managementWorkProfileBulkUpsert(
        @Args(
            'arguments',
            {type: () => [WorkProfileBulkUpsertInput]},
            new ParseArrayPipe({items: WorkProfileBulkUpsertInput})
        ) args: WorkProfileBulkUpsertInput[],
    ): Promise<WorkProfileBulkUpsertResponse> {
        return this.workProfileService.bulkUpsert(args)
    }

    @Query(() => File, {name: 'managementWorkProfileExport', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementWorkProfileExport(
        @Args('filter', {nullable: true}) filter: ManagementWorkProfileFilter,
    ): Promise<File> {
        return this.workProfileService.exportWorkProfile(filter)
    }

    /*-------------Office-------------*/

    @Query(() => WorkProfileListResponse, {name: 'officeWorkProfileList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeWorkProfileList(
        @Args('filter', {nullable: true}) filter: OfficeWorkProfileFilter,
    ): Promise<WorkProfileListResponse> {
        return this.workProfileService.listOfUser(filter)
    }
}