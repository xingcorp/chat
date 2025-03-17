import { Body, Controller, Post } from '@nestjs/common';
import { ScheduleBookingService } from "@modules/graphql/booking/schedule.booking.service";

@Controller('schedule-booking')
export class ScheduleBookingController {
    constructor(private readonly scheduleBookingService: ScheduleBookingService) {}

    @Post('remind-meeting')
    async remindMeeting(@Body() body: { key: string }): Promise<any> {

        console.log('SCHEDULE_MEETING_REMIND check')

        try {
            if (!body?.key || body?.key !== process.env.SCHEDULE_MEETING_REMIND) {
                return
            }

            console.log('SCHEDULE_MEETING_REMIND start')

            console.log('SCHEDULE_MEETING_REMIND gen')
            this.scheduleBookingService.remindMeeting()

            console.log('SCHEDULE_MEETING_REMIND end')

            return 'ok'
        } catch (e) {
            console.log('SCHEDULE_MEETING_REMIND err', e)
        }

    }
}
