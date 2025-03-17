import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql"
import { BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, Generated, ILike, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"
import { NotificationSchedule } from "./notification.schedule"
import { NotificationCampaignKind } from "@enum/campaign/campaign.enum";
import { DayOfWeek } from "@common/constant.common";

export enum NotificationCampaignStatus {
    Active = 'Active',
    Inactive = 'Inactive'
}

export enum NotificationScheduleType {
    Now = 'Now',
    Daily = 'Daily',
    Weekly = 'Weekly',
    Monthly = 'Monthly'
}

export enum NotificationObjectType {
    Personal = 'Personal',
    Department = 'Department'
}

registerEnumType(NotificationCampaignStatus, { name: 'NotificationCampaignStatus' })
registerEnumType(NotificationScheduleType, { name: 'NotificationScheduleType' })
registerEnumType(NotificationObjectType, { name: 'NotificationObjectType' })
registerEnumType(NotificationCampaignKind, { name: 'NotificationCampaignKind' })

const NO_START_VALUE: number = 100000

@ObjectType()
@Entity("office-notification-campaigns")
export class NotificationCampaign extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => Float)
    @Column({ nullable: false })
    @Generated('increment')
    no: number

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    title: string

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    content: string

    @Column('text', { nullable: true, array: true })
    attachFileIds: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    attachFileUrls: string[]

    @Column('text', { nullable: true, array: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    imageUrls: string[]

    @Field(_type => NotificationObjectType)
    @Column({ nullable: false, type: 'enum', enum: NotificationObjectType, default: NotificationObjectType.Department })
    objectType: NotificationObjectType

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    phones: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    userIds: string[]

    @Column('text', { nullable: true, array: true })
    departmentIds: string[]

    @Column('text', { nullable: true, array: true })
    titleIds: string[]

    @Field(_type => NotificationScheduleType)
    @Column({ nullable: false, type: 'enum', enum: NotificationScheduleType, default: NotificationScheduleType.Now })
    type: NotificationScheduleType

    /*legacy*/
    // @Field(_type => Int, { nullable: true })
    @Column({ nullable: true })
    startTimeInMinutes: number

    @Field(_type => [Int], { nullable: true })
    @Column('int', { nullable: true, array: true })
    startTimeIn: number[]

    @Field(_type => Float, { nullable: false })
    @Column({ nullable: false, default: 7 })
    timeZone: number

    @Field(_type => [DayOfWeek], { nullable: true })
    @Column({ nullable: true, array: true, type: 'enum', enum: DayOfWeek })
    weekDays: DayOfWeek[]

    @Field(_type => [Int], { nullable: true })
    @Column('int', { nullable: true, array: true })
    monthDays: number[]

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    startAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    endAt: Date

    @Field(_type => NotificationCampaignStatus)
    @Column({ nullable: false, type: 'enum', enum: NotificationCampaignStatus, default: NotificationCampaignStatus.Inactive })
    status: NotificationCampaignStatus

    @Field(_type => NotificationCampaignKind)
    @Column({ nullable: true, type: 'enum', enum: NotificationCampaignKind, default: NotificationCampaignKind.Campaign })
    notifyType: NotificationCampaignKind

    @Column({ nullable: true, default: null })
    notifyTypeId: string

    @Field(_type => Float)
    @CreateDateColumn()
    createdAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date
}