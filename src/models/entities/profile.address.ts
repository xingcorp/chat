import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import { AfterInsert, BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, Generated, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"

export enum AddressType {
    Temporary = 'Temporary',
    Permanent = 'Permanent',
}

registerEnumType(AddressType, { name: 'AddressType' })
@ObjectType()
@Entity("office-user-addresses")
export class UserAddress extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(() => Float, { nullable: true })
    @Column('float', { nullable: true })
    latitude: number

    @Field(() => Float, { nullable: true })
    @Column('float', { nullable: true })
    longitude: number

    @Column({ nullable: true })
    @Field(() => String, { nullable: true })
    addressZoneId: string

    @Field(() => String, { nullable: true })
    @Column({ nullable: true })
    provinceId: string

    @Field(() => String, { nullable: true })
    @Column({ nullable: true })
    districtId: string

    @Field(() => String, { nullable: true })
    @Column({ nullable: true })
    wardId: string

    @Field(() => String, { nullable: true, defaultValue: null })
    @Column({ nullable: true })
    province: string

    @Field(() => String, { nullable: true, defaultValue: null })
    @Column({ nullable: true })
    district: string

    @Field(() => String, { nullable: true, defaultValue: null })
    @Column({ nullable: true })
    ward: string

    @Field(() => String, { nullable: true })
    @Column({ nullable: true })
    address: string
    
    @Field(() => AddressType, { nullable: true })
    @Column({ nullable: true, default: AddressType.Permanent })
    addressType: AddressType

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