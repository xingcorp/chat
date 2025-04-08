import { Body, Controller, Post } from '@nestjs/common';
import { NotificationService } from "@core/iam/notification/notification.service";

@Controller('notification')
export class NotificationController {
    constructor(private readonly notificationService: NotificationService) {
    }

    @Post('notificationSchedule')
    async notificationSchedule(@Body() body: { key: string }): Promise<any> {

        // console.log('SCHEDULE_NOTIFY_NOTIFICATION_SCHEDULE_KEY check')

        try {
            if (!body?.key || body?.key !== process.env.SCHEDULE_NOTIFY_NOTIFICATION_SCHEDULE_KEY) {
                return
            }

            // console.log('SCHEDULE_NOTIFY_NOTIFICATION_SCHEDULE_KEY start')

            this.notificationService.notificationSchedule()

            // console.log('SCHEDULE_NOTIFY_NOTIFICATION_SCHEDULE_KEY end')

            return 'ok'
        } catch (e) {
            console.log('SCHEDULE_NOTIFY_NOTIFICATION_SCHEDULE_KEY err', e)
        }
    }
}
