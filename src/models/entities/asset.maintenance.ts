import { Field, ObjectType } from "@nestjs/graphql";
import { BaseEntity, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm";

@ObjectType()
@Entity("office-asset-maintenances")
export class AssetMaintenance extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Column({ nullable: false })
    assetId: string

    @Column({ nullable: true })
    content: string

    @Column({ nullable: true })
    handOverAt: Date

    @Column({ nullable: true })
    handOverReceipt: string

    @Column({ nullable: true })
    reason: string

    @Column({ nullable: true })
    handOverUserId: string

    @Column({ nullable: true })
    handOverStatus: string

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