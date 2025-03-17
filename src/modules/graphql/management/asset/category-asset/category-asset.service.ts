import { Injectable } from '@nestjs/common';
import { CategoryAssetRepo } from "@models/repositories";
import {
    ManagementCategoryAssetFilter
} from "@modules/graphql/management/asset/category-asset/dto/category-asset.args";

@Injectable()
export class CategoryAssetService {

    constructor(private readonly categoryAssetRepo: CategoryAssetRepo) {
    }

    async seedData() {
        console.log('categoryAssetRepo seedData start')
        try {
            await this.categoryAssetRepo.seedData()
        } catch (e) {
            console.log('categoryAssetRepo seedData error', e)
        }
        console.log('categoryAssetRepo seedData done')
    }

    async list(filter: ManagementCategoryAssetFilter) {
        const [data, total] = await this.categoryAssetRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }
}
