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

export enum OverTime {
    Before,
    After
}

registerEnumType(OverTime, {name: 'OverTime'})

@ObjectType()
@Entity("office-working-shift-over-time")
export class OfficeWorkingShiftOverTime extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => OfficeWorkingShift, { nullable: false })
    @ManyToOne(() => OfficeWorkingShift, (shift) => shift.outOfTimes)
    workingShift: OfficeWorkingShift

    @Field(_type => OverTime, {nullable: false})
    @Column({nullable: false})
    type: OverTime

    @Field(_type => Float, {nullable: true})
    @Column({nullable: true})
    minTime: number

    @Field(_type => Float, {nullable: true})
    @Column({nullable: true})
    maxTime: number

    @Field(_type => Float, {nullable: true})
    @Column({nullable: true})
    startTime: number

    @Field(_type => Boolean, {nullable: true})
    @Column({nullable: true})
    isStartAfterEndShift: boolean

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