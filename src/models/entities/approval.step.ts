import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql"
import { BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"
import { ApprovalAction, ActionUnit } from "./approval.form"
import { GrantType } from "@utils/enum.utils";

export enum ApprovalStepStatus {
    Waiting = 'Waiting',
    Requested = 'Requested',
    Consented = 'Consented',
    Rejected = 'Rejected',
    Approved = 'Approved'
}

export enum ApprovalProcessAction {
    Submit = 'Submit',
    Comment = 'Comment',
    Cancel = 'Cancel',
    Approve = 'Approve',
    Consent = 'Consent',
    Reject = 'Reject',
    Grant = 'Grant',
    Pending = 'Pending'
}

registerEnumType(ApprovalProcessAction, { name: 'ApprovalProcessAction' })
registerEnumType(ApprovalStepStatus, { name: 'ApprovalStepStatus' })
registerEnumType(GrantType, { name: 'GrantType' })

@ObjectType()
@Entity("office-approval-steps")
export class ApprovalStep extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    // @Field(_type => String)
    // @Column({ nullable: true })
    // formStepId: string

    // @Field(_type => String, { nullable: true })
    // @Column({ nullable: true })
    // approverId: string

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    approveBy: string[]

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    grantFrom: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    grantTo: string

    @Field(_type => GrantType, { nullable: true })
    @Column({ nullable: true })
    grantToType: GrantType

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    approvalRowIds: string[]

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    departmentId: string

    @Field(_type => Int, { nullable: true })
    @Column({ nullable: true })
    approverLevel: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    comment: string

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    consentBy: string[]

    @Field(_type => ActionUnit, { nullable: true })
    @Column({ nullable: true, type: 'enum', enum: ActionUnit })
    unit: ActionUnit

    @Field(_type => ApprovalAction, { nullable: true })
    @Column({ nullable: true, type: 'enum', enum: ApprovalAction })
    approvalAction: ApprovalAction

    // @Column({ nullable: false })
    // formId: string

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    order: number

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

    @Column({ nullable: false })
    approvalId: string

    @Field({ nullable: false, defaultValue: false })
    @Column({ nullable: false, default: false })
    currentStep: boolean

    @Field({ nullable: true })
    @Column({ nullable: true, default: false })
    canAction: boolean

    // @Field(_type => ApprovalStepStatus)
    // @Column({ nullable: false, type: 'enum', enum: ApprovalStepStatus, default: ApprovalStepStatus.Waiting })
    // status: ApprovalStepStatus

    @Field(_type => ApprovalProcessAction, { nullable: true })
    @Column({ nullable: true, type: 'enum', enum: ApprovalProcessAction })
    action: ApprovalProcessAction

    @Field({ nullable: true })
    @Column({ nullable: true })
    actionBy: string

    // @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    actionAt: Date

    @Column('text', { nullable: true, array: true })
    attachmentIds: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    attachmentUrls: string[]

    @Column('text', { nullable: true, array: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    imageUrls: string[]
}