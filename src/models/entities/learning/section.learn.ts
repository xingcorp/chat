import { Field, Int, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BeforeInsert,
    Column,
    Entity, ManyToOne, OneToMany,
} from "typeorm";
import { ActiveStatus } from "@common/enum.common";
import { LearnCourse, LearnLesson } from "@models/entities";
import { Base } from "@models/office.base";

registerEnumType(ActiveStatus, { name: 'ActiveStatus' })

@ObjectType()
@Entity("office-learn-sections")
export class LearnSection extends Base {
    @Field({ nullable: true })
    @Column({ nullable: true })
    code: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    name: string

    @Field(_type => Int, { nullable: true })
    @Column('int', { nullable: true })
    order: number

    @Field({ nullable: true })
    @Column({ nullable: true })
    description: string

    @Field(_type => ActiveStatus, { nullable: true })
    @Column({ nullable: true, default: ActiveStatus.Active })
    status: ActiveStatus

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    /*Relation*/
    @ManyToOne(() => LearnCourse, (ob) => ob.sections)
    course: LearnCourse

    @Field({ nullable: true })
    @Column()
    courseId: string

    @OneToMany(() => LearnLesson, (ob) => ob.section)
    lessons: LearnLesson[]

    /*Method*/

    /*Listener*/
    @BeforeInsert()
    async genData() {
    }
}