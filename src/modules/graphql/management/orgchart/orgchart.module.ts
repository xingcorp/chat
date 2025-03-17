import { forwardRef, Module } from "@nestjs/common";
import { IAMModule } from "src/modules/core/iam/iam.module";
import { StorageModule } from "src/modules/core/storage/storage.module";
import { OrgChartResolver } from "./orgchart.resolver";
import { OrgChartService } from "./orgchart.service";
import { TypeOrmModule } from "@nestjs/typeorm";
import { OfficeOrgChart } from "@models/entities";
import { OfficeOrgChartRepo } from "@models/repositories/office-org-chart.repo";
import { OfficeSysUser } from "@models/entities/system.user";
import { OfficeSysUserRepo } from "@models/repositories/office-sys-user.repo";
import { OfficeUserRepo } from "@repositories/profile.user.repo";
import {
    IsCodeExistedOrgChartDbValidateConstraint
} from "@decorators/validation/db/org-chart/is-code-existed.org-chart.db.validate";

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
        OrgChartResolver,
        OrgChartService,
        OfficeOrgChartRepo,
        OfficeSysUserRepo,
        OfficeUserRepo,
        IsCodeExistedOrgChartDbValidateConstraint,
    ],
    exports: [
        OrgChartService
    ]
})
export class OrgChartModule { }