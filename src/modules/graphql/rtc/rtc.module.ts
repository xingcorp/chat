import { forwardRef, Module } from "@nestjs/common";
import { CoreModule } from "src/modules/core/core.module";
import { IAMModule } from "src/modules/core/iam/iam.module";
import { RTCResolver } from "./rtc.resolver";
import { RTCService } from "./rtc.service";

@Module({
    imports: [
        forwardRef(() => IAMModule),
        forwardRef(() => CoreModule)
    ],
    // controllers: [HealthController],
    providers: [RTCResolver, RTCService],
    exports: [
        RTCService
    ]
})
export class RTCModule {}