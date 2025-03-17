import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, FindOptionsUtils, In, Repository } from "typeorm";
import { UserWorkProfile } from "@models/entities";
import { RequestContext } from "@common/context/request.context";
import {
    ManagementWorkProfileFilter
} from "@modules/graphql/management/work-profile/dto/work-profile.args";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";

@Injectable()
export class WorkProfileRepo extends Repository<UserWorkProfile> {
    constructor(private dataSource: DataSource) {
        super(UserWorkProfile, dataSource.createEntityManager());
    }

    createNew() {
        return this.create({
            createdBy: RequestContext.currentRequestId() ?? null,
            updatedBy: RequestContext.currentRequestId() ?? null,
        })
    }

    async getValidById(id: string) {
        return this.findOne({
            where: {
                id,
                user: {
                    id: In(await RequestContext.currentOrgDataUserIds()),
                }
            }
        })
    }

    listWithFilterByUserId(userId: string, filter: ManagementWorkProfileFilter) {
        return this.listWithFilterOfUser(filter, userId)
    }

    async listWithFilterOfUser(filter: ManagementWorkProfileFilter, userId?: string) {
        if (!userId && RequestContext.isNormalUser()) userId = await RequestContext.currentId()

        const query = this.createQueryBuilder('qb')
            .leftJoinAndSelect('qb.user', 'user')
            .leftJoinAndSelect('qb.info', 'info')
            .leftJoinAndSelect('qb.detail', 'detail')
            .where({})

        if (userId) {
            query.andWhere(`"user".id::text = :userId`, {userId})
                .orderBy('info.activeDate', 'DESC')
        } else {
            query.andWhere(`"user".id::text IN(:...userIds)`, {userIds: await RequestContext.currentOrgDataUserIds()})
                .orderBy('qb."createdAt"', 'DESC')
        }

        /*default get all*/
        if (filter.page || filter.size) {
            filter.size = filter.size ? filter.size : 20 //1
            filter.page = filter.page ? (filter.page - 1) : 0

            query.limit(filter.size)
                .offset(filter.page * filter.size)
        }


        /*Load child relations*/
        FindOptionsUtils.applyRelationsRecursively(query, ['detail'], query.alias, this.metadata, '');

        /*filter if it has another filter here*/
        await this.filterListWorkProfile(query, filter)

        return query.getManyAndCount()
    }

    private async filterListWorkProfile(query: SelectQueryBuilder<UserWorkProfile>, filter: ManagementWorkProfileFilter) {
        if (filter && filter.type) {
            query.andWhere({
                info: {
                    type: filter.type
                }
            })
        }

        if (filter && filter.orgId) {
            query.andWhere({
                detail: {
                    department: {
                        id: filter.orgId
                    }
                }
            })
        }

        if (filter && filter.activeDate) {
            if (filter.activeDate.start) query.andWhere(`info."activeDate" >= :activeDateStart`, {activeDateStart: new Date(filter.activeDate.start).toISOString()})
            if (filter.activeDate.end) query.andWhere(`info."activeDate" <= :activeDateEnd`, {activeDateEnd: new Date(filter.activeDate.end).toISOString()})
        }

        if (filter && filter.keyword) {
            query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(user.fullname)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                .orWhere(`unaccent(LOWER(user.code)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                // .orWhere(`unaccent(LOWER(user.phone)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
            }))
        }
    }
}