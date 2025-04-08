import { forwardRef, Module } from "@nestjs/common";
import { IAMModule } from "src/modules/core/iam/iam.module";
import { StorageModule } from "src/modules/core/storage/storage.module";
import { MeetingRoomResolver } from "./meeting.room.resolver";
import { MeetingRoomService } from './meeting-room.service';
import { TypeOrmModule } from "@nestjs/typeorm";
import { OfficeOrgChart } from "@models/entities";
import { OfficeSysUser } from "@models/entities/system.user";
import { OfficeOrgChartRepo } from "@models/repositories/office-org-chart.repo";
import { OfficeSysUserRepo } from "@models/repositories/office-sys-user.repo";
import { OfficeUserRepo } from "@models/repositories";

@Module({
    imports: [
        forwardRef(() => IAMModule),
        forwardRef(() => StorageModule),
        TypeOrmModule.forFeature([
            OfficeOrgChart,
            OfficeSysUser
        ])
    ],
    providers: [
        MeetingRoomResolver,
        MeetingRoomService,
        OfficeOrgChartRepo,
        OfficeSysUserRepo,
        OfficeUserRepo,
    ],
    exports: []
})
export class MeetingRoomModule { }