import { Field, Float, ObjectType } from "@nestjs/graphql"
import { AfterInsert, BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, Generated, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"

@ObjectType()
@Entity("office-user-bank-accounts")
export class UserBankAccount extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(() => String, { nullable: true })
    @Column({ nullable: true })
    bankId: string

    @Field(() => String, { nullable: true })
    @Column({ nullable: true })
    bankName: string

    @Field(() => String, { nullable: true })
    @Column({ nullable: true })
    accountNumber: string

    @Field(() => String, { nullable: true })
    @Column({ nullable: true })
    accountHolder: string

    @Field(() => String, { nullable: true })
    @Column({ nullable: true })
    cardNumber: string

    @Field(() => String, { nullable: true })
    @Column({ nullable: true })
    bankBranch: string

    @Column({ nullable: false })
    userId: string

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
}