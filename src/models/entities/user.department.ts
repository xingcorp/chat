import { ObjectType } from "@nestjs/graphql"
import { BaseEntity, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"

@ObjectType()
@Entity("office-user-departments")
export class UserDepartment extends BaseEntity {
    // @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    // @Field(() => String, { nullable: false })
    @Column({ nullable: false })
    departmentId: string

    // @Field(() => String, { nullable: true })
    @Column({ nullable: true })
    titleId: string

    // @Field(() => String, { nullable: false })
    @Column({ nullable: false })
    userId: string

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