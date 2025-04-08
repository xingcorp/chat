import { Injectable } from '@nestjs/common';
import { Timeout } from "@nestjs/schedule";
import { WarehouseAssetService } from "@modules/graphql/management/asset/warehouse-asset/warehouse-asset.service";

@Injectable()
export class WarehouseAssetJobService {

    constructor(private readonly warehouseAssetService: WarehouseAssetService) {
    }

    // @Timeout(10000)
    async seedDataForNew() {
        await this.warehouseAssetService.seedData()
    }
}
