import { forwardRef, Module } from "@nestjs/common";
import { IAMModule } from "src/modules/core/iam/iam.module";
import { StorageModule } from "src/modules/core/storage/storage.module";
import { CarResolver } from "./car.resolver";
import { CarService } from "./car.service";
import { ApprovalModule } from "../../approval/approval.module";
import { TypeOrmModule } from "@nestjs/typeorm";
import { OfficeOrgChart } from "@models/entities";
import { OfficeSysUser } from "@models/entities/system.user";
import { OfficeOrgChartRepo } from "@models/repositories/office-org-chart.repo";
import { OfficeSysUserRepo } from "@models/repositories/office-sys-user.repo";
import {
    BookingCarScheduleRepo,
    CarRepo,
    DateCloneRepo,
    NotificationCampaignRepo,
    OfficeUserRepo
} from "@models/repositories";
import { IsExistCarDbValidateConstraint } from "@decorators/validation/db/car/car/is-exist.car.db.validate";
import { ScheduleBookingCarService } from './schedule.booking.car.service';
import { ScheduleBookingCarResolver } from './schedule.booking.car.resolver';
import {
    IsExistAndCanModifyScheduleCarDbValidateConstraint
} from "@decorators/validation/db/car/schedule/is-exist-and-can-modify.schedule.car.db.validate";
import {
    IsValidTimeScheduleCarDbValidateConstraint
} from "@decorators/validation/db/car/schedule/is-valid-time.schedule.car.db.validate";

@Module({
    imports: [
        forwardRef(() => IAMModule),
        forwardRef(() => StorageModule),
        forwardRef(() => ApprovalModule),
        TypeOrmModule.forFeature([
            OfficeOrgChart,
            OfficeSysUser
        ])
    ],
    providers: [
        CarResolver,
        CarService,
        OfficeOrgChartRepo,
        OfficeSysUserRepo,
        OfficeUserRepo,
        BookingCarScheduleRepo,
        CarRepo,
        DateCloneRepo,
        NotificationCampaignRepo,
        IsExistCarDbValidateConstraint,
        ScheduleBookingCarService,
        ScheduleBookingCarResolver,
        IsExistAndCanModifyScheduleCarDbValidateConstraint,
        IsValidTimeScheduleCarDbValidateConstraint,
    ],
    exports: [
        CarService
    ]
})
export class CarModule { }