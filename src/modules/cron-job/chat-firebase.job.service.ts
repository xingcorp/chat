import { Injectable } from '@nestjs/common';
import { ChatFirebaseService } from "@modules/chat-firebase/chat-firebase.service";
import { Cron, CronExpression } from "@nestjs/schedule";
import { algoliaUpdateGroupMessage } from "@services/algolia/search.algolia";

@Injectable()
export class ChatFirebaseJobService {
    constructor(private chatFirebaseService: ChatFirebaseService) {
    }

    @Cron(CronExpression.EVERY_DAY_AT_1AM, {name: 'CheckCreatUserNotExistAtFirebase'})
    async createExistUserToFirebase() {
        try {
            return this.chatFirebaseService.createExistUserToFirebase()
        } catch (e) {
            console.log('createExistUserToFirebase err', e)
        }
    }

    // @Cron(CronExpression.EVERY_10_MINUTES, {name: 'algoliaUpdateGroupId'})
    async algoliaUpdateGroupId() {
        try {
            await algoliaUpdateGroupMessage()
        } catch (e) {
            console.log('algoliaUpdateGroupId err', e)
        }
    }
}
