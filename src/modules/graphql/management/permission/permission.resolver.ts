import { forwardRef, Inject, SetMetadata } from '@nestjs/common'
import { Args, Mutation, Query, Resolver } from '@nestjs/graphql'
import { PermissionService } from './permission.service'
import { BusinessRoleCodes, ServiceActions, ServiceKeys, UserType } from '../../../core/middleware/guard/service.action'
import { BearerAccessToken } from 'src/modules/core/middleware/decorator/request.decorator'
import { PolicyActionResponse } from 'src/modules/core/iam/access/permission/permission.response'
import { AddSysUserArgs, BusinessRoleCreateArgs, BusinessRoleUpdateArgs, EditSysUserArgs, PermissionBusinessRoleFilter, PermissionUpdateArgs, SysUserFilter } from './permission.args'
import { BusinessRoleService } from 'src/modules/core/iam/organization/business.role/business.role.service'
import { BusinessRoleResponse } from 'src/modules/core/iam/organization/business.role/business.role.response'
import { IAMPolicyActionService } from 'src/modules/core/iam/access/permission/policy.action.service'
import { BusinessRole } from 'src/modules/core/iam/objects/business.role'
import { OfficeError } from 'src/common/office.error'
import { OrganizationId, RequesterId } from 'src/modules/core/middleware/decorator/user.decorator'
import { OfficePermissionActionMenu } from '@models/entities/permission.action.menu'
import { OfficeSysUser } from '@models/entities/system.user'
import { OfficeOrgChart } from '@models/entities'
import { In } from 'typeorm'
import { OfficeSysUserResponse } from './permission.response'

@Resolver()
export class OfficePermissionResolver {
    constructor(
        private readonly permissionService: PermissionService,

        @Inject(forwardRef(() => BusinessRoleService))
        private readonly businessRoleService: BusinessRoleService,

        @Inject(forwardRef(() => IAMPolicyActionService))
        private readonly policyActionService: IAMPolicyActionService
    ) { }

    @Query(() => BusinessRoleResponse, { name: 'officePermissionBusinessRoleGetList' })
    // @SetMetadata(ServiceKeys.Action, [ServiceActions.SystemUserManagement, ServiceActions.SystemUserView])
    // @SetMetadata(ServiceKeys.BusinessRole, [BusinessRoleCodes.ADMINISTRATOR])
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async businessRoleList(
        @Args('filter', { nullable: true }) filter: PermissionBusinessRoleFilter,
        @BearerAccessToken() token: string
    ): Promise<BusinessRoleResponse> {
        // if (filter.page) filter.page -= 1
        return await this.businessRoleService.getList(token, filter)
    }

    @Query(() => PolicyActionResponse, { name: 'officePermissionActionGetList' })
    // @SetMetadata(ServiceKeys.Action, [ServiceActions.SystemUserManagement, ServiceActions.SystemUserView])
    // @SetMetadata(ServiceKeys.BusinessRole, [BusinessRoleCodes.ADMINISTRATOR])
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async actionList(
        @BearerAccessToken() token: string
    ): Promise<PolicyActionResponse> {
        const response: PolicyActionResponse = await this.policyActionService.list(
            token,
            {
                serviceId: process.env.SERVICE_ID,
                effectId: process.env.ALLOW_EFFECT_ID
            }
        )

        const actions = response.actions.filter(a => !['office.sysuser.management.*', 'office.permission.management.*'].includes(a.code))

        return {
            total: actions.length,
            count: actions.length,
            actions: actions
        }
    }

    @Mutation(() => BusinessRole, { name: 'officeBusinessRoleCreate' })
    // @SetMetadata(ServiceKeys.Action, [ServiceActions.SystemUserManagement, ServiceActions.SystemUserView])
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async businessRoleCreate(
        @Args('arguments', { nullable: false }) args: BusinessRoleCreateArgs,
        @OrganizationId() organizationId: string,
        @BearerAccessToken() token: string
    ): Promise<BusinessRole> {
        const totalRoles = await this.businessRoleService.getTotalList(token)

        const roleCode = `${(process.env.SERVICE_CODE as string).toUpperCase()}_ROLE${totalRoles && totalRoles.total ? `_00${totalRoles.total}` : ''}`

        const params = {
            organizationId: organizationId,
            name: args.name,
            code: roleCode,
            // typeCode: 0, //CMS - 0, Mobile - 1, Fixed - 2
            type: 'CMS',
            description: args.description,
            policyArgs: [{
                serviceId: process.env.SERVICE_ID,
                effectId: process.env.ALLOW_EFFECT_ID,
                actionIds: args.actionIds
            }],
            menuIds: null
        }

        const uniqueMenuIds = await OfficePermissionActionMenu
            .createQueryBuilder('permission_action_menu')
            .select('DISTINCT(permission_action_menu.menuId)', 'menuId')
            .where('permission_action_menu.actionId IN (:...actionIds)', { actionIds: args.actionIds.length > 0 ? args.actionIds : [''] })
            .getRawMany();
        console.log("uniqueMenuIds: ", uniqueMenuIds.map(item => item.menuId))
        params.menuIds = uniqueMenuIds.map(item => item.menuId)
        if (args.actionIds.includes(process.env.APP_USER_MANAGEMENT_ACTION_ID) || args.actionIds.includes(process.env.SYSTEM_USER_MANAGEMENT_ACTION_ID)) {
            params.policyArgs.push({
                serviceId: process.env.IAM_SERVICE_ID,
                effectId: process.env.ALLOW_EFFECT_ID,
                actionIds: [
                    process.env.IDENTITY_ACTION_ID,
                    process.env.ACCESS_ACTION_ID,
                    process.env.ORGANITZATION_ACTION_ID,
                    process.env.BUSINESSROLE_ACTION_ID,
                ]
            })
        }

        return await this.businessRoleService.create(token, params)
    }

    @Mutation(() => BusinessRole, { name: 'officeBusinessRoleUpdate' })
    // @SetMetadata(ServiceKeys.Action, [ServiceActions.SystemUserManagement, ServiceActions.SystemUserView])
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async businessRoleUpdate(
        @Args('arguments', { nullable: false }) args: BusinessRoleUpdateArgs,
        @OrganizationId() organizationId: string,
        @BearerAccessToken() token: string
    ): Promise<BusinessRole> {
        let { data, error } = await this.businessRoleService.findById(token, args.businessRoleId)
        if (!data || error) {
            throw error ? error : OfficeError.BusinessRoleNotExist
        }

        // const { data: data2, error: error2 } = await this.businessRoleService.findByName(token, args.name)
        // if ((data2 && data2.id !== args.businessRoleId) || error2) {
        //     throw error ? error : OfficeError.BusinessRoleIsExist
        // }

        const params = {
            businessRoleId: args.businessRoleId,
            name: args.name,
            description: args.description,
            organizationId: organizationId,
            policyArgs: [{
                serviceId: process.env.SERVICE_ID,
                effectId: process.env.ALLOW_EFFECT_ID,
                actionIds: args.actionIds
            }],
            menuIds: null
        }

        // if (data.code === BusinessRoleCodes.ADMINISTRATOR) {
        //     params.policyArgs.push({
        //         serviceId: process.env.IAM_SERVICE_ID,
        //         effectId: process.env.ALLOW_EFFECT_ID,
        //         actionIds: [
        //             process.env.IDENTITY_ACTION_ID,
        //             process.env.ACCESS_ACTION_ID,
        //             process.env.ORGANITZATION_ACTION_ID,
        //             process.env.BUSINESSROLE_ACTION_ID,
        //         ]
        //     })
        // } else {
        //     const uniqueMenuIds = await OfficePermissionActionMenu
        //         .createQueryBuilder('permission_action_menu')
        //         .select('DISTINCT(permission_action_menu.menuId)', 'menuId')
        //         .where('permission_action_menu.actionId IN (:...actionIds)', { actionIds: args.actionIds.length > 0 ? args.actionIds : [''] })
        //         .getRawMany();
        //     console.log("uniqueMenuIds: ", uniqueMenuIds.map(item => item.menuId))
        //     params.menuIds = uniqueMenuIds.map(item => item.menuId)
        //     if (args.actionIds.includes(process.env.APP_USER_MANAGEMENT_ACTION_ID) || args.actionIds.includes(process.env.SYSTEM_USER_MANAGEMENT_ACTION_ID)) {
        //         params.policyArgs.push({
        //             serviceId: process.env.IAM_SERVICE_ID,
        //             effectId: process.env.ALLOW_EFFECT_ID,
        //             actionIds: [
        //                 process.env.IDENTITY_ACTION_ID,
        //                 process.env.ACCESS_ACTION_ID,
        //                 process.env.ORGANITZATION_ACTION_ID,
        //                 process.env.BUSINESSROLE_ACTION_ID,
        //             ]
        //         })
        //     }
        // }

        const uniqueMenuIds = await OfficePermissionActionMenu
            .createQueryBuilder('permission_action_menu')
            .select('DISTINCT(permission_action_menu.menuId)', 'menuId')
            .where('permission_action_menu.actionId IN (:...actionIds)', { actionIds: args.actionIds.length > 0 ? args.actionIds : [''] })
            .getRawMany();
        console.log("uniqueMenuIds: ", uniqueMenuIds.map(item => item.menuId))
        params.menuIds = uniqueMenuIds.map(item => item.menuId)
        if (
            // args.actionIds.includes(process.env.SYSTEM_USER_VIEW_ACTION_ID) ||
            // args.actionIds.includes(process.env.SYSTEM_USER_CREATE_ACTION_ID) ||
            // args.actionIds.includes(process.env.SYSTEM_USER_UPDATE_ACTION_ID) ||
            // args.actionIds.includes(process.env.SYSTEM_USER_DELETE_ACTION_ID) ||
            // args.actionIds.includes(process.env.PERMISSION_VIEW_ACTION_ID) ||
            // args.actionIds.includes(process.env.PERMISSION_CREATE_ACTION_ID) ||
            // args.actionIds.includes(process.env.PERMISSION_UPDATE_ACTION_ID) ||
            // args.actionIds.includes(process.env.PERMISSION_DELETE_ACTION_ID)
            data.code === BusinessRoleCodes.ADMINISTRATOR
        ) {
            params.policyArgs.push({
                serviceId: process.env.IAM_SERVICE_ID,
                effectId: process.env.ALLOW_EFFECT_ID,
                actionIds: [
                    process.env.IDENTITY_ACTION_ID,
                    process.env.ACCESS_ACTION_ID,
                    process.env.ORGANITZATION_ACTION_ID,
                    process.env.BUSINESSROLE_ACTION_ID,
                ]
            })
            params.menuIds.push(
                process.env.SYSTEM_MANAGEMENT_ACCOUNT_MENU_ID,
                process.env.SYSTEM_MANAGEMENT_PERMISSION_MENU_ID
            )
        }

        return await this.businessRoleService.update(token, params)
    }

    @Mutation(() => OfficeSysUser, { name: 'officeSysUserCreate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async sysUserCreate(
        @Args('arguments', { nullable: false }) args: AddSysUserArgs,
        @BearerAccessToken() token: string,
        @RequesterId() requesterId: string,
    ): Promise<OfficeSysUser> {
        if (args.email) {
            const exist = await OfficeSysUser.findOne({ where: { email: args.email } })
            if (exist) {
                throw OfficeError.SysUserWithEmailExisted
            }
        }

        if (args.code) {
            const existedCode = await OfficeSysUser.findOne({ where: { code: args.code } })
            if (existedCode) throw OfficeError.SysUserWithCodeExisted
        }

        if (args.businessRoleId) {
            const businessRole = await this.businessRoleService.findById(
                token,
                args.businessRoleId
            )
            if (!businessRole) {
                throw OfficeError.BusinessRoleNotExist
            }
        }

        return await this.permissionService.sysUserCreate(
            token,
            requesterId,
            args
        )
    }

    @Mutation(() => OfficeSysUser, { name: 'officeSysUserUpdate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async sysUserUpdate(
        @Args('arguments', { nullable: false }) args: EditSysUserArgs,
        @BearerAccessToken() token: string,
        @RequesterId() requesterId: string,
    ): Promise<OfficeSysUser> {
        const existedUser = await OfficeSysUser.findOne({ where: { id: args.id } })
        if (!existedUser) {
            throw OfficeError.SysUserNotExisted
        }

        if (args.code && args.code !== existedUser.code) {
            const existedCode = await OfficeSysUser.findOne({ where: { code: args.code } })
            if (existedCode) throw OfficeError.SysUserWithCodeExisted
        }

        return await this.permissionService.sysUserUpdate(
            token,
            requesterId,
            existedUser,
            args
        )
    }

    @Query(_return => OfficeSysUserResponse, { name: "officeSysUserGetList" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async officeGetSysUsers(
        @Args("filter", { nullable: true }) filter: SysUserFilter
    ): Promise<OfficeSysUserResponse> {
        const [list, count] = await this.permissionService.sysUserGetList(filter)

        return {
            total: count,
            count: list.length,
            sysUsers: list
        }
    }
}
