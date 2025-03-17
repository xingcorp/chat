import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity, BeforeInsert,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity, Generated, Index, JoinTable, ManyToMany,
    PrimaryGeneratedColumn, UpdateDateColumn,
} from "typeorm";
import { OfficeOrgChart } from "@models/entities";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";
import { ActiveStatus } from "@common/enum.common";
import { OrgChartBase } from "@models/office.base";

registerEnumType(ActiveStatus, { name: 'ActiveStatus' })

@ObjectType()
@Entity("office-learn-skills")
export class LearnSkill extends OrgChartBase {
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

    @Field(_type => String, { nullable: false })
    @Index()
    @Column({ nullable: false, default: 'root'})
    parentId: string

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

    /*Method*/

    /*Listener*/
    @BeforeInsert()
    async genData() {
    }
}