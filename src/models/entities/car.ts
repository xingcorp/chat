import { Field, Float, Int, ObjectType } from "@nestjs/graphql"
import { AfterInsert, AfterUpdate, BaseEntity, Column, CreateDateColumn, DeleteDateColumn, Entity, JoinColumn, ManyToOne, OneToMany, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"
import { OfficeOrgChart } from "./org.chart"
import { ObjectStatus } from "./profile.info.block"
import { BookingMeetingRoom } from "./booking/booking.meeting.room"
import { OwnerBase } from "../office.base"
import { OfficeUser } from "./profile.user"


@ObjectType()
@Entity("office-cars")
export class Car extends OwnerBase {
    @Field(_type => String, { nullable: true })
    @PrimaryGeneratedColumn("uuid")
    id: string

    @PrimaryGeneratedColumn()
    no: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    model: string

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    plateNumber: string

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    driverId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    code: string

    @Field(_type => Int, { nullable: true })
    @Column()
    capacity: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    orgChartId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    approvalFormId: string

    @Field(_type => String, { nullable: true })
    @Column()
    color: string

    @Field(_type => ObjectStatus, { nullable: true })
    @Column({ type: 'enum', enum: ObjectStatus, default: ObjectStatus.Active })
    status: ObjectStatus

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @UpdateDateColumn()
    updatedAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    @AfterInsert()
    @AfterUpdate()
    async assignCode() {
        if (this.code) {
            return
        }
        this.code = `C${10000 + this.no}`
        this.save()
    }
}