import { Field, Float, ObjectType } from "@nestjs/graphql";
import {
    BeforeInsert,
    Column,
    Entity, ManyToOne,
} from "typeorm";
import { LearnCourse, OfficeUser } from "@models/entities";
import { Base } from "@models/office.base";

@ObjectType()
@Entity("office-learn-students")
export class LearnStudent extends Base {

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true, default: new Date() })
    joinedAt: Date

    @Field(_type => LearnCourse, { nullable: true })
    @ManyToOne(() => LearnCourse, ob => ob.students)
    course: LearnCourse

    @Column()
    courseId: string

    @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, ob => ob.learnStudents)
    user: OfficeUser

    @Column()
    userId: string
    /*Method*/

    /*Listener*/
    @BeforeInsert()
    async genData() {
    }
}