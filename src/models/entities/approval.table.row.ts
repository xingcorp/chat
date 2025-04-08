import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import { BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"

export enum TableRowStatus {
    Pending = 'Pending',
    Approved = 'Approved',
    Rejected = 'Rejected'
}

registerEnumType(TableRowStatus, { name: 'TableRowStatus' })

@ObjectType()
@Entity("office-approval-table-rows")
export class ApprovalTableRow extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Column({ nullable: false })
    fieldId: string

    @Column({ nullable: false })
    approvalId: string

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

    @Field(_type => TableRowStatus)
    @Column({ nullable: false, type: 'enum', enum: TableRowStatus, default: TableRowStatus.Pending })
    status: TableRowStatus

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    actionAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    actionBy: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    actionStepId: string

    // @BeforeInsert()
    // async beforeInsert() {
    //     const lastestRecord = await ApprovalFormField.findOne({
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