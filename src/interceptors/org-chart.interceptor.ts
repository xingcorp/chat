import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { GqlExecutionContext } from "@nestjs/graphql";
import { OfficeUserRepo } from "@repositories/profile.user.repo";
import { ApolloError } from "apollo-server-express";
import { OfficeOrgChartRepo } from "@repositories/office-org-chart.repo";
import { OfficeSysUserRepo } from "@repositories/office-sys-user.repo";
import { GetOrgChartKind, GetOrgChartType } from "@common/enum.common";
import { UserType } from "@core/middleware/guard/service.action";
import { In } from "typeorm";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";

const nullCount = [[], 0]

export const validateUserId = async (req: any) => {
    if (!req.requesterId) {
        throw new ApolloError('Không tìm thấy thông tin người dùng', '403')
    }
}

async function validateUserIdAndGetDepartmentId(req: any, self: any) {
    await validateUserId(req)

    const departmentId = await self.officeUserRepo.getDepartmentIdBy({iamUserId: req.requesterId})

    if (!departmentId) {
        throw new ApolloError('Không tìm thấy thông tin phòng ban', '403')
    }

    return departmentId
}

async function validateUserIdAndGetListSysDepartmentId(req: any, self: any) {
    await validateUserId(req)

    const sysUser = await self.officeSysUserRepo.findOneBy({id: req.requesterId})

    if (!sysUser) {
        throw new ApolloError('Thông tin người dùng không chính xác', '403')
    }

    return sysUser?.orgChartIds
}

async function validateUserIdAndGetListSysDepartmentIdCheckFullSys(req: any, _self: any) {
    await validateUserId(req)

    const sysUser = await _self.officeSysUserRepo.findOneBy({id: req.requesterId})

    if (!sysUser) {
        throw new ApolloError('Thông tin người dùng không chính xác', '403')
    }

    let orgChartIds = sysUser?.orgChartIds
    if (orgChartIds === null) {
        orgChartIds = _self.orgChartRepository.getAllIds()
    }

    return orgChartIds
}


async function getListOrgChartIds(orgIds: any, args: any, _self: any) {
    let getType = GetOrgChartType.Only
    if (args.filter && args.filter.orgType) getType = args.filter.orgType

    switch (getType) {
        case GetOrgChartType.All:
            return _self.orgChartRepository.getAllIdsOfOrgs(orgIds)
        case GetOrgChartType.WChild:
            return _self.orgChartRepository.getAllIdsCurrentAndChild(orgIds)
        case GetOrgChartType.WParent:
            return _self.orgChartRepository.getAllIdsCurrentAndParent(orgIds)
        case GetOrgChartType.Only:
        default:
            return orgIds
    }
}

@Injectable()
export class BaseOrgChartInterceptor implements NestInterceptor {

    protected filter = false

    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
    }

    intercept(context: ExecutionContext, next: CallHandler<any>): Observable<any> | Promise<Observable<any>> {
        return undefined;
    }
}

@Injectable()
export class BaseOrgChartSysInterceptor implements NestInterceptor {

    protected filter = false

    constructor(
        protected officeSysUserRepo: OfficeSysUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
    }

    intercept(context: ExecutionContext, next: CallHandler<any>): Observable<any> | Promise<Observable<any>> {
        return undefined;
    }
}

@Injectable()
export class BaseOrgChartAllInterceptor implements NestInterceptor {

    protected filter = false

    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected officeSysUserRepo: OfficeSysUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
    }

    intercept(context: ExecutionContext, next: CallHandler<any>): Observable<any> | Promise<Observable<any>> {
        return undefined;
    }
}

@Injectable()
export class OrgChartRootInterceptor implements NestInterceptor {

    constructor(
        private officeUserRepo: OfficeUserRepo,
        private orgChartRepository: OfficeOrgChartRepo,
    ) {
    }

    async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
        const {req} = GqlExecutionContext.create(context).getContext()

        await validateUserId(req)

        const departmentId = await this.officeUserRepo.getDepartmentIdBy({iamUserId: req.requesterId})
        req.orgRoot = await this.orgChartRepository.getRootOfDepartmentId(departmentId)

        return next.handle()
    }
}

@Injectable()
export class OrgChartFullInterceptor extends BaseOrgChartInterceptor{

    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeUserRepo, orgChartRepository)
    }

    async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
        const {req} = GqlExecutionContext.create(context).getContext()
        const args = GqlExecutionContext.create(context).getArgs();

        const departmentId = await validateUserIdAndGetDepartmentId(req, this)

        const rootId = await this.orgChartRepository.getRootIdOfDepartmentId(departmentId)

        if (this.filter) {
            args.filter = {
                ...args?.filter,
                size: 20
            }
        }

        if (args?.filter && args?.filter?.haveNoManager) {
            req.listDepartmentsOfOrg = await this.orgChartRepository.getAndCountFullOfRoot(rootId, this.filter ? args?.filter : null)
        } else {
            req.listDepartmentsOfOrg = await this.orgChartRepository.getFullHaveManagerOfRoot(rootId, this.filter ? args?.filter : null)
        }

        return next.handle()
    }
}

@Injectable()
export class OrgChartFullWithFilterInterceptor extends OrgChartFullInterceptor{
    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeUserRepo, orgChartRepository)
        this.filter = true
    }
}

@Injectable()
export class OrgChartSysFullInterceptor extends BaseOrgChartSysInterceptor{

    constructor(
        protected officeSysUserRepo: OfficeSysUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeSysUserRepo, orgChartRepository)
    }

    async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
        const {req} = GqlExecutionContext.create(context).getContext()
        const args = GqlExecutionContext.create(context).getArgs();

        let orgIds = await validateUserIdAndGetListSysDepartmentId(req, this)
        if (this.filter) {
            args.filter = {
                ...args?.filter,
                size: 20
            }
        }

        orgIds = await getListOrgChartIds(orgIds, args, this)

        if (args?.filter && args?.filter?.haveNoManager) {
            if (orgIds && !orgIds?.filter(i => i.approverId).length) {
                req.listDepartmentsOfOrg = [null, 0]
            } else {
                req.listDepartmentsOfOrg = await this.orgChartRepository.getFullOfList(orgIds?.filter(i => !!i.approverId), this.filter ? args?.filter : null)
            }
        } else {
            req.listDepartmentsOfOrg = await this.orgChartRepository.getFullOfList(orgIds, this.filter ? args?.filter : null)
        }

        return next.handle()
    }
}

@Injectable()
export class OrgChartFullSysWithFilterInterceptor extends OrgChartSysFullInterceptor{
    constructor(
        protected officeSysUserRepo: OfficeSysUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeSysUserRepo, orgChartRepository)
        this.filter = true
    }
}

@Injectable()
export class OrgChartUserInterceptor extends BaseOrgChartInterceptor{
    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeUserRepo, orgChartRepository)
    }

    async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
        const {req} = GqlExecutionContext.create(context).getContext()
        const args = GqlExecutionContext.create(context).getArgs();

        const departmentId = await validateUserIdAndGetDepartmentId(req, this)

        const rootId = await this.orgChartRepository.getRootIdOfDepartmentId(departmentId)
        const listDepartmentIds = await this.orgChartRepository.getFullIdOfRoot(rootId)

        req.listUsersOfOrg = await this.officeUserRepo.getFullUserOfOrg(listDepartmentIds, this.filter ? args?.filter : null)

        return next.handle()
    }
}


@Injectable()
export class OrgChartUserWithFilterInterceptor extends OrgChartUserInterceptor{

    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeUserRepo, orgChartRepository)
        this.filter = true
    }
}

@Injectable()
export class OrgChartUserSysInterceptor extends BaseOrgChartAllInterceptor{

    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected officeSysUserRepo: OfficeSysUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeUserRepo, officeSysUserRepo, orgChartRepository)
    }


    async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
        const {req} = GqlExecutionContext.create(context).getContext()
        const args = GqlExecutionContext.create(context).getArgs();

        let orgIds = await validateUserIdAndGetListSysDepartmentId(req, this)
        orgIds = await getListOrgChartIds(orgIds, args, this)
        if (this.filter) {
            args.filter = {
                ...args?.filter,
                size: 20
            }
        }

        req.listUsersOfOrg = await this.officeUserRepo.getFullUserOfOrg(orgIds, this.filter ? args?.filter : null)

        return next.handle()
    }
}

@Injectable()
export class OrgChartUserSysWithFilterInterceptor extends OrgChartUserSysInterceptor{

    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected officeSysUserRepo: OfficeSysUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeUserRepo, officeSysUserRepo, orgChartRepository)
        this.filter = true
    }
}

@Injectable()
export class FixedDataOrgChartInterceptor extends BaseOrgChartAllInterceptor{

    protected kind = [GetOrgChartKind.OrgChart]
    protected type = [GetOrgChartType.Only]

    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected officeSysUserRepo: OfficeSysUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeUserRepo, officeSysUserRepo, orgChartRepository)
    }

    async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
        const {req} = GqlExecutionContext.create(context).getContext()
        const args = GqlExecutionContext.create(context).getArgs();

        if (!req.requesterId) {
            throw new ApolloError('Không tìm thấy thông tin người dùng', '403')
        }

        const userType = req.requesterInfo?.user?.type
        let orgIds = []

        switch (userType) {
            case UserType.NORMAL_USER:
                orgIds = [await validateUserIdAndGetDepartmentId(req, this)]
                break;
            case UserType.SYSTEM_USER:
                orgIds = await validateUserIdAndGetListSysDepartmentIdCheckFullSys(req, this)
                break;
        }

        const root = await this.orgChartRepository.getRootOfDepartmentId(orgIds[0])
        req.rootOrg = root
        req.rootOrgId = root?.id
        req.listOrgIdOnly = orgIds

        await this.getRootsData(orgIds, req)

        if (this.kind.includes(GetOrgChartKind.OrgChart)) {
            await this.setFixedDataOrgChart(req)
        }

        if (this.kind.includes(GetOrgChartKind.User)) {
            await this.setFixedDataOrgChartUser(req)
        }

        if (args.filter && args.filter?.orgChartIds?.length) {
            await this.setCustomDataOrgChartUser(req, args.filter?.orgChartIds)
        }

        return next.handle()
    }

    private async getRootsData(orgIds: string[], req: any) {
        const departments = await this.orgChartRepository.findBy({id: In(orgIds)})

        if (!departments.length) return null

        const ids = arrayConvertToDistinctAndNotNull(departments.map(department => department.path ? department.path.split('/')[1] : department.id))

        const roots = await this.orgChartRepository.findBy({id: In(ids)})

        req.rootOrgs = roots
        req.rootOrgIds = roots?.map(i => i?.id)
    }

    private async setFixedDataOrgChart(req: any) {
        if (this.type.includes(GetOrgChartType.All)) {
            req.listOrgAll = await this.orgChartRepository.getFullOfRootByRootIds(req.rootOrgIds)
            req.listOrgIdAll = req.listOrgAll.map(i => i?.id)
        }
        if (this.type.includes(GetOrgChartType.WParent)) {
            req.listOrgWParent = req?.listOrgIdOnly?.length ? await this.orgChartRepository.getAllCurrentAndParent(req.listOrgIdOnly) : nullCount
            req.listOrgIdWParent = req.listOrgWParent.map(i => i?.id)
        }
        if (this.type.includes(GetOrgChartType.WChild)) {
            req.listOrgWChild = req?.listOrgIdOnly?.length ? await this.orgChartRepository.getAllCurrentAndChild(req.listOrgIdOnly) : nullCount
            req.listOrgIdWChild = req.listOrgWChild.map(i => i?.id)
        }
        if (this.type.includes(GetOrgChartType.WParent) && this.type.includes(GetOrgChartType.WChild)) {
            req.listOrgWParentAndChild = arrayConvertToDistinctAndNotNull([...req.listOrgWParent, ...req.listOrgWChild])
            req.listOrgIdWParentAndChild = req.listOrgWParentAndChild.map(i => i?.id)
        }
    }

    private async setFixedDataOrgChartUser(req: any) {
        let orgIds = []
        await this.setFixedDataOrgChart(req)
        if (this.type.includes(GetOrgChartType.All)) {
            orgIds = req.listOrgIdAll
        }
        if (this.type.includes(GetOrgChartType.WParent)) {
            orgIds = req.listOrgIdWParent
        }
        if (this.type.includes(GetOrgChartType.WChild)) {
            orgIds = req.listOrgIdWChild
        }
        if (this.type.includes(GetOrgChartType.WParent) && this.type.includes(GetOrgChartType.WChild)) {
            orgIds = req.listOrgIdWChild
        }

        req.listUsersOfOrg = orgIds.length ? await this.officeUserRepo.getFullUserOfOrg(orgIds, null) : nullCount
    }

    private async setCustomDataOrgChartUser(req: any, orgIds: string[]) {
        req.listUsersOfOrgCustom = await this.officeUserRepo.getFullUserOfOrg(orgIds, null)
    }

    private async setCustomDataOrgChartOfUser(req: any, id: any) {
        req.orgOfUserCustom = await this.officeUserRepo.getDepartmentIdBy({id})
    }
}

@Injectable()
export class FixedDataOrgChartUserWChildInterceptor extends FixedDataOrgChartInterceptor{

    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected officeSysUserRepo: OfficeSysUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeUserRepo, officeSysUserRepo, orgChartRepository)

        this.kind = [GetOrgChartKind.User]
        this.type = [GetOrgChartType.WChild]
    }
}

@Injectable()
export class FixedDataOrgChartUserAllInterceptor extends FixedDataOrgChartInterceptor{

    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected officeSysUserRepo: OfficeSysUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeUserRepo, officeSysUserRepo, orgChartRepository)

        this.kind = [GetOrgChartKind.User]
        this.type = [GetOrgChartType.All]
    }
}

@Injectable()
export class FixedDataOrgChartUserAllAndWChildInterceptor extends FixedDataOrgChartInterceptor{

    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected officeSysUserRepo: OfficeSysUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeUserRepo, officeSysUserRepo, orgChartRepository)

        this.kind = [GetOrgChartKind.User]
        this.type = [GetOrgChartType.All, GetOrgChartType.WChild]
    }
}

@Injectable()
export class FixedDataOrgChartUserAllAndWithChildInterceptor extends FixedDataOrgChartInterceptor{

    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected officeSysUserRepo: OfficeSysUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeUserRepo, officeSysUserRepo, orgChartRepository)

        this.kind = [GetOrgChartKind.User]
        this.type = [GetOrgChartType.All, GetOrgChartType.WChild]
    }
}

@Injectable()
export class FixedDataOrgChartUserWithParentAndChildInterceptor extends FixedDataOrgChartInterceptor{

    constructor(
        protected officeUserRepo: OfficeUserRepo,
        protected officeSysUserRepo: OfficeSysUserRepo,
        protected orgChartRepository: OfficeOrgChartRepo,
    ) {
        super(officeUserRepo, officeSysUserRepo, orgChartRepository)

        this.kind = [GetOrgChartKind.User]
        this.type = [GetOrgChartType.WParent, GetOrgChartType.WChild]
    }
}
