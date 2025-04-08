import { forwardRef, Module } from "@nestjs/common";
import { IAMModule } from "src/modules/core/iam/iam.module";
import { StorageModule } from "src/modules/core/storage/storage.module";
import { BookingMeetingRoomResolver } from "./meeting.room.resolver";
import { BookingService } from "./booking.service";
import { BookingCarResolver } from "./booking.car.resolver";
import { ApprovalModule } from "../approval/approval.module";
import {
    BookingMeetingRoomRepo, DateCloneRepo,
    MeetingRoomScheduleRepo, NotificationCampaignRepo,
    OfficeOrgChartRepo,
    OfficeSysUserRepo,
    OfficeUserRepo
} from "@models/repositories";
import { IsExistRoomDbValidateConstraint } from "@decorators/validation/db/room/room/is-exist.room.db.validate";
import { ScheduleBookingService } from './schedule.booking.service';
import { ScheduleBookingResolver } from './schedule.booking.resolver';
import {
    IsExistAndCanModifyScheduleMeetingDbValidateConstraint
} from "@decorators/validation/db/meeting/schedule/is-exist-and-can-modify.schedule.meeting.db.validate";
import {
    IsValidTimeScheduleMeetingDbValidateConstraint
} from "@decorators/validation/db/meeting/schedule/is-valid-time.schedule.meeting.db.validate";
import {
    IsExistScheduleMeetingDbValidateConstraint
} from "@decorators/validation/db/meeting/schedule/is-exist.schedule.meeting.db.validate";
import {
    IsExistAndGetUserDbValidateConstraint
} from "@decorators/validation/db/user/is-exist-and-get.user.db.validate";
import { CommonModule } from "@core/common/common.module";
import { ScheduleBookingController } from './schedule.booking.controller';
import { ModelModule } from "@models/model.module";

@Module({
    imports: [
        forwardRef(() => IAMModule),
        forwardRef(() => CommonModule),
        forwardRef(() => StorageModule),
        forwardRef(() => ApprovalModule),
        ModelModule
    ],
    providers: [
        BookingService,
        BookingCarResolver,
        BookingMeetingRoomResolver,
        ScheduleBookingService,
        ScheduleBookingResolver,
    ],
    exports: [
        BookingService
    ],
    controllers: [ScheduleBookingController]
})
export class BookingModule { }