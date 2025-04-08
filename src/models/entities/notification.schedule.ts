import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql"
import { BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, Generated, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"

export enum NotificationStatus {
    Error = 'Error',
    InQueue = 'InQueue',
    Sent = 'Sent',
    DealLetter = 'DealLetter'
}
registerEnumType(NotificationStatus, { name: 'NotificationStatus' })

@ObjectType()
@Entity("office-notification-schedules")
export class NotificationSchedule extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => Float)
    @Column({ nullable: false })
    @Generated('increment')
    no: number

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    campaignId: string

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    receiverIds: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    iamReceiverIds: string[]

    @Column({ nullable: true })
    metadata: string

    @Field(_type => Float, { nullable: false })
    @Column({ nullable: false })
    scheduleAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    pushAt: Date

    @Column({ nullable: true })
    iamRecordId: string

    @Column({ nullable: true })
    iamPushResult: string

    @Field(_type => NotificationStatus)
    @Column({ nullable: false, type: 'enum', enum: NotificationStatus, default: NotificationStatus.InQueue })
    status: NotificationStatus

    @Field(_type => Float)
    @CreateDateColumn()
    createdAt: Date

    // @Field({ nullable: true })
    // @Column({ nullable: true })
    // createdBy: string

    @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    // @Field({ nullable: true })
    // @Column({ nullable: true })
    // updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    @BeforeInsert()
    async beforeInsert() {
        // const date = new Date().toLocaleDateString('en-US', {timeZone: 'Asia/Jakarta'})
        // const dateArr = date.split("/")
        // const prefix = 'PDX_' + (dateArr[1].length === 2 ? dateArr[1] : ("0" + dateArr[1])) + (dateArr[0].length === 2 ? dateArr[0] : ("0" + dateArr[0])) + dateArr[2].substring(2)
        // const lastestNo = await CarBookingRequest.findOne({
        //     where: {
        //         code: ILike(`${prefix}%`)
        //     },
        //     order: {
        //         no: "DESC"
        //     }
        // })
        // this.no = lastestNo ? lastestNo.no + 1 : 1
        
        // this.code = prefix + `_${NO_START_VALUE + this.no}`.substring(1)
    }
}