import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import {
    BaseEntity, BeforeInsert, BeforeUpdate,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, OneToMany, OneToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm"
import { DayOfTheWeek } from "@utils/enum.utils";
import { OfficeWorkingShiftDetail, OfficeWorkingShiftOutOfTime, OfficeWorkingShiftOverTime } from "@models/entities";

registerEnumType(DayOfTheWeek, {name: 'DayOfTheWeek'})

@ObjectType()
@Entity("office-working-shift")
export class OfficeWorkingShift extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({nullable: false})
    name: string

    @Field(_type => String, {nullable: false})
    @Column({nullable: false})
    code: string

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

    @OneToOne(() => OfficeWorkingShiftDetail, (detail) => detail.workingShift)
    detail: OfficeWorkingShiftDetail

    @Field(_type => OfficeWorkingShiftOutOfTime, { nullable: true })
    @OneToMany(() => OfficeWorkingShiftOutOfTime, (oot) => oot.workingShift)
    outOfTimes: OfficeWorkingShiftOutOfTime[]

    @Field(_type => OfficeWorkingShiftOverTime, { nullable: true })
    @OneToMany(() => OfficeWorkingShiftOverTime, (oot) => oot.workingShift)
    overTimes: OfficeWorkingShiftOverTime[]
}