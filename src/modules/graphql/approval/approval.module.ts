import { forwardRef, Module } from "@nestjs/common";
import { IAMModule } from "src/modules/core/iam/iam.module";
import { ApprovalResolver } from "./approval.resolver";
import { StorageModule } from "src/modules/core/storage/storage.module";
import { ApprovalService } from "./approval.service";
import { TypeOrmModule } from "@nestjs/typeorm";
import { OfficeOrgChart } from "@models/entities";
import { OfficeSysUser } from "@models/entities/system.user";
import { OfficeOrgChartRepo } from "@models/repositories/office-org-chart.repo";
import { OfficeSysUserRepo } from "@models/repositories/office-sys-user.repo";
import { ApprovalFormStepRepo } from "@repositories/approval/approval.form.step.repo";
import { OfficeUserRepo } from "@repositories/profile.user.repo";
import {
    ApprovalFormGroupRepo,
    ApprovalFormRepo, ApprovalForwardRepo, ApprovalForwardUserRepo,
    ApprovalStepRepo,
    FilterRepo,
    OfficeApprovalRepo, OfficeLogRepo
} from "@models/repositories";
import { LogModule } from "@modules/graphql/log/log.module";
import {
    IsCanUpdateApprovalDbValidateConstraint
} from "@decorators/validation/db/approval/approval/is-can-update.approval.db.validate";
import {
    IsCanAddSubscriberApprovalDbValidateConstraint
} from "@decorators/validation/db/approval/approval/is-can-add-subscriber.approval.db.validate";
import {
    IsValidSubscriberListApprovalDbValidateConstraint
} from "@decorators/validation/db/approval/approval/is-valid-subscriber-list.approval.db.validate";
import {
    IsNameNotExistUserApprovalFilterDbValidateConstraint
} from "@decorators/validation/db/filter/user-approval/is-name-not-exist.user-approval.filter.db.validate";
import {
    IsCanUpdateUserApprovalFilterDbValidateConstraint
} from "@decorators/validation/db/filter/user-approval/is-can-update.user-approval.filter.db.validate";
import {
    IsExistApprovalFormGroupDbValidateConstraint
} from "@decorators/validation/db/approval/form/group/is-exist.approval-form-group.db.validate";
import {
    IsExistApprovalDbValidateConstraint
} from "@decorators/validation/db/approval/approval/is-exist.approval.db.validate";
import {
    IsExistAndGetUserDbValidateConstraint
} from "@decorators/validation/db/user/is-exist-and-get.user.db.validate";

@Module({
    imports: [
        forwardRef(() => IAMModule),
        forwardRef(() => StorageModule),
        LogModule,
        TypeOrmModule.forFeature([
            OfficeOrgChart,
            OfficeSysUser
        ]),
    ],
    providers: [
        ApprovalResolver,
        ApprovalService,
        OfficeOrgChartRepo,
        OfficeSysUserRepo,
        ApprovalFormStepRepo,
        OfficeUserRepo,
        OfficeApprovalRepo,
        ApprovalStepRepo,
        ApprovalFormRepo,
        ApprovalFormGroupRepo,
        ApprovalForwardRepo,
        OfficeLogRepo,
        ApprovalForwardUserRepo,
       
        FilterRepo,
       
    ],
    exports: [
        ApprovalService
    ]
})
export class ApprovalModule { }