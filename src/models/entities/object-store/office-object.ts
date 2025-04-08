import { Field, Float, Int, ObjectType } from "@nestjs/graphql"
import { BaseEntity, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"
import { OfficeObjectType } from "@enum/object-store/object-store.enum";

@Entity('office-objects')
@ObjectType()
export class OfficeObject extends BaseEntity {
    @Field(_type => String, { nullable: true })
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Column({ nullable: true })
    relationType: OfficeObjectType

    @Column({ nullable: true })
    relationId: string

    @Field(_type => String)
    @Column({ nullable: false })
    name: string

    @Field({ nullable: true })
    @Column()
    mimetype: string

    @Field({ nullable: true })
    @Column({default: '7bit'})
    encoding: string

    @Field(() => Float, { nullable: true })
    @Column({ type: 'bigint', nullable: true })
    size: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    location: string

    @Column({ nullable: true })
    etag: string

    @Column({ nullable: true })
    key: string

    @Column({ nullable: true })
    bucket: string

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