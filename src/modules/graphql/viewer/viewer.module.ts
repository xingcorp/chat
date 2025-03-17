import { Module } from '@nestjs/common';
import { ViewerService } from './viewer.service';
import { ViewerRepo } from "@models/repositories";

@Module({
    providers: [
        ViewerService,
        ViewerRepo
    ],
    exports: [ViewerService]
})
export class ViewerModule {
}
