import { Injectable } from '@nestjs/common';
import { WarehouseAssetRepo } from "@models/repositories";
import {
    ManagementWarehouseAssetFilter
} from "@modules/graphql/management/asset/warehouse-asset/dto/warehouse-asset.args";

@Injectable()
export class WarehouseAssetService {
    constructor(private readonly warehouseAssetRepo: WarehouseAssetRepo) {
    }

    async seedData() {
        console.log('warehouseAssetRepo seedData start')
        try {
            await this.warehouseAssetRepo.seedData()
        } catch (e) {
            console.log('warehouseAssetRepo seedData error', e)
        }
        console.log('warehouseAssetRepo seedData done')
    }

    async list(filter: ManagementWarehouseAssetFilter) {
        const [data, total] = await this.warehouseAssetRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }
}
