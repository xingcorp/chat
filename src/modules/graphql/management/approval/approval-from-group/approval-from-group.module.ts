import { Module } from '@nestjs/common';
import { ApprovalFromGroupService } from './approval-from-group.service';
import { ApprovalFromGroupResolver } from './approval-from-group.resolver';
import {
    ApprovalFormGroupRepo,
    ApprovalFormRepo,
    OfficeOrgChartRepo,
    OfficeSysUserRepo,
    OfficeUserRepo
} from "@models/repositories";
import {
    IsNameNotExistApprovalFormGroupDbValidateConstraint
} from "@decorators/validation/db/approval/form/group/is-name-not-exist.approval-form-group.db.validate";
import {
    IsExistApprovalFormGroupDbValidateConstraint
} from "@decorators/validation/db/approval/form/group/is-exist.approval-form-group.db.validate";

@Module({
    providers: [
        ApprovalFromGroupService,
        ApprovalFromGroupResolver,
        OfficeUserRepo,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
        ApprovalFormGroupRepo,
        ApprovalFormRepo,
        IsNameNotExistApprovalFormGroupDbValidateConstraint,
        IsExistApprovalFormGroupDbValidateConstraint,
    ],
    exports: [
        ApprovalFromGroupService,
    ]
})
export class ApprovalFromGroupModule {
}
