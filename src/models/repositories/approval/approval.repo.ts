import { Injectable } from "@nestjs/common";
import { BaseEntity, DataSource, In, Not, Repository } from "typeorm";
import { ApprovalStep, OfficeApproval, OfficeUser } from "@models/entities";
import { OfficeUserRepo } from "@models/repositories";
import { RequestContext } from "@common/context/request.context";
import { ApprovalStatus } from "@models/entities/approval";
import { ApprovalType } from "@models/entities/approval.form";

@Injectable()
export class OfficeApprovalRepo extends Repository<OfficeApproval> {
    constructor(
        private dataSource: DataSource,
        private officeUserRepo: OfficeUserRepo,
    ) {
        super(OfficeApproval, dataSource.createEntityManager());
    }

    async getAllUserListenerById(id: string) {
        const approval = await this.createQueryBuilder('qb')
            .leftJoinAndMapMany('qb.steps', ApprovalStep, 'steps', 'qb.id::text = steps."approvalId"::text')
            .where({id})
            .getOne()

        const steps: ApprovalStep[] = approval['steps'] ?? []

        let ids = [
            approval.createdBy,
            ...(approval.subscriberIds ? approval.subscriberIds : []),
            ...(approval.followerIds ? approval.followerIds : []),
            ...steps.flatMap(i => i.approveBy),
            ...steps.flatMap(i => i.consentBy),
        ]

        ids = [...new Set(ids)].filter(i => i)

        return this.officeUserRepo.getAllUserAllWayByIds(ids)
    }

    async getAllUserIdListenerById(id: string) {

        const users = await this.getAllUserListenerById(id)

        return users.map(i => i.id)
    }

    async getApprovalUserCanSeeById(id: string) {
        const userIdsListener = await this.getAllUserIdListenerById(id)
        if (!userIdsListener.includes(await RequestContext.currentId())) return null

        return this.findOne({where: {id}})
    }

    async onlyReadByUser(id: any, user: OfficeUser) {
        const approval = await this.findOne({
            relations: ['readBy'],
            where: {
                id,
                status: Not(In([ApprovalStatus.Draft, ApprovalStatus.Forward]))
            }
        })

        if (!approval) return

        approval.readBy = [user]

        await this.save(approval)
        await approval.reload()

        return approval
    }

    async getOneBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .andWhere({
                createdBy: In(await RequestContext.currentOrgDataUserIds())
            })
            .getOne()
    }

    async justOneBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getOne()
    }

    async getOneCanUpdateBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        const user = await RequestContext.currentUser()

        return query
            .where(where)
            .andWhere({
                createdBy: user?.id,
                status: In([ApprovalStatus.Draft])
            })
            .getOne()
    }

    getAllUserIdRelative(data: OfficeApproval) {
        return [
            data.createdBy,
            ...(data.followerIds ?? []),
            ...(data.subscriberIds ?? [])
        ]
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

    async cloneRelation(relations: BaseEntity[], cloneApproval: OfficeApproval, fieldIdName: string) {
        let cloneRelations: object[] = []

        relations.map(i => {
            const tmp = structuredClone(i)
            delete tmp['id']
            cloneRelations.push(tmp)
        })

        return cloneRelations.map(i => {
            let tmp = i;
            tmp[fieldIdName] = cloneApproval.id
            return tmp
        })
    }

    async getBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getOne()
    }

    async getOfVersion(id: string) {
        return this.createQueryBuilder()
            .where({
                relationId: id,
                type: ApprovalType.WikiRelease,
            })
            .getOne()
    }
}