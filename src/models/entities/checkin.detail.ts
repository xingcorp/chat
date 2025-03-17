import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql";
import { BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm";
import { CheckInTypeEnum } from "@enum/check-in/check-in-enum";
import { ObjectStatus } from "@models/entities/profile.info.block";

registerEnumType(CheckInTypeEnum, {name: 'CheckInTypeEnum'})

@ObjectType()
@Entity("office-check-in-details")
export class CheckInDetail extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    checkInId: string

    // @Field(_type => String)
    // @Column({ nullable: false })
    // checkInCode: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    placeId: string

    @Field(_type => CheckInTypeEnum, { nullable: true })
    @Column({ nullable: true, type: 'enum', enum: CheckInTypeEnum, default: CheckInTypeEnum.Place })
    checkInType: CheckInTypeEnum

    @Column('text', { nullable: true, array: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    imageUrls: string[]

    // @Column('text', { array: true, nullable: true })
    // images: string[]

    // @Column('text', { array: true, nullable: true })
    // exhibitionImages: string[]

    // @Column('text', { array: true, nullable: true })
    // overviewImages: string[]

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    description: string

    @Field(() => Float, { nullable: true })
    @Column('float', { nullable: true })
    latitude: number

    @Field(() => Float, { nullable: true })
    @Column('float', { nullable: true })
    longitude: number

    @Field({ nullable: false })
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

    @BeforeInsert()
    async beforeInsert() {
        const lastestRecord = await CheckInDetail.findOne({
            where: {
                checkInId: this.checkInId
            },
            order: {
                order: "DESC"
            }
        })
        this.order = lastestRecord ? lastestRecord.order + 1 : 1
    }
}