import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity, BeforeInsert,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity, Generated, JoinTable, ManyToMany,
    PrimaryGeneratedColumn, UpdateDateColumn,
} from "typeorm";
import { OfficeOrgChart } from "@models/entities";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";
import { ActiveStatus } from "@common/enum.common";
import { OrgChartBase } from "@models/office.base";

registerEnumType(ActiveStatus, { name: 'ActiveStatus' })

@ObjectType()
@Entity("office-learn-certifications")
export class LearnCertification extends OrgChartBase {
    @Field({ nullable: true })
    @Column({ nullable: true })
    code: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    name: string

    @Field(_type => ActiveStatus, { nullable: true })
    @Column({ nullable: true, default: ActiveStatus.Active })
    status: ActiveStatus

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    /*Method*/

    /*Listener*/
    @BeforeInsert()
    async genData() {
    }
}