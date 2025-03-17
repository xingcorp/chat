import { forwardRef, Module } from "@nestjs/common";
import { IAMModule } from "src/modules/core/iam/iam.module";
import { StorageModule } from "src/modules/core/storage/storage.module";
import { CheckInResolver } from "./checkin.resolver";
import { CheckinService } from './checkin.service';
import { WhiteListIpRepo } from "@repositories/check-in/white-list.ip.repo";

@Module({
    imports: [
        forwardRef(() => IAMModule),
        forwardRef(() => StorageModule)
    ],
    providers: [
        CheckInResolver,
        CheckinService,
        WhiteListIpRepo
    ],
    exports: []
})
export class CheckInModule { }