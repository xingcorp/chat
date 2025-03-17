import { Field, Float, Int, ObjectType } from "@nestjs/graphql"
import {
    BeforeInsert,
    BeforeUpdate,
    Column,
    DeleteDateColumn,
    Entity,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm"
import { OfficeOrgChart } from "./org.chart"
import { ObjectStatus } from "./profile.info.block"
import { BookingMeetingRoom } from "./booking/booking.meeting.room"
import { OwnerBase } from "../office.base"
import { OfficeUser } from "./profile.user"
import { stringNumberWithZeroLeading } from "@utils/string.utils";


@ObjectType()
@Entity("office-meeting-room")
export class MeetingRoom extends OwnerBase {
    @Field(_type => String, { nullable: true })
    @PrimaryGeneratedColumn("uuid")
    id: string

    @PrimaryGeneratedColumn()
    no: number

    @Field(_type => String, { nullable: true })
    @Column()
    name: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    code: string

    @Field(_type => Int, { nullable: true })
    @Column()
    capacity: number

    @Field(_type => OfficeOrgChart, { nullable: true })
    orgChart: OfficeOrgChart

    @Field(_type => String, { nullable: true })
    @Column()
    color: string

    @Field(_type => ObjectStatus, { nullable: true })
    @Column({ type: 'enum', enum: ObjectStatus, default: ObjectStatus.Active })
    status: ObjectStatus

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    approvalFormId: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdById: string

    @UpdateDateColumn()
    updatedAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    @BeforeInsert()
    @BeforeUpdate()
    async assignCode() {
        if (this.no) {
            this.code = `P${stringNumberWithZeroLeading(this.no)}`
            return
        }

        const qb = await MeetingRoom.createQueryBuilder('qb')
            .orderBy('qb.no', 'DESC')
            .getOne()

        const no = qb?.no ? qb.no + 1 : 1

        this.code = `P${stringNumberWithZeroLeading(no)}`
    }
}