import { Injectable } from "@nestjs/common";
import {
    DataSource, In,
    Repository,
} from "typeorm";
import { CategoryAsset, OfficeOrgChart } from "@models/entities";
import { AssetCategoryUnit } from "@enum/asset/asset.enum";
import {
    ManagementCategoryAssetFilter
} from "@modules/graphql/management/asset/category-asset/dto/category-asset.args";
import { RequestContext } from "@common/context/request.context";

@Injectable()
export class CategoryAssetRepo extends Repository<CategoryAsset> {
    constructor(
        private dataSource: DataSource
    ) {
        super(CategoryAsset, dataSource.createEntityManager());
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
                name: 'Màn hình máy tính',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Laptop',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Bàn phím rời',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Chuột',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Ổ cắm rời',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Lọ cắm hoa',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Tủ lạnh',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Lò vi sóng',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Nồi chiên không dầu',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Bàn',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Ghế',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Ấm đun nước siêu tốc',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Máy pha cà phê',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Tủ',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Loa',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Bình lọc nước',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Máy in',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Quạt cây',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Robot hút bụi',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Kệ sách',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Tivi',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Điện thoại',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Tablet',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Bộ loadbalancing',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Bộ phát wifi',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Switch 8 port',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Máy chấm công',
                unit: AssetCategoryUnit.Piece,
                orgChart
            },
            {
                name: 'Máy chiếu',
                unit: AssetCategoryUnit.Piece,
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

    async listByFilter(filter: ManagementCategoryAssetFilter) {
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

