import { forwardRef, Module } from "@nestjs/common";
import { IAMModule } from "src/modules/core/iam/iam.module";
import { ProfileResolver } from "./profile.resolver";
import { ProfileService } from "./profile.service";

@Module({
    imports: [
        forwardRef(() => IAMModule)
    ],
    providers: [
        ProfileResolver,
        ProfileService
    ],
    exports: [
        ProfileService
    ]
})
export class ProfileModule { }