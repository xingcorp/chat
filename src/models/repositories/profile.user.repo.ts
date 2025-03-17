import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, ILike, In, IsNull, MoreThanOrEqual, Not, Repository } from "typeorm";
import { OfficeApproval, OfficeOrgChart, OfficeTitle, OfficeUser, UserDepartment } from "@models/entities";
import { ChatConversationType } from "@models/entities/chat/conversation.chat";
import { AnalysisNumberOfUserUsedAppFilter } from "@modules/graphql/management/employee/employee.args";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { RequestContext } from "@common/context/request.context";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import { UserOrgChartFilter } from "@modules/graphql/management/orgchart/orgchart.args";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";

@Injectable()
export class OfficeUserRepo extends Repository<OfficeUser> {
    constructor(
        private dataSource: DataSource,
        private readonly redisService: RedisService,
    ) {
        super(OfficeUser, dataSource.createEntityManager());
    }

    async getPublicProfileUser(userId: string): Promise<OfficeUser> {
        let cacheProfile = await this.redisService.get(RedisKey.UserPublicProfile(userId));
        if (!cacheProfile) {
            const user = await OfficeUser.findOne({
                where: { id: userId },
                select: ["id", "code", "imageUrls", "fullname", "email"]
            })
            cacheProfile = JSON.stringify(user)
            await this.redisService.setWithTtl(RedisKey.UserPublicProfile(userId), cacheProfile, 15 * 60)
        }
        return JSON.parse(cacheProfile)
    }

    async getDepartmentsManagementById(id: string) {
        return OfficeOrgChart.findBy({
            approverId: id
        })
    }

    async haveDirectBetween(receiverId: string, senderId: string) {
        return !!(await this.findOneBy({
            id: senderId,
            conversations: {
                conversation: {
                    type: ChatConversationType.Direct,
                    members: {
                        user: {
                            id: receiverId
                        }
                    }
                }
            }
        }))
    }

    async getById(id: string) {
        if (!id) return null

        return this.findOneBy({ id })
    }

    async analysisNumberOfUserUsedApp(filter: AnalysisNumberOfUserUsedAppFilter) {
        const query = this.createQueryBuilder('qb')
            .leftJoinAndMapMany('qb.departments', UserDepartment, 'd', 'd."userId" = qb.id::text')
            .leftJoinAndMapOne('qb.department', OfficeOrgChart, 'dd', 'dd.id::text = d."departmentId"::text')
            .where({
                lastLoginAt: Not(IsNull())
            })
            .orderBy('qb.lastLoginAt', 'DESC')

        if (filter && filter.latestLoginTime) {
            query.andWhere({
                lastLoginAt: MoreThanOrEqual(new Date(filter.latestLoginTime))
            })
        }

        if (filter && filter.orgChardId) {
            query.andWhere('dd.path LIKE :orgId', { orgId: `%${filter.orgChardId.trim()}%` })
        }

        const [records, total] = await query.getManyAndCount()

        return {
            total,
            records
        }
    }

    async getDepartmentIdBy(byWhere: object) {
        const user = await this.createQueryBuilder('qb')
            .leftJoinAndMapMany('qb.departments', UserDepartment, 'd', 'd."userId" = qb.id::text')
            .leftJoinAndMapOne('qb.department', OfficeOrgChart, 'dd', 'dd.id::text = d."departmentId"::text')
            .where(byWhere)
            .getOne()

        if (!user) return null

        return user['department']['id']
    }

    async getFullUserOfOrg(listDepartmentIds: string[], filter?: any) {
        const query = this.createQueryBuilder('qb')
            .leftJoinAndMapMany('qb.departments', UserDepartment, 'd', 'd."userId" = qb.id::text')
            .where('d."departmentId" IN (:...oogIds)', { oogIds: listDepartmentIds })


        if (filter) await this.queryFilter(query, filter)

        return query.getManyAndCount()
    }

    private async queryFilter(query: SelectQueryBuilder<OfficeUser>, filter: any) {
        filter.size = filter.size ? filter.size : 20 //1
        filter.page = filter.page ? (filter.page - 1) : 0

        query.take(filter.size)
            .skip(filter.page * filter.size)

        if (filter && filter.keyword) {
            query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(qb.fullname)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                    .orWhere(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                    .orWhere(`unaccent(LOWER(qb.phone)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
            }))
        }

        if (filter && filter.onlyActive) {
            query.andWhere(`qb.status = :active`, { active: ObjectStatus.Active })
        }

        if (filter && filter.notResigned) {
            query.andWhere(new Brackets(db => {
                db.where("qb.resigned = :notResigned", { notResigned: false })
                    .orWhere(new Brackets(db => {
                        db.where("qb.resigned = :resigned", { resigned: true })
                            .andWhere(`qb."leaveOn" >= :dateNow`, { dateNow: new Date().toISOString() })
                    }))
            }))
        }
    }

    async getManyByIds(ids: string[]) {
        return this.find({
            where: {
                id: In(ids)
            }
        })
    }

    async listIamIdById(ids: string[]) {
        const users = await this.find({
            select: ['iamUserId'],
            where: {
                id: In(ids)
            }
        })

        return users.map(i => i.iamUserId)
    }

    async listPhoneById(ids: string[]) {
        const users = await this.find({
            select: ['phone'],
            where: {
                id: In(ids)
            }
        })

        return users.map(i => i.phone)
    }

    async listFieldById(ids: string[], field: string) {
        const users = await this.find({
            where: {
                id: In(ids)
            }
        })

        return users.map(i => i[field])
    }

    async getUserInOrgManagementById(id: string) {
        const orgCharts = await RequestContext.getOrgCharts()

        return this.createQueryBuilder('qb')
            .leftJoinAndMapMany('qb.departments', UserDepartment, 'd', 'd."userId" = qb.id::text')
            .where({ id })
            .andWhere(`d."departmentId" IN (:...orgCharts)`, { orgCharts: orgCharts.map(i => i.id) })
            .getOne()
    }

    async getAllUserAllWayByIds(ids: string[]) {
        const where: any[] = [
            { id: In(ids) },
            { iamUserId: In(ids) },
        ]

        ids.map(id => where.push({ iamUserUsedIds: ILike(`%${id}%`) }))

        return this.find({ where })
    }

    async getUserAllWayById(id: string) {
        const where: any[] = [
            { id },
            { iamUserId: id },
            { iamUserUsedIds: ILike(`%${id}%`) }
        ]

        return this.findOne({ where })
    }

    async getAllUserIdsAllWayByIds(ids: string[]) {
        const users = await this.getAllUserAllWayByIds(ids)

        return users?.map(i => i.id)
    }

    async getByIds(userIds: string[]) {
        return this.getBy({
            id: In(userIds)
        })
    }

    async listBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .andWhere({
                id: In(await RequestContext.currentOrgDataUserIds())
            })
            .getOne()
    }

    async getBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .andWhere({
                id: In(await RequestContext.currentOrgDataUserIds())
            })
            .getOne()
    }

    async getManyBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getMany()
    }

    async getByWithoutUserById(where: any, userId: string) {
        if (!userId) return this.getBy(where)

        return this.createQueryBuilder()
            .where(where)
            .andWhere({
                id: Not(userId)
            })
            .andWhere({
                id: In(await RequestContext.currentOrgDataUserIds())
            })
            .getOne()
    }

    async getCurrentUser() {
        return this.findOneBy({
            id: await RequestContext.currentId()
        })
    }

    async listByIds(userIds: string[]) {
        return this.find({
            where: {
                id: In(userIds)
            }
        })
    }

    async getManyWithDepartmentByIds(ids: string[]) {
        if (!ids || !ids.length) return null

        return this.createQueryBuilder('qb')
            .leftJoinAndMapMany('qb.departments', UserDepartment, 'd', 'd."userId" = qb.id::text')
            .leftJoinAndMapOne('qb.department', OfficeOrgChart, 'department', 'department.id::text = d."departmentId"::text')
            .leftJoinAndMapOne('qb.title', OfficeTitle, 'title', 'title.id::text = d."titleId"::text')
            .where(`qb.id IN (:...ids)`, { ids })
            .getMany()
    }

    async getUserManagementDepartmentById(departmentId: string) {
        if (!departmentId) return null;

        const departmentBridge = await UserDepartment.findOneBy({
            departmentId
        })

        if (!departmentBridge) return null;

        return this.findOneBy({
            id: departmentBridge.userId
        })
    }

    async readApproval(approval: OfficeApproval) {
        const user = await this.getBy(
            { id: RequestContext.currentId() },
            ['approvalsRead']
        )

        if (!user) return

        user.approvalsRead = arrayConvertToDistinctAndNotNull([...(user?.approvalsRead ? user.approvalsRead : []), approval])

        await this.save(user)
        await user.reload()

        return user
    }

    async getAndCountWithFilter(filter: UserOrgChartFilter) {
        const query = this.createQueryBuilder('qb')

        await this.queryFilter(query, filter)

        return query.getManyAndCount()
    }
}