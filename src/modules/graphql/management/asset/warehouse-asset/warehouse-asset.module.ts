import { Module } from '@nestjs/common';
import { WarehouseAssetService } from './warehouse-asset.service';
import { WarehouseAssetResolver } from './warehouse-asset.resolver';
import { OfficeOrgChartRepo, OfficeSysUserRepo, OfficeUserRepo, WarehouseAssetRepo } from "@models/repositories";

@Module({
    providers: [
        WarehouseAssetService,
        WarehouseAssetResolver,
        WarehouseAssetRepo,
        OfficeUserRepo,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
    ],
    exports: [
        WarehouseAssetService
    ]
})
export class WarehouseAssetModule {
}
