import { Injectable } from "@nestjs/common";
import {
    DataSource, In,
    Repository,
} from "typeorm";
import { WarehouseAsset, OfficeOrgChart } from "@models/entities";
import { RequestContext } from "@common/context/request.context";
import {
    ManagementWarehouseAssetFilter
} from "@modules/graphql/management/asset/warehouse-asset/dto/warehouse-asset.args";

@Injectable()
export class WarehouseAssetRepo extends Repository<WarehouseAsset> {
    constructor(
        private dataSource: DataSource
    ) {
        super(WarehouseAsset, dataSource.createEntityManager());
    }

    async seedData() {
        const check = await this.find({
            relations: ['orgChart'],
            where: {
                orgChart: {id: process.env.OXII_ORG_ID}
            }
        })

        if (check.length) return

        const orgChart = await OfficeOrgChart.findOneBy({id: process.env.OXII_ORG_ID})
        const data = [
            {
                // code: 'WH01',
                name: 'Kho Hành chính (TSCĐ)',
                orgChart
            },
            {
                // code: 'WH02',
                name: 'Kho Hành chính (CCDC)',
                orgChart
            },
            {
                // code: 'WH03',
                name: 'Kho Sản phẩm mẫu PM',
                orgChart
            },
            {
                // code: 'WH04',
                name: 'Kho Sản phẩm mẫu QA',
                orgChart
            },
        ]
        const records = []

        data.map(i => records.push(this.create(i)))

        for (const record of records) {
            await this.save(record)
        }

        return records
    }

    async listByFilter(filter: ManagementWarehouseAssetFilter) {
        const query = this.createQueryBuilder('qb')
            .leftJoinAndSelect('qb.orgChart', 'orgChart')
            .where({
                orgChart: {
                    id: In(await RequestContext.getRootOrgIds()) //Ok
                }
            })

        /*default get all*/
        if (filter.page || filter.size) {
            filter.size = filter.size ? filter.size : 20 //1
            filter.page = filter.page ? (filter.page - 1) : 0

            query.limit(filter.size)
                .offset(filter.page * filter.size)
        }

        return query.getManyAndCount()
    }

    async listByIds(ids: string[]) {
        return this.find({
            relations: ['orgChart'],
            where: {
                id: In(ids),
                orgChart: {
                    id: In(await RequestContext.getRootOrgIds()) //Ok
                }
            }
        })
    }

    async getBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .andWhere({
                orgChart: {
                    id: In(await RequestContext.getRootOrgIds()) //Ok
                }
            })
            .getOne()
    }

    async getOrgIdById(id: string | null) {
        if (!id) return null

        const record = await this.findOne({
            relations: ['orgChart'],
            where: {id}
        })

        return record?.orgChart?.id
    }
}

