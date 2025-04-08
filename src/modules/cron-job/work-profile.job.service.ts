import { Injectable } from '@nestjs/common';
import { Cron, Timeout } from "@nestjs/schedule";
import { WorkProfileService } from "@modules/graphql/management/work-profile/work-profile.service";

@Injectable()
export class WorkProfileJobService {
    constructor(private workProfileService: WorkProfileService) {
    }

    @Cron('5 0 * * *', {
        name: 'UpdateWorkProfileDataToUser',
        timeZone: process.env.TIMEZONE
    })
    async cronUpdateWorkProfileDataToUser() {
        try {
            return this.workProfileService.cronUpdateWorkProfileDataToUser()
        } catch (e) {
            console.log('UpdateWorkProfileDataToUser err', e)
        }
    }

    /*done*/
    // @Timeout(12000)
    async seedDataForNewCr() {
        return this.workProfileService.seedData()
    }

    /*done*/
    // @Timeout(10000)
    async seedNewSoftField() {
        return this.workProfileService.seedSoftResignField()
    }

    /*in progress*/
    // @Timeout(11000)
    async fillNewData() {
        return this.workProfileService.fillNewDataActionType()
    }
}
