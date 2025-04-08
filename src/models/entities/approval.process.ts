import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import { BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"
import { ApprovalAction, ActionUnit } from "./approval.form"

export enum ApprovalStepStatus {
    Waiting = 'Waiting',
    Requested = 'Requested',
    Consented = 'Consented',
    Rejected = 'Rejected',
    Approved = 'Approved'
}

registerEnumType(ApprovalStepStatus, { name: 'ApprovalStepStatus' })

@ObjectType()
@Entity("office-approval-processes")
export class ApprovalProcess extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    // @Field(_type => String)
    // @Column({ nullable: true })
    // formStepId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    actorId: string

    // @Field(_type => String, { nullable: true })
    // @Column({ nullable: true })
    // departmentId: string

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    consentBy: string[]

    // @Field(_type => ActionUnit)
    // @Column({ nullable: false, type: 'enum', enum: ActionUnit, default: ActionUnit.Person })
    // unit: ActionUnit

    @Field(_type => ApprovalAction)
    @Column({ nullable: false, type: 'enum', enum: ApprovalAction })
    action: ApprovalAction

    @Column({ nullable: false })
    formId: string

    @Field(_type => Float, { nullable: false })
    @Column({ nullable: false })
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

    @Field(_type => ApprovalStepStatus)
    @Column({ nullable: false, type: 'enum', enum: ApprovalStepStatus, default: ApprovalStepStatus.Waiting })
    status: ApprovalStepStatus

    @Field({ nullable: true })
    @Column({ nullable: true })
    actionBy: string
}