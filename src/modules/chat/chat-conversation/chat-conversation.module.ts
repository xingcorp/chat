import { Module } from '@nestjs/common';
import { ChatConversationService } from './chat-conversation.service';
import { ChatConversationResolver } from './chat-conversation.resolver';
import { OfficeUserRepo } from "@models/repositories";
import { SearchEngineModule } from "@modules/search-engine/search-engine.module";
import { CommonModule } from '@core/common/common.module';
import { ModelModule } from '@models/model.module';
import { ChatGatewayModule } from '../chat-gateway/chat-gateway.module';

@Module({
    imports: [
        SearchEngineModule,
        ModelModule,
        CommonModule,
        ChatGatewayModule,
    ],
    providers: [
        ChatConversationService,
        ChatConversationResolver,
        OfficeUserRepo,
    ],
    exports: [
        ChatConversationService,
    ]
})
export class ChatConversationModule {
}
