import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column,
    Entity, ManyToOne, OneToMany,
    PrimaryGeneratedColumn,
} from "typeorm";
import { OfficeOrgChart, OfficeTask } from "@models/entities";


@ObjectType()
@Entity("office-task-projects")
export class OfficeTaskProject extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({nullable: true})
    key: string

    @Field(_type => Boolean, {nullable: true, defaultValue: true})
    @Column({nullable: true, default: true})
    showKey: boolean

    @Field(_type => String)
    @Column({nullable: true})
    name: string

    @Field(_type => OfficeOrgChart, { nullable: true })
    @ManyToOne(() => OfficeOrgChart, (ob) => ob.projects, {
        eager: true
    })
    rootOrg: OfficeOrgChart

    @Field(_type => OfficeTask, { nullable: true })
    @OneToMany(() => OfficeTask, (ob) => ob.project)
    tasks: OfficeTask[]
}