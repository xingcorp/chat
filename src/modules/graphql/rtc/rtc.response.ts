import { CallRecord } from "@models/entities/rtc/call.record"
import { Field, Float, Int, ObjectType } from "@nestjs/graphql"
import { PagingData } from "src/models/base/paging.response"

@ObjectType()
export class CallEventResponse {
    @Field(_type => Float, { nullable: true })
    time: number

    @Field(_type => CallRecord, { nullable: true })
    room: CallRecord

    @Field(_type => String, { nullable: true })
    event: string

    // @Field(_type => Int, { nullable: true })
    // userInRoom: number

    @Field(_type => String, { nullable: true })
    metadata: String
}

@ObjectType()
export class EventResponse {
    @Field(_type => Float, { nullable: true })
    time: number

    @Field(_type => String, { nullable: true })
    message: String
}

@ObjectType()
export class CallTokenResponse {
    @Field(_type => String, { nullable: true })
    appId: string

    @Field(_type => String, { nullable: true })
    callToken: string

    @Field(_type => Float, { nullable: true })
    tokenExpireAt: Date

    @Field(_type => Int, { nullable: true })
    uId: number

    @Field(_type => Float, { nullable: true })
    callTimeout: number

    @Field(_type => Float, { nullable: true })
    incallTimeout: number

    @Field(_type => Float, { nullable: true })
    ringingTimeout: number
}

@ObjectType()
export class RTMTokenResponse {
    @Field(_type => String, { nullable: true })
    appId: string

    @Field(_type => String, { nullable: true })
    rtmToken: string

    @Field(_type => Float, { nullable: true })
    tokenExpireAt: Date

    @Field(_type => Int, { nullable: true })
    uId: number
}

@ObjectType({ implements: PagingData })
export class CallHistoryResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [CallRecord], { nullable: true })
    callHistories?: CallRecord[]
}