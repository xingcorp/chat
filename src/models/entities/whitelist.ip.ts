import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import { BaseEntity, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"

export enum IPVersion {
    IPv4 = 'IPv4',
    IPv6 = 'IPv6'
}

registerEnumType(IPVersion, { name: 'IPVersion' })

@ObjectType()
@Entity("office-whitelist-ips")
export class WhitelistIP extends BaseEntity {
    @Field(_type => String, { nullable: true })
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Column({ nullable: false })
    @Field(() => String, { nullable: false })
    publicIp: string

    @Field(_type => IPVersion)
    @Column({ nullable: false, type: 'enum', enum: IPVersion, default: IPVersion.IPv4 })
    type: IPVersion

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

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