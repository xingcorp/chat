import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import {
    BaseEntity, BeforeInsert, BeforeUpdate,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, JoinColumn, OneToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm"
import { DayOfTheWeek } from "@utils/enum.utils";
import { OfficeWorkingShift } from "@models/entities/working-shifts/working-shift";
import { castValueToDate } from "@utils/common.utils";

registerEnumType(DayOfTheWeek, {name: 'DayOfTheWeek'})

@ObjectType()
@Entity("office-working-shift-detail")
export class OfficeWorkingShiftDetail extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => OfficeWorkingShift, { nullable: false })
    @OneToOne(() => OfficeWorkingShift)
    @JoinColumn()
    workingShift: OfficeWorkingShift

    @Field(_type => Float, {nullable: true})
    @Column({nullable: true})
    startDate: Date

    @Field(_type => Float, {nullable: true})
    @Column({nullable: true})
    endDate: Date

    @Field(_type => [DayOfTheWeek], {nullable: true, defaultValue: []})
    @Column("int",{nullable: true, array: true})
    dayActive: DayOfTheWeek[]

    @Field(_type => Boolean, {nullable: true})
    @Column({nullable: true, default: false})
    active: boolean

    @Field(_type => Float, {nullable: false})
    @Column({nullable: false})
    checkInTime: number

    @Field(_type => Float, {nullable: false})
    @Column({nullable: false})
    checkOutTime: number

    @Field(_type => Float, {nullable: true})
    @Column({nullable: true})
    lunchStartTime: number

    @Field(_type => Float, {nullable: true})
    @Column({nullable: true})
    lunchEndTime: number

    @Field(_type => Float, {nullable: true})
    @Column('decimal', {nullable: true, default: 0, precision: 3, scale: 2})
    noCheckInTimePunishment: number

    @Field(_type => Float, {nullable: true})
    @Column('decimal', {nullable: true, default: 0, precision: 3, scale: 2})
    noCheckOutTimePunishment: number

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


    //listener
    @BeforeInsert()
    @BeforeUpdate()
    castToDate() {
        this.startDate = castValueToDate(this.startDate)
        this.endDate = castValueToDate(this.endDate)
    }
}