import { Controller, Get, Query } from '@nestjs/common';
import { ChatFirebaseService } from "@modules/chat-firebase/chat-firebase.service";

@Controller('chat-firebase')
export class ChatFirebaseController {

    constructor(
        private readonly chatService: ChatFirebaseService,
    ) {
    }

    // HIDE: just run for create user exist before add chat-firebase feature
    @Get('create-user')
    async createExistUserToFirebase(): Promise<any> {
        await this.chatService.createExistUserToFirebase()
        return 'ok'
    }

    @Get('link-preview')
    async linkPreviewGet(@Query('url') url: string): Promise<any> {
        return this.chatService.linkPreviewGetData(url)
    }
}
