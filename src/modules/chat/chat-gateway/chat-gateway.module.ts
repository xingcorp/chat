import { Module } from '@nestjs/common';
import { ChatGateway } from './chat.gateway';
import { ModelModule } from '@models/model.module';
import { CommonModule } from '@core/common/common.module';

@Module({
    imports: [
        ModelModule,
        CommonModule
    ],
    providers: [ChatGateway],
    exports: [ChatGateway]
})
export class ChatGatewayModule {
}
