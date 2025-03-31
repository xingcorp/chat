import {
  Args,
  Field,
  InputType,
  Int,
  Mutation,
  ObjectType,
  Query,
  Resolver
} from '@nestjs/graphql'
import { IsUUID } from 'class-validator'
import { CurrentRequest } from '../../middleware/decorator/request.decorator'
import { NotificationService } from './notification.service'
import { Request } from 'express'
import { Notification } from '../objects/notification'
import { AppNotificationResponse } from './notification.response'
import { AppNotificationUpdateAllArgs } from './notification.args'

@InputType()
export class AppNotificationFilterArgs {
  @Field(() => Int, { nullable: true, defaultValue: 0 })
  page?: number

  @Field(() => Int, { nullable: true, defaultValue: 100 })
  size?: number

  @Field(() => Boolean, { nullable: true })
  isRead: boolean

  @Field(() => String, { nullable: true })
  keyword: string
}

@InputType()
export class AppNotificationUpdateArgs {
  @Field(() => String, { nullable: false })
  @IsUUID()
  noticationId: string

  @Field(() => Boolean, { nullable: true })
  isRead: boolean
}

@ObjectType()
export class NotificationResponse {
  @Field(() => Int, { defaultValue: 0 })
  total: number

  @Field(() => Int, { defaultValue: 0 })
  count: number

  @Field(() => [Notification], { nullable: true })
  notifications?: Notification[]
}

@Resolver()
export class AppNotificationResolver {
  constructor(private readonly notificationService: NotificationService) {}

  @Query(() => NotificationResponse, {
    name: 'appNotificationGetList'
  })
  async getList(
    @Args('filter', { nullable: true }) _filter: AppNotificationFilterArgs,
    @CurrentRequest() request: Request
  ): Promise<NotificationResponse> {
    return this.notificationService.forwardRequest(request)
  }

  @Query(() => NotificationResponse, {
    name: 'notificationGetList'
  })
  async notificationGetList(
    @Args('filter', { nullable: true }) _filter: AppNotificationFilterArgs,
    @CurrentRequest() request: Request
  ): Promise<NotificationResponse> {
    return this.notificationService.forwardRequest(request)
  }

  @Mutation(() => Notification, { name: 'appNotificationGetDetail' })
  async detail(
    @Args('id', { nullable: false }) _id: string,
    @CurrentRequest() request: Request
  ): Promise<Notification> {
    return this.notificationService.forwardRequest(request)
  }

  @Mutation(() => Notification, { name: 'appNotificationUpdate' })
  async update(
    @Args('arguments', { nullable: false }) args: AppNotificationUpdateArgs,
    @CurrentRequest() request: Request
  ): Promise<Notification> {
    return this.notificationService.forwardRequest(request)
  }

  @Mutation(() => AppNotificationResponse, { name: 'appNotificationUpdateAll' })
  async updateAll(
    @Args('arguments', { nullable: false }) args: AppNotificationUpdateAllArgs,
    @CurrentRequest() request: Request
  ): Promise<AppNotificationResponse> {
    return this.notificationService.forwardRequest(request)
  }

  @Mutation(() => Notification, { name: 'appNotificationRemove' })
  async remove(
    @Args('id', { nullable: false }) _id: string,
    @CurrentRequest() request: Request
  ): Promise<Notification> {
    return this.notificationService.forwardRequest(request)
  }
}
