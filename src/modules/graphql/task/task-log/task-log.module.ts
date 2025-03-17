import { forwardRef, Module } from '@nestjs/common';
import { TaskLogService } from './task-log.service';
import { TaskLogResolver } from './task-log.resolver';
import { TaskModule } from "@modules/graphql/task/task/task.module";
import {
    OfficeOrgChartRepo,
    OfficeSysUserRepo,
    OfficeTaskLogRepo,
    OfficeTaskRepo,
    OfficeUserRepo
} from "@models/repositories";
import { IsExistAttachmentsIamValidateConstraint } from "@decorators/validation/iam/is-exist-attachments.iam.validate";
import { StorageModule } from "@core/storage/storage.module";
import { CommonModule } from "@core/common/common.module";

@Module({
    imports: [
        TaskModule,
        forwardRef(() => StorageModule),
        forwardRef(() => CommonModule),
    ],
    providers: [
        TaskLogService,
        TaskLogResolver,
        OfficeTaskLogRepo,
        OfficeUserRepo,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
        OfficeTaskRepo,
        IsExistAttachmentsIamValidateConstraint,
    ],
    exports: [
        TaskLogService,
    ]
})
export class TaskLogModule {
}
