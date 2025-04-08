import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, ILike, In, Repository } from "typeorm";
import { OfficeOrgChart, OfficeUser } from "@models/entities";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { RequestContext } from "@common/context/request.context";

@Injectable()
export class OfficeOrgChartRepo extends Repository<OfficeOrgChart> {
    constructor(private dataSource: DataSource) {
        super(OfficeOrgChart, dataSource.createEntityManager());
    }

    async getAllIds() {
        const all = await this.find()

        return all.map(i => i.id)
    }

    async getAllCurrentAndChild(ids: string[]) {
        const listCurrent = await this.createQueryBuilder('qb')
            .where(`qb.id IN (:...ids)`, {ids})
            .getMany()


        return this.createQueryBuilder('qb')
            .where({})
            .andWhere(new Brackets(db => {
                db.where({
                    path: ILike(`%${listCurrent[0].id}%`)
                })

                listCurrent.map(i => db.orWhere({
                    path: ILike(`%${i.id}%`)
                }))
            }))
            .getMany()
    }

    async getAllCurrentAndParent(ids: string[]) {
        const listCurrent = await this.createQueryBuilder('qb')
            .where(`qb.id IN (:...ids)`, {ids})
            .getMany()

        const listIds = listCurrent.map(item => item.path.substring(1).split('/')).flat()

        return this.createQueryBuilder('qb')
            .where(`qb.id IN (:...ids)`, {ids: listIds})
            .getMany()
    }

    async getAllIdsCurrentAndParent(ids: string[]) {
        const res = await this.getAllCurrentAndParent(ids)

        return res.map(item => item.id)
    }

    async getAllIdsCurrentAndChild(ids: string[]) {
        const res = await this.getAllCurrentAndChild(ids)

        return res.map(item => item.id)
    }

    async queryFilterBySysPermission(query: SelectQueryBuilder<any>, ids: string[], key: string = 'id') {
        const oogIds = await this.getAllIdsCurrentAndParent(ids)

        query.andWhere(`:key IN (:...oogIds)`, {key, oogIds})
    }

    async getCurrentAndLineParentAndAllChild(ids: string[]) {
        const listCurrent = await this.createQueryBuilder('qb')
            .where(`qb.id IN (:...ids)`, {ids})
            .getMany()

        const listParentIds = listCurrent.map(item => item.path.substring(1).split('/')).flat()
        const listChildIds = await this.getAllIdsCurrentAndChild(ids)

        return this.createQueryBuilder('qb')
            .where(`qb.id IN (:...ids)`, {ids: [...listParentIds, ...listChildIds]})
            .getMany()
    }

    async getIdsCurrentAndLineParentAndAllChild(ids: string[]) {
        const res = await this.getCurrentAndLineParentAndAllChild(ids)

        return res.map(item => item.id)
    }

    async getAllOfOrgs(ids: string[]) {
        const listCurrent = await this.createQueryBuilder('qb')
            .where(`qb.id IN (:...ids)`, {ids})
            .getMany()

        const listParentIds = await this.getAllIdsCurrentAndParent(ids)
        const listChildIds = await this.getAllIdsCurrentAndChild(ids)

        return this.createQueryBuilder('qb')
            .where(`qb.id IN (:...ids)`, {ids: [...listParentIds, ...listChildIds]})
            .getMany()
    }

    async getAllIdsOfOrgs(ids: string[]) {
        const res = await this.getAllOfOrgs(ids)

        return res.map(item => item.id)
    }

    async queryFilterBySysPermissionAndChild(query: SelectQueryBuilder<any>, ids: string[], key: string = 'id') {
        const oogIds = await this.getAllIdsCurrentAndChild(ids)

        query.andWhere(`":key" IN (:...oogIds)`, {key, oogIds})
    }

    async getRootOfDepartmentId(departmentId: string) {
        if (!departmentId) return null

        const department = await this.findOneBy({id: departmentId})

        if (!department) return null

        const id = department.path ? department.path.split('/')[1] : department.id

        return this.findOneBy({id})
    }

    async getRootIdOfDepartmentId(departmentId: string) {
        const root = await this.getRootOfDepartmentId(departmentId)

        return root?.id
    }

    private async getQueryGetFullByRootId(rootId: string | string[], filter?: any) {
        let listId = rootId
        if (!Array.isArray(listId)) listId = [listId]

        const where = []
        listId.map(i => where.push({path: ILike(`%${i}%`)}))

        const listOrg = await this.find({where})

        let query = this.createQueryBuilder('qb')
            .where({})
            .orderBy('qb.createdAt', 'DESC')

        if (RequestContext.isNormalUser()) {
            query.andWhere('qb.status = :statusOrg', {statusOrg: ObjectStatus.Active})
        }

        await this.queryFilter(query, filter, listOrg.map(i => i.id))

        return query
    }

    async getAndCountFullOfRoot(rootId: string, filter?: any) {
        if (!rootId) return []

        const query = await this.getQueryGetFullByRootId(rootId, filter)

        console.log(query.getQueryAndParameters())

        return query.getManyAndCount()
    }

    async getFullOfRootByRootId(rootId: string, filter?: any) {
        if (!rootId) return []

        const query = await this.getQueryGetFullByRootId(rootId, filter)

        return query.getMany()
    }

    async getFullOfRootByRootIds(rootOrgIds: any, filter?: any) {
        if (!rootOrgIds.length) return []

        const query = await this.getQueryGetFullByRootId(rootOrgIds, filter)

        return query.getMany()
    }

    async getFullHaveManagerOfRoot(rootId: string, filter?: any) {
        if (!rootId) return []

        const listOrg = await this.createQueryBuilder('qb')
            .where(`qb."approverId" IS NOT NULL`)
            .leftJoinAndMapOne('qb.user', OfficeUser, 'ur', 'ur.id::text = qb."approverId"::text')
            .andWhere(`ur.status = :active`, {active: ObjectStatus.Active})
            .andWhere(`qb.path ILIKE :rootId`, {rootId: `%${rootId.trim()}%`})
            .getMany()

        let query = this.createQueryBuilder('qb')
            .where('qb.status = :statusOrg', {statusOrg: ObjectStatus.Active})
            .orderBy('qb.createdAt', 'DESC')

        await this.queryFilter(query, filter, listOrg?.map(i => i.id))

        return query.getManyAndCount()
    }

    async getFullIdOfRoot(rootId: string) {
        const list = await this.getAndCountFullOfRoot(rootId)

        return list[0].map(i => i.id)
    }

    private async queryFilter(query: SelectQueryBuilder<OfficeOrgChart>, filter?: any, oogIds?: string[]) {
        if (oogIds && oogIds.length) {
            query.andWhere(`qb.id::text IN (:...oogIds)`, {oogIds})
        }

        if (filter) {
            filter.size = filter.size ? filter.size : 20 //1
            filter.page = filter.page ? (filter.page - 1) : 0

            query.take(filter.size)
                .skip(filter.page * filter.size)

            if (filter.keyword) {
                query.andWhere(new Brackets(db => {
                    db.where(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                        .orWhere(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                        .orWhere(`unaccent(LOWER(qb.note)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                }))
            }
        }
    }

    async getFullOfList(orgIds: any, filter?: any) {
        let query = this.createQueryBuilder('qb')
            .where({})
            .orderBy('qb.createdAt', 'DESC')

        await this.queryFilter(query, filter, orgIds)

        return query.getManyAndCount()
    }

    async getBy(where: any) {
        return this.createQueryBuilder()
            .where(where)
            .andWhere({
                id: In(await RequestContext.currentListOrgIds())
            })
            .getOne()
    }

    getAllRoot() {
        return this.find({
            where: {
                parentId: 'root'
            }
        })
    }

    async getL2OrgById(id: string) {
        return this.findOneBy({id: await this.getL2IdOrgById(id)})
    }

    async getL2IdOrgById(id: string) {
        const department = await this.findOneBy({id})
        if (department.path === 'root') return department.id

        return department.path.split('/')[2]
    }

    getManyBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getMany()
    }
}