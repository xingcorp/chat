import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, Repository } from "typeorm";
import { OfficeOrgChart, OfficePayroll } from "@models/entities";
import { PayrollListFilter } from "@modules/graphql/management/payroll/dto/payroll.args";

@Injectable()
export class OfficePayrollRepo extends Repository<OfficePayroll>{
    constructor(private dataSource: DataSource) {
        super(OfficePayroll, dataSource.createEntityManager());
    }

    async getListAndCount(filter: PayrollListFilter, orgIds: string[], departmentId: string = null) {
        filter.size = filter.size ? filter.size : 20
        filter.page = filter.page ? (filter.page - 1) : 0

        const query = this.createQueryBuilder('qb')
            .leftJoinAndSelect('qb.orgCharts','ocs')
            .where({})
            .take(filter.size)
            .skip(filter.page * filter.size)
            .orderBy('qb.createdAt', 'DESC')

        if (orgIds?.length) query.andWhere('ocs.id::text IN (:...ocsIds)', {ocsIds: orgIds})

        if (filter && filter.userId) {
            query.andWhere('ocs.id = :departmentId', {departmentId})
        }

        if (filter && filter.keyword) {
            query.andWhere(new Brackets(db => {
                    db.where(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                        .orWhere(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                        .orWhere(`unaccent(LOWER(ocs.name)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                        .orWhere(`unaccent(LOWER(ocs.code)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                }))
        }

        return query.getManyAndCount()
    }
}