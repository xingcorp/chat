import { Field, ObjectType } from "@nestjs/graphql";
import { Column, Entity, ManyToOne } from "typeorm";
import { Base } from "@models/office.base";
import { LearnCourse } from "./course.learn";
import { LearnProject } from "./project.learn";

@ObjectType()
@Entity("relation-learning-user-pinned")
export class LearningUserPinned extends Base {
    @Field(_type => LearnCourse, { nullable: true })
    @ManyToOne(() => LearnCourse, ob => ob.userPinned, { onDelete: 'CASCADE' })
    course: LearnCourse

    @Column({ nullable: true })
    courseId: string

    @Field(_type => LearnProject, { nullable: true })
    @ManyToOne(() => LearnProject, ob => ob.userPinned, { onDelete: 'CASCADE' })
    project: LearnProject

    @Column({ nullable: true })
    projectId: string

    @Column({ nullable: true })
    userId: string
}