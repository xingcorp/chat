import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql";
import { BaseEntity, Column, CreateDateColumn, DeleteDateColumn, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm";
import { OfficeUser } from "./profile.user";
import { OrganizationDeviceStatus } from "@enum/device/device.enum";




@ObjectType()
@Entity("office-organization-devices")

export class OrganizationDevice extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    userId: string

    @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, { nullable: true })
    @JoinColumn()
    user: OfficeUser

    @Field(_type => Int,{ nullable: true })
    @Column({ nullable: true })
    businessRoleId: number

    @Field(_type => String)
    @Column({nullable:true})
    name : string 

    @Field(_type => String)
    @Column('text', { nullable: true })
    model: string

    @Field(_type => String)
    @Column('text', { nullable: false })
    identifierForVendor: string

    @Field(_type => OrganizationDeviceStatus)
    @Column({type: 'enum',enum: OrganizationDeviceStatus,default: OrganizationDeviceStatus.REQUEST})
    status: OrganizationDeviceStatus;

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    adminUpdatedAt: Date

    @Field(() => String, { nullable: true })
    @Column('text', { nullable: true })
    versionOS: string

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    approvedAt: Date

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