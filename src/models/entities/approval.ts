import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import {
    BaseEntity,
    BeforeInsert,
    BeforeUpdate,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity,
    ILike, JoinTable,
    ManyToMany, OneToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm"
import { ApprovalType } from "./approval.form"
import { CarBookingRequest, RequestStatus } from "./car.booking.request"
import { BookingMeetingRoom } from "./booking/booking.meeting.room"
import { OfficeShoppingRequest } from "./office.shopping.request"
import { OfficeUser } from "@models/entities/profile.user";
import { BRIDGE_TABLE_DB } from "@common/db/bridge-table.db";
import { ApprovalSubmitTypeEnum } from "@enum/approval/approval/approval.enum";
import { ApprovalForward } from "@models/entities/approval/forward/approval.forward";

export enum ApprovalStatus {
    UnderReview = 'UnderReview',
    Pending = 'Pending',
    Approved = 'Approved',
    Rejected = 'Rejected',
    Recalled = 'Recalled',
    Draft = 'Draft',
    Forward = 'Forward',
}

export enum ApprovalSource {
    Blank = 'Blank',
    Template = 'Template'
}

export enum ApprovalOwnerStatus {
    Waiting = 'Waiting',
    Approved = 'Approved',
    Notify = 'Notify',
    Submitted = 'Submitted',
    Draft = 'Draft',
    NextAction = 'NextAction',
    Forward = 'Forward',
}

registerEnumType(ApprovalSource, { name: 'ApprovalSource' })
registerEnumType(ApprovalStatus, { name: 'ApprovalStatus' })
registerEnumType(ApprovalOwnerStatus, { name: 'ApprovalOwnerStatus' })

const NO_START_VALUE: number = 100000

@ObjectType()
@Entity("office-approvals")
export class OfficeApproval extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({ nullable: false })
    name: string

    @Field(_type => Float)
    @Column({ nullable: true })
    // @Generated('increment')
    no: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    code: string

    @Field(_type => ApprovalStatus)
    @Column({ nullable: false, type: 'enum', enum: ApprovalStatus, default: ApprovalStatus.UnderReview })
    status: ApprovalStatus

    @Column('text', { nullable: true, array: true })
    attachmentIds: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    attachmentUrls: string[]

    @Column('text', { nullable: true, array: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    imageUrls: string[]

    @Field(_type => ApprovalSource)
    @Column({ nullable: false, type: 'enum', enum: ApprovalSource })
    source: ApprovalSource

    @Field(_type => ApprovalType, { nullable: true })
    @Column({ nullable: false, type: 'enum', enum: ApprovalType, default: ApprovalType.Other })
    type: ApprovalType

    @Column({ nullable: true })
    relationId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    formId: string

    @Column({ nullable: true })
    requestId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    @Field(_type => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    subscriberIds: string[]

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    followerIds: string[]

    @Field({ nullable: true })
    @Column({ nullable: true, default: true })
    isPublic: boolean

    // @Field(_type => Float, { nullable: false })
    // @Column({ nullable: false, default: 1 })
    // currentStep: number

    // @Column('text', { array: true, nullable: true })
    // fields: string[]

    // @Column('text', { array: true, nullable: true })
    // steps: string[]

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

    @Field(_type => [OfficeUser], {nullable: true})
    @ManyToMany(() => OfficeUser, (ob) => ob.approvalsRead)
    @JoinTable({
        name: BRIDGE_TABLE_DB.USER_READ_APPROVAL,
    })
    readBy: OfficeUser[]

    @OneToOne(() => ApprovalForward, (ob) => ob.approval, {
        nullable: true,
    })
    forward: ApprovalForward

    /*Listener*/
    @BeforeInsert()
    async beforeInsert() {
        const date = new Date().toLocaleDateString('en-US', {timeZone: 'Asia/Jakarta'})
        const dateArr = date.split("/")
        const prefix = dateArr[2] + (dateArr[0].length === 2 ? dateArr[0] : ("0" + dateArr[0])) + (dateArr[1].length === 2 ? dateArr[1] : ("0" + dateArr[1]))
        const lastestNo = await OfficeApproval.findOne({
            where: {
                code: ILike(`${prefix}%`)
            },
            order: {
                no: "DESC"
            }
        })
        this.no = lastestNo ? lastestNo.no + 1 : 1
        
        this.code = prefix + `${NO_START_VALUE + this.no}`.substr(1)
    }

    @BeforeUpdate()
    async beforeUpdate() {
        //update request status
        if (this.requestId) {
            switch (this.type) {
                case ApprovalType.CarBooking:
                    const carRequest = await CarBookingRequest.findOne({ where: { id: this.requestId } })
                    if (carRequest) {
                        if (this.status === ApprovalStatus.Approved) {
                            carRequest.status = RequestStatus.Approved
                        } else if (this.status === ApprovalStatus.Rejected) {
                            carRequest.status = RequestStatus.Rejected
                        } else if (this.status === ApprovalStatus.Recalled) {
                            carRequest.status = RequestStatus.Recalled
                        }
                        await carRequest.save()
                    }
                    break
                case ApprovalType.RoomBooking:
                    const roomRequest = await BookingMeetingRoom.findOne({ where: { id: this.requestId } })
                    if (roomRequest) {
                        if (this.status === ApprovalStatus.Approved) {
                            roomRequest.status = RequestStatus.Approved
                        } else if (this.status === ApprovalStatus.Rejected) {
                            roomRequest.status = RequestStatus.Rejected
                        } else if (this.status === ApprovalStatus.Recalled) {
                            roomRequest.status = RequestStatus.Recalled
                        }
                        await roomRequest.save()
                    }
                    break
                case ApprovalType.OfficeShopping:
                    const shoppingRequest = await OfficeShoppingRequest.findOne({ where: { id: this.requestId } })
                    if (shoppingRequest) {
                        if (this.status === ApprovalStatus.Approved) {
                            shoppingRequest.status = RequestStatus.Approved
                        } else if (this.status === ApprovalStatus.Rejected) {
                            shoppingRequest.status = RequestStatus.Rejected
                        } else if (this.status === ApprovalStatus.Recalled) {
                            shoppingRequest.status = RequestStatus.Recalled
                        }
                        await shoppingRequest.save()
                    }
                    break
            }
        }
    }
}