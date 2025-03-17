import { Module ,forwardRef } from "@nestjs/common";
import { OrganizationDeviceResolver } from "./organization.devices.resolver";
import { OrganizationDeviceService } from "./organization.device.service";
import { IAMModule } from "src/modules/core/iam/iam.module";

@Module({
    imports: [
        forwardRef(() => IAMModule)
    ],
    providers: [OrganizationDeviceResolver, OrganizationDeviceService],
    exports: []
})
export class OrganizationDeviceModule { }