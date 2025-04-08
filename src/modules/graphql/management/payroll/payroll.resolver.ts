import { Args, Mutation, Resolver, Query } from '@nestjs/graphql';
import { PayrollService } from "@modules/graphql/management/payroll/payroll.service";
import { RequesterId, UserIp } from "@core/middleware/decorator/user.decorator";
import { InfoBlock, InfoField, OfficePayroll, OfficeUser } from "@models/entities";
import { Ip, SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import {
    PayrollBlockBulkUpsertInput,
    PayrollBlockCreateInput,
    PayrollBlockFieldCreateInput, PayrollBlockFieldUpdateInput, PayrollBlockUpdateInput, PayrollBulkUpsertInput,
    PayrollCreateInput, PayrollListFilter, PayrollUpdateInput
} from "@modules/graphql/management/payroll/dto/payroll.args";
import {
    PayrollBlockBulkUpsertResponse,
    PayrollBulkUpsertResponse, PayrollListResponse
} from "@modules/graphql/management/payroll/dto/payroll.response";
import { FixedDataOrgChartInterceptor, OrgChartSysFullInterceptor } from "@interceptors/org-chart.interceptor";
import { ListDataOfOrg, ListDepartmentsOfOrg } from "@core/middleware/decorator/org-chart.decorator";

@Resolver()
export class PayrollResolver {
    constructor(private readonly payrollService: PayrollService) {}

    @Mutation(() => OfficePayroll, { name: 'managementPayrollCreate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementPayrollCreate(
        @Args('arguments', { nullable: false }) args: PayrollCreateInput,
        @RequesterId() requesterId: string,
    ): Promise<OfficePayroll> {
        return this.payrollService.create(requesterId, args)
    }

    @Mutation(() => OfficePayroll, { name: 'managementPayrollUpdate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementPayrollUpdate(
        @Args('arguments', { nullable: false }) args: PayrollUpdateInput,
        @RequesterId() requesterId: string,
    ): Promise<OfficePayroll> {
        return this.payrollService.update(requesterId, args)
    }

    @Mutation(() => PayrollBulkUpsertResponse, { name: 'managementPayrollBulkUpsert', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementPayrollBulkUpsert(
        @Args('payrolls', { type: () => [PayrollBulkUpsertInput] }) args: PayrollBulkUpsertInput[],
        @RequesterId() requesterId: string,
    ): Promise<PayrollBulkUpsertResponse> {
        return this.payrollService.bulkUpsert(requesterId, args)
    }

    @Query(() => OfficePayroll, { name: 'managementPayrollGet', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(OrgChartSysFullInterceptor)
    async managementPayrollGet(
        @Args('id', { nullable: false }) id: string,
        @ListDepartmentsOfOrg('ids') orgIds: string[],
    ): Promise<OfficePayroll> {
        return this.payrollService.getById(id, orgIds)
    }

    @Query(() => PayrollListResponse, { name: 'managementPayrollList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(OrgChartSysFullInterceptor)
    @UseInterceptors(FixedDataOrgChartInterceptor)
    async managementPayrollList(
        @Args('filter', { nullable: true, defaultValue: { page: 1 }}) args: PayrollListFilter,
        @ListDepartmentsOfOrg('ids') orgIds: string[],
    ): Promise<PayrollListResponse> {
        return this.payrollService.getList(args, orgIds)
    }

    @Mutation(() => InfoBlock, { name: 'managementPayrollBlockCreate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementPayrollBlockCreate(
        @Args('arguments', { nullable: false }) args: PayrollBlockCreateInput,
        @RequesterId() requesterId: string,
    ): Promise<InfoBlock> {
        return this.payrollService.createBlock(requesterId, args)
    }

    @Mutation(() => InfoBlock, { name: 'managementPayrollBlockUpdate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementPayrollBlockUpdate(
        @Args('arguments', { nullable: false }) args: PayrollBlockUpdateInput,
        @RequesterId() requesterId: string,
    ): Promise<InfoBlock> {
        return this.payrollService.updateBlock(requesterId, args)
    }

    @Mutation(() => PayrollBlockBulkUpsertResponse, { name: 'managementPayrollBlockBulkUpsert', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementPayrollBlockBulkUpsert(
        @Args('blocks', { type: () => [PayrollBlockBulkUpsertInput] }) args: PayrollBlockBulkUpsertInput[],
        @RequesterId() requesterId: string,
    ): Promise<PayrollBlockBulkUpsertResponse> {
        return this.payrollService.bulkUpsertBlock(requesterId, args)
    }

    @Mutation(() => String, { name: 'managementPayrollBlockDelete', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementPayrollBlockDelete(
        @Args('id') id: string,
        @RequesterId() requesterId: string,
    ): Promise<string> {
        return this.payrollService.deleteBlock(requesterId, id)
    }

    @Mutation(() => InfoField, { name: 'managementPayrollBlockFieldCreate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementPayrollBlockFieldCreate(
        @Args('arguments', { nullable: false }) args: PayrollBlockFieldCreateInput,
        @RequesterId() requesterId: string,
    ): Promise<InfoField> {
        return this.payrollService.createBlockField(requesterId, args)
    }

    @Mutation(() => InfoField, { name: 'managementPayrollBlockFieldUpdate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementPayrollBlockFieldUpdate(
        @Args('arguments', { nullable: false }) args: PayrollBlockFieldUpdateInput,
        @RequesterId() requesterId: string,
    ): Promise<InfoField> {
        return this.payrollService.updateBlockField(requesterId, args)
    }

    @Query(() => InfoField, { name: 'managementInfoFieldGet', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementInfoFieldGet(
        @Args('id', { nullable: false }) id: string,
        @RequesterId() requesterId: string,
    ): Promise<InfoField> {
        return this.payrollService.getInfoFieldById(id)
    }
}
