import { Field, Int, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import { __Type } from "graphql";
import { BaseEntity, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm";

export enum CallParticipantRole {
    HOST = 'HOST',
    GUEST = 'GUEST'
}

export enum CallParticipantStatus {
    REQUEST = 'REQUEST',
    MISSED = 'MISSED',
    // CONNECT = 'CONNECT',
    // DISCONNECT = 'DISCONNECT',
    OFFLINE = 'OFFLINE',
    JOIN = 'JOIN',
    LEFT = 'LEFT'
}

registerEnumType(CallParticipantRole, { name: 'CallParticipantRole' })
registerEnumType(CallParticipantStatus, { name: 'CallParticipantStatus' })

@ObjectType()
@Entity("office-call-participants")
export class CallParticipant extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({ nullable: false })
    callId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    callToken: string

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    tokenExpireAt: Date

    // @Field(_type => String, { nullable: false })
    // @Column({ nullable: false })
    // userId: string

    @Field(_type => Int, { nullable: false })
    @Column({ nullable: false })
    userId: number

    // @Field(_type => Int, { nullable: false })
    // @Column({ nullable: false })
    // businessRoleId: number

    @Field(_type => CallParticipantRole)
    @Column({ nullable: false, type: 'enum', enum: CallParticipantRole })
    role: CallParticipantRole

    @Field(_type => CallParticipantStatus)
    @Column({ nullable: false, type: 'enum', enum: CallParticipantStatus, default: CallParticipantStatus.REQUEST })
    status: CallParticipantStatus

    @Field(_type => Float)
    @CreateDateColumn()
    createdAt: Date

    // @Field({ nullable: false })
    // @Column({ nullable: false })
    // createdBy: number

    @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    // @Field({ nullable: false })
    // @Column({ nullable: false })
    // updatedBy: number

    @DeleteDateColumn()
    deletedAt: Date
}