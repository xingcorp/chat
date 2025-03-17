import { Injectable } from "@nestjs/common";
import { InjectConnection } from "@nestjs/typeorm";
import { CarBookingRequest, RequestStatus } from "src/models/entities/car.booking.request";
import { CarBookingSchedule } from "src/models/entities/car.booking.schedule";
import {
    Between,
    Brackets,
    Connection,
    ILike,
    In,
    IsNull,
    LessThan,
    LessThanOrEqual,
    MoreThan,
    MoreThanOrEqual,
    Not
} from "typeorm";
import {Car} from "../../../../models/entities/car";
import { CarBookingScheduleFilter, OfficeActiveCarFilter, OfficeBookingCarArgs, OfficeCarFilter } from "./dto/car.args";
import { OfficeOrgChartRepo } from "@models/repositories/office-org-chart.repo";
import { OfficeSysUserRepo } from "@models/repositories/office-sys-user.repo";
import { BookingCarScheduleRepo, DateCloneRepo, NotificationCampaignRepo, OfficeUserRepo } from "@models/repositories";
import { OfficeError } from "@common/office.error";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { OfficeOrgChart } from "@models/entities";
import { RequestContext } from "@common/context/request.context";
import { RandomHelper } from "@common/random";
import { ApprovalSource, ApprovalStatus } from "@models/entities/approval";
import { ApprovalSubmitTypeEnum } from "@enum/approval/approval/approval.enum";
import { ApprovalService } from "@modules/graphql/approval/approval.service";
import { datetimeOfLocalDay, datetimeSetTime, datetimeStartOfLocalDay } from "@utils/datetime.utils";
import { CloneDatePeriodEnum } from "@enum/clone/date.clone.enum";
import { NotifyMessageTitle } from "@common/notify.message";
import { NotificationService } from "@core/iam/notification/notification.service";

@Injectable()
export class CarService {
    constructor(
        @InjectConnection()
        private readonly connection: Connection,

        private readonly approvalService: ApprovalService,
        private readonly notificationService: NotificationService,
        private orgChartRepository: OfficeOrgChartRepo,
        private officeSysUserRepo: OfficeSysUserRepo,
        private bookingCarScheduleRepo: BookingCarScheduleRepo,
        private readonly dateCloneRepo: DateCloneRepo,
        private readonly officeUserRepo: OfficeUserRepo,
        private readonly scheduleRepo: BookingCarScheduleRepo,
        private readonly notificationCampaignRepo: NotificationCampaignRepo,
    ) { }

    public scheduleIsExist = async (
        carId: string,
        startAt: Date,
        endAt: Date
    ) => {
        const approvedRequests = await CarBookingRequest.find({
            where: [
                {
                    carId: carId,
                    status: RequestStatus.Approved,
                    startAt: Between(startAt, endAt)
                },
                {
                    carId: carId,
                    status: RequestStatus.Approved,
                    endAt: Between(startAt, endAt)
                }
            ]
        })
        const commonWhere: any = { carId: carId, requestId: In(approvedRequests.map(rq => rq.id)) }
        const exist = await CarBookingSchedule.findOne({
            where: [
                {
                    ...commonWhere,
                    startAt: Between(startAt, endAt)
                },
                {
                    ...commonWhere,
                    endAt: Between(startAt, endAt)
                }
            ]
        })

        return exist ? true : false
    }

    public async officeGetCars(filter: OfficeCarFilter, requesterId: string) {
        filter.size = filter.size ? filter.size : 20 //2
        filter.page = filter.page ? (filter.page - 1) : 0

        let query = Car.createQueryBuilder('car')
            .where({})
            .take(filter.size)
            .skip(filter.page * filter.size)
            .orderBy('car.createdAt', 'DESC')

        const oogIds = RequestContext.currentListOrgIds()

        query.andWhere(`car."orgChartId"::text IN (:...oogIds)`, {oogIds})

        if (filter && filter.status) {
            query = query.andWhere({ status: filter.status })
        }

        if (filter && filter.model) {
            query = query.andWhere({ model: filter.model })
        }

        if (filter && filter.orgChartId) {
            query = query.andWhere({ orgChartId: filter.orgChartId })
        }

        if (filter && filter.approvalFormId) {
            query = query.andWhere({ approvalFormId: filter.approvalFormId })
        }

        if (filter && filter.keyword) {
            query =
                query.andWhere(new Brackets(db => {
                    db.where(`unaccent(LOWER(car.model)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                        .orWhere(`unaccent(LOWER(car.code)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                        .orWhere(`unaccent(LOWER(car.plateNumber)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                }))
        }

        return query.getManyAndCount()
    }

    // async checkCarAvailable(meetingRoomId: string, startTime: Date, endTime: Date): Promise<boolean> {
    //     if (startTime >= endTime) {
    //         throw new BaseError('Office.MeetingRoomNotAvailable', 'Thời gian đặt không phù hợp')
    //     }

    //     // TH1: -------startTime-------start--------------end-------endTime-------');
    //     let bookings = await MeetingRoomSchedule.findOne({
    //         where: {
    //             meetingRoomId: meetingRoomId,
    //             startAt: MoreThanOrEqual(startTime),
    //             endAt: LessThanOrEqual(endTime),
    //         },
    //     });

    //     if (!bookings) {
    //         // TH2: --------------start----startTime------endTime----end--------------');
    //         bookings = await MeetingRoomSchedule.findOne({
    //             where: {
    //                 meetingRoomId: meetingRoomId,
    //                 startAt: LessThanOrEqual(startTime),
    //                 endAt: MoreThanOrEqual(endTime),
    //             },
    //         });
    //     }

    //     if (!bookings) {
    //         // TH3: --------------start------startTime--------end-------endTime-------');
    //         bookings = await MeetingRoomSchedule.findOne({
    //             where: {
    //                 meetingRoomId: meetingRoomId,
    //                 startAt: LessThanOrEqual(startTime),
    //                 endAt: Between(startTime, endTime),
    //             },
    //         });
    //     }

    //     if (!bookings) {
    //         // TH:4 -------startTime-------start------endTime--------end--------------');
    //         bookings = await MeetingRoomSchedule.findOne({
    //             where: {
    //                 meetingRoomId: meetingRoomId,
    //                 startAt: Between(startTime, endTime),
    //                 endAt: MoreThanOrEqual(endTime),
    //             },
    //         });
    //     }
    //     return !!!bookings// If no bookings overlap, the room is available
    // }
    async validateCarSchedule(schedules: CarBookingSchedule[]) {
        const where = []
        for (const schedule of schedules) {
            where.push({
                startAt: LessThan(new Date(schedule.endAt)),
                endAt: MoreThan(new Date(schedule.startAt)),
                carId: schedule.carId,
            })
        }

        const isValidate = await this.bookingCarScheduleRepo.isCarAvailableBy(where)

        if (!isValidate) {
            throw OfficeError.BookingCarNotAvailable
        }
    }

    async officeGetActiveCars(filter: OfficeActiveCarFilter) {
        filter.size = filter.size ? filter.size : 20 //1
        filter.page = filter.page ? (filter.page - 1) : 0

        const query = Car.createQueryBuilder('qb')
            .where({
                status: ObjectStatus.Active,
                approvalFormId: Not(IsNull())
            })
            .take(filter.size)
            .skip(filter.page * filter.size)
            .orderBy('qb.createdAt', 'DESC')

        /*SOF-2034*/
        let oogIds: string[] = []

        if (RequestContext.isNormalUser()) {
            oogIds = RequestContext.currentOrgData('listOrgIdWParentAndChild')
        } else {
            oogIds = RequestContext.currentOrgData('listOrgIdWChild')
        }

        query.andWhere(`qb."orgChartId"::text IN (:...oogIds)`, {oogIds})

        if (filter && filter.keyword) {
            query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(qb.model)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(qb.plateNumber)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
            }))
        }

        if (filter && filter.companyId) {
            const companyDepartments = await OfficeOrgChart.find({ where: { path: ILike(`%${filter.companyId}%`) } })

            query.andWhere({
                orgChartId: In(companyDepartments.map(d => d.id))
            })
        }

        const [list, count] = await query.getManyAndCount()

        return {
            total: count,
            count: list.length,
            cars: list
        }
    }

    async officeCarBookingGetScheduleList(filter: CarBookingScheduleFilter) {

        // https://jr.smarthiz.vn/browse/SOF-387
        // filter.size = filter.size ? filter.size : 20 //1
        // filter.page = filter.page ? (filter.page - 1) : 0

        const query = CarBookingSchedule.createQueryBuilder('qb')
            .leftJoinAndMapOne('qb.car', Car, 'car', 'car.id::text = qb."carId"::text')
            .where({})
            // .take(filter.size)
            // .skip(filter.page * filter.size)
            .orderBy('qb.startAt', 'ASC')

        if (filter) {
            const fromDate = filter.fromDate ? new Date(filter.fromDate) : new Date(0);
            const toDate = filter.toDate ? new Date(filter.toDate) : new Date('12/31/9999');

            query.andWhere([
                {
                    startAt: Between(fromDate, toDate),
                },
                {
                    endAt: Between(fromDate, toDate),
                },
                {
                    startAt: LessThanOrEqual(fromDate),
                    endAt: MoreThanOrEqual(toDate),
                }
            ])
        }

        if (filter && filter.owner === true) {
            query.andWhere({
                createdBy: await RequestContext.currentId()
            })
        }

        if (filter && filter.carIds) {
            query.andWhere({
                carId: In(filter.carIds)
            })
        }

        const oogIds = RequestContext.currentListOrgIds()

        query.andWhere(`car."orgChartId"::text IN (:...oogIds)`, {oogIds})

        // console.log('query', query.getQueryAndParameters())

        const [list, count] = await query.getManyAndCount()

        return {
            total: count,
            count: list.length,
            schedules: list
        }
    }

    async officeCarBookingRequestLegacy(args: OfficeBookingCarArgs) {
        const officeId = await RequestContext.currentId()
        const existedCar = await Car.findOne({ where: { id: args.carId } })
        if (!existedCar) throw OfficeError.OfficeCarNotExisted

        const startAt = new Date(args.startAt)
        startAt.setMilliseconds(0)
        startAt.setSeconds(0)

        const endAt = new Date(args.endAt)
        endAt.setMinutes(endAt.getMinutes() - 1)
        endAt.setMilliseconds(999)
        endAt.setSeconds(59)
        if (endAt < startAt) throw OfficeError.EndTimeCannotLessThanStartTime

        if (await this.scheduleIsExist(existedCar.id, startAt, endAt)) {
            throw OfficeError.CarBookingScheduleOverlap
        }

        const bookingRequest = CarBookingRequest.create({
            id: RandomHelper.generateUUID(),
            startAt: startAt,
            endAt: endAt,
            carId: existedCar.id,
            fromAddress: args.fromAddress,
            toAddress: args.toAddress,
            note: args.note,
            createdBy: officeId,
            updatedBy: officeId
        })

        const bookingSchedule = CarBookingSchedule.create({
            id: RandomHelper.generateUUID(),
            startAt: startAt,
            endAt: endAt,
            carId: existedCar.id,
            requestId: bookingRequest.id,
            createdBy: officeId,
            updatedBy: officeId
        })

        await this.validateCarSchedule([bookingSchedule])

        if (existedCar.approvalFormId) {
            //tạo luồng phê duyệt & gắn approvalId
            const approval = await this.approvalService.submitApproval({
                source: ApprovalSource.Template,
                name: null,
                note: args.note,
                formId: existedCar.approvalFormId,
                formFieldData: args.formFieldData,
                structure: null,
                imageIds: null,
                attachmentIds: null,
                subscriberIds: args.subscriberIds,
                submitType: ApprovalSubmitTypeEnum.Submit
            }, bookingRequest.id)
            bookingRequest.approvalId = approval.id
            if (approval.status === ApprovalStatus.Approved) bookingRequest.status = RequestStatus.Approved
        } else {
            bookingRequest.status = RequestStatus.Approved
        }

        await bookingSchedule.save()
        return bookingRequest.save()
    }

    async officeCarBookingRequest(args: OfficeBookingCarArgs) {
        /*create booking*/
        const booking = await this.bookCarCreate(args)

        /*create schedule*/
        const schedules = await this.bookCarScheduleCreate(args, booking)


        await booking.save()

        /*approval*/
        await this.bookCarApprovalCreate(args, booking)

        /*notify*/
        if (args.notify) {
            await this.createNotifyBooking(args, booking)
        }

        await booking.save()

        for (const schedule of schedules) {
            schedule.requestId = booking.id
            schedule.booking = booking
            await schedule.save()
        }

        if (args.repeatConfig && args.repeatConfig.endAt) {
            const dateClone = this.bookCarDateCloneCreate(args, booking)

            await dateClone.save()
        }

        await booking.reload()

        return booking
    }

    private async bookCarCreate(args: OfficeBookingCarArgs) {
        const car = args.car
        const currentId = await RequestContext.currentId()

        return CarBookingRequest.create({
            startAt: new Date(args.startAt),
            endAt: new Date(args.endAt),
            carId: car.id,
            fromAddress: args.fromAddress,
            toAddress: args.toAddress,
            note: args.note,
            createdBy: currentId,
            updatedBy: currentId
        })
    }

    private async bookCarScheduleCreate(args: OfficeBookingCarArgs, booking: CarBookingRequest) {
        const currentId = await RequestContext.currentId()
        let schedulePeriods: { startAt: Date, endAt: Date }[]

        if (!args.repeatConfig || !args.repeatConfig.endAt) {
            schedulePeriods = [{
                startAt: new Date(args.startAt),
                endAt: new Date(args.endAt)
            }]
        } else {
            const scheduleDate = await this.carScheduleDateGet(args)
            schedulePeriods = await this.carSchedulePeriodGet(args, scheduleDate)
        }

        await this.validateScheduleTime(args, schedulePeriods)

        return this.bookingCarScheduleRepo.createMany({
            args,
            schedulePeriods,
            currentId
        })
    }

    private async carScheduleDateGet(args: OfficeBookingCarArgs) {
        const repeatConfig = args.repeatConfig
        const startTimestamp = Math.max(repeatConfig.startAt ?? args.startAt, Date.now())
        const endTimestamp = repeatConfig.endAt

        const currentDate = datetimeStartOfLocalDay(startTimestamp)
        const weekDays = this.dateCloneRepo.getWeekDayNumber(repeatConfig.weekDays)

        const res = []
        while (currentDate.getTime() <= endTimestamp) {

            switch (repeatConfig.periodType) {
                case CloneDatePeriodEnum.Daily:
                    res.push(structuredClone(currentDate))
                    break
                case CloneDatePeriodEnum.Weekly:
                    if (weekDays.includes(currentDate.getDay())) res.push(structuredClone(currentDate))
                    break
                case CloneDatePeriodEnum.Monthly:
                    if (repeatConfig.monthDays.includes(currentDate.getDate())) res.push(structuredClone(currentDate))
                    break
            }

            currentDate.setDate(currentDate.getDate() + 1);
        }

        return res
    }

    private async carSchedulePeriodGet(args: OfficeBookingCarArgs, scheduleDate: any[]) {
        const start = datetimeOfLocalDay(args.startAt)
        const end = datetimeOfLocalDay(args.endAt)

        return scheduleDate.map(i => ({
            startAt: datetimeSetTime(i, start.getHours(), start.getMinutes(), start.getSeconds()),
            endAt: datetimeSetTime(i, end.getHours(), end.getMinutes(), end.getSeconds())
        }))
    }

    private async validateScheduleTime(args: OfficeBookingCarArgs, schedulePeriods: { startAt: Date; endAt: Date }[]) {
        const where = []
        for (const schedule of schedulePeriods) {
            where.push({
                startAt: LessThan(schedule.endAt),
                endAt: MoreThan(schedule.startAt),
                carId: args.carId,
            })
        }

        const isValidate = await this.bookingCarScheduleRepo.isCarAvailableBy(where)

        if (!isValidate) {
            throw OfficeError.BookingCarNotAvailable
        }
    }

    private async bookCarApprovalCreate(args: OfficeBookingCarArgs, booking: CarBookingRequest) {
        const car = args.car

        if (car.approvalFormId && RequestContext.isNormalUser()) {
            try {
                //tạo luồng phê duyệt & gắn approvalId
                const approval = await this.approvalService.submitApproval({
                    source: ApprovalSource.Template,
                    name: null,
                    note: args.note,
                    formId: car.approvalFormId,
                    formFieldData: args.formFieldData,
                    structure: null,
                    imageIds: null,
                    attachmentIds: null,
                    subscriberIds: args.subscriberIds,
                    submitType: ApprovalSubmitTypeEnum.Submit
                }, booking.id)
                booking.approvalId = approval.id
                if (approval.status === ApprovalStatus.Approved) booking.status = RequestStatus.Approved
            } catch (e) {
                console.log('erre', e)
            }
        } else {
            booking.status = RequestStatus.Approved
        }
    }

    private async createNotifyBooking(args: OfficeBookingCarArgs, booking: CarBookingRequest) {
        args.notify.title = NotifyMessageTitle.BookingRoomNotify()
        args.notify.notifyTypeId = booking.id
        args.notify.phones = await this.officeUserRepo.listPhoneById([booking.createdBy])

        return this.notificationService.createNotificationBookingCar({
            requesterId: RequestContext.currentRequestId(),
            token: RequestContext.currentToken()
        }, args.notify)
    }

    private bookCarDateCloneCreate(args: OfficeBookingCarArgs, booking: CarBookingRequest) {
        return this.dateCloneRepo.bookingCarCreate({
            relationId: booking.id,
            startAt: args.startAt,
            endAt: args.endAt,
            repeatConfig: args.repeatConfig,
        })
    }

    async bookingRemove(args: { description: string; id: string }, booking: CarBookingRequest) {
        booking.updatedBy = RequestContext.isNormalUser() ? await RequestContext.currentId() : null
        booking.cancelDescription = args.description

        const schedule = await this.scheduleRepo.findOneBy({ requestId: booking.id })
        const notifyBooking = await this.notificationCampaignRepo.getBookingCarById(booking.id)

        schedule.updatedBy = RequestContext.isNormalUser() ? await RequestContext.currentId() : null
        schedule.cancelDescription = args.description

        await this.approvalService.removeById(booking.approvalId)

        await booking.save()
        await schedule.softRemove()
        await booking.softRemove()

        if (notifyBooking) await notifyBooking.softRemove()

        return args.id
    }
}