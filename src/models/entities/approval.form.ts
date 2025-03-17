import { Field, Int, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import { __Type } from "graphql";
import {
    AfterInsert,
    BaseEntity,
    BeforeInsert,
    BeforeUpdate,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity,
    Generated, JoinTable,
    ManyToMany,
    PrimaryGeneratedColumn,
    Unique,
    UpdateDateColumn
} from "typeorm";
import { ObjectStatus } from "./profile.info.block";
import { OfficeUser } from "@models/entities/profile.user";
import { BRIDGE_TABLE_DB } from "@common/db/bridge-table.db";
import { ApprovalFormGroup } from "@models/entities/approval.form.group";

export enum ObjectScope {
    Common = 'Common',
    Specified = 'Specified'
}

export enum ActionUnit {
    Person = 'Person',
    Department = 'Department',
    Level = 'Level',
    Leader = 'Leader'
}

export enum ApprovalAction {
    Consent = 'Consent',
    Approve = 'Approve'
}

export enum ApprovalType {
    Other = 'Other',
    CarBooking = 'CarBooking',
    RoomBooking = 'RoomBooking',
    OfficeShopping = 'OfficeShopping',
    WikiRelease = 'WikiRelease',
}

registerEnumType(ObjectScope, { name: 'ObjectScope' })
registerEnumType(ActionUnit, { name: 'ActionUnit' })
registerEnumType(ApprovalAction, { name: 'ApprovalAction' })
registerEnumType(ApprovalType, { name: 'ApprovalType' })

@ObjectType()
@Entity("office-approval-forms")
// @Unique(["code"])
export class ApprovalForm extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({ nullable: false })
    name: string

    @Field(_type => ObjectStatus)
    @Column({ nullable: false, type: 'enum', enum: ObjectStatus, default: ObjectStatus.Active })
    status: ObjectStatus

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    @Field(_type => ObjectScope)
    @Column({ nullable: false, type: 'enum', enum: ObjectScope, default: ObjectScope.Common })
    scope: ObjectScope

    @Field(_type => ApprovalType)
    @Column({ nullable: false, type: 'enum', enum: ApprovalType, default: ApprovalType.Other })
    type: ApprovalType

    @Column({ nullable: true })
    typeId: string

    @Field(_type => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    subscriberIds: string[]

    @Column('text', { nullable: true, array: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    imageUrls: string[]

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
    @Field(_type => [OfficeUser], {nullable: true})
    @ManyToMany(() => OfficeUser, (ob) => ob.approvalForms, {
        eager: true
    })
    @JoinTable({
        name: BRIDGE_TABLE_DB.APPROVAL_FORM_USER,
    })
    users: OfficeUser[]

    // @Field(_type => [ApprovalFormGroup], {nullable: true})
    @ManyToMany(() => ApprovalFormGroup, (ob) => ob.forms)
    groups: ApprovalFormGroup[]
}