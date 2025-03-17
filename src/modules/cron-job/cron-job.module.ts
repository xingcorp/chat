import { forwardRef, Module } from '@nestjs/common';
import { TaskJobService } from './task.job.service';
import { ScheduleModule } from "@nestjs/schedule";
import { ChatFirebaseJobService } from './chat-firebase.job.service';
import { ChatFirebaseModule } from "@modules/chat-firebase/chat-firebase.module";
import { TaskModule } from "@modules/graphql/task/task/task.module";
import { EmployeeJobService } from './employee.job.service';
import { EmployeeModule } from "@modules/graphql/management/employee/employee.module";
import { NotificationJobService } from './notification.job.service';
import { IAMModule } from "@core/iam/iam.module";
import { ObjectStoreJobService } from './object-store.job.service';
import { ObjectStoreModule } from "@service-modules/object-store/object-store.module";
import { RtcJobService } from './rtc.job.service';
import { RTCModule } from "@modules/graphql/rtc/rtc.module";
import { WorkProfileJobService } from './work-profile.job.service';
import { WorkProfileModule } from "@modules/graphql/management/work-profile/work-profile.module";
import { CategoryAssetJobService } from './asset/category.asset.job.service';
import { CategoryAssetModule } from "@modules/graphql/management/asset/category-asset/category-asset.module";
import { WarehouseAssetJobService } from "@modules/cron-job/asset/warehouse.asset.job.service";
import { WarehouseAssetModule } from "@modules/graphql/management/asset/warehouse-asset/warehouse-asset.module";
import { GroupFormJobService } from './approval/group-form.job.service';
import {
    ApprovalFromGroupModule
} from "@modules/graphql/management/approval/approval-from-group/approval-from-group.module";
import { ScheduleMeetingJobService } from './meeting/schedule.meeting.job.service';
import { ScheduleCarJobService } from './car/schedule.car.job.service';
import { ApprovalJobService } from './approval/approval.job.service';

@Module({
    imports: [
        ScheduleModule.forRoot(),
        ChatFirebaseModule,
        TaskModule,
        EmployeeModule,
        forwardRef(() => IAMModule),
        ObjectStoreModule,
        RTCModule,
        WorkProfileModule,
        CategoryAssetModule,
        WarehouseAssetModule,
        ApprovalFromGroupModule,
    ],
    providers: [
        TaskJobService,
        ChatFirebaseJobService,
        EmployeeJobService,
        NotificationJobService,
        ObjectStoreJobService,
        RtcJobService,
        WorkProfileJobService,
        CategoryAssetJobService,
        WarehouseAssetJobService,
        GroupFormJobService,
        ScheduleMeetingJobService,
        ScheduleCarJobService,
        ApprovalJobService,
    ],
})
export class CronJobModule {
}
