import { OfficeOrgChart, OfficeUser } from "@models/entities";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { OfficeSysUser } from "@models/entities/system.user";
import { Inject, forwardRef } from "@nestjs/common";
import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { BusinessRole } from "src/modules/core/iam/objects/business.role";
import { BusinessRoleService } from "src/modules/core/iam/organization/business.role/business.role.service";
import { BearerAccessToken } from "src/modules/core/middleware/decorator/request.decorator";
import { In } from "typeorm";

@Resolver(_of => OfficeSysUser)
export class OfficeSysUserFieldResolver {
    constructor (
        @Inject(forwardRef(() => BusinessRoleService))
        private readonly businessRoleService: BusinessRoleService
    ) { }

    @ResolveField('orgCharts', _return => [OfficeOrgChart], { nullable: true })
    async infoBlocks(
        @Parent() root: OfficeSysUser
    ) {
        if (root.orgChartIds) {
            return OfficeOrgChart.find({
                where: {
                    id: In(root.orgChartIds)
                }
            })
        }

        return null
    }

    @ResolveField('businessRole', _return => BusinessRole, { nullable: true })
    async businessRole(
        @Parent() root: OfficeSysUser,
        @BearerAccessToken() token: string,
    ) {
        const { data, error } = await this.businessRoleService.findById(token, root.businessRoleId)
        if (error) return null
        return data
    }

    @ResolveField('createdByUser', _return => OfficeSysUser, { nullable: true })
    async createdByUser(
        @Parent() root: OfficeSysUser
    ) {
        return OfficeSysUser.findOne({ where: { id: root.createdBy }, withDeleted: true })
    }

    @ResolveField('updatedByUser', _return => OfficeSysUser, { nullable: true })
    async updatedByUser(
        @Parent() root: OfficeSysUser
    ) {
        return OfficeSysUser.findOne({ where: { id: root.createdBy }, withDeleted: true })
    }

    @ResolveField('linkedUser', _return => OfficeUser, { nullable: true })
    async linkedUser(
        @Parent() root: OfficeSysUser
    ) {
        const _this = await OfficeSysUser.findOne({
            relations: ['user'],
            where: { id: root.id }
        })

        return _this?.user
    }
}