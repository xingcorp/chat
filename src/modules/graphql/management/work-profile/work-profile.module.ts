import { forwardRef, Module } from '@nestjs/common';
import { WorkProfileService } from './work-profile.service';
import { WorkProfileResolver } from './work-profile.resolver';
import {
    DetailWorkProfileRepo,
    InfoWorkProfileRepo,
    OfficeInfoBlockRepo,
    OfficeInfoFieldRepo,
    OfficeOrgChartRepo,
    OfficeSysUserRepo,
    OfficeUserRepo, TitleRepo, UserDepartmentRepo, WorkProfileRepo
} from "@models/repositories";
import { StorageModule } from "@core/storage/storage.module";
import { IsExistAttachmentsIamValidateConstraint } from "@decorators/validation/iam/is-exist-attachments.iam.validate";
import { IsExistCodeUserDbValidateConstraint } from "@decorators/validation/db/user/is-exist-code.user.db.validate";
import {
    IsExistWorkProfileDbValidateConstraint
} from "@decorators/validation/db/work-profile/is-exist.work-profile.db.validate";
import {
    IsCodeExistOrgChartDbValidateConstraint
} from "@decorators/validation/db/org-chart/is-code-exist.org-chart.db.validate";
import { IsCodeExistTitleDbValidateConstraint } from "@decorators/validation/db/title/is-code-exist.title.db.validate";
import {
    IsNotExistCodeUserDbValidateConstraint
} from "@decorators/validation/db/user/is-not-exist-code.user.db.validate";
import { IsUniqueCodeUserDbValidateConstraint } from "@decorators/validation/db/user/is-unique-code.user.db.validate";
import {
    IsUniqueActiveDateWorkProfileDbValidateConstraint
} from "@decorators/validation/db/work-profile/is-unique.active-date.work-profile.db.validate";
import { CommonModule } from "@core/common/common.module";
import {
    IsValidMetadataWorkProfileDbValidateConstraint
} from "@decorators/validation/db/work-profile/is-valid-metadata.work-profile.db.validate";

@Module({
    imports: [
        forwardRef(() => CommonModule),
        forwardRef(() => StorageModule),
    ],
    providers: [
        WorkProfileService,
        WorkProfileResolver,
        OfficeUserRepo,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
        OfficeInfoBlockRepo,
        OfficeInfoFieldRepo,
        TitleRepo,
        WorkProfileRepo,
        InfoWorkProfileRepo,
        DetailWorkProfileRepo,
        UserDepartmentRepo,
        IsExistAttachmentsIamValidateConstraint,
        IsExistCodeUserDbValidateConstraint,
        IsNotExistCodeUserDbValidateConstraint,
        IsExistWorkProfileDbValidateConstraint,
        IsCodeExistOrgChartDbValidateConstraint,
        IsCodeExistTitleDbValidateConstraint,
        IsUniqueCodeUserDbValidateConstraint,
        IsUniqueActiveDateWorkProfileDbValidateConstraint,
        IsValidMetadataWorkProfileDbValidateConstraint,
    ],
    exports: [
        WorkProfileService
    ]
})
export class WorkProfileModule {
}
