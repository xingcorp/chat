import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { ChatNotifyUserData } from "@modules/chat/chat-notify/dto/chat-notify.args";
import { NotificationService } from "@core/iam/notification/notification.service";
import { NotifyMessageTitle, NotifyType } from "@common/notify.message";

@Injectable()
export class ChatNotifyService {

    constructor(
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
    ) {
    }
    async sendToUsers(args: ChatNotifyUserData, accessToken: string = null) {
        const { error } = await this.notificationService.destinationPush(
            accessToken,
            NotifyType.ChatNotify,
            args.title,
            args.content,
            '',
            JSON.stringify(args.metadata ?? {}),
            args.receiverIds,
            null,
            process.env.OFFICE_ORGANIZATION_ID
        )

        return !error;


    }
}
