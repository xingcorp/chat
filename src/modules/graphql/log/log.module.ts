import { forwardRef, Module } from '@nestjs/common';
import { LogService } from './log.service';
import { OfficeLogRepo } from "@models/repositories";
import { StorageModule } from "@core/storage/storage.module";

@Module({
    imports: [
        forwardRef(() => StorageModule),
    ],
    providers: [
        LogService,
        OfficeLogRepo
    ],
    exports: [LogService]
})
export class LogModule {
}
