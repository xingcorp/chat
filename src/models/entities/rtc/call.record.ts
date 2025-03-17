import { Field, Int, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import { __Type } from "graphql";
import { BaseEntity, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, Unique, UpdateDateColumn } from "typeorm";
import { OfficeUser } from "../profile.user";

export enum CallType {
    AUDIO = 'AUDIO',
    VIDEO = 'VIDEO'
}

export enum CallStatus {
    CONNECTING = 'CONNECTING', //Pending
    CALLING = 'CALLING', //Pending
    // RINGING = 'RINGING', //Pending
    PICKED_UP = 'PICKED_UP', //Pending
    // MISSED_CALL = 'MISSED_CALL', //Done
    CANCELED = 'CANCELED', //Done
    ENDED = 'ENDED', //Done
    REFUSE = 'REFUSE' //Done
}

export const PendingCallStatus: String[] = [
    CallStatus.CONNECTING,
    CallStatus.CALLING,
    // CallStatus.RINGING,
    CallStatus.PICKED_UP
]

export const SuccessCallStatus: String[] = [
    // CallStatus.MISSED_CALL,
    CallStatus.CANCELED,
    CallStatus.ENDED,
    CallStatus.REFUSE
]

export enum RecordingStatus {
    UNKNOWN = 'UNKNOWN',
    FAIL = 'FAIL',
    RECORDING = 'RECORDING',
    SUCCESS = 'SUCCESS'
}

registerEnumType(RecordingStatus, { name: 'RecordingStatus' })
registerEnumType(CallStatus, { name: 'CallStatus' })
registerEnumType(CallType, { name: 'CallType' })

@ObjectType()
@Entity("office-call-records")
export class CallRecord extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    name: string

    @Field(_type => CallType)
    @Column({ nullable: false, type: 'enum', enum: CallType, default: CallType.AUDIO })
    type: CallType

    @Field({ nullable: false, defaultValue: false })
    @Column({ nullable: false, default: false })
    isGroupCall: boolean

    @Field(_type => String)
    @Column({ nullable: false, default: CallStatus.CONNECTING })
    status: string

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    startAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    endAt: Date

    @Column('text', { array: true, nullable: false })
    metadata: string[]

    @Field(_type => [String], { nullable: true })
    @Column('text', { array: true, nullable: true })
    invalidUserIds: string[]

    // @Field(_type => String)
    // @Column({ nullable: false })
    // code: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    // @Field(_type => String, { nullable: false, defaultValue: OriginCode.KRF })
    // @Column({ nullable: false, default: OriginCode.KRF })
    // origin: string

    @Field(_type => Float)
    @CreateDateColumn()
    createdAt: Date

    @Field(_type => Int, { nullable: false })
    @Column({ nullable: false })
    createdBy: number

    // @Field(_type => Int, { nullable: false })
    // @Column({ nullable: false })
    // businessRoleId: number

    @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    @Field(_type => Int, { nullable: false })
    @Column({ nullable: false })
    updatedBy: number

    @DeleteDateColumn()
    deletedAt: Date

    @Field(_type => String)
    historyType: string

    @Field({ nullable: false, defaultValue: false })
    @Column({ nullable: false, default: false })
    recording: boolean

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    recordingFilePaths: string[]

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    recordingResourceId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    recordingSid: string

    @Field(_type => RecordingStatus)
    @Column({ nullable: false, type: 'enum', enum: RecordingStatus, default: RecordingStatus.UNKNOWN })
    recordingStatus: RecordingStatus

    @Field(_type => String, { nullable: true })
    requestId: string

    @Field(_type => [OfficeUser], { nullable: true })
    receivers: OfficeUser[]
}