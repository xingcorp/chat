import { Inject, SetMetadata, UseGuards, forwardRef } from "@nestjs/common";
import { Resolver, Query, Mutation, Args } from "@nestjs/graphql";
import { CallRecord, CallStatus, CallType, PendingCallStatus, RecordingStatus, SuccessCallStatus } from "@models/entities/rtc/call.record";
// import { BusinessRoleId, OrganizationId, Requester, RequesterId, UserId } from "src/modules/middleware/decorator/user.decorator";
import { v4 as uuidv4 } from 'uuid';
import { CallHistoryFilter, InitCallArgs } from "./rtc.args";
import { CallParticipant, CallParticipantRole, CallParticipantStatus } from "@models/entities/rtc/call.participant";
import { ApolloError } from "apollo-server-errors";
import { Between, In, Not } from "typeorm";
import { CallEventResponse, CallHistoryResponse, CallTokenResponse, EventResponse, RTMTokenResponse } from "./rtc.response";
import { RtmTokenBuilder, RtmRole, RtcTokenBuilder, RtcRole } from 'agora-access-token';
import { RTCService } from "./rtc.service";
import { OfficeRequester, OfficeRequesterId } from "@core/middleware/decorator/user.decorator";
import { ServiceActions, ServiceKeys } from "@core/middleware/guard/service.action";
import { OfficeUser } from "@models/entities";
import { OfficeError, OfficeErrorMessage } from "@common/office.error";
import { BaseError, HttpError } from "@core/core.error";
import { BearerAccessToken } from "@core/middleware/decorator/request.decorator";
import { IdentityService } from "@core/iam/identity/identity.service";
import { NotificationService } from "@core/iam/notification/notification.service";
import { RandomHelper } from "@common/random";
// import { KshopIdentityGuard } from "src/modules/middleware/guard/kshop.identity.guard";
// import { RTCUser } from "src/models/entities/user"
// import { AgoraService } from "src/modules/core/agora/agora.service";

enum SUBSCRIPTION_EVENTS {
    newInventory = 'newInventory',
    callEvent = 'callEventResponse',
    testSubcription = 'testSubcription'
}

export enum CallEvent {
    RINGING = 'RINGING', //Pending
    JOIN_ROOM = 'JOIN_ROOM', //Pending
    JOIN_CALL = 'JOIN_CALL', //Pending
    MISSED_CALL = 'MISSED_CALL', //Done
    ENDED = 'ENDED', //Done
    REJECTED = 'REJECTED' //Done
}

export enum CallHistoryType {
    MISSED = 'MISSED',
    INCOMMING = 'INCOMMING',
    OUTGOING = 'OUTGOING'
}

@Resolver()
export class RTCResolver {
    constructor(
        // private readonly k365Service: K365Service,
        // private readonly notificationService: NotificationService,
        private readonly rtcService: RTCService,

        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        
        @Inject(forwardRef(() => IdentityService))
        private readonly identityService: IdentityService,
    ) { }

    @Mutation(_type => CallRecord, { name: "officeInitCall" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async officeInitCall(
        @Args("arguments", { nullable: false }) args: InitCallArgs,
        @OfficeRequester() officeRequester: OfficeUser,
        @BearerAccessToken() token: string
    ) {
        const requestId = RandomHelper.generateUUID()
        console.log(`[Mutation]:[officeInitCall]:[${requestId}] authorization: ${token}`)

        const validUsers: OfficeUser[] = []
        const invalidUsers = []
        const officeUser = await this.rtcService.getRtcUser(officeRequester)
        for (const input of args.receivers) {
            if (officeUser.id === input.userId) {
                throw OfficeError.RTCErrorCannotMakeCallToYourself
            }
            const org = await OfficeUser.findOne({ where: { id: input.userId } })

            if (!org) {
                invalidUsers.push(JSON.stringify({
                    userId: input.userId
                }))
            } else {
                const receiver = await this.rtcService.getRtcUser(org)
                validUsers.push(receiver)
            }
        }
        
        if (validUsers.length === 0) {
            throw OfficeError.RTCErrorRecipientInforNotFound
        }

        // check người dùng (caller/receiver) có online || đang trong cuộc gọi khác k?
        const allCallUserInIds = []
        const userInCalls = await CallParticipant.find({
            where: [{
                userId: officeUser.rtcUserId,
                status: CallParticipantStatus.JOIN
            }, {
                userId: officeUser.rtcUserId,
                role: CallParticipantRole.HOST,
                status: CallParticipantStatus.REQUEST
            }]
        })

        for (const call of userInCalls) {
            if (await this.rtcService.updateCallById(call.callId)) {
                allCallUserInIds.push(call.callId)
            }
        }

        if (allCallUserInIds.length) {
            throw new BaseError('Office.RTCErrorYouAreOnAnotherCall', `${OfficeErrorMessage.RTCErrorYouAreOnAnotherCall}: ${allCallUserInIds[0]}`)
        }

        const newRecord = CallRecord.create({
            id: uuidv4(),
            type: args.type === CallType.VIDEO ? CallType.VIDEO : CallType.AUDIO,
            metadata: [JSON.stringify({
                time: Date.now(),
                action: `[HOST] UserID: ${officeUser.rtcUserId} => INIT CALL`,
                callStatus: CallStatus.CONNECTING
            })],
            isGroupCall: validUsers.length > 1 ? true : false,
            invalidUserIds: invalidUsers,
            createdBy: officeUser.rtcUserId,
            updatedBy: officeUser.rtcUserId,
            recording: args.recording
            // businessRoleId: businessRoleId
        })

        const tokenExpireAt = new Date(Date.now() + 3600000)
        const hostToken = RtcTokenBuilder.buildTokenWithUid(
            process.env.AGORA_APP_ID,
            process.env.AGORA_APP_CERTIFICATE,
            newRecord.id,
            officeUser.rtcUserId,
            RtcRole.PUBLISHER,
            tokenExpireAt.getTime() / 1000
        )

        const host = CallParticipant.create({
            callId: newRecord.id,
            role: CallParticipantRole.HOST,
            status: CallParticipantStatus.REQUEST,
            userId: officeUser.rtcUserId,
            callToken: hostToken,
            tokenExpireAt: tokenExpireAt
        })

        const guests = []
        for (const receiver of validUsers) {
            // const recipient = await this.rtcService.getRtcUser(receiver)
            const receiverToken = RtcTokenBuilder.buildTokenWithUid(
                process.env.AGORA_APP_ID,
                process.env.AGORA_APP_CERTIFICATE,
                newRecord.id,
                receiver.rtcUserId,
                RtcRole.PUBLISHER,
                tokenExpireAt.getTime() / 1000
            )
            guests.push(CallParticipant.create({
                callId: newRecord.id,
                role: CallParticipantRole.GUEST,
                status: CallParticipantStatus.REQUEST,
                userId: receiver.rtcUserId,
                callToken: receiverToken,
                tokenExpireAt: tokenExpireAt
            }))
        }

        console.log(`[Mutation]:[officeInitCall]:[${requestId}] validUsers: ${JSON.stringify(validUsers)}`)
        await newRecord.save()
        newRecord.receivers = validUsers
        newRecord.requestId = requestId
        console.log(`[Mutation]:[officeInitCall]:[${requestId}] callInfo: ${JSON.stringify(newRecord)}`)
        await host.save()
        await CallParticipant.save(guests)

        setTimeout(async () => {
            const checkRecord = await CallRecord.findOne({ where: { id: newRecord.id } })
            if (PendingCallStatus.includes(checkRecord.status)) {
                const now = new Date()
                checkRecord.status = checkRecord.status === CallStatus.PICKED_UP ? CallStatus.ENDED : CallStatus.CANCELED
                checkRecord.note = `ENDED by CALL_TIMEOUT: ${Number(process.env.CALL_TIMEOUT)}`
                if (checkRecord.startAt) {
                    checkRecord.endAt = now
                }

                checkRecord.metadata.push(JSON.stringify({
                    time: now.getTime(),
                    action: `[SYSTEM] => CALL ENDED by CALL_TIMEOUT: ${Number(process.env.CALL_TIMEOUT)}`,
                    callStatus: checkRecord.status
                }))
                await CallParticipant.update({callId: checkRecord.id}, {status: CallParticipantStatus.LEFT})
                await checkRecord.save()
                
                console.log(`[CALL - ${checkRecord.id}]|<SYSTEM_END>: [SYSTEM] => CALL ENDED by CALL_TIMEOUT: ${Number(process.env.CALL_TIMEOUT)}`)
            }
        }, Number(process.env.CALL_TIMEOUT))

        return newRecord
    }

    @Query(_return => CallTokenResponse, { name: "officeFetchCallToken"})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async officeFetchCallToken(
        @Args("callId") callId: string,
        @OfficeRequester() officeRequester: OfficeUser,
        @BearerAccessToken() token: string,
    ): Promise<CallTokenResponse> {
        const officeUser = await this.rtcService.getRtcUser(officeRequester)
        const callRecord = await CallRecord.findOne({ where: { id: callId } })
        if (!callRecord) {
            throw OfficeError.RTCErrorCallInfoNotFound
        }
        if (SuccessCallStatus.includes(callRecord.status)) {
            throw OfficeError.RTCErrorTheCallHasEnded
        }

        const callParticipant = await CallParticipant.findOne({
            where: {
                callId: callId,
                userId: officeUser.rtcUserId
            }
        })
        if (!callParticipant) {
            throw OfficeError.RTCErrorCallInfoNotFound
        }
        // callParticipant.status = CallParticipantStatus.CONNECT
        // await callParticipant.save()

        callRecord.metadata.push(JSON.stringify({
            time: Date.now(),
            action: `[${callParticipant.role}] UserID: ${officeUser.rtcUserId} => FETCH CALL TOKEN`,
            callStatus: callRecord.status
        }))
        
        await callRecord.save()
        console.log(`[CALL - ${callId}]|<FETCH_CALL_TOKEN>: [${callParticipant.role}] UserID: ${officeUser.rtcUserId} => FETCH CALL TOKEN`)

        if (callParticipant.role === CallParticipantRole.HOST && callRecord.status === CallStatus.CONNECTING) {
            callRecord.status = CallStatus.CALLING
            
            const guestParticipants = await CallParticipant.find({
                where: {
                    callId: callId,
                    role: CallParticipantRole.GUEST
                }
            })
            const guests = await OfficeUser.find({
                where: {
                    rtcUserId: In(guestParticipants.map(p => p.userId))
                }
            })

            var offlineCount = 0
            var busyCount = 0
            for (const iterator of guests) {
                const checkBusy = await CallParticipant.findOne({
                    where: {
                        userId: iterator.rtcUserId,
                        status: CallParticipantStatus.JOIN,
                        callId: Not(callId)
                    }
                })
                if (checkBusy) {
                    busyCount += 1
                } else {
                    //check noti + bắn noti || end call
                    const subscribedUser = await this.identityService.subscribedUser(token, iterator.iamUserId)
                    console.log(`[CALL - ${callId}]| subscribedUser <${iterator.iamUserId}>: `, JSON.stringify(subscribedUser))
                    if (subscribedUser) {
                        const notiObject = {
                            callId: callRecord.id,
                            extra: {
                                callerId: `${officeUser.rtcUserId}`,
                                state: 1,
                                content: "",
                                response: "",
                                channelId: ""
                            },
                            // receiverRoleId: Number(iterator.serviceBusinessRoleId),
                            userId: officeUser.id,
                            // businessRoleId: businessRoleId,
                            code: officeUser.code || 'UNKNOWN',
                            name: officeUser.fullname || 'UNKNOWN',
                            avatar: officeUser.imageUrls && officeUser.imageUrls.length > 0 ? `${officeUser.imageUrls[0]}` : '',
                            callType: callRecord.type,
                            appId: process.env.AGORA_APP_ID
                        }
                        await this.notificationService.destinationPush(
                            token,
                            'call.notify',
                            'OFFICE',
                            JSON.stringify(notiObject),
                            '',
                            JSON.stringify(notiObject),
                            [iterator.id],
                            null,
                            process.env.OFFICE_ORGANIZATION_ID
                        )
                    } else {
                        // xử lý user offline
                        console.log(`[CALL - ${callId}]| OFFLINE GUEST <${iterator.id}>: `)
                        offlineCount += 1
                    }

                    // const setting = await this.k365Service.getNotificationSetting(Number(iterator.serviceUserId));
                    // if (setting && setting.endPointARN) { //chưa check businessRoleId
                    //     const sendNotification = await this.notificationService.destinationPush(
                    //         'call_notify',
                    //         'Karofi',
                    //         JSON.stringify({
                    //             callId: callRecord.id,
                    //             extra: {
                    //                 callerId: `${rtcUserId}`,
                    //                 state: 1,
                    //                 content: "",
                    //                 response: "",
                    //                 channelId: ""
                    //             },
                    //             receiverRoleId: Number(iterator.serviceBusinessRoleId),
                    //             userId: userId,
                    //             businessRoleId: businessRoleId,
                    //             code: businessRoleId === 12 ? 'KAROFI' : (userInfo.code || 'UNKNOWN'),
                    //             name: businessRoleId === 12 ? 'KAROFI' : (userInfo.name || 'UNKNOWN'),
                    //             avatar: userInfo.avatar ? `${process.env.S3_URL}/${userInfo.avatar}` : '',
                    //             callType: callRecord.type,
                    //             appId: process.env.AGORA_APP_ID
                    //         }),
                    //         "",
                    //         null,
                    //         [
                    //             {
                    //                 endpoint: setting.endPointARN,
                    //                 userId: setting.userId
                    //             }
                    //         ],
                    //         Number(iterator.serviceBusinessRoleId),
                    //         userId,
                    //         businessRoleId
                    //     )
                    //     console.log(`[CALL - ${callId}]| sendNotification to GUEST <${iterator.id}>: `, JSON.stringify(sendNotification))
                    // } else {
                    //     // xử lý user offline
                    //     console.log(`[CALL - ${callId}]| OFFLINE GUEST <${iterator.id}>: `)
                    //     offlineCount += 1
                    // }
                }
            }
            
            if (guests.length === (offlineCount + busyCount)) {
                // kết thúc cuộc gọi
                callRecord.status = CallStatus.CANCELED
                callRecord.metadata.push(JSON.stringify({
                    time: Date.now(),
                    action: `[${callParticipant.role}] UserID: ${officeUser.rtcUserId} => MISSED CALL (${offlineCount + busyCount} user(s) busy/offline)`,
                    callStatus: callRecord.status
                }))
                callParticipant.status = CallParticipantStatus.LEFT
                
                await CallParticipant.update({callId: callId, role: CallParticipantRole.GUEST}, {status: CallParticipantStatus.OFFLINE})
                await callParticipant.save()
                await callRecord.save()

                throw OfficeError.RTCErrorUnableToConnectToUser
            } else {
                await callRecord.save()
                setTimeout(async () => {
                    const checkRecord = await CallRecord.findOne({ where: { id: callRecord.id } })
                    if (checkRecord.status === CallStatus.CALLING) {
                        const now = new Date()
                        checkRecord.status = CallStatus.CANCELED
                        checkRecord.note = `ENDED by RINGING_TIMEOUT: ${Number(process.env.RINGING_TIMEOUT)}`
        
                        checkRecord.metadata.push(JSON.stringify({
                            time: now.getTime(),
                            action: `[SYSTEM] => CALL ENDED by RINGING_TIMEOUT: ${Number(process.env.RINGING_TIMEOUT)}`,
                            callStatus: checkRecord.status
                        }))
                        await CallParticipant.update({callId: checkRecord.id}, {status: CallParticipantStatus.LEFT})
                        await checkRecord.save()
                        
                        console.log(`[CALL - ${checkRecord.id}]|<SYSTEM_END>: [SYSTEM] => CALL ENDED by CALL_TIMEOUT: ${Number(process.env.CALL_TIMEOUT)}`)
                    }
                }, (Number(process.env.RINGING_TIMEOUT)+2000))
            }
        }

        return {
            appId: process.env.AGORA_APP_ID,
            callToken: callParticipant.callToken,
            tokenExpireAt: callParticipant.tokenExpireAt,
            uId: callParticipant.userId,
            callTimeout: Number(process.env.CALL_TIMEOUT),
            incallTimeout: Number(process.env.INCALL_TIMEOUT),
            ringingTimeout: Number(process.env.RINGING_TIMEOUT)
        }
    }

    @Query(_type => RTMTokenResponse, { name: "officeFetchRTMToken" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async officeFetchRTMToken(
        @OfficeRequester() officeRequester: OfficeUser
    ): Promise<RTMTokenResponse> {
        const officeUser = await this.rtcService.getRtcUser(officeRequester)
        const tokenExpireAt = Date.now() + 3600000
        const token = RtmTokenBuilder.buildToken(
            process.env.AGORA_APP_ID,
            process.env.AGORA_APP_CERTIFICATE,
            `${officeUser.rtcUserId}`,
            RtmRole.Rtm_User,
            tokenExpireAt/1000
        )

        return {
            appId: process.env.AGORA_APP_ID,
            rtmToken: token,
            tokenExpireAt: new Date(tokenExpireAt),
            uId: officeUser.rtcUserId
        }
    }

    @Mutation(_type => CallRecord, { name: "officeCallCancel" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async officeCallCancel(
        @Args('callId', { nullable: false }) callId: string,
        @OfficeRequester() officeRequester: OfficeUser
    ) : Promise<CallRecord> {
        const officeUser = await this.rtcService.getRtcUser(officeRequester)
        const now = new Date()

        const existedCall = await CallRecord.findOne({
            where: {
                id: callId,
                createdBy: officeUser.rtcUserId,
                status: In([CallStatus.CALLING, CallStatus.CONNECTING])
            }
        })

        if (!existedCall) {
            throw OfficeError.RTCErrorCallInfoNotFound
        }

        existedCall.status = CallStatus.CANCELED
        existedCall.metadata.push(JSON.stringify({
            time: now.getTime(),
            action: `[${CallParticipantRole.HOST}] UserID: ${officeUser.rtcUserId} => CANCEL CALL`,
            callStatus: existedCall.status
        }))

        console.log(`[CALL - ${callId}]|<CANCEL>: [${CallParticipantRole.HOST}] UserID: ${officeUser.rtcUserId} => CANCEL CALL`)

        await CallParticipant.update({
            callId: callId
        }, {
            status: CallParticipantStatus.LEFT
        })

        return existedCall.save()
    }

    @Mutation(_type => CallRecord, { name: "officeCallRefuse" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async officeCallRefuse(
        @Args('callId', { nullable: false }) callId: string,
        @OfficeRequester() officeRequester: OfficeUser
    ) : Promise<CallRecord> {
        const officeUser = await this.rtcService.getRtcUser(officeRequester)
        const now = new Date()

        const existedCall = await CallRecord.findOne({
            where: {
                id: callId,
                status: CallStatus.CALLING
            }
        })

        if (!existedCall) {
            throw OfficeError.RTCErrorCallInfoNotFound
        }

        const callParticipant = await CallParticipant.findOne({
            where: {
                callId: callId,
                userId: officeUser.rtcUserId,
                role: CallParticipantRole.GUEST
            }
        })
        if (!callParticipant) {
            throw OfficeError.RTCErrorTheCallIsNotSharedWithYou
        }

        if (existedCall.isGroupCall === true) {
            callParticipant.status = CallParticipantStatus.LEFT
            await callParticipant.save()

            existedCall.metadata.push(JSON.stringify({
                time: now.getTime(),
                action: `[${callParticipant.role}] UserID: ${officeUser.rtcUserId} => REFUSE CALL`,
                callStatus: existedCall.status
            }))

            console.log(`[CALL - ${callId}]|<REFUSE>: [${callParticipant.role}] UserID: ${officeUser.rtcUserId} => REFUSE CALL`)
        } else {
            existedCall.status = CallStatus.REFUSE
            existedCall.metadata.push(JSON.stringify({
                time: now.getTime(),
                action: `[${callParticipant.role}] UserID: ${officeUser.rtcUserId} => REFUSE CALL`,
                callStatus: existedCall.status
            }))

            console.log(`[CALL - ${callId}]|<REFUSE>: [${callParticipant.role}] UserID: ${officeUser.rtcUserId} => REFUSE CALL`)

            await CallParticipant.update({
                callId: callId
            }, {
                status: CallParticipantStatus.LEFT
            })
        }

        return existedCall.save()
    }

    @Mutation(_type => CallRecord, { name: "officeCallAccept" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async officeCallAccept(
        @Args('callId', { nullable: false }) callId: string,
        @OfficeRequester() officeRequester: OfficeUser
    ) : Promise<CallRecord> {
        const officeUser = await this.rtcService.getRtcUser(officeRequester)
        const now = new Date()

        const existedCall = await CallRecord.findOne({
            where: {
                id: callId,
                status: CallStatus.CALLING
            }
        })

        if (!existedCall) {
            throw OfficeError.RTCErrorCallInfoNotFound
        }

        const callParticipant = await CallParticipant.findOne({
            where: {
                callId: callId,
                userId: officeUser.rtcUserId,
                role: CallParticipantRole.GUEST
            }
        })
        if (!callParticipant) {
            throw OfficeError.RTCErrorTheCallIsNotSharedWithYou
        }

        if (existedCall.isGroupCall === true) {
            if (existedCall.status !== CallStatus.PICKED_UP) {
                existedCall.status = CallStatus.PICKED_UP
                existedCall.startAt = now
            }
            
            existedCall.metadata.push(JSON.stringify({
                time: now.getTime(),
                action: `[${callParticipant.role}] UserID: ${officeUser.rtcUserId} => ACCEPT CALL`,
                callStatus: existedCall.status
            }))
            callParticipant.status = CallParticipantStatus.JOIN
            await callParticipant.save()
            console.log(`[CALL - ${callId}]|<ACCEPT>: [${callParticipant.role}] UserID: ${officeUser.rtcUserId} => ACCEPT CALL`)
        } else {
            existedCall.status = CallStatus.PICKED_UP
            existedCall.startAt = now

            existedCall.metadata.push(JSON.stringify({
                time: now.getTime(),
                action: `[${callParticipant.role}] UserID: ${officeUser.rtcUserId} => ACCEPT CALL`,
                callStatus: existedCall.status
            }))

            callParticipant.status = CallParticipantStatus.JOIN
            await callParticipant.save()

            console.log(`[CALL - ${callId}]|<ACCEPT>: [${callParticipant.role}] UserID: ${officeUser.rtcUserId} => ACCEPT CALL`)
        }

        if (existedCall.recording === true) {
            try {
                const host = await CallParticipant.findOne({
                    where: {
                        callId: callId,
                        role: CallParticipantRole.HOST
                    }
                })
                const res = await this.rtcService.getResourceRecording(host.callId, `${host.userId}`)
                if (res.error) throw res.error
                if (!res.data) throw HttpError.NoContent
                const rs = await this.rtcService.startRecording(host.callId, `${host.userId}`, host.callToken, res.data.resourceId)
                if (rs.error) throw rs.error
                if (!rs.data) throw HttpError.NoContent
                existedCall.recordingStatus = RecordingStatus.RECORDING
                existedCall.recordingSid = rs.data.sid
                existedCall.recordingResourceId = rs.data.resourceId
            } catch (error) {
                console.error(`[AGORA] Cloud Recording ERR: `, error)
                existedCall.recordingStatus = RecordingStatus.FAIL
            }
        }

        return existedCall.save()
    }

    @Mutation(_type => CallRecord, { name: "officeCallEnd" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async officeCallEnd(
        @Args('callId', { nullable: false }) callId: string,
        @OfficeRequester() officeRequester: OfficeUser
    ) : Promise<CallRecord> {
        const officeUser = await this.rtcService.getRtcUser(officeRequester)
        const now = new Date()

        const existedCall = await CallRecord.findOne({
            where: {
                id: callId,
                status: CallStatus.PICKED_UP
            }
        })

        if (!existedCall) {
            throw OfficeError.RTCErrorCallInfoNotFound
        }

        const callParticipant = await CallParticipant.findOne({
            where: {
                callId: callId,
                userId: officeUser.rtcUserId
            }
        })
        if (!callParticipant) {
            throw OfficeError.RTCErrorTheCallIsNotSharedWithYou
        }

        callParticipant.status = CallParticipantStatus.LEFT
        await callParticipant.save()

        //END CALL (với cuộc gọi đơn & HOST endcall cuộc gọi nhóm)
        if (!(existedCall.isGroupCall === true && callParticipant.role === CallParticipantRole.GUEST)) {
            existedCall.status = CallStatus.ENDED
            existedCall.endAt = now
            existedCall.metadata.push(JSON.stringify({
                time: now.getTime(),
                action: `[${callParticipant.role}] UserID: ${officeUser.rtcUserId} => END CALL`,
                callStatus: existedCall.status
            }))
    
            console.log(`[CALL - ${callId}]|<END>: [${callParticipant.role}] UserID: ${officeUser.rtcUserId} => END CALL`)
    
            await CallParticipant.update({
                callId: callId
            }, {
                status: CallParticipantStatus.LEFT
            })
        } else {
            existedCall.metadata.push(JSON.stringify({
                time: now.getTime(),
                action: `[${callParticipant.role}] UserID: ${officeUser.rtcUserId} => END CALL`,
                callStatus: existedCall.status
            }))
    
            console.log(`[CALL - ${callId}]|<END>: [${callParticipant.role}] UserID: ${officeUser.rtcUserId} => END CALL`)
        }

        if (existedCall.recording === true && existedCall.recordingSid && existedCall.recordingResourceId) {
            try {
                const res = await this.rtcService.stopRecording(existedCall.id, `${existedCall.createdBy}`, existedCall.recordingSid, existedCall.recordingResourceId)
                if (res.error) throw res.error
                if (!res.data) throw HttpError.NoContent
                existedCall.recordingStatus = RecordingStatus.SUCCESS
                existedCall.recordingFilePaths = (res.data.serverResponse?.fileList || []).map((f: any) => f.fileName)
            } catch (error) {
                console.error(`[AGORA] Cloud Recording ERR: `, error)
                existedCall.recordingStatus = RecordingStatus.FAIL
            }
        }

        return existedCall.save()
    }
}