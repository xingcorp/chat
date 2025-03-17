import { Injectable } from "@nestjs/common";
import {
    Between,
    Brackets,
    DataSource, In,
    Repository,
} from "typeorm";
import { Asset } from "@models/entities/asset/asset";
import { RequestContext } from "@common/context/request.context";
import { ManagementAssetFilter } from "@modules/graphql/management/asset/asset/dto/asset.args";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";

@Injectable()
export class AssetRepo extends Repository<Asset> {
    constructor(
        private dataSource: DataSource
    ) {
        super(Asset, dataSource.createEntityManager());
    }

    async listByFilter(filter: ManagementAssetFilter) {
        const query = this.createQueryBuilder('qb')
            .leftJoinAndSelect('qb.department', 'department')
            .leftJoinAndSelect('qb.managementDepartment', 'managementDepartment')
            .leftJoinAndSelect('qb.assignedDepartment', 'assignedDepartment')
            .leftJoinAndSelect('qb.managementUser', 'managementUser')
            .leftJoinAndSelect('qb.category', 'category')
            .leftJoinAndSelect('qb.warehouse', 'warehouse')
            .leftJoinAndSelect('qb.assignedUser', 'assignedUser')
            .where({
                department: {
                    id: In(await RequestContext.getRootOrgIds()) //Ok
                },
            })
            .orderBy('qb.createdAt', 'DESC')

        await this.filterQuery(query, filter)

        return query.getManyAndCount()
    }

    async getById(id: string) {
        return this.findOne({
            relations: ['managementDepartment', 'assignedDepartment', 'managementUser', 'category', 'warehouse', 'assignedUser'],
            where: {
                id,
                department: {
                    id: In(await RequestContext.getRootOrgIds()) //Ok
                }
            }
        })
    }

    private async filterQuery(query: SelectQueryBuilder<Asset>, filter: ManagementAssetFilter) {
        /*default get all*/
        if (filter.page || filter.size) {
            filter.size = filter.size ? filter.size : 20 //1
            filter.page = filter.page ? (filter.page - 1) : 0

            query.limit(filter.size)
                .offset(filter.page * filter.size)
        }

        if (filter && filter.keyword) {
            query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(qb.serial)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
            }))
        }

        if (filter && filter.categoryId) {
            query.andWhere({
                category: {id: filter.categoryId}
            })
        }

        if (filter && filter.status) {
            query.andWhere({
                status: filter.status
            })
        }

        if (filter && filter.purchaseDate) {
            if (filter.purchaseDate.start) query.andWhere(`info."purchaseDate" >= :purchaseDateStart`, {purchaseDateStart: new Date(filter.purchaseDate.start).toISOString()})
            if (filter.purchaseDate.end) query.andWhere(`info."purchaseDate" <= :purchaseDateEnd`, {purchaseDateEnd: new Date(filter.purchaseDate.end).toISOString()})
        }

        if (filter && filter.warrantyByMonth) {
            query.andWhere({
                warrantyByMonth: filter.warrantyByMonth
            })
        }

        if (filter && filter.priceRange) {
            query.andWhere({
                price: Between(filter.priceRange.min, filter.priceRange.max)
            })
        }

        if (filter && filter.managementDepartmentId) {
            query.andWhere({
                managementDepartment: {id: filter.managementDepartmentId}
            })
        }

        if (filter && filter.assignedDepartmentId) {
            query.andWhere({
                assignedDepartment: {id: filter.assignedDepartmentId}
            })
        }
    }

    async getBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .andWhere({
                department: {
                    id: In(await RequestContext.getRootOrgIds()) //Ok
                }
            })
            .getOne()
    }
}

