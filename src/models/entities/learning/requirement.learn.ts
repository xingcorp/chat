import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity, BeforeInsert,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity, Generated, JoinColumn, JoinTable, ManyToMany, OneToOne,
    PrimaryGeneratedColumn, UpdateDateColumn,
} from "typeorm";
import { LearnCertification, LearnProject } from "@models/entities";
import { ActiveStatus } from "@common/enum.common";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";

registerEnumType(ActiveStatus, { name: 'ActiveStatus' })

@ObjectType()
@Entity("office-learn-requirements")
export class LearnRequirement extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => Float)
    @Column({ nullable: true })
    @Generated('increment')
    no: number

    @Field({ nullable: true })
    @Column({ nullable: true })
    code: string

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

    @ManyToMany(() => LearnProject)
    @JoinTable(BRIDGE_TABLE_DB_OBJ.LEARNING_REQUIREMENT_PROJECT)
    projects: LearnProject[]

    @ManyToMany(() => LearnCertification)
    @JoinTable(BRIDGE_TABLE_DB_OBJ.LEARNING_REQUIREMENT_CERTIFICATE)
    certificates: LearnCertification[]

    /*Method*/

    /*Listener*/
    @BeforeInsert()
    async genData() {
    }
}