import { Module } from '@nestjs/common';
import { PayrollService } from './payroll.service';
import { PayrollResolver } from './payroll.resolver';
import { OfficeSysUserRepo } from "@repositories/office-sys-user.repo";
import { OfficePayrollRepo } from "@repositories/payroll/office-payroll.repo";
import { OfficeUserPaycheckRepo } from "@repositories/payroll/office-user-paycheck.repo";
import { OfficeInfoBlockRepo } from "@repositories/office-info-block.repo";
import { OfficeInfoFieldRepo } from "@repositories/office-info-field.repo";
import { OfficeOrgChartRepo } from "@repositories/office-org-chart.repo";
import { OfficeUserRepo } from '@models/repositories/profile.user.repo';

@Module({
    providers: [
        PayrollService,
        PayrollResolver,
        OfficeSysUserRepo,
        OfficePayrollRepo,
        OfficeUserPaycheckRepo,
        OfficeInfoBlockRepo,
        OfficeInfoFieldRepo,
        OfficeOrgChartRepo,
        OfficeUserRepo
    ],
    exports: [
        PayrollService
    ]
})
export class PayrollModule {
}
