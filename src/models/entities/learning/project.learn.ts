import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BeforeInsert,
    Column,
    Entity, JoinTable, ManyToMany, OneToMany,
} from "typeorm";
import {
    LearnCertification,
    LearnCourse,
    LearnAddress,
    LearnSkill,
    OfficeOrgChart,
} from "@models/entities";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";
import { LearnProjectStatusEnum, ProjectTimeTypeEnum } from "@enum/learning/learning.enum";
import { OrgChartBase } from "@models/office.base";
import { LearningUserPinned } from "./pinned.learn";

registerEnumType(LearnProjectStatusEnum, { name: 'LearnProjectStatusEnum' })
registerEnumType(ProjectTimeTypeEnum, { name: 'ProjectTimeTypeEnum' })

@ObjectType()
@Entity("office-learn-projects")
export class LearnProject extends OrgChartBase {
    @Field({ nullable: true })
    @Column({ nullable: true })
    code: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    name: string

    @Field(_type => LearnProjectStatusEnum, { nullable: true })
    @Column({ nullable: true, default: LearnProjectStatusEnum.ACTIVE })
    status: LearnProjectStatusEnum

    @Field(_type => Boolean, { nullable: true })
    @Column({ default: false })
    isHide: boolean

    @Field(_type => ProjectTimeTypeEnum, { nullable: true })
    @Column({ nullable: true, default: ProjectTimeTypeEnum.PERIOD })
    timeType: ProjectTimeTypeEnum

    @Field(_type => Int, { nullable: true })
    @Column('int', { nullable: true })
    dayOfEvent: number

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    startDate: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    endDate: Date

    @Field({ nullable: true })
    @Column('text', { nullable: true })
    summary: string

    @Field({ nullable: true })
    @Column('text', { nullable: true })
    content: string

    @Field(_type => Int, { nullable: true })
    @Column('int', { nullable: true, default: 0 })
    maxNumberOfStudent: number

    @Column('text', { nullable: true, array: true })
    avatarIds: string[]

    @Column('text', { nullable: true, array: true })
    videoIds: string[]

    @Field(() => Float, { nullable: true })
    @Column({ nullable: true })
    timeToPass: number

    @Field(() => Float, { nullable: true })
    @Column({ nullable: true })
    scoreToPass: number

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    deletedBy: string

    @Field(_type => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    requiredLearnExaminationIds: string[]

    @Field(_type => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    requiredLearnProjectIds: string[]

    @Field(_type => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    requiredSurveyIds: string[]

    @Field(_type => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    requiredCertificateIds: string[]

    /*Relation*/
    @ManyToMany(() => LearnSkill)
    @JoinTable(BRIDGE_TABLE_DB_OBJ.LEARNING_PROJECT_SKILL)
    skills: LearnSkill[]

    @ManyToMany(() => LearnAddress)
    @JoinTable(BRIDGE_TABLE_DB_OBJ.LEARNING_ADDRESS_PROJECT)
    address: LearnAddress[]

    @ManyToMany(() => LearnCertification)
    @JoinTable(BRIDGE_TABLE_DB_OBJ.LEARNING_PROJECT_CERTIFICATE)
    certificates: LearnCertification[]

    @ManyToMany(() => OfficeOrgChart)
    @JoinTable(BRIDGE_TABLE_DB_OBJ.LEARNING_PROJECT_DEPARTMENT)
    departments: OfficeOrgChart[]

    @OneToMany(() => LearnCourse, (ob) => ob.project)
    courses: LearnCourse[]

    @OneToMany(() => LearningUserPinned, (ob) => ob.project)
    userPinned: LearningUserPinned[]

    @OneToMany(() => LearnCourse, (ob) => ob.project)
    examinations: LearnCourse[]

    /*Listener*/
    @BeforeInsert()
    async genData() {
    }
}