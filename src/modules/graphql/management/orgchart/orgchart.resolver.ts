import { Inject, SetMetadata, forwardRef, UseInterceptors } from "@nestjs/common";
import { Args, Mutation, Query, Resolver } from "@nestjs/graphql";
import { OfficeError } from "src/common/office.error";
import { OfficeOrgChart, OfficeUser, UserDepartment } from "src/models/entities";
import { ServiceActions, ServiceKeys, UserType } from "src/modules/core/middleware/guard/service.action";
import { ILike, In, Not } from "typeorm";
import {
    EditOrgChartArgs,
    OrgChartArgs,
    OrgChartFilter, OrgChartFullListFilter, SysOrgChartFilter,
    UpsertOrgChartArgs, UserOrgChartFilter, UserSysOrgChartFilter
} from "./orgchart.args";
import { BulkUpsertOrgChartResponse, OrgChartResponse, UpsertOrgChartResponse } from "./orgchart.response";
import { RequesterId } from "src/modules/core/middleware/decorator/user.decorator";
import { BearerAccessToken } from "src/modules/core/middleware/decorator/request.decorator";
import { OrgChartService } from "./orgchart.service";
import { File } from "src/modules/core/storage/objects/file";
import {
    FixedDataOrgChartUserAllAndWithChildInterceptor, FixedDataOrgChartUserAllInterceptor,
    OrgChartFullSysWithFilterInterceptor,
    OrgChartFullWithFilterInterceptor, OrgChartUserSysWithFilterInterceptor,
    OrgChartUserWithFilterInterceptor
} from "@interceptors/org-chart.interceptor";
import { ListDepartmentsOfOrg, ListUsersOfOrg } from "@core/middleware/decorator/org-chart.decorator";
import { OfficeUserResponse } from "@modules/graphql/management/employee/employee.response";
import { RequestContext } from "@common/context/request.context";
import { ErrorInterceptor } from "@interceptors/error.interceptor";

@Resolver()
export class OrgChartResolver {
    constructor(
        @Inject(forwardRef(() => OrgChartService))
        private readonly orgChartService: OrgChartService
    ) { }

    @Mutation(() => OfficeOrgChart, { name: 'managementAddOrgChart' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementAddOrgChart(
        @Args('arguments', { nullable: false }) args: OrgChartArgs,
        @RequesterId() requesterId: string,
    ): Promise<OfficeOrgChart> {

        const where: any = [{
            name: args.name,
            parentId: args.parentId ? args.parentId : 'root'
        }]

        if (args.parentId) {
            where.push({
                name: args.name,
                id: args.parentId
            })
        }

        const checkName = await OfficeOrgChart.findOne({
            where
        })
        if (checkName) throw OfficeError.OrgChartNameExisted

        const orgChart = OfficeOrgChart.create({
            name: args.name,
            note: args.note,
            status: args.status,
            code: args.code ?? null,
            createdBy: requesterId,
            updatedBy: requesterId
        })

        if (args.parentId) {
            const parent = await OfficeOrgChart.findOne({
                where: {
                    id: args.parentId
                }
            })

            if (!parent) throw OfficeError.OrgChartNotFound
            orgChart.parentId = args.parentId
        }

        if (args.approverId) {
            const officeUser = await OfficeUser.findOne({
                where: {
                    id: args.approverId
                }
            })

            if (!officeUser) throw OfficeError.EmployeeNotFound
            orgChart.approverId = args.approverId
        }

        return orgChart.save()
    }

    @Query(_return => OrgChartResponse, { name: "managementOrgChartTree" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementOrgChartTree(
        @Args("parentId", { nullable: false, defaultValue: 'root' }) parentId: string
    ): Promise<OrgChartResponse> {
        const [list, count] = await OfficeOrgChart.findAndCount({
            where: {
                parentId: parentId,
                id: In(RequestContext.currentListOrgIds())
            }
        })

        return {
            total: count,
            count: list.length,
            orgCharts: list
        }
    }

    /*admin full list*/
    @Query(_return => OrgChartResponse, { name: "managementOrgChartFullList" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementOrgChartFullList(
        @Args("rootId", { nullable: true }) rootId: string,
        @Args("filter", { nullable: true }) filter: OrgChartFullListFilter,
    ): Promise<OrgChartResponse> {
        if (rootId) {
            filter.rootId = rootId
        }
        return this.orgChartService.getAllBySysUser(filter)
    }

    @Query(_return => OrgChartResponse, { name: "managementOrgChartList" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async managementOrgChartList(
        @Args("filter", { nullable: true }) filter: OrgChartFilter,
    ): Promise<OrgChartResponse> {
        return this.orgChartService.getListByFilters(filter)
    }

    @Query(_return => OrgChartResponse, { name: "officeOrgChartList" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(OrgChartFullWithFilterInterceptor)
    async officeOrgChartList(
        @Args("filter", { nullable: true }) filter: OrgChartFilter,
        @ListDepartmentsOfOrg('list') list: any,
        @ListDepartmentsOfOrg('count') count: number,
    ): Promise<OrgChartResponse> {
        return {
            total: count,
            count: list?.length,
            orgCharts: list
        }
    }

    @Query(_return => OrgChartResponse, { name: "adminOrgChartList" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(OrgChartFullSysWithFilterInterceptor)
    async adminOrgChartList(
        @Args("filter", { nullable: true }) filter: SysOrgChartFilter,
        @ListDepartmentsOfOrg('list') list: any,
        @ListDepartmentsOfOrg('count') count: number,
    ): Promise<OrgChartResponse> {
        return {
            total: count,
            count: list?.length,
            orgCharts: list
        }
    }

    @Query(_return => OfficeUserResponse, { name: "officeListEmployeeOfOrgChart" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(OrgChartUserWithFilterInterceptor)
    async officeListEmployeeOfOrgChart(
        @Args("filter", { nullable: false }) filter: UserOrgChartFilter,
        @ListUsersOfOrg('list') list: any,
        @ListUsersOfOrg('count') count: number,
    ): Promise<OfficeUserResponse> {
        return {
            total: count,
            count: list?.length,
            officeUsers: list
        }
    }

    @Query(_return => OfficeUserResponse, { name: "officeEmployeeFullOrgChartList" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(OrgChartUserWithFilterInterceptor)
    async officeEmployeeFullOrgChartList(
        @Args("filter", { nullable: false }) filter: UserOrgChartFilter,
    ): Promise<OfficeUserResponse> {
        const [list, count] = await this.orgChartService.getAllUserOfAllOrg(filter)

        return {
            total: count,
            count: list?.length,
            officeUsers: list
        }
    }

    @Query(_return => OfficeUserResponse, { name: "managementListEmployeeOfOrgChart" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(OrgChartUserSysWithFilterInterceptor)
    async managementListEmployeeOfOrgChart(
        @Args("filter", { nullable: false }) filter: UserSysOrgChartFilter,
        @ListUsersOfOrg('list') list: any,
        @ListUsersOfOrg('count') count: number,
    ): Promise<OfficeUserResponse> {
        return {
            total: count,
            count: list?.length,
            officeUsers: list
        }
    }

    @Mutation(() => OfficeOrgChart, { name: 'managementEditOrgChart' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementEditOrgChart(
        @Args('arguments', { nullable: false }) args: EditOrgChartArgs,
        @RequesterId() requesterId: string,
    ): Promise<OfficeOrgChart> {
        return this.orgChartService.managementEditOrgChart(args)
    }

    @Mutation(() => OfficeOrgChart, { name: 'managementRemoveOrgChart' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementRemoveOrgChart(
        @Args("id", { nullable: false }) id: string,
        @RequesterId() requesterId: string,
    ): Promise<OfficeOrgChart> {
        const existedOrg = await OfficeOrgChart.findOne({
            where: {
                id: id
            }
        })

        if (!existedOrg) {
            throw OfficeError.OrgChartNotFound
        }

        const relationOrgs = await OfficeOrgChart.find({
            where: {
                path: ILike(`%${existedOrg.id}%`)
            }
        })
        // console.log("relationOrgs: ", relationOrgs)
        const relationOrgIds = relationOrgs.map(o => {
            o.updatedBy = requesterId
            return o.id
        })
        console.log("relationOrgIds: ", relationOrgIds)
        //check nhân sự thuộc đơn vị
        const departmentUsers = await UserDepartment.find({
            where: {
                departmentId: In(relationOrgIds)
            }
        })
        if (departmentUsers.length > 0) throw OfficeError.OrgChartNotEmptyEmployee

        await OfficeOrgChart.softRemove(relationOrgs)

        return existedOrg
    }

    @Mutation(() => OfficeOrgChart, { name: 'managementOrgChartOnOff' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementOrgChartOnOff(
        @Args("id", { nullable: false }) id: string,
    ): Promise<OfficeOrgChart> {
        return this.orgChartService.managementOrgChartOnOff(id)
    }

    @Mutation(_type => BulkUpsertOrgChartResponse, { nullable: true, name: "managementOrgChartBulkUpsert" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementOrgChartBulkUpsert(
        @Args('orgcharts', { type: () => [UpsertOrgChartArgs] }) orgcharts: UpsertOrgChartArgs[],
        @RequesterId() requesterId: string,
    ): Promise<BulkUpsertOrgChartResponse> {
        try {
            const response: UpsertOrgChartResponse[] = []
            const upsertOrgCharts: OfficeOrgChart[] = []
            // const newOrgChartDict: any = {}
            for (const input of orgcharts) {
                if (!input.name) {
                    response.push({ ...input, errorMessage: 'Vui lòng không để trống trường bắt buộc' })
                    continue
                }

                if (input.id) {
                    // update
                    const existedOrgChart = await OfficeOrgChart.findOne({
                        where: { id: input.id }
                    })

                    if (!existedOrgChart) {
                        response.push({ ...input, errorMessage: 'Mã id không tồn tại' })
                        continue
                    }

                    if (input.code && input.code !== existedOrgChart.code) {
                        const checkCode = await OfficeOrgChart.findOne({
                            where: { code: input.code }
                        })

                        if (checkCode) {
                            response.push({ ...input, errorMessage: 'Mã phòng ban đã tồn tại trên hệ thống' })
                            continue
                        }
                        existedOrgChart.code = input.code
                    }

                    if (input.parentCode) {
                        const parent = await OfficeOrgChart.findOne({
                            where: { code: input.parentCode }
                        })

                        if (!parent) {
                            response.push({ ...input, errorMessage: 'Mã cấp trên trực tiếp không tồn tại' })
                            continue
                        }

                        existedOrgChart.parentId = parent.id
                    } else {
                        existedOrgChart.parentId = 'root'
                    }

                    existedOrgChart.name = input.name
                    existedOrgChart.updatedBy = requesterId
                    upsertOrgCharts.push(existedOrgChart)
                    response.push({ ...input, errorMessage: 'Cập nhật thành công' })
                } else {
                    // insert
                    const newOrgChart = OfficeOrgChart.create({
                        name: input.name,
                        createdBy: requesterId,
                        updatedBy: requesterId
                    })

                    if (input.code) {
                        const checkCode = await OfficeOrgChart.findOne({
                            where: { code: input.code }
                        })

                        if (checkCode) {
                            response.push({ ...input, errorMessage: 'Mã phòng ban đã tồn tại trên hệ thống' })
                            continue
                        }
                        newOrgChart.code = input.code
                    }

                    if (input.parentCode) {
                        const parent = await OfficeOrgChart.findOne({
                            where: { code: input.parentCode }
                        })

                        if (!parent) {
                            response.push({ ...input, errorMessage: 'Mã cấp trên trực tiếp không tồn tại' })
                            continue
                        }

                        newOrgChart.parentId = parent.id
                    }
                    upsertOrgCharts.push(newOrgChart)
                    response.push({ ...input, errorMessage: 'Tạo mới thành công' })
                }
            }

            for (const iterator of upsertOrgCharts) {
                await iterator.save()
            }

            return {
                total: response.length,
                count: response.length,
                records: response
            }
        } catch (error) {
            console.log(`Bulk upsert org chart has error: ${error}`)
            throw error
        }
    }

    @Query(() => File, { name: 'managementOrgChartExport', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async export(
        @BearerAccessToken() token: string
    ): Promise<File> {
        // const result = await this.incidentService.ecoIncidentRawQuery(filter)
        // console.log("result: ", result)
        return this.orgChartService.orgChartExport(token)
    }
}