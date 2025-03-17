import { forwardRef, Module } from '@nestjs/common';
import { TaskService } from './task.service';
import { TaskResolver } from './task.resolver';
import {
    DateCloneRepo,
    FilterRepo,
    OfficeObjectRepo,
    OfficeOrgChartRepo,
    OfficeSysUserRepo, OfficeTaskLogRepo,
    OfficeTaskProjectRepo,
    OfficeTaskRepo,
    OfficeUserRepo
} from "@repositories/index";
import { StorageModule } from "@core/storage/storage.module";
import { CommonModule } from "@core/common/common.module";
import { IAMModule } from "@core/iam/iam.module";
import { TaskController } from './task.controller';
import {
    IsNameNotExistTaskFilterDbValidateConstraint
} from "@decorators/validation/db/filter/task/is-name-not-exist.task.filter.db.validate";
import {
    IsCanUpdateTaskFilterDbValidateConstraint
} from "@decorators/validation/db/filter/task/is-can-update.task.filter.db.validate";
import { IsExistTaskDbValidateConstraint } from "@decorators/validation/db/task/is-exist.task.db.validate";

@Module({
    imports: [
        forwardRef(() => StorageModule),
        forwardRef(() => CommonModule),
        forwardRef(() => IAMModule),
    ],
    providers: [
        TaskService,
        TaskResolver,
        OfficeTaskRepo,
        OfficeTaskProjectRepo,
        OfficeTaskLogRepo,
        OfficeUserRepo,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
        OfficeObjectRepo,
        DateCloneRepo,
        FilterRepo,
        IsNameNotExistTaskFilterDbValidateConstraint,
        IsCanUpdateTaskFilterDbValidateConstraint,
        IsExistTaskDbValidateConstraint,
    ],
    exports: [
        TaskService
    ],
    controllers: [TaskController]
})
export class TaskModule {
}
