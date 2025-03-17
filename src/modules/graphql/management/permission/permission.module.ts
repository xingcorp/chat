import { forwardRef, Module } from "@nestjs/common";
import { IAMModule } from "src/modules/core/iam/iam.module";
import { StorageModule } from "src/modules/core/storage/storage.module";
import { OfficePermissionResolver } from "./permission.resolver";
import { PermissionService } from "./permission.service";

@Module({
    imports: [
        forwardRef(() => IAMModule),
        forwardRef(() => StorageModule)
    ],
    providers: [
        OfficePermissionResolver,
        PermissionService
    ],
    exports: [
        PermissionService
    ]
})
export class PermissionModule { }