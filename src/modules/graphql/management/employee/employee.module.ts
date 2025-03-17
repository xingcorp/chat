import { forwardRef, Module } from "@nestjs/common";
import { IAMModule } from "src/modules/core/iam/iam.module";
import { StorageModule } from "src/modules/core/storage/storage.module";
import { EmployeeResolver } from "./employee.resolver";
import { EmployeeService } from "./employee.service";
import { TypeOrmModule } from "@nestjs/typeorm";
import { OfficeOrgChart } from "@models/entities";
import { OfficeOrgChartRepo } from "@models/repositories/office-org-chart.repo";
import { OfficeSysUserRepo } from "@models/repositories/office-sys-user.repo";
import { OfficeSysUser } from "@models/entities/system.user";
import { OfficeUserRepo } from "@repositories/profile.user.repo";
import { OfficeInfoFieldRepo, TitleRepo } from "@models/repositories";
import { IsExistAttachmentsIamValidateConstraint } from "@decorators/validation/iam/is-exist-attachments.iam.validate";
import {
    IsNotExistCodeUserDbValidateConstraint
} from "@decorators/validation/db/user/is-not-exist-code.user.db.validate";
import {
    IsCodeExistOrgChartDbValidateConstraint
} from "@decorators/validation/db/org-chart/is-code-exist.org-chart.db.validate";
import { IsExistCodeUserDbValidateConstraint } from "@decorators/validation/db/user/is-exist-code.user.db.validate";

@Module({
    imports: [
        forwardRef(() => IAMModule),
        forwardRef(() => StorageModule),
        TypeOrmModule.forFeature([
            OfficeOrgChart,
            OfficeSysUser
        ])
    ],
    providers: [
        EmployeeResolver,
        EmployeeService,
        OfficeOrgChartRepo,
        OfficeSysUserRepo,
        OfficeUserRepo,
        OfficeInfoFieldRepo,
        TitleRepo,
        IsExistAttachmentsIamValidateConstraint,
        IsNotExistCodeUserDbValidateConstraint,
        IsCodeExistOrgChartDbValidateConstraint,
        IsExistCodeUserDbValidateConstraint,
    ],
    exports: [
        EmployeeService
    ]
})
export class EmployeeModule { }