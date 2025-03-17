import { forwardRef, Module } from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminResolver } from './admin.resolver';
import { IAMModule } from "@core/iam/iam.module";
import { OfficeOrgChartRepo, OfficeSysUserRepo, OfficeUserRepo } from "@models/repositories";

@Module({
    imports: [
        forwardRef(() => IAMModule),
    ],
    providers: [
        AdminService,
        AdminResolver,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
        OfficeUserRepo,
    ]
})
export class AdminModule {
}
