import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import { BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, ILike, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"

export enum RequestStatus {
    UnderReview = 'UnderReview',
    Approved = 'Approved',
    Rejected = 'Rejected',
    Recalled = 'Recalled'
}

registerEnumType(RequestStatus, { name: 'RequestStatus' })

const NO_START_VALUE: number = 100000

@ObjectType()
@Entity("office-car-booking-requests")
export class CarBookingRequest extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => Float)
    @Column({ nullable: false })
    // @Generated('increment')
    no: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    code: string

    @Field(_type => Float, { nullable: false })
    @Column({ nullable: false })
    startAt: Date

    @Field(_type => Float, { nullable: false })
    @Column({ nullable: false })
    endAt: Date

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    carId: string

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    fromAddress: string

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    toAddress: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    @Field(_type => RequestStatus)
    @Column({ nullable: false, type: 'enum', enum: RequestStatus, default: RequestStatus.UnderReview })
    status: RequestStatus

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    approvalId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    cancelDescription: string

    //repeat

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
        const date = new Date().toLocaleDateString('en-US', {timeZone: 'Asia/Jakarta'})
        const dateArr = date.split("/")
        const prefix = 'PDX_' + (dateArr[1].length === 2 ? dateArr[1] : ("0" + dateArr[1])) + (dateArr[0].length === 2 ? dateArr[0] : ("0" + dateArr[0])) + dateArr[2].substring(2)
        const lastestNo = await CarBookingRequest.findOne({
            where: {
                code: ILike(`${prefix}%`)
            },
            order: {
                no: "DESC"
            }
        })
        this.no = lastestNo ? lastestNo.no + 1 : 1
        
        this.code = prefix + `_${NO_START_VALUE + this.no}`.substring(1)
    }
}