import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity,
    BeforeInsert,
    BeforeUpdate,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity,
    Index,
    PrimaryGeneratedColumn, UpdateDateColumn,
} from "typeorm";
import { CloneDatePeriodEnum, CloneDateTypeEnum } from "@enum/clone/date.clone.enum";
import GraphQLJSON from "graphql-type-json";
import { DayOfWeek } from "@common/constant.common";

@ObjectType()
export class CustomDayTaskReportConfig {
    @Field(() => Int, { nullable: true })
    month: number

    @Field(() => [Int], { nullable: true })
    days: number[]
}

@ObjectType()
@Entity("office-clone-by-dates")
export class CloneByDate extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Index()
    @Column({ nullable: true })
    relationType: CloneDateTypeEnum

    @Column({ nullable: true })
    relationId: string

    @Field(_type => GraphQLJSON, { nullable: true })
    @Column({
        type: "jsonb",
        nullable: true,
    })
    relationData: any

    @Field(_type => CloneDatePeriodEnum)
    @Column({ nullable: true })
    periodType: CloneDatePeriodEnum

    @Index()
    @Field(_type => [Int], { nullable: true })
    @Column('simple-array', { nullable: true })
    startTimeIn: number[]

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true, default: 7 })
    timeZone: number

    @Field(_type => [DayOfWeek], { nullable: true })
    @Column('simple-array', { nullable: true })
    weekDays: DayOfWeek[]

    @Field(_type => [Int], { nullable: true })
    @Column('simple-array', { nullable: true })
    monthDays: number[]

    @Field(() => [CustomDayTaskReportConfig], { nullable: true })
    @Column('jsonb', { nullable: true })
    customDays: CustomDayTaskReportConfig[]

    // @Index()
    @Column({ nullable: true })
    customDaysSearch: string

    @Index()
    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    startAt: Date

    @Index()
    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    endAt: Date

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

    @BeforeUpdate()
    @BeforeInsert()
    setCustomDaysSearch() {
        if (this.customDays) {
            const customDayArr = []
            this.customDays.forEach(i => {
                i.days.forEach(j => {
                    customDayArr.push(`${i.month}-${j}`)
                })
            })

            this.customDaysSearch = JSON.stringify(customDayArr)
        }
    }
}