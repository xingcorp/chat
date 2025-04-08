import { Module } from '@nestjs/common';
import { ChatMessageService } from './chat-message.service';
import { ChatMessageResolver } from './chat-message.resolver';
import { ChatMessageReaderRepo, ChatMessageRepo, OfficeUserRepo } from "@models/repositories";
import { ChatConversationModule } from "@modules/chat/chat-conversation/chat-conversation.module";
import { SearchEngineModule } from "@modules/search-engine/search-engine.module";
import { ChatMessageController } from './chat-message.controller';
import { ChatGatewayModule } from '../chat-gateway/chat-gateway.module';
import { CommonModule } from '@core/common/common.module';
import { BullModule } from "@nestjs/bull";
import { ModelModule } from '@models/model.module';
import { ChatNotifyModule } from '../chat-notify/chat-notify.module';
import { OpenSearchModule } from '@modules/search-engine/open-search/open-search.module';
import { messageIndexName } from '@modules/search-engine/open-search/open-search.index';

@Module({
    imports: [
        ChatConversationModule,
        SearchEngineModule,
        ChatGatewayModule,
        CommonModule,
        BullModule.registerQueueAsync({
            name: 'chat_message_queue',
        }),
        ModelModule,
        ChatNotifyModule,
        OpenSearchModule.register({ indexName: messageIndexName })
    ],
    providers: [
        ChatMessageService,
        ChatMessageResolver,
        ChatMessageReaderRepo,
        OfficeUserRepo,
    ],
    exports: [
        ChatMessageService
    ],
    controllers: [ChatMessageController]
})
export class ChatMessageModule {
}
