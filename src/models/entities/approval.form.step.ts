import { Field, Float, Int, ObjectType } from "@nestjs/graphql"
import { BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"
import { ApprovalAction, ActionUnit } from "./approval.form"


@ObjectType()
@Entity("office-approval-form-steps")
export class ApprovalFormStep extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    // @Field(_type => String, { nullable: true })
    // @Column({ nullable: true })
    // approverId: string

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    approveBy: string[]

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    departmentId: string

    @Field(_type => Int, { nullable: true })
    @Column({ nullable: true })
    approverLevel: number

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    consentBy: string[]

    @Field(_type => ActionUnit)
    @Column({ nullable: false, type: 'enum', enum: ActionUnit, default: ActionUnit.Person })
    unit: ActionUnit

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

    // @BeforeInsert()
    // async beforeInsert() {
    //     const lastestRecord = await ApprovalFormStep.findOne({
    //         where: {
    //             formId: this.formId
    //         },
    //         order: {
    //             order: "DESC"
    //         }
    //     })
    //     this.order = lastestRecord ? lastestRecord.order + 1 : 1
    // }
}