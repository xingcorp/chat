import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from "@nestjs/schedule";
import { RTCService } from "@modules/graphql/rtc/rtc.service";

@Injectable()
export class RtcJobService {
    constructor(private rtcService: RTCService) {
    }

    @Cron(CronExpression.EVERY_30_SECONDS, { name: "agoraLongPoll" })
    async agoraLongPoll() {
        try {
            return this.rtcService.agoraLongPoll()
        } catch (e) {
            console.log('agoraLongPoll err', e)
        }

    }
}
