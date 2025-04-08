import { forwardRef, Module } from '@nestjs/common';
import { UserPaycheckService } from './user-paycheck.service';
import { UserPaycheckResolver } from './user-paycheck.resolver';
import { OfficeUserPaycheckRepo } from "@repositories/payroll/office-user-paycheck.repo";
import { OfficeUserRepo } from "@repositories/profile.user.repo";
import { PayrollModule } from "@modules/graphql/management/payroll/payroll.module";
import { OfficeInfoFieldRepo } from "@repositories/office-info-field.repo";
import { OfficeInfoBlockRepo } from "@repositories/office-info-block.repo";
import { IAMModule } from "@core/iam/iam.module";
import { OfficeSysUserRepo } from "@repositories/office-sys-user.repo";
import { OfficeOrgChartRepo } from "@repositories/office-org-chart.repo";
import { LogModule } from "@modules/graphql/log/log.module";


@Module({
    imports: [
        PayrollModule,
        forwardRef(() => IAMModule),
        LogModule,
    ],
    providers: [
        UserPaycheckService,
        UserPaycheckResolver,
        OfficeUserPaycheckRepo,
        OfficeUserRepo,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
        OfficeInfoBlockRepo,
        OfficeInfoFieldRepo,
    ]
})
export class UserPaycheckModule {
}
