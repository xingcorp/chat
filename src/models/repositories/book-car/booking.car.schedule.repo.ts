import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { CarBookingSchedule } from "@models/entities/car.booking.schedule";
import { CarBookingRequest, RequestStatus } from "@models/entities/car.booking.request";
import { OfficeBookingCarArgs } from "@modules/graphql/management/car/dto/car.args";

@Injectable()
export class BookingCarScheduleRepo extends Repository<CarBookingSchedule> {
    constructor(private dataSource: DataSource) {
        super(CarBookingSchedule, dataSource.createEntityManager());
    }

    async isCarAvailableBy(where: any[]) {
        const bookingSchedules = await this.createQueryBuilder('qb')
            .leftJoinAndMapOne('qb.request', CarBookingRequest, 'request', 'qb."requestId"::text = request.id::text')
            .where(where)
            .andWhere(`request.status IN (:...status)`, {status: [RequestStatus.UnderReview, RequestStatus.Approved, RequestStatus.Recalled]})
            .getMany()

        return !bookingSchedules.length
    }

    createMany(param: {
        schedulePeriods: { startAt: Date; endAt: Date }[];
        args: OfficeBookingCarArgs;
        currentId: string
    }) {
        const {schedulePeriods, args, currentId} = param

        return schedulePeriods.map(i => this.create({
            startAt: i.startAt,
            endAt: i.endAt,
            carId: args.carId,
            fromAddress: args.fromAddress,
            toAddress: args.toAddress,
            note: args.note,
            createdBy: currentId,
            updatedBy: currentId
        }))
    }

    async getAllOfMeetingId(requestId: string) {
        return this.find({
            where: {
                requestId
            }
        })
    }
}