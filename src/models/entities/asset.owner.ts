import { Field, ObjectType } from "@nestjs/graphql";
import { BaseEntity, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm";

@ObjectType()
@Entity("office-asset-owners")
export class AssetOwner extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Column({ nullable: false })
    assetId: string

    @Column({ nullable: true })
    ownerId: string

    @Column({ nullable: true })
    supplyAt: Date

    @Column({ nullable: true })
    reason: string

    @CreateDateColumn()
    createdAt: Date

    @Column({ nullable: true })
    createdBy: string

    @UpdateDateColumn()
    updatedAt: Date

    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date
}