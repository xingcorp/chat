import { forwardRef, Inject, Injectable } from '@nestjs/common'
import { AccessService } from '../../../core/iam/access/access.service'
import { AddSysUserArgs, EditSysUserArgs, SysUserFilter } from './permission.args'
import { OfficeSysUser } from '@models/entities/system.user'
import { IdentityService } from 'src/modules/core/iam/identity/identity.service'
import { BusinessRoleService } from 'src/modules/core/iam/organization/business.role/business.role.service'
import { OfficeOrgChart } from '@models/entities'
import { Brackets, In } from 'typeorm'
import { OfficeError } from '@common/office.error'

@Injectable()
export class PermissionService {
    constructor(
        @Inject(forwardRef(() => IdentityService))
        private readonly identityService: IdentityService,

        @Inject(forwardRef(() => BusinessRoleService))
        private readonly businessRoleService: BusinessRoleService,

        @Inject(forwardRef(() => AccessService))
        private readonly accessService: AccessService
    ) { }

    public async sysUserCreate(
        token: string,
        requesterId: string,
        args: AddSysUserArgs
    ): Promise<OfficeSysUser> {
        let departments: OfficeOrgChart[] = []
        if (args.orgChartIds) {
            departments = await OfficeOrgChart.find({ where: { id: In(args.orgChartIds) } })
            if (departments.length === 0) {
                throw OfficeError.OrgChartNotFound
            }
        }

        const { data, error } = await this.identityService.sysUserCreate(
            token,
            args.fullname,
            args.email,
            '123456',
            null, null, null, null
        )

        if (error || !data || !data.id) { throw error }

        const registerBR = await this.businessRoleService.addUsers(token, args.businessRoleId, [data.id], true)

        if (registerBR.error) { throw registerBR.error }

        const sysUser = OfficeSysUser.create({
            id: data.id,
            businessRoleId: args.businessRoleId,
            code: args.code,
            email: args.email,
            fullname: args.fullname,
            iamUserId: data.id,
            orgChartIds: departments.map(d => d.id),
            createdBy: requesterId,
            updatedBy: requesterId
        })

        return await sysUser.save()
    }

    public async sysUserUpdate(
        token: string,
        requesterId: string,
        sysUser: OfficeSysUser,
        args: EditSysUserArgs
    ): Promise<OfficeSysUser> {
        const { data, error } = await this.identityService.sysUserUpdate(
            token,
            sysUser.iamUserId,
            args.fullname,
            null, null, null, null
        )

        if (error || !data || !data.id) { throw error }

        if (args.businessRoleId) {
            const targetRole = await this.businessRoleService.findById(token, args.businessRoleId)
            if (!targetRole || targetRole.error || !targetRole.data) {
                throw OfficeError.BusinessRoleNotExist
            }

            const registerBR = await this.businessRoleService.addUsers(token, args.businessRoleId, [sysUser.iamUserId], true)
            if (registerBR.error) { throw registerBR.error }

            sysUser.businessRoleId = args.businessRoleId
        }

        if (args.status) sysUser.status = args.status
        if (args.fullname) sysUser.fullname = args.fullname
        if (args.code) sysUser.code = args.code
        if (args.orgChartIds && args.orgChartIds.length > 0) {
            const departments = await OfficeOrgChart.find({ where: { id: In(args.orgChartIds) } })
            if (departments.length === 0) {
                throw OfficeError.OrgChartNotFound
            }

            sysUser.orgChartIds = departments.map(d => d.id)
        }

        sysUser.updatedBy = requesterId
        return await sysUser.save()
    }

    public async sysUserGetList(filter: SysUserFilter) {
        filter.size = filter.size ? filter.size : 20
        filter.page = filter.page ? filter.page : 0

        let query = OfficeSysUser.createQueryBuilder('su')
            .where({})
            .take(filter.size)
            .skip(filter.page * filter.size)
            .orderBy('su.createdAt', 'DESC')

        if (filter && filter.status) {
            query = query.andWhere({ status: filter.status })
        }

        if (filter && filter.orgChartId) {
            query = query.andWhere(':orgChartId = ANY(su.orgChartIds)', { orgChartId: filter.orgChartId })
        }

        if (filter && filter.keyword) {
            query = query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(su.fullname)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                    .orWhere(`unaccent(LOWER(su.code)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                    .orWhere(`unaccent(LOWER(su.email)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
            }))
        }

        return query.getManyAndCount()
    }
}
