import { Module } from '@nestjs/common';
import { AssetService } from './asset.service';
import { AssetResolver } from './asset.resolver';
import {
    AssetRepo,
    CategoryAssetRepo,
    OfficeOrgChartRepo,
    OfficeSysUserRepo,
    OfficeUserRepo, WarehouseAssetRepo
} from "@repositories/index";
import { AssignmentAssetRepo } from "@repositories/asset/assignment.asset.repo";
import { IsExistAttachmentsIamValidateConstraint } from "@decorators/validation/iam/is-exist-attachments.iam.validate";
import { StorageModule } from "@core/storage/storage.module";
import {
    IsExistCategoryAssetDbValidateConstraint
} from "@decorators/validation/db/asset/category-asset/is-exist.category-asset.db.validate";
import {
    IsExistWarehouseAssetDbValidateConstraint
} from "@decorators/validation/db/asset/warehouse-asset/is-exist.warehouse-asset.db.validate";
import {
    IsExistCodeWarehouseAssetDbValidateConstraint
} from "@decorators/validation/db/asset/warehouse-asset/is-exist-code.warehouse-asset.db.validate";
import {
    IsExistCodeCategoryAssetDbValidateConstraint
} from "@decorators/validation/db/asset/category-asset/is-exist-code.category-asset.db.validate";
import { IsExistCodeUserDbValidateConstraint } from "@decorators/validation/db/user/is-exist-code.user.db.validate";
import {
    IsCodeExistOrgChartDbValidateConstraint
} from "@decorators/validation/db/org-chart/is-code-exist.org-chart.db.validate";
import {
    IsExistCodeAssetDbValidateConstraint
} from "@decorators/validation/db/asset/asset/is-exist-code.asset.db.validate";
import {
    IsDataSameOrgAssetDbValidateConstraint
} from "@decorators/validation/db/asset/is-data-same-org.asset.db.validate";

@Module({
    imports: [
        StorageModule,
    ],
    providers: [
        AssetService,
        AssetResolver,
        OfficeUserRepo,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
        AssetRepo,
        CategoryAssetRepo,
        WarehouseAssetRepo,
        AssignmentAssetRepo,
        IsExistAttachmentsIamValidateConstraint,
        IsExistCategoryAssetDbValidateConstraint,
        IsExistWarehouseAssetDbValidateConstraint,
        IsExistCodeCategoryAssetDbValidateConstraint,
        IsExistCodeWarehouseAssetDbValidateConstraint,
        IsExistCodeUserDbValidateConstraint,
        IsCodeExistOrgChartDbValidateConstraint,
        IsExistCodeAssetDbValidateConstraint,
        IsDataSameOrgAssetDbValidateConstraint,
    ]
})
export class AssetModule {
}
