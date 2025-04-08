import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, In, IsNull, Repository } from "typeorm";
import { OfficeUserPaycheck } from "@models/entities";
import { UserPaycheckListFilter } from "@modules/graphql/management/user-paycheck/dto/user-paycheck.args";
import { RequestContext } from "@common/context/request.context";
import { PaycheckStatus } from "@enum/payroll/paycheck.enum";
import { cryptoAesStringDecode, cryptoAesStringEncode } from "@services/crypto-js/index.crypto-js";

@Injectable()
export class OfficeUserPaycheckRepo extends Repository<OfficeUserPaycheck> {
    constructor(private dataSource: DataSource) {
        super(OfficeUserPaycheck, dataSource.createEntityManager());
    }

    async getListAndCountByFilter(filter: UserPaycheckListFilter, userId: string = null, orgData: any = {}) {
        filter.size = filter.size ? filter.size : 20
        filter.page = filter.page ? (filter.page - 1) : 0

        const query = this.createQueryBuilder('qb')
            .leftJoinAndSelect('qb.user','ur')
            .leftJoinAndSelect('qb.payroll','pl')
            .where({})
            .take(filter.size)
            .skip(filter.page * filter.size)
            .orderBy('qb.createdAt', 'DESC')

        if (userId) {
            query.andWhere({
                user: {
                    id: userId
                },
            })
        }

        if (orgData?.userIds !== undefined) {
            if (orgData.userIds.length) {
                query.andWhere({
                    user: {
                        id: In(orgData.userIds)
                    }
                })
            } else {
                query.andWhere({
                    user: {
                        id: IsNull()
                    }
                })
            }

        }

        if (filter && filter.orgChartIds) {
            if (orgData?.userIdsPicked?.length) {
                query.andWhere({
                    user: {
                        id: In(orgData.userIdsPicked)
                    }
                })
            } else {
                query.andWhere({
                    user: {
                        id: IsNull()
                    }
                })
            }
        }

        if (filter && filter.keyword) {
            query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(ur.code)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(ur.fullname)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
            }))
        }

        if (filter && filter.month) {
            query.andWhere({month: filter.month})
        }

        if (filter && filter.paycheckId) {
            query.andWhere({id: filter.paycheckId})
        }

        if (filter && filter.year) {
            query.andWhere({year: filter.year})
        }

        if (filter && filter.payrollId) {
            query.andWhere({
                payroll: {
                    id: filter.payrollId
                }
            })
        }

        if (filter && filter.createdDate) {
            if (filter.createdDate.start) query.andWhere(`qb."createdAt" >= :createdDateStart`, {createdDateStart: new Date(filter.createdDate.start).toISOString()})
            if (filter.createdDate.end) query.andWhere(`qb."createdAt" <= :createdDateEnd`, {createdDateEnd: new Date(filter.createdDate.end).toISOString()})
        }

        if (filter && filter.statuses) {
            query.andWhere({status: In(filter.statuses)})
        }

        return query.getManyAndCount()
    }

    async getListAndCountByFilterByUserId(args: UserPaycheckListFilter, userId: string) {
        return this.getListAndCountByFilter(args, userId)
    }

    getOfUserById(userId: string, id: string) {
        return this.findOne({
            relations: ['user', 'payroll'],
            where: {
                id,
                user: {
                    id: userId
                }
            }
        })
    }

    async getOfRequesterById(id: string) {
        return this.findOne({
            relations: ['user', 'payroll'],
            where: {
                id,
                user: {
                    id: await RequestContext.currentId()
                }
            }
        })
    }

    async getOfAdminNotSupperById(id: string) {
        return this.findOne({
            relations: ['user', 'payroll'],
            where: {
                id,
                user: {
                    id: In(await RequestContext.currentOrgDataUserIds())
                }
            }
        })
    }

    getOfUsersById(id: string, userIds: any) {
        if (!userIds?.length) return null

        return this.findOne({
            relations: ['user', 'payroll'],
            where: {
                id,
                user: {
                    id: In(userIds ?? [])
                }
            }
        })
    }

    async getById(id: string) {
        return this.findOne({
            relations: ['user', 'payroll'],
            where: {
                id,
            }
        })
    }

    async changeStatusToInProgressById(id: string) {
        const paycheck = await this.findOneBy({id})

        if (paycheck.status !== PaycheckStatus.In_progress) {
            paycheck.status = PaycheckStatus.In_progress

            return paycheck.save()
        }

        return paycheck
    }

    encodeValue(mess: number | string, secret: string) {
        return cryptoAesStringEncode(mess, secret)
    }

    decodeValue(encode: any, secret: string) {
        return cryptoAesStringDecode(encode, secret)
    }

    metadataEncodeValue(metadata: JSON, secret: string) {
        let metadataEncode = {}
        for (const key of Object.keys(metadata)) {
            metadataEncode[key] = this.encodeValue(metadata[key], secret)
        }
        
        return metadataEncode
    }

    metadataDecodeValue(encodeData: string[], secret: string) {
        const metadata = JSON.parse(encodeData[0])

        let metadataDecode = {}
        for (const key of Object.keys(metadata)) {
            metadataDecode[key] = this.decodeValue(metadata[key], secret)
        }

        return [JSON.stringify(metadataDecode)]
    }
}