import { Injectable } from '@nestjs/common';
import {
    CarBookingScheduleRemoveInput,
    CarBookingScheduleUpdateInput
} from "@modules/graphql/management/car/dto/schedule.booking.car.args";
import { CarBookingSchedule } from "@models/entities/car.booking.schedule";
import { RequestContext } from "@common/context/request.context";
import { OfficeError } from "@common/office.error";
import { CarBookingRequest } from "@models/entities/car.booking.request";
import { BookingCarScheduleRepo, NotificationCampaignRepo } from "@models/repositories";
import { CarService } from "@modules/graphql/management/car/car.service";

@Injectable()
export class ScheduleBookingCarService {

    constructor(
        private readonly carService: CarService,
        private readonly scheduleRepo: BookingCarScheduleRepo,
        private readonly notificationCampaignRepo: NotificationCampaignRepo,
    ) {
    }

    adminCarBookingScheduleUpdate(args: CarBookingScheduleUpdateInput) {
        return this.carBookingScheduleUpdate(args)
    }

    async userCarBookingScheduleUpdate(args: CarBookingScheduleUpdateInput) {
        if (RequestContext.isNormalUser()) {
            await this.checkNormalUserCanModifyBooking(args.schedule.booking)
        }

        return this.carBookingScheduleUpdate(args)
    }

    async checkNormalUserCanModifyBooking(booking: CarBookingRequest) {
        if (booking.createdBy !== await RequestContext.currentId()) {
            throw OfficeError.NotAllow
        }
    }

    private async carBookingScheduleUpdate(args: CarBookingScheduleUpdateInput) {
        const schedule = args.schedule


        schedule.startAt = new Date(args.startAt) ?? schedule.startAt
        schedule.endAt = new Date(args.endAt) ?? schedule.endAt
        schedule.fromAddress = args.fromAddress ?? schedule.fromAddress
        schedule.toAddress = args.toAddress ?? schedule.toAddress
        schedule.note = args.note ?? schedule.note
        schedule.carId = args.carId ?? schedule.carId

        if (args.notify) {
            await this.bookingScheduleNotifyUpsert(args.notify, schedule)
        }

        await schedule.save()
        await schedule.reload()

        return schedule
    }

    private async bookingScheduleNotifyUpsert(notify: any, schedule: CarBookingSchedule) {

    }

    adminCarBookingScheduleRemove(args: CarBookingScheduleRemoveInput) {
        return this.carBookingScheduleRemove(args)
    }

    async userCarBookingScheduleRemove(args: CarBookingScheduleRemoveInput) {
        if (RequestContext.isNormalUser()) {
            await this.checkNormalUserCanModifyBooking(args.schedule.booking)
        }

        return this.carBookingScheduleRemove(args)
    }

    private async carBookingScheduleRemove(args: CarBookingScheduleRemoveInput) {
        const schedule = args.schedule

        const listAllScheduleOfBooking = await this.scheduleRepo.getAllOfMeetingId(schedule.requestId)

        if (listAllScheduleOfBooking.length === 1) {
            await this.carService.bookingRemove({
                id: schedule.requestId,
                description: args.description
            }, schedule.booking)
        } else {
            const notifyBooking = await this.notificationCampaignRepo.getBookingCarById(schedule.requestId)
            schedule.cancelDescription = args.description ?? null
            await schedule.save()
            await schedule.softRemove()

            if (notifyBooking) await notifyBooking.softRemove()
        }

        return args.scheduleId
    }
}
