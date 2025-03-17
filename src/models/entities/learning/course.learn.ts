import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BeforeInsert,
    Column,
    Entity, ManyToOne, OneToMany,
} from "typeorm";
import { LearnProject, LearnSection, LearnStudent, OfficeUser } from "@models/entities";
import {
    CourseJoinTypeEnum,
    CourseProposerTypeEnum,
    CourseStatusEnum,
    CourseTrainTypeEnum
} from "@enum/learning/learning.enum";
import { OwnerBase } from "@models/office.base";
import { DayOfWeek } from "@common/constant.common";
import { LearningUserPinned } from "./pinned.learn";

registerEnumType(CourseStatusEnum, { name: 'CourseStatusEnum' })
registerEnumType(CourseJoinTypeEnum, { name: 'CourseJoinTypeEnum' })
registerEnumType(CourseTrainTypeEnum, { name: 'CourseTrainTypeEnum' })
registerEnumType(CourseProposerTypeEnum, { name: 'CourseProposerTypeEnum' })

@ObjectType()
@Entity("office-learn-courses")
export class LearnCourse extends OwnerBase {
    @Field({ nullable: true })
    @Column({ nullable: true })
    code: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    name: string

    @Field(_type => CourseStatusEnum, { nullable: true })
    @Column({ nullable: true, default: CourseStatusEnum.ACTIVE })
    status: CourseStatusEnum

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    startClassAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    closeClassAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    timeStartAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    timeCloseAt: Date

    @Field(_type => CourseJoinTypeEnum, { nullable: true })
    @Column({ nullable: true, default: CourseJoinTypeEnum.FREE })
    joinType: CourseJoinTypeEnum

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    enrollStartAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    enrollEndAt: Date

    @Field(_type => Int, { nullable: true })
    @Column('int', { nullable: true })
    totalStudent: number

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    totalTimeTraining: number

    @Field(_type => Int, { nullable: true })
    @Column({ nullable: true })
    estimateDeadline: number

    @Column({ nullable: true })
    deadlineAt: Date

    @Field(_type => [DayOfWeek], { nullable: true })
    @Column('simple-array', { nullable: true })
    pickedDays: DayOfWeek[]

    @Field(_type => [CourseTrainTypeEnum], { nullable: true })
    @Column('simple-array', { nullable: true })
    trainingTypes: CourseTrainTypeEnum[]

    @Field(_type => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    trainingAddressIds: string[]

    @Field(_type => CourseProposerTypeEnum, { nullable: true })
    @Column({ nullable: true })
    proposerType: CourseProposerTypeEnum

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    deletedBy: string

    /*Relation*/
    @Field(_type => LearnProject, { nullable: true })
    @ManyToOne(() => LearnProject, (ob) => ob.courses)
    project: LearnProject

    @Field({ nullable: true })
    @Column({ nullable: true })
    projectId: string

    @OneToMany(() => LearningUserPinned, (ob) => ob.course)
    userPinned: LearningUserPinned[]

    @Field(_type => CourseProposerTypeEnum, { nullable: true })
    @Column({ nullable: true })
    teacherType: CourseProposerTypeEnum

    @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, (ob) => ob.courses)
    teacher: OfficeUser

    @Column({ nullable: true })
    teacherId: string

    @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, (ob) => ob.courses)
    proposer: OfficeUser

    @Field({ nullable: true })
    @Column({ nullable: true })
    proposerId: string

    @Field(_type => [LearnSection], { nullable: true })
    @OneToMany(() => LearnSection, (ob) => ob.course)
    sections: LearnSection[]

    @Field(_type => [LearnStudent], { nullable: true })
    @OneToMany(() => LearnStudent, (ob) => ob.course)
    students: LearnStudent[]

    /*Method*/

    /*Listener*/
    @BeforeInsert()
    async genData() {
        if (this.estimateDeadline && this.startClassAt) {
            this.deadlineAt = new Date(new Date(this.startClassAt).getTime() + this.estimateDeadline * 24 * 60 * 60 * 1000)
        }
    }
}