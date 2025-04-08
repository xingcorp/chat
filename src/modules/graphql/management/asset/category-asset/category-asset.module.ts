import { Module } from '@nestjs/common';
import { CategoryAssetService } from './category-asset.service';
import { CategoryAssetResolver } from './category-asset.resolver';
import { CategoryAssetRepo, OfficeOrgChartRepo, OfficeSysUserRepo, OfficeUserRepo } from "@models/repositories";

@Module({
    providers: [
        CategoryAssetService,
        CategoryAssetResolver,
        CategoryAssetRepo,
        OfficeUserRepo,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
    ],
    exports: [
        CategoryAssetService
    ]
})
export class CategoryAssetModule {
}
