import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column,
    Entity,
    JoinColumn,
    ManyToOne,
    PrimaryGeneratedColumn
} from "typeorm";
import { OfficeUser } from "./profile.user";
import { BookingMeetingRoom } from "./booking/booking.meeting.room";
import { LearnStudent } from "./learning/student.learn";

export enum ScheduleType {
    Meeting = 'Meeting',
    Learning = 'Learning',
    Other = 'Other'
}

registerEnumType(ScheduleType, { name: 'ScheduleType' })

export enum ScheduleTypeColor {
    Meeting = '#10B981',
    Learning = '#3b82f6',
    Other = '#F59E0B'
}
registerEnumType(ScheduleTypeColor, { name: 'ScheduleTypeColor' })

@ObjectType()
@Entity("office-user-schedule")
export class UserSchedule extends BaseEntity {
    @Field(_type => String,)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    title: string

    @ManyToOne(() => OfficeUser, { nullable: true })
    @JoinColumn()
    owner: OfficeUser

    @Column()
    ownerId: string

    @Field(_type => Float, { nullable: true })
    @Column()
    startAt: Date

    @Field(_type => Float, { nullable: true })
    @Column()
    endAt: Date

    @Field(_type => ScheduleType, { nullable: true })
    @Column({ default: ScheduleType.Other })
    type: ScheduleType

    @Field(_type => ScheduleTypeColor, { nullable: true })
    color: ScheduleTypeColor

    @Field(_type => BookingMeetingRoom, { nullable: true })
    @ManyToOne(() => BookingMeetingRoom)
    @JoinColumn()
    meeting: BookingMeetingRoom

    @Column({ nullable: true })
    meetingId: string

    @Field(_type => LearnStudent, { nullable: true })
    @ManyToOne(() => LearnStudent, { onDelete: 'CASCADE' })
    @JoinColumn()
    learnStudent: LearnStudent

    @Column({ nullable: true })
    learnStudentId: string
}