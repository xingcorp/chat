import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import { BaseEntity, Column, DeleteDateColumn, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from "typeorm"
import { OfficeUser } from "../profile.user"

export enum BookingCarProgress {
    Waiting_For_Approval = 'Waiting_For_Approval',
    Leader_Approve = 'Leader_Approve',
    Reject = 'Rejected',
    Approve = 'Approved',
    Canceled = 'Canceled',
}
registerEnumType(BookingCarProgress, { name: 'BookingCarProgress' })

@ObjectType()
@Entity("office-booking-car")
export class BookingCar extends BaseEntity {
    @Field(_type => String, { nullable: true })
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, { nullable: true })
    @JoinColumn()
    bookedBy: OfficeUser

    @Column()
    bookedById: string

    @Field(_type => Float, { nullable: true })
    @Column()
    startAt: Date

    @Field(_type => Float, { nullable: true })
    @Column()
    endAt: Date

    @Field(_type => String, { nullable: true })
    @Column()
    carType: string

    @Field(_type => String, { nullable: true })
    @Column("text", { nullable: true })
    note: string

    @Field(_type => String, { nullable: true })
    @Column()
    pickupAddress: string

    @Field(_type => String)
    @Column()
    destinationAddress: string

    @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, { nullable: true })
    @JoinColumn()
    leader: OfficeUser

    @Column({ nullable: true })
    leaderId: string

    @Field(_type => String, { nullable: true })
    @Column("text", { nullable: true })
    noteFromLeader: string

    @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, { nullable: true })
    @JoinColumn()
    admin: OfficeUser

    @Column({ nullable: true })
    adminId: string

    @Field(_type => String, { nullable: true })
    @Column("text", { nullable: true })
    noteFromAdmin: string

    @Field(_type => BookingCarProgress, { nullable: true })
    @Column({ default: BookingCarProgress.Waiting_For_Approval })
    progress: BookingCarProgress

    @DeleteDateColumn()
    deletedAt: Date
}