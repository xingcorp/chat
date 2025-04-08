import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ChatMessageService } from "@modules/chat/chat-message/chat-message.service";
import { OpenSearchService } from '@modules/search-engine/open-search/open-search.service';
import { OfficeChatMessage } from '@models/entities';

@Controller('chat-message')
export class ChatMessageController {
    constructor(
        private readonly chatMessageService: ChatMessageService,
        private readonly openSearchService: OpenSearchService<OfficeChatMessage>
    ) { }

    @Post('document')
    async indexDocument(
        @Body('id') id: string,
        @Body('document') document: OfficeChatMessage,
    ) {
        return this.openSearchService.indexDocument(id, document);
    }

    @Get('search')
    async search(
        @Query('query') query: Record<string, any>,
    ) {
        return this.openSearchService.search(query);
    }
}
