import { forwardRef, Module } from '@nestjs/common';
import { SqlScalingService } from './sql-scaling.service';
import { SqlScalingController } from './sql-scaling.controller';
import { CommonModule } from "@core/common/common.module";

@Module({
    imports: [
        forwardRef(() => CommonModule),
    ],
    providers: [SqlScalingService],
    controllers: [SqlScalingController]
})
export class SqlScalingModule {
}
