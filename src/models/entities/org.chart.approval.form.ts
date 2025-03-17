import { Field, Float, ObjectType } from "@nestjs/graphql"
import { AfterInsert, BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, Generated, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"

@ObjectType()
@Entity("office-org-chart-approval-forms")
export class OrgChartApprovalForm extends BaseEntity {
    // @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    // @Field(() => String, { nullable: false })
    @Column({ nullable: false })
    departmentId: string

    // @Field(() => String, { nullable: false })
    @Column({ nullable: false })
    formId: string

    // @Field(_type => Float)
    @CreateDateColumn()
    createdAt: Date

    // @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    // @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    // @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date
}