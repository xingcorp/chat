import { Injectable } from "@nestjs/common";
import {
    Brackets,
    DataSource, In, IsNull,
    LessThanOrEqual,
    MoreThanOrEqual, Not, Or,
    Repository
} from "typeorm";
import { CloneByDate } from "@models/entities";
import { CloneDatePeriodEnum, CloneDateTypeEnum } from "@enum/clone/date.clone.enum";
import {
    datetimeGetDayOfWeekTitleShort,
    datetimeOfLocalDay,
    datetimeStartTimeInMinutesGet
} from "@utils/datetime.utils";
import { EquimentsForMettingRoom, LogisticsForMettingRoom } from "@models/entities/meeting.room.schedule";
import { BookMeetingRoomRepeatConfigInput } from "@modules/graphql/booking/dto/booking.args";
import { TaskStatus } from "@enum/task/task.enum";
import { BookCarRepeatConfigInput } from "@modules/graphql/management/car/dto/car.args";
import { DayOfWeek } from "@common/constant.common";

@Injectable()
export class DateCloneRepo extends Repository<CloneByDate> {
    constructor(private dataSource: DataSource) {
        super(CloneByDate, dataSource.createEntityManager());
    }

    taskReportConfigGetOneBy(whereBy: object) {
        return this.findOne({
            where: {
                relationType: CloneDateTypeEnum.TaskReportConfig,
                ...whereBy
            }
        })
    }

    async getAllHaveCloneRightNowByRelationType(relationType: CloneDateTypeEnum): Promise<CloneByDate[]> {
        const now = new Date();
        const nowLocal = datetimeOfLocalDay(now)
        now.setMilliseconds(0)
        now.setSeconds(0)

        const startTimeInMinutes = [datetimeStartTimeInMinutesGet(now)]

        const query = this.createQueryBuilder('qb')
            .where("qb.relationType = :relationType", { relationType })
            .andWhere(
                '("qb"."startAt" IS NULL OR "qb"."startAt" <= :now) AND ("qb"."endAt" IS NULL OR "qb"."endAt" >= :now)',
                { now }
            )
            .andWhere(`STRING_TO_ARRAY(qb."startTimeIn", ',') && ARRAY[:...startTimeInMinutes]`, {startTimeInMinutes})
            .andWhere(new Brackets(db => {
                db
                    .where({
                        periodType: CloneDatePeriodEnum.Daily
                    })
                    .orWhere(new Brackets(db2 => {
                        db2
                            .where({
                                periodType: CloneDatePeriodEnum.Weekly
                            })
                            .andWhere(`STRING_TO_ARRAY(qb."weekDays", ',') && ARRAY[:...weekDays]`, { weekDays: [datetimeGetDayOfWeekTitleShort(nowLocal)] })
                    }))
                    .orWhere(new Brackets(db2 => {
                        db2
                            .where({
                                periodType: CloneDatePeriodEnum.Monthly
                            })
                            .andWhere(`STRING_TO_ARRAY(qb."monthDays", ',') && ARRAY[:...monthDays]`, { monthDays: [nowLocal.getDate()] })
                    }))
                    .orWhere(new Brackets(db2 => {
                        db2
                            .where({
                                periodType: CloneDatePeriodEnum.Custom
                            })
                            .andWhere(`qb."customDaysSearch" LIKE :customDaysSearch`, { customDaysSearch: `%${nowLocal.getMonth()}-${nowLocal.getDate()}%` })
                    }))
            }))

        // console.log('getAllHaveCloneRightNowByRelationType query', query.getQueryAndParameters())

        return query.getMany()
    }

    getWeekDayNumber(weekDays: DayOfWeek[]): number[] {
        if (!weekDays) {
            return []
        }

        return weekDays.map(w => {
            if (w === DayOfWeek.Sun) {
                return 0
            } else if (w === DayOfWeek.Mon) {
                return 1
            } else if (w === DayOfWeek.Tue) {
                return 2
            } else if (w === DayOfWeek.Wed) {
                return 3
            } else if (w === DayOfWeek.Thu) {
                return 4
            } else if (w === DayOfWeek.Fri) {
                return 5
            } else if (w === DayOfWeek.Sat) {
                return 6
            }
        })
    }

    bookingMeetingRoomCreate(param: {
        logistics: LogisticsForMettingRoom[];
        relationId: string;
        endAt: number;
        repeatConfig: BookMeetingRoomRepeatConfigInput;
        startAt: number;
        equiments: EquimentsForMettingRoom[]
    }) {
        const { logistics, relationId, endAt, repeatConfig, startAt, equiments } = param

        return this.create({
            relationType: CloneDateTypeEnum.BookingMeetingRoom,
            relationId,
            relationData: {
                startAt,
                endAt,
                logistics,
                equiments
            },
            ...repeatConfig,
            startAt: new Date(Math.max(repeatConfig.startAt ?? startAt, Date.now())),
            endAt: new Date(repeatConfig.endAt),
        })
    }

    bookingCarCreate(param: {
        relationId: string;
        endAt: number;
        repeatConfig: BookCarRepeatConfigInput;
        startAt: number
    }) {
        const { relationId, endAt, repeatConfig, startAt } = param

        return this.create({
            relationType: CloneDateTypeEnum.BookingMeetingRoom,
            relationId,
            relationData: {
                startAt,
                endAt,
            },
            ...repeatConfig,
            startAt: new Date(Math.max(repeatConfig.startAt ?? startAt, Date.now())),
            endAt: new Date(repeatConfig.endAt),
        })
    }
}