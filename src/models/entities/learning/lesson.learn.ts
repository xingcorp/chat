import { Field, Int, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BeforeUpdate,
    Column,
    Entity, ManyToOne,
    PrimaryGeneratedColumn,
} from "typeorm";
import { ActiveStatus } from "@common/enum.common";
import { LessonMediaTypeEnum } from "@enum/learning/learning.enum";
import { LearnSection } from "@models/entities";
import { Base } from "@models/office.base";

registerEnumType(ActiveStatus, { name: 'ActiveStatus' })
registerEnumType(LessonMediaTypeEnum, { name: 'LessonMediaTypeEnum' })

@ObjectType()
@Entity("office-learn-lessons")
export class LearnLesson extends Base {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    name: string

    @Field(_type => Int, { nullable: true })
    @Column('int', { nullable: true })
    order: number

    @Field({ nullable: true })
    @Column('text', { nullable: true })
    description: string

    @Field(_type => LessonMediaTypeEnum, { nullable: true })
    @Column({ nullable: true })
    mediaType: LessonMediaTypeEnum

    @Field(_type => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    embedUrls: string[]

    @Column('text', { nullable: true, array: true })
    attachmentIds: string[]

    @Field(_type => ActiveStatus, { nullable: true })
    @Column({ nullable: true, default: ActiveStatus.Active })
    status: ActiveStatus

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @ManyToOne(() => LearnSection, (ob) => ob.lessons, { onDelete: 'CASCADE' })
    section: LearnSection

    @Column()
    sectionId: string

    @BeforeUpdate()
    async genData() {
    }
}