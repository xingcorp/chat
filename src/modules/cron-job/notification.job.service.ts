import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from "@nestjs/schedule";
import { NotificationService } from "@core/iam/notification/notification.service";

@Injectable()
export class NotificationJobService {
    constructor(private notificationService: NotificationService) {
    }

    /*@Cron(CronExpression.EVERY_MINUTE, {
      name: "notificationSchedule"
    })*/
    async notificationSchedule() {
        try {
            return this.notificationService.notificationSchedule()
        } catch (e) {
            console.log('notificationSchedule err', e)
        }
    }
}
