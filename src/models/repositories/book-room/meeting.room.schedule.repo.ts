import { Injectable } from "@nestjs/common";
import { Between, DataSource, Repository } from "typeorm";
import { BookingMeetingRoom, MeetingRoomSchedule } from "@models/entities";
import { BookMeetingRoomArgs } from "@modules/graphql/booking/dto/booking.args";
import { datetimeDateEndOfToMinuteGet, datetimeDateRoundToMinuteGet } from "@utils/datetime.utils";

@Injectable()
export class MeetingRoomScheduleRepo extends Repository<MeetingRoomSchedule> {
    constructor(private dataSource: DataSource) {
        super(MeetingRoomSchedule, dataSource.createEntityManager());
    }

    async createMany(param: {
        args: BookMeetingRoomArgs;
        booking: BookingMeetingRoom;
        schedulePeriods: { endAt: Date; startAt: Date }[];
    }) {
        const {args, booking, schedulePeriods} = param

        return schedulePeriods.map(i => this.create({
            startAt: i.startAt,
            endAt: i.endAt,
            meetingRoom: args.meetingRoom,
            booking,
            logistics: args.logistics ?? null,
            equiments: args.equiments ?? null,
            meetingContent: args.meetingContent ?? null,
            host: args.host ?? null,
            participants: args.participants ?? null,
            quantity: args.quantity ?? null,
            note: args.note ?? null,
        }))
    }

    async getAllOfMeetingId(bookingId: string) {
        return this.find({
            where: {
                bookingId
            }
        })
    }

    async getBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getOne()
    }

    async getAllStartAt(date: Date) {
        return this.find({
            relations: ['host', 'participants', 'booking', 'meetingRoom'],
            where: {
                startAt: Between(datetimeDateRoundToMinuteGet(date), datetimeDateEndOfToMinuteGet(date))
            }
        })
    }
}