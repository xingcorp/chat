import { Inject, Injectable, forwardRef } from '@nestjs/common'
import { GraphQLClient } from '../../common/graphql.client'
import * as GQLTag from 'graphql-tag'
import {
  NotificationCampaignArgs,
  NotificationCampaignDifferentArgs,
  NotificationCampaignFilter
} from './notification.args'
import {
  NotificationCampaign, NotificationCampaignStatus,
  NotificationObjectType,
  NotificationScheduleType
} from '@models/entities/notification.campaign'
import { Brackets, Connection, In } from 'typeorm'
import { DateFormater } from '@common/date.formater'
import { InjectConnection } from '@nestjs/typeorm'
import { MeetingRoomSchedule, OfficeOrgChart, OfficeTitle, OfficeUser, UserDepartment } from '@models/entities'
import { NotificationSchedule, NotificationStatus } from '@models/entities/notification.schedule'
import { OfficeOrgChartRepo } from '@models/repositories/office-org-chart.repo'
import { NotificationCampaignKind } from "@enum/campaign/campaign.enum";
import { OfficeUserRepo } from "@models/repositories";
import { RequestContext } from "@common/context/request.context";
import { RandomHelper } from "@common/random";
import { OfficeError } from "@common/office.error";
import { StorageService } from "@core/storage/storage.service";
import { NotificationBookingMeetingRoomArgs } from "@modules/graphql/booking/dto/booking.args";
import { NotifyType } from "@common/notify.message";
import { arrayChunk } from "@utils/array.utils";

const NOTIFICATION_DESTINATION_PUSH = GQLTag.gql`
  mutation iamNotificationDestinationPush(
    $type: String
    $title: String!
    $content: String!
    $image: String
    $metadata: String
    $receiverIds: [String!]!
    $receiverBusinessRoleId: String
    $serviceId: String!
    $organizationId: String!
  ) {
    iamNotificationDestinationPush(
      arguments: {
        type: $type
        title: $title
        content: $content
        image: $image
        metadata: $metadata
        receiverIds: $receiverIds
        receiverBusinessRoleId: $receiverBusinessRoleId
        serviceId: $serviceId
        organizationId: $organizationId
      }
    ) {
      id
      createdAt
      updatedAt
      type
      title
      content
      image
      receivers {
        id
      }
    }
  }
`

const SYSTEM_NOTIFICATION_DESTINATION_PUSH = GQLTag.gql`
  mutation iamNotificationPush(
    $type: String
    $title: String!
    $content: String!
    $image: String
    $metadata: String
    $receiverIds: [String!]!
    $receiverBusinessRoleId: String
    $serviceId: String!
    $organizationId: String!
    $requesterId: String!
  ) {
    iamNotificationPush(
      arguments: {
        type: $type
        title: $title
        content: $content
        image: $image
        metadata: $metadata
        receiverIds: $receiverIds
        receiverBusinessRoleId: $receiverBusinessRoleId
        serviceId: $serviceId
        organizationId: $organizationId
        requesterId: $requesterId
      }
    ) {
      id
      createdAt
      updatedAt
      type
      title
      content
      image
      status
      receivers {
        id
      }
    }
  }
`

@Injectable()
export class NotificationService extends GraphQLClient {
  constructor(
    @InjectConnection()
    private readonly connection: Connection,

    private orgChartRepository: OfficeOrgChartRepo,
    private officeUserRepo: OfficeUserRepo,
    @Inject(forwardRef(() => StorageService))
    private readonly storageService: StorageService,
  ) {
    super(process.env.SRT_IAM_MICROSERVICE_DOMAIN)
  }

  public async destinationPush(
    token: string = null,
    type: string,
    title: string,
    content: string,
    image: string,
    metadata: any,
    receiverIds: string[],
    receiverRoleId: string,
    organizationId: string
  ) {

    const receiverIamIds = await this.officeUserRepo.listIamIdById(receiverIds)

    return await this.sendMutation(
      token ?? RequestContext.currentToken(),
      NOTIFICATION_DESTINATION_PUSH,
      {
        type: type,
        title: title,
        content: content,
        image: image ? image : '',
        metadata: metadata,
        receiverIds: receiverIamIds,
        receiverBusinessRoleId: receiverRoleId,
        serviceId: process.env.SERVICE_ID,
        organizationId: organizationId,
      }
    )
  }

  public async systemDestinationPush(
    type: string,
    title: string,
    content: string,
    image: string,
    metadata: any,
    receiverIds: string[],
    receiverRoleId: string,
    organizationId: string,
    requesterId: string
  ) {
    const receiverIamIds = await this.officeUserRepo.listIamIdById(receiverIds)

    return await this.sendMutation(
      null,
      SYSTEM_NOTIFICATION_DESTINATION_PUSH,
      {
        type: type,
        title: title,
        content: content,
        image: image ? image : '',
        metadata: metadata,
        receiverIds: receiverIamIds,
        receiverBusinessRoleId: receiverRoleId,
        serviceId: process.env.SERVICE_ID,
        organizationId: organizationId,
        requesterId: requesterId
      }
    )
  }

  public async systemDestinationPushQueue(
      type: string,
      title: string,
      content: string,
      image: string,
      metadata: any,
      receiverIds: string[],
      receiverRoleId: string,
      organizationId: string,
      requesterId: string
  ) {
    const receiverIamIds = await this.officeUserRepo.listIamIdById(receiverIds)

    const receiverChunk = arrayChunk(receiverIamIds, 20)

    for (const receiver of receiverChunk) {
      await this.sendMutation(
          null,
          SYSTEM_NOTIFICATION_DESTINATION_PUSH,
          {
            type: type,
            title: title,
            content: content,
            image: image ? image : '',
            metadata: metadata,
            receiverIds: receiver,
            receiverBusinessRoleId: receiverRoleId,
            serviceId: process.env.SERVICE_ID,
            organizationId: organizationId,
            requesterId: requesterId
          }
      )
    }

    return true
  }

  public async notificationCampaignList(filter: NotificationCampaignFilter) {
    filter.size = filter.size ? filter.size : 20
    filter.page = filter.page ? (filter.page - 1) : 0

    let query = NotificationCampaign.createQueryBuilder('nc')
      .where({
        notifyType: NotificationCampaignKind.Campaign
      })
      .take(filter.size)
      .skip(filter.page * filter.size)
      .orderBy('nc.createdAt', 'DESC')

    if (filter && filter.status) {
      query = query.andWhere({ status: filter.status })
    }

    if (filter && filter.type) {
      query = query.andWhere({ type: filter.type })
    }

    if (filter && filter.keyword) {
      query = query.andWhere(new Brackets(db => {
        db.where(`unaccent(LOWER(nc.title)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
          // .orWhere(`unaccent(LOWER(su.code)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
          // .orWhere(`unaccent(LOWER(su.email)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
      }))
    }

    if (filter.fromDate) {
      query = query.andWhere('nc.startAt >= :from', { from: new Date(filter.fromDate) })
    }

    if (filter.toDate) {
      query = query.andWhere('nc.endAt <= :to', { to: new Date(filter.toDate) })
    }

    return query.getManyAndCount()
  }

  public async getActiveNotificationsInQueue(): Promise<any[]> {
    let query = `select 
                  ons.*,
	                onc."createdBy",
                  onc.title,
                  onc."content",
                  onc."attachFileIds",
                  onc."attachFileUrls",
                  onc."imageIds",
                  onc."imageUrls",
                  onc."objectType",
                  onc.phones,
                  onc."userIds",
                  onc."departmentIds",
                  onc."titleIds",
                  onc."type",
                  onc."notifyType",
                  onc."notifyTypeId"
                from office."office-notification-schedules" ons 
                left join office."office-notification-campaigns" onc 
                  on onc.id::text = ons."campaignId" 
                where ons."deletedAt" is null and ons.status = 'InQueue' and onc.status = 'Active' and onc."type" <> 'Now' and ons."scheduleAt" <= current_timestamp`

    return this.connection.query(query)
  }

  public async getActiveNotificationByCampaignId(campaignId: string): Promise<any[]> {
    let query = `select 
                  ons.*,
	                onc."createdBy",
                  onc.title,
                  onc."content",
                  onc."attachFileIds",
                  onc."attachFileUrls",
                  onc."imageIds",
                  onc."imageUrls",
                  onc."objectType",
                  onc.phones,
                  onc."userIds",
                  onc."departmentIds",
                  onc."titleIds",
                  onc."type"
                from office."office-notification-schedules" ons 
                left join office."office-notification-campaigns" onc 
                  on onc.id::text = ons."campaignId" 
                where ons."deletedAt" is null and ons.status = 'InQueue' and onc.status = 'Active' and onc.id = '${campaignId}'`

    return this.connection.query(query)
  }

  async getFilterEmployees(departmentIds: string[], titleIds: string[]) {
    const query = OfficeUser.createQueryBuilder('ou')
      .leftJoinAndMapMany('ou.departments', UserDepartment, 'd', 'd."userId" = ou.id::text')
      .leftJoinAndMapOne('ou.department', OfficeOrgChart, 'dd', 'dd.id::text = d."departmentId"::text')
      .leftJoinAndMapOne('ou.title', OfficeTitle, 'dt', 'dt.id::text = d."titleId"::text')
      .where({})
      .orderBy('ou.createdAt', 'DESC')

    if (departmentIds.length > 0) {
      const ids = await this.orgChartRepository.getAllIdsCurrentAndChild(departmentIds)

      query.andWhere(`d."departmentId"::text IN (:...oogIds)`, { oogIds: ids })
    }

    if (titleIds.length > 0) {
      query.andWhere(`d."titleId"::text IN (:...titleIds)`, { titleIds: titleIds })
    }

    return query.getManyAndCount()
  }

  async notificationSchedule() {
    const now = new Date()
    console.log('[notificationSchedule] Events every 1 min: ', DateFormater.dateToStringWithFormat(now, 'HH:mm:ss DD/MM/yyyy'));
    const data = await this.getActiveNotificationsInQueue();
    console.log('[notificationSchedule] inQueue data: ', data)
    for (const iterator of data) {
      const updatePayload: any = {}
      const receiverIds: string[] = await this.getListReceivers(iterator)

      let metadata = JSON.stringify({})
      let type = ''

      switch (iterator.notifyType) {
        case NotificationCampaignKind.Book_Room:
          metadata = JSON.stringify({ bookRoomId: iterator.notifyTypeId })
          type = NotifyType.BookingRoomNotify
          break
        case NotificationCampaignKind.Book_Room_Schedule:
          const schedule = await MeetingRoomSchedule.findOneBy({id: iterator.notifyTypeId})
          metadata = JSON.stringify({ bookRoomId: schedule.bookingId, scheduleId: iterator.notifyTypeId })
          type = NotifyType.BookingRoomNotify
          break
        case NotificationCampaignKind.Book_Car:
          metadata = JSON.stringify({ bookCarId: iterator.notifyTypeId })
          type = NotifyType.BookingCarNotify
          break
        case NotificationCampaignKind.Campaign:
        default:
          metadata = JSON.stringify({ attachFileIds: iterator.attachFileIds || [], imageIds: iterator.imageIds || [] })
          type = NotifyType.Campaign
          break
      }

      updatePayload.receiverIds = receiverIds
      updatePayload.pushAt = now
      updatePayload.metadata = metadata

      const { data, error } = await this.systemDestinationPush(
        type,
        iterator.title,
        iterator.content,
        '',
        metadata,
        receiverIds,
        null,
        process.env.OFFICE_ORGANIZATION_ID,
        iterator.createdBy
      )


      if (error) {
        updatePayload.status = NotificationStatus.Error
        updatePayload.iamPushResult = JSON.stringify(error)
        updatePayload.iamPushResult = JSON.stringify(error)
      } else {
        updatePayload.iamRecordId = data?.id
        updatePayload.status = NotificationStatus.Sent
        updatePayload.iamPushResult = data ? JSON.stringify(data) : null
        updatePayload.iamReceiverIds = data?.receivers ? data.receivers.map((r: any) => r.id) : null
      }

      await NotificationSchedule.update({ id: iterator.id }, updatePayload)
    }
  }

  async notificationTrigger(campaignId: string) {
    const now = new Date()
    const data = await this.getActiveNotificationByCampaignId(campaignId);
    console.log('[notificationSchedule] trigger data: ', data)
    for (const iterator of data) {
      const updatePayload: any = {}
      let receiverIds = []
      switch (iterator.objectType) {
        case 'Personal':
          const officeUsers = await OfficeUser.find({
            where: [
              {phone: In(iterator.phones || [])},
              {id: In(iterator.userIds || [])}
            ]
          })
          receiverIds = officeUsers.map(ou => ou.id)
          break
        case 'Department':
          receiverIds = await this.getListReceivers(iterator)
          break
      }

      const metadata = JSON.stringify({ attachFileIds: iterator.attachFileIds || [], imageIds: iterator.imageIds || [] })
      updatePayload.receiverIds = receiverIds
      updatePayload.pushAt = now
      updatePayload.metadata = metadata

      const { data, error } = await this.systemDestinationPush(
        'system.campaign',
        iterator.title,
        iterator.content,
        '',
        metadata,
        receiverIds,
        null,
        process.env.OFFICE_ORGANIZATION_ID,
        iterator.createdBy
      )


      if (error) {
        updatePayload.status = NotificationStatus.Error
        updatePayload.iamPushResult = JSON.stringify(error)
      } else {
        updatePayload.iamRecordId = data?.id
        updatePayload.status = NotificationStatus.Sent
        updatePayload.iamPushResult = data ? JSON.stringify(data) : null
        updatePayload.iamReceiverIds = data?.receivers ? data.receivers.map((r: any) => r.id) : null
      }

      await NotificationSchedule.update({ id: iterator.id }, updatePayload)
    }
  }

  async createNotificationCampaign(param: {
    requesterId: string;
    token: string
  }, args: NotificationCampaignArgs | NotificationCampaignDifferentArgs, isDefaultCampaign: boolean = true) {
    const {requesterId, token} = param

    const campaign = NotificationCampaign.create({
      id: RandomHelper.generateUUID(),
      title: args.title,
      content: args.content,
      objectType: args.objectType, //check
      type: args.type,
      timeZone: args.timeZone,
      // startAt: new Date(args.startAt),
      // endAt: new Date(args.endAt),
      status: args.status,
      departmentIds: args.departmentIds,
      titleIds: args.titleIds,
      phones: args.phones,
      userIds: args.userIds,
      createdBy: requesterId,
      updatedBy: requesterId,
    })

    if (!isDefaultCampaign) {
      campaign.notifyType = (args as NotificationCampaignDifferentArgs).notifyType
      campaign.notifyTypeId = (args as NotificationCampaignDifferentArgs).notifyTypeId
    }

    /*departmentIds and titleIds is optional now*/
    /*if (campaign.objectType === NotificationObjectType.Department) {
      if (!args.departmentIds) throw OfficeError.NotificationDepartmentsIsRequired
      if (!args.titleIds) throw OfficeError.NotificationTitlesIsRequired
      campaign.departmentIds = args.departmentIds
      campaign.titleIds = args.titleIds
    }*/

    if (campaign.type !== NotificationScheduleType.Now) {
      if (!args.startTimeInMinutes) throw OfficeError.NotificationStartTimeIsRequired
      if (!args.startAt) throw OfficeError.NotificationStartAtIsRequired
      if (!args.endAt) throw OfficeError.NotificationEndAtIsRequired

      campaign.startTimeIn = Array.isArray(args.startTimeInMinutes) ? args.startTimeInMinutes : [args.startTimeInMinutes]
      campaign.startAt = new Date(args.startAt)
      campaign.endAt = new Date(args.endAt)
    }

    if (campaign.type === NotificationScheduleType.Weekly) {
      if (!args.weekDays || args.weekDays.length === 0) throw OfficeError.NotificationAtIsRequired
      campaign.weekDays = args.weekDays
    } else if (campaign.type === NotificationScheduleType.Monthly) {
      if (!args.monthDays || args.monthDays.length === 0) throw OfficeError.NotificationAtIsRequired
      campaign.monthDays = args.monthDays
    }

    if (args.imageIds) {
      for (const imageId of args.imageIds) {
        const { data, error } = await this.storageService.getFileDetail(token, imageId)
        if (error) throw error
        if (!data) throw OfficeError.FileNotExisted

        if (campaign.imageIds) {
          campaign.imageIds.push(imageId)
        } else {
          campaign.imageIds = [imageId]
        }

        if (campaign.imageUrls) {
          campaign.imageUrls.push(data.location)
        } else {
          campaign.imageUrls = [data.location]
        }
      }
    }

    if (args.attachFileIds) {
      for (const attachFileId of args.attachFileIds) {
        const { data, error } = await this.storageService.getFileDetail(token, attachFileId)
        if (error) throw error
        if (!data) throw OfficeError.FileNotExisted

        if (campaign.attachFileIds) {
          campaign.attachFileIds.push(attachFileId)
        } else {
          campaign.attachFileIds = [attachFileId]
        }

        if (campaign.attachFileUrls) {
          campaign.attachFileUrls.push(data.location)
        } else {
          campaign.attachFileUrls = [data.location]
        }
      }
    }

    if (args instanceof NotificationCampaignDifferentArgs) {
      campaign.notifyTypeId = args.notifyTypeId
      campaign.notifyType = args.notifyType
    }

    await campaign.save()

    if (campaign.type === NotificationScheduleType.Now) this.notificationTrigger(campaign.id)

    return campaign
  }

  async createNotificationBookingRoom(param: {
    requesterId: string;
    token: string
  }, notify: NotificationCampaignDifferentArgs) {
    notify.notifyType = NotificationCampaignKind.Book_Room
    notify.objectType = NotificationObjectType.Personal
    notify.status = NotificationCampaignStatus.Active

    return this.createNotificationCampaign(param, notify, false)
  }

  async createNotificationBookingCar(param: {
    requesterId: string;
    token: string
  }, notify: NotificationCampaignDifferentArgs) {
    notify.notifyType = NotificationCampaignKind.Book_Car
    notify.objectType = NotificationObjectType.Personal
    notify.status = NotificationCampaignStatus.Active

    return this.createNotificationCampaign(param, notify, false)
  }

  async upsertNotificationBookingRoomSchedule(notify: NotificationCampaignDifferentArgs) {
    let campaign = await NotificationCampaign.findOneBy({
      notifyTypeId: notify.notifyTypeId,
      notifyType: NotificationCampaignKind.Book_Room_Schedule,
    })

    if (!campaign) {
      return this.createNotificationBookingRoomSchedule(notify)
    }

    return this.updateNotificationBookingRoomSchedule(notify, campaign)
  }


  async createNotificationBookingRoomSchedule(notify: NotificationCampaignDifferentArgs) {
    notify.notifyType = NotificationCampaignKind.Book_Room_Schedule
    notify.objectType = NotificationObjectType.Personal
    notify.status = NotificationCampaignStatus.Active

    return this.createNotificationCampaign({
      requesterId: RequestContext.currentRequestId(),
      token: RequestContext.currentToken()
    }, notify, false)
  }

  async updateNotificationBookingRoomSchedule(notify: NotificationCampaignDifferentArgs, campaign: NotificationCampaign) {
    campaign.content = notify.content ?? campaign.content
    campaign.phones = notify.phones ?? campaign.phones
    campaign.userIds = notify.userIds ?? campaign.userIds
    campaign.type = notify.type ?? campaign.type

    campaign.startTimeIn = notify.startTimeInMinutes ?? campaign.startTimeIn

    campaign.startAt = notify.startAt ? new Date(notify.startAt) : campaign.startAt
    campaign.endAt = notify.endAt ? new Date(notify.endAt) : campaign.endAt
    campaign.updatedBy = RequestContext.currentSysId()

    if (Array.isArray(campaign.startTimeInMinutes)) delete campaign.startTimeInMinutes
    if (campaign.startTimeIn) campaign.startTimeIn = Array.isArray(campaign.startTimeIn) ? campaign.startTimeIn : [campaign.startTimeIn]

    await campaign.save()
    await campaign.reload()

    if (campaign.type === NotificationScheduleType.Now && RequestContext.isSysUser()) {
      this.notificationTrigger(campaign.id)
    }

    return campaign
  }

  async updateNotificationBookingRoom(notify: NotificationCampaignDifferentArgs) {
    let campaign = await NotificationCampaign.findOneBy({
      notifyTypeId: notify.notifyTypeId,
      notifyType: NotificationCampaignKind.Book_Room,
    })

    if (!campaign) {
      campaign = await this.createNotificationBookingRoom({
        requesterId: RequestContext.currentRequestId(),
        token: RequestContext.currentToken()
      }, notify)
    }

    campaign.content = notify.content ?? campaign.content
    campaign.phones = notify.phones ?? campaign.phones
    campaign.userIds = notify.userIds ?? campaign.userIds
    campaign.type = notify.type ?? campaign.type

    campaign.startTimeIn = notify.startTimeInMinutes ?? campaign.startTimeIn

    campaign.startAt = notify.startAt ? new Date(notify.startAt) : campaign.startAt
    campaign.endAt = notify.endAt ? new Date(notify.endAt) : campaign.endAt
    campaign.updatedBy = RequestContext.currentSysId()

    if (Array.isArray(campaign.startTimeInMinutes)) delete campaign.startTimeInMinutes
    if (campaign.startTimeIn) campaign.startTimeIn = Array.isArray(campaign.startTimeIn) ? campaign.startTimeIn : [campaign.startTimeIn]

    await campaign.save()
    await campaign.reload()

    if (campaign.type === NotificationScheduleType.Now && notify instanceof NotificationBookingMeetingRoomArgs) {
      this.notificationTrigger(campaign.id)
    }

    return campaign
  }

  private async getListReceivers(notification: any) {
    const officeUsers = await OfficeUser.find({
      where: [
        {phone: In(notification.phones || [])},
        {id: In(notification.userIds || [])}
      ]
    })

    const [departmentUsers, total] = await this.getFilterEmployees(notification.departmentIds || [], notification.titleIds || [])

    return [...new Set([
        ...officeUsers.map(i => i?.id),
        ...departmentUsers.map(i => i?.id),
    ])]
  }
}
