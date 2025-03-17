import { Injectable } from '@nestjs/common';
import { Cron, Timeout } from "@nestjs/schedule";
import { BookingMeetingRoom, MeetingRoomSchedule, OfficeUser } from "@models/entities";
import { In, IsNull } from "typeorm";

@Injectable()
export class ScheduleMeetingJobService {
    constructor() {
    }

    /*Done*/
    // @Timeout(8000)
    async setDataForSchedule() {
        try {
            console.log('setDataForSchedule start')
            const schedules = await MeetingRoomSchedule.find({
                relations: ['host'],
                where: {
                    host: IsNull()
                },
                order: {
                    createdAt: 'DESC'
                }
            })

            console.log('setDataForSchedule data', schedules.length)

            for (const schedule of schedules) {
                const booking = await BookingMeetingRoom.findOne({
                    relations: ['host', 'participants'],
                    where: {
                        id: schedule.bookingId
                    }
                })

                if (!booking) continue
                schedule.host = booking.host
                schedule.meetingContent = booking.meetingContent
                schedule.quantity = booking.quantity
                schedule.note = booking.note
                schedule.participants = booking.participants

                await schedule.save()
            }

        } catch (e) {
            console.log('setDataForSchedule err', e)
        }
    }
}
