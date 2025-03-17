import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, JoinTable, ManyToMany,
    ManyToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm";
import { ObjectStatus } from "./profile.info.block";
import { OfficeOrgChart } from "@models/entities/org.chart";
import { ActiveStatus } from "@common/enum.common";
import { BRIDGE_TABLE_DB } from "@common/db/bridge-table.db";
import { ApprovalForm } from "@models/entities/approval.form";

registerEnumType(ActiveStatus, {name: 'ActiveStatus'})

@ObjectType()
@Entity("office-approval-form-groups")
// @Unique(["code"])
export class ApprovalFormGroup extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({ nullable: false })
    name: string

    @Field(_type => ActiveStatus)
    @Column({ nullable: false, default: ObjectStatus.Active })
    status: ActiveStatus

    @Field(_type => Float)
    @CreateDateColumn()
    createdAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    /*relation*/
    // @Field(_type => [OfficeOrgChart], {nullable: true})
    // @ManyToOne(() => OfficeOrgChart)
    // orgCharts: OfficeOrgChart[]

    // @Field(_type => [OfficeOrgChart], {nullable: true})
    @ManyToMany(() => OfficeOrgChart)
    @JoinTable({
        name: BRIDGE_TABLE_DB.APPROVAL_FORM_GROUP_ORG_CHART,
    })
    orgCharts: OfficeOrgChart[]

    // @Field(_type => [ApprovalForm], {nullable: true})
    @ManyToMany(() => ApprovalForm, (ob) => ob.groups)
    @JoinTable({
        name: BRIDGE_TABLE_DB.APPROVAL_FORM_IN_GROUP,
    })
    forms: ApprovalForm[]
}