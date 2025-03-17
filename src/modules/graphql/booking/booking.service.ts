import { forwardRef, Inject, Injectable } from "@nestjs/common";
import {
  BookingMeetingRoom,
  MeetingRoom,
  MeetingRoomSchedule,
  OfficeUser
} from "@models/entities";
import { Between, Brackets, DataSource, In, LessThan, LessThanOrEqual, MoreThan, MoreThanOrEqual } from "typeorm";
import { BaseError } from "@core/core.error";
import { OfficeError } from "@common/office.error";
import {
  BookMeetingRoomArgs,
  CaseQueryMeeting,
  DeleteBookingMeetingRoomArgs,
  NotificationBookingMeetingRoomArgs,
  QueryBookingMeetingRoomArgs,
  UpdateBookingMeetingRoomArgs
} from "./dto/booking.args";
import { RepeatedDay } from "@models/entities/booking/booking.meeting.room";
import { RequestStatus } from "src/models/entities/car.booking.request";
import { EquimentsForMettingRoom, LogisticsForMettingRoom } from "@models/entities/meeting.room.schedule";
import { RandomHelper } from "@common/random";
import { ApprovalSource, ApprovalStatus } from "@models/entities/approval";
import { ApprovalService } from "@modules/graphql/approval/approval.service";
import { NotificationService } from "@core/iam/notification/notification.service";
import {
  BookingMeetingRoomRepo, DateCloneRepo,
  MeetingRoomScheduleRepo,
  OfficeOrgChartRepo,
  OfficeUserRepo
} from "@models/repositories";
import { NotifyMessageTitle } from "@common/notify.message";
import { RequestContext } from "@common/context/request.context";
import { NotificationCampaignDifferentArgs } from "@core/iam/notification/notification.args";
import { NotificationCampaignRepo } from "@repositories/notification/notification.campaign.repo";
import { ApprovalSubmitTypeEnum } from "@enum/approval/approval/approval.enum";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import {
  datetimeLocalGetDate, datetimeLocalGetDay,
  datetimeStartOfLocalDay, datetimeOfLocalDay, datetimeSetTime, datetimeAddTimestamp
} from "@utils/datetime.utils";
import { CloneDatePeriodEnum } from "@enum/clone/date.clone.enum";
import { BRIDGE_TABLE_DB } from "@common/db/bridge-table.db";

@Injectable()
export class BookingService {
  constructor(
      private dataSource: DataSource,
      @Inject(forwardRef(() => ApprovalService))
      private readonly approvalService: ApprovalService,
      private readonly notificationService: NotificationService,
      private readonly officeUserRepo: OfficeUserRepo,
      private readonly bookingMeetingRoomRepo: BookingMeetingRoomRepo,
      private readonly meetingRoomScheduleRepo: MeetingRoomScheduleRepo,
      private readonly notificationCampaignRepo: NotificationCampaignRepo,
      private readonly orgChartRepo: OfficeOrgChartRepo,
      private readonly dateCloneRepo: DateCloneRepo,
  ) {
  }

  async checkMeetingRoomAvailable(meetingRoomId: string, startTime: Date, endTime: Date): Promise<boolean> {
    if (startTime >= endTime) {
      throw new BaseError('Office.MeetingRoomNotAvailable', 'Thời gian đặt không phù hợp')
    }

    let approvedRequests = await BookingMeetingRoom.find({
      where: {
        meetingRoomId: meetingRoomId,
        status: RequestStatus.Approved,
        startAt: MoreThanOrEqual(startTime),
        endAt: LessThanOrEqual(endTime),
      }
    })
    // TH1: -------startTime-------start--------------end-------endTime-------');
    let bookings = await MeetingRoomSchedule.findOne({
      where: {
        meetingRoomId: meetingRoomId,
        startAt: MoreThanOrEqual(startTime),
        endAt: LessThanOrEqual(endTime),
        bookingId: In(approvedRequests.map(r => r.id))
      },
    });

    if (!bookings) {
      approvedRequests = await BookingMeetingRoom.find({
        where: {
          meetingRoomId: meetingRoomId,
          status: RequestStatus.Approved,
          startAt: LessThanOrEqual(startTime),
          endAt: MoreThanOrEqual(endTime),
        }
      })
      // TH2: --------------start----startTime------endTime----end--------------');
      bookings = await MeetingRoomSchedule.findOne({
        where: {
          meetingRoomId: meetingRoomId,
          startAt: LessThanOrEqual(startTime),
          endAt: MoreThanOrEqual(endTime),
          bookingId: In(approvedRequests.map(r => r.id))
        },
      });
    }

    if (!bookings) {
      approvedRequests = await BookingMeetingRoom.find({
        where: {
          meetingRoomId: meetingRoomId,
          status: RequestStatus.Approved,
          startAt: LessThanOrEqual(startTime),
          endAt: Between(startTime, endTime),
        }
      })
      // TH3: --------------start------startTime--------end-------endTime-------');
      bookings = await MeetingRoomSchedule.findOne({
        where: {
          meetingRoomId: meetingRoomId,
          startAt: LessThanOrEqual(startTime),
          endAt: Between(startTime, endTime),
          bookingId: In(approvedRequests.map(r => r.id))
        },
      });
    }

    if (!bookings) {
      approvedRequests = await BookingMeetingRoom.find({
        where: {
          meetingRoomId: meetingRoomId,
          status: RequestStatus.Approved,
          startAt: Between(startTime, endTime),
          endAt: MoreThanOrEqual(endTime),
        }
      })
      // TH:4 -------startTime-------start------endTime--------end--------------');
      bookings = await MeetingRoomSchedule.findOne({
        where: {
          meetingRoomId: meetingRoomId,
          startAt: Between(startTime, endTime),
          endAt: MoreThanOrEqual(endTime),
          bookingId: In(approvedRequests.map(r => r.id))
        },
      });
    }
    return !!!bookings// If no bookings overlap, the room is available
  }

  async verifyParticipantIds(participantIds: string[]) {
    const participants = await OfficeUser.find({
      where: { id: In(participantIds) },
      select: ["id", "fullname"]
    })
    const foundIds = participants.reduce((prev, current) => {
      prev.push(current.id)
      return prev
    }, [])

    const notFoundIds = participantIds.reduce((prev, currentId) => {
      if (!foundIds.includes(currentId)) {
        prev.push(currentId)
      }
      return prev
    }, [])

    if (notFoundIds.length > 0) {
      throw new BaseError(
        OfficeError.EmployeeNotFound.code,
        OfficeError.EmployeeNotFound.baseMsg,
        { ids: notFoundIds }
      )
    }
    return participants
  }

  private async createNotifyBooking(param: {
    requesterId: string;
    token: string
  }, args: BookMeetingRoomArgs, booking: BookingMeetingRoom) {
    args.notify.title = NotifyMessageTitle.BookingRoomNotify()
    args.notify.notifyTypeId = booking.id
    args.notify.phones = await this.officeUserRepo.listPhoneById([booking.hostId, ...booking.participantIds, booking.bookedById])

    return this.notificationService.createNotificationBookingRoom(param, args.notify)
  }

  private async updateNotifyBooking(args: NotificationCampaignDifferentArgs, booking: BookingMeetingRoom) {
    args.phones = await this.officeUserRepo.listPhoneById([booking.hostId, ...booking.participantIds, booking.bookedById])
    args.userIds = await this.officeUserRepo.listFieldById([booking.hostId, ...booking.participantIds, booking.bookedById], 'id')
    args.notifyTypeId = booking.id
    args.title = args.title ?? NotifyMessageTitle.BookingRoomUpdate()

    return this.notificationService.updateNotificationBookingRoom(args)
  }

  async createMeetingRoomSchedule(args: {
    startAt: Date,
    endAt: Date,
    meetingRoomId: string,
    bookingId: string,
    repeatedEndAt: Date,
    repeatedDays: RepeatedDay[],
    equiments: EquimentsForMettingRoom[],
    logistics: LogisticsForMettingRoom[]
  }): Promise<MeetingRoomSchedule[]> {
    const {
      startAt,
      endAt,
      meetingRoomId,
      bookingId,
      equiments,
      logistics
    } = args
    const meetingRoom = await MeetingRoom.findOne({ where: { id: meetingRoomId } });
    if (!meetingRoom) throw OfficeError.MeetingRoomNotFound;

    const repeatedEndAt = args.repeatedEndAt ? args.repeatedEndAt : endAt;
    const repeatedDays = args.repeatedDays && args.repeatedDays.length > 0
      ? args.repeatedDays
      : [startAt.getDay()];

    const periodBetweenStartAndEnd = endAt.getTime() - startAt.getTime()
    let newStartAt = startAt;
    let newEndAt = endAt;

    if (startAt >= repeatedEndAt) {
      throw new BaseError('Office.MeetingRoomNotAvailable', 'Thời gian đặt không phù hợp')
    }
    const batchBooking: MeetingRoomSchedule[] = []
    const batchError = []

    while (startAt <= repeatedEndAt) {
      const dayOfWeek = startAt.getDay();

      if (repeatedDays.includes(dayOfWeek)) {
        newStartAt = new Date(startAt)
        newEndAt = new Date(newStartAt.getTime() + periodBetweenStartAndEnd)

        const isRoomAvailable = await this.checkMeetingRoomAvailable(
          meetingRoomId,
          newStartAt,
          newEndAt
        )
        if (!isRoomAvailable) {
          batchError.push(`Lịch phòng họp ngày ${newStartAt.toLocaleString()} đã được đặt!`)
        }
        batchBooking.push(
          MeetingRoomSchedule.create({
            startAt: newStartAt,
            endAt: newEndAt,
            meetingRoomId: meetingRoomId,
            meetingRoom: meetingRoom,
            bookingId: bookingId,
            equiments: equiments || null,
            logistics: logistics || null
          })
        )
      }
      // Move to the next day
      startAt.setDate(startAt.getDate() + 1);
    }
    if (batchError.length > 0) {
      throw new BaseError('Office.MeetingRoomNotAvailable', 'Phòng họp không có sẵn', { errorMessage: batchError })
    }

    return batchBooking
  }

  public async getAllMeeting(filter: QueryBookingMeetingRoomArgs) {
    const bookings = await this.bookingMeetingRoomRepo.list()
    const currentRequestId = await RequestContext.currentId()

    let query = MeetingRoomSchedule.createQueryBuilder('meeting')
        .where({
          startAt: Between(new Date(filter.startAt), new Date(filter.endAt)),
          bookingId: In(bookings.map(i => i.id))
        })
        .leftJoinAndSelect('meeting.booking', 'booking')
        .leftJoinAndSelect('booking.bookedBy', 'bookedBy')
        .leftJoinAndSelect('meeting.host','host')
        .leftJoinAndSelect('meeting.meetingRoom', 'meetingRoom')
        .leftJoinAndSelect(BRIDGE_TABLE_DB.MEETING_SCHEDULE_PARTICIPANTS, 'wBridgeParticipants', '"wBridgeParticipants"."officeMeetingRoomScheduleId" = meeting.id')

    if (filter.case === CaseQueryMeeting.OnlyMe && RequestContext.isNormalUser()) {
      query = query
          .andWhere(new Brackets(db => {
            db.where('"wBridgeParticipants"."officeUsersId" = :userId', { userId: currentRequestId })
                .orWhere(`"host"."id" = :userId`, { userId: currentRequestId })
          }))
    }

    if (filter.bookingStatus) {
      query = query
          .andWhere('booking.status = :bookingStatus', { bookingStatus: filter.bookingStatus })
    }
    if (!filter.isAllRoom && filter.meetingRoomIds.length > 0) {
      query = query
          .andWhere('meetingRoom.id IN (:...meetingRoomIds)', { meetingRoomIds: filter.meetingRoomIds })
    }
    if (filter.orgChartId) {
      query = query
          .andWhere('"meetingRoom"."organizationId" = :organizationId', { organizationId: filter.orgChartId })
    }
    const [meetings, total] = await query
        .getManyAndCount()

    return {
      total,
      meetings
    }
  }

  async bookMeetingRoomLegacy(param: { requesterId: string; token: string }, args: BookMeetingRoomArgs) {
    const {requesterId, token} = param

    const meetingRoom = await MeetingRoom.findOne({ where: { id: args.meetingRoomId } });
    if (!meetingRoom) throw OfficeError.MeetingRoomNotFound;
    // const currentDate = new Date();
    // currentDate.setHours(23, 59, 59, 999);
    // const endOfDayTimestamp = currentDate.getTime();
    // args.repeatedEndAt = args.repeatedEndAt ? args.repeatedEndAt :
    const bookingId = RandomHelper.generateUUID()

    const batchBooking: MeetingRoomSchedule[] = await this.createMeetingRoomSchedule({
      startAt: new Date(args.startAt),
      endAt: new Date(args.endAt),
      meetingRoomId: meetingRoom.id,
      bookingId,
      repeatedEndAt: args.repeatedEndAt ? new Date(args.repeatedEndAt) : new Date(args.endAt),
      repeatedDays: args.repeatedDays,
      logistics: args.logistics,
      equiments: args.equiments
    })

    args.participantIds.push(args.hostId)
    const participants = await this.verifyParticipantIds(args.participantIds)

    await this.validateRoomAvailable(batchBooking)

    const currentId = await RequestContext.currentId()
    const booking = BookingMeetingRoom.create({
      id: bookingId,
      startAt: new Date(args.startAt),
      endAt: new Date(args.endAt),
      organizationId: args.organizationId ?? meetingRoom.organizationId, // handled
      meetingContent: args.meetingContent,
      hostId: args.hostId,
      quantity: args.quantity,
      participantIds: args.participantIds,
      participants: participants,
      note: args.note,
      meetingRoomId: args.meetingRoomId,
      meetingRoom: meetingRoom,
      repeatedEndAt: args.repeatedEndAt ? new Date(args.repeatedEndAt) : null,
      repeatedDays: args.repeatedDays,
      bookedById: RequestContext.isNormalUser() ? currentId : null,
      createdById: currentId,
      updatedById: currentId
    })

    /*Booking created by sys user not in approval page is auto approved*/
    if (meetingRoom.approvalFormId && RequestContext.isNormalUser()) {
      //tạo luồng phê duyệt & gắn approvalId
      const approval = await this.approvalService.submitApproval({
        source: ApprovalSource.Template,
        name: null,
        note: args.note,
        formId: meetingRoom.approvalFormId,
        formFieldData: args.formFieldData,
        structure: null,
        imageIds: null,
        attachmentIds: null,
        subscriberIds: args.subscriberIds,
        submitType: ApprovalSubmitTypeEnum.Submit
      }, booking.id)
      booking.approvalId = approval.id
      if (approval.status === ApprovalStatus.Approved) booking.status = RequestStatus.Approved
    } else {
      booking.status = RequestStatus.Approved
    }

    if (args.notify) {
      await this.createNotifyBooking({requesterId, token}, args, booking)
    }

    /*await this.dataSource.manager.transaction(async entity => {
      await entity.save(booking)
      await entity.save(batchBooking)
    })*/

    await this.dataSource.manager.save(booking)
    await this.dataSource.manager.save(batchBooking)

    return { booking }
  }

  async updateScheduleMeetingRoom(args: UpdateBookingMeetingRoomArgs) {
    const schedule = await MeetingRoomSchedule.findOneBy({ id: args.scheduleId })

    if (!schedule) {
      throw OfficeError.BookingRoomScheduleNotFound
    }

    if (schedule.startAt < new Date()) {
      throw OfficeError.BookingRoomCanNotChange
    }

    await MeetingRoomSchedule.delete({ id: args.scheduleId })

    return this.bookMeetingRoomLegacy({
      requesterId: RequestContext.currentRequestId(),
      token: RequestContext.currentToken()
    }, {
      ...args,
      formFieldData: null,
      subscriberIds: [],
    } as BookMeetingRoomArgs)
  }

  async updateBookingMeetingRoom(args: UpdateBookingMeetingRoomArgs) {
    const booking = await this.bookingMeetingRoomRepo.getById(args.bookingId)
    if (!booking) {
      throw OfficeError.BookingMeetingRoomNotFound
    }

    if (booking.status !== RequestStatus.Approved) {
      throw OfficeError.BookingRoomNotApprovalCanNotChange
    }

    if (booking.repeatedDays && booking.repeatedDays.length) {
      return this.updateScheduleMeetingRoom(args)
    }

    if (booking.startAt < new Date()) {
      throw OfficeError.BookingRoomCanNotChange
    }

    if (args.hostId != booking.hostId) {
      booking.hostId = await this.checkAndGetHostId(args.hostId)
    }

    if (args.note != booking.note) {
      booking.note = args.note
    }
    if (args.meetingContent != booking.meetingContent) {
      booking.meetingContent = args.meetingContent
    }
    if (args.quantity != booking.quantity) {
      booking.quantity = args.quantity
    }
    if (args.organizationId != booking.organizationId) {
      booking.organizationId = args.organizationId
    }
    if (!args.participantIds.includes(args.hostId)) {
      args.participantIds.push(args.hostId)
      booking.hostId = args.hostId
    }
    const participants = await this.verifyParticipantIds(args.participantIds)

    booking.participantIds = args.participantIds
    booking.participants = participants
    // const addedParticipantIds = args.participantIds.filter(item => !booking.participantIds.includes(item));
    // const lostParticipantIds = booking.participantIds.filter(item => !args.participantIds.includes(item));
    let isReschedule = false
    if (args.startAt !== booking.startAt.getTime()) {
      isReschedule = true;
      booking.startAt = args.startAt ? new Date(args.startAt) : null
    }
    if (args.endAt !== booking.endAt.getTime()) {
      isReschedule = true;
      booking.endAt = args.endAt ? new Date(args.endAt) : null
    }
/*    if (args.repeatedEndAt !== booking.repeatedEndAt?.getTime()) {
      isReschedule = true;
      booking.repeatedEndAt = args.repeatedEndAt ? new Date(args.repeatedEndAt) : null
    }*/

/*    if (!(booking.repeatedDays.length === args.repeatedDays.length
        && booking.repeatedDays.every(item => args.repeatedDays.includes(item)))) {
      isReschedule = true;
      booking.repeatedDays = args.repeatedDays
    }*/

    if (args.meetingRoomId != booking.meetingRoomId) {
      const meetingRoom = await MeetingRoom.findOne({ where: { id: args.meetingRoomId } });
      if (!meetingRoom) throw OfficeError.MeetingRoomNotFound;
      booking.meetingRoomId = args.meetingRoomId;
      booking.meetingRoom = meetingRoom;
      await MeetingRoomSchedule.update({ bookingId: booking.id }, { meetingRoomId: args.meetingRoomId, meetingRoom: meetingRoom })
    }

    let batchBooking = null
    if (isReschedule) {
      await MeetingRoomSchedule.delete({ bookingId: booking.id })

      batchBooking = await this.createMeetingRoomSchedule({
        startAt: new Date(args.startAt),
        endAt: new Date(args.endAt),
        meetingRoomId: booking.meetingRoomId,
        bookingId: booking.id,
        repeatedEndAt: args.repeatedEndAt ? new Date(args.repeatedEndAt) : null,
        repeatedDays: args.repeatedDays,
        equiments: args.equiments,
        logistics: args.logistics
      })

      await this.validateRoomAvailable(batchBooking)
    }

    if (args.notify) {
      await this.updateNotifyBooking(args.notify, booking)
    }

    /*await this.dataSource.manager.transaction(async entity => {
      await entity.save(booking)
      if (batchBooking) await entity.save(batchBooking)
    })*/

    await this.dataSource.manager.save(booking)
    if (batchBooking) await this.dataSource.manager.save(batchBooking)

    await booking.reload()
    return booking
  }

  private async validateAndGetBookingById(id: string) {
    const booking = await this.bookingMeetingRoomRepo.getById(id)

    if (!booking) {
      throw OfficeError.MeetingRoomNotFound;
    }

    if (booking.status !== RequestStatus.Approved) {
      throw OfficeError.BookingRoomNotApprovalCanNotChange
    }

    if (booking.startAt < new Date()) {
      throw OfficeError.BookingRoomCanNotChange
    }

    return booking
  }


  async adminBookingRemove(args: DeleteBookingMeetingRoomArgs) {
    const booking = await this.validateAndGetBookingById(args.id)

    return this.bookingRemove(args, booking)
  }

  async userBookingRemove(args: DeleteBookingMeetingRoomArgs) {
    const booking = await this.validateAndGetBookingById(args.id)

    await this.checkNormalUserCanModifyBooking(booking)

    return this.bookingRemove(args, booking)
  }

  async checkNormalUserCanModifyBooking(booking: BookingMeetingRoom) {
    if (booking.createdById !== await RequestContext.currentId()) {
      throw OfficeError.NotAllow
    }
  }

  async bookingRemove(args: DeleteBookingMeetingRoomArgs, booking: BookingMeetingRoom) {
    booking.updatedById = await RequestContext.currentId()
    booking.cancelDescription = args.description

    const meeting = await this.meetingRoomScheduleRepo.findOneBy({ bookingId: booking.id })
    const notifyBooking = await this.notificationCampaignRepo.getBookingRoomById(booking.id)

    meeting.cancelDescription = args.description

    await this.dataSource.manager.save(booking)
    await this.dataSource.manager.softRemove(meeting)
    await this.dataSource.manager.softRemove(booking)

    if (notifyBooking) await this.dataSource.manager.softRemove(notifyBooking)

    return args.id
  }

  async notifyBookingUpdate(args: NotificationBookingMeetingRoomArgs) {
    const booking = await this.bookingMeetingRoomRepo.getById(args.bookingId)
    if (!booking) {
      throw OfficeError.BookingMeetingRoomNotFound
    }

    if (booking.status !== RequestStatus.Approved) {
      throw OfficeError.BookingRoomNotApprovalCanNotChange
    }

    return this.updateNotifyBooking(args, booking)
  }

  private async validateRoomAvailable(schedules: MeetingRoomSchedule[]) {
    const where = []
    for (const schedule of schedules) {
      where.push({
        startAt: LessThan(new Date(schedule.endAt)),
        endAt: MoreThan(new Date(schedule.startAt)),
        meetingRoomId: schedule.meetingRoomId,
        booking: {
          status: In([RequestStatus.UnderReview, RequestStatus.Approved, RequestStatus.Recalled])
        }
      })
    }

    const bookingSchedules = await this.meetingRoomScheduleRepo.find({
      where
    })

    if (bookingSchedules.length) {
      throw OfficeError.BookingRoomNotAvailable
    }
  }

  private async checkAndGetHostId(hostId: string) {
    if (RequestContext.isNormalUser()) {
      return hostId;
    }

    const host = await this.officeUserRepo.getUserInOrgManagementById(hostId)

    if (!host) {
      throw OfficeError.BookingRoomHostNotFound
    }

    return host.id
  }

  async bookMeetingRoom(args: BookMeetingRoomArgs) {
    const requesterId = RequestContext.currentRequestId()
    const token = RequestContext.currentToken()

    const booking = await this.bookMeetingRoomCreate(args)

    await booking.save()

    const schedules = await this.bookMeetingRoomScheduleCreate(args, booking)

    await this.bookMeetingRoomApprovalCreate(args, booking)

    if (args.notify) {
      await this.createNotifyBooking({requesterId, token}, args, booking)
    }

    await booking.save()

    for (const schedule of schedules) {
      schedule.booking = booking
      await schedule.save()
    }

    if (args.repeatConfig && args.repeatConfig.endAt) {
      const dateClone = this.bookMeetingRoomDateCloneCreate(args, booking)

      await dateClone.save()
    }

    await booking.reload()

    return { booking }
  }

  private async bookMeetingRoomCreate(args: BookMeetingRoomArgs) {
    const meetingRoom: MeetingRoom = args.meetingRoom
    const participants = arrayConvertToDistinctAndNotNull([...args.participantIds, args.hostId])
    const currentId = await RequestContext.currentId()

    return BookingMeetingRoom.create({
      startAt: new Date(args.startAt),
      endAt: new Date(args.endAt),
      organizationId: args.organizationId ?? meetingRoom.organizationId,
      meetingContent: args.meetingContent,
      hostId: args.hostId,
      quantity: args.quantity,
      participantIds: args.participantIds,
      participants: participants,
      note: args.note,
      meetingRoomId: args.meetingRoomId,
      meetingRoom: meetingRoom,
      repeatedEndAt: args.repeatedEndAt ? new Date(args.repeatedEndAt) : null,
      repeatedDays: args.repeatedDays,
      bookedById: RequestContext.isNormalUser() ? currentId : null,
      createdById: currentId,
      updatedById: currentId
    })
  }

  private async bookMeetingRoomScheduleCreate(args: BookMeetingRoomArgs, booking: BookingMeetingRoom) {
    let schedulePeriods: {startAt: Date, endAt: Date}[]
    if (!args.repeatConfig || !args.repeatConfig.endAt) {
      schedulePeriods = [{
        startAt: new Date(args.startAt),
        endAt: new Date(args.endAt)
      }]
    } else {
      const scheduleDate = await this.meetingScheduleDateGet(args)
      schedulePeriods = await this.meetingSchedulePeriodGet(args, scheduleDate)
    }

    await this.validateScheduleTime(args, schedulePeriods)

    return this.meetingRoomScheduleRepo.createMany({
      booking,
      args,
      schedulePeriods
    })
  }

  private async meetingScheduleDateGet(args: BookMeetingRoomArgs): Promise<Date[]> {
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
          if (weekDays.includes(datetimeLocalGetDay(currentDate))) res.push(structuredClone(currentDate))
          break
        case CloneDatePeriodEnum.Monthly:
          if (repeatConfig.monthDays.includes(datetimeLocalGetDate(currentDate))) res.push(structuredClone(currentDate))
          break
      }

      currentDate.setDate(currentDate.getDate() + 1);
    }

    return res
  }

  private async meetingSchedulePeriodGet(args: BookMeetingRoomArgs, scheduleDate: Date[]) {
    const timeStart = args.startAt - (datetimeStartOfLocalDay(args.startAt)).getTime()
    const timeEnd = args.endAt - (datetimeStartOfLocalDay(args.endAt)).getTime()


    return scheduleDate.map(i => ({
      startAt: datetimeAddTimestamp(i, timeStart),
      endAt: datetimeAddTimestamp(i, timeEnd)
    }))
  }

  private async validateScheduleTime(args: BookMeetingRoomArgs, schedulePeriods: { endAt: Date; startAt: Date }[]) {
    const where = []
    for (const schedule of schedulePeriods) {
      where.push({
        startAt: LessThan(schedule.endAt),
        endAt: MoreThan(schedule.startAt),
        meetingRoomId: args.meetingRoomId,
        booking: {
          status: In([RequestStatus.UnderReview, RequestStatus.Approved, RequestStatus.Recalled])
        }
      })
    }

    const bookingSchedules = await this.meetingRoomScheduleRepo.find({
      where
    })

    if (bookingSchedules.length) {
      throw OfficeError.BookingRoomNotAvailable
    }
  }

  private async bookMeetingRoomApprovalCreate(args: BookMeetingRoomArgs, booking: BookingMeetingRoom) {
    const meetingRoom = args.meetingRoom

    /*Booking created by sys user not in approval page is auto approved*/
    if (meetingRoom.approvalFormId && RequestContext.isNormalUser()) {
      //tạo luồng phê duyệt & gắn approvalId
      const approval = await this.approvalService.submitApproval({
        source: ApprovalSource.Template,
        name: null,
        note: args.note,
        formId: meetingRoom.approvalFormId,
        formFieldData: args.formFieldData,
        structure: null,
        imageIds: null,
        attachmentIds: null,
        subscriberIds: args.subscriberIds,
        submitType: ApprovalSubmitTypeEnum.Submit
      }, booking.id)
      booking.approvalId = approval.id
      if (approval.status === ApprovalStatus.Approved) booking.status = RequestStatus.Approved
    } else {
      booking.status = RequestStatus.Approved
    }
  }

  private bookMeetingRoomDateCloneCreate(args: BookMeetingRoomArgs, booking: BookingMeetingRoom) {
    return this.dateCloneRepo.bookingMeetingRoomCreate({
      relationId: booking.id,
      startAt: args.startAt,
      endAt: args.endAt,
      equiments: args.equiments ?? null,
      logistics: args.logistics ?? null,
      repeatConfig: args.repeatConfig,
    })
  }
}