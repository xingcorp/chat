import { CallType } from "@models/entities/rtc/call.record"
import { Field, InputType } from "@nestjs/graphql"
import { IsNotEmpty, IsUUID } from "class-validator"

@InputType()
export class CallReceiverArgs {
    @Field({ nullable: false })
    userId: string

    // @Field({ nullable: false })
    // businessRoleId: number
}

@InputType()
export class InitCallArgs {
    @Field(_type => CallType, { nullable: false, defaultValue: CallType.AUDIO })
    type: CallType

    @Field(_type => [CallReceiverArgs], { nullable: false })
    receivers: CallReceiverArgs[]

    @Field(_type => Boolean, { nullable: false, defaultValue: true })
    recording: boolean
}

@InputType()
export class CallHistoryFilter {
    @Field({ nullable: true, defaultValue: 0})
    page?: number

    @Field({ nullable: true, defaultValue: 20})
    size?: number

    @Field({ nullable: true })
    fromDate?: number

    @Field({ nullable: true })
    toDate?: number

    @Field({ nullable: true })
    type?: string
}