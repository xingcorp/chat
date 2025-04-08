import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql";
import { BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm";

export enum CheckInStatus {
    Request = 'Request',
    Rejected = 'Rejected',
    Approved = 'Approved'
}

registerEnumType(CheckInStatus, { name: 'CheckInStatus' })

@ObjectType()
@Entity("office-check-ins")
export class CheckIn extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({ nullable: false })
    code: string

    // @Field(_type => Int)
    // @Column({ nullable: false, default: 1 })
    // checkinTime: number

    // @Column('text', { nullable: true, array: true, default: null })
    // checkInDetailIds: string[]

    @Field(_type => CheckInStatus)
    @Column({ nullable: false, type: 'enum', enum: CheckInStatus, default: CheckInStatus.Request })
    status: CheckInStatus

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    reasonStatus: string

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

    // @BeforeInsert()
    // async beforeInsert() {
    //     const date = new Date().toLocaleDateString('en-US', {timeZone: 'Asia/Jakarta'})
    //     const dateArr = date.split("/")
    //     this.code = dateArr[2] + (dateArr[0].length === 2 ? dateArr[0] : ("0" + dateArr[0])) + (dateArr[1].length === 2 ? dateArr[1] : ("0" + dateArr[1]))
    // }
}