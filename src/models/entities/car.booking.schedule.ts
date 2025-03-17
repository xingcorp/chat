import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import {
    BaseEntity,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, JoinColumn,
    ManyToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm"
import { CarBookingRequest } from "@models/entities/car.booking.request";

@ObjectType()
@Entity("office-car-booking-schedules")
export class CarBookingSchedule extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => Float, { nullable: false })
    @Column({ nullable: false })
    startAt: Date

    @Field(_type => Float, { nullable: false })
    @Column({ nullable: false })
    endAt: Date

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    carId: string

    // @Field(_type => String, { nullable: true })
    // @Column({ nullable: true })
    // note: string

    @Field(_type => CarBookingRequest, { nullable: true })
    @ManyToOne(() => CarBookingRequest)
    booking: CarBookingRequest

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    requestId: string

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    remindAt: Date

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    fromAddress: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    toAddress: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    cancelDescription: string

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