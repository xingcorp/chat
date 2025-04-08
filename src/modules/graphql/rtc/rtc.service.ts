import { RestClient } from "@core/common/rest.client";
import { OfficeUser } from "@models/entities";
import { Injectable } from "@nestjs/common";
import { RtmRole, RtmTokenBuilder } from "agora-access-token";
import { IsNull, Not } from "typeorm";
import { CallRecord, CallStatus, SuccessCallStatus } from "@models/entities/rtc/call.record";
import { CallParticipant, CallParticipantRole, CallParticipantStatus } from "@models/entities/rtc/call.participant";
import { RequestContext } from "@common/context/request.context";

const NO_START_VALUE: number = 1000000

@Injectable()
export class RTCService extends RestClient {
    token: string
    apiToken: string
    constructor() {
        super()
        this.apiToken = Buffer.from(process.env.AGORA_API_KEY + ":" + process.env.AGORA_API_SECRET).toString('base64')
        const tokenExpireAt = Date.now() + 3600000
        this.token = RtmTokenBuilder.buildToken(
            process.env.AGORA_APP_ID,
            process.env.AGORA_APP_CERTIFICATE,
            `SYSTEM`,
            RtmRole.Rtm_User,
            tokenExpireAt / 1000
        )
        // console.log("RTM TOKEN: ", this.token)
        setInterval(() => {
            const tokenExpireAt = Date.now() + 3600000
            this.token = RtmTokenBuilder.buildToken(
                process.env.AGORA_APP_ID,
                process.env.AGORA_APP_CERTIFICATE,
                `SYSTEM`,
                RtmRole.Rtm_User,
                tokenExpireAt/1000
            )
            // console.log("RTM TOKEN: ", this.token)
        }, 3600000)
    }
    public async fetchChannelEvents() {
        try {
            const { response, error } = await this.sendRawRequest(
                {
                    method: 'get',
                    baseURL: process.env.AGORA_DOMAIN,
                    url: `dev/v2/project/${process.env.AGORA_APP_ID}/rtm/vendor/channel_events`
                }, {
                    'x-agora-token': `${this.token}`,
                    'x-agora-uid': `SYSTEM`
                }
            )

            return { events: response.events, error: error }
        } catch (error) {
            return { data: null, error: error }
        }
    }

    public async getResourceRecording(cname: string, uid: string) {
        try {
            const { response, error } = await this.sendRawRequest(
                {
                    method: 'post',
                    baseURL: process.env.AGORA_DOMAIN,
                    url: `v1/apps/${process.env.AGORA_APP_ID}/cloud_recording/acquire`,
                    data: {
                        cname: cname,
                        uid: uid,
                        clientRequest: {
                            resourceExpiredHour: 24,
                            scene: 0
                        }
                    }
                }, {
                    'Authorization': `Basic ${this.apiToken}`,
                    'Content-Type': `application/json;charset=utf-8`
                }
            )

            return { data: response, error: error }
        } catch (error) {
            return { data: null, error: error }
        }
    }

    public async startRecording(cname: string, uid: string, callToken: string, resourceid: string) {
        try {
            const { response, error } = await this.sendRawRequest(
                {
                    method: 'post',
                    baseURL: process.env.AGORA_DOMAIN,
                    url: `v1/apps/${process.env.AGORA_APP_ID}/cloud_recording/resourceid/${resourceid}/mode/mix/start`,
                    data: {
                        uid: uid,
                        cname: cname,
                        clientRequest: {
                            token: callToken,
                            recordingConfig: {
                                maxIdleTime: 30,
                                streamTypes: 2,
                                audioProfile: 1,
                                channelType: 0,
                                videoStreamType: 0,
                                transcodingConfig: {
                                    height: 480,
                                    width: 640,
                                    bitrate: 500,
                                    fps: 15,
                                    mixedVideoLayout: 1
                                }
                            },
                            recordingFileConfig: {
                                avFileType: ["hls", "mp4"]
                            },
                            storageConfig: {
                                accessKey: process.env.AWS_IAM_ACCESS_KEY_ID,
                                region: 8, //ap-southeast-1
                                bucket: process.env.AWS_S3_BUCKET,
                                secretKey: process.env.AWS_IAM_ACCESS_KEY_SECRET,
                                vendor: 1, //AWS S3
                                fileNamePrefix: [process.env.SERVICE_CODE, "record", cname.replaceAll('-', '')]
                            }
                        }
                    }
                }, {
                    'Authorization': `Basic ${this.apiToken}`,
                    'Content-Type': `application/json;charset=utf-8`
                }
            )

            return { data: response, error: error }
        } catch (error) {
            return { data: null, error: error }
        }
    }

    public async stopRecording(cname: string, uid: string, sid: string, resourceid: string) {
        try {
            const { response, error } = await this.sendRawRequest(
                {
                    method: 'post',
                    baseURL: process.env.AGORA_DOMAIN,
                    url: `v1/apps/${process.env.AGORA_APP_ID}/cloud_recording/resourceid/${resourceid}/sid/${sid}/mode/mix/stop`,
                    data: {
                        uid: uid,
                        cname: cname,
                        clientRequest: {}
                    }
                }, {
                    'Authorization': `Basic ${this.apiToken}`,
                    'Content-Type': `application/json;charset=utf-8`
                }
            )

            return { data: response, error: error }
        } catch (error) {
            return { data: null, error: error }
        }
    }

    public async getRecordingInfo(sid: string, resourceid: string) {
        try {
            const { response, error } = await this.sendRawRequest(
                {
                    method: 'get',
                    baseURL: process.env.AGORA_DOMAIN,
                    url: `v1/apps/${process.env.AGORA_APP_ID}/cloud_recording/resourceid/${resourceid}/sid/${sid}/mode/mix/query`
                }, {
                    'Authorization': `Basic ${this.apiToken}`,
                    'Content-Type': `application/json;charset=utf-8`
                }
            )

            return { data: response, error: error }
        } catch (error) {
            return { data: null, error: error }
        }
    }

    public async getRtcUser(officeUser: OfficeUser): Promise<OfficeUser> {
        const user = await OfficeUser.findOne({ where: { id: officeUser.id } })
        if (user.rtcUserId) return user
        const countRtcUser = await OfficeUser.count({ where: {
            rtcUserId: Not(IsNull())
        } })
        user.rtcUserId = (NO_START_VALUE + countRtcUser + 1)

        return user.save()
    }

    async agoraLongPoll() {
        const { events, error } = await this.fetchChannelEvents()
        console.log('[AGORA] Long poll events every 30s: ', events);
        for (const e of events) {
            // const rtcUserId = e.user_id as string
            const rtcUserId = e.user_id as number
            const channel = e.group_id as string
            const action = e.type as string

            const existedCall = await CallRecord.findOne({ where: { id: channel } })
            if (!existedCall) {
                console.log(`[agoraLongPoll] CallID ${channel} not found`)
                continue
            }
            // if (SuccessCallStatus.includes(existedCall.status)) {
            //     console.log(`[agoraLongPoll] CallID ${channel} is ended`)
            //     continue
            // }
            const existedParticipant = await CallParticipant.findOne({
                where: {
                    callId: channel,
                    userId: rtcUserId
                }
            })
            if (!existedParticipant) {
                console.log(`[agoraLongPoll] CallID ${channel} not contain ${rtcUserId}`)
                continue
            }
            switch(action) {
                case 'Join':
                    console.log(`[AGORA] UserID ${rtcUserId} join call channel ${channel}`)
                    existedParticipant.status = CallParticipantStatus.JOIN
                    await existedParticipant.save()

                    existedCall.metadata.push(JSON.stringify({
                        time: Date.now(),
                        action: `[${existedParticipant.role}] UserID: ${rtcUserId} => JOIN ROOM`,
                        callStatus: existedCall.status
                    }))
                    await existedCall.save()

                    console.log(`[CALL - ${channel}]|<SUBCRIBE>: [${existedParticipant.role}] UserID: ${rtcUserId} => JOIN ROOM`)
                    break
                case 'Leave':
                    console.log(`[AGORA] UserID ${rtcUserId} leave call channel ${channel}`)
                    existedParticipant.status = CallParticipantStatus.LEFT
                    await existedParticipant.save()

                    existedCall.metadata.push(JSON.stringify({
                        time: Date.now(),
                        action: `[${existedParticipant.role}] UserID: ${rtcUserId} => LEFT ROOM`,
                        callStatus: existedCall.status
                    }))
                    await existedCall.save()

                    console.log(`[CALL - ${channel}]|<SUBCRIBE>: [${existedParticipant.role}] UserID: ${rtcUserId} => LEFT ROOM`)
                    //Xử lý k reconnect -> END CALL (với cuộc gọi đơn & HOST mất kết nối cuộc gọi nhóm)
                    if (!(existedCall.isGroupCall === true && existedParticipant.role === CallParticipantRole.GUEST)) {
                        setTimeout(async () => {
                            const recheckCall = await CallRecord.findOne({ where: { id: channel } })
                            if (!SuccessCallStatus.includes(recheckCall.status)) {
                                recheckCall.status = CallStatus.ENDED
                                const now = new Date()
                                if (recheckCall.startAt) {
                                    recheckCall.endAt = now
                                }
                                await CallParticipant.update({
                                    callId: channel
                                    // status: CallParticipantStatus.JOIN
                                }, {
                                    status: CallParticipantStatus.LEFT
                                })

                                recheckCall.metadata.push(JSON.stringify({
                                    time: Date.now(),
                                    action: `[SYSTEM] => CALL ENDED by DISCONNECT_TIMEOUT: ${Number(process.env.DISCONNECT_TIMEOUT)}`,
                                    callStatus: recheckCall.status
                                }))
                                await recheckCall.save()

                                console.log(`[CALL - ${channel}]|<SYSTEM_END>: [SYSTEM] => CALL ENDED by DISCONNECT_TIMEOUT: ${Number(process.env.DISCONNECT_TIMEOUT)}`)
                            }
                        }, Number(process.env.DISCONNECT_TIMEOUT))
                    }
                    break
            }
        }
    }

    /*https://docs.agora.io/en/video-calling/channel-management-api/endpoint/query-channel-information/query-user-status?platform=android*/
    async callQueryUserStatus(callId: string, user: OfficeUser) {
        const { response, error } = await this.sendRawRequest(
            {
                method: 'get',
                baseURL: process.env.AGORA_DOMAIN,
                url: `dev/v1/channel/user/property/${process.env.AGORA_APP_ID}/${user.rtcUserId}/${callId}`
            }, {
                'Authorization': `Basic ${this.apiToken}`,
                'Content-Type': `application/json;charset=utf-8`
            }
        )

        return { response, error }
    }

    async updateCallById(callId: string) {
        try {
            const user = await RequestContext.currentUser()
            if (!user) return

            const { response, error } = await this.callQueryUserStatus(callId, user)

            if (!response.data.in_channel) {
                await this.leftRequesterOutOfChannel(callId, user)
                return false
            }

            return callId
        } catch (error) {
            return false
        }
    }

    private async leftRequesterOutOfChannel(callId: string, user: OfficeUser) {
        await CallParticipant.update({
            callId,
            userId: user.rtcUserId
        }, {
            status: CallParticipantStatus.LEFT
        })
    }
}