import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql"
import { BaseEntity, BeforeInsert, Column, DeleteDateColumn, Entity, ILike, JoinColumn, JoinTable, ManyToMany, ManyToOne, PrimaryGeneratedColumn } from "typeorm"
import { OfficeUser } from "../profile.user"
import { OfficeOrgChart } from "../org.chart"
import { MeetingRoom } from "../meeting.room"
import { RequestStatus } from "../car.booking.request"
import { Base } from "../../office.base"

export enum RepeatedDay {
    Sunday,
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,
}
registerEnumType(RepeatedDay, { name: 'RepeatedDay' })

const NO_START_VALUE: number = 100000

@ObjectType()
@Entity("office-booking-meeting-room")
export class BookingMeetingRoom extends Base {
    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    // @Generated('increment')
    no: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    code: string

    @ManyToOne(() => OfficeOrgChart, { nullable: true })
    @JoinColumn()
    organization: OfficeOrgChart

    @Column({ nullable: true })
    organizationId: string

    @Field(_type => String, { nullable: true })
    @Column()
    meetingContent: string

    // @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, { nullable: true })
    @JoinColumn()
    bookedBy: OfficeUser

    @Column({ nullable: true})
    bookedById: string

    @Column({ nullable: true})
    createdById: string

    @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, { nullable: true })
    @JoinColumn()
    host: OfficeUser

    @Column()
    hostId: string

    @Field(_type => [OfficeUser], { nullable: true })
    @ManyToMany(() => OfficeUser)
    @JoinTable()
    participants: OfficeUser[]

    @Column('text', { nullable: true, array: true })
    participantIds: string[]

    @Field(_type => MeetingRoom, { nullable: true })
    @ManyToOne(() => MeetingRoom, { eager: true})
    @JoinColumn()
    meetingRoom: MeetingRoom

    @Column({ nullable: true })
    meetingRoomId: string

    @Field(_type => Int, { nullable: true })
    @Column()
    quantity: number

    @Field(_type => Float, { nullable: true })
    @Column()
    startAt: Date

    @Field(_type => Float, { nullable: true })
    @Column()
    endAt: Date

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    @Field(_type => RequestStatus)
    @Column({ nullable: false, type: 'enum', enum: RequestStatus, default: RequestStatus.UnderReview })
    status: RequestStatus

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    approvalId: string

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    repeatedEndAt: Date

    @Field(_type => [Int], { nullable: true })
    @Column('text', { nullable: true, array: true })
    repeatedDays: RepeatedDay[]

    @Column({ nullable: true })
    updatedById: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    cancelDescription: string

    @Field(_type => Float, { nullable: true })
    @DeleteDateColumn()
    canceledAt: Date

    @BeforeInsert()
    async beforeInsert() {
        const date = new Date().toLocaleDateString('en-US', {timeZone: 'Asia/Jakarta'})
        const dateArr = date.split("/")
        const prefix = 'PDP_' + (dateArr[1].length === 2 ? dateArr[1] : ("0" + dateArr[1])) + (dateArr[0].length === 2 ? dateArr[0] : ("0" + dateArr[0])) + dateArr[2].substring(2)
        const lastestNo = await BookingMeetingRoom.findOne({
            where: {
                code: ILike(`${prefix}%`)
            },
            order: {
                no: "DESC"
            }
        })
        this.no = lastestNo ? lastestNo.no + 1 : 1
        
        this.code = prefix + `_${NO_START_VALUE + this.no}`.substring(1)
    }
}