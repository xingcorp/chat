import { Injectable } from '@nestjs/common';
import { ObjectStoreService } from "@service-modules/object-store/object-store.service";

@Injectable()
export class ObjectStoreJobService {
    constructor(private objectStoreService: ObjectStoreService) {
    }

    // @Cron(CronExpression.EVERY_HOUR)
    async bucketAiChangeNameToUUID() {
        try {
            return this.objectStoreService.bucketAiChangeNameToUUID()
        } catch (e) {
            console.log('bucketAiChangeNameToUUID err', e)
        }
    }
}
