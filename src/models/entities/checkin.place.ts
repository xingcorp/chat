import { Field, Float, ObjectType } from "@nestjs/graphql";
import { __Type } from "graphql";
import { BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm";
import { ObjectStatus } from "./profile.info.block";

const NO_START_VALUE: number = 100000

@ObjectType()
@Entity("office-check-in-places")
// @Unique(["code"])
export class CheckInPlace extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({ nullable: false })
    name: string

    @Field(_type => Float)
    @Column({ nullable: false })
    // @Generated('increment')
    no: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    code: string

    @Field(_type => ObjectStatus)
    @Column({ nullable: false, type: 'enum', enum: ObjectStatus, default: ObjectStatus.Active })
    status: ObjectStatus

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

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

    @Column('simple-array', { nullable: true })
    secrets: string[]

    @Field({ nullable: false, defaultValue: false })
    @Column({ nullable: false, default: false })
    ipValidation: boolean

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

    @BeforeInsert()
    async beforeInsert() {
        const lastestNo = await CheckInPlace.findOne({
            where: {},
            order: {
                no: "DESC"
            }
        })
        this.no = lastestNo ? lastestNo.no + 1 : 1
        // this.code = `block_${this.name.trim().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^A-Z0-9]+/ig, "_").toLowerCase()}_${this.no}`
        this.code = 'C' + `${NO_START_VALUE + this.no}`.substr(1)
    }
}