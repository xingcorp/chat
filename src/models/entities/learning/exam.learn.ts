import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity, BeforeInsert,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity, Generated, JoinTable, ManyToMany,
    ManyToOne,
    PrimaryGeneratedColumn, UpdateDateColumn,
} from "typeorm";
import { LearnProject, OfficeOrgChart } from "@models/entities";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";
import { ActiveStatus } from "@common/enum.common";

registerEnumType(ActiveStatus, { name: 'ActiveStatus' })

@ObjectType()
@Entity("office-learn-examinations")
export class LearnExaminations extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    code: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    name: string

    @Field(_type => ActiveStatus, { nullable: true })
    @Column({ nullable: true, default: ActiveStatus.Active })
    status: ActiveStatus

    @Field(_type => Float, { nullable: true })
    @CreateDateColumn()
    createdAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field(_type => Float, { nullable: true })
    @UpdateDateColumn()
    updatedAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    @ManyToOne(() => LearnProject, (ob) => ob.examinations)
    project: LearnProject

    /*Method*/

    /*Listener*/
    @BeforeInsert()
    async genData() {
    }
}