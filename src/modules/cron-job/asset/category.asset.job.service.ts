import { Injectable } from '@nestjs/common';
import { Timeout } from "@nestjs/schedule";
import { CategoryAssetService } from "@modules/graphql/management/asset/category-asset/category-asset.service";

@Injectable()
export class CategoryAssetJobService {

    constructor(private readonly categoryAssetService: CategoryAssetService) {
    }

    // @Timeout(10000)
    async seedDataForNew() {
        await this.categoryAssetService.seedData()
    }
}
