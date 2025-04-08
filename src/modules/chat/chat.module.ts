import { Module } from '@nestjs/common';
import { ChatMessageModule } from './chat-message/chat-message.module';
import { ChatConversationModule } from './chat-conversation/chat-conversation.module';
import { ChatNotifyModule } from './chat-notify/chat-notify.module';
import { ChatReactionModule } from './chat-reaction/chat-reaction.module';
import { ChatGatewayModule } from './chat-gateway/chat-gateway.module';
import { ChatResolver } from './chat.resolver';
import { ModelModule } from '@models/model.module';
import { OpenSearchModule } from '@modules/search-engine/open-search/open-search.module';
import { messageIndexName } from '@modules/search-engine/open-search/open-search.index';

@Module({
    imports: [
        ChatMessageModule,
        ChatConversationModule,
        ChatNotifyModule,
        ChatReactionModule,
        ChatGatewayModule,
        ModelModule,
        OpenSearchModule.register({ indexName: messageIndexName })
    ],
    providers: [
        ChatResolver
    ]
})
export class ChatModule {
}
