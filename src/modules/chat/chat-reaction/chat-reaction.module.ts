import { Module } from '@nestjs/common';
import { ChatReactionService } from './chat-reaction.service';
import { ChatReactionResolver } from './chat-reaction.resolver';
import { ModelModule } from '@models/model.module';
import { CommonModule } from '@core/common/common.module';

@Module({
    imports: [
        ModelModule,
        CommonModule
    ],
    providers: [
        ChatReactionService,
        ChatReactionResolver,
    ]
})
export class ChatReactionModule {
}
