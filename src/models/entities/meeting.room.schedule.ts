import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column,
    DeleteDateColumn,
    Entity,
    JoinColumn, JoinTable,
    ManyToMany,
    ManyToOne,
    PrimaryGeneratedColumn
} from "typeorm";
import { MeetingRoom } from "./meeting.room";
import { BookingMeetingRoom } from "./booking/booking.meeting.room";
import { Base } from "../office.base";
import { OfficeUser } from "@models/entities/profile.user";
import { BRIDGE_TABLE_DB } from "@common/db/bridge-table.db";

export enum EquimentsForMettingRoom {
    Internet = 'Internet',
    Projector = 'Projector',
    OnlineMeetingHCM = 'OnlineMeetingHCM'
}
registerEnumType(EquimentsForMettingRoom, { name: "EquimentsForMettingRoom" });

export enum LogisticsForMettingRoom {
    Candy = 'Candy',
    Flower = 'Flower',
    Water = 'Water'
}
registerEnumType(LogisticsForMettingRoom, { name: "LogisticsForMettingRoom" });

@ObjectType()
@Entity("office-meeting-room-schedule")
export class MeetingRoomSchedule extends Base {
    @Field(_type => Float, { nullable: true })
    @Column()
    startAt: Date

    @Field(_type => Float, { nullable: true })
    @Column()
    endAt: Date

    @Field(_type => MeetingRoom, { nullable: true })
    @ManyToOne(() => MeetingRoom, { nullable: true })
    @JoinColumn()
    meetingRoom: MeetingRoom

    @Column({ nullable: true })
    meetingRoomId: string

    @Field(_type => BookingMeetingRoom, { nullable: true })
    @ManyToOne(() => BookingMeetingRoom)
    @JoinColumn()
    booking: BookingMeetingRoom

    @Column({ nullable: true })
    bookingId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    meetingContent: string

    // @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, { nullable: true })
    host: OfficeUser

    // @Field(_type => [OfficeUser], { nullable: true })
    @ManyToMany(() => OfficeUser, {nullable: true})
    @JoinTable({
        name: BRIDGE_TABLE_DB.MEETING_SCHEDULE_PARTICIPANTS,
    })
    participants: OfficeUser[]

    @Field(_type => Int, { nullable: true })
    @Column({ nullable: true })
    quantity: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    cancelDescription: string

    @Field(_type => [EquimentsForMettingRoom], { nullable: true })
    @Column('text', { nullable: true, array: true })
    equiments: EquimentsForMettingRoom[]
    
    @Field(_type => [LogisticsForMettingRoom], { nullable: true })
    @Column('text', { nullable: true, array: true })
    logistics: LogisticsForMettingRoom[]

    @DeleteDateColumn()
    deletedAt: Date
}
