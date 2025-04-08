import { Field, Float, ObjectType } from "@nestjs/graphql"
import { BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"
import { DataType } from "./profile.info.field"


@ObjectType()
@Entity("office-approval-form-table-columns")
export class ApprovalFormTableColumn extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({ nullable: false })
    name: string

    @Field({ nullable: false, defaultValue: false })
    @Column({ nullable: false, default: false })
    required: boolean

    @Field(_type => DataType)
    @Column({ nullable: false, type: 'enum', enum: DataType, default: DataType.Text })
    dataType: DataType

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    hintText: string //TEXT

    @Field({ nullable: false, defaultValue: true })
    @Column({ nullable: false, default: true })
    timeInPast: boolean //DATE

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    optionItems: string[] //LIST

    @Field({ nullable: false, defaultValue: false })
    @Column({ nullable: false, default: false })
    multiSelect: boolean //LIST

    @Column({ nullable: false })
    fieldId: string

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