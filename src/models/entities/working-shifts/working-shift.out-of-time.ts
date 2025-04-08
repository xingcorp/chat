import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import {
    BaseEntity,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, JoinColumn, ManyToOne, OneToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm"
import { DayOfTheWeek } from "@utils/enum.utils";
import { OfficeWorkingShift } from "@models/entities/working-shifts/working-shift";

export enum OutOfTime {
    Soon,
    Late
}

export enum WorkShiftOutOfTimePunishment {
    Pass,
    Late,
    Fixed,
    FollowTime
}

registerEnumType(OutOfTime, {name: 'OutOfTime'})
registerEnumType(WorkShiftOutOfTimePunishment, {name: 'WorkShiftOutOfTimePunishment'})

@ObjectType()
@Entity("office-working-shift-out-of-time")
export class OfficeWorkingShiftOutOfTime extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => OfficeWorkingShift, { nullable: false })
    @ManyToOne(() => OfficeWorkingShift, (shift) => shift.outOfTimes)
    workingShift: OfficeWorkingShift

    @Field(_type => OutOfTime, {nullable: false})
    @Column({nullable: false})
    type: OutOfTime

    @Field(_type => Float, {nullable: false})
    @Column({nullable: false})
    from: number

    @Field(_type => Float, {nullable: false})
    @Column({nullable: false})
    to: number

    @Field(_type => WorkShiftOutOfTimePunishment, {nullable: false})
    @Column({nullable: false})
    punishmentType: WorkShiftOutOfTimePunishment

    @Field(_type => Float, {nullable: true})
    @Column('decimal', {nullable: true, precision: 3, scale: 2})
    punishmentValue: number

    @Field(_type => Float)
    @CreateDateColumn()
    createdAt: Date

    @Field({nullable: true})
    @Column({nullable: true})
    createdBy: string

    @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    @Field({nullable: true})
    @Column({nullable: true})
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date
}