import * as cls from 'cls-hooked';
import { IncomingMessage } from "http";
import { generateNoneDashUUID } from "@core/common/uuid";
import { UserType } from "@core/middleware/guard/service.action";
import {
    OfficeOrgChart, OfficeSysUser,
    OfficeUser,
    UserDepartment
} from "@models/entities";
import { ApolloError } from "apollo-server-express";
import { In } from "typeorm";
import { ValidateDataType } from "@interceptors/validate-data-type.interceptor";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";

export class RequestContext {

    public static nsid = generateNoneDashUUID();
    public readonly id: Number;
    public request: IncomingMessage;
    public response: Response;

    constructor(request: IncomingMessage, response: Response) {
        this.id = Math.random();
        this.request = request;
        this.response = response;
    }

    public static currentRequestContext(): RequestContext {
        const session = cls.getNamespace(RequestContext.nsid);
        if (session && session.active) {
            return session.get(RequestContext.name);
        }

        return null;
    }

    public static currentRequest(): IncomingMessage {
        let requestContext = RequestContext.currentRequestContext();

        if (requestContext) {
            return requestContext.request;
        }

        return null;
    }

    public static requestId(): string {
        let ctx = RequestContext.currentRequestContext();
        if (!ctx) return null

        const req = ctx.request as any

        return req.requestId
    }

    public static currentRequestId(): string {
        let ctx = RequestContext.currentRequestContext();
        if (!ctx) return null

        const req = ctx.request as any

        if (!req.requesterId) {
            throw new ApolloError('Không tìm thấy thông tin người dùng', '403')
        }

        return req.requesterId
    }

    static currentOfficeRequesterId(): string {
        let ctx = RequestContext.currentRequestContext();
        const req = ctx.request as any

        if (!req.officeRequesterId) {
            throw new ApolloError('Không tìm thấy thông tin người dùng', '403')
        }

        return req.officeRequesterId
    }


    public static currentToken(): string {
        let ctx = RequestContext.currentRequestContext();

        if (ctx?.request?.headers['authorization']) {
            return ctx.request.headers['authorization'];
        }

        return null;
    }

    public static currentSysId(): string {
        let ctx = RequestContext.currentRequestContext();
        const req = ctx.request as any

        switch (req.requesterInfo?.user?.type) {
            case UserType.SYSTEM_USER:
                return req?.requesterId
            default:
                return null
        }
    }

    static currentId(): string {
        let ctx = RequestContext.currentRequestContext();
        const req = ctx.request as any
        switch (req.requesterInfo?.user?.type) {
            case UserType.SYSTEM_USER:
                return req?.requesterId
            case UserType.NORMAL_USER:
                // const officeUser = await OfficeUser.findOne({
                //     where: { iamUserId: req.requesterId }
                // })
                // return officeUser?.id
                return req.officeRequesterId
            default:
                return null
        }
    }

    public static async currentUser(): Promise<OfficeUser> {
        let ctx = RequestContext.currentRequestContext();
        const req = ctx.request as any

        switch (req.requesterInfo?.user?.type) {
            case UserType.NORMAL_USER:
                return req.officeUser
            case UserType.SYSTEM_USER:
                const sys = await OfficeSysUser.findOne({
                    relations: ['user'],
                    where: { id: req.requesterId }
                })

                return sys.user
            default:
                return null
        }
    }

    public static async currentAdmin(): Promise<OfficeSysUser> {
        let ctx = RequestContext.currentRequestContext();
        const req = ctx.request as any

        switch (req.requesterInfo?.user?.type) {
            case UserType.SYSTEM_USER:
                return OfficeSysUser.findOne({
                    where: { id: req.requesterId }
                })
            default:
                return null
        }
    }

    public static async getOrgCharts(): Promise<OfficeOrgChart[]> {
        let ctx = RequestContext.currentRequestContext();
        const req = ctx.request as any

        switch (req.requesterInfo?.user?.type) {
            case UserType.NORMAL_USER:
                return [await this.getOrgChartUser(req.requesterId)]

            case UserType.SYSTEM_USER:
                return this.getOrgChartSys(req.requesterId)

            default:
                return null
        }
    }

    public static async getRootOrg(): Promise<OfficeOrgChart> {
        let ctx = RequestContext.currentRequestContext();
        const req = ctx.request as any

        switch (req.requesterInfo?.user?.type) {
            case UserType.NORMAL_USER:
                return this.getRootOrgUser(req.requesterId)

            case UserType.SYSTEM_USER:
                return this.getRootOrgSys(req.requesterId)

            default:
                return null
        }
    }

    public static async getRootOrgId(): Promise<string> {
        return (await this.getRootOrg())?.id
    }

    public static async getRootOrgs(): Promise<OfficeOrgChart[]> {
        let ctx = RequestContext.currentRequestContext();
        const req = ctx.request as any

        switch (req.requesterInfo?.user?.type) {
            case UserType.NORMAL_USER:
                return [await this.getRootOrgUser(req.requesterId)]

            case UserType.SYSTEM_USER:
                return this.getRootOrgsAdmin(req.requesterId)

            default:
                return null
        }
    }

    public static async getRootOrgIds(): Promise<string[]> {
        const orgs = await this.getRootOrgs()
        return orgs?.map(i => i?.id)
    }

    public static async getOnlyRootOrgId(): Promise<string> {
        const ids = await this.getRootOrgIds()
        return ids.length === 1 ? ids[0] : null
    }

    public static isNormalUser(): boolean {
        try {
            let ctx = RequestContext.currentRequestContext();
            const req = ctx.request as any

            return req.requesterInfo?.user?.type === UserType.NORMAL_USER
        } catch {
            return false
        }
    }

    public static isSysUser(): boolean {
        let ctx = RequestContext.currentRequestContext();
        const req = ctx.request as any

        return req.requesterInfo?.user?.type === UserType.SYSTEM_USER
    }

    private static async getRootOrgUser(requesterId: string) {
        const officeUser = await OfficeUser.findOne({
            where: { iamUserId: requesterId }
        })

        if (!officeUser) {
            throw new ApolloError('Không tìm thấy thông tin nhân viên', '404')
        }

        const userDepartment = await UserDepartment.findOne({
            where: {
                userId: officeUser.id
            },
            order: {
                createdAt: 'DESC'
            }
        })
        const department = await OfficeOrgChart.findOneBy({ id: userDepartment.departmentId })

        if (!department) return null

        const id = department.path ? department.path.split('/')[1] : department.id

        return OfficeOrgChart.findOneBy({ id })
    }

    private static async getRootOrgsAdmin(requesterId: string) {
        const sysUser = await OfficeSysUser.findOne({
            where: { id: requesterId }
        })

        if (!sysUser) {
            throw new ApolloError('Không tìm thấy thông tin admin', '404')
        }

        if (!sysUser.orgChartIds) return null

        const departments = await OfficeOrgChart.findBy({ id: In(sysUser.orgChartIds) })

        if (!departments.length) return null

        const ids = arrayConvertToDistinctAndNotNull(departments.map(department => department.path ? department.path.split('/')[1] : department.id))

        return OfficeOrgChart.findBy({ id: In(ids) })
    }

    private static async getRootOrgSys(requesterId: string) {
        const sysUser = await OfficeSysUser.findOne({
            where: { id: requesterId }
        })

        if (!sysUser) {
            throw new ApolloError('Không tìm thấy thông tin admin', '404')
        }

        if (!sysUser.orgChartIds) return null

        const department = await OfficeOrgChart.findOneBy({ id: sysUser.orgChartIds[0] })

        if (!department) return null

        const id = department.path ? department.path.split('/')[1] : department.id

        return OfficeOrgChart.findOneBy({ id })
    }

    private static async getOrgChartUser(requesterId: string = RequestContext.currentRequestId()) {
        const officeUser = await OfficeUser.findOne({
            where: { iamUserId: requesterId }
        })

        if (!officeUser) {
            throw new ApolloError('Không tìm thấy thông tin nhân viên', '404')
        }

        const userDepartment = await UserDepartment.findOne({
            where: {
                userId: officeUser.id
            },
            order: {
                createdAt: 'DESC'
            }
        })
        return OfficeOrgChart.findOneBy({ id: userDepartment.departmentId })
    }

    private static async getOrgChartUserId(requesterId: string = RequestContext.currentRequestId()) {
        const department = await this.getOrgChartUser()
        return department.id
    }

    private static async getOrgChartSys(requesterId: string) {
        const sysUser = await OfficeSysUser.findOne({
            where: { id: requesterId }
        })

        if (!sysUser) {
            throw new ApolloError('Không tìm thấy thông tin admin', '404')
        }

        if (!sysUser.orgChartIds) return null

        return OfficeOrgChart.findBy({ id: In(sysUser.orgChartIds) })
    }

    /*Data add in interceptor*/
    public static currentListOrgIds(): any {
        let oogIds: string[]
        if (RequestContext.isNormalUser()) {
            oogIds = RequestContext.currentOrgData('listOrgIdAll') //ok
        } else {
            oogIds = RequestContext.currentOrgData('listOrgIdWChild')
        }

        return oogIds
    }

    public static async currentListDepartmentIds(): Promise<any> {
        let oogIds: string[]
        if (RequestContext.isNormalUser()) {
            oogIds = [await this.getOrgChartUserId()]
        } else {
            oogIds = RequestContext.currentOrgData('listOrgIdWChild')
        }

        return oogIds
    }

    public static currentOrgData(name: string): any {
        let ctx = RequestContext.currentRequestContext();
        const req = ctx.request as any

        return req?.[name]
    }

    public static async currentOrgDataUserIds(): Promise<string[]> {
        const admin = await this.currentAdmin()

        // if (!admin?.orgChartIds) return []

        let ctx = RequestContext.currentRequestContext();
        const req = ctx.request as any

        const res = req?.listUsersOfOrg

        if (!res) return []

        return res[0]?.map(i => i?.id)
    }

    public static currentValidateDataType(): ValidateDataType {
        let ctx = RequestContext.currentRequestContext();
        const req = ctx.request as any

        const res = req?.validateDataType

        if (!res) return ValidateDataType.Default

        return req?.validateDataType
    }

    public static isValidateDataTypeBulkUpsert(): boolean {
        return this.currentValidateDataType() === ValidateDataType.BulkUpsert
    }
}