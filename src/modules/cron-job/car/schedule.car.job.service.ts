import { Injectable } from '@nestjs/common';
import { Timeout } from "@nestjs/schedule";
import { BookingMeetingRoom, MeetingRoomSchedule } from "@models/entities";
import { IsNull, Not } from "typeorm";
import { CarBookingSchedule } from "@models/entities/car.booking.schedule";
import { CarBookingRequest } from "@models/entities/car.booking.request";

@Injectable()
export class ScheduleCarJobService {
    constructor() {
    }

    /*Done*/
    // @Timeout(9000)
    async setCarDataForSchedule() {
        try {
            console.log('setCarDataForSchedule start')
            const schedules = await CarBookingSchedule.find({
                relations: ['booking'],
                where: {
                    booking: IsNull(),
                    requestId: Not(IsNull())
                },
                order: {
                    createdAt: 'DESC'
                }
            })

            console.log('setCarDataForSchedule data', schedules.length)

            for (const schedule of schedules) {
                const booking = await CarBookingRequest.findOne({
                    where: {
                        id: schedule.requestId
                    }
                })

                if (!booking) continue
                schedule.booking = booking
                schedule.fromAddress = booking.fromAddress
                schedule.toAddress = booking.toAddress
                schedule.note = booking.note

                await schedule.save()
            }

        } catch (e) {
            console.log('setCarDataForSchedule err', e)
        }
    }
}
