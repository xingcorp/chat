import { OfficeUser } from "@models/entities"
import { CallParticipant, CallParticipantRole } from "@models/entities/rtc/call.participant"
import { CallRecord } from "@models/entities/rtc/call.record"
import { Field, Float, Int, ObjectType, Parent, ResolveField, Resolver } from "@nestjs/graphql"
import { In } from "typeorm"

@ObjectType()
export class CallLogResponse {
    @Field(_type => Float, { nullable: true })
    time: number

    @Field(_type => String, { nullable: true })
    action: string

    @Field(_type => String, { nullable: true })
    callStatus: string

    // @Field(_type => Int, { nullable: true })
    // userInRoom: number
}

@Resolver((_of: any) => CallRecord)
export class CallRecordFieldResolver {
    constructor(
    ) { }

    @ResolveField('caller', _return => OfficeUser, { nullable: false })
    async caller(@Parent() root: CallRecord) {
        return await OfficeUser.findOne({ where: { rtcUserId: root.createdBy } })
    }

    @ResolveField('receivers', _return => [OfficeUser], { nullable: false })
    async receivers(@Parent() root: CallRecord) {
        if (root.receivers && root.receivers.length > 0) return root.receivers
        const guests = await CallParticipant.find({
            where: {
                callId: root.id,
                role: CallParticipantRole.GUEST
            }
        })
        
        return await OfficeUser.find({
            where: {
                rtcUserId: In(guests.map(g => g.userId))
            }
        })
    }

    @ResolveField('logs', _return => [CallLogResponse], { nullable: false })
    async logs(@Parent() root: CallRecord) {
        const rs = []
        for (const iterator of root.metadata) {
            rs.push(JSON.parse(iterator))
        }
        return rs
    }

    @ResolveField('recordingFileUrls', _return => [String], { nullable: true })
    async recordingFileUrls(@Parent() root: CallRecord) {
        if (root.recordingFilePaths) {
            return root.recordingFilePaths.map(filePath => `${process.env.AWS_S3_OBJECT_URL}/${filePath}`)
        }
        return null
    }
}